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

    # Check if we have sudo privileges (for container vs host environment)
    if sudo -n true 2>/dev/null; then
        print_info "Installing OpenOCD system-wide..."
        sudo apt-get update
        sudo apt-get install -y openocd
        print_success "OpenOCD installed successfully"
        openocd --version
    else
        print_error "OpenOCD installation requires system privileges"
        print_info "In a container environment, OpenOCD should be pre-installed in the image"
        return 1
    fi
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
    wget -c -t 10 -T 30 https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz
    wget -c -t 10 -T 30 https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc

    print_info "Verifying download..."
    sha256sum -c arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc

    print_info "Extracting toolchain..."
    tar -xf arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz -C "$TOOLCHAIN_DIR"

    # Create symlink
    ln -sf "$TOOLCHAIN_DIR/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi" "$HOME/gnuarm14.3"

    # Cleanup
    rm arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc

    print_success "GNU Arm Toolchain 14.3 installed successfully"

    # Offer to update PATH
    offer_path_update
}

# Install Arm Compiler for Embedded (ATFE) 21.1
install_arm_atfe() {
    print_info "Installing Arm Compiler for Embedded 21.1..."

    if [ -d "$HOME/atfe21.1" ]; then
        print_warning "Arm Compiler for Embedded 21.1 already installed"
        return 0
    fi

    cd "$TEMP_DIR"

    print_info "Downloading ATFE 21.1 (~3GB)..."
    wget -c -t 10 -T 30 https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz
    wget -c -t 10 -T 30 https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz.sha256

    print_info "Verifying download..."
    sha256sum -c ATfE-21.1.1-Linux-x86_64.tar.xz.sha256

    print_info "Extracting ATFE toolchain..."
    tar -xf ATfE-21.1.1-Linux-x86_64.tar.xz -C "$TOOLCHAIN_DIR"

    print_info "Downloading ATFE newlib overlay..."
    wget -c -t 10 -T 30 https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-newlib-overlay-21.1.1.tar.xz
    wget -c -t 10 -T 30 https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-newlib-overlay-21.1.1.tar.xz.sha256

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

    # Offer to update PATH
    offer_path_update
}

# Install STLink Tools
install_stlink() {
    print_info "Installing STLink tools..."

    # Check if STLink is already installed system-wide
    if command -v st-flash >/dev/null 2>&1; then
        print_warning "STLink tools are already installed system-wide"
        st-flash --version 2>&1 | head -1 || echo "STLink tools available"
        return 0
    fi

    if [ -f "$TOOLCHAIN_DIR/stlink/bin/st-flash" ]; then
        print_warning "STLink tools already installed in user directory"
        return 0
    fi

    cd "$TEMP_DIR"

    # Check if required dependencies are available
    if ! command -v cmake >/dev/null 2>&1; then
        print_error "cmake not found. Please install cmake first."
        return 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        print_error "git not found. Please install git first."
        return 1
    fi

    if ! pkg-config --exists libusb-1.0; then
        print_error "libusb-1.0-dev not found. Please install libusb development package first."
        return 1
    fi

    print_info "Dependencies satisfied, proceeding with STLink build..."

    # Clone and build stlink
    git clone https://github.com/stlink-org/stlink.git
    cd stlink

    # Clean any previous build
    if [ -f Makefile ]; then
        make clean
    fi

    # Configure with CMake for user installation
    cmake -DCMAKE_INSTALL_PREFIX="$TOOLCHAIN_DIR/stlink" \
        -DCMAKE_BUILD_TYPE=Release \
        .

    # Build with all available cores
    make -j$(nproc)

    # Create directories manually
    mkdir -p "$TOOLCHAIN_DIR/stlink/bin"

    # Copy only the binaries we need (avoid make install to skip system files)
    print_info "Installing STLink binaries to user directory..."
    cp bin/st-flash "$TOOLCHAIN_DIR/stlink/bin/"
    cp bin/st-info "$TOOLCHAIN_DIR/stlink/bin/"
    cp bin/st-util "$TOOLCHAIN_DIR/stlink/bin/"

    # Make binaries executable
    chmod +x "$TOOLCHAIN_DIR/stlink/bin/"*

    # Create symlinks in user's local bin
    ln -sf "$TOOLCHAIN_DIR/stlink/bin/st-flash" "$LOCAL_BIN_DIR/st-flash"
    ln -sf "$TOOLCHAIN_DIR/stlink/bin/st-info" "$LOCAL_BIN_DIR/st-info"
    ln -sf "$TOOLCHAIN_DIR/stlink/bin/st-util" "$LOCAL_BIN_DIR/st-util"

    print_success "STLink tools installed successfully to user directory"
    print_info "STLink binaries available in: $TOOLCHAIN_DIR/stlink/bin/"
    print_info "Symlinks created in: $LOCAL_BIN_DIR/"
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

    # Check which tools are already installed
    local tools_needed=()
    local tools_available=()

    for tool in gdb-multiarch minicom screen picocom dfu-util; do
        if command -v "$tool" >/dev/null 2>&1; then
            tools_available+=("$tool")
        else
            tools_needed+=("$tool")
        fi
    done

    if [ ${#tools_available[@]} -gt 0 ]; then
        print_info "Already installed: ${tools_available[*]}"
    fi

    if [ ${#tools_needed[@]} -eq 0 ]; then
        print_success "All development tools are already installed"
        return 0
    fi

    # Check if we have sudo privileges (for container vs host environment)
    if sudo -n true 2>/dev/null; then
        print_info "Installing missing tools: ${tools_needed[*]}"
        sudo apt-get update
        sudo apt-get install -y "${tools_needed[@]}"
        print_success "Additional development tools installed"
    else
        print_error "Development tools installation requires system privileges"
        print_info "Missing tools: ${tools_needed[*]}"
        print_info "In a container environment, these should be pre-installed in the image"
        return 1
    fi
}

# Offer to update PATH after toolchain installation
offer_path_update() {
    # Check if PATH is already configured
    if grep -q "Development Tools PATH" "$HOME/.zshrc" 2>/dev/null; then
        print_info "PATH already configured in shell profiles"
        return 0
    fi

    print_info "Toolchain installed successfully!"
    print_warning "To use the toolchain, you need to add it to your PATH"
    echo
    print_info "Options:"
    echo "  1. Add to PATH automatically (modifies .zshrc/.bashrc)"
    echo "  2. Skip (you can run 'stm32-tools updatepath' later)"
    echo "  3. Show manual PATH export command"
    echo

    read -p "Choose option [1/2/3]: " path_choice
    case $path_choice in
    1)
        update_path_silent
        ;;
    2)
        print_info "Skipped PATH update. Run 'stm32-tools updatepath' when ready"
        ;;
    3)
        print_info "Add this to your shell profile manually:"
        echo 'export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$HOME/.toolchains/stm32tools/stlink/bin:$HOME/.toolchains/stm32tools/stm32cubeprog/bin:$HOME/.local/bin:$PATH"'
        ;;
    *)
        print_info "Invalid choice. Skipping PATH update"
        ;;
    esac
}

