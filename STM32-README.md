# STM32 Development Docker Container

This Docker container provides a complete STM32 development environment with on-demand tool installation.

## Base Tools Included

- **ARM Toolchains**: GNU Arm 14.3 and Arm Compiler for Embedded 21.1
- **Development Tools**: CMake, Python 3.13, GCC 14, build essentials
- **32-bit/64-bit Support**: GCC 14 with multilib for both architectures
- **Shell**: Zsh with Oh My Zsh configuration

## STM32 Tools (On-Demand Installation)

The container includes a convenient script to install STM32-specific tools as needed:

### Available Tools

1. **OpenOCD** - Open On-Chip Debugger for STM32 debugging
2. **STLink Tools** - Open source ST-Link utilities
3. **STM32CubeProgrammer** - Official ST programming tool (requires manual download)
4. **Additional Development Tools** - GDB, minicom, dfu-util, etc.

### Usage

#### Interactive Installation

```bash
stm32-tools
```

#### Command Line Installation

```bash
# Install specific tools
stm32-tools openocd        # Install OpenOCD
stm32-tools stlink         # Install STLink tools
stm32-tools devtools       # Install additional dev tools
stm32-tools all            # Install all available tools

# Check status
stm32-tools status         # Show what's installed

# Update shell PATH
stm32-tools updatepath     # Add tools to .zshrc/.bashrc
```

### STM32CubeProgrammer Installation

STM32CubeProgrammer requires manual download due to license agreements:

1. Download from [ST Website](https://www.st.com/en/development-tools/stm32cubeprog.html)
2. Copy the zip file to `/tmp/` in the container
3. Run: `stm32-tools cubeprog`

## Hardware Support

The container includes udev rules for ST-Link devices:

- ST-Link V1, V2, V2-1, V3
- Proper USB permissions configured
- User added to `dialout` and `plugdev` groups

## Running the Container

### Basic Usage

```bash
docker build -t stm32-dev .
docker run -it --rm stm32-dev
```

### With ST-Link Hardware Support

```bash
docker run -it --rm --privileged -v /dev:/dev stm32-dev
```

### With Volume Mounting

```bash
docker run -it --rm -v $(pwd):/home/kdev/workspaces/project stm32-dev
```

## Directory Structure

- `~/workspaces/` - Working directory for projects
- `~/.toolchains/` - All toolchains and development tools
- `~/gnuarm14.3` - GNU Arm toolchain symlink
- `~/atfe21.1` - Arm Compiler for Embedded symlink
- `~/.local/bin/` - User binaries and scripts

## Toolchain Paths

- **GNU Arm 14.3**: `~/gnuarm14.3/bin/`
- **ATFE 21.1**: `~/atfe21.1/bin/`
- **STM32 Tools**: `~/.toolchains/stm32tools/*/bin/`

All tools are automatically added to PATH when installed.

## Examples

### Quick Setup for STM32 Development

```bash
# Start container
docker run -it --privileged -v /dev:/dev -v $(pwd):/home/kdev/workspaces/project stm32-dev

# Inside container - install tools
stm32-tools all

# Verify ST-Link connection
st-info --probe
# or
STM32_Programmer_CLI -l
```

### OpenOCD Debugging Session

```bash
# Install OpenOCD
stm32-tools openocd

# Start OpenOCD server
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg

# In another terminal, connect with GDB
arm-none-eabi-gdb firmware.elf
(gdb) target remote localhost:3333
```

## Customization

The installation script can be modified to add additional tools or change installation paths. Edit `/home/kdev/.local/bin/stm32-tools` inside the container or modify `stm32-tools.sh` before building the image.
