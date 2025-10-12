#!/usr/bin/env bash
iostat -dx 1 2 | awk 'NF && $1 !~ /^(Device|Linux)/ {print $1, int($3), int($9), int($23), int($18)}' | awk '{ a[$1]=$0 } END { for (i in a) print a[i] }'
