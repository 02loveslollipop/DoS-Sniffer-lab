#!/usr/bin/env python3
import serial
import time
import argparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Configuration Constants (Modify these as per your environment) ---
DEFAULT_SERIAL_PORT = '/dev/ttyUSB0'  # Example serial port
DEFAULT_BAUD_RATE = 9600
DEFAULT_TIMEOUT = 5  # seconds

# Cisco switch commands - these are examples and will vary based on your switch model and IOS version
# Ensure you have the correct commands for your specific switch.
# It's assumed the script will be run with sufficient privileges on the switch after login.
CISCO_ENABLE_PASSWORD = "your_enable_password" # Replace with your enable password if needed, or None
CISCO_USERNAME = "your_username" # Replace with your switch username
CISCO_PASSWORD = "your_password" # Replace with your switch password

# --- Helper Functions ---

def send_command(ser, command, timeout=2, expect_prompt=True, prompt="#"):
    """Sends a command to the serial device and waits for the prompt or timeout."""
    logging.info(f"Sending command: {command.strip()}")
    ser.write(command.encode('ascii'))
    time.sleep(0.5) # Give a bit of time for the command to be processed

    output = ""
    start_time = time.time()
    while True:
        if ser.in_waiting > 0:
            output += ser.read(ser.in_waiting).decode('ascii', errors='replace')
            if expect_prompt and prompt in output:
                break
        if time.time() - start_time > timeout:
            logging.warning(f"Timeout waiting for prompt after command: {command.strip()}")
            break
        time.sleep(0.1)
    logging.debug(f"Output after '{command.strip()}': {output}")
    return output

def configure_port_mirroring(serial_port, baud_rate, timeout,
                             source_interfaces, destination_interface,
                             session_number=1, enable_password=None,
                             username=None, password=None, revert=False):
    """
    Configures or reverts port mirroring (SPAN) on a Cisco switch.

    Args:
        serial_port (str): The serial port to connect to (e.g., /dev/ttyUSB0).
        baud_rate (int): The baud rate for the serial connection.
        timeout (int): The timeout for serial operations.
        source_interfaces (list): List of source interface names (e.g., ['GigabitEthernet0/1', 'GigabitEthernet0/2']).
        destination_interface (str): The destination interface name (e.g., 'GigabitEthernet0/3').
        session_number (int): SPAN session number.
        enable_password (str, optional): Enable password for the switch.
        username (str, optional): Username for switch login.
        password (str, optional): Password for switch login.
        revert (bool): If True, removes the SPAN configuration.
    """
    try:
        logging.info(f"Attempting to connect to switch on {serial_port} at {baud_rate} baud.")
        with serial.Serial(serial_port, baud_rate, timeout=timeout) as ser:
            logging.info("Successfully connected to serial port.")

            # Optional: Handle login
            if username:
                send_command(ser, f"{username}\n", timeout=5, expect_prompt=True, prompt="Password:")
                if password:
                    send_command(ser, f"{password}\n", timeout=5, expect_prompt=True, prompt=">") # or "#" if direct to enable
                else:
                    logging.error("Password not provided for username.")
                    return False

            # Enter enable mode
            send_command(ser, "enable\n", timeout=3, expect_prompt=True, prompt="Password:")
            if enable_password:
                send_command(ser, f"{enable_password}\n", timeout=3, expect_prompt=True, prompt="#")
            else: # If no enable password or already in enable mode from login
                # Check if we are already in enable mode
                ser.write(b"\n") # Send a newline to get a prompt
                time.sleep(0.5)
                initial_prompt_check = ser.read(ser.in_waiting).decode('ascii', errors='replace')
                if "#" not in initial_prompt_check:
                    logging.error("Could not enter enable mode. Enable password might be required or incorrect.")
                    return False
                logging.info("Already in enable mode or no enable password needed.")


            # Enter configuration mode
            send_command(ser, "configure terminal\n", timeout=3, expect_prompt=True, prompt="(config)#")
            logging.info("Entered configuration mode.")

            if revert:
                logging.info(f"Reverting SPAN session {session_number}.")
                cmd = f"no monitor session {session_number}\n"
                send_command(ser, cmd, prompt="(config)#")
                logging.info(f"SPAN session {session_number} removed.")
            else:
                logging.info(f"Configuring SPAN session {session_number}.")
                # Remove existing session if any, to ensure idempotency
                cmd_remove_existing = f"no monitor session {session_number}\n"
                send_command(ser, cmd_remove_existing, prompt="(config)#")

                # Configure source interfaces
                for src_if in source_interfaces:
                    cmd_source = f"monitor session {session_number} source interface {src_if}\n"
                    send_command(ser, cmd_source, prompt="(config-monitor)#") # Prompt might change

                # Configure destination interface
                cmd_destination = f"monitor session {session_number} destination interface {destination_interface}\n"
                send_command(ser, cmd_destination, prompt="(config-monitor)#") # Prompt might change

                logging.info(f"SPAN session {session_number} configured: Sources {source_interfaces}, Destination {destination_interface}")

            # Exit configuration mode
            send_command(ser, "end\n", prompt="#")
            logging.info("Exited configuration mode.")

            # Optional: Save configuration
            # send_command(ser, "write memory\n", prompt="#", timeout=10)
            # logging.info("Configuration saved to startup-config.")

            ser.close()
            logging.info("Serial connection closed.")
            return True

    except serial.SerialException as e:
        logging.error(f"Serial connection error: {e}")
        return False
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
        return False

