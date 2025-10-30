#!/bin/bash

# STM32 Development Environment Setup Script
# This script sets up the development environment with commonly needed tools

set -e

echo "🚀 Setting up STM32 Development Environment..."
echo "================================================"

# Function to print colored output
print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }

# Check current status
print_info "Current tool installation status:"
stm32-tools status

echo ""
print_info "Available quick setup options:"
echo "1. Minimal (no additional tools) - Ready to go!"
echo "2. Basic STM32 (GNU Arm toolchain) - ~500MB"  
echo "3. Full STM32 (GNU Arm + STM32 tools) - ~600MB"
echo "4. Everything (All toolchains + tools) - ~3.5GB"
echo ""

read -p "Choose setup option (1-4) or press Enter for manual setup: " choice

case $choice in
    1)
        print_success "Minimal setup selected - you're ready to go!"
        print_info "Install tools later with: stm32-tools <toolname>"
        ;;
    2)
        print_info "Installing GNU Arm Toolchain..."
        stm32-tools gnuarm
        stm32-tools updatepath
        print_success "Basic STM32 setup complete!"
        ;;
    3)
        print_info "Installing GNU Arm + STM32 tools..."
        stm32-tools gnuarm
        stm32-tools stm32tools
        stm32-tools updatepath
        print_success "Full STM32 setup complete!"
        ;;
    4)
        print_info "Installing all available tools..."
        stm32-tools all
        stm32-tools updatepath
        print_success "Everything installed!"
        ;;
    *)
        print_info "Manual setup selected"
        echo "Available commands:"
        echo "  STM32 Tools:"
        echo "    stm32-tools                  - Interactive installer"
        echo "    stm32-tools gnuarm           - Install GNU Arm toolchain"
        echo "    stm32-tools armtools         - Install both ARM toolchains" 
        echo "    stm32-tools stm32tools       - Install STM32 debug tools"
        echo "    stm32-tools all              - Install everything"
        echo "    stm32-tools status           - Show installation status"
        echo ""
        echo "  Python Development:"
        echo "    ./.devcontainer/bootstrap-pyenv.sh  - Install pyenv"
        echo "    pyenv install 3.12.0        - Install Python 3.12.0"
        echo "    pyenv global 3.12.0         - Set global Python version"
        ;;
esac

echo ""
print_info "Creating project directories..."
mkdir -p src include build docs

echo ""
print_success "🎉 Setup complete!"
echo ""
print_info "Next steps:"
echo "  • Check installation: stm32-tools status"
echo "  • Create your STM32 project in src/"
echo "  • Use VS Code extensions for debugging"
echo "  • Connect ST-Link for hardware debugging"
echo ""
print_warning "💡 Remember to reload your shell or run 'source ~/.zshrc' to update PATH"