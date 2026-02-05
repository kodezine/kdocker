# Git Hooks for STM32 Docker Development Environment

This repository uses **Git hooks** to automatically enforce code quality, security, and consistency. Git hooks run automatically during Git operations (commit, push, etc.) and provide immediate feedback during development.

## 🚀 Quick Setup

### Automatic Setup

```bash
# Setup all Git hooks automatically
./scripts/setup-hooks.sh

# Or use the Makefile shortcut
make setup-hooks
```

### Manual Setup

```bash
# Install pre-commit framework
pip install pre-commit

# Install hooks
pre-commit install
pre-commit install --hook-type commit-msg
pre-commit install --hook-type pre-push
```

## 🪝 Configured Git Hooks

### 1. **Pre-commit Hook**

**Triggers:** Before each `git commit`
**Purpose:** Code quality validation and automatic fixes

**Checks performed:**

- ✅ **File validation** (trailing whitespace, line endings, large files)
- ✅ **JSON/YAML formatting** (auto-fix with proper indentation)
- ✅ **Shell script linting** (ShellCheck with severity warnings)
- ✅ **Docker linting** (Hadolint for Dockerfile best practices)
- ✅ **Markdown formatting** (auto-fix common issues)
- ✅ **Security scanning** (detect private keys and secrets)
- ✅ **Merge conflict detection**

**Example output:**

```
Trim Trailing Whitespace.................................................Passed
Fix End of Files.........................................................Passed
Check JSON...............................................................Passed
ShellCheck...............................................................Passed
hadolint.................................................................Passed
```

### 2. **Commit Message Hook**

**Triggers:** During `git commit` (message validation)
**Purpose:** Enforce conventional commit format

**Format enforced:**

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Valid types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`

**Examples:**

```bash
git commit -m "feat(docker): add ARM toolchain on-demand installation"
git commit -m "fix(devcontainer): correct USB device permissions"
git commit -m "docs: update setup instructions for Git hooks"
```

### 3. **Pre-push Hook**

**Triggers:** Before `git push`
**Purpose:** Comprehensive validation before sharing code

**Validations:**

- 🐳 **Docker build test** (ensures Dockerfile builds successfully)
- 📚 **Documentation completeness** (check required files exist)
- 🔒 **Protected branch checks** (extra validation for main/master)
- 🧪 **Comprehensive testing** (for protected branches)

### 4. **Post-commit Hook**

**Triggers:** After successful `git commit`
**Purpose:** Provide feedback and suggestions

**Features:**

- ✅ **Success confirmation** with commit details
- 🐳 **Docker-related commit detection** (suggests running tests)
- 📚 **Documentation update detection** (suggests version updates)
- 🔄 **Branch and hash information**

## 🔧 Git Hooks Management

### Check Status

```bash
# Show current Git hooks status
./scripts/setup-hooks.sh status
make hooks-status

# List installed hooks
ls -la .git/hooks/
```

### Test Hooks

```bash
# Test Git hooks functionality
./scripts/setup-hooks.sh test

# Run pre-commit manually
pre-commit run --all-files

# Run specific hook
pre-commit run shellcheck
```

### Update Hooks

```bash
# Update all hooks to latest versions
./scripts/setup-hooks.sh update

# Update pre-commit configuration
pre-commit autoupdate
```

### Disable/Enable Hooks

```bash
# Temporarily disable all hooks
git config core.hooksPath /dev/null

# Re-enable hooks
git config --unset core.hooksPath

# Skip hooks for one commit (emergency use)
git commit --no-verify -m "emergency fix"

# Skip specific hook
SKIP=shellcheck git commit -m "commit message"
```

### Uninstall Hooks

```bash
# Remove all Git hooks
./scripts/setup-hooks.sh uninstall

# Remove specific hook type
pre-commit uninstall --hook-type commit-msg
```

## 🚀 Development Workflow with Git Hooks

### 1. **Initial Setup**

```bash
# Clone repository
git clone <repository-url>
cd kdocker

# Setup development environment
make dev-setup  # Includes Git hooks setup
```

### 2. **Daily Development**

```bash
# Make changes
vim Dockerfile

# Stage changes
git add Dockerfile

# Commit (hooks run automatically)
git commit -m "feat(docker): optimize base image size"

# Push (pre-push hook validates)
git push origin feature-branch
```

### 3. **Hook Feedback Examples**

**Successful commit:**

```
$ git commit -m "feat(docker): add ARM toolchain support"

Trim Trailing Whitespace.................................................Passed
Fix End of Files.........................................................Passed
Check JSON...............................................................Passed
hadolint.................................................................Passed

