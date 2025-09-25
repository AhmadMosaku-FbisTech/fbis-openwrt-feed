#!/usr/bin/env python3
import subprocess, time, logging

logging.basicConfig(level=logging.INFO)
WG_IF = "wg0"

def is_up():
    try:
        out = subprocess.check_output(["wg", "show", WG_IF])
        return True
    except Exception:
        return False

def ensure_up():
    if not is_up():
        logging.info("WireGuard down, attempting up")
        subprocess.call(["wg-quick", "up", WG_IF])

if __name__ == "__main__":
    while True:
        ensure_up()
        time.sleep(60)
