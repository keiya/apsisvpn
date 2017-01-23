#!/bin/sh

source '/tmp/tinc-script-vars'
iptables=/sbin/iptables

# bridge
ip addr del ${BRIDGE_IP}/${SUBNET} dev ${VPN_IF}
ip link delete ${BRIDGE_IF} type bridge

$iptables -t nat -D POSTROUTING -s ${NETWORK}/${SUBNET} -o ${EXIT_IF} -j MASQUERADE

# from/to VPN tap
$iptables -D INPUT -i ${VPN_IF} -j ACCEPT
$iptables -D OUTPUT -o ${VPN_IF} -j ACCEPT

# stateful filtering for br -> container
$iptables -D FORWARD -m state --state NEW -d ${CONTAINER_IP} -i ${BRIDGE_IF} -j DROP
$iptables -D FORWARD -m state --state NEW,ESTABLISHED,RELATED -s ${CONTAINER_IP} -i ${BRIDGE_IF} -j ACCEPT
$iptables -D FORWARD -m state --state ESTABLISHED,RELATED -d ${CONTAINER_IP} -o ${BRIDGE_IF} -j ACCEPT

# allow for pair ip from vpn -> br -> eth0 
$iptables -D FORWARD -s ${PAIR_CONTAINER_IP} -i ${BRIDGE_IF} -o ${EXIT_IF} -j ACCEPT
$iptables -D FORWARD -d ${PAIR_CONTAINER_IP} -o ${BRIDGE_IF} -i ${EXIT_IF} -j ACCEPT
$iptables -D FORWARD -s ${PAIR_CONTAINER_IP} -i ${BRIDGE_IF} ! -o ${EXIT_IF} -j DROP
$iptables -D FORWARD -d ${PAIR_CONTAINER_IP} -o ${BRIDGE_IF} ! -i ${EXIT_IF} -j DROP
