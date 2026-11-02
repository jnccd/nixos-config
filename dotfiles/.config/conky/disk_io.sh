#!/usr/bin/env bash
mkdir -p /tmp/conky
declare -A fs_used fs_size

# --- 1. filesystem usage per device ---
while read -r name used size; do
    [ -z "$name" ] && continue
    fs_used[$name]=$used
    fs_size[$name]=$size
done < <(lsblk -b -P -n -o NAME,PKNAME,FSTYPE,FSSIZE,FSUSED | awk '
{
    name=""; parent=""; fstype=""; size=0; used=0
    for (i = 1; i <= NF; i++) {
        k = $i; v = $i
        sub(/=.*/, "", k); sub(/^[^=]*="/, "", v); sub(/"$/, "", v)
        if      (k == "NAME")   name   = v
        else if (k == "PKNAME") parent = v
        else if (k == "FSTYPE") fstype = v
        else if (k == "FSSIZE") size   = v + 0
        else if (k == "FSUSED") used   = v + 0
    }
    if (name == "" || fstype == "swap" || size <= 0) next
    sz[name] += size; us[name] += used
    if (parent != "") { sz[parent] += size; us[parent] += used }
}
END { for (d in sz) print d, us[d], sz[d] }')

# --- 2. Add swap usage ---
while read -r name size used; do
    [ -z "$name" ] && continue
    name="${name#/dev/}"
    fs_size[$name]=$size
    fs_used[$name]=$used
done < <(swapon --show=NAME,SIZE,USED --bytes --noheadings 2>/dev/null)

# --- 3. Function to get SMART health ---
get_smart() {
    local dev=$1
    local smart_out
    smart_out=$(sudo smartctl -H -A "/dev/$dev" 2>/dev/null)

    # SSD: NVMe
    if echo "$smart_out" | grep -q "Percentage Used"; then
        local used=$(echo "$smart_out" | awk '/Percentage Used:/ {gsub(/%/,"",$3); print $3}')
        local rem=$((100 - used))
        [ "$rem" -lt 0 ] && rem=0
        echo "$rem ${rem}%"
    # SSD: SATA
    elif echo "$smart_out" | grep -qE "Media_Wearout_Indicator|Wear_Leveling_Count|Percentage_Lifetime_Remaining"; then
        local val=$(echo "$smart_out" | awk '/Media_Wearout_Indicator|Wear_Leveling_Count|Percentage_Lifetime_Remaining/ {print $4}' | head -n1)
        echo "$val ${val}%"
    # HDD / Generic
    elif echo "$smart_out" | grep -q "overall-health self-assessment test result"; then
        local health=$(echo "$smart_out" | grep "overall-health" | awk '{print $NF}')
        if [ "$health" == "PASSED" ]; then
            local bad=$(echo "$smart_out" | awk '$1 == 5 || $1 == 197 || $1 == 198 {sum += $10} END {print sum+0}')
            if [ "$bad" -gt 0 ]; then
                echo "50 WARN" # Bar: 50%, Text: WARN
            else
                echo "100 OK"  # Bar: 100%, Text: OK
            fi
        else
            echo "0 FAIL"
        fi
    else
        echo "0 N/A"
    fi
}

# --- 4. I/O stats + Health ---
while read -r dev f1 f2 f3 f4; do
    t=${fs_size[$dev]:-0}
    u=${fs_used[$dev]:-0}

    smart_bar="0"
    smart_txt="N/A"
    
    # Only query SMART for physical drives
    if [[ "$dev" == nvme* || "$dev" == sd* || "$dev" == hd* ]]; then
        cache_file="/tmp/conky/smart_${dev}.cache"
        # Cache SMART data for 60 seconds to prevent disk spam
        if [ -f "$cache_file" ] && [ $(( $(date +%s) - $(stat -c %Y "$cache_file") )) -lt 60 ]; then
            smart_bar=$(awk '{print $1}' "$cache_file")
            smart_txt=$(awk '{print $2}' "$cache_file")
        else
            out=$(get_smart "$dev")
            echo "$out" > "$cache_file"
            smart_bar=$(echo "$out" | awk '{print $1}')
            smart_txt=$(echo "$out" | awk '{print $2}')
        fi
    fi

    if [ "$t" -gt 0 ]; then
        pct=$(( u * 100 / t ))
        printf '%s %s %s %s %s %s %s %s\n' "$dev" "$f1" "$f2" "$f3" "$f4" "$pct" "$smart_bar" "$smart_txt"
    else
        printf '%s %s %s %s %s - %s %s\n' "$dev" "$f1" "$f2" "$f3" "$f4" "$smart_bar" "$smart_txt"
    fi
done < <(iostat -dx 1 2 \
    | awk 'NF && $1 !~ /^(Device|Linux|loop|ram|sr)/ {print $1, int($3), int($9), (int($23) > 100 ? 100 : int($23)), int($18)}' \
    | awk '{ a[$1]=$0 } END { for (i in a) print a[i] }')