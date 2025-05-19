#!/bin/bash
set -e
COMMON_CLEANUP_SCRIPT_PATH="../common/cleanup_host.sh"
log_info() { echo "[INFO-CLEANUP-VICTIM] $1"; }
log_error() { echo "[ERROR-CLEANUP-VICTIM] $1" >&2; }

log_info "Starting victim host cleanup..."

# Victim-specific cleanup
# Task 17: Close opened ports.
# This should ideally be handled by the common_cleanup_host.sh script's firewall reversion logic.
# If specific netcat listeners were started, common_cleanup_host.sh should also handle killing them.
log_info "Ensuring opened ports are closed (primarily handled by common cleanup firewall reversion)..."
echo "TODO: Verify that common_cleanup_host.sh correctly reverts firewall rules for ports $LAND_ATTACK_PORT and $SYN_FLOOD_PORT."

if [ -f "$COMMON_CLEANUP_SCRIPT_PATH" ]; then
    log_info "Running common host cleanup script..."
    if bash "$COMMON_CLEANUP_SCRIPT_PATH"; then # Pass LAND_ATTACK_PORT and SYN_FLOOD_PORT if common cleanup needs them for specific rule deletion
        log_info "Common host cleanup completed successfully for victim."
    else
        log_error "Common host cleanup failed for victim."
    fi
else
    log_error "Common cleanup script not found at $COMMON_CLEANUP_SCRIPT_PATH"
    exit 1
fi
log_info "Victim host cleanup finished."
