#!/bin/sh
#ip addr del ${VPN_IP}/${SUBNET} dev ${VPN_IF}
ip addr del ${BRIDGE_IP}/${SUBNET} dev ${BRIDGE_IF}
