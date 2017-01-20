#!/bin/sh

iptables=/sbin/iptables

# bridge
ip link add name ${BRIDGE_IF} type bridge && echo "br" > /tmp/apsisuplog
ip link set dev ${BRIDGE_IF} up && echo "brup" >> /tmp/apsisuplog
#ip addr add 0.0.0.0 dev ${VPN_IF} && echo "3" >> /tmp/tincuplog
#ip link set dev ${VPN_IF} promisc on && echo "4" >> /tmp/tincuplog
#ip link set dev ${VPN_IF} up && echo "5" >> /tmp/tincuplog
ip link set dev ${VPN_IF} master ${BRIDGE_IF} && echo "6" >> /tmp/apsisuplog

# set ip for vpn tun
#ip addr add ${ROUTER_IP}/${SUBNET} dev ${VPN_IF} && echo "1" >> /tmp/apsisuplog
ip link set dev ${VPN_IF} up && echo "up" >> /tmp/apsisuplog

# VPN Bridge
ip addr add ${BRIDGE_IP}/${SUBNET} dev ${BRIDGE_IF} && echo "2" >> /tmp/apsisuplog

# Gateway configuration for routing pair user's traffic
$iptables -t nat -I POSTROUTING -s ${NETWORK}/${SUBNET} -o ${MASQ_IF} -j MASQUERADE && echo "3" >> /tmp/apsisuplog
#$iptables -A INPUT -m physdev --physdev-in ${VPN_IF} -d ${CONTAINER_IP} -j DROP
