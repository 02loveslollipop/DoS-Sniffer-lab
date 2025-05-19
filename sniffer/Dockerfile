# Snort 3 Dockerfile
# Base image: Ubuntu 22.04 (Jammy Jellyfish)
FROM ubuntu:22.04 AS builder

ARG SNORT_VERSION=3.1.80.0
ARG DAQ_VERSION=3.0.14

ENV DEBIAN_FRONTEND=noninteractive \
    MY_SNORT_LUA_PATH=/usr/local/etc/snort \
    SNORT_LUA_PATH=/usr/local/etc/snort

# 1. Install build dependencies and common tools
RUN apt-get update && apt-get install -y --no-install-recommends \\\
    build-essential \\\
    cmake \\\
    flex \\\
    bison \\\
    git \\\
    wget \\\
    curl \\\
    pkg-config \\\
    libpcap-dev \\\
    libpcre3-dev \\\
    libdumbnet-dev \\\
    libssl-dev \\\
    zlib1g-dev \\\
    luajit \\\
    libluajit-5.1-dev \\\
    libhwloc-dev \\\
    liblzma-dev \\\
    openssl \\\
    ragel \\\
    asciidoctor \\\
    dnet-common \\\
    libtool \\\
    autoconf \\\
    automake \\\
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/snort_src

# 2. Build and install libdaq
RUN if [ -n "$DAQ_VERSION" ]; then \
        wget "https://github.com/snort3/libdaq/archive/refs/tags/v${DAQ_VERSION}.tar.gz" -O libdaq.tar.gz; \
        tar -xzf libdaq.tar.gz && cd libdaq-${DAQ_VERSION}; \
    else \
        git clone https://github.com/snort3/libdaq.git && cd libdaq; \
    fi && \
    ./bootstrap && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf libdaq*

# 3. Build and install Snort 3
RUN if [ -n "$SNORT_VERSION" ]; then \
        wget "https://github.com/snort3/snort3/archive/refs/tags/${SNORT_VERSION}.tar.gz" -O snort3.tar.gz; \
        tar -xzf snort3.tar.gz && cd snort3-${SNORT_VERSION}; \
    else \
        git clone https://github.com/snort3/snort3.git && cd snort3; \
    fi && \
    ./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc --enable-jemalloc --enable-debug && \
    cd build && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf snort3*

# Create necessary directories for Snort
RUN mkdir -p /usr/local/etc/snort/rules \
    && mkdir -p /usr/local/etc/snort/preproc_rules \
    && mkdir -p /usr/local/etc/snort/builtin_rules \
    && mkdir -p /var/log/snort \
    && mkdir -p /usr/local/lib/snort_dynamicrules \
    && mkdir -p /usr/local/lib/snort_dynamicengine \
    && mkdir -p /usr/local/lib/snort_dynamicpreprocessor

# Update shared library cache
RUN ldconfig

# Final stage image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    MY_SNORT_LUA_PATH=/usr/local/etc/snort \
    SNORT_LUA_PATH=/usr/local/etc/snort \
    PATH="/usr/local/bin:/usr/local/sbin:${PATH}"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\\
    libpcap0.8 \\\
    libpcre3 \\\
    libdumbnet1 \\\
    libssl3 \\\
    zlib1g \\\
    libluajit-5.1-2 \\\
    libhwloc15 \\\
    liblzma5 \\\
    dumbnet-tools \\\
    iproute2 \\\
    net-tools \\\
    curl \\\
    wget \\\
    vim-tiny \\\
    tcpdump \\\
    && rm -rf /var/lib/apt/lists/*

# Copy Snort installation from builder stage
COPY --from=builder /usr/local /usr/local/
COPY --from=builder /tmp/snort_src /tmp/snort_src/

# Copy Snort directories (already created in builder, but ensures ownership and layers)
COPY --from=builder /usr/local/etc/snort /usr/local/etc/snort/
COPY --from=builder /var/log/snort /var/log/snort/
COPY --from=builder /usr/local/lib/snort_dynamicrules /usr/local/lib/snort_dynamicrules/
COPY --from=builder /usr/local/lib/snort_dynamicengine /usr/local/lib/snort_dynamicengine/
COPY --from=builder /usr/local/lib/snort_dynamicpreprocessor /usr/local/lib/snort_dynamicpreprocessor/


# Placeholder for Snort configuration files and rules
# These will typically be mounted via docker-compose.
# COPY snort.lua /usr/local/etc/snort/
# COPY snort_defaults.lua /usr/local/etc/snort/
# COPY file_magic.lua /usr/local/etc/snort/
# COPY custom.rules /usr/local/etc/snort/rules/

# Ensure ldconfig is run in the final image as well
RUN ldconfig

# Set working directory
WORKDIR /usr/local/etc/snort

# Expose any ports if Snort were to run a service directly (not typical for IDS mode)
# EXPOSE <port>

# Default command (can be overridden in docker-compose.yml)
# This command just verifies Snort installation and version.
CMD ["snort", "-V"]
