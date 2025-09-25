#!/usr/bin/env python3
# fbisd.py - minimal digital twin synchronizer

import time
import json
import subprocess
import requests
import os
import logging

SERVER_URL = os.getenv("FBIS_SERVER_URL", "https://central.fbis.io/sync")
ROUTER_TOKEN_FILE = "/etc/fbis/router_id.token"
LOG = "/var/log/fbisd.log"

logging.basicConfig(filename=LOG, level=logging.INFO, format="%(asctime)s %(message)s")

def read_token():
    try:
        with open(ROUTER_TOKEN_FILE, "r") as f:
            return f.read().strip()
    except Exception as e:
        logging.error("Cannot read router token: %s", e)
        return None

def collect_state():
    state = {}
    try:
        imsi = subprocess.check_output(["mmcli", "-m", "0", "--command=AT+CIMI"]).decode().strip()
    except Exception:
        imsi = ""
    try:
        vpn_status = subprocess.check_output(["wg", "show"]).decode()
    except Exception:
        vpn_status = ""
    try:
        iptables = subprocess.check_output(["iptables", "-L", "FORWARD"]).decode()
    except Exception:
        iptables = ""
    state.update({
        "imsi": imsi,
        "vpn_status": vpn_status,
        "iptables": iptables,
    })
    return state

def sync():
    token = read_token()
    if not token:
        logging.warning("No router token, skipping sync")
        return
    payload = {
        "router_token": token,
        "state": collect_state()
    }
    try:
        r = requests.post(SERVER_URL, json=payload, timeout=10, verify=True)
        logging.info("Sync status: %s", r.status_code)
    except Exception as e:
        logging.error("Sync failed: %s", e)

def main():
    while True:
        sync()
        time.sleep(30)

if __name__ == "__main__":
    main()
