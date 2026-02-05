# Example Templates for Downstream Projects

This directory contains ready-to-use templates for projects using the kdocker dev container.

## Files

### `devcontainer-basic.json`

A minimal devcontainer configuration for STM32 development.

**Features:**
- ✅ Pre-commit hooks auto-install
- ✅ GNU ARM toolchain installation
- ✅ Basic VS Code extensions
- ✅ ST-Link hardware access

**Usage:**
```bash
# 1. Copy to your project
mkdir -p .devcontainer
cp examples/devcontainer-basic.json .devcontainer/devcontainer.json

# 2. Open in VS Code
# Press F1 → "Dev Containers: Reopen in Container"
```

### `pre-commit-config-template.yaml`

A starter pre-commit configuration for embedded C/C++ projects.

**Hooks included:**
- C/C++ formatting (clang-format)
- Shell script linting (shellcheck)
- Markdown linting
- General file validation

**Usage:**
```bash
# Copy to your project root
cp examples/pre-commit-config-template.yaml .pre-commit-config.yaml

# Hooks will auto-install when you open the dev container!
```

## Quick Setup Guide

### Minimal Setup (Auto-configured)

1. **Copy devcontainer config:**
   ```bash
   mkdir -p .devcontainer
   cp examples/devcontainer-basic.json .devcontainer/devcontainer.json
   ```

2. **Optional: Add pre-commit config:**
   ```bash
   cp examples/pre-commit-config-template.yaml .pre-commit-config.yaml
   ```

3. **Open in VS Code:**
   - Press `F1` → "Dev Containers: Reopen in Container"
   - Wait for setup to complete
   - Start coding!

### What Happens Automatically

When you open the dev container:
1. ✅ Pre-commit hooks install (if `.pre-commit-config.yaml` exists)
2. ✅ GNU ARM toolchain installs
3. ✅ Git configuration applied
4. ✅ VS Code extensions install

### Customization

**Disable pre-commit auto-setup:**
```json
{
  "postCreateCommand": "stm32-tools gnuarm"
}
```

**Install all STM32 tools:**
```json
{
  "postCreateCommand": "setup-pre-commit ${containerWorkspaceFolder} && stm32-tools all"
}
```

**Skip toolchain installation:**
```json
{
  "postCreateCommand": "setup-pre-commit ${containerWorkspaceFolder}"
}
```

## Documentation

- **Full DevContainer Guide**: [DEVCONTAINER.md](../DEVCONTAINER.md)
- **Pre-commit Guide**: [PRE-COMMIT.md](../PRE-COMMIT.md)
- **Main README**: [README.md](../README.md)
