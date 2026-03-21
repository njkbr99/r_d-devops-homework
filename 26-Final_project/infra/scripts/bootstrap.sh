#!/bin/bash
set -e

REGION="eu-north-1"
STATE_BUCKET="trainings-tracker-tf-state"
ECR_REPO="trainings-tracker/backend"

echo "Initializing S3 bucket for Terraform state storage. Bucket name: $STATE_BUCKET"

aws s3 mb s3://$STATE_BUCKET --region $REGION
aws s3api put-bucket-versioning \
  --bucket $STATE_BUCKET \
  --versioning-configuration Status=Enabled

echo "Initializing ECR repository: $ECR_REPO in region: $REGION"

aws ecr create-repository \
  --repository-name $ECR_REPO \
  --region $REGION

echo ""
echo "Initializing finished. Remember to copy the ECR URI (above) — needed for GitHub Actions secret."