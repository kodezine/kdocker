# ARM Toolchain Usage

## Overview

This environment includes two ARM toolchains optimized for embedded development:

1. **ARM Toolchain for Embedded (ATfE) 21.1.1**
2. **GNU ARM Toolchain 14.3.rel1**

## ARM Toolchain for Embedded (ATfE)

### Location
- Full path: `/opt/ATfE-21.1.1-Linux-x86_64`
- Symlink: `/opt/atfe21.1`

### Components
- GCC 14.2.0 based
- Newlib C library (with overlay)
- GDB for ARM
- Binutils

### Usage

```bash
# Compiler
/opt/atfe21.1/bin/arm-none-eabi-gcc

# C++ Compiler
/opt/atfe21.1/bin/arm-none-eabi-g++

# Assembler
/opt/atfe21.1/bin/arm-none-eabi-as

# Linker
/opt/atfe21.1/bin/arm-none-eabi-ld

# Debugger
/opt/atfe21.1/bin/arm-none-eabi-gdb

# Other tools
/opt/atfe21.1/bin/arm-none-eabi-objcopy
/opt/atfe21.1/bin/arm-none-eabi-objdump
/opt/atfe21.1/bin/arm-none-eabi-size
```

### Example Compilation

```bash
# Simple compilation
/opt/atfe21.1/bin/arm-none-eabi-gcc \
    -mcpu=cortex-m4 \
    -mthumb \
    -O2 \
    -o firmware.elf \
    main.c

# With C++ and standard library
/opt/atfe21.1/bin/arm-none-eabi-g++ \
    -mcpu=cortex-m4 \
    -mthumb \
    -mfloat-abi=hard \
    -mfpu=fpv4-sp-d16 \
    -std=c++17 \
    -O2 \
    -o firmware.elf \
    main.cpp
```

## GNU ARM Toolchain 14.3.rel1

### Location
- Full path: `/opt/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi`
- Symlink: `/opt/gnuarm14.3`

### Components
- GCC 14.3.0
- Newlib C library
- GDB for ARM
- Binutils

### Usage

```bash
# Compiler
/opt/gnuarm14.3/bin/arm-none-eabi-gcc

# C++ Compiler
/opt/gnuarm14.3/bin/arm-none-eabi-g++

# Debugger
/opt/gnuarm14.3/bin/arm-none-eabi-gdb

# Other tools
/opt/gnuarm14.3/bin/arm-none-eabi-objcopy
/opt/gnuarm14.3/bin/arm-none-eabi-objdump
/opt/gnuarm14.3/bin/arm-none-eabi-size
```

### Example Compilation

```bash
# Simple compilation
/opt/gnuarm14.3/bin/arm-none-eabi-gcc \
    -mcpu=cortex-m4 \
    -mthumb \
    -O2 \
    -o firmware.elf \
    main.c

# With linker script
/opt/gnuarm14.3/bin/arm-none-eabi-gcc \
    -mcpu=cortex-m4 \
    -mthumb \
    -T linker_script.ld \
    -o firmware.elf \
    startup.s main.c
```

## Common Targets

### Cortex-M0/M0+
```bash
-mcpu=cortex-m0 -mthumb
```

### Cortex-M3
```bash
-mcpu=cortex-m3 -mthumb
```

### Cortex-M4 (no FPU)
```bash
-mcpu=cortex-m4 -mthumb
```

### Cortex-M4 (with FPU)
```bash
-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
```

### Cortex-M7 (with DP FPU)
```bash
-mcpu=cortex-m7 -mthumb -mfloat-abi=hard -mfpu=fpv5-d16
```

### Cortex-A Series
```bash
-mcpu=cortex-a9 -marm
```

## CMake Integration

### Using ATfE Toolchain

Create `cmake/atfe-toolchain.cmake`:

```cmake
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

set(TOOLCHAIN_PREFIX /opt/atfe21.1/bin/arm-none-eabi-)

set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++)
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_OBJCOPY ${TOOLCHAIN_PREFIX}objcopy)
set(CMAKE_OBJDUMP ${TOOLCHAIN_PREFIX}objdump)
set(CMAKE_SIZE ${TOOLCHAIN_PREFIX}size)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_FLAGS_INIT "-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16")
set(CMAKE_CXX_FLAGS_INIT "-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16")
```

Use it:

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=cmake/atfe-toolchain.cmake -B build
cmake --build build
```

### Using GNU ARM Toolchain

Create `cmake/gnuarm-toolchain.cmake`:

```cmake
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

set(TOOLCHAIN_PREFIX /opt/gnuarm14.3/bin/arm-none-eabi-)

set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++)
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_OBJCOPY ${TOOLCHAIN_PREFIX}objcopy)
set(CMAKE_OBJDUMP ${TOOLCHAIN_PREFIX}objdump)
set(CMAKE_SIZE ${TOOLCHAIN_PREFIX}size)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_FLAGS_INIT "-mcpu=cortex-m4 -mthumb")
set(CMAKE_CXX_FLAGS_INIT "-mcpu=cortex-m4 -mthumb")
```

## Creating Binary Files

### Generate HEX file
```bash
/opt/atfe21.1/bin/arm-none-eabi-objcopy -O ihex firmware.elf firmware.hex
```

### Generate BIN file
```bash
/opt/atfe21.1/bin/arm-none-eabi-objcopy -O binary firmware.elf firmware.bin
```

### Check size
```bash
/opt/atfe21.1/bin/arm-none-eabi-size firmware.elf
```

## Debugging

### Using GDB

```bash
# Start GDB
/opt/atfe21.1/bin/arm-none-eabi-gdb firmware.elf

# Connect to OpenOCD (example)
(gdb) target remote localhost:3333
(gdb) monitor reset halt
(gdb) load
(gdb) continue
```

### GDB with Python Support

Both toolchains include GDB with Python support for advanced debugging:

```bash
/opt/atfe21.1/bin/arm-none-eabi-gdb --configuration
```

## Differences Between Toolchains

| Feature | ATfE 21.1.1 | GNU ARM 14.3.rel1 |
|---------|-------------|-------------------|
| GCC Version | 14.2.0 | 14.3.0 |
| Release | Arm official | Arm official |
| Newlib | With overlay | Standard |
| Best for | Latest features | Stable production |

## Common Issues

### Library Not Found

If you get library errors:

```bash
# Check available multilib configurations
/opt/atfe21.1/bin/arm-none-eabi-gcc -print-multi-lib

# Specify library path explicitly
-L/opt/atfe21.1/arm-none-eabi/lib/thumb/v7e-m/nofp
```

### Undefined Reference to `_exit`

Add minimal system stubs:

```c
void _exit(int status) {
    while(1);
}

void _kill(int pid, int sig) {
    while(1);
}

int _getpid(void) {
    return 1;
}
```

### Stack/Heap Size

Configure in linker script or compiler flags:

```bash
-Wl,--defsym=__stack_size__=0x400
-Wl,--defsym=__heap_size__=0x200
```

## Additional Resources

- [ARM GCC Documentation](https://gcc.gnu.org/onlinedocs/)
- [Newlib Documentation](https://sourceware.org/newlib/)
- [ARM CMSIS](https://github.com/ARM-software/CMSIS_5)