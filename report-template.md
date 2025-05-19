# DoS Attack Simulation Report

## 1. General Information

*   **Date of Simulation:** YYYY-MM-DD
*   **Tester Name/ID:** [Your Name/ID]
*   **Lab Setup Reference:** (Link to or version of the `README.md` or setup documentation used)
    *   Attacker IP (Host1): `192.168.1.101` (or as configured)
    *   Sniffer IP (Host2): `192.168.1.102` (or as configured)
    *   Victim IP (Host3): `192.168.1.103` (or as configured)
*   **Snort Version:** (Specify Snort version used, e.g., Snort 3.x)
*   **Wireshark Version:** (Specify Wireshark version used)

## 2. Land Attack Simulation

### 2.1. Attack Parameters
*   **Target IP (Victim):** [e.g., `192.168.1.103`]
*   **Target Port:** [e.g., `139`]
*   **Source IP (Spoofed, same as Target):** [e.g., `192.168.1.103`]
*   **Source Port (Spoofed, same as Target):** [e.g., `139`]
*   **Number of Packets Sent:** [As per `land_attack.py` execution]
*   **Duration/Rate:** [If applicable/modified in script]

### 2.2. Manual Detection (Wireshark on Host2)
*   **Wireshark Filter Used:** [e.g., `ip.src == <victim_ip> and ip.dst == <victim_ip> and tcp.srcport == <target_port> and tcp.dstport == <target_port> and tcp.flags.syn == 1`]
*   **Observed Packet Characteristics:**
    *   [Describe the packets seen, confirming source IP/port match destination IP/port]
    *   [Note any responses or lack thereof from the victim]
*   **Screenshots:**
    *   *(Placeholder for Wireshark screenshot showing Land attack packets)*

### 2.3. Automated Detection (Snort on Host2)
*   **Snort Rule Triggered (SID):** [e.g., `1000001`]
*   **Alert Message:** [Copy the exact alert message from Snort logs, e.g., "DOS Land Attack Detected (Matching IP/Port)"]
*   **Log Snippet:**
    ```
    (Paste relevant lines from Snort's alert log)
    ```

### 2.4. Impact on Victim (Host3)
*   **Observed Behavior:** [e.g., CPU usage, service responsiveness, error messages on victim console/logs]
*   **Netcat Listener Status:** [e.g., Did the `nc` listener on the target port crash or become unresponsive?]

## 3. TCP SYN Flood Attack Simulation

### 3.1. Attack Parameters
*   **Target IP (Victim):** [e.g., `192.168.1.103`]
*   **Target Port:** [e.g., `80`]
*   **Number of SYN Packets Sent:** [As per `syn_flood.py` execution]
*   **Sending Rate/Interval:** [As per `syn_flood.py` execution]
*   **Source IP Spoofing:** [Yes/No, range if applicable]

### 3.2. Manual Detection (Wireshark on Host2)
*   **Wireshark Filter Used:** [e.g., `ip.dst == <victim_ip> and tcp.dstport == <target_port> and tcp.flags.syn == 1`]
*   **Observed Packet Characteristics:**
    *   [Describe the high volume of SYN packets]
    *   [Note the variety of source IPs if spoofing was effective]
    *   [Observe lack of corresponding SYN-ACKs from the victim for many SYNs]
*   **Screenshots:**
    *   *(Placeholder for Wireshark screenshot showing SYN flood packets)*
    *   *(Optional: Wireshark I/O graph showing traffic spike)*

### 3.3. Automated Detection (Snort on Host2)
*   **Snort Rule Triggered (SID):** [e.g., `1000002`]
*   **Alert Message:** [Copy the exact alert message, e.g., "DOS TCP SYN Flood Detected"]
*   **Log Snippet:**
    ```
    (Paste relevant lines from Snort's alert log)
    ```

### 3.4. Impact on Victim (Host3)
*   **Observed Behavior:** [e.g., High CPU usage, slow response times, connection table exhaustion (`netstat -anp | grep SYN_RECV`), service unavailability]
*   **Netcat Listener Status:** [e.g., Did the `nc` listener on the target port become overwhelmed or stop accepting new connections?]

## 4. Teardrop Attack Simulation

### 4.1. Attack Parameters
*   **Target IP (Victim):** [e.g., `192.168.1.103`]
*   **Number of Fragment Pairs Sent:** [As per `teardrop_attack.py` execution]
*   **Fragment Offset Details:** [Briefly describe the overlapping offset strategy if known/modified]

### 4.2. Manual Detection (Wireshark on Host2)
*   **Wireshark Filter Used:** [e.g., `ip.dst == <victim_ip> and ip.flags.mf == 1` or `ip.frag_offset != 0`]
*   **Observed Packet Characteristics:**
    *   [Describe the fragmented packets, noting MF bit, fragment offsets, and small sizes if applicable]
    *   [Look for evidence of overlapping fragments if Wireshark can display this or if deduced from packet details]
*   **Screenshots:**
    *   *(Placeholder for Wireshark screenshot showing Teardrop attack fragments)*

### 4.3. Automated Detection (Snort on Host2)
*   **Snort Rule Triggered (SID(s)):** [e.g., `1000003`, `1000004`]
*   **Alert Message(s):** [Copy the exact alert messages]
*   **Log Snippet:**
    ```
    (Paste relevant lines from Snort's alert log for each triggered rule)
    ```

### 4.4. Impact on Victim (Host3)
*   **Observed Behavior:** [e.g., System instability, crashes, high CPU usage during reassembly attempts, error messages related to IP reassembly in system logs]
*   **Network Connectivity:** [Any disruption to general network connectivity for the victim?]

## 5. Overall Summary & Conclusion

*   **Effectiveness of Manual Detection (Wireshark):**
    *   [Summarize how well Wireshark helped in identifying each attack]
    *   [Challenges encountered, if any]
*   **Effectiveness of Automated Detection (Snort):**
    *   [Summarize how well Snort detected each attack]
    *   [Discuss any false positives or negatives if observed/suspected]
    *   [Effectiveness of the custom rules]
*   **Observed Impact on Victim Host:**
    *   [General summary of how the victim was affected by the attacks]
*   **Lessons Learned:**
    *   [Key takeaways from the simulation exercise]
*   **Potential Improvements/Further Investigations:**
    *   [Ideas for refining Snort rules, attack scripts, or lab setup]
    *   [Other attack types or scenarios to explore]

---
*End of Report Template*
---
