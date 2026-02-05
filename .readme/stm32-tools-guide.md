# STM32-Tools Command Guide

## Overview

The `stm32-tools` script provides on-demand installation and management of STM32 development toolchains and utilities. This approach keeps the base Docker image small (~2GB) while providing comprehensive development capabilities when needed.

## Installation Commands

### Basic Installation

```bash
# Interactive installer - choose what you need
stm32-tools

# Quick STM32 development setup (most common)
stm32-tools gnuarm

# Install everything for comprehensive development
stm32-tools all
```

### Specific Tool Installation

```bash
stm32-tools gnuarm             # GNU ARM Toolchain 14.3 (~500MB)
stm32-tools atfe              # ARM Toolchain for Embedded 21.1 (~3GB)
stm32-tools armtools          # Both ARM toolchains
stm32-tools stm32tools        # STM32 debug/programming tools (~200MB)
stm32-tools devtools          # Development utilities
```

## Management Commands

### Status and Information

```bash
stm32-tools status            # Show installation status of all tools
stm32-tools --version         # Show stm32-tools script version
stm32-tools --help            # Show help information
```

### PATH Management

```bash
stm32-tools updatepath        # Add installed tools to PATH
                             # Offers user choice:
                             # 1. Auto-update shell config
                             # 2. Skip (manual later)
                             # 3. Show export command
```

### Cleanup Commands

```bash
stm32-tools clean             # Clean download cache
stm32-tools uninstall <tool>  # Remove specific tool (future feature)
```

## Installation Details

### Download Process

1. **Secure Download**: HTTPS from official ARM/ST repositories
2. **SHA256 Verification**: All downloads cryptographically verified
3. **Caching**: Downloads cached in `~/.toolchains/stm32tools/.downloads/`
4. **User Installation**: Tools install in `~/.toolchains/` (no root required)

### Installation Locations

| Tool | Installation Path | Symlink |
|------|------------------|---------|
| GNU ARM 14.3 | `~/.toolchains/stm32tools/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi/` | `~/gnuarm14.3/` |
| ATFE 21.1 | `~/.toolchains/stm32tools/ATfE-21.1.1-Linux-x86_64/` | `~/atfe21.1/` |
| STM32 Tools | `~/.toolchains/stm32tools/stlink/`, `~/.toolchains/stm32tools/stm32cubeprog/` | Various |

## Tool Details

### GNU ARM Toolchain 14.3.rel1

**Size**: ~500MB
**Components**:

- `arm-none-eabi-gcc` - C compiler
- `arm-none-eabi-g++` - C++ compiler
- `arm-none-eabi-gdb` - Debugger
- `arm-none-eabi-objcopy`, `arm-none-eabi-objdump` - Binary utilities

**Usage**:

```bash
# After installation and PATH update
arm-none-eabi-gcc --version
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs -o firmware.elf main.c
```

### ARM Toolchain for Embedded (ATFE) 21.1.1

**Size**: ~3GB
**Components**:

- `clang` - Modern LLVM-based C/C++ compiler
- `llvm-objcopy`, `llvm-objdump` - LLVM binary utilities
- Newlib overlay for embedded development

**Usage**:

```bash
# After installation and PATH update
clang --version
clang --target=arm-none-eabi -mcpu=cortex-m4 -mthumb -o firmware.elf main.c
```

### STM32 Development Tools

**Size**: ~200MB
**Components**:

- **STLink Tools**: Programming and debugging via ST-Link
- **OpenOCD**: Open On-Chip Debugger (pre-installed in base image)
- **STM32CubeProgrammer**: Official ST programming tool
- **Additional utilities**: Device detection, firmware flashing

## PATH Management Philosophy

### User Consent Approach

The `stm32-tools` script **never modifies your shell configuration without permission**:

1. **Installation**: Tools install but PATH is not automatically modified
2. **Notification**: User is informed about PATH update options
3. **Choice**: User chooses how to handle PATH updates:
   - Automatic shell config modification
   - Skip for later (`stm32-tools updatepath`)
   - Manual export command display

### PATH Update Options

```bash
# Option 1: Automatic (modifies ~/.zshrc or ~/.bashrc)
stm32-tools updatepath
# Choose "1" when prompted

# Option 2: Manual for current session
export PATH="$HOME/gnuarm14.3/bin:$HOME/atfe21.1/bin:$PATH"

# Option 3: Skip and decide later
stm32-tools updatepath
# Choose "2" when prompted
```

## Integration Examples

### CMake Integration

```cmake
# CMakeLists.txt for STM32
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

# Use installed toolchain
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)

# STM32F4 specific settings
set(CMAKE_C_FLAGS "-mcpu=cortex-m4 -mthumb --specs=nosys.specs")
```

### VS Code tasks.json

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build STM32 Firmware",
      "type": "shell",
      "command": "arm-none-eabi-gcc",
      "args": [
        "-mcpu=cortex-m4",
        "-mthumb",
        "--specs=nosys.specs",
        "-o", "firmware.elf",
        "main.c"
      ],
      "group": "build"
    }
  ]
}
```

## Troubleshooting

### Common Issues

**"stm32-tools: command not found"**

```bash
# Ensure container has the script
ls -la ~/.local/bin/stm32-tools

# Check PATH includes local bin
echo $PATH | grep -o ".local/bin"
```

**"Download failed"**

```bash
# Check network connectivity
curl -I https://github.com/arm/arm-toolchain/releases

# Clear cache and retry
stm32-tools clean
stm32-tools gnuarm
```

**"arm-none-eabi-gcc not found after installation"**

```bash
# Check installation
stm32-tools status

# Update PATH
stm32-tools updatepath

# Or manual export
export PATH="$HOME/gnuarm14.3/bin:$PATH"
```

## Advanced Usage

### Non-Interactive Installation

```bash
# For scripts/CI - auto-select option 2 (skip PATH update)
echo '2' | stm32-tools gnuarm

# For scripts/CI - auto-select option 1 (update PATH)
echo '1' | stm32-tools gnuarm
```

### Custom Installation Directory

The installation directory is currently fixed at `~/.toolchains/stm32tools/` but future versions may support customization.

### Offline Usage

Once tools are installed, they work offline. The download cache in `~/.toolchains/stm32tools/.downloads/` can be preserved for faster reinstallation.
