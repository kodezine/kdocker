# Building and Configuration

## Build Options

### Basic Build

```bash
docker build -t cpp-arm-dev .
```

### Build with Build Arguments

The Dockerfile doesn't currently use build arguments, but you can modify it to accept custom versions:

```bash
# Example if you modify Dockerfile to accept PYTHON_VERSION
docker build --build-arg PYTHON_VERSION=3.12 -t cpp-arm-dev .
```

### Build without Cache

Force a fresh build without using cached layers:

```bash
docker build --no-cache -t cpp-arm-dev .
```

### Multi-platform Build

If you need to build for different architectures:

```bash
docker buildx build --platform linux/amd64 -t cpp-arm-dev .
```

## Build Time

Expected build times:
- **First build**: 15-25 minutes (depending on internet speed)
- **Subsequent builds**: 5-10 minutes (with layer caching)

The longest steps are:
1. Downloading ARM toolchains (~500MB each)
2. Installing system packages
3. Python installation and setup

## Optimizing Build Time

### Using BuildKit

Enable Docker BuildKit for faster builds:

```bash
DOCKER_BUILDKIT=1 docker build -t cpp-arm-dev .
```

### Layer Caching

The Dockerfile is structured to maximize layer caching:
- System packages are installed first
- Toolchains are downloaded in separate layers
- Frequently changing items are near the end

## Customization

### Adding Additional Packages

Edit the first `RUN` command in the Dockerfile:

```dockerfile
RUN apt-get update && apt-get install -y \
    # ... existing packages ...
    your-package-here \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### Adding Python Packages

Add after the gcovr installation:

```dockerfile
RUN python3 -m pip install --no-cache-dir \
    gcovr \
    your-python-package \
    another-package
```

### Changing Python Version

Modify the deadsnakes PPA installation:

```dockerfile
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y \
    python3.12 \      # Change version here
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### Using Different ARM Toolchain Versions

Replace the download URLs in the Dockerfile:

```dockerfile
RUN cd /tmp \
    && wget https://developer.arm.com/-/media/Files/downloads/gnu/YOUR_VERSION/binrel/arm-gnu-toolchain-YOUR_VERSION-x86_64-arm-none-eabi.tar.xz \
    # ... rest of the commands
```

## Verifying the Build

### Check Installed Tools

```bash
docker run --rm cpp-arm-dev bash -c "
  echo 'GCC:' && gcc --version | head -n1 && \
  echo 'CMake:' && cmake --version | head -n1 && \
  echo 'Python:' && python --version && \
  echo 'Ruby:' && ruby --version && \
  echo 'Perl:' && perl --version | head -n2 && \
  echo 'ARM ATfE:' && /opt/atfe21.1/bin/clang --version | head -n1 && \
  echo 'ARM GNU:' && /opt/gnuarm14.3/bin/arm-none-eabi-gcc --version | head -n1
"
```

### Check Image Size

```bash
docker images cpp-arm-dev
```

### Inspect Layers

```bash
docker history cpp-arm-dev
```

## Troubleshooting Build Issues

### Download Failures

If ARM toolchain downloads fail:
1. Check your internet connection
2. Verify the URLs are still valid
3. Try building again (downloads may resume)

### SHA256 Verification Failures

If checksum verification fails:
```bash
# Remove the sha256sum check temporarily to diagnose
# Or verify the checksums manually
wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz.sha256
cat ATfE-21.1.1-Linux-x86_64.tar.xz.sha256
```

### Out of Disk Space

The build requires ~10GB free space:
```bash
# Clean up Docker
docker system prune -a

# Check disk usage
docker system df
```

### Python apt_pkg Errors

If you encounter `ModuleNotFoundError: No module named 'apt_pkg'`:
- Ensure Ruby/Perl are installed before Python 3.13
- The Dockerfile is already ordered correctly to avoid this

## Image Maintenance

### Cleaning Up Old Images

```bash
# Remove old versions
docker rmi cpp-arm-dev:old-tag

# Remove dangling images
docker image prune
```

### Updating Base Image

To get security updates:
```bash
# Pull latest Ubuntu 24.04
docker pull ubuntu:24.04

# Rebuild
docker build --no-cache -t cpp-arm-dev .
```