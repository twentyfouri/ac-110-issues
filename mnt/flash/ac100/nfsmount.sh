#!/bin/sh

if mountpoint -q /mnt/nand; then
	echo mounted
else
	mount -o nolock 192.168.8.143:/smartac /mnt/nand
fi

cd /mnt/flash/ac100
export LD_LIBRARY_PATH=/mnt/flash/vienna/lib:/mnt/flash/vienna/lib/vienna:/lib

case "$1" in
debugkp)
	/mnt/nand/kp_firmware_host_stream_custom_app_security &
	;;
debugp2p)
	/mnt/nand/p2p &
	;;
park)
	insmod /mnt/flash/vienna/drivers/bluetooth.ko 
	insmod /mnt/flash/vienna/drivers/hidp.ko 
	insmod /mnt/flash/vienna/drivers/rtk_btusb.ko	
	hciconfig hci0 up
	;;
start)
	/mnt/nand/p2p &
	;;
stop)
	killall -9 p2p
	sleep 1
	rm /tmp/p2p_*
	echo "stop"
	;;
esac

