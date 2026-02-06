# STM32 Development Docker Environment

[![Build and Release](https://github.com/kodezine/kdocker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-build.yml)
[![Test Docker Image](https://github.com/kodezine/kdocker/actions/workflows/docker-test.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-test.yml)
[![Docker Release](https://github.com/kodezine/kdocker/actions/workflows/docker-release.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-release.yml)

A lightweight, optimized Docker environment for C++ and STM32 embedded development with **on-demand tool installation**.

## ✨ Key Features

- 🐳 **Small Base Image**: ~2GB (68% size reduction)
- 🛠️ **On-Demand Tools**: ARM toolchains install when needed
- � **Bootstrap Scripts**: Direct toolchain installation via compiler names
- 🔧 **Modern Toolchain**: GCC 14 with multilib (32-bit & 64-bit support)
- �🔒 **Secure**: Non-root user, SHA256 verified downloads
- 🎯 **STM32 Ready**: GNU ARM 14.3, ATFE 21.1, OpenOCD, ST-Link- ✨ **Code Quality**: Pre-commit hooks auto-configure on startup- 🪟 **Windows Support**: Full WSL2 + Docker Desktop integration
- 📦 **Pre-built Images**: Available on GitHub Container Registry

## 🚀 Quick Start

### Using Pre-built Image (Recommended)

```bash
# Pull and run the latest image
docker pull ghcr.io/kodezine/kdocker:latest
docker run -it --rm ghcr.io/kodezine/kdocker:latest

# Install STM32 tools on first run (choose method)
stm32-tools gnuarm    # Interactive: GNU ARM toolchain (~500MB)
arm-none-eabi-gcc     # Bootstrap: Direct GNU ARM installation
stm32-tools status    # Check installation
```

### Building from Source

```bash
git clone https://github.com/kodezine/kdocker.git
cd kdocker
docker build -t cpp-arm-dev .
docker run -it --rm cpp-arm-dev
```

### VS Code DevContainer

1. Add `.devcontainer/devcontainer.json` to your project:

```json
{
  "name": "STM32 Development",
  "image": "ghcr.io/kodezine/kdocker:latest",
  "remoteUser": "kdev",
  "postCreateCommand": "setup-pre-commit ${containerWorkspaceFolder} && stm32-tools gnuarm"
}
```

1. Open in VS Code → F1 → "Dev Containers: Reopen in Container"

**Note**: Pre-commit hooks auto-install if you have `.pre-commit-config.yaml` in your repo.

## STM32 Development Examples

### Basic STM32 Compilation

```bash
# Install ARM toolchain
stm32-tools gnuarm

# Compile for STM32F4 (Cortex-M4)
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs -o firmware.elf main.c

# Check result
file firmware.elf
```

### With VS Code + STM32 Extension

```bash
# For STM32 debugging with ST-Link
docker run -it --rm --privileged \
  -v $(pwd):/home/kdev/workspaces/project \
  -v /dev/bus/usb:/dev/bus/usb \
  ghcr.io/kodezine/kdocker:latest
```

```bash
# Method 1: Interactive installation
stm32-tools gnuarm
arm-none-eabi-gcc --version

# Method 2: Direct bootstrap installation
arm-none-eabi-gcc     # Installs GNU ARM toolchain automatically
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs \
  -o firmware.elf main.c

# Advanced: ATFE toolchain
clang                 # Installs ATFE toolchain automatically
clang --target=arm-none-eabi -mcpu=cortex-m4 -mthumb \
  --sysroot=~/atfe21.1/arm-none-eabi -o firmware.elf main.c
```

## 📚 Documentation

### Complete Guides

- **[Bootstrap Scripts](.readme/bootstrap-scripts.md)** - Direct toolchain installation via compiler names
- **[STM32 Tools Command Reference](.readme/stm32-tools-guide.md)** - Complete `stm32-tools` usage guide
- **[ARM Toolchain Usage](.readme/arm-toolchains.md)** - GNU ARM & ATFE compilation examples
- **[VS Code DevContainer Setup](.readme/devcontainer.md)** - DevContainer integration + Windows support
- **[Build Verification & Testing](.readme/build-testing.md)** - CI/CD pipeline and manual testing
- **[Troubleshooting Guide](.readme/troubleshooting.md)** - Common issues and solutions

### Quick References

```bash
# Bootstrap Installation (New!)
arm-none-eabi-gcc              # Install & use GNU ARM directly
clang                          # Install & use ATFE directly

# STM32 Tools Commands
stm32-tools                    # Interactive installer
stm32-tools gnuarm             # Install GNU ARM (~500MB)
stm32-tools status             # Show installation status

# ARM Cross-compilation
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs -o firmware.elf main.c

# Container with USB debugging
docker run -it --rm --privileged -v /dev/bus/usb:/dev/bus/usb ghcr.io/kodezine/kdocker:latest
```

## System Requirements

- **Docker**: 20.10+
- **Space**: 2GB base, +500MB-3GB for ARM toolchains
- **RAM**: 4GB recommended
- **USB**: `--privileged` flag for STM32 debugging

## License

[Add your license here]

## Support

For issues and questions, please open an issue in the repository.
