import socket, struct, sys, time
iface, tip = sys.argv[1], sys.argv[2]
s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(0x0806)); s.bind((iface,0)); s.settimeout(1.0)
my = bytes(int(x,16) for x in open(f'/sys/class/net/{iface}/address').read().strip().split(':'))
pkt = b'\xff'*6 + my + b'\x08\x06' + struct.pack('!HHBBH',1,0x0800,6,4,1) + my + socket.inet_aton('192.168.1.251') + b'\0'*6 + socket.inet_aton(tip)
for i in range(3):
    s.send(pkt); t=time.time()
    while time.time()-t<1.0:
        try: d=s.recv(2048)
        except socket.timeout: break
        if d[20:22]==b'\x00\x02' and d[28:32]==socket.inet_aton(tip):
            print("ARP reply from", tip, ':'.join('%02x'%b for b in d[22:28])); sys.exit(0)
print("no ARP reply from", tip)
