# Test procedure
Start `nc -lvnp 9999` on the sensor, run Suricata on `<INTERFACE>`, then from the client run `printf 'SURICATA-LAB-HELLO\n' | nc -v <SURICATA_IP> 9999`. Confirm the banner and inspect logs for SID 1000001. Listener is on destination; rule matches SYN, not banner.
