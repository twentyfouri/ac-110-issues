#!/bin/sh
mkdir -p /tmp/venc/c0/;
mkdir -p /tmp/aenc/c0/;
mkdir -p /tmp/playback/c0/;
mkdir -p /tmp/twoway/c0/;
mkdir -p /tmp/sr/c0/;
mkdir -p /tmp/vrecord/videoclips/;
#export LD_LIBRARY_PATH=$(pwd)/../lib;

export LD_LIBRARY_PATH=/mnt/flash/vienna/lib:/mnt/flash/vienna/lib/vienna:$LD_LIBRARY_PATH

cd /mnt/flash/ac100

sleep 1

./time_sync.sh

UPDATEDIR=/mnt/sd/ac-100
TARGETDIR=/mnt/flash/ac100
if [ -d "$UPDATEDIR" ]; then
    echo "examine patch"
    # 將所有要比對的文件名列在這裡
    for file in p2p kp_firmware_host_stream_custom_app_security gatt_server; do
	SRC="$UPDATEDIR/$file"
	DST="$TARGETDIR/$file"
	if [ -f "$SRC" ]; then
            # 如果不同，則執行括號內的更新動作
            cmp -s "$DST" "$SRC" || {
                cp "$SRC" "$DST"
                echo -e "\e[33m[start.sh] Update $file\e[m"
            }
	fi
    done
fi

./rtsps -c stream_server_config.ini &
if [ -f /mnt/flash/etc/p2p.ini.new ]; then
    echo -e "\e[33m[start.sh] Found backup file\e[m"
    mv /mnt/flash/etc/p2p.ini.new /mnt/flash/etc/p2p.ini
fi
./p2p &
sleep 1

#shutdown flooding "Reset NPU"
echo "6 4 1 7" > /proc/sys/kernel/printk
./kp_firmware_host_stream_custom_app_security &

(
COUNT=0
SEEN_THREADS=""
PID=$(pidof kp_firmware_host_stream_custom_app_security)
while true; do
    if [ $COUNT -ge 20 ]; then
	break
    fi

    [ -z "$PID" ] && sleep 1 && continue

    for comm in $(cat /proc/$PID/task/*/comm 2>/dev/null); do
        # 檢查這個名稱是否在 SEEN_THREADS 字串中
        case "$SEEN_THREADS" in
            *"|$comm|"*) ;; # 已看過，跳過
            *) 
                echo -e "\e[32m[start.sh] $comm\e[0m"
                SEEN_THREADS="$SEEN_THREADS|$comm|" # 加入紀錄
                ;;
        esac
    done

    # 定義你的退出條件
    echo "$SEEN_THREADS" | grep -q "encode0x0" && break
    COUNT=$((COUNT + 1))
    sleep 1
done
./playback_example_mmap -d "default" -r 8000 -C 4 -R aenc_srb_2 -c 1 -D
./auto_sd.sh
) &
