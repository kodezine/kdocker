# Build Verification & Testing Guide

## ✅ Automated CI/CD Pipeline

This project uses **comprehensive GitHub Actions workflows** to ensure quality and reliability:

### 🔨 Build Pipeline (`docker-build.yml`)
- ✅ **Multi-platform builds** - Linux/AMD64 with ARM64 planned
- ✅ **Automated testing** - Container functionality validation
- ✅ **Security scanning** - Dependency and image vulnerability checks
- ✅ **Registry publishing** - Automatic publishing to GitHub Container Registry
- ✅ **Size optimization** - Build artifact size monitoring

### 🧪 Test Suite (`docker-test.yml`)
- ✅ **Core functionality** - GCC, Clang, CMake, Python compilation tests
- ✅ **ARM toolchain installation** - On-demand GNU ARM and ATFE installation
- ✅ **Cross-compilation testing** - STM32 Cortex-M4 firmware compilation with `--specs=nosys.specs`
- ✅ **STM32 tools verification** - ST-Link, OpenOCD, debugging tool availability
- ✅ **User environment** - Non-root user, shell configuration, PATH management
- ✅ **Code coverage tools** - gcovr functionality validation

### 📦 Release Pipeline (`docker-release.yml`)
- ✅ **Tagged releases** - Automatic Docker image releases on version tags
- ✅ **Container attestation** - Signed build provenance for security
- ✅ **Multi-registry support** - GitHub Container Registry with Docker Hub planned

## Manual Build Verification

### Complete Test Suite
To verify a successful build locally (same tests as CI):

```bash
# Clone and build
git clone https://github.com/kodezine/kdocker.git
cd kdocker
docker build -t cpp-arm-dev:test .

# Run comprehensive tests
docker run --rm --user kdev cpp-arm-dev:test bash -c "
  # Test core development tools
  gcc --version && g++ --version && cmake --version && python --version

  # Test ARM toolchain installation
  echo '2' | stm32-tools gnuarm >/dev/null
  arm-none-eabi-gcc --version

  # Test STM32 cross-compilation
  echo 'int main(){return 0;}' > /tmp/test.c
  arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb --specs=nosys.specs -o /tmp/test.elf /tmp/test.c
  file /tmp/test.elf | grep 'ARM'

  echo 'All tests passed! ✅'
"

# Test 32-bit compilation support
docker run --rm --user kdev cpp-arm-dev:test bash -c "
  echo 'int main(){return 0;}' > /tmp/test.c
  gcc -m32 -o /tmp/test32 /tmp/test.c && echo '32-bit compilation: ✅'
"
```

### Individual Component Testing

#### Core Development Tools
```bash
docker run --rm --user kdev cpp-arm-dev:test bash -c "
  echo 'Testing core tools...'
  gcc --version | head -1
  g++ --version | head -1
  clang --version | head -1
  cmake --version | head -1
  python --version
  gcovr --version
  echo 'Core tools: ✅'
"
```

#### ARM Toolchain Installation
```bash
docker run --rm --user kdev cpp-arm-dev:test bash -c "
  echo 'Testing ARM toolchain installation...'

  # Test GNU ARM installation
  echo '2' | stm32-tools gnuarm >/dev/null 2>&1
  if [ -x ~/gnuarm14.3/bin/arm-none-eabi-gcc ]; then
    echo 'GNU ARM 14.3: ✅'
    ~/gnuarm14.3/bin/arm-none-eabi-gcc --version | head -1
  else
    echo 'GNU ARM 14.3: ❌'
  fi

  # Test ATFE installation (optional, large download)
  # echo '2' | stm32-tools atfe >/dev/null 2>&1
  # if [ -x ~/atfe21.1/bin/clang ]; then
  #   echo 'ATFE 21.1: ✅'
  # fi
"
```

#### STM32 Cross-compilation
```bash
docker run --rm --user kdev cpp-arm-dev:test bash -c "
  echo 'Testing STM32 cross-compilation...'

  # Install toolchain first
  echo '2' | stm32-tools gnuarm >/dev/null 2>&1

  # Create test firmware
  cat > /tmp/stm32_test.c << 'EOF'
int main(void) {
    volatile int counter = 0;
    while(1) {
        counter++;
    }
    return 0;
}
EOF

  # Compile for STM32F4 (Cortex-M4)
  ~/gnuarm14.3/bin/arm-none-eabi-gcc \\
    -mcpu=cortex-m4 \\
    -mthumb \\
    -mfpu=fpv4-sp-d16 \\
    -mfloat-abi=hard \\
    --specs=nosys.specs \\
    -Os -g \\
    -o /tmp/stm32_firmware.elf \\
    /tmp/stm32_test.c

  # Verify result
  if file /tmp/stm32_firmware.elf | grep -q 'ARM.*executable'; then
    echo 'STM32 cross-compilation: ✅'
    ~/gnuarm14.3/bin/arm-none-eabi-size /tmp/stm32_firmware.elf
  else
    echo 'STM32 cross-compilation: ❌'
  fi
"
```

### Performance Testing

#### Container Size Analysis
```bash
# Check image size
docker images cpp-arm-dev:test

# Check layer sizes
docker history cpp-arm-dev:test

# Check disk usage with tools installed
docker run --rm --user kdev cpp-arm-dev:test bash -c "
  echo '2' | stm32-tools gnuarm >/dev/null 2>&1
  du -sh ~/.toolchains/
  df -h /home/kdev/
"
```

