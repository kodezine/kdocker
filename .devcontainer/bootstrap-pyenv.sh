#!/bin/bash

# Pyenv Bootstrap Script for Development Container
# This script installs pyenv and its dependencies on container startup

set -e

# Function to print colored output
print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# Check if pyenv is already installed
if command -v pyenv >/dev/null 2>&1; then
    print_info "pyenv is already installed ($(pyenv --version))"
    exit 0
fi

print_info "🐍 Bootstrapping pyenv for Python development..."
echo "================================================"

# Install pyenv dependencies
print_info "Installing pyenv build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    >/dev/null 2>&1

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

print_success "Dependencies installed successfully"

# Install pyenv
print_info "Installing pyenv..."
if ! curl -sSL https://pyenv.run | bash >/dev/null 2>&1; then
    print_error "Failed to install pyenv"
    exit 1
fi

print_success "pyenv installed successfully"

# Add pyenv to shell configuration
print_info "Configuring shell environment..."

# Add to .zshrc if not already present
if ! grep -q "PYENV_ROOT" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'EOF'

# Pyenv configuration (auto-added by bootstrap)
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
    print_success "Added pyenv configuration to ~/.zshrc"
else
    print_info "pyenv configuration already exists in ~/.zshrc"
fi

# Source the configuration for current session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

print_success "pyenv bootstrap completed!"
print_info "Available commands:"
echo "  pyenv install --list      # List available Python versions"
echo "  pyenv install 3.12.0      # Install Python 3.12.0"
echo "  pyenv global 3.12.0       # Set global Python version"
echo "  pyenv versions             # List installed versions"
echo ""
print_warning "Note: Restart your terminal or run 'source ~/.zshrc' to use pyenv in the current session"
