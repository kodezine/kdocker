#!/bin/bash
KDEV_HOME=${KDEV_HOME:-/home/kdev}
ATFE_VERSION=${ATFE_VERSION:-21.1.1}
TOOLCHAIN_DIR="$KDEV_HOME/.toolchains/stm32tools"
# The extracted directory name matches what stm32-tools.sh expects
ATFE_INSTALL_DIR=$TOOLCHAIN_DIR/ATfE-$ATFE_VERSION-Linux-x86_64
DOWNLOAD_DIR=${DOWNLOAD_DIR:-/tmp}
ALLOW_INSECURE_DOWNLOAD=${ALLOW_INSECURE_DOWNLOAD:-false}
# Fixed architecture for consistency
ARCH_SUFFIX="Linux-x86_64"

function downloadAndExtract {
    FILE_TO_DOWNLOAD=$1
    BASE_URL="https://github.com/arm/arm-toolchain/releases/download/release-${ATFE_VERSION}-ATfE/"
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

    # Also download the SHA256 checksum file
    SHA256_FILE="${FILE_TO_DOWNLOAD}.sha256"
    echo "Downloading checksum file..."
    wget "$BASE_URL$SHA256_FILE" -O "$DOWNLOAD_DIR/$SHA256_FILE" $WGET_FLAGS

    if [ $? -ne 0 ]; then
        echo "Failed to download $SHA256_FILE" >&2
        exit 1
    fi

    echo "Verifying download..."
    cd "$DOWNLOAD_DIR"
    sha256sum -c "$SHA256_FILE"

    if [ $? -ne 0 ]; then
        echo "Checksum verification failed" >&2
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

function downloadAndExtractOverlay {
    FILE_TO_DOWNLOAD=$1
    BASE_URL="https://github.com/arm/arm-toolchain/releases/download/release-${ATFE_VERSION}-ATfE/"
    WGET_FLAGS="-q --show-progress -c -t 10 -T 30"
    if [ "$ALLOW_INSECURE_DOWNLOAD" == "true" ]; then
        WGET_FLAGS="$WGET_FLAGS --no-check-certificate"
    fi

    mkdir -p $DOWNLOAD_DIR
    echo "Downloading overlay $FILE_TO_DOWNLOAD..."
    wget "$BASE_URL$FILE_TO_DOWNLOAD" -O "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" $WGET_FLAGS

    if [ $? -ne 0 ]; then
        echo "Failed to download overlay $FILE_TO_DOWNLOAD" >&2
        exit 1
    fi

    # Download overlay checksum
    SHA256_FILE="${FILE_TO_DOWNLOAD}.sha256"
    echo "Downloading overlay checksum file..."
    wget "$BASE_URL$SHA256_FILE" -O "$DOWNLOAD_DIR/$SHA256_FILE" $WGET_FLAGS

    if [ $? -ne 0 ]; then
        echo "Failed to download overlay $SHA256_FILE" >&2
        exit 1
    fi

    echo "Verifying overlay..."
    cd "$DOWNLOAD_DIR"
    sha256sum -c "$SHA256_FILE"

    if [ $? -ne 0 ]; then
        echo "Overlay checksum verification failed" >&2
        exit 1
    fi

    echo "Extracting overlay $FILE_TO_DOWNLOAD to $ATFE_INSTALL_DIR..."
    tar xf "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" -C "$ATFE_INSTALL_DIR"

    if [ $? -ne 0 ]; then
        echo "Failed to extract overlay $FILE_TO_DOWNLOAD" >&2
        exit 1
    fi
}

function verifyInstallation {
    INSTALL_DIR=$1
    if [ -x "$INSTALL_DIR/bin/clang" ]; then
        echo "Installation verified: clang found at $INSTALL_DIR/bin/"
        "$INSTALL_DIR/bin/clang" --version | head -1
        return 0
    else
        echo "Installation verification failed: clang not found" >&2
        return 1
    fi
}

function linkAsDefault {
    rm -f "$KDEV_HOME/atfe21.1"
    ln -s "$ATFE_INSTALL_DIR" "$KDEV_HOME/atfe21.1"
    echo "Created symlink: $KDEV_HOME/atfe21.1 -> $ATFE_INSTALL_DIR"
}

function installNewlibOverlay {
    NEWLIB_OVERLAY_FILE="ATfE-newlib-overlay-${ATFE_VERSION}.tar.xz"

    echo "Installing ATfE newlib overlay..."
    downloadAndExtractOverlay "$NEWLIB_OVERLAY_FILE"

    if [ $? -eq 0 ]; then
        echo "ATfE newlib overlay $ATFE_VERSION installed successfully"
    else
        echo "Warning: Failed to install newlib overlay, but main toolchain is functional" >&2
    fi
}

function install {
    PACKAGE_FILE="ATfE-${ATFE_VERSION}-${ARCH_SUFFIX}.tar.xz"

    if [ ! -d "$ATFE_INSTALL_DIR" ]; then
        echo "Requested version $ATFE_VERSION is not installed"
        downloadAndExtract "$PACKAGE_FILE"

        if verifyInstallation "$ATFE_INSTALL_DIR"; then
            echo "Arm Toolchain for Embedded $ATFE_VERSION installed successfully"

            # Install newlib overlay
            installNewlibOverlay

            # Copy armv7m configuration file if it exists
            if [ -f "$KDEV_HOME/.toolchains/armv7m_hard_fpv4_sp_d16.cfg" ]; then
                cp "$KDEV_HOME/.toolchains/armv7m_hard_fpv4_sp_d16.cfg" "$ATFE_INSTALL_DIR/bin/"
            fi
        else
            echo "Installation failed" >&2
            exit 1
        fi
    else
        echo "Arm Toolchain for Embedded $ATFE_VERSION is already installed at $ATFE_INSTALL_DIR"

        # Check if newlib overlay needs to be installed
        if [ ! -f "$ATFE_INSTALL_DIR/newlib.cfg" ]; then
            echo "Newlib overlay not detected, installing..."
            installNewlibOverlay
        else
            echo "Newlib overlay already installed"
        fi

        # Copy armv7m configuration file if it exists and not already copied
        if [ -f "$KDEV_HOME/.toolchains/armv7m_hard_fpv4_sp_d16.cfg" ] && [ ! -f "$ATFE_INSTALL_DIR/bin/armv7m_hard_fpv4_sp_d16.cfg" ]; then
            cp "$KDEV_HOME/.toolchains/armv7m_hard_fpv4_sp_d16.cfg" "$ATFE_INSTALL_DIR/bin/"
        fi
    fi

    linkAsDefault
}

# Main execution
install

if [ ! -z "$1" ]; then
    echo "Executing: $@"
    "$ATFE_INSTALL_DIR/bin/clang" "$@"
fi
