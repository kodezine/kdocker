#!/bin/bash

# Auto-setup script for pre-commit hooks in downstream dev containers
# This script runs automatically when the dev container starts

set -e

WORKSPACE_DIR="${1:-/home/kdev/workspaces}"

echo "🔍 Checking for pre-commit configuration..."

# Check if we're in a git repository
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    echo "ℹ️  No git repository found at $WORKSPACE_DIR"
    echo "   Pre-commit hooks require a git repository. Skipping auto-setup."
    exit 0
fi

# Check if .pre-commit-config.yaml exists
if [ ! -f "$WORKSPACE_DIR/.pre-commit-config.yaml" ]; then
    echo "ℹ️  No .pre-commit-config.yaml found in $WORKSPACE_DIR"
    echo "   Create one to enable pre-commit hooks auto-installation."
    echo "   See: https://pre-commit.com/#2-add-a-pre-commit-configuration"
    exit 0
fi

# Navigate to workspace directory
cd "$WORKSPACE_DIR" || exit 1

echo "✅ Found .pre-commit-config.yaml"

# Check if pre-commit hooks are already installed
if [ -f ".git/hooks/pre-commit" ] && grep -q "pre-commit" ".git/hooks/pre-commit" 2>/dev/null; then
    echo "✅ Pre-commit hooks already installed"
else
    echo "📦 Installing pre-commit hooks..."
    if pre-commit install --install-hooks; then
        echo "✅ Pre-commit hooks installed successfully!"
        echo ""
        echo "💡 Tips:"
        echo "   - Run 'pre-commit run --all-files' to check all files"
        echo "   - Hooks will run automatically on 'git commit'"
        echo "   - Run 'pre-commit uninstall' to remove hooks"
    else
        echo "❌ Failed to install pre-commit hooks"
        exit 1
    fi
fi

# Optionally install commit-msg hooks if configured
if grep -q "commit-msg" "$WORKSPACE_DIR/.pre-commit-config.yaml" 2>/dev/null; then
    if [ -f ".git/hooks/commit-msg" ] && grep -q "pre-commit" ".git/hooks/commit-msg" 2>/dev/null; then
        echo "✅ Commit-msg hooks already installed"
    else
        echo "📦 Installing commit-msg hooks..."
        if pre-commit install --hook-type commit-msg; then
            echo "✅ Commit-msg hooks installed successfully!"
        else
            echo "⚠️  Warning: Failed to install commit-msg hooks"
        fi
    fi
fi

echo ""
echo "🎉 Pre-commit setup complete!"
