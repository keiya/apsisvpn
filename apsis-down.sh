#!/bin/sh
ip addr del ${BRIDGE_IP}/${SUBNET} dev ${BRIDGE_IF}