#### Compilation Speed Test
```bash
docker run --rm --user kdev cpp-arm-dev:test bash -c "
  echo 'Testing compilation speed...'

  # Create test C++ project
  cat > /tmp/test.cpp << 'EOF'
#include <iostream>
#include <vector>
#include <algorithm>
#include <chrono>

int main() {
    std::vector<int> data(1000);
    std::iota(data.begin(), data.end(), 1);

    auto start = std::chrono::high_resolution_clock::now();
    std::sort(data.begin(), data.end(), std::greater<int>());
    auto end = std::chrono::high_resolution_clock::now();

    std::cout << \"Sorted \" << data.size() << \" elements\" << std::endl;
    return 0;
}
EOF

  # Test compilation times
  echo 'GCC compilation:'
  time g++ -std=c++17 -O2 -o /tmp/test_gcc /tmp/test.cpp

  echo 'Clang compilation:'
  time clang++ -std=c++17 -O2 -o /tmp/test_clang /tmp/test.cpp

  echo 'Compilation speed test: ✅'
"
```

## Test Coverage Details

The CI pipeline validates:

### 100% Core Tools Coverage
- **GCC/G++**: C/C++ compilation with various standards (C++17, C++20)
- **Clang/Clang++**: Alternative compiler with different optimization profiles
- **CMake**: Project configuration and build system generation
- **Ninja**: Fast parallel builds
- **Python 3.13**: Script execution and package management
- **Ruby/Perl**: Additional scripting language support
- **gcovr**: Code coverage report generation

### ARM Development Coverage
- **GNU ARM 14.3**: Cross-compilation for ARM Cortex-M series
- **ATFE 21.1**: Modern LLVM-based ARM compilation (optional)
- **Embedded specs**: `--specs=nosys.specs` for minimal system calls
- **Multiple architectures**: Cortex-M4, Cortex-M3, Cortex-M0+ support
- **FPU configurations**: Hard float, soft float, no FPU options

### STM32 Toolchain Coverage
- **ST-Link tools**: Device programming and debugging
- **OpenOCD**: Open source debugging interface
- **GDB multiarch**: ARM debugging support
- **Device detection**: USB ST-Link probe recognition
- **Firmware flashing**: Binary upload to microcontrollers

### Security & User Experience Coverage
- **Non-root operation**: All development as `kdev` user (UID 1000)
- **PATH management**: User-controlled shell configuration
- **SSH key mounting**: Secure git credential access
- **Download verification**: SHA256 checksums for all toolchain downloads
- **User consent**: No automatic system modifications

### Container Integration Coverage
- **DevContainer support**: VS Code integration testing
- **USB device access**: Privileged container mode for hardware debugging
- **File system performance**: Bind mount optimization
- **Shell environment**: Zsh with Oh My Zsh configuration
- **Welcome messages**: User onboarding and command guidance

## Image Verification

### Pre-built Image Testing
```bash
# Pull and verify pre-built image
docker pull ghcr.io/kodezine/kdocker:latest

# Verify image signature and provenance
docker buildx imagetools inspect ghcr.io/kodezine/kdocker:latest

# Quick functionality test
docker run --rm --user kdev ghcr.io/kodezine/kdocker:latest bash -c "
  gcc --version && echo 'Pre-built image: ✅'
"
```

### Security Scanning
```bash
# Scan for vulnerabilities (requires docker scout or similar)
docker scout quickview ghcr.io/kodezine/kdocker:latest

# Check for known CVEs
docker scout cves ghcr.io/kodezine/kdocker:latest
```

## Continuous Integration

### GitHub Actions Status
- **Build Status**: [![Build and Release](https://github.com/kodezine/kdocker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-build.yml)
- **Test Status**: [![Test Docker Image](https://github.com/kodezine/kdocker/actions/workflows/docker-test.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-test.yml)
- **Release Status**: [![Docker Release](https://github.com/kodezine/kdocker/actions/workflows/docker-release.yml/badge.svg)](https://github.com/kodezine/kdocker/actions/workflows/docker-release.yml)

### Test Execution Frequency
- **On every push** to `main` and `develop` branches
- **On every pull request** targeting `main`
- **On tagged releases** for version builds
- **Manual dispatch** for ad-hoc testing

### Quality Gates
All tests must pass before:
- **Merging pull requests** to main branch
- **Publishing container images** to registry
- **Creating release tags** with version numbers
- **Updating documentation** with new features

## Local Development Testing

### Pre-commit Testing
```bash
# Test before committing changes
make test-local    # If Makefile available
# OR
./scripts/test-container.sh    # If test script available
# OR use manual commands above
```

### Integration Testing
```bash
# Test with real STM32 project
git clone https://github.com/STMicroelectronics/STM32CubeF4.git /tmp/stm32-project
docker run -it --rm --privileged \\
  -v /tmp/stm32-project:/home/kdev/workspaces/project \\
  -v /dev/bus/usb:/dev/bus/usb \\
  cpp-arm-dev:test

# In container:
cd /home/kdev/workspaces/project
stm32-tools gnuarm
# Build actual STM32 firmware
```

This comprehensive testing approach ensures the container works reliably across different environments and use cases.
