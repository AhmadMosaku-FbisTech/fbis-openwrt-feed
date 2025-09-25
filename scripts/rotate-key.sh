#!/bin/bash
set -euo pipefail
# rotate-key.sh <suffix> <github-owner/repo> <github-token>
# Example: ./rotate-key.sh 20250923 myorg/fbis-openwrt-feed ghp_xxx

if [ $# -ne 3 ]; then
  echo "Usage: $0 <suffix> <owner/repo> <github-token>"
  exit 1
fi

SUFFIX="$1"
REPO="$2"
TOKEN="$3"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY_DIR="$REPO_DIR/gpg/keys"
mkdir -p "$KEY_DIR"

NAME="FBIS Firmware Feed"
EMAIL="firmware@fbis.local"
KEY_ID="fbis-feed-${SUFFIX}"

echo "[FBIS] Generating new GPG key ${KEY_ID}..."
cat > /tmp/gpg-batch <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: ${NAME}
Name-Email: ${EMAIL}
Expire-Date: 0
%commit
EOF

gpg --batch --generate-key /tmp/gpg-batch
rm -f /tmp/gpg-batch

# get fingerprint of last secret key
FPR=$(gpg --list-secret-keys --with-colons | awk -F: '/^sec/ {print $5}' | tail -n1)
if [ -z "$FPR" ]; then
  echo "Failed to get new key fingerprint"
  exit 2
fi

PUB_FILE="$KEY_DIR/${KEY_ID}.pub"
PRIV_TMP="$REPO_DIR/gpg/${KEY_ID}.priv"

gpg --armor --export "$FPR" > "$PUB_FILE"
gpg --armor --export-secret-keys "$FPR" > "$PRIV_TMP"

echo "[FBIS] Exported pub: $PUB_FILE"

# prepare index.html
echo "[FBIS] Regenerating index.html..."
(
  echo "<html><body><h1>FBIS Feed Keys</h1><ul>"
  for f in "$KEY_DIR"/*.pub; do
    [ -e "$f" ] || continue
    fn=$(basename "$f")
    echo "<li><a href=\"$fn\">$fn</a></li>"
  done
  echo "</ul></body></html>"
) > "$KEY_DIR/index.html"

# push pub and index
git add "$KEY_DIR"/*.pub "$KEY_DIR/index.html"
git commit -m "chore: rotate signing key ${KEY_ID}"
git push origin main

# Update GitHub secret FEED_GPG_PRIVATE_KEY (encrypted with repo public key)
echo "[FBIS] Updating GitHub Actions secret (FEED_GPG_PRIVATE_KEY)..."

API="https://api.github.com/repos/${REPO}"
REPO_KEY_JSON=$(curl -s -H "Authorization: token ${TOKEN}" "${API}/actions/secrets/public-key")
KEY_ID_JSON=$(echo "$REPO_KEY_JSON" | jq -r .key_id)
REPO_PUBKEY=$(echo "$REPO_KEY_JSON" | jq -r .key)

if [ -z "$KEY_ID_JSON" ] || [ -z "$REPO_PUBKEY" ]; then
  echo "Failed to fetch repo public key"
  exit 3
fi

# Read private key content
PRIV_CONTENT=$(cat "$PRIV_TMP")

# Use Python + nacl to encrypt the secret (GitHub expects libsodium sealed box)
ENC_VALUE=$(python3 - <<PY
import sys,base64
from nacl import public
repo_key_b64 = "${REPO_PUBKEY}"
repo_key = base64.b64decode(repo_key_b64)
pk = public.PublicKey(repo_key)
sealed_box = public.SealedBox(pk)
enc = sealed_box.encrypt(bytes("""${PRIV_CONTENT}""","utf-8"))
print(base64.b64encode(enc).decode('utf-8'))
PY
)

# PUT secret
curl -s -X PUT -H "Authorization: token ${TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"encrypted_value\":\"${ENC_VALUE}\",\"key_id\":\"${KEY_ID_JSON}\"" \
  "${API}/actions/secrets/FEED_GPG_PRIVATE_KEY" >/dev/null

echo "[FBIS] Secret updated."

# cleanup private material locally
shred -u "$PRIV_TMP" || rm -f "$PRIV_TMP"
# remove private secret key from local gpg keyring (to avoid local leakage)
gpg --batch --yes --delete-secret-keys "$FPR" || true

echo "[FBIS] Rotation done. New pub pushed and secret updated."
