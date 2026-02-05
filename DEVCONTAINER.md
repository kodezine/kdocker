# Development Container Setup

This guide shows how to use the STM32 development Docker image as a VS Code devcontainer for seamless embedded development.

## 📁 Devcontainer Configuration

### 1. Create Devcontainer Files

Create the following directory structure in your project:

```
your-project/
├── .devcontainer/
│   ├── devcontainer.json
│   └── docker-compose.yml (optional)
├── src/
└── README.md
```

### 2. Basic Devcontainer Configuration

Create `.devcontainer/devcontainer.json`:

```json
{
    "name": "STM32 Development Environment",
    "image": "stm32-dev-minimal:latest",
    
    // Run as kdev user (UID 1000)
    "remoteUser": "kdev",
    "containerUser": "kdev",
    
    // Mount project files
    "workspaceFolder": "/home/kdev/workspaces/project",
    "mounts": [
        "source=${localWorkspaceFolder},target=/home/kdev/workspaces/project,type=bind,consistency=cached"
    ],
    
    // Forward ports for debugging
    "forwardPorts": [3333, 4444, 8080],
    
    // VS Code settings
    "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "terminal.integrated.defaultProfile.linux": "zsh"
    },
    
    // Install recommended extensions
    "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cpptools-extension-pack", 
        "ms-vscode.cmake-tools",
        "marus25.cortex-debug",
        "dan-c-underwood.arm",
        "ms-vscode.vscode-serial-monitor",
        "webfreak.debug"
    ],
    
    // Run commands after container creation
    "postCreateCommand": "setup-pre-commit /workspaces/project && stm32-tools status",
    
    // Keep container running
    "shutdownAction": "stopContainer",
    
    // Hardware access for ST-Link
    "runArgs": [
        "--privileged",
        "--device=/dev:/dev"
    ],
    
    // Environment variables
    "containerEnv": {
        "DISPLAY": "${localEnv:DISPLAY}",
        "WORKSPACE_ROOT": "/home/kdev/workspaces/project"
    }
}
```

### 3. Advanced Configuration with Docker Compose

For more complex setups, create `.devcontainer/docker-compose.yml`:

```yaml
version: '3.8'

services:
  stm32-dev:
    image: stm32-dev-minimal:latest
    volumes:
      - ../..:/home/kdev/workspaces/project:cached
      - /dev:/dev
    working_dir: /home/kdev/workspaces/project
    command: sleep infinity
    user: kdev
    privileged: true
    environment:
      - DISPLAY=${DISPLAY:-:0}
    ports:
      - "3333:3333"  # OpenOCD GDB server
      - "4444:4444"  # OpenOCD telnet
      - "8080:8080"  # Web server (if needed)
```

And update `.devcontainer/devcontainer.json`:

```json
{
    "name": "STM32 Development Environment",
    "dockerComposeFile": "docker-compose.yml",
    "service": "stm32-dev",
    "workspaceFolder": "/home/kdev/workspaces/project",
    "remoteUser": "kdev",
    
    "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
    },
    
    "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "marus25.cortex-debug"
    ],
    
    "postCreateCommand": "stm32-tools status"
}
```

## 🚀 Quick Setup Commands

### Install Development Tools On-Demand

After opening in VS Code devcontainer, install tools as needed:

```bash
# Check current status
stm32-tools status

# Install GNU Arm toolchain (most common)
stm32-tools gnuarm

# Install STM32 debugging tools
stm32-tools stm32tools

# Install everything
stm32-tools all

# Update shell PATH
stm32-tools updatepath
```

### Project-Specific Installation Script

Create `.devcontainer/setup.sh` for automatic tool installation:

```bash
#!/bin/bash

echo "🔧 Setting up STM32 development environment..."

# Install required toolchains
stm32-tools gnuarm
stm32-tools openocd
stm32-tools devtools

# Update PATH
stm32-tools updatepath

# Create project directories
mkdir -p build src include

echo "✅ Setup complete! Ready for STM32 development."
```

Update your `devcontainer.json`:

```json
{
    "postCreateCommand": "chmod +x .devcontainer/setup.sh && ./.devcontainer/setup.sh"
}
```

## 🛠️ VS Code Integration

### 1. Recommended Extensions

Essential extensions for STM32 development:

