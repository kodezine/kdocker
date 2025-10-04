# Troubleshooting

## Build Issues

### Docker Build Fails

#### Problem: "Cannot connect to Docker daemon"
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
- Ensure Docker Desktop is running
- Check Docker service status: `systemctl status docker` (Linux)
- Restart Docker: `sudo systemctl restart docker` (Linux)

#### Problem: "No space left on device"

**Solution:**
```bash
# Clean up Docker
docker system prune -a -f

# Check disk usage
docker system df

# Remove unused volumes
docker volume prune
```

#### Problem: Download failures during build

**Solution:**
```bash
# Retry the build (Docker will cache successful layers)
docker build -t cpp-arm-dev .

# Use a proxy if behind firewall
docker build --build-arg http_proxy=http://proxy:port -t cpp-arm-dev .

# Increase timeout
docker build --network=host -t cpp-arm-dev .
```

### SHA256 Verification Fails

#### Problem: Checksum mismatch

**Solution:**
1. Check if the download URLs have been updated
2. Verify checksums manually:
```bash
cd /tmp
wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz
wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz.sha256
sha256sum -c ATfE-21.1.1-Linux-x86_64.tar.xz.sha256
```
3. Update Dockerfile with correct URLs/checksums

## Runtime Issues

### Container Won't Start

#### Problem: "docker: Error response from daemon"

**Solution:**
```bash
# Check Docker logs
docker logs <container-id>

# Run with verbose logging
docker run --log-level debug -it cpp-arm-dev

# Check system resources
docker info
```

### ARM Toolchain Not Working

#### Problem: "bash: /opt/atfe21.1/bin/clang: No such file or directory"

**Solution:**
```bash
# Check if toolchain was extracted
docker run --rm cpp-arm-dev ls -la /opt/

# Check symlinks
docker run --rm cpp-arm-dev ls -la /opt/atfe21.1

# Manually verify
docker run --rm cpp-arm-dev /opt/ATfE-21.1.1-Linux-x86_64/bin/clang --version
```

#### Problem: "error while loading shared libraries: libncurses.so.5"

**Solution:**
The Dockerfile includes `libncurses6` and `libtinfo6`. If issues persist:

```bash
# Check installed libraries
docker run --rm cpp-arm-dev ldconfig -p | grep ncurses

# Create compatibility symlinks if needed
docker run --rm cpp-arm-dev bash -c "
  ln -s /lib/x86_64-linux-gnu/libncursesw.so.6 /lib/x86_64-linux-gnu/libncurses.so.5
  ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
"
```

### Python Issues

#### Problem: "ModuleNotFoundError: No module named 'apt_pkg'"

**Solution:**
This should be resolved in the current Dockerfile (Ruby/Perl installed before Python 3.13). If it still occurs:

```bash
# Rebuild with correct order
docker build --no-cache -t cpp-arm-dev .
```

#### Problem: pip packages not found

**Solution:**
```bash
# Check Python version
docker run --rm cpp-arm-dev python --version

# Check pip installation
docker run --rm cpp-arm-dev python -m pip --version

# Reinstall package
docker run --rm cpp-arm-dev python -m pip install gcovr
```

## DevContainer Issues

### VS Code Can't Connect

#### Problem: "Failed to connect to the remote extension host server"

**Solution:**
1. Restart Docker Desktop
2. Rebuild container: `F1` → "Dev Containers: Rebuild Container"
3. Check Docker is accessible: `docker ps`
4. Try without cache: "Dev Containers: Rebuild Container Without Cache"

### Extensions Not Installing

#### Problem: Extensions fail to install in container

**Solution:**
1. Check internet connection in container:
```bash
docker run --rm cpp-arm-dev ping -c 3 google.com
```

2. Install manually:
   - Open Extensions panel (`Ctrl+Shift+X`)
   - Search and install individually

3. Check VS Code logs:
   - `F1` → "Developer: Show Logs" → "Extension Host"

### SSH Keys Not Accessible

#### Problem: Git operations fail with SSH

