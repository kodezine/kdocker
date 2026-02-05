#!/bin/bash
KDEV_HOME=${KDEV_HOME:-/home/kdev}
ARM_GCC_VERSION=${ARM_GCC_VERSION:-14.3.rel1}
TOOLCHAIN_DIR="$KDEV_HOME/.toolchains/stm32tools"
# The extracted directory name matches what stm32-tools.sh expects
ARM_GCC_INSTALL_DIR=$TOOLCHAIN_DIR/arm-gnu-toolchain-$ARM_GCC_VERSION-x86_64-arm-none-eabi
DOWNLOAD_DIR=${DOWNLOAD_DIR:-/tmp}
ALLOW_INSECURE_DOWNLOAD=${ALLOW_INSECURE_DOWNLOAD:-false}
# Fixed architecture for consistency
ARCH_SUFFIX="x86_64"

function downloadAndExtract {
    FILE_TO_DOWNLOAD=$1
    BASE_URL="https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_GCC_VERSION}/binrel/"
    WGET_FLAGS="-q --show-progress -c -t 10 -T 30"
    if [ "$ALLOW_INSECURE_DOWNLOAD" == "true" ]; then
        WGET_FLAGS="$WGET_FLAGS --no-check-certificate"
    fi

    mkdir -p $DOWNLOAD_DIR
    echo "Downloading $FILE_TO_DOWNLOAD..."
    wget "$BASE_URL$FILE_TO_DOWNLOAD" -O "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" $WGET_FLAGS

    if [ $? -ne 0 ]; then
        echo "Failed to download $FILE_TO_DOWNLOAD" >&2
        exit 1
    fi

    mkdir -p "$TOOLCHAIN_DIR"
    echo "Extracting $FILE_TO_DOWNLOAD to $TOOLCHAIN_DIR..."
    tar xf "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" -C "$TOOLCHAIN_DIR"

    if [ $? -ne 0 ]; then
        echo "Failed to extract $FILE_TO_DOWNLOAD" >&2
        exit 1
    fi
}

function verifyInstallation {
    INSTALL_DIR=$1
    if [ -x "$INSTALL_DIR/bin/arm-none-eabi-gcc" ]; then
        echo "Installation verified: arm-none-eabi-gcc found at $INSTALL_DIR/bin/"
        "$INSTALL_DIR/bin/arm-none-eabi-gcc" --version | head -1
        return 0
    else
        echo "Installation verification failed: arm-none-eabi-gcc not found" >&2
        return 1
    fi
}

function linkAsDefault {
    rm -f "$KDEV_HOME/gnuarm14.3"
    ln -s "$ARM_GCC_INSTALL_DIR" "$KDEV_HOME/gnuarm14.3"
    echo "Created symlink: $KDEV_HOME/gnuarm14.3 -> $ARM_GCC_INSTALL_DIR"
}

function install {
    PACKAGE_FILE="arm-gnu-toolchain-${ARM_GCC_VERSION}-${ARCH_SUFFIX}-arm-none-eabi.tar.xz"

    if [ ! -d "$ARM_GCC_INSTALL_DIR" ]; then
        echo "Requested version $ARM_GCC_VERSION is not installed"
        downloadAndExtract "$PACKAGE_FILE"

        if verifyInstallation "$ARM_GCC_INSTALL_DIR"; then
            echo "arm-none-eabi-gcc $ARM_GCC_VERSION installed successfully"
        else
            echo "Installation failed" >&2
            exit 1
        fi
    else
        echo "arm-none-eabi-gcc $ARM_GCC_VERSION is already installed at $ARM_GCC_INSTALL_DIR"
    fi

    linkAsDefault
}

# Main execution
install

if [ ! -z "$1" ]; then
    echo "Executing: $@"
    "$ARM_GCC_INSTALL_DIR/bin/arm-none-eabi-gcc" "$@"
fi
