# Bootstrap Scripts Documentation

## Overview

The kdocker environment now includes **bootstrap scripts** that provide an alternative installation method for ARM toolchains. These scripts offer direct toolchain installation without requiring the interactive `stm32-tools` interface.

## What's New in This Release

### 🚀 Bootstrap Script Integration
- **Direct Toolchain Installation**: Install toolchains using dedicated bootstrap scripts
- **Unified Installation Location**: Bootstrap scripts and `stm32-tools` install to the same directories
- **Perfect Compatibility**: No conflicts between installation methods
- **Simplified Access**: Bootstrap scripts accessible as compiler names

### 📁 Installation Structure
Both bootstrap scripts and `stm32-tools` now install toolchains to the unified location:
```
~/.toolchains/stm32tools/
├── arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi/  # GNU ARM
└── ATfE-21.1.1-Linux-x86_64/                          # ATFE
```

### 🔗 Access Methods
Bootstrap scripts are available through multiple access points:
```bash
# Direct compiler names (new bootstrap method)
arm-none-eabi-gcc    # Installs GNU ARM toolchain
clang                # Installs ATFE toolchain

# Traditional symlinks (compatibility)
~/gnuarm14.3/bin/arm-none-eabi-gcc
~/atfe21.1/bin/clang

# Full paths
~/.toolchains/bootstrap/bin/arm-none-eabi-gcc
~/.toolchains/bootstrap/bin/clang
```

## Bootstrap Scripts

### GNU ARM Bootstrap (`arm-none-eabi-gcc`)

**Purpose**: Installs GNU ARM Toolchain 14.3.rel1 for STM32 development

**Usage**:
```bash
# Install GNU ARM toolchain
arm-none-eabi-gcc

# Use after installation
arm-none-eabi-gcc --version
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs -o firmware.elf main.c
```

**Features**:
- Downloads `arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz`
- SHA256 checksum verification
- Installs to `~/.toolchains/stm32tools/`
- Creates symlink `~/gnuarm14.3`
- Compatible with `stm32-tools gnuarm`

### ATFE Bootstrap (`clang`)

**Purpose**: Installs ARM Toolchain for Embedded (ATFE) 21.1.1 with LLVM/Clang

**Usage**:
```bash
# Install ATFE toolchain
clang

# Use after installation
clang --version
clang --target=arm-none-eabi -mcpu=cortex-m4 -mthumb -o firmware.elf main.c
```

**Features**:
- Downloads `ATfE-21.1.1-Linux-x86_64.tar.xz`
- Downloads and installs newlib overlay
- SHA256 checksum verification for both packages
- Installs to `~/.toolchains/stm32tools/`
- Creates symlink `~/atfe21.1`
- Copies armv7m configuration file
- Compatible with `stm32-tools atfe`

## Installation Behavior

### First Run (Toolchain Not Installed)
When you run a bootstrap script for the first time:

1. **Download Phase**
   - Downloads toolchain package and SHA256 checksum
   - Verifies package integrity
   - Downloads additional overlays (ATFE only)

2. **Installation Phase**
   - Extracts to `~/.toolchains/stm32tools/`
   - Creates convenience symlinks
   - Sets up configuration files

3. **Execution Phase**
   - After installation, executes the requested command
   - Behaves like the actual compiler from that point forward

### Subsequent Runs (Toolchain Installed)
- **Immediate Execution**: No installation overhead
- **Direct Compiler Access**: Runs the actual installed compiler
- **Full Compatibility**: Works exactly like standard toolchain installation

## Compatibility with stm32-tools

### Perfect Interoperability
Bootstrap scripts and `stm32-tools` are fully compatible:

```bash
# Install with bootstrap
arm-none-eabi-gcc

# Check status with stm32-tools
stm32-tools status
# Output: ✓ GNU Arm Toolchain 14.3: arm-none-eabi-gcc (GNU Arm...) 14.3.1

# Install ATFE with stm32-tools
stm32-tools atfe

# Use via bootstrap name
clang --version
# Works immediately, no reinstallation
```

### Unified Installation Detection
Both methods recognize existing installations:
- Bootstrap scripts detect `stm32-tools` installations
- `stm32-tools` detects bootstrap installations
- No duplicate downloads or conflicting installations

## Technical Details

### Architecture Support
Both bootstrap scripts are configured for:
- **Target Architecture**: `linux-x86_64` (fixed, no dynamic detection)
- **Container Optimization**: Specifically targets Docker container environment
- **Consistency**: Matches `stm32-tools` package selection

### Package Verification
Security features include:
- **SHA256 Checksums**: All packages verified before extraction
- **Trusted Sources**: Downloads from official ARM and GitHub releases
- **Integrity Checks**: Extraction validation

### Directory Structure
```
/home/kdev/
├── .toolchains/
│   ├── stm32tools/                     # Unified toolchain storage
│   │   ├── arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi/
│   │   └── ATfE-21.1.1-Linux-x86_64/
│   └── bootstrap/
│       └── bin/
│           ├── arm-none-eabi-gcc       # GNU ARM bootstrap
│           └── clang                   # ATFE bootstrap
├── gnuarm14.3 -> .toolchains/stm32tools/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi
└── atfe21.1 -> .toolchains/stm32tools/ATfE-21.1.1-Linux-x86_64
```

## Migration and Compatibility

### Existing Users
- **No Breaking Changes**: Existing `stm32-tools` installations continue working
- **Enhanced Options**: Bootstrap scripts provide additional installation methods
- **Unified Experience**: All methods result in identical installations

### New Users
- **Multiple Entry Points**: Choose between `stm32-tools` interactive mode or direct bootstrap
- **Consistent Results**: Same toolchains, same locations, same functionality
- **Flexibility**: Mix and match installation methods as needed

## Examples

### Quick STM32 Development Setup
```bash
# Option 1: Direct bootstrap installation
arm-none-eabi-gcc
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs -o hello.elf hello.c

# Option 2: Traditional stm32-tools
stm32-tools gnuarm
~/gnuarm14.3/bin/arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs -o hello.elf hello.c
```

### Advanced LLVM Development
```bash
# Install ATFE with bootstrap
clang
clang --target=arm-none-eabi -mcpu=cortex-m4 -mthumb --sysroot=~/atfe21.1/arm-none-eabi -o firmware.elf main.c

# Check installation status
stm32-tools status
```

### Mixed Installation Workflow
```bash
# Install GNU ARM with bootstrap
arm-none-eabi-gcc

# Install ATFE with stm32-tools
stm32-tools atfe

# Both available and compatible
arm-none-eabi-gcc --version
clang --version
~/gnuarm14.3/bin/arm-none-eabi-gcc --version
~/atfe21.1/bin/clang --version
```

## Benefits

### For Users
- **Faster Setup**: Direct compiler access without menu navigation
- **Intuitive Commands**: Use compiler names directly
- **Flexible Installation**: Choose your preferred installation method
- **Zero Conflicts**: All methods work together seamlessly

### For Automation
- **Scriptable Installation**: Bootstrap in CI/CD pipelines
- **Predictable Behavior**: Fixed architecture, consistent packages
- **Integration Friendly**: Works with existing `stm32-tools` workflows

### For Development
- **Unified Codebase**: Single toolchain management system
- **Consistent Updates**: Changes benefit both installation methods
- **Maintainable**: Shared directory structure and verification logic
