#!/bin/sh
# vpn_setup.sh - simplistic WireGuard bringup helper
WG_IF="wg0"
WG_CONF="/etc/wireguard/${WG_IF}.conf"
LOG_TAG="[FBIS-vpn]"

if [ -f "$WG_CONF" ]; then
  logger -t $LOG_TAG "Bringing up $WG_IF"
  wg-quick up $WG_IF && logger -t $LOG_TAG "VPN up" || logger -t $LOG_TAG "VPN failed"
else
  logger -t $LOG_TAG "No WireGuard config at $WG_CONF"
fi
