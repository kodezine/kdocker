# STM32 Development Docker Environment

[![Build and Release](https://github.com/kodezine/kdocker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-build.yml)
[![Test Docker Image](https://github.com/kodezine/kdocker/actions/workflows/docker-test.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-test.yml)
[![Docker Release](https://github.com/kodezine/kdocker/actions/workflows/docker-release.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-release.yml)

A lightweight, optimized Docker environment for C++ and STM32 embedded development with **on-demand tool installation**.

## ✨ Key Features

- 🐳 **Small Base Image**: ~2GB (68% size reduction)
- 🛠️ **On-Demand Tools**: ARM toolchains install when needed
- 🔒 **Secure**: Non-root user, SHA256 verified downloads  
- 🎯 **STM32 Ready**: GNU ARM 14.3, ATFE 21.1, OpenOCD, ST-Link
- 🪟 **Windows Support**: Full WSL2 + Docker Desktop integration
- 📦 **Pre-built Images**: Available on GitHub Container Registry

## 🚀 Quick Start

### Using Pre-built Image (Recommended)
```bash
# Pull and run the latest image
docker pull ghcr.io/kodezine/kdocker:latest
docker run -it --rm ghcr.io/kodezine/kdocker:latest

# Install STM32 tools on first run
stm32-tools gnuarm    # GNU ARM toolchain (~500MB)
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
  "postCreateCommand": "stm32-tools gnuarm"
}
```
2. Open in VS Code → F1 → "Dev Containers: Reopen in Container"

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

## 📚 Documentation

### Complete Guides
- **[STM32 Tools Command Reference](.readme/stm32-tools-guide.md)** - Complete `stm32-tools` usage guide
- **[ARM Toolchain Usage](.readme/arm-toolchains.md)** - GNU ARM & ATFE compilation examples
- **[VS Code DevContainer Setup](.readme/devcontainer.md)** - DevContainer integration + Windows support
- **[Build Verification & Testing](.readme/build-testing.md)** - CI/CD pipeline and manual testing
- **[Troubleshooting Guide](.readme/troubleshooting.md)** - Common issues and solutions

### Quick References
```bash
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