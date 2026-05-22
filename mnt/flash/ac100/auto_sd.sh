#!/bin/sh

export LD_LIBRARY_PATH=/mnt/flash/vienna/lib:/mnt/flash/vienna/lib/vienna:$LD_LIBRARY_PATH

VREC_PATH="/mnt/flash/ac100"
SD_MOUNT_PATH="/mnt/sd"
SD_MOUNT_PATH_TMP="/tmp/vrecord/videoclips"
VREC_CONF="vrec_conf.ini"
APP_NAME="kp_firmware_host_stream_custom_app_security"
LOG_FILE="/tmp/sd_event.log"

printf "\n\n\n===== auto_sd.sh =====\n\n"

APP_PID=$(pidof "$APP_NAME")

if [ "$ACTION" = "add" ] || [ -b /dev/mmcblk0p1 ]; then
    echo "[auto_sd.sh] SD card inserted" >> "$LOG_FILE"

    mkdir -p "$SD_MOUNT_PATH_TMP"
    mount /dev/mmcblk0p1 "$SD_MOUNT_PATH_TMP"
    mount /dev/mmcblk0p1 "$SD_MOUNT_PATH"

else
    echo "[auto_sd.sh] SD card removed" >> "$LOG_FILE"

    umount "$SD_MOUNT_PATH"
    umount "$SD_MOUNT_PATH_TMP"

fi
