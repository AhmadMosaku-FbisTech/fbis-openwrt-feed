#!/bin/sh
# Handle USSD requests via ModemManager (dynamic SIM control)

MODEM=$(mmcli -L | awk '/Modem/ {print $1; exit}' | cut -d: -f2)

if [ -z "$MODEM" ]; then
    echo "No modem found"
    exit 1
fi

CMD=$1
if [ -z "$CMD" ]; then
    echo "Usage: $0 '*USSD_CODE#'"
    exit 1
fi

echo "[fbis] Sending USSD: $CMD"
mmcli -m "$MODEM" --command="$CMD"
if [ $? -ne 0 ]; then
    echo "Failed to send USSD command"
    exit 1
fi