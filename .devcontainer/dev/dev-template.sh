#!/bin/bash
# file: .devcontainer/dev/dev-template.sh
# Description: This scripts download the selected template and set up the project
# Usage: ./install-dev-template.sh
#------------------------------------------------------------------------------
set -e

echo ""
echo "🛠️  Urbalurba Developer Platform - Project Initializer"
echo "This script will set up your project with the necessary files and configurations."
echo "-----------------------------------------------------"


# Detect GitHub username and repo
GITHUB_REMOTE=$(git remote get-url origin)
GITHUB_USERNAME=$(echo "$GITHUB_REMOTE" | sed -n 's/.*github.com[:/]\(.*\)\/.*/\1/p')
REPO_NAME=$(basename -s .git "$GITHUB_REMOTE")

if [[ -z "$GITHUB_USERNAME" || -z "$REPO_NAME" ]]; then
  echo "❌ Could not determine GitHub username or repo name"
  exit 1
fi

echo "✅ GitHub user: $GITHUB_USERNAME"
echo "✅ Repo name: $REPO_NAME"

# Download template from the template repo
TEMPLATE_NAME="typescript-basic-webserver"
TEMPLATE_REPO="https://github.com/terchris/urbalurba-dev-templates"
TEMPLATE_URL="$TEMPLATE_REPO/tree/main/$TEMPLATE_NAME"

echo "==> Downloading template: $TEMPLATE_NAME from $TEMPLATE_REPO"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
gh repo clone terchris/urbalurba-dev-templates
cp -r urbalurba-dev-templates/$TEMPLATE_NAME/* "$OLDPWD"
cd "$OLDPWD"

echo "==> Patching deployment.yaml..."
sed -i.bak "s|{{GITHUB_USERNAME}}|$GITHUB_USERNAME|g" manifests/deployment.yaml
rm manifests/deployment.yaml.bak

echo "==> Patching GitHub Actions workflow..."
sed -i.bak "s|{{GITHUB_USERNAME}}|$GITHUB_USERNAME|g" .github/workflows/build-and-push.yaml
rm .github/workflows/build-and-push.yaml.bak

echo "==> Cleaning up..."
rm -rf "$TEMP_DIR"

echo "✅ Template setup complete. You can now commit and push your project."
