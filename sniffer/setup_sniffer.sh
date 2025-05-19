#!/bin/bash

# Task 3: Setup for Host2 (Sniffer/IDS)
set -e

COMMON_SETUP_SCRIPT_PATH="../common/setup_host.sh"

# --- Configuration ---
TARGET_IP=""
NETMASK=""
GATEWAY=""
INTERFACE_NAME=""

# --- Helper Functions ---
log_info() {
    echo "[INFO-SNIFFER] $1"
}

log_error() {
    echo "[ERROR-SNIFFER] $1" >&2
}

# --- Argument Parsing for Sniffer ---
if [ "$#" -ne 4 ]; then
    log_error "Usage: $0 <target_ip> <netmask> <gateway> <interface_name>"
    log_error "Example: $0 192.168.1.20 255.255.255.0 192.168.1.1 eth0"
    exit 1
fi

TARGET_IP="$1"
NETMASK="$2"
GATEWAY="$3"
INTERFACE_NAME="$4"

log_info "Starting sniffer host setup..."

# --- 1. Run common setup ---
if [ -f "$COMMON_SETUP_SCRIPT_PATH" ]; then
    log_info "Running common host setup script..."
    if bash "$COMMON_SETUP_SCRIPT_PATH" "$TARGET_IP" "$NETMASK" "$GATEWAY" "$INTERFACE_NAME"; then
        log_info "Common host setup completed successfully."
    else
        log_error "Common host setup failed."
        exit 1
    fi
else
    log_error "Common setup script not found at $COMMON_SETUP_SCRIPT_PATH"
    exit 1
fi

# --- 2. Install Sniffer-specific tools ---
# Docker, Docker Compose, Wireshark, pyserial
# For Wireshark, non-root capture can be enabled by: 
# dpkg-reconfigure wireshark-common -> select Yes
# usermod -aG wireshark $USER
# This script assumes it's run as root, so direct wireshark execution would be as root.
SNIFFER_PACKAGES="docker.io docker-compose wireshark python3-pyserial"

log_info "Installing sniffer-specific tools: $SNIFFER_PACKAGES..."
DEBIAN_FRONTEND=noninteractive apt install -y $SNIFFER_PACKAGES
if [ $? -eq 0 ]; then
    log_info "Sniffer tools installed successfully."
    # Add current user (the one who ran sudo) to the docker group
    # $USER might be root if script is run with `sudo bash script.sh`
    # SUDO_USER is the user who invoked sudo
    ACTUAL_USER="${SUDO_USER:-$(whoami)}"
    if ! getent group docker | grep -qw "$ACTUAL_USER"; then
        log_info "Adding user '$ACTUAL_USER' to docker group..."
        usermod -aG docker "$ACTUAL_USER"
        log_info "User '$ACTUAL_USER' added to docker group. A logout/login or 'newgrp docker' is required for this change to take effect for the user's current session."
    else
        log_info "User '$ACTUAL_USER' is already in the docker group."
    fi
else
    log_error "Failed to install some sniffer tools. Please check logs."
    # exit 1 # Decide if this is fatal
fi

# Enable and start Docker service if not already running
if ! systemctl is-active --quiet docker; then
    log_info "Docker service is not active. Starting and enabling Docker..."
    systemctl start docker
    systemctl enable docker
    log_info "Docker service started and enabled."
else
    log_info "Docker service is already active."
fi


# --- 3. Configure firewall (UFW) ---
# common_setup_host.sh already enables UFW and allows SSH.
log_info "Configuring UFW for sniffer..."

# Allow a specific port for Snort management if accessed directly
# This is an example; actual port might vary based on Snort configuration within Docker.
SNORT_MANAGEMENT_PORT="8080" # Example port for a web UI or management interface
SNORT_MANAGEMENT_PROTOCOL="tcp"

if ! ufw status verbose | grep -qw "${SNORT_MANAGEMENT_PORT}/${SNORT_MANAGEMENT_PROTOCOL}"; then
    log_info "Allowing Snort management port ${SNORT_MANAGEMENT_PORT}/${SNORT_MANAGEMENT_PROTOCOL} through UFW..."
    ufw allow ${SNORT_MANAGEMENT_PORT}/${SNORT_MANAGEMENT_PROTOCOL} comment 'Snort Management'
    ufw reload
else
    log_info "UFW rule for Snort management port ${SNORT_MANAGEMENT_PORT}/${SNORT_MANAGEMENT_PROTOCOL} already exists."
fi

log_info "UFW basic configuration (allow SSH) handled by common_setup. Sniffer-specific UFW rules updated."

log_info "Sniffer host setup script finished."
