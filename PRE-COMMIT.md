# Pre-commit Configuration Guide

This repository uses [pre-commit](https://pre-commit.com/) to ensure code quality and consistency across all file types. The configuration automatically validates and formats Docker files, JSON, shell scripts, Markdown, and more.

## 🚀 Quick Setup

### 1. Install pre-commit

```bash
# Using pip
pip install pre-commit

# Using conda
conda install -c conda-forge pre-commit

# Using homebrew (macOS)
brew install pre-commit

# Using apt (Ubuntu/Debian)
sudo apt install pre-commit
```

### 2. Install the hooks

```bash
# In the repository root
pre-commit install

# Also install commit message hooks
pre-commit install --hook-type commit-msg
```

### 3. Run on all files (optional)

```bash
# Run all hooks on all files
pre-commit run --all-files
```

## 🔧 Configured Hooks

### General File Validation
- ✅ **Trailing whitespace removal**
- ✅ **End-of-file fixing** (ensure files end with newline)
- ✅ **Large file detection** (10MB limit)
- ✅ **Merge conflict detection**
- ✅ **Private key detection** (security)
- ✅ **Line ending normalization** (LF)

### JSON & YAML
- ✅ **JSON validation and formatting** (4-space indentation)
- ✅ **YAML validation and linting** (yamllint)
- ✅ **DevContainer JSON validation**

### Shell Scripts
- ✅ **ShellCheck linting** (warning level)
- ✅ **Shell formatting** (shfmt - 4 space indentation)
- ✅ **Executable permissions** (auto-fix)

### Docker
- ✅ **Dockerfile linting** (hadolint)
- ✅ **Docker build validation** (dry-run)
- ✅ **Docker Compose validation**

### Markdown
- ✅ **Markdown linting** (markdownlint with auto-fix)

### C/C++ (if present)
- ✅ **Code formatting** (clang-format with Google style)

### Python (if present)  
- ✅ **Code formatting** (Black)
- ✅ **Import sorting** (isort)

### Security
- ✅ **Secret detection** (detect-secrets)
- ✅ **TODO/FIXME detection** (warning)

### Git
- ✅ **Conventional commit messages** (enforced)

## 📝 Conventional Commits

This repository enforces [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types
- `feat`: A new feature
- `fix`: A bug fix  
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code changes that neither fix bugs nor add features
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates
- `ci`: CI/CD changes
- `build`: Build system or dependency changes

### Examples
```bash
git commit -m "feat(docker): add on-demand ARM toolchain installation"
git commit -m "fix(devcontainer): correct path configuration for STM32 tools"
git commit -m "docs: add pre-commit setup guide"
git commit -m "chore: update dependencies to latest versions"
```

## 🔧 Configuration Files

### `.pre-commit-config.yaml`
Main configuration file defining all hooks and their settings.

### `.secrets.baseline`
Baseline file for detect-secrets to track known false positives.

### Excluded Files
The following files/patterns are excluded from most hooks:
- `.vscode/*.json` (VS Code configuration files)
- `*.jsonc` (JSON with comments)
- `*.patch` and `*.diff` (patch files)
- `*.lock` and `*.log` (generated files)
- `node_modules/`, `.git/`, `build/`, `dist/` (directories)

## 🚀 Running Hooks

### Automatic (Recommended)
Hooks run automatically on `git commit` and `git push` after installation.

### Manual Execution
```bash
# Run all hooks on staged files
pre-commit run

# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run shellcheck
pre-commit run hadolint-docker

# Run hooks on specific files
pre-commit run --files path/to/file.sh
```

### Skip Hooks (Emergency)
```bash
# Skip all hooks for a commit (not recommended)
git commit --no-verify -m "emergency fix"

# Skip specific hook
SKIP=shellcheck git commit -m "commit message"
```

## 🔧 Customization

### Adding New File Types
Edit `.pre-commit-config.yaml` and add new hooks or modify existing ones:

```yaml
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.5.0
  hooks:
    - id: check-xml  # Add XML validation
```

### Adjusting Hook Configuration
Modify hook arguments:

```yaml
- id: shellcheck
  args: [--severity=error]  # Change from warning to error level
```

### Local Custom Hooks
Add repository-specific hooks:

```yaml
- repo: local
  hooks:
    - id: custom-validation
      name: Custom Project Validation
      entry: ./scripts/validate.sh
      language: system
```

## 🐛 Troubleshooting

### Common Issues

1. **Hook installation failed**
   ```bash
   pre-commit clean
   pre-commit install
   ```

2. **Hooks running slowly**
   ```bash
   pre-commit run --all-files  # Run once to cache
   ```

3. **False positive in secrets detection**
   ```bash
   detect-secrets scan --baseline .secrets.baseline
   ```

4. **Docker validation fails**
   - Ensure Docker is running
   - Check Dockerfile syntax

5. **ShellCheck errors**
   - Fix shell script issues or add `# shellcheck disable=SC####`
   - See [ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki) for rules

### Updating Hooks
```bash
# Update all hooks to latest versions
pre-commit autoupdate

# Update specific hook
pre-commit autoupdate --repo https://github.com/hadolint/hadolint
```

### Bypassing Hooks During Development
```bash
# Temporarily disable for development
git config hooks.pre-commit false

# Re-enable
git config hooks.pre-commit true
```

## 📊 Hook Performance

View hook execution times:
```bash
pre-commit run --all-files --verbose
```

Optimize slow hooks by:
- Excluding unnecessary files
- Running only on changed files
- Using faster alternatives

## 🔗 Integration

### CI/CD Integration
The configuration includes pre-commit.ci settings for automatic updates and fixes in pull requests.

### IDE Integration
Most IDEs can integrate with pre-commit:
- **VS Code**: Install pre-commit extension
- **PyCharm**: Configure as external tool
- **Vim/Neovim**: Use pre-commit plugins

### GitHub Actions
```yaml
name: Pre-commit
on: [push, pull_request]
jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
    - uses: pre-commit/action@v3.0.1
```

This comprehensive pre-commit setup ensures consistent, high-quality code across all file types in the repository!