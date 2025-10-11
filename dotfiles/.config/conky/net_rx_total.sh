#!/usr/bin/env bash
# Reports total network download and upload speed across all interfaces (except lo)

RX_FILE="/tmp/conky_rx_total"

# Sum all interfaces except loopback
rx=$(awk '{sum+=$1} END{print sum}' /sys/class/net/*/statistics/rx_bytes)

# Read previous values, default to current if missing
[ -f "$RX_FILE" ] && prev_rx=$(cat "$RX_FILE") || prev_rx=$rx

# Compute delta
delta_rx=$((rx - prev_rx))

# Save current values for next run
echo $rx > "$RX_FILE"

echo "$(numfmt --to=iec <<< "$delta_rx")"