#!/bin/sh

# List of process names to kill
#processes="kp_firmware_host_stream_app_babycam tinyaenc_mmap rtsps playback_example_mmap vrec"
processes="kp_firmware_host_stream_app_babycam tinyaenc_mmap rtsps vrec p2p"

# Loop through each process name
for process in $processes; do
  # Use ps and grep to find the PID(s)
  pids=$(ps | grep "$process" | grep -v "grep" | awk '{print $1}')
  
  # Check if process IDs exist
  if [ -n "$pids" ]; then
    echo "Found process: $process, PID(s): $pids"
    # Forcefully terminate the process using kill -9
    kill -9 $pids
    echo "Sent SIGKILL to $process (PID(s): $pids)"
  else
    echo "No process found with the name: $process"
  fi
done

echo "Script execution completed."

