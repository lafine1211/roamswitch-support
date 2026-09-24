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
- The forged-address cases above were not re-run against these exact versions on real hardware for this
  page.

## ARP-spoof detection and the Air-Gap

Detection of a changed gateway MAC can lead to a full network cut (Air-Gap) when lockdown is active, or when
the user chooses "contain now" on the warning. A forged ARP reply is enough to trigger the detection, so an
attacker on the same segment can make the warning appear. This is a denial-of-service path by design.

- Mac: outside lockdown the detection only warns. The Air-Gap needs the user's choice or lockdown.
  Release: see the security whitepaper section 4. The whitepaper and the changelog say an ARP-caused
  isolation is not released automatically. The code also contains a read-only check that could release it
  after three consecutive matching reads over 60 seconds. Which one applies on a real Mac is not verified.
- Linux: the ARP re-check sends a direct ARP request when the gateway has no neighbour entry
  (`arp_recheck_active_probe`, on by default, from 1.9.91) to reduce isolations that stay stuck.

## Not verified

- Behaviour with a forged MAC on the gateway itself (a rogue access point that copies the gateway MAC).
  No public test exists for whether protection is relaxed on a network trusted only by gateway MAC.
- A third-party reproduction of any of the above.
