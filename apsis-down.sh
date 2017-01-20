#!/bin/sh

source '/tmp/tinc-script-vars'
iptables=/sbin/iptables

# bridge
ip addr del ${BRIDGE_IP}/${SUBNET} dev ${VPN_IF}
ip link delete ${BRIDGE_IF} type bridge

#$iptables -D INPUT -d ${CONTAINER_IP} -i ${VPN_IF} -j DROP