✅ Commit successful!
📝 Branch: feature-arm-toolchain
🔄 Hash: a1b2c3d4
💬 Message: feat(docker): add ARM toolchain support

🐳 Docker-related commit detected
💡 Consider running: make build && make test
```

**Failed validation:**

```
$ git commit -m "fix something"

conventional-pre-commit.................................................Failed
- hook id: conventional-pre-commit
- exit code: 1

Commit message does not follow Conventional Commits format!
Expected: <type>[scope]: <description>
Got: fix something

Please use format: feat|fix|docs|style|refactor|perf|test|chore|ci|build: description
```

### 4. **Bypassing Hooks (When Necessary)**

```bash
# Emergency commit (skip all hooks)
git commit --no-verify -m "hotfix: critical security patch"

# Skip specific problematic hook
SKIP=hadolint git commit -m "fix(docker): temporary workaround"
```

## 🔧 Customization

### Adding New Hooks

Edit `.pre-commit-config.yaml`:

```yaml
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.5.0
  hooks:
    - id: check-xml  # Add XML validation
```

### Custom Project Hook

```yaml
- repo: local
  hooks:
    - id: docker-build-test
      name: Docker Build Test
      entry: docker build -t test-image .
      language: system
      files: ^Dockerfile$
```

### Modifying Hook Behavior

```yaml
- id: shellcheck
  args: [--severity=error]  # Change severity level

- id: trailing-whitespace
  exclude: ^(.*\.patch|.*\.diff)$  # Add exclusions
```

## 🐛 Troubleshooting

### Common Issues

1. **Hooks not running:**

   ```bash
   # Reinstall hooks
   pre-commit install --overwrite
   ```

2. **Pre-commit not found:**

   ```bash
   # Install pre-commit
   pip install --user pre-commit
   # Add to PATH if needed
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. **Docker validation fails:**

   ```bash
   # Ensure Docker is running
   docker info

   # Check Dockerfile syntax
   docker build -t test .
   ```

4. **Shell script errors:**

   ```bash
   # Fix shell script syntax
   shellcheck scripts/setup-hooks.sh

   # Make scripts executable
   chmod +x scripts/*.sh
   ```

5. **Slow hook execution:**

   ```bash
   # Run hooks once to cache dependencies
   pre-commit run --all-files

   # Check hook performance
   pre-commit run --all-files --verbose
   ```

### Performance Optimization

- **File exclusions**: Add patterns to exclude generated files
- **Selective running**: Use `files` and `exclude` patterns
- **Local caching**: Pre-commit caches dependencies automatically

### Hook Debugging

```bash
# Debug specific hook
pre-commit run shellcheck --verbose

# Show hook configuration
pre-commit run --all-files --show-diff-on-failure

# Manual hook execution
.git/hooks/pre-commit
```

## 📊 Benefits of Git Hooks Approach

### ✅ **Advantages over Makefile-only approach:**

1. **Automatic Execution**: Runs without manual intervention
2. **Immediate Feedback**: Catches issues before they enter history
3. **Team Consistency**: Everyone gets the same validation
4. **Integration**: Works with any Git workflow/IDE
5. **Standard Practice**: Industry-standard approach
6. **Granular Control**: Different hooks for different Git operations

### 🔄 **Integration with Existing Tools:**

- ✅ **VS Code**: Git integration shows hook results
- ✅ **IDEs**: Most IDEs respect Git hooks
- ✅ **CI/CD**: Same hooks run in automated pipelines
- ✅ **Git GUI**: Works with any Git interface

### 📈 **Scalability:**

- ✅ **Team onboarding**: New developers get hooks automatically
- ✅ **Configuration updates**: Centrally managed via `.pre-commit-config.yaml`
- ✅ **Language support**: Extensible to any language/tool
- ✅ **Performance**: Runs only on changed files by default

## 🔗 Related Documentation

- **[Pre-commit Configuration](PRE-COMMIT.md)**: Detailed hook configuration
- **[DevContainer Setup](DEVCONTAINER.md)**: IDE integration
- **[Main README](README.md)**: Project overview
- **[Testing Guide](scripts/test.sh)**: Automated testing

## 🚀 Quick Reference

```bash
# Essential commands
./scripts/setup-hooks.sh          # Initial setup
git commit -m "feat: new feature" # Commit (hooks run automatically)
git push                          # Push (pre-push validation)
./scripts/setup-hooks.sh status   # Check hook status
pre-commit run --all-files        # Manual validation
```

Git hooks provide automatic, consistent, and immediate feedback for code quality, making them the ideal choice for maintaining high standards in collaborative development! 🎯
