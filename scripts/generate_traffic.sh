#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then echo "Usage: $0 <SURICATA_IP> [PORT]" >&2; exit 2; fi
TARGET="$1"; PORT="${2:-9999}"
printf 'SURICATA-LAB-HELLO\\n' | nc -v "$TARGET" "$PORT"
