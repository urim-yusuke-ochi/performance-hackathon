#!/bin/bash
# Add a new participant's target group and ALB listener rule
# Usage: ./add-participant.sh <participant_id> <priority>

set -euo pipefail

PARTICIPANT_ID="${1:?Usage: $0 <participant_id> <priority>}"
PRIORITY="${2:?Usage: $0 <participant_id> <priority>}"

# Load configuration
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
CLUSTER_NAME="performance-hackathon"
STACK_NAME="performance-hackathon-base"

echo "Adding participant: ${PARTICIPANT_ID} (priority: ${PRIORITY})"

# Get stack outputs
VPC_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' --output text)
ALB_LISTENER_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`ALBListenerArn`].OutputValue' --output text)

echo "VPC: ${VPC_ID}"
echo "ALB Listener: ${ALB_LISTENER_ARN}"

# Create target group for participant
TG_ARN=$(aws elbv2 create-target-group \
  --name "perf-hack-${PARTICIPANT_ID}" \
  --protocol HTTP \
  --port 8000 \
  --vpc-id "${VPC_ID}" \
  --target-type ip \
  --health-check-path "/" \
  --health-check-interval-seconds 30 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 5 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group created: ${TG_ARN}"

# Create listener rule (route by Host header)
DOMAIN_NAME="performance-hackathon.example.com"
aws elbv2 create-rule \
  --listener-arn "${ALB_LISTENER_ARN}" \
  --priority "${PRIORITY}" \
  --conditions "Field=host-header,Values=[\"${PARTICIPANT_ID}.${DOMAIN_NAME}\"]" \
  --actions "Type=forward,TargetGroupArn=${TG_ARN}"

echo "Listener rule created for: ${PARTICIPANT_ID}.${DOMAIN_NAME}"
echo ""
echo "Target Group ARN: ${TG_ARN}"
echo "Store this as TARGET_GROUP_ARN_PREFIX secret value"
