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
    gnupg \
    software-properties-common \
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

# Download ARM toolchains
RUN cd /tmp \
    && wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz \
    && wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-21.1.1-Linux-x86_64.tar.xz.sha256 \
    && sha256sum -c ATfE-21.1.1-Linux-x86_64.tar.xz.sha256 \
    && tar -xf ATfE-21.1.1-Linux-x86_64.tar.xz -C /opt \
    && rm ATfE-21.1.1-Linux-x86_64.tar.xz ATfE-21.1.1-Linux-x86_64.tar.xz.sha256

RUN cd /tmp \
    && wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-newlib-overlay-21.1.1.tar.xz \
    && wget https://github.com/arm/arm-toolchain/releases/download/release-21.1.1-ATfE/ATfE-newlib-overlay-21.1.1.tar.xz.sha256 \
    && sha256sum -c ATfE-newlib-overlay-21.1.1.tar.xz.sha256 \
    && tar -xf ATfE-newlib-overlay-21.1.1.tar.xz -C /opt/ATfE-21.1.1-Linux-x86_64 \
    && rm ATfE-newlib-overlay-21.1.1.tar.xz ATfE-newlib-overlay-21.1.1.tar.xz.sha256

RUN cd /tmp \
    && wget https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz \
    && wget https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc \
    && sha256sum -c arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc \
    && tar -xf arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz -C /opt \
    && rm arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc

WORKDIR /workspace

# Create symlinks in /opt instead of /workspace to avoid mount issues
RUN ln -s /opt/ATfE-21.1.1-Linux-x86_64 /opt/atfe21.1 \
    && ln -s /opt/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi /opt/gnuarm14.3

ENV DEBIAN_FRONTEND=dialog

CMD ["/bin/bash"]