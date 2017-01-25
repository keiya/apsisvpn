# Related project

- rendezvous-hub (server-side) https://github.com/keiya/rendezvous-hub
- anoncontainer (network sandboxing) https://github.com/keiya/anoncontainer

# Prerequisites
- `apt install bridge-utils` or `yum install bridge-utils`
- `apt install iptables`
- `gem install bundler`

# config.yml sample

```
hub:
  url: http://apsis-exchange-hub
exchanger:
  vpntype: tinc
tinc:
  dir: /usr/local/etc/tinc
  exitif: eth0
  bindaddr: 0.0.0.0
  bindport: 10000
dockerrunner:
  command: python /path/to/anoncontainer/apsis.py
```
# Installation
```
bundle install
```

# Run
```
sudo bundle exec ruby client.rb 33dadd3c345c /bin/bash ; sudo bash rm-nets.sh
```

# VPN Modules
## Tinc VPN
### Firewall Setup
```
iptables -A INPUT -m state --state NEW -p udp --dport 655 -j ACCEPT
iptables -A INPUT -p tcp --dport 655 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 655 -m state --state ESTABLISHED -j ACCEPT
```
