# C++ ARM Development Docker Environment

A comprehensive Docker-based development environment for C++ and ARM embedded systems development, built on Ubuntu 24.04 LTS.

## Features

### Development Tools
- **GCC 13.2** - Default system compiler
- **Clang** - Modern C++ compiler with clang-format
- **CMake** (latest) - From Kitware's official repository
- **Ninja** - Fast build system
- **ccache** - Compiler cache for faster rebuilds
- **GDB** - GNU Debugger
- **Valgrind** - Memory debugging and profiling

### Languages
- **Python 3.13** - Latest stable from deadsnakes PPA
- **Ruby 3.2** - From Ubuntu repository
- **Perl 5.38** - From Ubuntu repository

### Code Coverage
- **gcovr** (latest) - Generate code coverage reports

### ARM Toolchains
- **ARM Toolchain for Embedded (ATfE) 21.1.1** with newlib overlay
  - Location: `/opt/ATfE-21.1.1-Linux-x86_64`
  - Symlink: `/opt/atfe21.1`
- **GNU ARM Toolchain 14.3.rel1** (arm-none-eabi)
  - Location: `/opt/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi`
  - Symlink: `/opt/gnuarm14.3`

All toolchains are SHA256 verified during build.

## Quick Start

### Building the Docker Image

```bash
# Clone the repository
git clone <repository-url>
cd dev-docker

# Build the image
docker build -t cpp-arm-dev .

# Build with custom tag
docker build -t my-cpp-dev:latest .
```

### Running the Container

```bash
# Basic run
docker run -it --rm cpp-arm-dev

# Mount current directory
docker run -it --rm -v $(pwd):/workspace cpp-arm-dev

# With SSH credentials
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.ssh:/root/.ssh:ro \
  cpp-arm-dev
```

### Using with VS Code DevContainers

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open the project folder in VS Code
3. Press `F1` and select "Dev Containers: Reopen in Container"
4. VS Code will build and start the container automatically

See [DevContainer Setup](.readme/devcontainer.md) for more details.

## Usage Examples

### Compiling C++ Code

```bash
# Using GCC
g++ -std=c++20 -O2 -o myapp main.cpp

# Using Clang
clang++ -std=c++20 -O2 -o myapp main.cpp

# Using CMake
mkdir build && cd build
cmake -G Ninja ..
ninja
```

### Using ARM Toolchains

```bash
# ARM Toolchain for Embedded (ATfE)
/opt/atfe21.1/bin/arm-none-eabi-gcc --version
/opt/atfe21.1/bin/arm-none-eabi-g++ -o firmware.elf main.cpp

# GNU ARM Toolchain
/opt/gnuarm14.3/bin/arm-none-eabi-gcc --version
/opt/gnuarm14.3/bin/arm-none-eabi-g++ -o firmware.elf main.cpp
```

### Code Coverage with gcovr

```bash
# Compile with coverage flags
g++ -fprofile-arcs -ftest-coverage -o myapp main.cpp

# Run the application
./myapp

# Generate coverage report
gcovr --html-details coverage.html
```

### Using ccache

```bash
# Set compiler to use ccache
export CC="ccache gcc"
export CXX="ccache g++"

# Build with CMake
cmake -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      ..
```

## Documentation

- [Building and Configuration](.readme/building.md)
- [DevContainer Setup](.readme/devcontainer.md)
- [ARM Toolchain Usage](.readme/arm-toolchains.md)
- [Troubleshooting](.readme/troubleshooting.md)

## System Requirements

- Docker 20.10 or later
- At least 10GB free disk space (for the image)
- 4GB RAM recommended

## Image Size

The built image is approximately 3-4GB due to the ARM toolchains and development tools.

## Contributing

Contributions are welcome! Please ensure:
- All files use LF line endings (enforced by `.gitattributes`)
- Dockerfile changes are tested locally
- Documentation is updated accordingly

## License

[Add your license here]

## Support

For issues and questions, please open an issue in the repository.