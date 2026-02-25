#!/bin/sh

touch "/mnt/flash/ac100/pre-install"

xzcat /tmp/ac100-firmware.tar.xz | tar xf - -C /tmp nand-env
if [ -f /tmp/nand-env ]; then
        /usr/sbin/flash_erase /dev/mtd1 0 0
        /usr/sbin/nandwrite -p /dev/mtd1 /tmp/nand-env
        echo writing env done
fi

if [ ! -L /mnt/flash/ac100/nef ]; then
    rm -rf /mnt/flash/ac100/nef
    ln -s /mnt/flash/vienna/nef /mnt/flash/ac100/nef
fi

rm -rf /mnt/flash/ac100/p2p-*
rm -rf /mnt/flash/ac100/kp_firmware_host_stream_app_babycam
