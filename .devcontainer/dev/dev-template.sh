#!/bin/bash
# file: .devcontainer/dev/dev-template.sh
# Description: This script downloads the selected template and sets up the project
# Usage: ./dev-template.sh
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

# Template variables
TEMPLATE_OWNER="terchris"
TEMPLATE_REPO_NAME="urbalurba-dev-templates"
TEMPLATE_REPO_URL="https://github.com/$TEMPLATE_OWNER/$TEMPLATE_REPO_NAME"
TEMPLATE_NAME="typescript-basic-webserver"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Cloning template repository to temp folder: $TEMP_DIR"
cd "$TEMP_DIR"

# Self-contained clone function - no external dependencies
echo "Cloning from $TEMPLATE_REPO_URL..."
git clone $TEMPLATE_REPO_URL

# Check if the template exists
if [ ! -d "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME" ]; then
  echo "❌ Template '$TEMPLATE_NAME' not found in repository."
  echo "Available templates:"
  ls -la "$TEMPLATE_REPO_NAME"
  echo "Removing template repository folder: $TEMP_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Verify required files and directories exist in the template
echo "Verifying template structure..."

# Check for deployment.yaml
if [ ! -f "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/manifests/deployment.yaml" ]; then
  echo "❌ Required file 'manifests/deployment.yaml' not found in template."
  echo "Removing template repository folder: $TEMP_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Check for GitHub workflow file
if [ ! -f "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/.github/workflows/urbalurba-build-and-push.yaml" ]; then
  echo "❌ Required file '.github/workflows/urbalurba-build-and-push.yaml' not found in template."
  echo "Removing template repository folder: $TEMP_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
fi

echo "✅ All required template files verified"

echo "Extracting template $TEMPLATE_NAME"
# Copy all visible files
cp -r "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/"* "$OLDPWD/"

# Copy hidden files and directories
echo "Copying hidden files and directories..."
if [ -d "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/.github" ]; then
  echo "Setting up .github directory and workflows..."
  
  # Create .github directory if it doesn't exist
  mkdir -p "$OLDPWD/.github/workflows"
  
  # Copy all files from .github directory preserving structure
  cp -r "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/.github"/* "$OLDPWD/.github/"
  echo "✅ Added GitHub files and workflows"
fi

# Handle .gitignore merging
if [ -f "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/.gitignore" ]; then
  echo "Merging .gitignore files..."
  
  # Check if destination .gitignore exists
  if [ -f "$OLDPWD/.gitignore" ]; then
    echo "Existing .gitignore found, merging with template .gitignore"
    
    # Create temporary files
    TEMP_MERGED=$(mktemp)
    
    # Copy existing .gitignore entries to temp file
    cat "$OLDPWD/.gitignore" > "$TEMP_MERGED"
    
    # Add a newline to ensure separation
    echo "" >> "$TEMP_MERGED"
    
    # Add template .gitignore entries that don't already exist
    echo "# Added from template $TEMPLATE_NAME" >> "$TEMP_MERGED"
    
    while IFS= read -r line; do
      # Skip empty lines and comments
      if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
        # Check if this entry already exists in the destination .gitignore
        if ! grep -Fxq "$line" "$OLDPWD/.gitignore"; then
          echo "$line" >> "$TEMP_MERGED"
        fi
      fi
    done < "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/.gitignore"
    
    # Replace the existing .gitignore with the merged file
    # Use cat instead of mv to avoid permission issues
    if cat "$TEMP_MERGED" > "$OLDPWD/.gitignore"; then
        echo "✅ Successfully merged .gitignore files"
        # Clean up temp file
        rm -f "$TEMP_MERGED"
    else
        echo "❌ Failed to update .gitignore file: Permission denied"
        rm -f "$TEMP_MERGED"
        exit 1
    fi
  else
    echo "No existing .gitignore, copying template .gitignore"
    cp "$TEMPLATE_REPO_NAME/$TEMPLATE_NAME/.gitignore" "$OLDPWD/"
  fi
fi

# Navigate back to the project directory
cd "$OLDPWD"

echo "==> Patching deployment.yaml..."
TEMP_FILE=$(mktemp)
# Replace both placeholders in one operation
cat manifests/deployment.yaml | \
  sed -e "s|{{GITHUB_USERNAME}}|$GITHUB_USERNAME|g" \
      -e "s|{{REPO_NAME}}|$REPO_NAME|g" > $TEMP_FILE
cat $TEMP_FILE > manifests/deployment.yaml
rm $TEMP_FILE
echo "✅ Updated manifests/deployment.yaml"

echo "==> Patching GitHub Actions workflow..."
TEMP_FILE=$(mktemp)
# Replace both placeholders in one operation
cat .github/workflows/urbalurba-build-and-push.yaml | \
  sed -e "s|{{GITHUB_USERNAME}}|$GITHUB_USERNAME|g" \
      -e "s|{{REPO_NAME}}|$REPO_NAME|g" > $TEMP_FILE
if cat $TEMP_FILE > .github/workflows/urbalurba-build-and-push.yaml; then
  rm $TEMP_FILE
  echo "✅ Updated .github/workflows/urbalurba-build-and-push.yaml"
else
  rm $TEMP_FILE
  echo "❌ Failed to update workflow file"
  exit 1
fi

echo "Removing template repository folder: $TEMP_DIR"
rm -rf "$TEMP_DIR"

echo "✅ Template setup complete. You can now commit and push your project."