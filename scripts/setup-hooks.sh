#!/bin/bash

# Git Hooks Setup Script for STM32 Docker Development Environment
# This script configures Git hooks for automated code quality checks

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT
readonly HOOKS_DIR="${PROJECT_ROOT}/.git/hooks"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "This directory is not a Git repository"
        log_info "Please run 'git init' first"
        exit 1
    fi

    log_success "Git repository detected"
}

# Install pre-commit if not available
install_precommit() {
    if command -v pre-commit >/dev/null 2>&1; then
        log_success "pre-commit is already installed ($(pre-commit --version))"
        return 0
    fi

    log_info "Installing pre-commit..."

    # Try different installation methods
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user pre-commit
    elif command -v pip >/dev/null 2>&1; then
        pip install --user pre-commit
    elif command -v brew >/dev/null 2>&1; then
        brew install pre-commit
    elif command -v conda >/dev/null 2>&1; then
        conda install -c conda-forge pre-commit
    else
        log_error "Could not install pre-commit automatically"
        log_info "Please install pre-commit manually:"
        log_info "  pip install pre-commit"
        log_info "  or visit: https://pre-commit.com/#installation"
        exit 1
    fi

    log_success "pre-commit installed successfully"
}

# Setup Git hooks using pre-commit
setup_git_hooks() {
    log_info "Setting up Git hooks with pre-commit..."

    # Add user local bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Check if core.hooksPath is set and temporarily unset it for this repo
    if git config core.hooksPath >/dev/null 2>&1; then
        log_info "Temporarily unsetting core.hooksPath for this repository..."
        git config --local core.hooksPath ""
    fi

    # Install pre-commit hooks
    if ! pre-commit install; then
        log_error "Failed to install pre-commit hooks"
        exit 1
    fi

    # Install commit message hooks
    if ! pre-commit install --hook-type commit-msg; then
        log_warning "Failed to install commit-msg hooks (optional)"
    fi

    # Install pre-push hooks
    if ! pre-commit install --hook-type pre-push; then
        log_warning "Failed to install pre-push hooks (optional)"
    fi

    log_success "Git hooks installed successfully"
}

# Create custom Git hooks
create_custom_hooks() {
    log_info "Creating custom Git hooks..."

    # Create pre-commit hook (backup if pre-commit fails)
    cat >"${HOOKS_DIR}/pre-commit.manual" <<'EOF'
#!/bin/bash

# Manual pre-commit hook for STM32 Docker Environment
# This is a fallback if pre-commit framework is not available

set -e

echo "Running manual pre-commit checks..."

# Check for large files
find . -name "*.tar.gz" -o -name "*.zip" -o -name "*.deb" -o -name "*.rpm" | while read -r file; do
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if [ "$size" -gt 10485760 ]; then  # 10MB
            echo "Error: Large file detected: $file ($(numfmt --to=iec $size))"
            echo "Please use Git LFS for large files or add to .gitignore"
            exit 1
        fi
    fi
done

# Check for merge conflicts
if git diff --cached --name-only | xargs grep -l "^<<<<<<< \|^======= \|^>>>>>>> " 2>/dev/null; then
    echo "Error: Merge conflict markers detected in staged files"
    exit 1
fi

# Check Docker files with basic linting
if git diff --cached --name-only | grep -E "Dockerfile|\.dockerfile$" >/dev/null; then
    echo "Checking Dockerfile syntax..."
    git diff --cached --name-only | grep -E "Dockerfile|\.dockerfile$" | while read -r dockerfile; do
        if [ -f "$dockerfile" ]; then
            # Basic Dockerfile validation
            if ! grep -q "^FROM " "$dockerfile"; then
                echo "Error: $dockerfile missing FROM instruction"
                exit 1
            fi
        fi
    done
fi

# Check shell scripts
if git diff --cached --name-only | grep -E "\.sh$|\.bash$" >/dev/null; then
    echo "Checking shell scripts..."
    git diff --cached --name-only | grep -E "\.sh$|\.bash$" | while read -r script; do
        if [ -f "$script" ]; then
            # Check if executable
            if [ ! -x "$script" ]; then
                echo "Warning: $script is not executable"
            fi

            # Basic syntax check
            if ! bash -n "$script"; then
                echo "Error: Syntax error in $script"
                exit 1
            fi
        fi
    done
fi

echo "Manual pre-commit checks completed successfully"
EOF

    chmod +x "${HOOKS_DIR}/pre-commit.manual"

    # Create post-commit hook for notifications
    cat >"${HOOKS_DIR}/post-commit" <<'EOF'
#!/bin/bash

# Post-commit hook for STM32 Docker Environment

# Get commit info
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=format:"%s")
BRANCH=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)

