# STM32 Development Docker Environment

A lightweight, optimized Docker-based development environment for C++ and STM32 embedded systems development, built on Ubuntu 24.04 LTS.

## 🚀 **On-Demand Tool Installation**
This container uses a **smart on-demand installation system** to keep the base image small while providing comprehensive STM32 development capabilities when needed.

- **Base Image**: ~2GB (68% smaller than previous versions)  
- **ARM Toolchains**: Install only what you need (~500MB - 3GB)
- **STM32 Tools**: Debug and programming tools on-demand
- **User Control**: No automatic PATH modifications without consent

## Features

### Development Tools
- **GCC 13.2** - Default system compiler
- **Clang** - Modern C++ compiler with clang-format
- **CMake** (latest) - From Kitware's official repository
- **Ninja** - Fast build system
- **ccache** - Compiler cache for faster rebuilds
- **GDB** - GNU Debugger
- **Valgrind** - Memory debugging and profiling

### Languages
- **Python 3.13** - Latest stable from deadsnakes PPA
- **Ruby 3.2** - From Ubuntu repository
- **Perl 5.38** - From Ubuntu repository

### Code Coverage
- **gcovr** (latest) - Generate code coverage reports

### STM32 Development Tools (On-Demand)
- **GNU ARM Toolchain 14.3.rel1** (arm-none-eabi) - ~500MB
  - Install: `stm32-tools gnuarm`
  - Location: `~/.toolchains/stm32tools/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi`
  - Symlink: `~/gnuarm14.3`
- **ARM Toolchain for Embedded (ATfE) 21.1.1** with newlib overlay - ~3GB
  - Install: `stm32-tools atfe`  
  - Location: `~/.toolchains/stm32tools/ATfE-21.1.1-Linux-x86_64`
  - Symlink: `~/atfe21.1`
- **STM32 Debug Tools** (OpenOCD, STLink, STM32CubeProgrammer)
  - Install: `stm32-tools stm32tools`
  - Pre-installed: `stlink-tools`, `openocd`, `gdb-multiarch`

All downloads are SHA256 verified for security.

### Security & User Experience
- **Non-root user**: Default user `kdev` (UID 1000) with sudo access
- **No password sudo**: Passwordless sudo for development convenience
- **SSH key mounting**: SSH credentials mounted read-only for git operations
- **Zsh shell**: Enhanced shell experience with Oh My Zsh pre-configured

## Quick Start

### Building the Docker Image

```bash
# Clone the repository
git clone https://github.com/kodezine/kdocker.git
cd kdocker

# Build the image
docker build -t cpp-arm-dev .

# Build with custom tag
docker build -t my-stm32-dev:latest .
```

### Running the Container

```bash
# Basic run with welcome message
docker run -it --rm cpp-arm-dev

# Mount current directory as workspace
docker run -it --rm -v $(pwd):/home/kdev/workspaces/project cpp-arm-dev

# With SSH credentials for git operations
docker run -it --rm \
  -v $(pwd):/home/kdev/workspaces/project \
  -v ~/.ssh:/home/kdev/.ssh:ro \
  cpp-arm-dev

# For STM32 debugging with USB device access
docker run -it --rm --privileged \
  -v $(pwd):/home/kdev/workspaces/project \
  -v /dev/bus/usb:/dev/bus/usb \
  cpp-arm-dev
```

### First-Time Setup

When you first run the container, you'll see a welcome message with available commands:

```bash
# Interactive installer - choose what you need
stm32-tools

# Quick STM32 development setup (most common)
stm32-tools gnuarm

# Install everything for comprehensive development
stm32-tools all

# Check what's currently installed
stm32-tools status
```

### Using with VS Code DevContainers

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open the project folder in VS Code
3. Press `F1` and select "Dev Containers: Reopen in Container"
4. VS Code will build and start the container automatically

See [DevContainer Setup](.readme/devcontainer.md) for more details.

## Usage Examples

### Compiling C++ Code

```bash
# Using GCC
g++ -std=c++20 -O2 -o myapp main.cpp

# Using Clang
clang++ -std=c++20 -O2 -o myapp main.cpp

# Using CMake
mkdir build && cd build
cmake -G Ninja ..
ninja
```

### STM32 Development Workflow

```bash
# 1. Install GNU ARM toolchain (most common for STM32)
stm32-tools gnuarm

# 2. Verify installation
arm-none-eabi-gcc --version

# 3. Compile for STM32 (Cortex-M4 example)
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs \
  -o firmware.elf main.c

# 4. Alternative: Use ATFE for advanced features
stm32-tools atfe
clang --target=arm-none-eabi -mcpu=cortex-m4 -mthumb \
  --sysroot=~/atfe21.1/arm-none-eabi -o firmware.elf main.c
```

### STM32 Debugging and Programming

```bash
# Install STM32 debugging tools
stm32-tools stm32tools

# Check connected STM32 devices
st-info --probe

# Flash firmware using st-flash
st-flash write firmware.bin 0x8000000

# Start OpenOCD debugging session
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg
```

### Code Coverage with gcovr

```bash
# Compile with coverage flags
g++ -fprofile-arcs -ftest-coverage -o myapp main.cpp

# Run the application
./myapp

# Generate coverage report
gcovr --html-details coverage.html
```

### Using ccache

```bash
# Set compiler to use ccache
export CC="ccache gcc"
export CXX="ccache g++"

# Build with CMake
cmake -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      ..
```

## STM32-Tools Command Reference

