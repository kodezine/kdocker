#!/bin/bash
KDEV_HOME=${KDEV_HOME:-/home/kdev}
ATFE_VERSION=${ATFE_VERSION:-21.1.1}
ATFE_INSTALL_DIR=$KDEV_HOME/ARM/ATfE-$ATFE_VERSION
DOWNLOAD_DIR=${DOWNLOAD_DIR:-/tmp}
ALLOW_INSECURE_DOWNLOAD=${ALLOW_INSECURE_DOWNLOAD:-false}
ARCH=$(uname -m)

function getArchSuffix {
    case "$ARCH" in
        x86_64)
            echo "linux-x86_64"
            ;;
        aarch64)
            echo "linux-aarch64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH" >&2
            exit 1
            ;;
    esac
}

function downloadAndExtract {
    FILE_TO_DOWNLOAD=$1
    EXTRACT_DIR=$2
    BASE_URL="https://github.com/arm/arm-toolchain/releases/download/release-${ATFE_VERSION}-ATfE/"
    WGET_FLAGS="-q --show-progress"
    if [ "$ALLOW_INSECURE_DOWNLOAD" == "true" ]; then
        WGET_FLAGS="$WGET_FLAGS --no-check-certificate"
    fi
    
    mkdir -p $DOWNLOAD_DIR
    echo "Downloading $FILE_TO_DOWNLOAD..."
    wget -nc "$BASE_URL$FILE_TO_DOWNLOAD" -O "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" $WGET_FLAGS
    
    if [ $? -ne 0 ]; then
        echo "Failed to download $FILE_TO_DOWNLOAD" >&2
        exit 1
    fi

    mkdir -p "$EXTRACT_DIR"
    echo "Extracting $FILE_TO_DOWNLOAD to $EXTRACT_DIR..."
    tar xf "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" -C "$EXTRACT_DIR" --strip-components=1
    
    if [ $? -ne 0 ]; then
        echo "Failed to extract $FILE_TO_DOWNLOAD" >&2
        exit 1
    fi
}

function downloadAndExtractOverlay {
    FILE_TO_DOWNLOAD=$1
    EXTRACT_DIR=$2
    BASE_URL="https://github.com/arm/arm-toolchain/releases/download/release-${ATFE_VERSION}-ATfE/"
    WGET_FLAGS="-q --show-progress"
    if [ "$ALLOW_INSECURE_DOWNLOAD" == "true" ]; then
        WGET_FLAGS="$WGET_FLAGS --no-check-certificate"
    fi
    
    mkdir -p $DOWNLOAD_DIR
    echo "Downloading overlay $FILE_TO_DOWNLOAD..."
    wget -nc "$BASE_URL$FILE_TO_DOWNLOAD" -O "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" $WGET_FLAGS
    
    if [ $? -ne 0 ]; then
        echo "Failed to download overlay $FILE_TO_DOWNLOAD" >&2
        exit 1
    fi

    echo "Extracting overlay $FILE_TO_DOWNLOAD to $EXTRACT_DIR..."
    tar xf "$DOWNLOAD_DIR/$FILE_TO_DOWNLOAD" -C "$EXTRACT_DIR"
    
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
    NEWLIB_OVERLAY_FILE="arm-toolchain-for-embedded-newlib-overlay-${ATFE_VERSION}.tar.xz"
    
    echo "Installing ATfE newlib overlay..."
    downloadAndExtractOverlay "$NEWLIB_OVERLAY_FILE" "$ATFE_INSTALL_DIR"
    
    if [ $? -eq 0 ]; then
        echo "ATfE newlib overlay $ATFE_VERSION installed successfully"
    else
        echo "Warning: Failed to install newlib overlay, but main toolchain is functional" >&2
    fi
}

function install {
    ARCH_SUFFIX=$(getArchSuffix)
    PACKAGE_FILE="arm-toolchain-for-embedded-${ATFE_VERSION}-${ARCH_SUFFIX}.tar.xz"
    
    if [ ! -d "$ATFE_INSTALL_DIR" ]; then
        echo "Requested version $ATFE_VERSION is not installed"
        downloadAndExtract "$PACKAGE_FILE" "$ATFE_INSTALL_DIR"
        
        if verifyInstallation "$ATFE_INSTALL_DIR"; then
            echo "Arm Toolchain for Embedded $ATFE_VERSION installed successfully"
            
            # Install newlib overlay
            installNewlibOverlay
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
    fi
    
    linkAsDefault
}

# Main execution
install

if [ ! -z "$1" ]; then
    echo "Executing: $@"
    "$ATFE_INSTALL_DIR/bin/clang" "$@"
fi