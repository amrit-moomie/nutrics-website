#!/usr/bin/env bash
# setup-github-deploy-access.sh - One-time setup so .github/workflows/deploy.yml can deploy the
# website. Reuses the nutrics-github-deploy role the nutrics app repo already uses (it may only
# add/remove port-22 rules on the box's security group). Safe to re-run.
# Usage: aws login  (or AWS_PROFILE=<admin profile>), then ./scripts/setup-github-deploy-access.sh
#
#   1. Adds this repo's production environment to the role's trust policy
#   2. Copies AWS_REGION, AWS_DEPLOY_ROLE_ARN, EC2_SECURITY_GROUP_ID from the app repo's variables
#   3. Stores the EC2 private key as this repo's EC2_SSH_KEY secret

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_REPO="amrit-moomie/nutrics"
ROLE_NAME="nutrics-github-deploy"
PEM_KEY="${NUTRICS_PEM:-$REPO_DIR/../nutrics/.pvt/nutrics-n2026.pem}"
GITHUB_REPO="$(cd "$REPO_DIR" && gh repo view --json nameWithOwner --jq .nameWithOwner)"
SUBJECT="repo:$GITHUB_REPO:environment:production"

[ -f "$PEM_KEY" ] || { echo "Missing PEM key at $PEM_KEY - set NUTRICS_PEM." >&2; exit 1; }
echo "AWS identity: $(aws sts get-caller-identity --query Arn --output text)"

# ── 1. Trust policy: let this repo's production jobs assume the role ──────────
POLICY="$(aws iam get-role --role-name "$ROLE_NAME" --query Role.AssumeRolePolicyDocument --output json)"
NEW_POLICY="$(SUBJECT="$SUBJECT" python3 -c '
import json, os, sys
doc = json.load(sys.stdin)
sub = os.environ["SUBJECT"]
cond = doc["Statement"][0]["Condition"]["StringEquals"]
key = next(k for k in cond if k.endswith(":sub"))
subs = cond[key] if isinstance(cond[key], list) else [cond[key]]
if sub not in subs:
    subs.append(sub)
cond[key] = subs
print(json.dumps(doc))
' <<< "$POLICY")"
if [ "$POLICY" != "$NEW_POLICY" ]; then
  aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document "$NEW_POLICY"
fi
echo "[1/3] Role $ROLE_NAME trusts $SUBJECT"

# ── 2. Repo variables, same values as the app repo ────────────────────────────
for name in AWS_REGION AWS_DEPLOY_ROLE_ARN EC2_SECURITY_GROUP_ID; do
  value="$(gh variable get "$name" -R "$APP_REPO")"
  gh variable set "$name" -R "$GITHUB_REPO" --body "$value"
done
echo "[2/3] Set repo variables AWS_REGION, AWS_DEPLOY_ROLE_ARN, EC2_SECURITY_GROUP_ID"

# ── 3. SSH key secret ─────────────────────────────────────────────────────────
gh secret set EC2_SSH_KEY -R "$GITHUB_REPO" < "$PEM_KEY"
echo "[3/3] Set repo secret EC2_SSH_KEY"

echo ""
echo "Done. Deploy with: gh workflow run deploy.yml -R $GITHUB_REPO   (or merge to main)"
