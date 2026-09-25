import socket, struct, sys, time, random
# usage: syn_scan.py IFACE DST_IP DST_MAC SRC_IP SRC_MAC_OR_own FIRST_PORT LAST_PORT [DELAY]
# Sends TCP SYNs with a forged IP source, framed with our own (or a given) Ethernet source MAC.
iface, dip, dmac, sip, smac, p1, p2 = sys.argv[1:8]
delay = float(sys.argv[8]) if len(sys.argv) > 8 else 0.002
def mac(s): return bytes(int(x,16) for x in s.split(':'))
def csum(b):
    if len(b) % 2: b += b'\0'
    s = sum(struct.unpack('!%dH' % (len(b)//2), b))
    s = (s >> 16) + (s & 0xffff); s += s >> 16
    return ~s & 0xffff
s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW); s.bind((iface, 0))
own = open(f'/sys/class/net/{iface}/address').read().strip()
src_mac = mac(own if smac == 'own' else smac)
n = 0
for port in range(int(p1), int(p2)+1):
    sport = random.randint(20000, 60000)
    tcp = struct.pack('!HHIIBBHHH', sport, port, random.getrandbits(32), 0, 5<<4, 0x02, 64240, 0, 0)
    pseudo = socket.inet_aton(sip) + socket.inet_aton(dip) + struct.pack('!BBH', 0, 6, len(tcp))
    tcp = tcp[:16] + struct.pack('!H', csum(pseudo + tcp)) + tcp[18:]
    ip = struct.pack('!BBHHHBBH', 0x45, 0, 20+len(tcp), random.getrandbits(16), 0x4000, 64, 6, 0) + socket.inet_aton(sip) + socket.inet_aton(dip)
    ip = ip[:10] + struct.pack('!H', csum(ip)) + ip[12:]
    s.send(mac(dmac) + src_mac + b'\x08\x00' + ip + tcp)
    n += 1; time.sleep(delay)
print("sent", n, "SYNs src", sip, "eth-src", ':'.join('%02x'%b for b in src_mac))
