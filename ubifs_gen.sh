#!/bin/bash

help() {
    printf "Usage: $0 -[p Page_size (bytes)] [-s Partition_size (bytes)] [-d Target_dir_Path] [-o Output_file_name] -D(debug)\n"
    printf "Example: Partition size is 0xD240000 (220463104) bytes, page size is 4096 bytes and folder is \"demo\".\n"
    printf "command:\n\t$0 -p 4096 -s 0xD240000 -d demo\n"
    printf "or\t$0 -p 4096 -s 220463104 -d demo\n"
}

unset page_size_kb
unset total_b
unset src_dir
debug=0

while getopts "p:s:d:o:D" opt; do
  case $opt in
    p)  page_size_b="$OPTARG";;
    s)  total_b="$OPTARG";;
    d)  src_dir="$OPTARG";;
    o)  output="$OPTARG";;
    D)  debug=1;;
    ?)  echo "[ERROR] Unknown argument -$opt"
        help
        exit 1;;
  esac
done

cfg=$(mktemp ~/ubi.cfg.XXXXXX)

if [ -z "${page_size_b}" ]; then
    echo "[ERROR] Empty option: -p"
    help
    exit 1
elif [ -z "${total_b}" ]; then
    echo "[ERROR] Empty option: -s"
    help
    exit 1
elif [ -z "${src_dir}" ]; then
    echo "[ERROR] Empty option: -d"
    help
    exit 1
fi

if [ -z "${output}" ]; then
    output="output_ubifs_stress_test_evm.img"
fi

total_kb=$(($(printf "%d" ${total_b}) / 1024))
page_size_kb=$((${page_size_b} / 1024))
peb_size_kb=$((64 * ${page_size_kb}))
total_pebs=$(echo "scale=0;$total_kb / $peb_size_kb" | bc)
reserved_pebs=$(awk -v val=$(echo "$total_pebs * 0.055" | bc) 'BEGIN { print int(val) + (val != int(val)) }')
effective_pebs=$(echo "$total_pebs - $reserved_pebs" | bc)
vol_kb=$(printf "%.0f\n" $(echo "$effective_pebs * $peb_size_kb" | bc))
leb_size_kb=$(expr ${peb_size_kb} - $(expr $page_size_kb \* 2))
max_lebs=$effective_pebs

cat <<-eof > $cfg
[ubifs]
mode=ubi
image=tmp_ubi_fw.bin
vol_id=0
vol_size=${vol_kb}KiB
vol_type=dynamic
vol_alignment=1
vol_name=ubi0_0
vol_flags=autoresize
eof

if [ -d "${src_dir}" ]; then
    rm -rf tmp_ubi_fw.bin "${output}"
    cmd="mkfs.ubifs -F -m $(expr $page_size_kb \* 1024) -e ${leb_size_kb}KiB -c $max_lebs -r ${src_dir} -o tmp_ubi_fw.bin"
    if [ $debug -eq 1 ]; then
        printf "* Debug mode: ON\n* Command:\n"
        echo "$ $cmd"
    fi
    $cmd
    if [ $? -ne 0 ]; then
        echo "[ERROR] mkfs.ubifs failed"
        exit 1
    fi

    cmd="ubinize -o ${output} -m $(expr $page_size_kb \* 1024) -p ${peb_size_kb}KiB -s 512 -O $(expr $page_size_kb \* 1024) $cfg"
    if [ $debug -eq 1 ]; then
        echo "$ cat $cfg"
        cat $cfg
        echo "$ $cmd"
    fi
    $cmd
    if [ $? -ne 0 ]; then
        echo "[ERROR] ubinize failed"
        exit 1
    fi

    rm -rf tmp_ubi_fw.bin
    rm -f "$cfg"
    chmod 777 "${output}"

    # Split if file > 45MB
    MAX_SIZE_MB=45
    MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1024 * 1024))
    actual_size=$(stat -c%s "${output}")
    if [ "$actual_size" -gt "$MAX_SIZE_BYTES" ]; then
        echo "[INFO] Output file exceeds ${MAX_SIZE_MB}MB. Splitting..."
        split_prefix="${output}.part"
        split -b ${MAX_SIZE_BYTES} -d -a 2 "${output}" "${split_prefix}"
        rm -f "${output}"
        echo "[INFO] Split completed. Generated parts:"
        ls -lh ${split_prefix}*
    else
        echo "[INFO] Output file size within limit (${actual_size} bytes). No split needed."
    fi

    echo "[done] Output file(s):"
    ls -lh ${output}*
else
    echo "[ERROR] The directory ${src_dir} does not exist."
    exit 1
fi