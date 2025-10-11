#!/usr/bin/env bash
iostat -dx 1 2 | awk 'NF && $1 !~ /^(Device|Linux)/ {print $1, $3"Br", $9"Bw", $23"%"}' | awk '{ a[$1]=$0 } END { for (i in a) print a[i] }'
