# Command Cheat Sheet

```bash
ip -br address
ip route
sudo apt update
sudo apt install -y suricata jq
sudo suricata -T -c /etc/suricata/suricata.yaml
nc -lvnp 9999
sudo suricata -c /etc/suricata/suricata.yaml -i <INTERFACE>
printf 'SURICATA-LAB-HELLO\\n' | nc -v <SURICATA_IP> 9999
sudo tail -n 20 /var/log/suricata/fast.log
sudo jq 'select(.event_type=="alert") | {timestamp,src_ip,src_port,dest_ip,dest_port,signature:.alert.signature}' /var/log/suricata/eve.json
```
