#!/bin/sh

CONF_FILE="/etc/mdev.conf"
RULE='mmcblk[0-9]* root:root 0660 * /mnt/flash/ac100/auto_sd.sh'

mount_as_tmpfs /etc

if grep -q "^mmcblk[0-9]*" "$CONF_FILE"; then
    echo "mdev rule already exists. Skipping."
else
    echo "$RULE" >> "$CONF_FILE"
    echo "mdev rule added successfully."
fi

