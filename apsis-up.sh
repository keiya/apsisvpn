#!/bin/sh

iptables=/sbin/iptables

# bridge
ip link add name ${BRIDGE_IF} type bridge
ip link set dev ${BRIDGE_IF} up
#ip addr add 0.0.0.0 dev ${VPN_IF}
#ip link set dev ${VPN_IF} promisc on
#ip link set dev ${VPN_IF} up
ip link set dev ${VPN_IF} master ${BRIDGE_IF}

# set ip for vpn tun
#ip addr add ${ROUTER_IP}/${SUBNET} dev ${VPN_IF}
ip link set dev ${VPN_IF} up

# VPN Bridge
ip addr add ${BRIDGE_IP}/${SUBNET} dev ${BRIDGE_IF}

# Gateway configuration for routing pair user's traffic
$iptables -t nat -I POSTROUTING -s ${NETWORK}/${SUBNET} -o ${MASQ_IF} -j MASQUERADE

# from/to VPN tap
$iptables -A INPUT -i ${VPN_IF} -j ACCEPT
$iptables -A OUTPUT -o ${VPN_IF} -j ACCEPT

# stateful filtering for br -> container
$iptables -A FORWARD -m state --state NEW -d ${CONTAINER_IP} -i ${BRIDGE_IF} -j DROP
$iptables -A FORWARD -m state --state NEW,ESTABLISHED,RELATED -s ${CONTAINER_IP} -i ${BRIDGE_IF} -j ACCEPT
$iptables -A FORWARD -m state --state ESTABLISHED,RELATED -d ${CONTAINER_IP} -o ${BRIDGE_IF} -j ACCEPT

# allow for pair ip from vpn -> br -> eth0 
$iptables -A FORWARD -s 10.0.77.4 -i ${BRIDGE_IF} -o eth0 -j ACCEPT
$iptables -A FORWARD -d 10.0.77.4 -o ${BRIDGE_IF} -i eth0 -j ACCEPT
$iptables -A FORWARD -s 10.0.77.4 -i ${BRIDGE_IF} ! -o eth0 -j DROP
$iptables -A FORWARD -d 10.0.77.4 -o ${BRIDGE_IF} ! -i eth0 -j DROP
