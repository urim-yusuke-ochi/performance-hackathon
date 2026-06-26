#!/bin/bash
# Bulk setup GitHub secrets for multiple participants
# Requires: gh CLI (GitHub CLI) authenticated
#
# Usage:
#   export GITHUB_ORG="your-org"
#   ./bulk-setup-secrets.sh participants.txt
#
# participants.txt format (one GitHub username per line):
#   alice
#   bob
#   charlie

set -euo pipefail

PARTICIPANTS_FILE="${1:?Usage: $0 <participants_file>}"
GITHUB_ORG="${GITHUB_ORG:?Error: GITHUB_ORG is required}"
REPO_NAME="${REPO_NAME:-performance-hackathon}"
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
STACK_NAME="performance-hackathon-base"

# Get shared values from CloudFormation outputs
echo "Fetching CloudFormation outputs..."
ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`GitHubActionsRoleArn`].OutputValue' --output text --region $AWS_REGION)
EXEC_ROLE=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`ECSExecutionRoleArn`].OutputValue' --output text --region $AWS_REGION)
TASK_ROLE=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`ECSTaskRoleArn`].OutputValue' --output text --region $AWS_REGION)
CF_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' --output text --region $AWS_REGION)
SUBNETS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`SubnetIds`].OutputValue' --output text --region $AWS_REGION)
SG=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`SecurityGroupId`].OutputValue' --output text --region $AWS_REGION)

echo "Shared secrets:"
echo "  AWS_ROLE_ARN: ${ROLE_ARN}"
echo "  ECS_EXECUTION_ROLE_ARN: ${EXEC_ROLE}"
echo "  ECS_TASK_ROLE_ARN: ${TASK_ROLE}"
echo ""

PRIORITY=10

while IFS= read -r PARTICIPANT_ID; do
  # Skip empty lines and comments
  [[ -z "$PARTICIPANT_ID" || "$PARTICIPANT_ID" == \#* ]] && continue
  
  REPO="${PARTICIPANT_ID}/${REPO_NAME}"
  echo "============================================"
  echo "Setting up: ${REPO} (priority: ${PRIORITY})"
  echo "============================================"
  
  # Create target group for participant
  echo "Creating target group..."
  TG_ARN=$(bash add-participant.sh "${PARTICIPANT_ID}" "${PRIORITY}" 2>/dev/null | grep "Target Group ARN:" | cut -d' ' -f4) || true
  
  if [ -z "$TG_ARN" ]; then
    echo "  Warning: Could not create target group, it may already exist"
    TG_ARN=$(aws elbv2 describe-target-groups \
      --names "perf-hack-${PARTICIPANT_ID}" \
      --query 'TargetGroups[0].TargetGroupArn' \
      --output text 2>/dev/null || echo "")
  fi
  
  # Set GitHub secrets
  echo "Setting GitHub secrets for ${REPO}..."
  gh secret set AWS_ROLE_ARN --repo "${REPO}" --body "${ROLE_ARN}" 2>/dev/null || echo "  Failed to set AWS_ROLE_ARN"
  gh secret set ECS_EXECUTION_ROLE_ARN --repo "${REPO}" --body "${EXEC_ROLE}" 2>/dev/null || echo "  Failed to set ECS_EXECUTION_ROLE_ARN"
  gh secret set ECS_TASK_ROLE_ARN --repo "${REPO}" --body "${TASK_ROLE}" 2>/dev/null || echo "  Failed to set ECS_TASK_ROLE_ARN"
  gh secret set CLOUDFRONT_DISTRIBUTION_ID --repo "${REPO}" --body "${CF_ID}" 2>/dev/null || echo "  Failed to set CLOUDFRONT_DISTRIBUTION_ID"
  gh secret set SUBNET_IDS --repo "${REPO}" --body "${SUBNETS}" 2>/dev/null || echo "  Failed to set SUBNET_IDS"
  gh secret set SECURITY_GROUP_ID --repo "${REPO}" --body "${SG}" 2>/dev/null || echo "  Failed to set SECURITY_GROUP_ID"
  
  if [ -n "$TG_ARN" ]; then
    gh secret set TARGET_GROUP_ARN_PREFIX --repo "${REPO}" --body "${TG_ARN}" 2>/dev/null || echo "  Failed to set TARGET_GROUP_ARN_PREFIX"
  fi
  
  echo "  Done!"
  echo ""
  
  PRIORITY=$((PRIORITY + 10))
done < "${PARTICIPANTS_FILE}"

echo "============================================"
echo "All participants configured!"
echo "============================================"
