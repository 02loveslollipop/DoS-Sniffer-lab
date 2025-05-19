#!/bin/bash
set -e
COMMON_CLEANUP_SCRIPT_PATH="../common/cleanup_host.sh"
log_info() { echo "[INFO-CLEANUP-SNIFFER] $1"; }
log_error() { echo "[ERROR-CLEANUP-SNIFFER] $1" >&2; }

log_info "Starting sniffer host cleanup..."

# Sniffer-specific cleanup

# --- 1. Stop and remove Snort Docker container and image ---
log_info "Stopping and removing Snort Docker container and associated images..."
SNORT_COMPOSE_FILE_PATH="." # Assuming this script is in sniffer/ and docker-compose.yml is in sniffer/

if [ -f "${SNORT_COMPOSE_FILE_PATH}/docker-compose.yml" ]; then
    log_info "Found docker-compose.yml in ${SNORT_COMPOSE_FILE_PATH}, attempting to stop and remove Snort service and local images..."
    # Change to the directory containing docker-compose.yml to ensure correct context for compose commands
    current_dir=$(pwd)
    cd "${SNORT_COMPOSE_FILE_PATH}"
    if docker-compose down --rmi local; then # --rmi local removes images built by compose
        log_info "Snort Docker service stopped and locally built images removed successfully."
    else
        log_error "Failed to stop/remove Snort Docker service/images. Manual cleanup may be needed."
    fi
    cd "$current_dir"
else
    log_warning "Snort docker-compose.yml not found in ${SNORT_COMPOSE_FILE_PATH}. Manual Docker cleanup might be needed."
fi

# --- 2. Revert switch port mirroring configuration ---
log_info "Attempting to revert switch port mirroring configuration..."
SWITCH_CONFIG_SCRIPT="./configure_switch_mirror.py" # Assuming it's in the same directory (sniffer/)

# Check if the script exists and is executable
if [ -f "$SWITCH_CONFIG_SCRIPT" ] && [ -x "$SWITCH_CONFIG_SCRIPT" ]; then
    echo "To revert switch port mirroring, the script '$SWITCH_CONFIG_SCRIPT' would need a --revert option."
    echo "Please provide the necessary parameters if you want to attempt this."
    read -p "Do you want to attempt to revert switch configuration using $SWITCH_CONFIG_SCRIPT? (yes/no): " REVERT_SWITCH_CHOICE
    if [[ "$REVERT_SWITCH_CHOICE" =~ ^[Yy](es)?$ ]]; then
        # These would be the same parameters used for setup, or a session identifier
        read -p "Enter serial port for switch (e.g., /dev/ttyUSB0): " SWITCH_SERIAL_PORT
        read -p "Enter switch username: " SWITCH_USERNAME
        read -s -p "Enter switch password: " SWITCH_PASSWORD
        echo
        read -s -p "Enter switch enable password: " SWITCH_ENABLE_PASSWORD
        echo
        # The revert action might not need source/destination ports if it clears a session by ID, 
        # or it might need the original destination port to know which session to clear.
        # For now, we assume it can figure it out or the script is adapted for a simple revert.
        log_info "Calling $SWITCH_CONFIG_SCRIPT with --revert (actual implementation in script needed)..."
        if python3 "$SWITCH_CONFIG_SCRIPT" --revert \
            --port "$SWITCH_SERIAL_PORT" \
            --username "$SWITCH_USERNAME" \
            --password "$SWITCH_PASSWORD" \
            --enable_password "$SWITCH_ENABLE_PASSWORD"; then # Add other params if script needs them for revert
            log_info "Switch configuration revert script executed. Check script output for success."
        else
            log_error "Switch configuration revert script failed or was skipped. Manual reversion may be needed."
        fi
    else
        log_info "Skipping automated switch configuration reversion."
    fi
else
    log_warning "Switch configuration script $SWITCH_CONFIG_SCRIPT not found or not executable. Manual reversion needed."
fi
log_info "Reminder: If automated reversion was not performed or failed, please manually remove the SPAN session from your Cisco switch."
log_info "Example manual Cisco commands:"
log_info "  configure terminal"
log_info "  no monitor session <session_number>"
log_info "  end"

# --- 3. Call Common Cleanup Script ---
if [ -f "$COMMON_CLEANUP_SCRIPT_PATH" ]; then
    log_info "Running common host cleanup script..."
    if bash "$COMMON_CLEANUP_SCRIPT_PATH"; then
        log_info "Common host cleanup completed successfully for sniffer."
    else
        log_error "Common host cleanup failed for sniffer."
    fi
else
    log_error "Common cleanup script not found at $COMMON_CLEANUP_SCRIPT_PATH"
    exit 1
fi
log_info "Sniffer host cleanup finished."