### Installation Commands
```bash
stm32-tools                    # Interactive installer
stm32-tools gnuarm             # Install GNU ARM Toolchain 14.3 (~500MB)
stm32-tools atfe              # Install ATFE 21.1 (~3GB)
stm32-tools armtools          # Install both ARM toolchains
stm32-tools stm32tools        # Install STM32 debug tools
stm32-tools devtools          # Install development tools
stm32-tools all               # Install everything
```

### Management Commands  
```bash
stm32-tools status            # Show installation status
stm32-tools updatepath        # Add tools to PATH (with user consent)
stm32-tools uninstall <tool>  # Remove specific tool
stm32-tools clean             # Clean download cache
```

### PATH Management
The container respects user choice for PATH modifications:
- **Option 1**: Automatic PATH update (modifies shell config)
- **Option 2**: Skip (run `stm32-tools updatepath` later)  
- **Option 3**: Manual export command shown

## VS Code DevContainer Integration

### Quick Setup
1. Install [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Copy `.devcontainer/devcontainer.json` to your project
3. Open project in VS Code → F1 → "Dev Containers: Reopen in Container"

### Sample `.devcontainer/devcontainer.json`
```json
{
  "name": "STM32 Development",
  "image": "cpp-arm-dev:latest",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "marus25.cortex-debug"
      ]
    }
  },
  "mounts": [
    "source=${localWorkspaceFolder},target=/home/kdev/workspaces/project,type=bind"
  ],
  "remoteUser": "kdev",
  "privileged": true,
  "postCreateCommand": "stm32-tools gnuarm"
}
```

### Windows 10/11 Support
✅ **Full Windows support** with WSL2 integration:
- Complete setup guide in [DevContainer documentation](.readme/devcontainer.md#windows-1011-setup-guide)
- WSL2 + Docker Desktop integration
- ST-Link USB device access methods
- Performance optimization tips
- Windows-specific troubleshooting

## System Requirements

- **Docker**: 20.10 or later
- **Disk Space**: 
  - Base image: ~2GB
  - With GNU ARM toolchain: ~2.5GB  
  - With all tools: ~5GB
- **RAM**: 4GB recommended for compilation
- **USB Access**: For STM32 debugging (requires `--privileged` flag)

## Image Optimization

### Smart Size Management
- **Base Image**: 2.04GB (68% smaller than previous versions)
- **On-Demand Tools**: Install only what you need
- **User-Level Installation**: Tools install in `~/.toolchains/` (no root required)
- **Cached Downloads**: SHA256-verified downloads cached for reuse

### Installation Sizes
| Component | Size | Description |
|-----------|------|-------------|
| Base Image | ~2GB | Core development tools, languages |  
| GNU ARM 14.3 | ~500MB | Essential STM32 development |
| ATFE 21.1 | ~3GB | Advanced ARM compilation |
| STM32 Tools | ~200MB | Debug and programming utilities |

## Security Features

### User Security
- **Non-root operation**: All development as `kdev` user (UID 1000)
- **Controlled sudo**: Passwordless sudo for system operations
- **SSH credential mounting**: Read-only SSH key access for git
- **User consent**: PATH modifications require explicit approval

### Download Security  
- **SHA256 verification**: All ARM toolchain downloads verified
- **HTTPS downloads**: Secure download from official sources
- **Signature verification**: GPG signature checks where available

## Troubleshooting

### Common Issues

**ARM toolchain not in PATH**
```bash
# Check installation status
stm32-tools status

# Add to PATH (if installed)  
stm32-tools updatepath

# Or manually export for current session
export PATH="$HOME/gnuarm14.3/bin:$PATH"
```

**STM32 device not detected**  
```bash
# Run container with USB access
docker run -it --rm --privileged -v /dev/bus/usb:/dev/bus/usb cpp-arm-dev

# Check connected devices
lsusb | grep -i st-link
st-info --probe
```

**Container size concerns**
```bash
# Start with minimal setup
stm32-tools gnuarm    # Only GNU ARM (~500MB)

# Check current usage
stm32-tools status
du -sh ~/.toolchains/
```

### Getting Help
```bash
# Tool-specific help
stm32-tools --help
arm-none-eabi-gcc --help
openocd --help

# Check versions
stm32-tools status
```

## Migration from Previous Versions

### From Fixed Installation Containers
If upgrading from containers with pre-installed toolchains:

1. **Remove old PATH entries** from shell config
2. **Use new commands**: `stm32-tools gnuarm` instead of direct paths
3. **User-level installation**: Tools now install in `~/.toolchains/`
4. **Consent-based PATH**: Choose how to handle PATH updates

### Version Compatibility
- **GNU ARM**: Now version 14.3.rel1 (was 13.x)
- **ATFE**: Now version 21.1.1 (was 20.x)  
- **Tool locations**: Moved from `/opt/` to `~/.toolchains/`

## Contributing & Development

### Container Development
```bash
# Build development version
docker build -t cpp-arm-dev:dev .

# Test new features
docker run -it --rm cpp-arm-dev:dev

# Run CI tests locally  
docker build -f .github/workflows/docker-test.yml .
```

### STM32-Tools Script Development
The `stm32-tools` script handles all tool management:
- Location: `~/.local/bin/stm32-tools`  
- Features: Download, verify, install, manage ARM toolchains
- User consent: Prompts before modifying shell configuration

## License

[Add your license here]

## Support

For issues and questions, please open an issue in the repository.