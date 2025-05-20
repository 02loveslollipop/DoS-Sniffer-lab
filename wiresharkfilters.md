# Syn Flood
> Overwhelms a server with a barrage of connection initiation (SYN) requests, often from fake addresses. This exhausts server resources, preventing legitimate users from establishing connections.

tcp.flags.syn == 1 && tcp.flags.ack == 0 && tcp.flags.fin == 0 && tcp.flags.reset == 0 && tcp.flags.push == 0 && tcp.flags.urg == 0

tcp.flags.syn == 1 and tcp.flags.ack == 0

# LAND
> Sends a packet to a machine where the source and destination IP/port are identical. This can confuse older systems, causing them to loop, freeze, or crash.

ip.src == ip.dst

# Teardrop
> Sends deliberately malformed or overlapping IP fragments to a target system. Exploits flaws in the fragment reassembly process, potentially crashing the victim's OS.

ip.frag_offset == 0 && ip.flags.mf == 1 && ip.len < 60

