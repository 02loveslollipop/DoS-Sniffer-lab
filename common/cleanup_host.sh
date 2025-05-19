#!/bin/bash

# Task 15: General cleanup for all hosts

set -e

# --- Configuration ---
# Retrieve backup path if stored by setup script
NETWORK_BACKUP_PATH_FILE="/tmp/network_backup_path.txt"
BACKUP_DIR=""
if [ -f "$NETWORK_BACKUP_PATH_FILE" ]; then
    BACKUP_DIR=$(cat "$NETWORK_BACKUP_PATH_FILE")
fi

# --- Helper Functions ---
log_info() {
    echo "[INFO-CLEANUP] $1"
}

log_error() {
    echo "[ERROR-CLEANUP] $1" >&2
}

log_warning() {
    echo "[WARN-CLEANUP] $1"
}

# --- Argument Parsing (if any needed, e.g., interface name) ---
# Example: INTERFACE_NAME="$1"

log_info "Starting common host cleanup..."

# --- 1. Stop running services/processes related to the simulation ---
log_info "Stopping simulation-related services/processes..."
# Example: pkill -f 'nc -lkp' if netcat listeners were used on the victim.
# This will be more specific in victim_cleanup.sh or if other general services are started.
if pkill -f 'nc -lkp'; then
    log_info "Killed running netcat listeners."
else
    log_info "No netcat listeners found or already stopped."
fi


# --- 2. Revert network configuration to its original state (Netplan) ---
log_info "Reverting Netplan network configuration to its original state..."
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    log_info "Attempting to restore Netplan config from $BACKUP_DIR"
    # Remove current Netplan configurations (especially the one we added)
    # Be cautious with blanket rm; ensure it targets only simulation-added files if possible.
    # For now, removing all and restoring from backup.
    current_netplan_files=$(ls /etc/netplan/*.yaml 2>/dev/null)
    if [ -n "$current_netplan_files" ]; then
        rm -f /etc/netplan/*.yaml
        log_info "Removed current Netplan configuration files."
    else
        log_info "No current Netplan files to remove in /etc/netplan/."
    fi

    if ls "$BACKUP_DIR"/*.yaml 1> /dev/null 2>&1; then
        cp "$BACKUP_DIR"/*.yaml /etc/netplan/
        log_info "Copied backed-up Netplan YAMLs to /etc/netplan/."
        if netplan apply; then
            log_info "Successfully reverted to backed-up Netplan configuration."
        else
            log_error "CRITICAL: Failed to apply restored Netplan configuration. Manual intervention required."
        fi
    elif [ -f "$BACKUP_DIR/no_netplan_config_found.marker" ] || [ -f "$BACKUP_DIR/no_netplan_directory.marker" ]; then
        log_info "Original state had no Netplan configuration or /etc/netplan was not found. Leaving /etc/netplan empty or as is."
        # If the system should default to DHCP, ensure it does.
        # This might mean creating a simple DHCP config if /etc/netplan is now empty.
        # Example: Ensure DHCP on a primary interface if no config was restored.
        # Find primary interface (heuristic, might need adjustment)
        # PRIMARY_INTERFACE=$(ip route | grep default | sed -e "s/^.*dev \([^ ]*\) .*$/\1/")
        # if [ -n "$PRIMARY_INTERFACE" ] && [ ! -f "/etc/netplan/00-dhcp.yaml" ]; then
        #   log_info "No specific Netplan config restored, ensuring DHCP on $PRIMARY_INTERFACE"
        #   cat << EOF > /etc/netplan/00-dhcp.yaml
        # network:
        #   version: 2
        #   ethernets:
        #     $PRIMARY_INTERFACE:
        #       dhcp4: true
        # EOF
        #   netplan apply
        # fi
    else
        log_warning "No Netplan backup YAMLs found in $BACKUP_DIR. Cannot restore."
    fi
    # Clean up the backup directory itself
    # rm -rf "$BACKUP_DIR"
    # log_info "Removed backup directory $BACKUP_DIR"
else
    log_warning "Network backup directory path not found or directory does not exist. Manual network reversion may be needed."
fi
rm -f "$NETWORK_BACKUP_PATH_FILE" # Clean up temp file

# --- 3. Remove installed packages/tools (optional) ---
log_info "Handling installed packages (optional step)..."

PACKAGES_INSTALLED_BY_SETUP_FILE="/tmp/packages_installed_by_setup.txt"

if [ -f "$PACKAGES_INSTALLED_BY_SETUP_FILE" ]; then
    PACKAGES_TO_REMOVE=$(cat "$PACKAGES_INSTALLED_BY_SETUP_FILE")
    if [ -n "$PACKAGES_TO_REMOVE" ]; then
        echo "The following packages were recorded as installed by the setup scripts:"
        echo "$PACKAGES_TO_REMOVE"
        read -p "Do you want to attempt to remove these packages? (yes/no): " REMOVE_PACKAGES_CHOICE
        if [[ "$REMOVE_PACKAGES_CHOICE" =~ ^[Yy](es)?$ ]]; then
            log_info "Attempting to remove packages: $PACKAGES_TO_REMOVE"
            if apt-get remove --purge -y $PACKAGES_TO_REMOVE; then
                log_info "Successfully removed packages."
                if apt-get autoremove -y; then
                    log_info "Successfully ran apt autoremove."
                else
                    log_warning "apt autoremove encountered an issue."
                fi
            else
                log_error "Failed to remove some or all packages. Manual cleanup may be needed."
            fi
        else
            log_info "Skipping package removal."
        fi
    else
        log_info "No packages were recorded as installed by setup scripts."
    fi
    rm -f "$PACKAGES_INSTALLED_BY_SETUP_FILE"
else
    log_info "No record of packages installed by setup scripts found. Skipping package removal."
fi

# --- 4. Revert firewall changes (UFW) ---
log_info "Reverting UFW firewall changes..."
# This is a simple approach; more granular rule deletion might be needed if setup adds many specific rules.
# For now, we will delete rules that were explicitly added by setup scripts.
# Assuming setup_host.sh adds 'allow ssh'
# Assuming setup_victim.sh adds rules for LAND_ATTACK_PORT and SYN_FLOOD_PORT

# Delete rules added by setup scripts (idempotent)
RULES_TO_DELETE=(
    "allow ssh"
    # Victim ports will be handled by victim_cleanup.sh if it passes them here or handles them itself
)

for rule in "${RULES_TO_DELETE[@]}"; do
    if ufw status | grep -qw "$(echo $rule | awk '{print $2}')"; then # Check if the port/service part of the rule exists
        log_info "Deleting UFW rule: $rule"
        ufw delete $rule
    else
        log_info "UFW rule '$rule' not found or already deleted."
    fi
done

# Consider disabling UFW if it was enabled by the script and wasn't enabled before.
# This requires storing UFW's initial state. For now, leaving it enabled if setup enabled it.
# A more robust way: check if ufw was active before `ufw enable` in setup_host.sh
# if ufw_was_inactive_before; then ufw disable; fi
log_info "Firewall cleanup: SSH rule deleted if present. Other rules should be handled by specific cleanup scripts or this one if generalized."
# If UFW was enabled by the script and should be disabled:
# log_info "Disabling UFW..."
# ufw disable

log_info "Common host cleanup script finished."
log_info "IMPORTANT: Reverting network configuration and firewall changes are placeholders and need careful OS-specific implementation."
