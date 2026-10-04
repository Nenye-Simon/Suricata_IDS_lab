#!/usr/bin/env bash
set -euo pipefail
CONFIG="${1:-/etc/suricata/suricata.yaml}"
command -v suricata >/dev/null || { echo "Suricata not installed" >&2; exit 127; }
[[ -r "$CONFIG" ]] || { echo "Cannot read config: $CONFIG" >&2; exit 2; }
echo "Testing $CONFIG"
sudo suricata -T -c "$CONFIG"
