#!/bin/bash
# Performance Hackathon - Infrastructure Setup Script
# 
# Prerequisites:
#   - AWS CLI configured with appropriate permissions
#   - A domain name and ACM certificate in us-east-1
#
# Usage:
#   export DOMAIN_NAME="performance-hackathon.your-domain.com"
#   export CERTIFICATE_ARN="arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID"
#   ./setup.sh

set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-northeast-1}"
STACK_NAME="performance-hackathon-base"
DOMAIN_NAME="${DOMAIN_NAME:?Error: DOMAIN_NAME is required}"
CERTIFICATE_ARN="${CERTIFICATE_ARN:?Error: CERTIFICATE_ARN is required}"
EXISTING_OIDC_ARN="${EXISTING_GITHUB_OIDC_ARN:-}"

echo "============================================"
echo "Performance Hackathon - Setup"
echo "============================================"
echo "Region: ${AWS_REGION}"
echo "Domain: ${DOMAIN_NAME}"
echo "Stack:  ${STACK_NAME}"
if [ -n "$EXISTING_OIDC_ARN" ]; then
  echo "OIDC:   Using existing (${EXISTING_OIDC_ARN})"
else
  echo "OIDC:   Will create new provider"
fi
echo ""

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
  --template-file ../cloudformation-base.yml \
  --stack-name "${STACK_NAME}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    DomainName="${DOMAIN_NAME}" \
    CertificateArn="${CERTIFICATE_ARN}" \
    ExistingGitHubOIDCProviderArn="${EXISTING_OIDC_ARN}" \
  --region "${AWS_REGION}"

echo ""
echo "Stack deployed successfully!"
echo ""

# Get outputs
echo "============================================"
echo "Stack Outputs:"
echo "============================================"
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table \
  --region "${AWS_REGION}"

echo ""
echo "============================================"
echo "GitHub Actions Secrets to Configure:"
echo "============================================"
echo ""

ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`GitHubActionsRoleArn`].OutputValue' --output text --region $AWS_REGION)
EXEC_ROLE=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`ECSExecutionRoleArn`].OutputValue' --output text --region $AWS_REGION)
TASK_ROLE=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`ECSTaskRoleArn`].OutputValue' --output text --region $AWS_REGION)
CF_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' --output text --region $AWS_REGION)
SUBNETS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`SubnetIds`].OutputValue' --output text --region $AWS_REGION)
SG=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`SecurityGroupId`].OutputValue' --output text --region $AWS_REGION)

echo "Set these secrets in each participant's repository:"
echo ""
echo "  AWS_ROLE_ARN=${ROLE_ARN}"
echo "  ECS_EXECUTION_ROLE_ARN=${EXEC_ROLE}"
echo "  ECS_TASK_ROLE_ARN=${TASK_ROLE}"
echo "  CLOUDFRONT_DISTRIBUTION_ID=${CF_ID}"
echo "  SUBNET_IDS=${SUBNETS}"
echo "  SECURITY_GROUP_ID=${SG}"
echo ""
echo "============================================"
echo "Next Steps:"
echo "============================================"
echo ""
echo "1. Configure DNS:"
echo "   - *.${DOMAIN_NAME} → CloudFront distribution"
echo "   - dashboard.${DOMAIN_NAME} → Dashboard CloudFront"
echo ""
echo "2. Add participants:"
echo "   ./add-participant.sh <github-username> <priority-number>"
echo ""
echo "3. Set GitHub secrets in each fork"
echo ""
echo "4. Deploy dashboard:"
echo "   Trigger the 'Deploy Dashboard' workflow"
echo ""
echo "Done! 🎉"
