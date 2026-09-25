# Can the automatic blocks be turned against you? What is verified and what is not

Written 2026-09-25 for Mac 1.10.3 and Linux 1.10.4. It reads the source and the unit tests. It does not
claim a live attack reproduction except where a lab measurement is named.

An automatic block is a tool for an attacker if a forged packet can make the defence cut off a legitimate
peer. This page lists the paths that were considered, what stops each one, and what still works.

## Port-scan auto-block (Mac and Linux)

A SYN scan never completes a handshake, so the source address is whatever the sender writes there.

| Case | Result | Where it is tested |
|---|---|---|
| Forged SYNs whose source is the default gateway, a DNS resolver, or this host | Detected and recorded, never blocked | Mac `PortScanProtectedAddressesTests`, Linux `gateway_resolver_and_own_address_are_never_blocked` |
| Loopback, broadcast, multicast, unspecified sources | Never blocked | same tests |
| Forged source that is another on-link peer (Linux) | Not blocked. The frames carry the forger's MAC, which differs from the neighbour table | Linux `a_forged_on_link_source_is_not_blocked` |
| Forged off-link source (Linux) | Not blocked unless the frame came from a gateway MAC | Linux `off_link_sources_must_arrive_via_a_gateway_mac` |
| Forged source on Mac that is not gateway, resolver or own address | Can still be blocked, for a limited time. The block covers only new inbound TCP connections, so replies and established flows keep working | Mac `PFRulesetCoordinator` rule (`flags S/SA`) |
| A flood of forged SYNs | The log is rate limited (200 per second) and anything above it is counted. In an isolated lab about 70,000 forged SYNs per second produced about 900 log lines. Saturation raises a notification at most once per 6 hours | Linux 1.9.87 |
| A flood that fills pf's state table (Mac) | Fixed in 1.9.47. In a lab, 24 of 100 forged SYNs still had state after 3 seconds. Floods with many different sources are not blocked | Mac 1.9.47 |

Known limits.

- Mac cannot check the source MAC. `pflog0` frames carry no Ethernet header.
- On Linux, a forger who first sends one ARP request claiming the address makes the neighbour table agree
  with the forger. This was measured in an isolated lab on 2026-09-20. The gateway's ARP entry is
  additionally pinned by the ARP lock (on by default on Linux, Pro and off by default on Mac).
- On Linux, the forged-address cases were re-run on a real kernel and LAN on 2026-09-26 (see below). On Mac
  they were not.

## ARP-spoof detection and the Air-Gap

Detection of a changed gateway MAC can lead to a full network cut (Air-Gap) when lockdown is active, or when
the user chooses "contain now" on the warning. A forged ARP reply is enough to trigger the detection, so an
attacker on the same segment can make the warning appear. This is a denial-of-service path by design.

- Mac: outside lockdown the detection only warns. The Air-Gap needs the user's choice or lockdown. A read-only
  check (three consecutive matching ARP-cache reads over 60 seconds) releases an ARP-caused isolation
  automatically when it can confirm the cause is gone. During isolation the gateway's ARP entry can disappear
  from the neighbour table (seen on a real Mac); then the check cannot confirm, and the isolation stays until it
  is released by hand. The security whitepaper section 4 says the same since 2026-09-26. The combination was not
  reproduced end to end on a real Mac.
- Linux: the ARP re-check sends a direct ARP request when the gateway has no neighbour entry
  (`arp_recheck_active_probe`, on by default, from 1.9.91) to reduce isolations that stay stuck.

## Lab results

The cases above for Linux (forged gateway ARP, forged-source SYN scans, release of an ARP isolation) were run on a real kernel and a real LAN on 2026-09-26; see [REAL_HOST_TESTS_2026-09-26.md](REAL_HOST_TESTS_2026-09-26.md). That run found and fixed a harmless machine answering for two IPs cutting a lockdown machine off completely, and an isolation record lost on every service restart.

## Not verified

- Behaviour with a forged MAC on the gateway itself (a rogue access point that copies the gateway MAC).
  Not measured: a second device with the router's MAC would confuse the real switch of the test LAN. No MAC
  comparison can tell the clone from the router, so a network trusted only by gateway MAC is trusted.
- A third-party reproduction of any of the above.
