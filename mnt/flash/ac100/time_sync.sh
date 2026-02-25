#!/bin/sh

# EVB Time Synchronization Script
# This script manages system time synchronization on EVB

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UTC_TIME_LOG="${SCRIPT_DIR}/utc_time.log"
GET_UTC_TIME="${SCRIPT_DIR}/get_utc_time"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check network connectivity
# Returns 0 only if network connectivity is confirmed (at least one host is reachable), 1 otherwise.
check_network_connectivity() {
    log_message "Checking network connectivity..."

    # Test multiple endpoints
    test_hosts="1.1.1.1 8.8.8.8 114.114.114.114 223.5.5.5 119.29.29.29 180.76.76.76"
    ping_timeout=3
    
    # Flag to track if any host was successfully pinged
    local connectivity_success=1 

    for host in $test_hosts; do
        log_message "Testing connectivity to $host..."
        if ping -c 1 -W "$ping_timeout" "$host" >/dev/null 2>&1; then
            log_message "Successfully pinged $host. Network connectivity confirmed."
            connectivity_success=0 # Set flag to 0 for success
            break # Exit loop on first success
        else
            log_message "Failed to ping $host."
        fi
    done

    if [ "$connectivity_success" -eq 0 ]; then
        return 0 # Return 0 if network connectivity was confirmed
    else
        log_message "Network connectivity failed: No reachable hosts found."
        return 1 # Return 1 if no host was reachable
    fi
}

# Function to get UTC time using get_utc_time program
# Returns 0 on successful time synchronization from network, 1 otherwise.
get_network_time() {
    log_message "Attempting to get network time..."

    if [ ! -f "$GET_UTC_TIME" ]; then
        log_message "ERROR: get_utc_time program not found at $GET_UTC_TIME"
        return 1
    fi

    if [ ! -x "$GET_UTC_TIME" ]; then
        log_message "Making get_utc_time executable..."
        chmod +x "$GET_UTC_TIME" || {
            log_message "Failed to make get_utc_time executable"
            return 1
        }
    fi

    # Execute get_utc_time; if it returns 0 (success), proceed
    if "$GET_UTC_TIME"; then
        # *** FIX: Capture the newly set system time in a standard, parseable format (YYYY-MM-DD HH:MM:SS) ***
        # This format is generally more robust for 'date -s' parsing than the default 'date -u' output.
        current_utc=$(date -u '+%Y-%m-%d %H:%M:%S') 
        echo "$current_utc" > "$UTC_TIME_LOG"
	hwclock -w
        log_message "Network time synchronized and saved to $UTC_TIME_LOG"
        return 0
    else
        log_message "Failed to get network time using $GET_UTC_TIME"
        return 1
    fi
}

# Function to set system time from log file
# Returns 0 on successful time set from log, 1 otherwise.
set_time_from_log() {
    if [ -f "$UTC_TIME_LOG" ]; then
        # Read the first line, remove newline/carriage return characters
        saved_time=$(head -n 1 "$UTC_TIME_LOG" 2>/dev/null | tr -d '\n\r')
        
        # Check if saved_time is not empty and potentially valid format
        if [ -n "$saved_time" ]; then
            log_message "Attempting to set system time from saved time: '$saved_time'"
            # Use 'date -u -s' with the expected standard format (YYYY-MM-DD HH:MM:SS)
            if date -u -s "$saved_time" >/dev/null 2>&1; then
                log_message "System time set from log file successfully"
                return 0
            else
                # This error indicates the format written to log is not parsable by 'date -s'
                log_message "Failed to set system time from log file (date command failed or invalid format: '$saved_time')."
            fi
        else
            log_message "UTC time log file exists but is empty or contains invalid data."
        fi
    else
        log_message "UTC time log file ($UTC_TIME_LOG) not found."
    fi
    return 1 # Return 1 if log file not found, empty, or set failed
}

# Function to set default time (2030-01-01 00:00:00)
# Returns 0 on successful default time set, 1 otherwise.
set_default_time() {
    log_message "Setting system time to default: 2030-01-01 00:00:00 UTC"
    if date -u -s "2030-01-01 00:00:00" >/dev/null 2>&1; then
        log_message "System time set to default successfully"
        return 0
    else
        log_message "Failed to set system time to default"
        return 1
    fi
}

# Function to display current system time
show_system_time() {
    current_time=$(date)
    current_utc=$(date -u)
    log_message "Current local time: $current_time"
    log_message "Current UTC time: $current_utc"
}

# --- Main execution logic ---
main() {
    log_message "=== EVB Time Synchronization Script Started ==="
    log_message "Script location: $SCRIPT_DIR"

    show_system_time # Show initial time

    local script_exit_status=1 # Default to failure for the script's final exit status

    if check_network_connectivity; then
        # Condition 1: Network is connected
        log_message "Network connectivity confirmed. Attempting to synchronize time from network."
        if get_network_time; then
            log_message "Successfully synchronized time from network."
            script_exit_status=0 # Network synchronization successful, set final status to success
        fi
    fi

    log_message "Final system time after synchronization attempt:"
    show_system_time

    log_message "=== EVB Time Synchronization Script Completed ==="
    echo "" # Add an empty line for readability
    
    return "$script_exit_status" # Return the final status of the script
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges to set system time."
    echo "Please run with: sudo $0"
    exit 1
fi

# Run main function and capture its exit status
main "$@"
exit "$?" # Exit the script with the status from main
