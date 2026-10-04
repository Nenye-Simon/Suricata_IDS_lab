# Troubleshooting
| Symptom | Checks |
|---|---|
| No route to host | Compare `ip -br address` and `ip route`; confirm same private VM network and interfaces up. |
| Connection refused | Start listener on destination; check `ss -lntp \| grep 9999`; verify target. |
| Wrong interface | Check `ip -br address`, `ip route get <CLIENT_IP>`, optionally `tcpdump -ni <INTERFACE> tcp port 9999`. |
| Missing alerts | Test config; confirm rule loaded, HOME_NET/direction/port, interface, log settings, and fresh traffic. |
| Rule not found | Check default-rule-path and rule-files. |
| Duplicate process | Check `pgrep -a suricata` and service status; avoid simultaneous capture instances. |
