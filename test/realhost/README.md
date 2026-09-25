# Real-host tests

Scripts used on 2026-09-26 to test RoamSwitch Linux on a real kernel, real systemd and a real LAN, where the
Docker suite (`../docker`) cannot: it has no systemd, no fanotify permission events and no second machine
on the same Ethernet segment. The results are in [`../../docs/REAL_HOST_TESTS_2026-09-26.md`](../../docs/REAL_HOST_TESTS_2026-09-26.md).

**These scripts send forged ARP replies and forged TCP SYNs, and simulate ransomware. Use them only on a
network and on machines you own. Send forged ARP only to the victim (unicast), never broadcast.**

Setup used: two Ubuntu 24.04 VMs (a victim with the `.deb` installed, an attacker) bridged to the same wired
LAN, each with its own MAC, and the real router as the gateway. A VM that is bridged over Wi-Fi does not work:
the hypervisor rewrites MAC addresses there.

| Script | Run on | What it does |
|---|---|---|
| `arp_spoof.py IFACE VICTIM_IP VICTIM_MAC CLAIMED_IP CLAIMED_MAC COUNT INTERVAL` | attacker | Unicast ARP replies claiming `CLAIMED_IP` (the gateway) is at `CLAIMED_MAC`. |
| `arp_probe.py IFACE IP` | attacker | ARP who-has, prints the MAC that answers (is the victim alive at layer 2?). |
| `syn_scan.py IFACE DST_IP DST_MAC SRC_IP own FIRST LAST [DELAY]` | attacker | TCP SYNs to a port range with a forged IP source (own Ethernet source MAC). |
| `victim_monitor.sh SECONDS GW_IP OUTFILE` | victim | Once a second: gateway neighbour entry, isolation record. |
| `ransom_sim.pl DIR MODE [COMM]` | victim (as the desktop user) | Creates 40 files in `DIR` and rewrites them like ransomware: `full`, `partial` (16 of every 32 bytes), `b64`, `none`; `COMM` sets the process name. |
| `ransom_case.sh MODE [COMM]` | victim | Runs one case and prints whether the writer was frozen and how many files were lost. |
| `fp_case.sh NAME COMMAND...` | victim | Runs a genuine tool (`cp -r`, `rsync -a`, `tar -x`, `python3`) that writes many high-entropy files; it must not be detected. `fake_makepkg.sh` is a stand-in for a bash build script. |

Example (victim `192.168.1.251`, attacker on the same segment):

```sh
# attacker: forged gateway ARP to the victim
sudo python3 arp_spoof.py enp0s1 192.168.1.251 <victim-mac> 192.168.1.1 02:de:ad:be:ef:01 15 0.3
# victim: what happened?
sudo journalctl -u roamswitch --since -1min | grep -i -E 'arp|air-gap'
cat /run/roamswitch/airgap_isolation.json
```

Recover a victim that is isolated: `sudo roamswitch emergency-restore --force`.
