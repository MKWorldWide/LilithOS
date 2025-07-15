FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    unzip \
    autoconf \
    automake \
    bison \
    flex \
    libtool \
    texinfo \
    libreadline-dev \
    libncurses5-dev \
    libusb-dev \
    libftdi-dev \
    zlib1g-dev \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    patch && \
    apt-get clean

# Create a user for building
RUN useradd -ms /bin/bash builder
USER builder
WORKDIR /home/builder

# Clone and build the PSP toolchain
RUN git clone https://github.com/pspdev/psptoolchain.git && \
    cd psptoolchain && \
    ./toolchain-sudo.sh