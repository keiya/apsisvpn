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
