# Real-host tests, 2026-09-26

The Docker suite has no systemd, no fanotify permission events and no second machine on the same Ethernet
segment. These tests were run where those exist. The scripts are in [`../test/realhost`](../test/realhost).

## Environment

- Victims: Ubuntu 24.04 (aarch64) VMs with kernel 7.0 and systemd 255, on a Mac, bridged to a real wired LAN
  so that each has its own MAC; the real router is the gateway. The `.deb` was built from the source of the
  day and installed with `dpkg`. An attacker VM sat on the same segment.
- One physical x86_64 Ubuntu 24.04 machine (kernel 6.8) with an older build.
- Not run on macOS: see "What was not done".

## Forged ARP against a Linux client (lockdown)

| Case | Result |
|---|---|
| 15 forged unicast ARP replies claiming the gateway, from another device, dynamic gateway entry | "ARP cache change on stable network session" and Air-Gap in about 1 second. Record: `arp_spoof_lockdown`, phase `full`, the trusted MAC stored. |
| The same, with the gateway ARP lock on (entry `PERMANENT`) | No effect: the kernel keeps the pinned entry, nothing is detected, nothing is cut. |
| Release after the attack stopped | Automatic, about 11 minutes later (10 minutes by default, then 3 checks over 60 seconds), gateway MAC verified as the trusted one. |
| `roamswitch emergency-restore` without `--force`, cause not verified | Refuses (exit 2 without a terminal), prints the current and trusted MAC. With `--force`: firewall tables, records, ARP lock, DNS and connection tracking restored; the gateway answers again. |

## A harmless multi-address machine (found by these tests)

A machine answering for two IPs with one MAC (here the attacker VM with an alias address; the same shape as
a PC running a VM or a NAS with an alias) is not an attack on the gateway.

| Build | Result |
|---|---|
| Before | In lockdown, "ARP SPOOFING DETECTED in lockdown" and a full Air-Gap, with no forged packet at all. The release check also counted that duplicate as "the spoof is still there" (read from the code; consistent with the physical machine below, which never released). |
| After | A notification only (10 languages); no cut. A forged gateway ARP with the duplicate still present: Air-Gap in about 1 second, automatic release about 11 minutes later (isolation at 15:56:46, released at 16:07:46). |

The physical machine, on the older build, went into Air-Gap at the first forged reply and was still isolated
more than an hour later; a Mac and a VM bridged next to it produced exactly this duplicate. It could not be
reached to release it remotely and has to be recovered on its console (`sudo roamswitch emergency-restore --force`).

## The isolation record and a service restart

`RuntimeDirectory=roamswitch` made systemd delete `/run/roamswitch` when the service stopped, and the isolation
record (cause, confidence, start) went with it: after `dpkg -i`, a restart or a crash, a high-confidence
isolation was rebuilt as "unknown", low-confidence, and lifted itself after 10 minutes. With
`RuntimeDirectoryPreserve=yes` the record (`arp_spoof_lockdown`, same start time) is identical before and after
`systemctl restart roamswitch`.

## Forged-source SYN scan (200 SYNs per case, Linux client)

| Forged source | Detected | Blocked | Why |
|---|---|---|---|
| The default gateway | yes | no | SYNs arrived from a MAC other than the gateway's neighbour entry |
| Another on-link host | yes | no | no MAC resolved for that address, so nothing real answers for it |
| An off-link address | yes | no | off-link, but the frames did not come from a gateway MAC |
| This host's own address | no | - | the kernel drops it |
| A real, resolvable scanner (control) | yes | yes, 10 minutes | |

With a default-deny profile the victim silently drops the SYNs, so an unresolved source is never blocked: it
fails safe.

## Ransomware behaviour on a real kernel (fanotify)

40 files of 64 KiB rewritten by one process, in a watched folder. "Lost" is how many were rewritten before the
process was frozen.

| Case | Before this date's fix | After |
|---|---|---|
| Full encryption, ordinary process name | detected, frozen; 31 of 40 lost | same |
| Full encryption, process name set to `python3` | **not detected**; 40 of 40 lost | detected, frozen |
| Full encryption, process name set to `git` | **not detected**; 40 of 40 lost | detected, frozen |
| Partial encryption (16 of every 32 bytes) | not detected | not detected |
| Encrypted data written as Base64 | not detected | not detected |
| Genuine `python3`, `cp -r`, `rsync -a`, `tar -x`, a bash script named `makepkg`, each writing 40 random files | `python3`, `cp`, `rsync`, `tar` were reported as an "unknown process" burst (1 or 2 detections each) | no detection |

The false reports came from short-lived tools having exited before the worker evaluated the burst; the writer
is now identified when the write is seen. The name check now also requires the executable (or the script an
interpreter runs) to agree with the name. A binary that is really called `git`, or the real `python3` running an
attacker's script, is still skipped: names are not a boundary.

## The GTK app, driven for real

The app ran in a private virtual display inside the VM, with a screenshot of that display. The Link Guard tab
shows the new field for DNS-tunnelling exempt domains with the saved value; the VPN tab with the Tailscale
backend shows no WireGuard rows. Typing an Exit Node saved "（なし — 保護オフ）node1.example.ts.net": the label was
part of the name (fixed). The Network tab's release button lifted the isolation without asking (fixed); the
release dialog now shows the cause, the phase, what to check, the gateway MACs and an acknowledgement box that
enables the button.

## Packages

| Target | Result |
|---|---|
| Fedora (aarch64), a built `.rpm`, `rpm -e` | the removal script ran `roamswitch uninstall --scripted`: firewall table and isolation record gone |
| Arch Linux ARM, a package with the shipped `.INSTALL`, `pacman -R` | same |
| Debian 12 and Ubuntu 22.04 (aarch64) | `apt install ./roamswitch.deb` resolves dependencies; no unresolved library; `purge` works |

## What was not done

- **macOS uninstaller, end to end.** The steps that matter (unregistering the helper's daemons and the system
  extension) need approvals in System Settings, and the uninstall itself starts from a modal dialog. In a macOS
  VM, GUI scripting stopped at the system's permission prompt, which cannot be answered without a person.
- **x86_64 packages on the Debian family other than the machine above**; the tests here were aarch64.
- **A gateway-MAC clone on a live LAN.** A second device with the router's MAC would confuse the real switch. It
  cannot be told apart by any MAC comparison (see the whitepaper); it was not measured.
- **Third-party reproduction.**
