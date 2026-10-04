# Suricata IDS Practical Lab: Detecting TCP Connections with Netcat

**Scope:** Authorized, isolated lab only. This is an IDS alerting exercise; it does not block traffic.

## 1. Overview and learning objectives
Install and validate Suricata, identify the sensor interface, load a local signature, generate a TCP connection with Netcat, and investigate alerts in `fast.log` and `eve.json`.

By the end, you can identify interfaces/IPs, explain a rule's fields, run a controlled test, parse alert records, and document findings.

## 2. Environment and topology
```text
Client VM (<CLIENT_IP>) ---- private host-only/internal network ---- Sensor VM (<SURICATA_IP>)
                                                               Suricata monitors <INTERFACE>
```
Use two Linux VMs on the same isolated virtual network. A one-VM self-test is possible but does not verify sensor visibility between hosts.

**Placeholders:** `<SURICATA_IP>` sensor lab IPv4; `<CLIENT_IP>` client lab IPv4; `<INTERFACE>` sensor lab NIC (e.g. `eth0`, `ens33`, `enp0s8`); `<PORT>` defaults to `9999`. Replace them with real values and omit angle brackets in commands.

## 3. Prerequisites
- Kali/Debian/Ubuntu Linux VMs, same host-only/internal network.
- Sudo access on sensor; network access for package installation.
- Netcat on client and `jq` on sensor.
- Basic terminal knowledge. Use only systems you own or are explicitly authorized to test.

## 4. Identify interfaces and addresses
Run on both VMs:
```bash
ip -br address
ip route
```
`ip -br address` summarizes interfaces and addresses; `ip route` shows routing decisions. On the sensor:
```bash
ip -br link
ip -4 addr show dev <INTERFACE>
ip route get <CLIENT_IP>
```
These help identify the lab NIC and route toward the client. Check reachability from client:
```bash
ping -c 3 <SURICATA_IP>
```
A failed ping alone does not prove TCP is unavailable; ICMP may be filtered.

## 5. Install Suricata
On the sensor:
```bash
sudo apt update
sudo apt install -y suricata jq
suricata --build-info
```
The first command refreshes package metadata; the second installs Suricata and the JSON parser; the third confirms the executable/build information.
```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```
`-T` tests configuration and rule loading without starting packet capture. Resolve errors before continuing.

## 6. Configure the custom rule
Place this line in the active `local.rules` file:
```suricata
alert tcp any any -> $HOME_NET 9999 (msg:"LAB TCP connection to port 9999"; flags:S; flow:stateless; sid:1000001; rev:1;)
```
Rule explanation: `alert` logs but does not block; `tcp` selects protocol; `any any` matches any source; `-> $HOME_NET 9999` targets port 9999 on a protected network; `flags:S` matches SYN packets; `flow:stateless` does not require established flow state; `sid` is the unique signature ID; `rev` is the rule revision.

Inspect active configuration:
```bash
sudo grep -nE 'HOME_NET|default-rule-path|rule-files|local.rules' /etc/suricata/suricata.yaml
```
Ensure `local.rules` is included under `rule-files`, its path matches `default-rule-path`, and `HOME_NET` includes the sensor lab address/subnet. Configuration layout varies by version/distribution. Do not replace the full system YAML with the partial example in `config/`.
```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```
A successful test reports configuration/rules loaded without fatal errors.

## 7. Generate Netcat traffic
On the **sensor** (destination), start a listener:
```bash
nc -lvnp 9999
```
This listens on TCP port 9999. Netcat syntax varies; try `nc -l 9999` if needed. In a second sensor terminal, start Suricata:
```bash
sudo suricata -c /etc/suricata/suricata.yaml -i <INTERFACE>
```
It runs in the foreground; keep it open. From the **client**:
```bash
printf 'SURICATA-LAB-HELLO\n' | nc -v <SURICATA_IP> 9999
```
The client connects to the sensor and sends a harmless banner. The listener should display it. Do not run a second manual Suricata process if the service is already capturing on that interface.

Optional helper from the project root:
```bash
bash scripts/generate_traffic.sh <SURICATA_IP> 9999
```

