#!/bin/bash

# STM32 Tools On-Demand Installer
# This script provides easy installation of various STM32 development tools
# Run this script as the kdev user inside the container

set -e

TOOLCHAIN_DIR="$HOME/.toolchains/stm32tools"
LOCAL_BIN_DIR="$HOME/.local/bin"
TEMP_DIR="/tmp/stm32-install"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create necessary directories
setup_directories() {
    mkdir -p "$TOOLCHAIN_DIR"
    mkdir -p "$LOCAL_BIN_DIR"
    mkdir -p "$TEMP_DIR"
}

# Install OpenOCD (Open On-Chip Debugger)
install_openocd() {
    print_info "Installing OpenOCD..."
    
    if command -v openocd >/dev/null 2>&1; then
        print_warning "OpenOCD is already installed system-wide"
        openocd --version
        return 0
    fi
    
    sudo apt-get update
    sudo apt-get install -y openocd
    print_success "OpenOCD installed successfully"
    openocd --version
}

# Install GNU Arm Toolchain 14.3
install_gnu_arm() {
    print_info "Installing GNU Arm Toolchain 14.3..."
    
    if [ -d "$TOOLCHAIN_DIR/gnuarm14.3" ]; then
        print_warning "GNU Arm Toolchain 14.3 already installed"
        return 0
    fi
    
    cd "$TEMP_DIR"
    
    print_info "Downloading GNU Arm Toolchain 14.3 (~500MB)..."
    wget https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz
    wget https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc
    
    print_info "Verifying download..."
    sha256sum -c arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc
    
    print_info "Extracting toolchain..."
    tar -xf arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz -C "$TOOLCHAIN_DIR"
    
    # Create symlink
    ln -sf "$TOOLCHAIN_DIR/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi" "$HOME/gnuarm14.3"
    
    # Cleanup
    rm arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc
    
    print_success "GNU Arm Toolchain 14.3 installed successfully"
}

# Install Arm Compiler for Embedded (ATFE) 21.1
install_arm_atfe() {
    print_info "Installing Arm Compiler for Embedded 21.1..."
    
    if [ -d "$TOOLCHAIN_DIR/atfe21.1" ]; then
        print_warning "Arm Compiler for Embedded 21.1 already installed"
        return 0
    fi
    
    cd "$TEMP_DIR"
    
    print_info "Downloading ATFE 21.1 (~3GB)..."
    wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz
    wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz.sha256
    
    print_info "Verifying download..."
    sha256sum -c ATfE-21.1.1-Linux-x86_64.tar.xz.sha256
    
    print_info "Extracting ATFE toolchain..."
    tar -xf ATfE-21.1.1-Linux-x86_64.tar.xz -C "$TOOLCHAIN_DIR"
    
    print_info "Downloading ATFE newlib overlay..."
    wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-newlib-overlay-21.1.1.tar.xz
    wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-newlib-overlay-21.1.1.tar.xz.sha256
    
    print_info "Verifying overlay..."
    sha256sum -c ATfE-newlib-overlay-21.1.1.tar.xz.sha256
    
    print_info "Extracting overlay..."
    tar -xf ATfE-newlib-overlay-21.1.1.tar.xz -C "$TOOLCHAIN_DIR/ATfE-21.1.1-Linux-x86_64"
    
    # Create symlink
    ln -sf "$TOOLCHAIN_DIR/ATfE-21.1.1-Linux-x86_64" "$HOME/atfe21.1"
    
    # Copy armv7m configuration file if it exists
    if [ -f "$HOME/.toolchains/armv7m_hard_fpv4_sp_d16.cfg" ]; then
        cp "$HOME/.toolchains/armv7m_hard_fpv4_sp_d16.cfg" "$HOME/atfe21.1/bin/"
    fi
    
    # Cleanup
    rm ATfE-21.1.1-Linux-x86_64.tar.xz ATfE-21.1.1-Linux-x86_64.tar.xz.sha256
    rm ATfE-newlib-overlay-21.1.1.tar.xz ATfE-newlib-overlay-21.1.1.tar.xz.sha256
    
    print_success "Arm Compiler for Embedded 21.1 installed successfully"
}