echo ""
echo "✅ Commit successful!"
echo "📝 Branch: $BRANCH"
echo "🔄 Hash: ${COMMIT_HASH:0:8}"
echo "💬 Message: $COMMIT_MSG"
echo ""

# Check if this is a Docker-related commit
if echo "$COMMIT_MSG" | grep -i -E "(docker|dockerfile|container|image)" >/dev/null; then
    echo "🐳 Docker-related commit detected"
    echo "💡 Consider running: make build && make test"
    echo ""
fi

# Check if this is a documentation commit
if git diff-tree --no-commit-id --name-only -r HEAD | grep -E "\.md$|README|CHANGELOG" >/dev/null; then
    echo "📚 Documentation updated"
    echo "💡 Consider updating version or changelog"
    echo ""
fi
EOF

    chmod +x "${HOOKS_DIR}/post-commit"

    # Create pre-push hook
    cat >"${HOOKS_DIR}/pre-push" <<'EOF'
#!/bin/bash

# Pre-push hook for STM32 Docker Environment

echo "🚀 Running pre-push validations..."

# Check if we're pushing to main/master
protected_branch='main|master'
current_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

if [[ $current_branch =~ $protected_branch ]]; then
    echo "🔒 Pushing to protected branch: $current_branch"

    # Run comprehensive tests before pushing to main
    echo "🧪 Running comprehensive tests..."

    # Check if Docker image builds
    if [ -f Dockerfile ]; then
        echo "🐳 Testing Docker build..."
        if ! docker build -t stm32-dev-test . >/dev/null 2>&1; then
            echo "❌ Docker build failed"
            echo "Please fix Docker build issues before pushing to $current_branch"
            exit 1
        fi
        echo "✅ Docker build successful"

        # Cleanup test image
        docker rmi stm32-dev-test >/dev/null 2>&1 || true
    fi

    # Check if all documentation is up to date
    if [ -f README.md ] && [ -f DEVCONTAINER.md ] && [ -f PRE-COMMIT.md ]; then
        echo "✅ Documentation files present"
    else
        echo "⚠️  Some documentation files may be missing"
    fi
fi

echo "✅ Pre-push validations completed"
EOF

    chmod +x "${HOOKS_DIR}/pre-push"

    log_success "Custom Git hooks created"
}

# Validate hook installation
validate_hooks() {
    log_info "Validating Git hook installation..."

    local hooks_installed=0

    # Check pre-commit hook
    if [ -f "${HOOKS_DIR}/pre-commit" ]; then
        log_success "pre-commit hook installed"
        hooks_installed=$((hooks_installed + 1))
    else
        log_warning "pre-commit hook not found"
    fi

    # Check commit-msg hook
    if [ -f "${HOOKS_DIR}/commit-msg" ]; then
        log_success "commit-msg hook installed"
        hooks_installed=$((hooks_installed + 1))
    else
        log_warning "commit-msg hook not found"
    fi

    # Check custom hooks
    if [ -f "${HOOKS_DIR}/post-commit" ]; then
        log_success "post-commit hook installed"
        hooks_installed=$((hooks_installed + 1))
    fi

    if [ -f "${HOOKS_DIR}/pre-push" ]; then
        log_success "pre-push hook installed"
        hooks_installed=$((hooks_installed + 1))
    fi

    if [ "$hooks_installed" -gt 0 ]; then
        log_success "Git hooks validation completed ($hooks_installed hooks active)"
    else
        log_error "No Git hooks found"
        exit 1
    fi
}

