# VS Code DevContainer Setup for STM32 Development

## Overview

This guide shows how to use the STM32 development container with Visual Studio Code DevContainers for seamless embedded development.

## Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Docker Desktop or Docker Engine

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
  "postCreateCommand": "stm32-tools gnuarm && echo 'STM32 development environment ready!'"
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