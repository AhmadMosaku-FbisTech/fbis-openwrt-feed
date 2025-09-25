#!/bin/sh
# iptables_rules.sh - allow/deny forwarding
ACTION="$1"
LOG_TAG="[FBIS-iptables]"

case "$ACTION" in
  allow)
    iptables -D FORWARD -j DROP 2>/dev/null || true
    logger -t $LOG_TAG "Allowing forwarding"
    ;;
  deny)
    iptables -I FORWARD -j DROP 2>/dev/null || true
    logger -t $LOG_TAG "Blocking forwarding"
    ;;
  *)
    echo "Usage: $0 {allow|deny}"
    exit 2
    ;;
esac
