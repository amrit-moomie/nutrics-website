#!/usr/bin/env bash
# deploy.sh — Deploy the Nutrics marketing site (static HTML/CSS/assets) to the
# shared Nutrics EC2 box (Amazon Linux 2023).
# Usage: ./scripts/deploy.sh
# Prerequisites:
#   - PEM key at ../nutrics/.pvt/nutrics-n2026.pem (override with NUTRICS_PEM).
#   - nutrics.ca and www.nutrics.ca A records pointing at $EC2_HOST, or the
#     certbot step will fail.
#
# Same box as the PWA/API (see ../nutrics/scripts/deploy.sh); this adds a second
# nginx server block keyed on server_name, so the two sites don't interact.
# There is no build step - the site is served exactly as it is in the repo.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PEM_KEY="${NUTRICS_PEM:-$REPO/../nutrics/.pvt/nutrics-n2026.pem}"
EC2_USER="ec2-user"
EC2_HOST="15.223.48.150"
DOMAIN="nutrics.ca"
WWW_DOMAIN="www.nutrics.ca"
STATIC_DIR="/home/$EC2_USER/nutrics-website"
SSH_OPTS="-i $PEM_KEY -o StrictHostKeyChecking=accept-new -o BatchMode=yes"

ssh_run() { ssh $SSH_OPTS "$EC2_USER@$EC2_HOST" "$@"; }
scp_put() { scp $SSH_OPTS "$1" "$EC2_USER@$EC2_HOST:$2"; }

if [ ! -f "$PEM_KEY" ]; then
  echo "Missing PEM key at $PEM_KEY - set NUTRICS_PEM to its location." >&2
  exit 1
fi

# ── 1. Preflight: DNS must already resolve to this box ────────────────────────
# Certbot's HTTP-01 challenge hits the domain from Let's Encrypt's side, so a
# half-propagated record burns a rate-limited issuance attempt for nothing.
echo "[1/4] Checking DNS..."
for host in "$DOMAIN" "$WWW_DOMAIN"; do
  resolved="$(dig +short "$host" A | tail -1)"
  if [ "$resolved" != "$EC2_HOST" ]; then
    echo "  WARNING: $host resolves to '${resolved:-nothing}', expected $EC2_HOST." >&2
    echo "  TLS for that name will fail until the A record is in place." >&2
  else
    echo "  $host -> $resolved"
  fi
done

# ── 2. Sync the site ──────────────────────────────────────────────────────────
# routes.json is Azure Static Web Apps config - nginx does the equivalent below.
echo "[2/4] Syncing site to $EC2_HOST..."
ssh_run "mkdir -p $STATIC_DIR"
rsync -az --delete \
  --exclude '.git' \
  --exclude '.github' \
  --exclude '.gitignore' \
  --exclude '.DS_Store' \
  --exclude 'scripts' \
  --exclude 'routes.json' \
  -e "ssh $SSH_OPTS" \
  "$REPO/" "$EC2_USER@$EC2_HOST:$STATIC_DIR/"

# ── 3. Nginx server block ─────────────────────────────────────────────────────
# Regenerated in full on every deploy, then certbot is re-run - it detects the
# still-valid cert and re-wires the HTTPS block/redirect onto whatever we wrote
# here, so this stays idempotent across reruns (same pattern as the API deploy).
echo "[3/4] Configuring nginx + TLS..."
cat > /tmp/nutrics-website.nginx.conf << EOF
server {
    listen 80;
    server_name $DOMAIN $WWW_DOMAIN;

    root $STATIC_DIR;
    index index.html;

    # index.html is the whole site - never let a client cache a stale copy.
    location = /index.html {
        add_header Cache-Control "no-cache";
    }

    # Fingerprint-free filenames, so keep this short enough that a deploy is
    # visible within the day without re-fetching 8MB of video every visit.
    location /assets/ {
        add_header Cache-Control "public, max-age=86400";
    }

    # Equivalent of routes.json's navigationFallback.
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
scp_put /tmp/nutrics-website.nginx.conf /tmp/nutrics-website.nginx.conf
ssh_run "
  sudo mv /tmp/nutrics-website.nginx.conf /etc/nginx/conf.d/nutrics-website.conf
  sudo nginx -t
  sudo systemctl enable nginx
  sudo systemctl reload nginx
  sudo chmod o+x /home/$EC2_USER
  sudo chmod -R o+rX $STATIC_DIR
"

echo "  [3b] Certbot TLS..."
for _attempt in 1 2 3; do
  ssh_run "sudo certbot --nginx -d $DOMAIN -d $WWW_DOMAIN --non-interactive --agree-tos \
    -m webmaster@$DOMAIN --redirect 2>&1 | tail -5" && break
  echo "  [3b] Certbot attempt $_attempt failed (lock?), retrying in 10s..."
  sleep 10
done || true

# ── 4. Health check ───────────────────────────────────────────────────────────
echo "[4/4] Health check..."
sleep 2
APEX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$DOMAIN/" \
  || curl -s -o /dev/null -w "%{http_code} (http)" --max-time 5 "http://$DOMAIN/" \
  || echo "unreachable")
WWW_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$WWW_DOMAIN/" \
  || echo "unreachable")

echo ""
echo "====================================="
echo "  Deployed to https://$DOMAIN"
echo "  Apex health check: $APEX_STATUS"
echo "  www health check:  $WWW_STATUS"
echo "====================================="
