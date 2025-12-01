#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "    Nyota Final Test – FULL ONE-CLICK DEPLOYMENT"
echo "=================================================="

# === EDIT ONLY THESE TWO LINES ===
export GITHUB_OWNER="YOUR_GITHUB_USERNAME"        # ← CHANGE THIS (e.g. home123)
export CONNECTION_ARN="arn:aws:codeconnections:ca-central-1:YOUR_ACCOUNT_ID:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # ← CHANGE THIS
# =====================================

export AWS_REGION="ca-central-1"
export PREFIX="nyota"
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Using region: $AWS_REGION"
echo "Using account: $ACCOUNT_ID"
echo "GitHub repo: $GITHUB_OWNER/nyota-final-test"
echo ""

# === 1. Create ECR repository (with scanning) ===
echo "1. Creating ECR repository: ${PREFIX}-final-repo"
aws ecr create-repository \
  --repository-name ${PREFIX}-final-repo \
  --image-scanning-configuration scanOnPush=true \
  --region $AWS_REGION || echo "ECR repo already exists – continuing..."

# === 2. Deploy full infrastructure (VPC, ALB, ECS, Auto-Scaling 2→5) ===
echo "2. Deploying infrastructure stack: ${PREFIX}-infra"
aws cloudformation deploy \
  --stack-name ${PREFIX}-infra \
  --template-file cf-templates/nyota-final-infra.yml \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides Prefix=$PREFIX \
  --no-fail-on-empty-changeset

# === 3. Deploy CI/CD (CodeBuild + CodePipeline) ===
echo "3. Deploying CI/CD stack: ${PREFIX}-cicd"
aws cloudformation deploy \
  --stack-name ${PREFIX}-cicd \
  --template-file cf-templates/nyota-final-cicd.yml \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      GitHubRepo="${GITHUB_OWNER}/nyota-final-test" \
      GitHubConnectionArn="$CONNECTION_ARN" \
  --no-fail-on-empty-changeset

echo ""
echo "=================================================="
echo "           ALL DONE! DEPLOYMENT COMPLETE"
echo "=================================================="
echo ""
echo "Next steps:"
echo "   1. Go to AWS Console → CodePipeline"
echo "   2. Open pipeline: nyota-final-pipeline"
echo "   3. Click 'Release change' → 'Approve' when asked"
echo "   4. Wait 5–8 minutes → everything turns green"
echo ""
echo "Then take your 11 perfect screenshots and submit Nyota_Final.docx"
echo ""
echo "To delete everything later, run:"
echo "   aws cloudformation delete-stack --stack-name ${PREFIX}-cicd"
echo "   aws cloudformation delete-stack --stack-name ${PREFIX}-infra"
echo "   aws ecr delete-repository --repository-name ${PREFIX}-final-repo --force --region $AWS_REGION"
echo ""
echo "You are now 20 minutes away from 30/30. Good luck!"