# Related project

- rendezvous-hub (server-side) https://github.com/keiya/rendezvous-hub
- anoncontainer (network sandboxing) https://github.com/keiya/anoncontainer

# Prerequisites
- `apt install bridge-utils` or `yum install bridge-utils`
- `apt install iptables`

# config.yml sample

```
hub:
  url: http://apsis-exchange-hub
tinc:
  dir: /usr/local/etc/tinc/ipex/hosts
dockerrunner:
  command: python /path/to/anoncontainer/apsis.py
```

# VPN Modules
## Tinc VPN
### Firewall Setup
```
iptables -A INPUT -m state --state NEW -p udp --dport 655 -j ACCEPT
iptables -A INPUT -p tcp --dport 655 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 655 -m state --state ESTABLISHED -j ACCEPT
```
