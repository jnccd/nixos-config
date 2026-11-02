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

# --- 2. Add swap usage (captures zram0) ---
while read -r name size used; do
    [ -z "$name" ] && continue
    name="${name#/dev/}"
    fs_size[$name]=$size
    fs_used[$name]=$used
done < <(swapon --show=NAME,SIZE,USED --bytes --noheadings 2>/dev/null)

# --- 3. I/O stats (Filtering out loop and ram devices here!) ---
while read -r dev f1 f2 f3 f4; do
    t=${fs_size[$dev]:-0}
    u=${fs_used[$dev]:-0}
    if [ "$t" -gt 0 ]; then
        pct=$(( u * 100 / t ))
        printf '%s %s %s %s %s %s\n' "$dev" "$f1" "$f2" "$f3" "$f4" "$pct"
    else
        printf '%s %s %s %s %s -\n' "$dev" "$f1" "$f2" "$f3" "$f4"
    fi
done < <(iostat -dx 1 2 \
    | awk 'NF && $1 !~ /^(Device|Linux|loop|ram|sr)/ {print $1, int($3), int($9), (int($23) > 100 ? 100 : int($23)), int($18)}' \
    | awk '{ a[$1]=$0 } END { for (i in a) print a[i] }')