**Solution:**
```bash
# Verify SSH mount
docker run --rm -v ~/.ssh:/root/.ssh:ro cpp-arm-dev ls -la /root/.ssh/

# Check SSH key permissions (on host)
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Test SSH connection
docker run --rm -v ~/.ssh:/root/.ssh:ro cpp-arm-dev ssh -T git@github.com
```

### File Permission Issues

#### Problem: Files created in container have wrong permissions

**Solution:**
1. Run as non-root user (see [DevContainer Setup](.devcontainer.md))
2. Or fix permissions on host:
```bash
sudo chown -R $USER:$USER .
```

## Compilation Issues

### CMake Configuration Fails

#### Problem: "Could not find CMAKE_MAKE_PROGRAM"

**Solution:**
```bash
# Specify generator explicitly
cmake -G Ninja ..

# Or use Make
cmake -G "Unix Makefiles" ..
```

#### Problem: Toolchain file not working

**Solution:**
```bash
# Use absolute path
cmake -DCMAKE_TOOLCHAIN_FILE=/workspace/cmake/toolchain.cmake ..

# Verify toolchain file
cat cmake/toolchain.cmake

# Check compiler exists
/opt/atfe21.1/bin/clang --version
```

### Compilation Errors

#### Problem: "undefined reference to `__stack_chk_guard`"

**Solution:**
Disable stack protection for embedded targets:

```bash
arm-none-eabi-gcc -fno-stack-protector ...
```

Or in CMakeLists.txt:
```cmake
add_compile_options(-fno-stack-protector)
```

#### Problem: "cannot find -lstdc++"

**Solution:**
```bash
# Use g++ instead of gcc for C++
/opt/atfe21.3/bin/arm-none-eabi-g++ ...

# Or explicitly link
arm-none-eabi-gcc -lstdc++ ...
```

## Performance Issues

### Slow Build Times

**Solution:**
1. Use ccache:
```bash
export CC="ccache gcc"
export CXX="ccache g++"
```

2. Use Ninja instead of Make:
```bash
cmake -G Ninja ..
```

3. Increase Docker resources:
   - Docker Desktop → Settings → Resources
   - Increase CPU and Memory

### Slow File I/O

**Solution:**
On macOS, use VirtioFS (Docker Desktop 4.6+):
- Docker Desktop → Settings → General → "Use the new Virtualization framework"

Or use named volumes instead of bind mounts:
```bash
docker volume create workspace
docker run -v workspace:/workspace cpp-arm-dev
```

## Debugging Issues

### GDB Won't Start

#### Problem: "gdb: command not found"

**Solution:**
```bash
# Use full path
/opt/atfe21.1/bin/arm-none-eabi-gdb

# Or add to PATH temporarily
export PATH="/opt/atfe21.1/bin:$PATH"
arm-none-eabi-gdb
```

#### Problem: Can't connect to target

**Solution:**
```bash
# Check OpenOCD is running (if using OpenOCD)
ps aux | grep openocd

# Verify port
netstat -tuln | grep 3333

# Try different connection
(gdb) target remote localhost:3333
# or
(gdb) target extended-remote localhost:3333
```

## Getting Help

### Collecting Diagnostic Information

```bash
# Docker version
docker --version

# Docker info
docker info

# Image details
docker inspect cpp-arm-dev

# Container logs
docker logs <container-name>

# Check all installed tools
docker run --rm cpp-arm-dev bash -c "
  echo '=== System ===' &&
  uname -a &&
  echo '=== GCC ===' &&
  gcc --version &&
  echo '=== CMake ===' &&
  cmake --version &&
  echo '=== Python ===' &&
  python --version &&
  echo '=== ARM Toolchains ===' &&
  ls -la /opt/
"
```

### Reporting Issues

When reporting issues, include:
1. Output of `docker --version`
2. Output of `docker info`
3. Complete error message
4. Steps to reproduce
5. Dockerfile modifications (if any)

### Useful Commands

```bash
# Interactive debugging
docker run -it --rm cpp-arm-dev bash

# Check environment
docker run --rm cpp-arm-dev env

# Test specific command
docker run --rm cpp-arm-dev which gcc

# Mount current directory and test
docker run --rm -v $(pwd):/test -w /test cpp-arm-dev ls -la
```