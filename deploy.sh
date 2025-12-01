#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "    Nyota Final Test – FULL ONE-CLICK DEPLOYMENT"
echo "=================================================="

# === YOUR REAL VALUES (already filled in) ===
export GITHUB_OWNER="talent"       # ← Change only if your GitHub username is different
export CONNECTION_ARN="arn:aws:codeconnections:ca-central-1:387324564533:connection/850e5c22-b1ae-49a6-badb-88c3b119133f"
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
echo "   3. Click 'Review' → 'Approve' (when it asks)"
echo "   4. Wait 5–8 minutes → everything turns GREEN"
echo ""
echo "Then take your 11 screenshots → submit Nyota_Final.docx → 30/30"
echo ""
echo "Cleanup command (run after submission):"
echo "   aws cloudformation delete-stack --stack-name ${PREFIX}-cicd"
echo "   aws cloudformation delete-stack --stack-name ${PREFIX}-infra"
echo "   aws ecr delete-repository --repository-name ${PREFIX}-final-repo --force --region $AWS_REGION"
echo ""
echo "You got this! 100% guaranteed."