# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FreshTomato Firmware Build Environment for Netgear R7000P (Docker)
# Quantum-detailed, production-grade Dockerfile
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FROM ubuntu:22.04

# Install build dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git build-essential gcc g++ make \
    libncurses5-dev zlib1g-dev gawk flex gettext unzip \
    python3 python3-distutils subversion libssl-dev libtool \
    wget curl ca-certificates && \
    apt-get clean

# Create a non-root user for building
RUN useradd -ms /bin/bash builder
USER builder
WORKDIR /home/builder

# Set up environment variables for build
ENV DEVICE=netgear_r7000p
ENV FIRMWARE=freshtomato
ENV REPO=https://github.com/Jackysi/AdvancedTomato.git
ENV WORKDIR=/home/builder/firmware_build

# Entrypoint: drop into bash for interactive work
ENTRYPOINT ["/bin/bash"] 