# Use Ubuntu 22.04 LTS as base
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
# - python3, pip, git: Core tools
# - build-essential: GCC/G++ and Make
# - srecord: Required by project specific tools
# - verilator: Open-source Verilog simulator
# - wget, curl, unzip: Utilities for downloading Bazel/dependencies
# - zlib1g-dev: Compression library needed by Bazel
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    build-essential \
    srecord \
    verilator \
    wget \
    curl \
    unzip \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk
# Bazelisk is a wrapper for Bazel that automatically downloads the version
# specified in .bazelversion (which is 7.4.1 for this project).
RUN wget https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -O /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Set up workspace directory
WORKDIR /workspace

# Create a non-root user to satisfy rules_python constraints
# We create a user 'coralnpu' with explicit UID/GID (1000 is common for default users)
RUN groupadd -g 1000 coralnpu && \
    useradd -m -u 1000 -g coralnpu -s /bin/bash coralnpu

# Switch to the non-root user
USER coralnpu

# By default, start a shell
CMD ["/bin/bash"]
