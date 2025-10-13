#!/usr/bin/env bash
mkdir -p /tmp/conky
mapfile -t disks < <(bash ~/.config/conky/disk_io.sh)

for i in "${!disks[@]}"; do
    read -ra disk_info <<< "${disks[$i]}"
    for j in "${!disk_info[@]}"; do
        echo "${disk_info[$j]}" > /tmp/conky/disk_${i}_info_${j}.cache
    done
done