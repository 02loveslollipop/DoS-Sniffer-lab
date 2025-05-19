#!/bin/bash

# Task 4: Setup for Host3 (Victim)
set -e

COMMON_SETUP_SCRIPT_PATH="../common/setup_host.sh"

# --- Configuration ---
TARGET_IP=""
NETMASK=""
GATEWAY=""
INTERFACE_NAME=""

# Default ports for attacks, can be overridden by arguments
DEFAULT_LAND_ATTACK_PORT="139"
DEFAULT_SYN_FLOOD_PORT="80"

# --- Helper Functions ---
log_info() {
    echo "[INFO-VICTIM] $1"
}

log_error() {
    echo "[ERROR-VICTIM] $1" >&2
}

# --- Argument Parsing for Victim ---
if [ "$#" -lt 4 ]; then # At least 4 args needed
    log_error "Usage: $0 <target_ip> <netmask> <gateway> <interface_name> [land_port] [syn_flood_port]"
    log_error "Example: $0 192.168.1.30 255.255.255.0 192.168.1.1 eth0 139 80"
    exit 1
fi

TARGET_IP="$1"
NETMASK="$2"
GATEWAY="$3"
INTERFACE_NAME="$4"
LAND_ATTACK_PORT="${5:-$DEFAULT_LAND_ATTACK_PORT}"
SYN_FLOOD_PORT="${6:-$DEFAULT_SYN_FLOOD_PORT}"

log_info "Starting victim host setup..."
log_info "Land Attack Port: $LAND_ATTACK_PORT, SYN Flood Port: $SYN_FLOOD_PORT"

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

# --- 2. Install basic network utilities for monitoring ---
MONITORING_PACKAGES="tcpdump netcat-openbsd" # net-tools is in common, added netcat
log_info "Installing victim-specific monitoring tools: $MONITORING_PACKAGES..."
if apt update && apt install -y $MONITORING_PACKAGES; then
    log_info "Monitoring tools installed successfully."
else
    log_error "Failed to install some monitoring tools."
fi

# --- 3. Open specific ports for attacks ---
log_info "Opening ports for attacks: Land Attack (TCP $LAND_ATTACK_PORT), TCP SYN Flood (TCP $SYN_FLOOD_PORT)..."

# Ensure UFW is active (common_setup should have done this)
if ! ufw status | grep -qw active; then
    log_info "UFW is not active, enabling..."
    ufw --force enable # Enable UFW if not already (common_setup should handle SSH allow)
else
    log_info "UFW is already active."
fi

# Allow Land Attack Port
if ! ufw status verbose | grep -qw "$LAND_ATTACK_PORT/tcp.*ALLOW IN"; then
    ufw allow "$LAND_ATTACK_PORT/tcp" comment 'Land Attack Target Port'
    log_info "UFW rule added for Land Attack port $LAND_ATTACK_PORT/tcp."
else
    log_info "UFW rule for Land Attack port $LAND_ATTACK_PORT/tcp already exists."
fi

# Allow SYN Flood Port
if ! ufw status verbose | grep -qw "$SYN_FLOOD_PORT/tcp.*ALLOW IN"; then
    ufw allow "$SYN_FLOOD_PORT/tcp" comment 'SYN Flood Target Port'
    log_info "UFW rule added for SYN Flood port $SYN_FLOOD_PORT/tcp."
else
    log_info "UFW rule for SYN Flood port $SYN_FLOOD_PORT/tcp already exists."
fi

ufw reload
log_info "UFW rules applied."

# --- 4. Ensure services are listening or simulate them ---
log_info "Ensuring services are listening on opened ports (or simulating)..."

# Kill existing listeners on these ports to ensure idempotency for nc
log_info "Checking for existing listeners on port $LAND_ATTACK_PORT..."
PIDS_LAND=$(pgrep -f "nc -lkp $LAND_ATTACK_PORT")
if [ -n "$PIDS_LAND" ]; then
    log_info "Killing existing nc listener(s) on port $LAND_ATTACK_PORT (PID(s): $PIDS_LAND)."
    kill $PIDS_LAND || log_info "Failed to kill some PIDs or no process was running."
    sleep 1 # Give a moment to
