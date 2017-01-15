#!/bin/sh
#ip addr add ${VPN_IP}/${SUBNET} dev ${VPN_IF}
ip addr add ${BRIDGE_IP}/${SUBNET} dev ${BRIDGE_IF}
