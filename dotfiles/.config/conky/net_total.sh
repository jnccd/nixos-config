#!/usr/bin/env bash
# Reports total network download and upload speed across all interfaces (except lo)

RX_FILE="/tmp/conky_rx_total"
TX_FILE="/tmp/conky_tx_total"

# Sum all interfaces except loopback
rx=$(awk '{sum+=$1} END{print sum}' /sys/class/net/*/statistics/rx_bytes)
tx=$(awk '{sum+=$1} END{print sum}' /sys/class/net/*/statistics/tx_bytes)

# Read previous values, default to current if missing
[ -f "$RX_FILE" ] && prev_rx=$(cat "$RX_FILE") || prev_rx=$rx
[ -f "$TX_FILE" ] && prev_tx=$(cat "$TX_FILE") || prev_tx=$tx

# Compute delta
delta_rx=$((rx - prev_rx))
delta_tx=$((tx - prev_tx))

# Save current values for next run
echo $rx > "$RX_FILE"
echo $tx > "$TX_FILE"

# Print both on the same line, human-readable
printf "%s / %s" \
  "$(numfmt --to=iec <<< "$delta_rx")B RX" \
  "$(numfmt --to=iec <<< "$delta_tx")B TX"