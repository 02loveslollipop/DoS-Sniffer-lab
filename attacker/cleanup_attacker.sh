#!/bin/bash
set -e
COMMON_CLEANUP_SCRIPT_PATH="../common/cleanup_host.sh"
log_info() { echo "[INFO-CLEANUP-ATTACKER] $1"; }
log_error() { echo "[ERROR-CLEANUP-ATTACKER] $1" >&2; }

log_info "Starting attacker host cleanup..."

# Attacker-specific cleanup (e.g., stop attack scripts if any are long-running and not handled by general process kill)
echo "TODO: Add attacker-specific cleanup tasks if any (e.g., kill specific attack processes)."

if [ -f "$COMMON_CLEANUP_SCRIPT_PATH" ]; then
    log_info "Running common host cleanup script..."
    # Pass any necessary arguments to common_cleanup_host.sh if it needs them
    if bash "$COMMON_CLEANUP_SCRIPT_PATH"; then
        log_info "Common host cleanup completed successfully for attacker."
    else
        log_error "Common host cleanup failed for attacker."
        # exit 1 # Decide if failure here is fatal for the rest of this script
    fi
else
    log_error "Common cleanup script not found at $COMMON_CLEANUP_SCRIPT_PATH"
    exit 1
fi
log_info "Attacker host cleanup finished."
