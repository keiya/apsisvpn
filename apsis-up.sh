#!/bin/sh

# VPN Bridge
ip addr add ${BRIDGE_IP}/${SUBNET} dev ${BRIDGE_IF}

# Gateway configuration for routing pair user's traffic
iptables -t nat -I POSTROUTING -s 10.0.77.0/24 -o eth0 -j MASQUERADE
