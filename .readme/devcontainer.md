# VS Code DevContainer Setup for STM32 Development

## Overview

This guide shows how to use the STM32 development container with Visual Studio Code DevContainers for seamless embedded development.

## Prerequisites

### All Platforms
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Platform-Specific Requirements

#### Windows 10/11
- **Docker Desktop for Windows** - [Download here](https://www.docker.com/products/docker-desktop/)
- **WSL2** (Windows Subsystem for Linux 2) - Required for best performance
- **Git for Windows** - For git operations and SSH key management

#### Linux  
- Docker Engine or Docker Desktop
- Docker Compose (usually included)

#### macOS
- Docker Desktop for Mac
- Xcode Command Line Tools (for git)

## Windows 10/11 Setup Guide

### 1. Install Prerequisites for Windows

#### Step 1: Install WSL2
```powershell
# Run in PowerShell as Administrator
wsl --install
# Restart computer when prompted
```

#### Step 2: Install Docker Desktop
1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Run the installer
3. **Important**: Enable WSL2 integration during setup
4. Restart Windows when prompted

#### Step 3: Configure Docker Desktop  
1. Open Docker Desktop
2. Go to Settings → General
3. ✅ **Enable "Use WSL 2 based engine"**
4. Go to Settings → Resources → WSL Integration  
5. ✅ **Enable integration with your default WSL distro**
6. ✅ **Enable integration with additional distros** (Ubuntu, etc.)
7. Click "Apply & Restart"

#### Step 4: Install VS Code and Extensions
```powershell
# Install VS Code if not already installed
winget install Microsoft.VisualStudioCode

# Or download from: https://code.visualstudio.com/
```

Install required extensions in VS Code:
- **Dev Containers** (`ms-vscode-remote.remote-containers`)
- **WSL** (`ms-vscode-remote.remote-wsl`) - Optional but recommended

### 2. Windows-Specific DevContainer Configuration

Create `.devcontainer/devcontainer.json` with Windows optimizations:

```json
{
  "name": "STM32 Development Environment",
  "image": "cpp-arm-dev:latest",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools", 
        "marus25.cortex-debug",
        "dan-c-underwood.arm"
      ]
    }
  },
  "mounts": [
    "source=${localWorkspaceFolder},target=/home/kdev/workspaces/project,type=bind"
  ],
  "remoteUser": "kdev",
  "postCreateCommand": "setup-pre-commit /home/kdev/workspaces/project && stm32-tools gnuarm && echo 'STM32 development environment ready!'",
  "settings": {
    "terminal.integrated.defaultProfile.linux": "zsh",
    "files.eol": "\n",
    "git.autocrlf": false
  }
}
```

### 3. STM32 Hardware Access on Windows

For STM32 debugging with ST-Link on Windows:

#### Option A: USB Passthrough (Recommended)
```json
{
  // Add to devcontainer.json
  "runArgs": ["--privileged"],
  "mounts": [
    // Windows: USB device access through WSL2
    "source=/mnt/c/Windows/System32/drivers,target=/drivers,type=bind,readonly"
  ]
}
```

#### Option B: Use ST-Link Utilities on Windows Host
Install ST-Link utilities on Windows host and use network debugging:
1. Install [STM32CubeIDE](https://www.st.com/en/development-tools/stm32cubeide.html) or [ST-Link Utilities](https://www.st.com/en/development-tools/stsw-link004.html)
2. Use OpenOCD in container with TCP connection
3. Configure VS Code to debug via network connection

### 4. Windows File System Performance

#### Use WSL2 File System (Recommended)
```bash
# Clone your project in WSL2 for best performance
cd /home/username/
git clone https://github.com/your-username/your-stm32-project.git
cd your-stm32-project

# Open in VS Code from WSL2
code .
```

#### Windows File System (Alternative)
```bash
# If using Windows file system
# Clone to Windows directory
git clone https://github.com/your-username/your-stm32-project.git C:\dev\your-stm32-project

# Open in VS Code
code C:\dev\your-stm32-project
```

### 5. Windows-Specific Troubleshooting

#### Docker Desktop Not Starting
```powershell
# Check WSL2 status
wsl --status

# Restart WSL2 if needed  
wsl --shutdown
# Wait 10 seconds, then start Docker Desktop
```

#### Permission Issues
```powershell  
# Run VS Code as Administrator if needed
# Right-click VS Code → "Run as Administrator"
```

#### Line Ending Issues
```bash
# In the container terminal
git config --global core.autocrlf false
git config --global core.eol lf
```

## Quick Setup for STM32 Development

### 1. Create DevContainer Configuration
Create `.devcontainer/devcontainer.json` in your STM32 project:

```json
{
  "name": "STM32 Development Environment",
  "image": "cpp-arm-dev:latest",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools", 
        "marus25.cortex-debug",
        "dan-c-underwood.arm"
      ]
    }
  },
  "mounts": [
    "source=${localWorkspaceFolder},target=/home/kdev/workspaces/project,type=bind"
  ],
  "remoteUser": "kdev",
  "privileged": true,
  "runArgs": [
    "--device=/dev/bus/usb:/dev/bus/usb"
  ],
  "postCreateCommand": "setup-pre-commit /home/kdev/workspaces/project && stm32-tools gnuarm && echo 'STM32 development environment ready!'"
}
```

### 2. Start Development
1. Open your STM32 project folder in VS Code
2. Press `F1` → "Dev Containers: Reopen in Container"  
3. Container builds and installs GNU ARM toolchain automatically
4. Your project is mounted at `/home/kdev/workspaces/project`

### 3. First-Time Setup in Container
```bash
# Verify ARM toolchain installation
stm32-tools status

# Add tools to PATH 
stm32-tools updatepath

# Verify STM32 toolchain
arm-none-eabi-gcc --version
```

## Configuration Details

### Workspace Mounting

```json
"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
```

- Your project files are accessible at `/workspace` in the container
- Changes are synced between host and container
- Uses `cached` consistency for better performance on macOS

### SSH Credentials

```json
"mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/kdev/.ssh,type=bind,consistency=cached,readonly"
]
```

- Your SSH keys are available in the container for user `kdev`
- Mounted as read-only for security
- Allows git operations with SSH remotes

### Installed Extensions

The following VS Code extensions are automatically installed:

- **ms-vscode.cpptools** - C/C++ IntelliSense and debugging
- **ms-vscode.cpptools-extension-pack** - C/C++ extension pack
- **ms-vscode.cmake-tools** - CMake integration
- **twxs.cmake** - CMake language support
- **ms-python.python** - Python support
- **ms-python.vscode-pylance** - Python language server
- **eamodio.gitlens** - Git integration

### VS Code Settings

```json
"settings": {
    "terminal.integrated.defaultProfile.linux": "zsh",
    "cmake.configureOnOpen": false,
    "C_Cpp.default.compilerPath": "/usr/bin/g++",
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "files.eol": "\n"
}
```

- Default terminal is zsh (with Oh My Zsh)
- CMake doesn't auto-configure on open
- Default C++ compiler is GCC
- Python 3.13 is the default interpreter
- All files use LF line endings

### Post-Create Commands

```json
"postCreateCommand": "git config --global --add safe.directory /workspace && git config --global core.autocrlf input"
```

Runs after container creation:
- Marks workspace as safe directory for git
- Configures git to use LF line endings

## Customization

### Adding More Extensions

Edit `.devcontainer/devcontainer.json`:

```json
"extensions": [
    "ms-vscode.cpptools",
    // ... existing extensions ...
    "your-extension-id"
]
```

### Changing Settings

Add or modify settings:

```json
"settings": {
    "terminal.integrated.defaultProfile.linux": "bash",
    "editor.formatOnSave": true,
    "C_Cpp.clang_format_style": "Google"
}
```

### Mounting Additional Directories

Add to the `mounts` array:

```json
"mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/kdev/.ssh,type=bind,consistency=cached,readonly",
    "source=${localEnv:HOME}/.gitconfig,target=/home/kdev/.gitconfig,type=bind,readonly"
]
```

## Common Tasks

### Opening Terminal

- Press `` Ctrl+` `` or `Cmd+` `` (Mac)
- Or use menu: Terminal → New Terminal

### Building C++ Projects

1. Open the Command Palette (`F1`)
2. Type "CMake: Configure"
3. Select a kit (e.g., GCC 13.2.0)
4. Build with "CMake: Build" or press `F7`

### Debugging

1. Set breakpoints in your code
2. Press `F5` or use Run → Start Debugging
3. Configure `launch.json` for your project:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "C++ Debug",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/myapp",
            "cwd": "${workspaceFolder}",
            "MIMode": "gdb"
        }
    ]
}
```

### Using ARM Toolchains

In the integrated terminal:

```bash
# Use ATfE toolchain
/opt/atfe21.1/bin/clang --version

# Use GNU ARM toolchain
/opt/gnuarm14.3/bin/arm-none-eabi-gcc --version
```

## Rebuilding the Container

If you modify the Dockerfile:

1. Press `F1`
2. Select "Dev Containers: Rebuild Container"
3. Or "Dev Containers: Rebuild Container Without Cache" for a clean build

## Troubleshooting

### Container Won't Start

Check Docker Desktop is running:
```bash
docker ps
```

### SSH Keys Not Working

Ensure your SSH keys are in `~/.ssh/`:
```bash
ls -la ~/.ssh/
```

### Extensions Not Installing

Manually install in the container:
1. Open Extensions panel (`Ctrl+Shift+X`)
2. Search for the extension
3. Click Install

### Performance Issues on macOS

The `cached` consistency mode should help, but you can also try:
- Use Docker Desktop with VirtioFS
- Reduce the number of files in your workspace
- Add commonly rebuilt directories to `.dockerignore`

### Port Forwarding

To expose ports from the container:

```json
"forwardPorts": [8080, 3000],
"portsAttributes": {
    "8080": {
        "label": "Web Server"
    }
}
```

## Advanced Configuration

### Using Docker Compose

Create `.devcontainer/docker-compose.yml`:

```yaml
version: '3.8'
services:
  app:
    build:
      context: ..
      dockerfile: Dockerfile
    volumes:
      - ..:/workspace:cached
    command: sleep infinity
```

Update `devcontainer.json`:

```json
{
    "name": "C++ ARM Development",
    "dockerComposeFile": "docker-compose.yml",
    "service": "app",
    "workspaceFolder": "/workspace"
}
```

### Non-Root User Configuration

This container runs as the non-root user `kdev` (UID 1000) by default for better security:

**Features:**
- User `kdev` with home directory `/home/kdev`
- Passwordless sudo access for development tasks
- SSH keys mounted to `/home/kdev/.ssh`
- Workspace owned by `kdev` user

**Configuration already included:**

```dockerfile
ARG USERNAME=kdev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
```

**DevContainer configuration:**

```json
"remoteUser": "kdev"
```

## Windows-Specific Troubleshooting

### Docker Desktop Issues

#### "Docker Desktop is starting..." (stuck)
```powershell
# Restart Docker Desktop service
net stop com.docker.service
net start com.docker.service

# Or restart WSL2
wsl --shutdown
# Wait 10 seconds, start Docker Desktop
```

#### "Docker daemon is not running"
1. Open Docker Desktop manually  
2. Check system tray for Docker whale icon
3. Right-click → "Start Docker Desktop"

#### WSL2 Integration Issues  
```powershell
# Check WSL2 distros
wsl --list --verbose

# Reset WSL2 if needed
wsl --shutdown
wsl --unregister Ubuntu  # if using Ubuntu
wsl --install -d Ubuntu
```

### VS Code DevContainer Issues

#### Container builds but won't start on Windows
```json
// Add to devcontainer.json for Windows compatibility
{
  "runArgs": [
    "--init"  // Helps with signal handling on Windows
  ],
  "shutdownAction": "stopContainer"  // Clean shutdown
}
```

#### File permission issues (Windows file system)
```json
// Use bind mount with specific options
{
  "mounts": [
    "source=${localWorkspaceFolder},target=/home/kdev/workspaces/project,type=bind,consistency=cached"
  ],
  "remoteEnv": {
    "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}"
  }
}
```

### STM32 Hardware Issues on Windows

#### ST-Link not detected in container
**Solution 1: Use ST-Link on Windows host**
```bash
# In container: Use OpenOCD with network debugging
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg -c "bindto 0.0.0.0"

# From Windows host: Connect to container IP
# Configure VS Code to debug via TCP
```

**Solution 2: USB Device passthrough (Advanced)**
```powershell
# Install usbipd-win on Windows host
winget install usbipd

# List USB devices
usbipd list

# Attach ST-Link to WSL2
usbipd attach --wsl --busid <BUSID>
```

#### OpenOCD connection issues
```bash
# In container: Check for existing processes
sudo pkill openocd
sudo pkill st-util

# Try manual OpenOCD connection
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg -d 3
```

### Performance Optimization on Windows

#### Slow file operations  
**Use WSL2 file system:**
```bash
# Clone projects in WSL2, not Windows file system
cd /home/username/projects/
git clone https://github.com/your-repo/project.git
code ./project  # Opens in VS Code with DevContainer
```

#### Container startup slow
```json
// Optimize devcontainer.json
{
  "build": {
    "dockerfile": "../Dockerfile",
    "options": [
      "--no-cache"  // Remove for faster rebuilds after first build
    ]
  },
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/project,type=bind,consistency=cached"
}
```

### Git and SSH on Windows

#### SSH keys not working in container
```powershell
# On Windows: Ensure SSH keys are in standard location
ls C:\Users\%USERNAME%\.ssh\

# Check key permissions (in WSL2)
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

#### Line ending issues
```bash
# Configure git globally in container
git config --global core.autocrlf false
git config --global core.eol lf

# Or add to devcontainer.json
{
  "postCreateCommand": "git config --global core.autocrlf false && git config --global core.eol lf"
}
```

### Helpful Windows Commands

```powershell
# Check Docker version
docker --version

# List running containers
docker ps

# Check WSL2 integration
docker context ls

# View Docker Desktop logs
# Docker Desktop → Settings → Troubleshoot → Get Support → View Logs

# Restart WSL2 completely  
wsl --shutdown
# Wait 8-10 seconds before restarting
```