# Install STLink Tools
install_stlink() {
    print_info "Installing STLink tools..."
    
    if [ -f "$TOOLCHAIN_DIR/stlink/bin/st-flash" ]; then
        print_warning "STLink tools already installed"
        return 0
    fi
    
    cd "$TEMP_DIR"
    
    # Install dependencies
    sudo apt-get update
    sudo apt-get install -y git cmake libusb-1.0-0-dev
    
    # Clone and build stlink
    git clone https://github.com/stlink-org/stlink.git
    cd stlink
    make clean
    cmake -DCMAKE_INSTALL_PREFIX="$TOOLCHAIN_DIR/stlink" .
    make -j$(nproc)
    make install
    
    # Create symlinks
    ln -sf "$TOOLCHAIN_DIR/stlink/bin/st-flash" "$LOCAL_BIN_DIR/st-flash"
    ln -sf "$TOOLCHAIN_DIR/stlink/bin/st-info" "$LOCAL_BIN_DIR/st-info"
    ln -sf "$TOOLCHAIN_DIR/stlink/bin/st-util" "$LOCAL_BIN_DIR/st-util"
    
    print_success "STLink tools installed successfully"
}

# Install STM32CubeProgrammer (requires manual download)
install_stm32cubeprog() {
    print_info "Installing STM32CubeProgrammer..."
    
    if [ -f "$TOOLCHAIN_DIR/stm32cubeprog/bin/STM32_Programmer_CLI" ]; then
        print_warning "STM32CubeProgrammer already installed"
        return 0
    fi
    
    # Check for downloaded file
    CUBE_ZIP=$(find /tmp -name "*stm32cubeprg*.zip" 2>/dev/null | head -1)
    
    if [ -z "$CUBE_ZIP" ]; then
        print_error "STM32CubeProgrammer zip file not found in /tmp/"
        print_info "Please download STM32CubeProgrammer from:"
        print_info "https://www.st.com/en/development-tools/stm32cubeprog.html"
        print_info "Save the zip file to /tmp/ and run this command again"
        return 1
    fi
    
    cd "$TEMP_DIR"
    unzip -q "$CUBE_ZIP"
    
    # Find the installer
    INSTALLER=$(find . -name "SetupSTM32CubeProgrammer*.linux" 2>/dev/null | head -1)
    
    if [ -z "$INSTALLER" ]; then
        print_error "STM32CubeProgrammer installer not found"
        return 1
    fi
    
    chmod +x "$INSTALLER"
    
    # Install with unattended mode
    print_info "Running STM32CubeProgrammer installer..."
    echo "yes" | "$INSTALLER" --mode unattended --prefix "$TOOLCHAIN_DIR/stm32cubeprog"
    
    # Create symlink
    ln -sf "$TOOLCHAIN_DIR/stm32cubeprog/bin/STM32_Programmer_CLI" "$LOCAL_BIN_DIR/STM32_Programmer_CLI"
    
    print_success "STM32CubeProgrammer installed successfully"
}

# Install STM32CubeIDE (headless CLI tools only)
install_stm32cubeide_cli() {
    print_info "Installing STM32CubeIDE CLI tools..."
    
    if [ -d "$TOOLCHAIN_DIR/stm32cubeide" ]; then
        print_warning "STM32CubeIDE CLI already installed"
        return 0
    fi
    
    print_error "STM32CubeIDE requires manual download and installation"
    print_info "Download from: https://www.st.com/en/development-tools/stm32cubeide.html"
    print_info "Extract to $TOOLCHAIN_DIR/stm32cubeide/"
}

# Install additional development tools
install_dev_tools() {
    print_info "Installing additional development tools..."
    
    sudo apt-get update
    sudo apt-get install -y \
        gdb-multiarch \
        minicom \
        screen \
        picocom \
        dfu-util
    
    print_success "Additional development tools installed"
}

# Update PATH in shell profiles
update_path() {
    print_info "Updating PATH in shell profiles..."
    
    # Add to .zshrc
    if ! grep -q "Development Tools PATH" "$HOME/.zshrc" 2>/dev/null; then
        cat >> "$HOME/.zshrc" << 'EOF'

# Development Tools PATH
export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$HOME/.toolchains/stm32tools/stlink/bin:$HOME/.toolchains/stm32tools/stm32cubeprog/bin:$HOME/.local/bin:$PATH"
EOF
        print_success "Added development tools to .zshrc"
    fi
    
    # Add to .bashrc (if it exists)
    if [ -f "$HOME/.bashrc" ] && ! grep -q "Development Tools PATH" "$HOME/.bashrc"; then
        cat >> "$HOME/.bashrc" << 'EOF'

# Development Tools PATH  
export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$HOME/.toolchains/stm32tools/stlink/bin:$HOME/.toolchains/stm32tools/stm32cubeprog/bin:$HOME/.local/bin:$PATH"
EOF
        print_success "Added development tools to .bashrc"
    fi
}

