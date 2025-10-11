#!/usr/bin/env bash
# Reports total network download and upload speed across all interfaces (except lo)

TX_FILE="/tmp/conky_tx_total"

# Sum all interfaces except loopback
tx=$(awk '{sum+=$1} END{print sum}' /sys/class/net/*/statistics/tx_bytes)

# Read previous values, default to current if missing
[ -f "$TX_FILE" ] && prev_tx=$(cat "$TX_FILE") || prev_tx=$tx

# Compute delta
delta_tx=$((tx - prev_tx))

# Save current values for next run
echo $tx > "$TX_FILE"

echo "$(numfmt --to=iec <<< "$delta_tx")"