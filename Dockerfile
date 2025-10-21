FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture support
RUN dpkg --add-architecture i386

# Install base development tools and languages
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    gcc \
    gcc-multilib \
    g++-multilib \
    make \
    gdb \
    valgrind \
    git \
    vim \
    sudo \
    openssh-client \
    wget \
    curl \
    gnupg \
    software-properties-common \
    zsh \
    ninja-build \
    ruby \
    ruby-dev \
    perl \
    libperl-dev \
    ccache \
    clang \
    clang-format \
    libncurses6 \
    libncursesw6 \
    libtinfo6 \
    file \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install 32-bit libraries (only those available in Ubuntu 24.04)
RUN apt-get update && apt-get install -y \
    libc6-i386 \
    lib32stdc++6 \
    lib32gcc-s1 \
    lib32z1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest CMake
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
    && echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ noble main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null \
    && apt-get update \
    && apt-get install -y cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.13
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.13 1

RUN python3 -m pip install --no-cache-dir gcovr

# Remove ubuntu user
RUN userdel -r ubuntu

# Create non-root user kdev with sudo access
ARG KDEV_USERNAME=kdev
ARG KDEV_USER_UID=1000
ARG KDEV_USER_GID=$KDEV_USER_UID

# Check if user/group exists and create if not
RUN if ! getent group $KDEV_USER_GID; then groupadd --gid $KDEV_USER_GID $KDEV_USERNAME; fi \
    && if ! getent passwd $KDEV_USER_UID; then useradd --uid $KDEV_USER_UID --gid $KDEV_USER_GID -m $KDEV_USERNAME -s /bin/zsh; fi \
    && echo $KDEV_USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$KDEV_USERNAME \
    && chmod 0440 /etc/sudoers.d/$KDEV_USERNAME

ENV KDEV_HOME=/home/kdev
# ENV USERNAME=$KDEV_USERNAME
# Install Oh My Zsh as kdev user
USER kdev
WORKDIR $KDEV_HOME
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Final ownership fix as root (after Oh My Zsh installation)
USER root
WORKDIR $KDEV_HOME
RUN mkdir -p $KDEV_HOME/.toolchains

# Copy armv7m configuration file for ATFE (when installed)
COPY armv7m_hard_fpv4_sp_d16.cfg ${KDEV_HOME}/.toolchains/

# Install base dependencies for STM32 development
RUN apt-get update && apt-get install -y \
    udev \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libusb-dev \
    libudev-dev \
    unzip \
    pkg-config \
    default-jre \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories for STM32 tools
RUN mkdir -p ${KDEV_HOME}/.local/bin ${KDEV_HOME}/.toolchains/stm32tools

# Copy STM32 tools installation script
COPY stm32-tools.sh ${KDEV_HOME}/.local/bin/stm32-tools
RUN chmod +x ${KDEV_HOME}/.local/bin/stm32-tools

# Install ST-Link udev rules for proper device access
RUN echo '# ST-Link V1' > /etc/udev/rules.d/49-stlinkv1.rules \
    && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3744", MODE="0666"' >> /etc/udev/rules.d/49-stlinkv1.rules \
    && echo '' >> /etc/udev/rules.d/49-stlinkv1.rules \
    && echo '# ST-Link V2' > /etc/udev/rules.d/49-stlinkv2.rules \
    && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3748", MODE="0666"' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo '' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo '# ST-Link V2-1' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374b", MODE="0666"' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo '' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo '# ST-Link V3' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374d", MODE="0666"' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374e", MODE="0666"' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374f", MODE="0666"' >> /etc/udev/rules.d/49-stlinkv2.rules \
    && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3753", MODE="0666"' >> /etc/udev/rules.d/49-stlinkv2.rules

# Add kdev user to dialout group for serial device access
RUN usermod -a -G dialout,plugdev kdev

RUN mkdir -p ${KDEV_HOME}/workspaces
ENV KDEV_WORKSPACES=${KDEV_HOME}/workspaces

# Add development tools to PATH (when installed)
ENV PATH="${KDEV_HOME}/gnuarm14.3/bin:${KDEV_HOME}/atfe21.1/bin:${KDEV_HOME}/.toolchains/stm32tools/stlink/bin:${KDEV_HOME}/.toolchains/stm32tools/stm32cubeprog/bin:${KDEV_HOME}/.local/bin:${PATH}"

# Create welcome message
RUN echo '#!/bin/bash' > ${KDEV_HOME}/.welcome \
    && echo 'echo "============================================"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "Welcome to Embedded Development Container"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "============================================"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo ""' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "📦 All tools install on-demand for flexibility!"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo ""' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "🔧 ARM Toolchains (install as needed):"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  - GNU Arm Toolchain 14.3 (~500MB)"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  - Arm Compiler for Embedded 21.1 (~3GB)"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo ""' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "🎯 STM32 Tools (install as needed):"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  - OpenOCD (debugging)"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  - STLink tools (programming)"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  - STM32CubeProgrammer (ST official)"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  - Additional development tools"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo ""' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "🚀 Quick Start:"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  stm32-tools                    - Interactive installer"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  stm32-tools gnuarm             - Install GNU Arm only"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  stm32-tools armtools           - Install both ARM toolchains"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  stm32-tools stm32tools         - Install STM32 debug tools"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  stm32-tools all                - Install everything"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "  stm32-tools status             - Show installation status"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo ""' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "💡 Tip: Start with \"stm32-tools gnuarm\" for basic STM32 development"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo "============================================"' >> ${KDEV_HOME}/.welcome \
    && echo 'echo ""' >> ${KDEV_HOME}/.welcome \
    && chmod +x ${KDEV_HOME}/.welcome

# Add welcome message to zshrc
RUN echo '' >> ${KDEV_HOME}/.zshrc \
    && echo '# Show welcome message on login' >> ${KDEV_HOME}/.zshrc \
    && echo '~/.welcome' >> ${KDEV_HOME}/.zshrc

RUN chown -R kdev:kdev $KDEV_HOME
WORKDIR $KDEV_HOME/workspaces

CMD ["/bin/zsh"]
