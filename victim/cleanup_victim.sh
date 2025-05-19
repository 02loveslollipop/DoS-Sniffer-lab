#!/bin/bash
set -e

COMMON_CLEANUP_SCRIPT_PATH="../common/cleanup_host.sh"

# --- Configuration ---
# Default ports for attacks, matching setup_victim.sh defaults
DEFAULT_LAND_ATTACK_PORT="139"
DEFAULT_SYN_FLOOD_PORT="80"

log_info() { echo "[INFO-CLEANUP-VICTIM] $1"; }
log_error() { echo "[ERROR-CLEANUP-VICTIM] $1" >&2; }

log_info "Starting victim host cleanup..."

# --- Argument Parsing for Victim Cleanup ---
# These arguments should match those potentially passed to setup_victim.sh
# to ensure the correct ports are targeted for cleanup.
LAND_ATTACK_PORT="${1:-$DEFAULT_LAND_ATTACK_PORT}"
SYN_FLOOD_PORT="${2:-$DEFAULT_SYN_FLOOD_PORT}"

log_info "Targeting Land Attack Port for UFW rule deletion: $LAND_ATTACK_PORT"
log_info "Targeting SYN Flood Port for UFW rule deletion: $SYN_FLOOD_PORT"

# --- Victim-specific cleanup ---
# Task 17: Close opened ports by deleting UFW rules.
# The common cleanup script handles killing netcat listeners.

log_info "Deleting UFW rules for victim-specific ports..."

# Delete Land Attack Port rule (idempotent)
if ufw status verbose | grep -qw "$LAND_ATTACK_PORT/tcp.*ALLOW IN"; then
    ufw delete allow "$LAND_ATTACK_PORT/tcp"
    log_info "UFW rule for Land Attack port $LAND_ATTACK_PORT/tcp deleted."
else
    log_info "UFW rule for Land Attack port $LAND_ATTACK_PORT/tcp not found or already deleted."
fi

# Delete SYN Flood Port rule (idempotent)
if ufw status verbose | grep -qw "$SYN_FLOOD_PORT/tcp.*ALLOW IN"; then
    ufw delete allow "$SYN_FLOOD_PORT/tcp"
    log_info "UFW rule for SYN Flood port $SYN_FLOOD_PORT/tcp deleted."
else
    log_info "UFW rule for SYN Flood port $SYN_FLOOD_PORT/tcp not found or already deleted."
fi

if ufw status | grep -qw active; then # Only reload if UFW is active
    log_info "Reloading UFW rules..."
    ufw reload
    log_info "UFW reloaded."
else
    log_info "UFW is not active, skipping reload."
fi

if [ -f "$COMMON_CLEANUP_SCRIPT_PATH" ]; then
    log_info "Running common host cleanup script..."
    if bash "$COMMON_CLEANUP_SCRIPT_PATH"; then
        log_info "Common host cleanup completed successfully for victim."
    else
        log_error "Common host cleanup failed for victim."
    fi
else
    log_error "Common cleanup script not found at $COMMON_CLEANUP_SCRIPT_PATH"
    exit 1
fi

log_info "Victim host cleanup finished."
