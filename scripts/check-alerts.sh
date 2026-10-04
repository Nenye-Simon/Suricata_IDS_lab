#!/usr/bin/env bash
set -euo pipefail
FAST_LOG="${FAST_LOG:-/var/log/suricata/fast.log}"
EVE_LOG="${EVE_LOG:-/var/log/suricata/eve.json}"
PATTERN="${1:-LAB TCP connection to port 9999}"
found=0
if [[ -r "$FAST_LOG" ]]; then
  echo "fast.log:"
  if grep -F "$PATTERN" "$FAST_LOG"; then found=1; else echo "No matching line."; fi
else echo "Missing/unreadable: $FAST_LOG"; fi
if [[ -r "$EVE_LOG" ]] && command -v jq >/dev/null 2>&1; then
  echo "eve.json:"
  if jq -c --arg p "$PATTERN" 'select(.event_type=="alert" and ((.alert.signature // "") | contains($p)))' "$EVE_LOG"; then found=1; else echo "No matching EVE alert."; fi
else echo "EVE log unavailable/unreadable or jq missing."; fi
if [[ "$found" -eq 0 ]]; then echo "No matching alert; check rule, interface, traffic, and logging."; exit 1; fi
