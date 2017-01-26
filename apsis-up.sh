#!/bin/sh

iptables=/sbin/iptables

# bridge
ip link add name ${BRIDGE_IF} type bridge
ip link set dev ${BRIDGE_IF} up
ip link set dev ${VPN_IF} master ${BRIDGE_IF}

# set ip for vpn tun
ip link set dev ${VPN_IF} up

# VPN Bridge
ip addr add ${BRIDGE_IP}/${SUBNET} dev ${BRIDGE_IF}

# Gateway configuration for routing pair user's traffic
$iptables -t nat -I POSTROUTING -s ${NETWORK}/${SUBNET} -o ${EXIT_IF} -j MASQUERADE

# from/to VPN tap
$iptables -A INPUT -i ${VPN_IF} -j ACCEPT
$iptables -A OUTPUT -o ${VPN_IF} -j ACCEPT

# stateful filtering for br -> container
$iptables -A FORWARD -m state --state NEW -d ${CONTAINER_IP} -i ${BRIDGE_IF} -j DROP
$iptables -A FORWARD -m state --state NEW,ESTABLISHED,RELATED -s ${CONTAINER_IP} -i ${BRIDGE_IF} -j ACCEPT
$iptables -A FORWARD -m state --state ESTABLISHED,RELATED -d ${CONTAINER_IP} -o ${BRIDGE_IF} -j ACCEPT

# allow for pair ip from vpn -> br -> eth0 
$iptables -A FORWARD -s ${PAIR_CONTAINER_IP} -i ${BRIDGE_IF} -o ${EXIT_IF} -j ACCEPT
$iptables -A FORWARD -d ${PAIR_CONTAINER_IP} -o ${BRIDGE_IF} -i ${EXIT_IF} -j ACCEPT
$iptables -A FORWARD -s ${NETWORK}/${SUBNET} -i ${BRIDGE_IF} ! -o ${EXIT_IF} -j DROP
$iptables -A FORWARD -d ${NETWORK}/${SUBNET} -o ${BRIDGE_IF} ! -i ${EXIT_IF} -j DROP

# block br -> host
$iptables -A INPUT -s ${NETWORK}/${SUBNET} -i ${BRIDGE_IF} -j DROP
$iptables -A OUTPUT -d ${NETWORK}/${SUBNET} -o ${BRIDGE_IF} -j DROP

# block private ip
$iptables -A FORWARD -s ${NETWORK}/${SUBNET} -i ${BRIDGE_IF} -o ${EXIT_IF} -d 10.0.0.0/8 -j DROP
$iptables -A FORWARD -s ${NETWORK}/${SUBNET} -i ${BRIDGE_IF} -o ${EXIT_IF} -d 176.16.0.0/12 -j DROP
$iptables -A FORWARD -s ${NETWORK}/${SUBNET} -i ${BRIDGE_IF} -o ${EXIT_IF} -d 192.168.0.0/16 -j DROP
$iptables -A FORWARD -s ${NETWORK}/${SUBNET} -i ${BRIDGE_IF} -o ${EXIT_IF} -d 127.0.0.0/8 -j DROP