# --- Main Execution ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Configure Cisco Switch Port Mirroring (SPAN) via Serial.")
    parser.add_argument('--port', type=str, default=DEFAULT_SERIAL_PORT, help=f"Serial port (default: {DEFAULT_SERIAL_PORT}).")
    parser.add_argument('--baud', type=int, default=DEFAULT_BAUD_RATE, help=f"Baud rate (default: {DEFAULT_BAUD_RATE}).")
    parser.add_argument('--timeout', type=int, default=DEFAULT_TIMEOUT, help=f"Serial connection timeout in seconds (default: {DEFAULT_TIMEOUT}).")
    parser.add_argument('--session', type=int, default=1, help="SPAN session number (default: 1).")
    
    # Make source and destination optional if --revert is used
    parser.add_argument('--source', nargs='+', help="Source interface(s) (e.g., GigabitEthernet0/1 FastEthernet0/1). Required if not --revert.")
    parser.add_argument('--destination', type=str, help="Destination interface (e.g., GigabitEthernet0/2). Required if not --revert.")
    
    parser.add_argument('--enable-password', type=str, default=None, help="Enable password for the switch. If not provided, script will attempt to use pre-configured or no password.")
    parser.add_argument('--username', type=str, default=None, help="Username for switch login. If not provided, script will attempt to use pre-configured or no username.")
    parser.add_argument('--password', type=str, default=None, help="Password for switch login. If not provided, script will attempt to use pre-configured or no password.")
    
    parser.add_argument('--revert', action='store_true', help="Revert/remove the SPAN configuration instead of applying it.")
    parser.add_argument('--verbose', '-v', action='store_true', help="Enable verbose debug logging.")

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Update global Cisco credentials if provided via CLI, otherwise they use defaults or remain None
    # This allows overriding defaults if needed for a specific run.
    effective_enable_password = args.enable_password if args.enable_password is not None else CISCO_ENABLE_PASSWORD
    effective_username = args.username if args.username is not None else CISCO_USERNAME
    effective_password = args.password if args.password is not None else CISCO_PASSWORD

    if not args.revert and (not args.source or not args.destination):
        parser.error("--source and --destination are required unless --revert is specified.")

    logging.info("Starting switch configuration script.")
    logging.info(f"Action: {'Revert' if args.revert else 'Configure'} SPAN session {args.session}")
    if not args.revert:
        logging.info(f"Source Interface(s): {args.source}")
        logging.info(f"Destination Interface: {args.destination}")

    success = configure_port_mirroring(
        serial_port=args.port,
        baud_rate=args.baud,
        timeout=args.timeout,
        source_interfaces=args.source if not args.revert else [], # Pass empty list if reverting
        destination_interface=args.destination if not args.revert else "", # Pass empty string if reverting
        session_number=args.session,
        enable_password=effective_enable_password,
        username=effective_username,
        password=effective_password,
        revert=args.revert
    )

    if success:
        logging.info("Switch configuration script completed successfully.")
    else:
        logging.error("Switch configuration script failed.")
        exit(1)
