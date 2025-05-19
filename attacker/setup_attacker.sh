#!/bin/bash

# Task 2: Setup for Host1 (Attacker)
set -e

COMMON_SETUP_SCRIPT_PATH="../common/setup_host.sh"

# --- Configuration ---
TARGET_IP=""
NETMASK=""
GATEWAY=""
INTERFACE_NAME=""

# --- Helper Functions ---
log_info() {
    echo "[INFO-ATTACKER] $1"
}

log_error() {
    echo "[ERROR-ATTACKER] $1" >&2
}

# --- Argument Parsing for Attacker ---
if [ "$#" -ne 4 ]; then
    log_error "Usage: $0 <target_ip> <netmask> <gateway> <interface_name>"
    log_error "Example: $0 192.168.1.10 255.255.255.0 192.168.1.1 eth0"
    exit 1
fi

TARGET_IP="$1"
NETMASK="$2"
GATEWAY="$3"
INTERFACE_NAME="$4"

log_info "Starting attacker host setup..."

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

# --- 2. Install attack tools/libraries ---
log_info "Installing attacker-specific tools..."
log_info "Installing hping3 and build-essential via apt..."
if apt install -y hping3 build-essential; then
    log_info "hping3 and build-essential installed successfully."
else
    log_error "Failed to install hping3 or build-essential via apt."
fi

log_info "Installing Scapy using pip3..."
if pip3 install scapy; then
    log_info "Scapy installed successfully via pip3."
else
    log_error "Failed to install Scapy via pip3. Ensure pip3 is working (python3-pip should be installed by common script)."
fi

# --- 3. Configure firewall (UFW) ---
log_info "Configuring UFW for attacker (default deny incoming, allow outgoing)..."

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Explicitly allow outgoing traffic on the specified interface (optional, as default is allow)
# ufw allow out on "$INTERFACE_NAME"

# Ensure UFW is enabled (common script should have enabled it and allowed SSH)
if ! ufw status | grep -qw active; then
    log_info "UFW is not active, enabling..."
    ufw --force enable
else
    log_info "UFW is already active."
fi

# Reload UFW to apply changes if any were made to rules/defaults
ufw reload
log_info "UFW configured for attacker: default deny incoming, default allow outgoing. SSH should be allowed from common setup."

log_info "Attacker host setup script finished."