# Silent version of PATH update (no prompts)
update_path_silent() {
    print_info "Updating PATH in shell profiles..."

    # Add to .zshrc
    if ! grep -q "Development Tools PATH" "$HOME/.zshrc" 2>/dev/null; then
        cat >>"$HOME/.zshrc" <<'EOF'

# Development Tools PATH
export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$HOME/.toolchains/stm32tools/stlink/bin:$HOME/.toolchains/stm32tools/stm32cubeprog/bin:$HOME/.local/bin:$PATH"
EOF
        print_success "Added development tools to .zshrc"
    else
        print_warning "Development tools PATH already exists in .zshrc"
    fi

    # Add to .bashrc (if it exists)
    if [ -f "$HOME/.bashrc" ] && ! grep -q "Development Tools PATH" "$HOME/.bashrc"; then
        cat >>"$HOME/.bashrc" <<'EOF'

# Development Tools PATH
export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$HOME/.toolchains/stm32tools/stlink/bin:$HOME/.toolchains/stm32tools/stm32cubeprog/bin:$HOME/.local/bin:$PATH"
EOF
        print_success "Added development tools to .bashrc"
    elif [ -f "$HOME/.bashrc" ]; then
        print_warning "Development tools PATH already exists in .bashrc"
    fi
}

# Update PATH in shell profiles
update_path() {
    print_info "This will update PATH in your shell profiles (.zshrc and .bashrc)"
    print_warning "This will modify your shell configuration files"

    # Ask for user confirmation
    read -p "Do you want to update PATH in your shell profiles? [y/N]: " confirm
    case $confirm in
    [yY][eE][sS] | [yY])
        print_info "Updating PATH in shell profiles..."
        ;;
    *)
        print_info "Skipping PATH update. You can run 'stm32-tools updatepath' later"
        return 0
        ;;
    esac

    # Add to .zshrc
    if ! grep -q "Development Tools PATH" "$HOME/.zshrc" 2>/dev/null; then
        cat >>"$HOME/.zshrc" <<'EOF'

# Development Tools PATH
export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$HOME/.toolchains/stm32tools/stlink/bin:$HOME/.toolchains/stm32tools/stm32cubeprog/bin:$HOME/.local/bin:$PATH"
EOF
        print_success "Added development tools to .zshrc"
    else
        print_warning "Development tools PATH already exists in .zshrc"
    fi

    # Add to .bashrc (if it exists)
    if [ -f "$HOME/.bashrc" ] && ! grep -q "Development Tools PATH" "$HOME/.bashrc"; then
        cat >>"$HOME/.bashrc" <<'EOF'

# Development Tools PATH
export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$HOME/.toolchains/stm32tools/stlink/bin:$HOME/.toolchains/stm32tools/stm32cubeprog/bin:$HOME/.local/bin:$PATH"
EOF
        print_success "Added development tools to .bashrc"
    elif [ -f "$HOME/.bashrc" ]; then
        print_warning "Development tools PATH already exists in .bashrc"
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
        echo "  ✓ Arm Compiler for Embedded 21.1: $($HOME/atfe21.1/bin/clang --version 2>&1 | head -1)"
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

    if command -v st-flash >/dev/null 2>&1; then
        echo "  ✓ STLink Tools: $(st-flash --version 2>&1 | head -1 || echo "System-wide installation")"
    elif [ -f "$LOCAL_BIN_DIR/st-flash" ]; then
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
            13)
                print_info "Exiting..."
                break
                ;;
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