```json
"extensions": [
    // C/C++ Development
    "ms-vscode.cpptools",
    "ms-vscode.cpptools-extension-pack",
    "ms-vscode.cmake-tools",
    
    // Embedded Development
    "marus25.cortex-debug",
    "dan-c-underwood.arm",
    "ms-vscode.vscode-serial-monitor",
    
    // Build & Debug
    "webfreak.debug",
    "ms-vscode.makefile-tools",
    
    // Git & Utilities
    "eamodio.gitlens",
    "ms-vsliveshare.vsliveshare"
]
```

### 2. Workspace Settings

Create `.vscode/settings.json`:

```json
{
    "C_Cpp.default.compilerPath": "/home/kdev/gnuarm14.3/bin/arm-none-eabi-gcc",
    "C_Cpp.default.cStandard": "c11",
    "C_Cpp.default.cppStandard": "c++17",
    "C_Cpp.default.includePath": [
        "${workspaceFolder}/src/**",
        "${workspaceFolder}/include/**",
        "/home/kdev/gnuarm14.3/arm-none-eabi/include/**"
    ],
    "C_Cpp.default.defines": [
        "STM32F4XX",
        "USE_HAL_DRIVER"
    ],
    
    "cmake.configureOnOpen": true,
    "cmake.generator": "Unix Makefiles",
    
    "cortex-debug.armToolchainPath": "/home/kdev/gnuarm14.3/bin",
    "cortex-debug.openocdPath": "/usr/bin/openocd",
    
    "terminal.integrated.defaultProfile.linux": "zsh"
}
```

### 3. Launch Configuration

Create `.vscode/launch.json` for debugging:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug STM32 (OpenOCD)",
            "cwd": "${workspaceRoot}",
            "executable": "${workspaceRoot}/build/firmware.elf",
            "request": "launch",
            "type": "cortex-debug",
            "runToEntryPoint": "main",
            "servertype": "openocd",
            "configFiles": [
                "interface/stlink.cfg",
                "target/stm32f4x.cfg"
            ],
            "searchDir": [
                "/usr/share/openocd/scripts"
            ],
            "openOCDLaunchCommands": [
                "monitor arm semihosting enable"
            ]
        }
    ]
}
```

### 4. Build Tasks

Create `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build Project",
            "type": "shell",
            "command": "make",
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": "$gcc"
        },
        {
            "label": "Clean Build",
            "type": "shell",
            "command": "make clean",
            "group": "build"
        },
        {
            "label": "Flash Firmware",
            "type": "shell", 
            "command": "st-flash",
            "args": ["write", "build/firmware.bin", "0x8000000"],
            "group": "build",
            "dependsOn": "Build Project"
        }
    ]
}
```

## ✨ Code Quality & Pre-commit Hooks

The Docker image includes **automatic pre-commit hook installation** for seamless code quality enforcement. Pre-commit is pre-installed and will automatically configure your git hooks when you open the dev container.

### Automatic Setup

When you open your project in the dev container, the `setup-pre-commit` script runs automatically and:

1. ✅ Detects if your project is a git repository
2. ✅ Checks for `.pre-commit-config.yaml` in your project
3. ✅ Automatically runs `pre-commit install` if not already configured
4. ✅ Installs commit-msg hooks if configured

**No manual installation required!** Just add a `.pre-commit-config.yaml` to your project.

### Enabling Pre-commit in Your DevContainer

Simply add the setup command to your `postCreateCommand`:

```json
{
    "name": "STM32 Development Environment",
    "image": "ghcr.io/kodezine/kdocker:latest",
    "remoteUser": "kdev",
    "postCreateCommand": "setup-pre-commit /workspaces/project && stm32-tools status"
}
```

Or if using a custom workspace folder:

```json
{
    "postCreateCommand": "setup-pre-commit ${containerWorkspaceFolder} && stm32-tools gnuarm"
}
```

### Creating Your Pre-commit Configuration

Create `.pre-commit-config.yaml` in your project root:

```yaml
# Minimal example for C/C++ embedded projects
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: mixed-line-ending
        args: ['--fix=lf']

  # C/C++ formatting
  - repo: https://github.com/pre-commit/mirrors-clang-format
    rev: v18.1.2
    hooks:
      - id: clang-format
        files: \.(c|cc|cxx|cpp|h|hpp|hxx)$
        args: [--style=Google]

  # Shell script linting
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck
        files: \.(sh|bash)$