## 8. Trigger and analyze alerts
The rule detects the TCP SYN attempt to destination port 9999; it does not inspect the banner text. On sensor:
```bash
sudo tail -n 20 /var/log/suricata/fast.log
sudo grep 'LAB TCP connection to port 9999' /var/log/suricata/fast.log
```
`tail` shows recent records; `grep` filters the matching signature. Example shape (values are illustrative):
```text
10/03/2026-12:00:00.000000 [**] [1:1000001:1] LAB TCP connection to port 9999 [**] {TCP} 192.168.56.20:49152 -> 192.168.56.10:9999
```
Parse EVE JSON:
```bash
sudo jq 'select(.event_type=="alert") | {timestamp,src_ip,src_port,dest_ip,dest_port,proto,signature:.alert.signature}' /var/log/suricata/eve.json
```
`eve.json` is structured event output; `jq` selects alert events and prints useful fields. No output may mean no new matching alert, alert logging disabled, or a different log path.
```bash
sudo jq -r 'select(.event_type=="alert") | [.timestamp,.src_ip,.src_port,.dest_ip,.dest_port,.alert.signature] | @tsv' /var/log/suricata/eve.json
```
This produces tab-separated alert details suitable for quick review.

## 9. Service mode (optional)
```bash
sudo systemctl status suricata --no-pager
sudo journalctl -u suricata -n 50 --no-pager
```
These inspect service state and recent service logs. Service interface settings differ by distribution. Use either service capture or a manual foreground instance, not both on the same interface.

## 10. Troubleshooting
| Error/symptom | Checks and fixes |
|---|---|
| `No route to host` | Compare `ip -br address` and `ip route` on both VMs; ensure adapters share the same private virtual network and are up; verify target IP. |
| `Connection refused` | Listener is absent/stopped or target port/IP is wrong. Start `nc -lvnp 9999` on destination; check `ss -lntp \| grep 9999`. |
| Wrong interface/no packets | Use `ip -br address`, `ip route get <CLIENT_IP>`, and optionally `sudo tcpdump -ni <INTERFACE> tcp port 9999`. |
| Missing alerts | Validate config; check rule inclusion, HOME_NET, rule direction/port, interface, log path and EVE alert setting; generate fresh traffic after Suricata starts. |
| Rule file not found | Inspect `default-rule-path` and `rule-files`; place the rule in the configured path. |
| Duplicate process/address busy | Check `pgrep -a suricata` and service status; stop one capture instance cleanly. |

## 11. Verification checklist
- [ ] VMs use the intended isolated network.
- [ ] Sensor/client IPs and sensor interface recorded.
- [ ] Suricata installed and build info displayed.
- [ ] Configuration test passes.
- [ ] `local.rules` loaded and HOME_NET is appropriate.
- [ ] Listener is active on destination TCP/9999.
- [ ] Suricata monitors the correct interface.
- [ ] Client banner reaches listener.
- [ ] Matching alert appears in fast.log.
- [ ] Matching alert fields are parsed from eve.json.
- [ ] Real, sanitized evidence is saved.

## 12. Student questions
1. How does IDS alerting differ from IPS blocking?
2. What do `sid` and `rev` mean?
3. What source/destination IPs and ports appear in your alert?
4. Why can a SYN alert occur before application data is sent?
5. How do fast.log and eve.json differ?
6. Why might a sensor miss traffic that reaches the destination?
7. How would you adapt the rule to another port?

## 13. Practical challenge
Create a second rule for TCP SYN attempts to port 10000 using a new unique SID. Start a listener on that port, generate a client connection, and verify the alert in both logs. Submit the rule, traffic command, sanitized alert, parsed EVE fields, and a brief explanation of interface/rule verification.

## GitHub project structure
```text
Suricata_IDS_Detection_Lab/
├── README.md
├── suricata/README.md
│   └── rules/README.md, local.rules
├── tests/README.md
├── evidence/README.md
├── results/README.md, alert-analysis.md, troubleshooting.md
├── docs/README.md, lab-report.md
├── scripts/README.md, validate-suricata.sh, check-alerts.sh, generate_traffic.sh
├── git-workflow/README.md
├── config/suricata.yaml.example
├── examples/sample-alert.json
└── .gitignore
```

Sample output is illustrative, not proof of a completed run. Replace it with your own sanitized evidence before publishing.
