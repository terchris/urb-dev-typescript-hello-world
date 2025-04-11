#!/bin/bash
# File: .devcontainer.extend/project-installs.sh
# Purpose: Post-creation setup script for development container
# Called after the devcontainer is created and installs the sw needed for a spesiffic project.
# So add you stuff here and they will go into your development container.

set -e

# Main execution flow
main() {
    echo "🚀 Starting project-installs setup..."

    # Set container ID and change hostname
    # shellcheck source=/dev/null
    source "$(dirname "$(dirname "$(realpath "$0")")")/.devcontainer/additions/set-hostname.sh"
    set_container_id || {
        echo "❌ Failed to set container ID"
        return 1
    }

    # Set up Git and GitHub
    mark_git_folder_as_safe
    setup_git_identity
    setup_github_cli

    # Version checks
    echo "🔍 Verifying installed versions..."
    check_node_version
    check_python_version
    check_powershell_version
    check_azure_cli_version
    check_npm_packages

    # Run project-specific installations
    install_project_tools

    echo "🎉 Post-creation setup complete!"
}

# Check Node.js version
check_node_version() {
    echo "Checking Node.js installation..."
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        echo "✅ Node.js is installed (version: $NODE_VERSION)"
    else
        echo "❌ Node.js is not installed"
        exit 1
    fi
}

# Check Python version
check_python_version() {
    echo "Checking Python installation..."
    if command -v python >/dev/null 2>&1; then
        PYTHON_VERSION=$(python --version)
        echo "✅ Python is installed (version: $PYTHON_VERSION)"
    else
        echo "❌ Python is not installed"
        exit 1
    fi
}

# Check PowerShell version
check_powershell_version() {
    echo "PowerShell version:"
    pwsh -Version
}

# Check Azure CLI version
check_azure_cli_version() {
    echo "Azure CLI version:"
    az version
}

# Check global npm packages versions
check_npm_packages() {
    echo "📦 Installed npm global packages:"
    npm list -g --depth=0
}

# Set up Git identity if not already configured
setup_git_identity() {
    echo "🧑‍💻 Checking Git identity..."
    
    # Check if git user is already configured
    if git config --get user.name > /dev/null && git config --get user.email > /dev/null; then
        echo "✅ Git identity already configured:"
        echo "   User: $(git config --get user.name)"
        echo "   Email: $(git config --get user.email)"
        return 0
    fi
    
    echo "⚠️ Git identity not configured"
    
    # Try to get user info from environment variables
    local git_user=""
    local git_email=""
    
    # For Mac hosts
    if [ -n "$DEV_MAC_USER" ]; then
        git_user="$DEV_MAC_USER"
        git_email="$DEV_MAC_USER@users.noreply.github.com"
    # For Windows hosts
    elif [ -n "$DEV_WIN_USERNAME" ]; then
        git_user="$DEV_WIN_USERNAME"
        git_email="$DEV_WIN_USERNAME@users.noreply.github.com"
    fi
    
    # Set Git configs
    if [ -n "$git_user" ]; then
        git config --global user.name "$git_user"
        git config --global user.email "$git_email"
        echo "✅ Git identity set to: $git_user <$git_email>"
        echo "   (This is a placeholder identity - update it if needed)"
    else
        echo "❌ Could not determine Git identity"
        echo "Please run these commands to set your Git identity:"
        echo "  git config --global user.name \"Your Name\""
        echo "  git config --global user.email \"your.email@example.com\""
    fi
}

# Check and setup GitHub CLI authentication
setup_github_cli() {
    echo "🔄 Checking GitHub CLI authentication..."
    
    # Test if GitHub CLI is authenticated
    if gh auth status &>/dev/null; then
        echo "✅ GitHub CLI already authenticated"
        return 0
    fi
    
    echo "⚠️ GitHub CLI not authenticated"
    
    # Check for GitHub token in environment
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "🔑 Found GITHUB_TOKEN environment variable"
        echo "Setting up GitHub CLI authentication using token..."
        echo "$GITHUB_TOKEN" | gh auth login --with-token
        if [ $? -eq 0 ]; then
            echo "✅ GitHub CLI authenticated successfully using token"
        else
            echo "❌ Failed to authenticate GitHub CLI with token"
        fi
    else
        # Fall back to using git protocol for cloning
        echo "⚙️ Configuring GitHub CLI to use git protocol for cloning"
        gh config set git_protocol ssh
        
        echo "🔑 You need to authenticate with GitHub CLI for full functionality."
        echo "Run this command: gh auth login"
        echo ""
        echo "💡 To authenticate silently in the future, you can:"
        echo "   1. Create a personal access token at https://github.com/settings/tokens"
        echo "   2. Add it to your environment as GITHUB_TOKEN"
    fi
}

mark_git_folder_as_safe() {
    echo "🔒 Setting up Git repository safety..."

    # Check if .git folder exists
    if [ -d "/workspace/.git" ]; then
        # Check current ownership
        local repo_owner=$(stat -c '%u' /workspace/.git)
        local container_user=$(id -u)
        echo "👤 Repository ownership:"
        echo "   Repository owner ID: $repo_owner"
        echo "   Container user ID: $container_user"
        ls -l /workspace/.git

        # Test Git status to verify it works
        if git status &>/dev/null; then
            echo "✅ Git commands working correctly"
        else
            echo "❌ Git commands still having issues"
        fi
    else
        echo "⚠️ No Git repository found in workspace. Skipping Git-specific steps."
        # Still set safe directory configurations for future use
    fi

    # Mark workspace as safe globally regardless
    git config --global --add safe.directory /workspace
    git config --global --add safe.directory '*'

    # Additional git configurations for mounted volumes
    git config --global core.fileMode false  # Ignore file mode changes
    git config --global core.hideDotFiles false  # Show dotfiles

    # Show final git config for verification
    echo "🔧 Current Git configuration:"
    git config --global --list | grep -E "safe|core"
}

# Helper function for cloning repositories that handles both gh and git methods
clone_repo() {
    local repo="$1"
    local target_dir="${2:-.}"
    
    echo "📥 Cloning repository: $repo"
    
    # Try GitHub CLI first if authenticated
    if gh auth status &>/dev/null; then
        echo "Using GitHub CLI to clone..."
        gh repo clone "$repo" "$target_dir" && return 0
    fi
    
    # Fallback to git clone
    echo "Using git to clone..."
    git clone "https://github.com/$repo.git" "$target_dir"
}

# Run project-specific installations
install_project_tools() {
    echo "🛠️ Installing project-specific tools..."

    # === ADD YOUR PROJECT-SPECIFIC INSTALLATIONS BELOW ===

    # Example: Installing Azure Functions Core Tools
    # npm install -g azure-functions-core-tools@4

    # Example: Installing specific Python packages
    # pip install pandas numpy

    # === END PROJECT-SPECIFIC INSTALLATIONS ===
}

# Export the clone_repo function so it can be used by other scripts
export -f clone_repo

main