```

See the [repository's .pre-commit-config.yaml](../.pre-commit-config.yaml) for a comprehensive example with Docker, Markdown, and security hooks.

### Manual Usage

If you prefer manual control:

```bash
# Check setup status (automatic in postCreateCommand)
setup-pre-commit /workspaces/project

# Run hooks manually on all files
pre-commit run --all-files

# Run hooks on staged files only
pre-commit run

# Update hook versions
pre-commit autoupdate

# Temporarily skip hooks
SKIP=clang-format git commit -m "WIP: quick fix"

# Uninstall hooks
pre-commit uninstall
```

### Skipping Auto-Setup

If you don't want automatic pre-commit installation, simply don't include `setup-pre-commit` in your `postCreateCommand`:

```json
{
    "postCreateCommand": "stm32-tools status"
}
```

Pre-commit will still be available for manual use.

## 🔧 Hardware Configuration

### ST-Link Connection

For ST-Link debugging support:

1. **Linux Host**: Add udev rules (already included in container)
2. **Windows Host**: Install ST-Link drivers on host
3. **macOS Host**: No additional drivers needed

### USB Device Access

The devcontainer configuration includes:

```json
"runArgs": [
    "--privileged",
    "--device=/dev:/dev"
]
```

This provides access to:
- ST-Link debuggers
- Serial ports (UART)
- USB devices

### Serial Port Access

For serial communication:

```bash
# List available serial ports
ls /dev/tty*

# Use minicom for serial communication
minicom -D /dev/ttyUSB0 -b 115200

# Or use VS Code Serial Monitor extension
```

## 📖 Usage Examples

### Example 1: Basic STM32 Project

```bash
# Open VS Code in your project directory
code .

# VS Code will detect .devcontainer and prompt to reopen in container
# Install GNU Arm toolchain when prompted
stm32-tools gnuarm

# Create basic project structure
mkdir -p src include build
touch src/main.c include/main.h Makefile
```

### Example 2: CMake Project

```bash
# Install tools
stm32-tools gnuarm
stm32-tools openocd

# Generate build files
mkdir build && cd build
cmake ..

# Build project
make -j$(nproc)
```

### Example 3: Debugging Session

```bash
# Start OpenOCD server
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg

# In VS Code: Press F5 to start debugging
# Or use command palette: "Debug: Start Debugging"
```

## 📋 Troubleshooting

### Common Issues

1. **Permission Denied for USB Devices**
   ```bash
   # Check if running with correct privileges
   docker run --privileged --device=/dev:/dev stm32-dev-minimal
   ```

2. **Tool Not Found After Installation**
   ```bash
   # Update PATH in current session
   stm32-tools updatepath
   source ~/.zshrc
   ```

3. **OpenOCD Connection Failed**
   ```bash
   # Check ST-Link connection
   st-info --probe
   
   # Verify OpenOCD installation
   stm32-tools openocd
   ```

4. **Extension Installation Failed**
   ```bash
   # Rebuild container
   # Command Palette -> "Dev Containers: Rebuild Container"
   ```

### Container Size Management

Monitor installed tools:

```bash
# Check installation status
stm32-tools status

# Check disk usage
du -sh ~/.toolchains/*

# Clean up if needed (removes all installed tools)
rm -rf ~/.toolchains/*/
```

## 🔄 Updates and Maintenance

### Updating the Base Image

```bash
# Pull latest image
docker pull stm32-dev-minimal:latest

# Rebuild devcontainer
# Command Palette -> "Dev Containers: Rebuild Container"
```

### Adding Custom Tools

Extend the container by creating a custom Dockerfile:

```dockerfile
FROM stm32-dev-minimal:latest

USER root

# Install additional tools
RUN apt-get update && apt-get install -y \
    your-custom-tool \
    && apt-get clean

USER kdev
```

Update `.devcontainer/devcontainer.json`:

```json
{
    "dockerFile": "Dockerfile",
    "context": ".."
}
```

This devcontainer setup provides a complete, reproducible STM32 development environment that scales from minimal (2.6GB) to full-featured (6GB+) based on your project needs!