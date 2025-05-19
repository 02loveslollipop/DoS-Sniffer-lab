#!/bin/bash

# Task 1: Common initial setup for all hosts

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
TARGET_IP=""
NETMASK=""
GATEWAY=""
INTERFACE_NAME=""
BACKUP_DIR_BASE="/opt/network_backups"
NETWORK_BACKUP_PATH_FILE="/tmp/network_backup_path.txt"

# --- Helper Functions ---
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# --- Argument Parsing ---
if [ "$#" -ne 4 ]; then
    log_error "Usage: $0 <target_ip> <netmask> <gateway> <interface_name>"
    log_error "Example: $0 192.168.1.10 255.255.255.0 192.168.1.1 eth0"
    exit 1
fi

TARGET_IP="$1"
NETMASK="$2"
GATEWAY="$3"
INTERFACE_NAME="$4"

log_info "Starting common host setup for interface $INTERFACE_NAME"
log_info "Target IP: $TARGET_IP, Netmask: $NETMASK, Gateway: $GATEWAY"

# --- 1. Store current network configuration (Netplan) ---
log_info "Storing current Netplan network configuration..."
BACKUP_DIR="${BACKUP_DIR_BASE}/$(date +%Y%m%d%H%M%S)_${INTERFACE_NAME}"
mkdir -p "$BACKUP_DIR"

if [ -d /etc/netplan ]; then
    if ls /etc/netplan/*.yaml 1> /dev/null 2>&1; then
        cp /etc/netplan/*.yaml "$BACKUP_DIR/"
        log_info "Netplan configuration YAMLs backed up to $BACKUP_DIR"
        # Store the path to this specific backup for the cleanup script
        echo "$BACKUP_DIR" > "$NETWORK_BACKUP_PATH_FILE"
    else
        log_info "No YAML files found in /etc/netplan. Skipping Netplan backup."
        # Create an empty marker or specific state file if needed for cleanup logic
        touch "$BACKUP_DIR/no_netplan_config_found.marker"
        echo "$BACKUP_DIR" > "$NETWORK_BACKUP_PATH_FILE"
    fi
else
    log_info "/etc/netplan directory not found. Assuming not using Netplan or Netplan not configured."
    # Create an empty marker or specific state file if needed for cleanup logic
    touch "$BACKUP_DIR/no_netplan_directory.marker"
    echo "$BACKUP_DIR" > "$NETWORK_BACKUP_PATH_FILE"
fi

# --- 2. Set the static IP address for the host (Netplan) ---
log_info "Setting static IP address for $INTERFACE_NAME using Netplan..."

NETPLAN_CONFIG_FILE="/etc/netplan/01-custom-${INTERFACE_NAME}.yaml"

log_info "Creating Netplan configuration file: $NETPLAN_CONFIG_FILE"

# Create a new Netplan configuration file for the static IP
# This configuration will overwrite others for the same interface if they exist after 'netplan apply'
# Ensure this doesn't conflict with other network management tools if any are active.
cat << EOF > "$NETPLAN_CONFIG_FILE"
network:
  version: 2
  renderer: networkd # or NetworkManager, depending on the system's default
  ethernets:
    $INTERFACE_NAME:
      dhcp4: no
      addresses:
        - $TARGET_IP/$NETMASK
      routes:
        - to: default
          via: $GATEWAY
      # Optional: Specify DNS servers
      # nameservers:
      #   addresses: [8.8.8.8, 1.1.1.1]
EOF

log_info "Applying Netplan configuration..."
if netplan apply; then
    log_info "Netplan configuration applied successfully for $INTERFACE_NAME."
else
    log_error "Failed to apply Netplan configuration. Check $NETPLAN_CONFIG_FILE and system logs."
    log_error "Attempting to revert to backed up Netplan configuration..."
    if [ -d "$BACKUP_DIR" ] && ls "$BACKUP_DIR"/*.yaml 1> /dev/null 2>&1; then
        rm -f /etc/netplan/*.yaml # Clear potentially broken configs
        cp "$BACKUP_DIR"/*.yaml /etc/netplan/
        if netplan apply; then
            log_info "Successfully reverted to backed up Netplan configuration."
        else
            log_error "CRITICAL: Failed to revert to backed up Netplan configuration. Manual intervention required."
        fi
    else
        log_error "CRITICAL: No Netplan backup found or backup was empty. Manual network intervention required."
    fi
    exit 1
fi

# --- 3. Update package lists ---
log_info "Updating package lists (apt update)..."
apt-get update -y

# --- 4. Install essential tools ---
PACKAGES_TO_INSTALL="python3-pip net-tools git ufw"
PACKAGES_INSTALLED_BY_SETUP_FILE="/tmp/packages_installed_by_setup.txt"

log_info "Installing essential tools: $PACKAGES_TO_INSTALL..."
# Record packages for potential removal by cleanup script
# This simply appends; cleanup script should handle duplicates if scripts are run multiple times
# A more robust solution might check if already installed or use a dedicated marker file per package.
echo "$PACKAGES_TO_INSTALL" >> "$PACKAGES_INSTALLED_BY_SETUP_FILE"

if apt-get install -y $PACKAGES_TO_INSTALL; then
    log_info "Essential tools installed successfully."
else
    log_error "Failed to install some or all essential tools."
    # Decide if this is a fatal error for the script
fi

# --- 5. Configure Firewall (UFW) ---
log_info "Configuring UFW (allowing SSH, enabling firewall)..."
ufw allow ssh # Ensure SSH access is not lost
ufw --force enable # Enable UFW, --force to bypass interactive prompt
log_info "UFW enabled and SSH allowed."

log_info "Common host setup script finished."
