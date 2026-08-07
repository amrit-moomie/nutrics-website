#!/usr/bin/env bash
# set-investors-passcode.sh — Create or rotate the passcode that gates
# /investors.html (see scripts/deploy.sh for the nginx auth_basic block).
#
# The hash is written straight to the EC2 box and never touches this repo
# (which is public) or git history. Deploys are safe to re-run afterwards -
# deploy.sh doesn't touch this file.
#
# Usage:
#   ./scripts/set-investors-passcode.sh            # prompts, generates a random 8-digit code
#   ./scripts/set-investors-passcode.sh 64351031    # sets a specific passcode

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PEM_KEY="${NUTRICS_PEM:-$REPO/../nutrics/.pvt/nutrics-n2026.pem}"
EC2_USER="ec2-user"
EC2_HOST="15.223.48.150"
SSH_OPTS="-i $PEM_KEY -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
REMOTE_FILE="/etc/nginx/.htpasswd-investors"
AUTH_USER="investor" # fixed, non-secret - only the passcode is meant to be shared

if [ ! -f "$PEM_KEY" ]; then
  echo "Missing PEM key at $PEM_KEY - set NUTRICS_PEM to its location." >&2
  exit 1
fi

PASSCODE="${1:-}"
if [ -z "$PASSCODE" ]; then
  PASSCODE="$(python3 -c 'import secrets; print(secrets.randbelow(90000000)+10000000)')"
  echo "Generated passcode: $PASSCODE"
fi

if ! [[ "$PASSCODE" =~ ^[0-9]{8}$ ]]; then
  echo "Passcode must be exactly 8 digits, got: $PASSCODE" >&2
  exit 1
fi

HASH="$(openssl passwd -apr1 "$PASSCODE")"

ssh $SSH_OPTS "$EC2_USER@$EC2_HOST" \
  "echo '$AUTH_USER:$HASH' | sudo tee $REMOTE_FILE > /dev/null && \
   sudo chown root:root $REMOTE_FILE && sudo chmod 644 $REMOTE_FILE && \
   sudo nginx -t && sudo systemctl reload nginx"

echo ""
echo "====================================="
echo "  /investors.html is now gated."
echo "  Browser login prompt username: $AUTH_USER"
echo "  Passcode: $PASSCODE"
echo "====================================="
