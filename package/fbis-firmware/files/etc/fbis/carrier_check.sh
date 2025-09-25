#!/bin/sh
# carrier_check.sh - check IMSI and allow/deny forwarding (uses mmcli)
MODEM_INDEX=0
ALLOWED_CARRIER_PREFIX="6230"   # example prefix — set to your carrier IDs
LOG_TAG="[FBIS-carrier]"

imsi=$(mmcli -m ${MODEM_INDEX} --command="AT+CIMI" 2>/dev/null | tr -d '\r\n ')

if [ -z "$imsi" ]; then
  logger -t $LOG_TAG "Failed to read IMSI"
  exit 1
fi

carrier_id="$(echo $imsi | cut -c1-4)"

logger -t $LOG_TAG "IMSI=$imsi carrier_id=$carrier_id"

if echo "$carrier_id" | grep -q "^${ALLOWED_CARRIER_PREFIX}"; then
  logger -t $LOG_TAG "Carrier allowed"
  /etc/fbis/iptables_rules.sh allow
else
  logger -t $LOG_TAG "Carrier denied"
  /etc/fbis/iptables_rules.sh deny
fi
