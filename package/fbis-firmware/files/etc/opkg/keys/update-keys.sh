#!/bin/sh
set -euo pipefail

KEYDIR="/etc/opkg/keys"
TMPDIR="$(mktemp -d /tmp/fbis-keys-XXXX)"
KEYURL="https://AhmadMosaku-FbisTech.github.io/https://github.com/AhmadMosaku-FbisTech/fbis-openwrt-feed.git/gpg/keys"
INDEX_URL="$KEYURL/index.html"
BACKUP_DIR="/etc/opkg/keys.bak"
LOG_PREFIX="[FBIS-keys]"

mkdir -p "$KEYDIR" "$BACKUP_DIR"

echo "$LOG_PREFIX Updating FBIS public keys from $KEYURL ..."

IDX="$TMPDIR/index.html"
if ! wget -q -O "$IDX" "$INDEX_URL"; then
    echo "$LOG_PREFIX ERROR: failed to download $INDEX_URL"
    rm -rf "$TMPDIR"
    exit 1
fi

PUBS=$(grep -o 'href="[^\"]*\.pub"' "$IDX" | sed 's/href="//; s/"$//')
if [ -z "$PUBS" ]; then
    echo "$LOG_PREFIX WARNING: no .pub keys found at $INDEX_URL"
    rm -rf "$TMPDIR"
    exit 0
fi

STAGE="$TMPDIR/stage"
mkdir -p "$STAGE"

VALID_COUNT=0
for keyfile in $PUBS; do
    KEY_URL="$KEYURL/$keyfile"
    TMP_KEY="$TMPDIR/$(basename "$keyfile")"
    echo "$LOG_PREFIX Downloading $keyfile ..."
    if ! wget -q -O "$TMP_KEY" "$KEY_URL"; then
        echo "$LOG_PREFIX WARN: failed to download $KEY_URL — skipping"
        continue
    fi

    if [ ! -s "$TMP_KEY" ]; then
        echo "$LOG_PREFIX WARN: $keyfile empty — skipping"
        rm -f "$TMP_KEY"
        continue
    fi
    if ! grep -q "-----BEGIN PGP PUBLIC KEY BLOCK-----" "$TMP_KEY"; then
        echo "$LOG_PREFIX WARN: $keyfile missing header — skipping"
        rm -f "$TMP_KEY"
        continue
    fi
    if ! grep -q "-----END PGP PUBLIC KEY BLOCK-----" "$TMP_KEY"; then
        echo "$LOG_PREFIX WARN: $keyfile missing footer — skipping"
        rm -f "$TMP_KEY"
        continue
    fi

    if command -v gpg >/dev/null 2>&1; then
        TEST_KEYRING="$TMPDIR/test-keyring.gpg"
        rm -f "$TEST_KEYRING"
        if gpg --no-default-keyring --keyring "$TEST_KEYRING" --import "$TMP_KEY" >/dev/null 2>&1; then
            if gpg --no-default-keyring --keyring "$TEST_KEYRING" --list-keys >/dev/null 2>&1; then
                mv "$TMP_KEY" "$STAGE/$(basename "$keyfile")"
                VALID_COUNT=$((VALID_COUNT+1))
            else
                echo "$LOG_PREFIX WARN: import/list failed for $keyfile — skipping"
            fi
        else
            echo "$LOG_PREFIX WARN: gpg import failed for $keyfile — skipping"
        fi
        rm -f "$TEST_KEYRING"
    else
        mv "$TMP_KEY" "$STAGE/$(basename "$keyfile")"
        VALID_COUNT=$((VALID_COUNT+1))
    fi
done

if [ "$VALID_COUNT" -eq 0 ]; then
    echo "$LOG_PREFIX WARNING: no valid keys found — leaving existing keys intact"
    rm -rf "$TMPDIR"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR/$TS"
cp -a "$KEYDIR/"* "$BACKUP_DIR/$TS/" 2>/dev/null || true

# delete only .pub files
for f in "$KEYDIR"/*.pub; do
    [ -e "$f" ] && rm -f "$f"
done

for k in "$STAGE"/*.pub; do
    [ -e "$k" ] || continue
    install -m 0644 "$k" "$KEYDIR/$(basename "$k")"
    echo "$LOG_PREFIX Installed $(basename "$k")"
done

rm -rf "$TMPDIR"
echo "$LOG_PREFIX Done. Installed $VALID_COUNT key(s)."
exit 0
