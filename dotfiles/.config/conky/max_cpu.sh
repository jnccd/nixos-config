#!/usr/bin/env bash
# Max CPU usage across all cores using /proc/stat deltas

interval=1  # seconds between snapshots

# Read first snapshot
mapfile -t stat1 < <(grep '^cpu[0-9]\+' /proc/stat)

sleep $interval

# Read second snapshot
mapfile -t stat2 < <(grep '^cpu[0-9]\+' /proc/stat)

max=0
sum=0

for i in "${!stat1[@]}"; do
    # Split each line into array
    read -a cpu1 <<< "${stat1[$i]}"
    read -a cpu2 <<< "${stat2[$i]}"

    user1=${cpu1[1]}
    nice1=${cpu1[2]}
    system1=${cpu1[3]}
    idle1=${cpu1[4]}
    iowait1=${cpu1[5]}
    irq1=${cpu1[6]}
    softirq1=${cpu1[7]}
    steal1=${cpu1[8]}

    user2=${cpu2[1]}
    nice2=${cpu2[2]}
    system2=${cpu2[3]}
    idle2=${cpu2[4]}
    iowait2=${cpu2[5]}
    irq2=${cpu2[6]}
    softirq2=${cpu2[7]}
    steal2=${cpu2[8]}

    prevIdle=$(echo "$idle1 + $iowait1" | bc -l)
    idle=$(echo "$idle2 + $iowait2" | bc -l)

    prevNonIdle=$(echo "$user1 + $nice1 + $system1 + $irq1 + $softirq1 + $steal1" | bc -l)
    nonIdle=$(echo "$user2 + $nice2 + $system2 + $irq2 + $softirq2 + $steal2" | bc -l)

    prevTotal=$(echo "$prevIdle + $prevNonIdle" | bc -l)
    total=$(echo "$idle + $nonIdle" | bc -l)

    totald=$(echo "$total - $prevTotal" | bc -l)
    idled=$(echo "$idle - $prevIdle" | bc -l)

    usage=$(echo "($totald - $idled) / $totald * 100" | bc -l)

    usage=${usage%.*}
    (( usage > max )) && max=$usage
    sum=$((sum + usage))
done

avg=$(echo "$sum / ${#cpu1[@]}" | bc -l)
avg=${avg%.*}

echo -e "$max\n$avg"