# Show installed tools
show_status() {
    print_info "Development Tools Installation Status:"
    echo
    
    echo "ARM Toolchains:"
    if [ -d "$HOME/gnuarm14.3" ]; then
        echo "  ✓ GNU Arm Toolchain 14.3: $($HOME/gnuarm14.3/bin/arm-none-eabi-gcc --version 2>&1 | head -1)"
    else
        echo "  ✗ GNU Arm Toolchain 14.3: Not installed"
    fi
    
    if [ -d "$HOME/atfe21.1" ]; then
        echo "  ✓ Arm Compiler for Embedded 21.1: $($HOME/atfe21.1/bin/armclang --version 2>&1 | head -1)"
    else
        echo "  ✗ Arm Compiler for Embedded 21.1: Not installed"
    fi
    
    echo
    echo "STM32 Debug/Programming Tools:"
    if command -v openocd >/dev/null 2>&1; then
        echo "  ✓ OpenOCD: $(openocd --version 2>&1 | head -1)"
    else
        echo "  ✗ OpenOCD: Not installed"
    fi
    
    if [ -f "$LOCAL_BIN_DIR/st-flash" ]; then
        echo "  ✓ STLink Tools: $($LOCAL_BIN_DIR/st-flash --version 2>&1 | head -1)"
    else
        echo "  ✗ STLink Tools: Not installed"
    fi
    
    if [ -f "$LOCAL_BIN_DIR/STM32_Programmer_CLI" ]; then
        echo "  ✓ STM32CubeProgrammer: Available"
    else
        echo "  ✗ STM32CubeProgrammer: Not installed"
    fi
    
    echo
    echo "Additional Development Tools:"
    for tool in gdb-multiarch minicom dfu-util; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "  ✓ $tool"
        else
            echo "  ✗ $tool"
        fi
    done
}

# Main menu
show_menu() {
    echo
    print_info "Development Tools On-Demand Installer"
    echo "======================================"
    echo "ARM Toolchains:"
    echo "1) Install GNU Arm Toolchain 14.3 (~500MB)"
    echo "2) Install Arm Compiler for Embedded 21.1 (~3GB)" 
    echo ""
    echo "STM32 Debug/Programming Tools:"
    echo "3) Install OpenOCD"
    echo "4) Install STLink Tools"
    echo "5) Install STM32CubeProgrammer (requires manual download)"
    echo "6) Install STM32CubeIDE CLI (requires manual download)"
    echo ""
    echo "Utilities:"
    echo "7) Install Additional Development Tools"
    echo "8) Install All ARM Toolchains"
    echo "9) Install All STM32 Tools"
    echo "10) Install Everything"
    echo "11) Update PATH in shell profiles"
    echo "12) Show installation status"
    echo "13) Exit"
    echo
}

# Main script logic
main() {
    setup_directories
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Choose an option [1-13]: " choice
            
            case $choice in
                1) install_gnu_arm ;;
                2) install_arm_atfe ;;
                3) install_openocd ;;
                4) install_stlink ;;
                5) install_stm32cubeprog ;;
                6) install_stm32cubeide_cli ;;
                7) install_dev_tools ;;
                8) 
                    install_gnu_arm
                    install_arm_atfe
                    ;;
                9) 
                    install_openocd
                    install_stlink
                    install_dev_tools
                    print_info "Note: STM32CubeProgrammer requires manual download"
                    ;;
                10) 
                    install_gnu_arm
                    install_arm_atfe
                    install_openocd
                    install_stlink
                    install_dev_tools
                    print_info "Note: STM32CubeProgrammer requires manual download"
                    ;;
                11) update_path ;;
                12) show_status ;;
                13) print_info "Exiting..."; break ;;
                *) print_error "Invalid option. Please choose 1-13." ;;
            esac
            echo
        done
    else
        # Command line mode
        case "$1" in
            "gnuarm") install_gnu_arm ;;
            "atfe") install_arm_atfe ;;
            "openocd") install_openocd ;;
            "stlink") install_stlink ;;
            "cubeprog") install_stm32cubeprog ;;
            "cubeide") install_stm32cubeide_cli ;;
            "devtools") install_dev_tools ;;
            "armtools") 
                install_gnu_arm
                install_arm_atfe
                ;;
            "stm32tools") 
                install_openocd
                install_stlink
                install_dev_tools
                ;;
            "all") 
                install_gnu_arm
                install_arm_atfe
                install_openocd
                install_stlink
                install_dev_tools
                ;;
            "status") show_status ;;
            "updatepath") update_path ;;
            *)
                echo "Usage: $0 [gnuarm|atfe|openocd|stlink|cubeprog|cubeide|devtools|armtools|stm32tools|all|status|updatepath]"
                echo "Run without arguments for interactive mode"
                ;;
        esac
    fi
}

# Cleanup on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

main "$@"