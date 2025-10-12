#!/usr/bin/env bash
# Universal CPU temperature fetcher for Conky
# Works on Intel and AMD systems

set -euo pipefail

get_amd_temp() {
    # Try 'sensors' first
    local tctl
    tctl=$(sensors 2>/dev/null | awk '/Tctl:/ {gsub(/\+|°C/,"",$2); print $2; exit}')
    if [[ -n "$tctl" ]]; then
        echo "$tctl"
        return
    fi

    # Fallback: read from hwmon directly
    local path
    path=$(grep -l "Tctl" /sys/class/hwmon/*/temp*_label 2>/dev/null | sed 's/_label/_input/' | head -n1)
    if [[ -n "$path" && -r "$path" ]]; then
        awk '{printf "%.1f\n", $1/1000}' "$path"
        return
    fi
}

get_intel_temp() {
    # Try 'sensors' (common name: Package id 0)
    local pkg
    pkg=$(sensors 2>/dev/null | awk '/Package id 0:/ {gsub(/\+|°C/,"",$4); print $4; exit}')
    if [[ -n "$pkg" ]]; then
        echo "$pkg"
        return
    fi

    # Fallback: try hwmon
    local path
    path=$(grep -l "Package id 0" /sys/class/hwmon/*/temp*_label 2>/dev/null | sed 's/_label/_input/' | head -n1)
    if [[ -n "$path" && -r "$path" ]]; then
        awk '{printf "%.1f\n", $1/1000}' "$path"
        return
    fi
}

# Detect CPU vendor
vendor=$(cat /proc/cpuinfo | grep -m1 'vendor_id' | awk '{print $3}')

case "$vendor" in
    GenuineIntel)
        get_intel_temp
        ;;
    AuthenticAMD)
        get_amd_temp
        ;;
    *)
        echo ""
        ;;
esac