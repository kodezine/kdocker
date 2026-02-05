# Non-Root User Setup: `kdev`

This document explains the changes made to run the container with a non-root user named `kdev`.

## Changes Made

### 1. Dockerfile Updates

- Created user `kdev` with UID 1001 and GID 1001
- Added passwordless sudo access
- Set proper ownership of workspace directory
- Added ARM toolchain binaries to PATH environment variable
- Changed default user from `root` to `kdev`

### 2. DevContainer Configuration Updates

- Updated SSH mount path from `/root/.ssh` to `/home/kdev/.ssh`
- Changed `remoteUser` from `root` to `kdev`
- Maintained all existing VS Code extensions and settings

### 3. Documentation Updates

- Updated README.md with security section
- Updated devcontainer.md with non-root user configuration
- Updated SSH mounting examples

## User Details

```
Username: kdev
UID: 1001
GID: 1001
Home Directory: /home/kdev
Shell: /bin/zsh (with Oh My Zsh)
Sudo Access: Passwordless (NOPASSWD:ALL)
```

## Running the Container

### Basic Usage

```bash
# Build the image
docker build -t cpp-arm-dev .

# Run interactively
docker run -it --rm cpp-arm-dev

# Check current user
whoami  # Should output: kdev
```

### With Workspace Mount

```bash
# Mount current directory
docker run -it --rm -v $(pwd):/workspace cpp-arm-dev

# Mount with SSH keys
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.ssh:/home/kdev/.ssh:ro \
  cpp-arm-dev
```

### Using Sudo

```bash
# Inside the container, you can use sudo without password
sudo apt update
sudo systemctl status  # if needed
```

### File Permissions

```bash
# Files created in /workspace will have kdev ownership
touch /workspace/test.txt
ls -la /workspace/test.txt
# -rw-r--r-- 1 kdev kdev 0 Oct  5 12:00 test.txt
```

## VS Code DevContainer

The DevContainer automatically uses the `kdev` user:

1. **SSH Keys**: Mounted to `/home/kdev/.ssh`
2. **Git Config**: Can be mounted to `/home/kdev/.gitconfig`
3. **Extensions**: All work normally with the non-root user
4. **Terminal**: Opens as `kdev` user with sudo access

## ARM Toolchains Access

The ARM toolchains are accessible via PATH for the `kdev` user:

```bash
# ATfE toolchain
clang --version  # Works directly
/opt/atfe21.1/bin/clang --version  # Also works

# GNU ARM toolchain
arm-none-eabi-gcc --version  # Works directly
/opt/gnuarm14.3/bin/arm-none-eabi-gcc --version  # Also works
```

## Shell Configuration

### Zsh with Oh My Zsh

The `kdev` user is configured with **zsh** as the default shell and includes **Oh My Zsh** for enhanced functionality:

```bash
# Check current shell
echo $SHELL
# /bin/zsh

# Oh My Zsh location
ls -la ~/.oh-my-zsh/

# Zsh configuration
cat ~/.zshrc
```

### Features

- **Syntax highlighting**: Better command visibility
- **Auto-completion**: Enhanced tab completion
- **Git integration**: Git status in prompt
- **Plugin system**: Extensible with Oh My Zsh plugins
- **Themes**: Customizable appearance

### Customization

```bash
# Edit zsh configuration
nano ~/.zshrc

# Change theme (edit ~/.zshrc)
ZSH_THEME="agnoster"  # or "powerlevel10k/powerlevel10k"

# Add plugins (edit ~/.zshrc)
plugins=(git docker kubectl python pip)

# Apply changes
source ~/.zshrc
```

## Benefits

### Security

- **Principle of least privilege**: No unnecessary root access
- **File ownership**: Files match host user permissions (UID 1001)
- **Read-only SSH**: SSH keys mounted read-only for security

### Compatibility

- **Host file permissions**: Works better with host file systems
- **IDE integration**: Better VS Code file watching and permissions
- **Docker best practices**: Follows security recommendations

### Development Experience

- **Sudo available**: Can install packages when needed
- **Standard user**: Behaves like normal Linux user account
- **Tool compatibility**: All development tools work normally
- **Enhanced shell**: Zsh with Oh My Zsh for better productivity
- **VS Code integration**: Zsh as default terminal in DevContainer

## Migration from Root User

If you have existing scripts or workflows expecting root user:

```bash
# Old way (as root)
apt update && apt install -y package

# New way (as kdev with sudo)
sudo apt update && sudo apt install -y package
```

Most development tasks don't require root access and work unchanged.

## Troubleshooting

### Permission Issues

```bash
# If you need to fix file permissions
sudo chown -R kdev:kdev /workspace

# Check current user and groups
id
groups
```

### SSH Key Issues

```bash
# Check SSH key permissions
ls -la ~/.ssh/
# Should show files owned by kdev:kdev

# Fix SSH permissions if needed
sudo chmod 600 ~/.ssh/id_rsa
sudo chmod 644 ~/.ssh/id_rsa.pub
sudo chmod 700 ~/.ssh
```

### Package Installation

```bash
# Install packages (requires sudo)
sudo apt update
sudo apt install -y new-package

# Python packages (user install)
pip install --user package

# System-wide Python packages (requires sudo)
sudo pip install package
```
