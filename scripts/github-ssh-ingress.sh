#!/usr/bin/env bash
# github-ssh-ingress.sh - Let one GitHub Actions deploy job reach the EC2 box over SSH: `open` adds
# an ingress rule for port 22 from this runner's IP (/32) to the box's security group, `close`
# removes it. The security group then never needs SSH open to GitHub's (huge, shifting) ranges.
# Usage, from .github/workflows/deploy.yml (copied from the nutrics app repo):
#   ./scripts/github-ssh-ingress.sh open    # before the first SSH; exports SSH_INGRESS_RULE_ID
#   ./scripts/github-ssh-ingress.sh close   # in an `if: always()` step
# Needs AWS credentials for the nutrics-github-deploy role (see scripts/setup-github-deploy-access.sh), plus
# EC2_SECURITY_GROUP_ID and AWS_REGION.
#
# Each rule's description carries an expiry. A job killed before `close` can run (runner lost,
# hard timeout) leaves its rule behind, so `open` first sweeps rules that have expired.

set -euo pipefail
EC2_HOST="15.223.48.150"

ACTION="${1:?usage: github-ssh-ingress.sh open|close}"
SG="${EC2_SECURITY_GROUP_ID:?EC2_SECURITY_GROUP_ID is not set}"
RULE_PREFIX="gha-deploy"
RULE_TTL_SECONDS=3600

revoke_expired_rules() {
  local now rule_id description expires
  now="$(date +%s)"
  aws ec2 describe-security-group-rules \
    --filters "Name=group-id,Values=$SG" \
    --query "SecurityGroupRules[?starts_with(Description || '', '$RULE_PREFIX ')].[SecurityGroupRuleId, Description]" \
    --output text |
    while read -r rule_id description; do
      expires="$(sed -nE 's/.*expires=([0-9]+).*/\1/p' <<< "$description")"
      if [ -n "$expires" ] && [ "$expires" -lt "$now" ]; then
        echo "  Revoking expired rule $rule_id ($description)"
        aws ec2 revoke-security-group-ingress --group-id "$SG" --security-group-rule-ids "$rule_id" > /dev/null || true
      fi
    done
}

case "$ACTION" in
  open)
    revoke_expired_rules

    RUNNER_IP="$(curl -fsS --max-time 10 https://checkip.amazonaws.com | tr -d '[:space:]')"
    [[ "$RUNNER_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || { echo "Could not determine runner IP (got '$RUNNER_IP')." >&2; exit 1; }
    DESCRIPTION="$RULE_PREFIX run=${GITHUB_RUN_ID:-local}/${GITHUB_RUN_ATTEMPT:-1} expires=$(( $(date +%s) + RULE_TTL_SECONDS ))"
    PERMISSIONS="[{\"IpProtocol\":\"tcp\",\"FromPort\":22,\"ToPort\":22,\"IpRanges\":[{\"CidrIp\":\"$RUNNER_IP/32\",\"Description\":\"$DESCRIPTION\"}]}]"

    echo "Opening SSH on $SG to $RUNNER_IP/32..."
    if ! OUTPUT="$(aws ec2 authorize-security-group-ingress --group-id "$SG" --ip-permissions "$PERMISSIONS" \
        --query 'SecurityGroupRules[0].SecurityGroupRuleId' --output text 2>&1)"; then
      # Another job on the same runner IP already holds a rule. Use it, but leave revoking it to that
      # job (or the expiry sweep) so this job's `close` can't cut the other one off mid-deploy.
      if [[ "$OUTPUT" == *InvalidPermission.Duplicate* ]]; then
        echo "  $RUNNER_IP/32 is already allowed by another rule - reusing it."
      else
        echo "$OUTPUT" >&2
        exit 1
      fi
    else
      echo "  Rule $OUTPUT"
      [ -n "${GITHUB_ENV:-}" ] && echo "SSH_INGRESS_RULE_ID=$OUTPUT" >> "$GITHUB_ENV"
    fi

    # Security group changes apply within seconds, but don't let the first ssh race them.
    for _ in $(seq 1 10); do
      timeout 3 bash -c "exec 3<>/dev/tcp/$EC2_HOST/22" 2> /dev/null && exit 0
      sleep 2
    done
    echo "  Warning: port 22 on $EC2_HOST still not reachable - continuing, ssh will report the error." >&2
    ;;

  close)
    if [ -z "${SSH_INGRESS_RULE_ID:-}" ]; then
      echo "No SSH ingress rule was opened by this job - nothing to close."
      exit 0
    fi
    echo "Closing SSH ingress rule $SSH_INGRESS_RULE_ID on $SG..."
    aws ec2 revoke-security-group-ingress --group-id "$SG" --security-group-rule-ids "$SSH_INGRESS_RULE_ID" > /dev/null
    ;;

  *)
    echo "usage: github-ssh-ingress.sh open|close" >&2
    exit 1
    ;;
esac
