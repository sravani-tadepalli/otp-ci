#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/deploy.sh
# Environment expected:
#   ARTIFACT_BUCKET  - S3 bucket to upload artifacts (e.g. otp-lambda-artifacts-me-us-east-1)
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY (in Jenkins credentials)
#   TF_VAR_name_suffix (optional if your terraform uses it)
# NOTE: this script will run 'terraform apply -auto-approve' in infra/

if [ -z "${ARTIFACT_BUCKET:-}" ]; then
  echo "ERROR: ARTIFACT_BUCKET must be set"
  exit 2
fi

echo "Uploading built lambda zips to s3://${ARTIFACT_BUCKET}/"
mkdir -p build
if ls build/*.zip >/dev/null 2>&1; then
  for f in build/*.zip; do
    echo "Uploading $f ..."
    aws s3 cp "$f" "s3://${ARTIFACT_BUCKET}/$(basename "$f")"
  done
else
  echo "No build/*.zip found — aborting"
  exit 3
fi

# Move to infra and run terraform apply to deploy (expects backend configured)
if [ -d infra ]; then
  echo "Running terraform init && terraform apply in infra/"
  pushd infra >/dev/null
  terraform init -input=false
  terraform apply -auto-approve -input=false
  popd >/dev/null
else
  echo "No infra/ directory found — skipping terraform apply"
fi

echo "Deploy completed successfully"