# Test hooks
test_hooks() {
    log_info "Testing Git hooks..."

    # Add user local bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Create a test file
    echo "# Test file for Git hooks" >test_hooks_file.md
    git add test_hooks_file.md

    # Test pre-commit hook (dry run)
    if pre-commit run --files test_hooks_file.md >/dev/null 2>&1; then
        log_success "Pre-commit hooks are working"
    else
        log_warning "Pre-commit hooks may have issues (check configuration)"
    fi

    # Clean up test file
    git reset HEAD test_hooks_file.md >/dev/null 2>&1 || true
    rm -f test_hooks_file.md

    log_success "Hook testing completed"
}

# Show hook status
show_status() {
    log_info "Git Hooks Status"
    log_info "================"

    echo ""
    echo "📁 Hooks directory: $HOOKS_DIR"
    echo ""

    if [ -d "$HOOKS_DIR" ]; then
        echo "📋 Installed hooks:"
        for hook in "$HOOKS_DIR"/*; do
            if [ -f "$hook" ] && [ -x "$hook" ]; then
                hook_name=$(basename "$hook")
                echo "  ✅ $hook_name"
            fi
        done
        echo ""
    fi

    # Add user local bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Check pre-commit status
    if command -v pre-commit >/dev/null 2>&1; then
        echo "🔧 Pre-commit framework:"
        pre-commit --version
        echo ""

        # Show configured hooks
        echo "📋 Configured pre-commit hooks:"
        pre-commit run --all-files --dry-run 2>/dev/null | grep -E "^- " | head -10
        echo ""
    fi

    echo "💡 Usage:"
    echo "  - Hooks run automatically on git commit/push"
    echo "  - Manual run: pre-commit run --all-files"
    echo "  - Skip hooks: git commit --no-verify"
    echo ""
}

# Main setup function
main() {
    local command="${1:-setup}"

    case "$command" in
    "setup" | "install" | "s")
        log_info "Setting up Git hooks for STM32 Docker Environment"
        log_info "=================================================="
        check_git_repo
        install_precommit
        setup_git_hooks
        create_custom_hooks
        validate_hooks
        test_hooks
        log_success "Git hooks setup completed successfully!"
        show_status
        ;;
    "status" | "st")
        show_status
        ;;
    "test" | "t")
        test_hooks
        ;;
    "uninstall" | "remove" | "u")
        log_info "Uninstalling Git hooks..."
        # Add user local bin to PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
        pre-commit uninstall >/dev/null 2>&1 || true
        pre-commit uninstall --hook-type commit-msg >/dev/null 2>&1 || true
        pre-commit uninstall --hook-type pre-push >/dev/null 2>&1 || true
        rm -f "${HOOKS_DIR}/post-commit"
        rm -f "${HOOKS_DIR}/pre-push"
        rm -f "${HOOKS_DIR}/pre-commit.manual"
        log_success "Git hooks uninstalled"
        ;;
    "update" | "up")
        log_info "Updating pre-commit hooks..."
        # Add user local bin to PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
        pre-commit autoupdate
        pre-commit install
        log_success "Pre-commit hooks updated"
        ;;
    "help" | "h" | "--help")
        echo "Git Hooks Setup Script for STM32 Docker Environment"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  setup, install, s  - Install and configure Git hooks (default)"
        echo "  status, st         - Show current Git hooks status"
        echo "  test, t           - Test Git hooks functionality"
        echo "  uninstall, u      - Remove all Git hooks"
        echo "  update, up        - Update pre-commit hooks to latest versions"
        echo "  help, h           - Show this help"
        echo ""
        echo "Git Hooks Configured:"
        echo "  pre-commit        - Code quality and linting checks"
        echo "  commit-msg        - Conventional commit message validation"
        echo "  post-commit       - Success notifications and suggestions"
        echo "  pre-push          - Comprehensive validation before push"
        echo ""
        ;;
    *)
        log_error "Unknown command: $command"
        log_info "Use '$0 help' for usage information"
        exit 1
        ;;
    esac
}

# Execute if run directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
    main "$@"
fi
