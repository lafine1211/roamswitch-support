# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.9.x series) are versioned
independently. Older releases are summarized in ranges.

---

## RoamSwitch Sensor

Software you install on your own general-purpose hardware (PC, Raspberry
Pi, etc., x86_64/arm64) — a separate product: pairing-code-based mutual
trust (fixed IP + short-lived code) with RoamSwitch-equipped endpoints
(Mac / Linux Client / Server Edition) for active vulnerability audits,
plus detection of new devices and spoofing on the LAN. Still under
development — see
<https://lafine.net/roamswitch-sensor-manual.html> for current status and
setup instructions.

### 0.3.11

- **Improve: the fingerprint field on the manual-pairing screen now explains itself.** Since the shown
  command already includes `--fingerprint` (0.3.10), this field is now labeled as being for the GUI /
  Mac entry field specifically.

### 0.3.10

- **Fix: the pairing command shown to you failed when run as-is.** The TUI's `sudo roamswitch sensor pair
  --addr … --code …` did not include the fingerprint, and Linux 1.9.90+ endpoints refuse to pair without
  one, so running it exactly as shown always failed. With TLS on, the command now includes
  `--fingerprint`. `sensor-cli issue-code` also prints the command to run on the endpoint (with this
  Sensor's own IP and fingerprint).

### 0.3.9

- **Add: the control API now speaks TLS 1.3 with certificate pinning.** Until now, pairing codes
  and audit results crossed the LAN in plaintext. The Sensor holds a self-signed certificate and
  the RoamSwitch client pins its fingerprint. The pairing request binds that fingerprint with a
  signature, so a man in the middle cannot complete pairing. `control.tls` is
  `off` / `optional` / `required` (default `optional`). In `optional` mode, clients that do not
  speak TLS yet still connect in plaintext, with a warning in the TUI and CLI while they do.
  Switch to `required` once every client is updated. `sensor-cli tls show|rotate`, `pairing show`.
- **Change: replay protection.** Signed requests now carry a timestamp (±300 seconds) and a
  one-time value. The old format is accepted only while `control.allow_legacy_signatures` is on,
  and warns each time. Pairing brute force is locked out per source and globally, and request
  lines are capped at 64 KiB.
- **Add: the TUI now covers every function of the CLI and daemon.** View and edit all 25 config
  keys, TLS status and certificate rotation, manual pairing, a test notification, the passive
  capture / IoT behaviour / network threat / IoT advisory event views, collector management, and
  filtered exports. Ten languages; reports and exports are also rendered in ten languages.
- **Add**: a bind address (`control.bind_addr`), a switch to stop the CVE-map and NSE-database
  fetch (`updates.fetch_cve_map`), and a distinction between hosts that run RoamSwitch but are not
  paired and unknown devices (a per-device summary can optionally be sent to the collector).
- **Compatibility**: the RoamSwitch Mac app does not speak the Sensor's TLS or the new signatures
  yet. It keeps pairing as before while `control.tls=optional` and
  `allow_legacy_signatures=true` (both defaults). The Linux client speaks TLS from 1.9.90.

### 0.2.1 - 0.3.8

- **Better network inventory** (0.2.1 to 0.2.7): always-on tracking of the network
  layout, plus extended detection (botnet/DDoS participation, DNS tunneling). An active
  ARP sweep equivalent to `nmap -sn` closed detection gaps (and a bug that dropped the
  Sensor itself from the list was fixed), and the network layout and ARP events were
  reworked to carry enough information to act on (refreshed hourly). Device notes were
  added, and TUI display bugs were fixed.
- **Audit operations features for security teams at larger organizations** (0.3.0):
  scheduled audits, diffs against the previous run, notifications (webhook and syslog),
  a tamper-evident operation log, export, retention, and a central collector that
  aggregates several Sensors. Everything is opt-in, and nothing is sent anywhere by
  default.
- **Fixed automatic updates of the CVE maps and the NSE script DB failing silently**
  under systemd's write restrictions (0.3.1 to 0.3.2).
- **Added a diff tab, an operation-log tab and export to the TUI** (0.3.4).
- **Broader active audits** (0.3.5): Elasticsearch, CouchDB, VNC, RDP and SMB added.
- **Slow ARP sweeps detected** (0.3.8): a long window notifies once 64 distinct targets are reached within 24 hours (a 2.5 s-per-address sweep fired at the 64th target). Requests for hosts known to be alive do not count toward it, and the number of tracked MAC addresses, targets per MAC and the live-host table are capped, so a flood of spoofed sources cannot grow memory without bound.
- **Repository size** (0.3.7): the apt and rpm repositories had kept every past version, so they were cut to the latest one (1.10.5 and later keep the latest three).

### 0.2.0

- **Added: IoT-device-security-focused ARP events, in four tiers.**
  Previously an ARP event was just a bare MAC/IP diff with nothing
  actionable in it.
  - Tier 1: MAC-vendor classification against a curated, verified subset
    of the IEEE OUI registry (camera/smart-plug/etc. categories), a
    persistent per-device inventory (`sensor-cli device-inventory`), and
    detection of a single MAC issuing ARP requests for an unusual number
    of distinct IPs (possible LAN-internal reconnaissance).
  - Tier 2: reads self-announced mDNS/SSDP/DHCP identifiers (extends the
    existing passive packet-capture path) for more precise, model-level
    device identification than the OUI alone.
  - Tier 3: cross-references classified IoT devices' traffic against
    known-malicious destinations and admin-port contact on other LAN
    devices, with device context attached (`sensor-cli iot-events`,
    requires passive-capture to be configured).
  - Tier 4: a small, hand-verified reference table of real public CVEs
    for a handful of IoT vendors (e.g. Hikvision camera auth-bypass/RCE
    flaws) via `sensor-cli iot-advisories` — static, not a
    network-refreshed feed; that's out of scope for this release.
  - All four tiers are detection/reference only — Sensor never blocks
    traffic. Device classification is also shown inline in the
    `sensor-tui` ARP events tab.

### 0.1.0 - 0.1.7

- **Distributed as deb/rpm packages** (0.1.0), running as a systemd service. Extended
  passive LAN visibility (opt-in) was added too.
- **Pairing moved from mDNS discovery to a pairing code** (0.1.3). mDNS works only
  within one LAN segment, broadcasts constantly, and has no strong authentication by
  default. The Sensor sits at a fixed IP and issues a one-time code (8 characters,
  expires in 10 minutes), authenticated with Ed25519 signatures. Accepting audit
  requests from clients and making the nmap NSE supplementary scan always-on came in
  the same release.
- **Audit status badges for paired endpoints, and viewing the latest report** (0.1.4).
  Manual pairing was removed in favor of the code method, and the IP address is always
  shown.
- **Fixes** (0.1.5 to 0.1.7): several audits running in parallel against the same
  endpoint; the daemon crashing on `Too many open files` and losing in-flight audits
  (the file descriptor limit is now 65536); the detailed description missing from
  audit findings.

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.10.7

- **Changed: the license signing key was replaced, and the app accepts the old and the new public key.** Licenses activated before keep verifying; new activations are signed with the new key, so an older version cannot activate a new license: upgrade first.
- **Fixed: upgrading from the GUI could hang, report success when nothing changed, and did not restart the app.** (1) `apt-get update` waited for every repository, so one unreachable mirror left the tab on "Upgrading…" for good; it now refreshes only RoamSwitch's own repository (`roamswitch.list`) and gives up after 60 seconds. (2) `apt-get install --only-upgrade` exits 0 when the repository is not configured, so the tab said "complete" with nothing installed; the installed version is now compared before and after. (3) The restart used the path `…/roamswitch-app (deleted)` that `/proc/self/exe` shows once the package replaced the file, and started nothing; it now uses the real path. An upgrade made outside the app (a terminal, unattended upgrades) is noticed too, and the app restarts by itself (at once when the window is hidden, 40 seconds after a notice when it is open). The upgrade tab also detects pending upgrades on dnf, zypper and pacman, not only apt. Reproduced and checked in an Ubuntu 24.04 VM through the real polkit prompt.
- **Added: a "Recovery & Uninstall" tab in the main window** (10 languages). The two actions used to sit in the middle of the Help page. Uninstalling from the tray now waits up to 300 seconds for the package manager's lock (unattended-upgrades holds it after boot), which made the last step fail before; checked through the real polkit prompt.
- **Added: detection of partly encrypted files.** Only fully encrypted files were counted. Files where 16 of every 32 bytes are encrypted (the technique of LockBit-style families) are now detected (94% of simulated files; 2 of 19,997 ordinary files, 0.01%, would be flagged). Three more shapes (alternating 4 KiB regions, encrypted head, uniformly random Base64) are only counted and logged in shadow mode (`ransomware shadow (nothing frozen)`), never frozen, until field data shows they are safe: they flag about 1% of ordinary media files, or cannot be told from any Base64-encoded compressed data. Measurements: `docs/RANSOMWARE_SHAPES_2026-09-26.md`.
- **Fixed: on a low-resolution screen the tray menu's bottom submenus (recovery, language) looked empty.** GNOME opens a submenu inside the menu itself, and a menu taller than the screen pushes it out of view (found on a real machine). On screens 820 pixels tall or less the menu is now shorter (the four protection levels fold into one submenu); `ROAMSWITCH_TRAY_COMPACT=1` or `0` overrides it. **Added: "Recovery and uninstall" buttons in the Help & Guide tab** (the tray menu can be unusable on a small screen), and new Help & Guide entries on isolation status and release, recovery and uninstall, the compact tray menu, guard monitoring and the DNS-tunnelling exempt domains (10 languages).
- **Added: recovery and uninstall.** `roamswitch emergency-restore` and a "Recovery and uninstall" tray menu put the network back (isolation, firewall tables, gateway pin, DNS, connection tracking), and `roamswitch uninstall` (also run by the deb, rpm and Arch removal hooks) does that first and then removes the decoys and the files setup added. When the gateway is not the trusted one, or the isolation's cause is not verified gone, both refuse without an explicit acknowledgement (`--force`; a checkbox in the app; exit 2 without a terminal). Tested with real dpkg, rpm and pacman removals.
- **Fixed (security): a release adopted whatever gateway was present as the new trusted one, and the gateway pin froze a forged MAC permanently.** Only a verified release adopts the current gateway, and the pin is not made while a spoof is unresolved or when the MAC differs from the trusted one.
- **Fixed (security): on a wired link a changed gateway MAC was taken for a move to another network,** so a forged MAC reset the baseline and was pinned without any detection. A wired link now counts as moved only when the gateway address, the interface or the link state changed.
- **Fixed: a harmless machine answering for two IP addresses with one MAC (a PC running a VM, a NAS with an alias) cut a lockdown machine off completely, and the isolation was never released.** Found on a real LAN. Automatic isolation is now reserved for findings that involve the gateway; anything else is reported in a notification (10 languages) and does not cut the network. The release check counts only duplicates that involve the gateway. Verified with a second machine on the LAN: a forged gateway ARP triggered the Air-Gap in about 1 second, and it was released automatically about 11 minutes after the attack stopped, with the harmless duplicate still present.
- **Fixed (security): the isolation record (cause, confidence, start time) was deleted whenever the service stopped,** because systemd removed `/run/roamswitch`; after an upgrade, a restart or a crash, a high-confidence isolation became a low-confidence one that lifted itself after 10 minutes. The unit now sets `RuntimeDirectoryPreserve=yes`; verified across a restart.
- **Fixed: the ransomware burst check skipped any process whose name was on the allowlist, and short-lived tools were misreported.** A process could rename itself to `python3` or `git` and encrypt 40 files unnoticed (measured on a real machine). The allowlist now also requires that the executable, or the script an interpreter runs, agrees with the name. Separately, `cp -r`, `rsync -a`, `tar -x` and Python scripts writing 20+ compressed-looking files had usually exited by the time the burst was evaluated and were reported as an "unknown process"; the writer is now identified when the write is seen (signature scans still run for it). Partial encryption and Base64 output are still not detected; the measurements are in the Linux whitepaper.
- **Fixed: a false "the gateway's MAC changed" dialog** was shown for anomalies that do not involve the gateway.
- **Fixed: the Network tab's "Disable Air-Gap and restore" button lifted an isolation without asking,** unlike the emergency window. It now asks the same question and needs the acknowledgement checkbox when the cause is not verified gone.
- **Fixed: typing an Exit Node in the VPN tab appended to the "(none)" label and saved the label as part of the name.** Found by driving the real GTK app.
- **Fixed: the daemon did not start while the gateway was unreachable** (the ClamAV signature update ran synchronously with no time limit at start-up). **Fixed: Tailscale installed as a snap was invisible to the sandboxed daemon.** **Added: after setting a Tailscale exit node, the daemon checks that the kernel route really goes through the tunnel** and disarms itself with a notification if not. **Fixed: duplicate notifications when shared services were stopped or restored.**
- **Added: while an isolation is in force, the tray and the release dialog show its phase (full or degraded), its cause, how long it has lasted, and what to check before releasing (10 languages).**
- **Added: a field in the Link Guard tab for domains exempt from the DNS-tunnelling false-positive check** (10 languages; it used to need a hand edit of `config.json`).
- **Server: the setup wizard now requires a maintenance source** (blank is refused; `ANYWHERE` allows every address, including during isolation), **the investigation agent never runs as root** (not saved by the wizard, not started by the daemon), and **incident text is passed to it as truncated JSON strings** so it cannot forge a separator or an instruction section. **Added: `honeytokens_home`** (where the decoys are planted). **Added: the evidence bundle's `manifest.json` is anchored outside the bundle** (a hash chain in `evidence_anchor.log`, append-only where possible, and the system log), and `roamswitch-incident-capture verify` fails when the manifest was rewritten or the chain was edited.
- **Tested: deterministic fuzzing** of the Falco event lines, `guard.yaml`, `server.conf`, the isolation record, IPC refusal text, the DNS allowlist field and the maintenance-source answers never panics. The number of editable configuration keys (88 in `server.conf`, 37 in `guard.yaml`) is pinned by a test.
- **Security: the Link Guard's packet parser no longer runs as root.** The first packets of every new connection (IP, TCP, DNS, TLS ClientHello, HTTP) are bytes chosen by the other end. A child process (the same binary, `--link-guard-parser`) parses them after dropping to `nobody`, clearing its capabilities, setting no-new-privileges and installing a seccomp filter that allows only reading and writing its two pipes and managing memory; the daemon reads only its answer. If the worker is missing or slow, the packet is accepted unparsed (the guard never takes connectivity down) and the daemon does not parse it itself.

### 1.10.6

- **Security (server and client): the daemons run inside a systemd sandbox.** Kernel modules, the kernel log, cgroups, the clock, the host name, namespaces, realtime scheduling and SUID/SGID files are protected; capabilities and system calls the daemon never uses are removed; only the socket types it uses (Unix, IP, netlink, packet) are allowed; writable-executable memory is denied. `systemd-analyze security` went from 9.3 (UNSAFE) to 5.4 (MEDIUM). Each directive was applied in a real systemd 255 install, and the health report, the guards, host isolation and restore, the download guard and the FIM gave the same result as without them. `NoNewPrivileges`, `PrivateTmp` and `PrivateMounts` stay off because they break user notifications (`sudo -u`) and the `/tmp` noexec guard.
- **Fixed: the daily updater never updated the ClamAV signatures.** Its unit set `NoNewPrivileges=yes`, and `freshclam` fails to switch to the `clamav` user under it ("Failed to switch to clamav user"). The unit now allows it, holds only the capabilities it needs (no `NET_ADMIN`, `SYS_ADMIN`, `NET_RAW`, `KILL`), cannot open netlink or packet sockets, and can write `/var/log/clamav`.
- **Fixed (security): `rustls` is updated to 0.23.45 (RUSTSEC-2026-0285, TLS 1.3 handshake messages accepted across encryption levels).** CI now checks the dependency tree against the RustSec advisory database on every push.
- **Fixed: the "helper programs installed" diagnostic showed its status in Japanese in every other language.** A test now fails if a translated report contains Japanese.
- **Tested: the packet parsers of the Link Guard (TLS ClientHello, SNI, DNS, HTTP host, TCP reassembly) never panic on hostile input** (random bytes, every truncation, extreme length fields).

### 1.10.5

- **Fixed: the packages of 1.10.0 to 1.10.4 did not contain `roamswitch-honeytokens` and `roamswitch-incident-capture`, so credential decoys and forensic evidence bundles never ran on installs from the apt, dnf/zypper and tarball packages** (the daemons start them by name and treat a missing binary as a silent no-op). Both are now packaged for the client and the server, the daemons log an error at start-up if either is missing, and CI fails a build whose package lacks them (`scripts/check_package_contents.sh`).
- **Fixed (security): the root daemon trusted `~/.config/roamswitch/config.json` in every `/home/*` without checking who owned it, and followed a symlink when it wrote to it.** A local user could make root overwrite another JSON file, and a user's config could switch guards off for everyone. A config is now accepted only if it is a regular file (never a symlink), owned by the owner of that home (root or uid 1000 and above), and not writable by others (group-writable only when the group is the owner's own). Turning a guard off or adding scan exclusions is honoured only from root or a uid with a local login session, the same rule as the IPC.
- **Added (server): `honeytokens_enabled` (default true) and `harden_userns_enabled` (default true).** Turning honeytokens off stops planting and watching; decoys already on disk stay. `harden_userns_enabled=false` skips the permanent denial of unprivileged user namespaces, which breaks rootless containers; updating to a fixed kernel is the real fix for CVE-2026-53362.
- **Changed (server): the investigation agent is refused when it would run as root with its permission prompts switched off** (`--dangerously-skip-permissions` and similar). The setup form will not save it and the daemon will not start it.
- **Improved (server): evidence is captured before a host-wide Air-Gap, on an escalation from a failed per-process isolation, and on a ransomware canary trip.** Before, only per-process isolation captured evidence.
- **Improved (server): a start-up warning when the maintenance SSH ports stay open to every address during isolation (empty `whitelist_ips`), and when the egress blocklist is on but the feed is empty.**
- **Fixed (server): host isolation cut off the admin SSH channel it was meant to keep.** The isolation output chain ran at priority -300, before connection tracking, so `ct state established,related` never matched for the host's own replies and the SSH SYN-ACK (and every packet of an existing session) hit the drop policy. The operator was locked out during isolation even with `preserve_ssh_on_isolation=true`. The chain now runs at -100, with a regression test. Confirmed on the published 1.10.4 with the corrected pentest suite.
- **Fixed (server): with `preserve_ssh_on_isolation=false` host isolation still opened port 22** (an empty port list fell back to the legacy admin port). It now severs everything except loopback, as documented.
- **Fixed (server): an operator acknowledgement (`roamswitch server ack`) was ignored for a high-confidence isolation whose cause looked cleared.** The isolation was released although the command promises it will not auto-restore. An acknowledged FULL isolation is now held until the operator releases it.
- **Fixed: the FIM reported the honeytoken decoys under `/root/.ssh` as new files.** Once the helper binary is packaged the daemon plants them after the baseline exists, so the FIM tripped its own bait. Files carrying the honeytoken marker are no longer listed; a real key without the marker is still reported.
- **Pentest suite re-run on 2026-09-25** (Docker Desktop, arm64, Ubuntu 24.04 containers): the server suite passes 19 of 19 on a build of the 1.10 source with these fixes, and on the published 1.10.4 the corrected suite fails two checks (SSH during isolation, acknowledgement). The client suite passes 11 of 11. Kernel-level checks that need a real VM (user-namespace and Yama sysctls) are not covered. The suite now requires `PENT_DEB` and no longer tests a fixed v1.3.2 package by accident.
- **Fixed (server): the systemd unit's sandbox (`ProtectSystem=strict`, `ProtectHome=read-only`) stopped the daemon and the honeytoken helper from creating `~/.aws`, `~/.docker` and the ransomware canaries under `/root` and `/opt`.** The helper still exited 0, so the daemon logged "honeytokens deployed" with no decoy on disk. The unit now uses `ProtectHome=no` with `ReadWritePaths=-/root -/opt` (`/home` stays read-only through `ProtectSystem=strict`), and the helper exits 3 when it cannot plant a decoy. Found and confirmed in an Ubuntu 24.04 VM (kernel 7.0, systemd 255) with the published 1.10.4; the Docker suite has no such sandbox.
- **Added: a diagnostic "helper programs installed"** (client 27 items, server 33 items, 10 languages) that checks the two helper binaries the daemon starts by name are present.
- **Changed: apt and rpm keep the newest three versions of each package** (was one), so a defective release can be rolled back with `apt install roamswitch=<version>` or `dnf downgrade`.
- **Verified in a real VM (2026-09-25):** the Frag Gap mitigation lands (`user.max_user_namespaces=0`, `kernel.unprivileged_userns_clone=0`, Yama 2, unprivileged BPF off) and `unshare -U -r` is refused; and during host isolation SSH from another machine works on the fixed build and is cut off on the published 1.10.4.

### 1.10.4

- **Fixed: ClamAV detection relied on a fallback because `clamdscan --fdpass` always failed inside the daemon's systemd sandbox** ("Not a regular file"). `--stream` is now tried first and `--fdpass` is retried only on error. If both fail the result is an error, never "clean".
- **Fixed: the USB disk scan treated `clamdscan` exit code 2 (execution failure) as malware and ran `umount -f`.** Only exit code 1 (detection) now unmounts.
- **Added: a ClamAV detection self-test and a fanotify event-overflow check (diagnostics: Client 24→26, Server 30→32, 10 languages).** An EICAR test file verifies, 120 s after start and every 6 hours, that the detection path really works.
- **Fixed: DNS enforcement ran `resolvectl` (`dns`, `default-route`, `flush-caches`) every 3 seconds.** This flushed the DNS cache continuously and slowed name resolution. It now runs only when the state changes.
- **Improved: Docker protection (`DOCKER-USER`) is self-healed every 60 seconds (including IPv6 and native nftables)**, on the desktop edition too, instead of once at startup.
- **Improved: Link Guard.** The 50 ms packet-wait sleep was replaced with `poll(2)`, the queue length is 4096, and the TCP ClientHello is reassembled from sequence numbers (up to 8192 bytes). In block mode, an option (`linkGuard.blockQuic`, off by default) rejects UDP/443 (QUIC) so clients fall back to TCP.
- **Improved: fanotify on-access scanning.** Permission events are limited to execution (`FAN_OPEN_EXEC_PERM`); `open` is a notification (`fanotify_open_perm` restores the old behavior). Executables already scanned clean are cached for 60 s and the daemon's own children are excluded. A warning is shown when `/home` is on the same filesystem as `/`.
- **Changed: BadUSB guard.** An unapproved keyboard is no longer released after the 3-minute approval wait (`usb_keyboard_timeout_release` restores the old behavior). Hot-plug is detected immediately from `/dev/input`. A USB descriptor fingerprint (trust on first use) detects a different device claiming an already-approved VID:PID.
- **Changed (security): IPC calls that change state are accepted only from root or from a UID with a local login session.** Read-only calls are unchanged. A refusal returns a fixed code and is shown in the GUI (10-language notification) and the CLI (ja/en). The CLI's `airgap enable/disable` also reported success without reading the reply; that is fixed.
- **Improved: honeytoken decoy files no longer break real tools.** The AWS decoy no longer uses the `[default]` profile and the Docker decoy no longer targets Docker Hub (it uses a non-existent registry name). Decoys are created with mode 0600. Access by the OpenSSH clients (`ssh`, `scp`, `sftp`, …) and by RoamSwitch itself is recognized by executable path and no longer raises a false alarm. The accessing process is identified at event time with notify-class fanotify. Decoys planted by older versions are migrated on start (real files are never touched).
- **Improved: external commands are launched by absolute path**, removing audit-log noise from failed `PATH` lookups. `/proc/net/route` is parsed directly and unnecessary command launches were reduced.
- **Fixed: the advanced settings dropped unknown keys on save.** The GUI gains checkboxes for QUIC blocking, synchronous scanning on open, and keyboard auto-release (10 languages).

### 1.10.3

- **Improved: repeated identical notifications are now suppressed.** A notification with the same
  title and body is not shown as a pop-up or queued over IPC again for 10 minutes; it is still
  recorded in the notification history (every one is kept). Low-urgency notifications go to the
  history only. Dangerous-Docker-configuration notifications are likewise suppressed for the same
  image and the same reason (a new reason notifies immediately).
- **Fixed: DNS tunneling detection false-flagged `clamav.net` TXT responses (freshclam's
  definition check).** These TXT queries are now exempt (NULL records and high-entropy responses
  are still detected as before). The re-notification interval now grows in steps
  (300 → 600 → 1200 → 1800 s), and the notification text and timeline now include the target
  apex domain.
- **Improved: YARA false positives on development build output (under `target/debug` and
  `target/release`) no longer raise a notification or an approval request.** When ClamAV does not
  agree and nothing was blocked from executing, the hit is recorded in the history only. Hits that
  ClamAV disagrees with in the same directory and the same family are collapsed to one per 30
  minutes.
- **Improved: on Arch-based distributions, the "automatic security updates" diagnostic is now
  treated as "not applicable" (no score penalty).** Unattended `pacman -Syu` on a rolling release
  can leave the system unbootable through partial upgrades and is officially discouraged. If you
  have enabled automatic updates yourself, it is evaluated as usual. Behavior on non-Arch
  distributions is unchanged.
- **Fixed: removed hard-coded developer home-directory paths.** When `HOME` was unset, the MCP
  server's config-file lookup and the app's scan targets fell back to a fixed path. UIDs whose
  user name cannot be resolved are now skipped instead of running commands as a fixed user name.

### 1.10.2

- **Fixed: Server Edition's unknown-port-exposure guard could permanently, wrongly block the
  co-located RoamSwitch Sensor's own pairing control port (50543), depending on startup
  timing.** If this guard's baseline scan for "ports not yet known to be exposed" happened to run
  moments before the Sensor started listening on its control port, it flagged the Sensor's own
  port as a newly-seen, suspicious listener and blocked it — with no way to clear it short of
  restarting the daemon. Ports the firewall already always allows (`ssh_ports`, `allowed_ports`)
  are now exempt from this guard's auto-block, regardless of scan timing.

### 1.10.1

- **Fixed: a program that rebinds to a random ephemeral UDP port through an interpreter (like
  `wsdd`) was treated as a different port on every restart, repeating the notification endlessly.**
  Introduced a fingerprint that excludes the port (executable path + script arguments); only the
  first occurrence raises a desktop notification, and further occurrences with the same fingerprint
  are recorded to the notification history only. Individual incident records (for the MCP history)
  are still written every time.

### 1.10.0

- **Add: DNS tunneling / exfiltration detection** (Client and Server Edition). Watches this host's own
  outbound DNS queries for the suspicious shapes DNS-tunneling tools (iodine, dnscat2, …) rely on — long,
  high-entropy labels, or TXT/NULL query types — and alerts (and records to the incident timeline) once a
  burst crosses a threshold within a short window. Never inspects non-DNS traffic, and a stalled or
  crashed detector can never delay DNS resolution. Server Edition gets a new `dns_tunnel_detect_enabled`
  config key (on by default).
- **Add: forensic evidence bundles** (Client and Server Edition). When a containment action fires (a
  ransomware canary trip, a critical eBPF detection, …), a process list, recently-modified files, and a
  SHA-256 manifest are captured automatically.
- **Add: deception / credential honeytokens** (Client and Server Edition). Realistic-looking decoy files
  are placed at `.aws/credentials`, `.ssh/id_rsa`, `.docker/config.json`, and similar paths (with a cascade
  of related decoys); any real access is detected and alerted on immediately.
- **Add: vulnerability scan staleness (pass_age) is now visible.** For each active-verification probe
  (`scan-vulns --confirm`), the last recorded result and the days elapsed since are available from
  `roamswitch vuln-status`, the GUI app's Ports tab, and an MCP tool.
- **Add: health-check items now carry NIST CSF 2.0 / CIS Controls v8 mappings** (Client and Server
  Edition) — useful for audits and business/compliance conversations. Only confidently-mappable items get
  a control number; uncertain ones are left blank rather than guessed.
- **Fix: CPU usage could pin itself at high levels indefinitely in rare cases.** The malware guard (YARA)
  asking ClamAV for a second opinion spawns `clamdscan`, whose own file-open was re-detected by the
  on-access monitor, causing the notification pipeline to re-trigger itself in a self-sustaining loop.
  `clamdscan` (and `clamscan`/`clamd`) are now excluded from on-access monitoring.
- **Improve: `credential_watch` (off by default) now allowlists `ansible`/`python3`/`python`**, reducing
  false positives from common infrastructure-as-code tooling.
- **Add: four new AI-agent triage skills for `roamswitch-mcp`** (the MCP server), covering port-anomaly,
  active-vulnerability-scan, package-CVE, and ransomware/incident-timeline prioritization — a consistent
  procedure an AI agent can follow when triaging RoamSwitch's findings.

### 1.9.39 - 1.9.94 (summarized)

Everything in these releases, grouped by topic (Client and Server Edition unless marked). The full text of each entry is in the git history of this file.

- **Isolation (Air-Gap) reworked** (1.9.90, 1.9.91): an isolation caused by a high-confidence detection (a tampered canary, suspected ransomware, a critical eBPF detection) no longer releases itself on a timer. After a cap (1 hour by default) without a verified-cleared re-check it moves to a "degraded" mode that never re-opens on a timer, and it is released only by `roamswitch emergency-restore`, the GUI, the server's `roamswitch server ack`, or a verified-cleared re-check. Detections prone to false positives still release on the short timer. Connections that were already open no longer survive an isolation (the server keeps only the maintenance SSH and allowed IPs; the client's degraded mode allows loopback only). The ARP re-check sends a direct ARP request when the gateway has no neighbour entry (`arp_recheck_active_probe`), so ARP-triggered isolations stop getting stuck.
- **Process-execution record, forwarding and Server TUI** (1.9.90): a continuous record of which programs ran, with parents, hashes and containers, on the machine only (default 200 MB / 14 days, hash chain), and seven notify-only correlation rules; event forwarding (off by default: syslog, CEF, JSON Lines, HMAC-signed webhook); and a full-coverage TUI for the Server Edition (`roamswitch server tui`). Also `--json`/`--export`, and a notification when another program opens credential files (off by default).
- **Containers and network** (1.9.43, 1.9.44, 1.9.90): the Docker firewall-bypass guard works with Docker's native nftables backend and IPv6 and heals itself within a minute; Container Exec Guard (Server) marks each container's rootfs with fanotify's notify-only `FAN_OPEN_EXEC` and captures even a self-deleting attacker binary; the Egress Guard covers container traffic; per-process CPU-saturation detection; a wider FIM scope (`authorized_keys`, `ld.so.preload`, new files in watched directories).
- **Investigation agent** (Server, 1.9.45 to 1.9.56): automated first-pass triage of eBPF, FIM and lockfile detections (false-positive likelihood, reasons, next commands, Markdown report) and an optional, off-by-default handoff to an agentic CLI (Claude Code, agy, Codex CLI, OpenCode, custom), skipped right before a host isolation; fixes for it never working under root, for the sudo wrapping, and for the recursion where an agent's own investigation looked like a new incident.
- **Security fixes** (1.9.84 to 1.9.90): a local user could send a forged critical event to Falco's socket and trigger a full Air-Gap (the socket is now mode 0600 with a peer-UID check); look-alike names such as `sshd-x` escaped the protected-process list; allowlist entries could be bypassed by renaming a process (entries can be bound to the real executable with `--exe`); Telegram and LINE tokens and webhook URLs were visible in the process list; the port-scan auto-block could be abused with a forged source address (it now refuses only new inbound connections, never blocks the gateway, DNS resolvers or the host's own addresses, and checks the SYNs' source MAC); a flood of forged SYNs could push scan records out of the log (200 per second limit first, and a notification when detection is saturated); a scan claiming the Sensor's address escaped the block (the Sensor's MAC is recorded at pairing); unknown-listening-port detection could be evaded with a system daemon's name (`/tmp/sshd`) or by an interpreter script from a temporary directory; the dev-server block rules were briefly lifted while being re-applied; log-frequency detection went blind after one large burst; the root daemon created root-owned directories under `~/.local`.
- **Port scans, listeners and vulnerability checks** (1.9.39 to 1.9.94): stronger port-scan detection (memory bounded under a flood, a 24-hour window, IPv6 per /64), unknown-listening-port detection for non-wildcard binds and temporary, in-memory or deleted binaries, UDP listeners from interpreters, alerts that name the real program (`wsdd (python3)`); active checks for Elasticsearch, CouchDB, Jenkins, VNC, RDP (NLA) and SMB (SMBv1, signing); CSV export that explains safe and inconclusive results, scan IDs and locked logs; typosquat detection for npm packages (Pro); the kernel-CVE check no longer flags distro backports that only bump the ABI number; the nmap NSE scan is always on and the CVE maps update monthly.
- **RoamSwitch Sensor** (1.9.55 to 1.9.91): pairing moved from mDNS to a pairing code; an active audit can be requested from a Sensor and its result fetched later (MCP tool `get_sensor_audit_results`); TLS 1.3 with certificate pinning (`roamswitch sensor pair --fingerprint`, `sensor repin`; new pairings need Sensor 0.3.9 or later, existing plaintext pairings keep working with a warning); the setup wizard offers a preset when a Sensor runs on the same host; a failed pairing now says why (30 seconds of waiting, likely causes, a command for the Sensor host).
- **Network control review** (1.9.71 to 1.9.72, 1.9.85 to 1.9.87): firewall settings not re-applied right after a daemon restart, services stopped by shared-service control never restored, and a manual security-level change racing the daemon's patrol; ARP false positives triggering Air-Gap under VirtualBox NAT and in NAT environments; the Frag Gap mitigation (denying user namespaces) became opt-in (`auto_enable_userns_restriction`) because it broke browsers, Flatpak, Electron and rootless containers on the client.
- **Notifications, screens and languages** (1.9.40 to 1.9.94): every notification is in ten languages (FIM, lockfile, eBPF, kernel exploit, all Server alerts, the second-instance message, health-check lines), and the Server Edition's language is set with `language`; the notification history no longer freezes (bodies capped at 2,000 characters, newest 200 drawn); "suspected malware" notifications no longer repeat for a file you keep saving; screens split into tabs (package CVE scan, Ports & DevIsolator); the onboarding wizard defaults to standard protection instead of "open"; several GTK layout, CSV-header and translation fixes.
- **Packaging and updates** (1.9.75 to 1.9.88): the periodic nmap NSE database update and the CVE map updates were failing silently in systemd's sandbox or held back by a shared marker; RoamSwitch did not start at boot on some systems; the health check advised apt on Arch-based systems; an administrator password was requested every time Air-Gap was released; and the apt and rpm repositories held every past version until the publishing job failed, so they were cut to the latest version (1.10.5 keeps the latest three).

### 1.0.0 - 1.9.38 (initial release through the stable era, summarized)

- **Initial release (1.0.0)**: ported the macOS edition's zero-trust
  architecture to Linux (systemd + nftables). Followed by the core
  defense capabilities — VPN tunnel + killswitch (WireGuard/Tailscale),
  unknown-port auto-blocking, passive link protection, daily threat feed,
  BadUSB/USB storage authorization, autonomous ARP-spoofing detection
  (1.0.1 - 1.0.66).
- **Official launch of RoamSwitch Server Edition (1.1.0)**: Falco eBPF
  runtime threat detection & auto-isolation, Critical Path FIM, a 25-item
  server security health check, Webhook/PagerDuty alerts. Followed by
  event-driven FIM, Egress/C2 containment, Tetragon sensor support, and
  fine-grained `guard.yaml` policy configuration (1.1.1 - 1.3.2).
- **Package CVE Scan (1.5.0)**, **Log Audit template anomaly detection +
  automatic secret masking (1.6.0)**, **incident history for Air-Gap
  trigger guards exposed via MCP/CLI (1.7.0)**, **File Scan Guard &
  Docker risk detection (1.4.1 - 1.8.0)**.
- **Evil-Twin SSID warning, BadUSB keystroke-timing anomaly detection,
  Ransomware Canary blast-radius evidence (1.9.0 - 1.9.5)**; **notification
  history, ClickFix detection, and the log audit's background schedule
  added to the client edition (1.9.6 - 1.9.15)**.
- **Critical Path FIM extended to the client edition, Resource Exhaustion
  / Process Anomaly Guard (Server Edition), a root-cause fix for Log
  Audit's masking regex, and fixes for several Server Edition
  success-without-verification bugs (1.9.16 - 1.9.26)**.
- **Four npm-install supply-chain-risk features (Lockfile FIM,
  install-script inventory, npm signature verification, bubblewrap
  sandboxing), typosquat detection, crypto-wallet seed-phrase leak
  detection, and a critical fix for the Default-Deny firewall blocking
  100% of Docker containers' outbound traffic (1.9.27 - 1.9.38)**.

---

## RoamSwitch for Mac

## 1.10.5

- **Changed: the license signing key was replaced, and the app accepts the old and the new public key.** The private half of the previous key was lost with the license backend's environment. Licenses activated before keep verifying (the earlier key is still accepted); new activations are signed with the new key, so **an older version of the app cannot activate a new license: upgrade to this version first**.
- **Fixed: a crafted Mach-O file could stop the root helper.** When you pin a Homebrew tool (WireGuard, Tailscale), the helper reads the tool's Mach-O header; a 64-bit fat header whose slice offset is beyond the range of `Int` made the conversion trap and the helper exit. Found by a new test that feeds the root-side parsers broken and random input (Mach-O, WireGuard configuration, ARP table, addresses, the frames of the parse worker; about 80,000 inputs with a fixed seed). It could only stop the helper, not run code.
- **Added: the root helper checks its own sandbox at every start and says so when it is missing or no longer refuses what it must.** The sandbox is a deny list, so a change in macOS could make it stop denying while the helper carried on without telling anyone. The helper now tries four things the sandbox must refuse (writing to `/Library/LaunchDaemons`, `/etc/pam.d` and `/etc/sudoers.d`, and running a program from a place users can write) and three things it must allow (`networksetup`, `arp`, writing in its own state folder), writes the result to `/Library/Application Support/RoamSwitch/sandbox_selftest.json`, and the app notifies once per distinct problem (10 languages). Checked on a real Mac (macOS 27.0): the sandbox was entered, all four refusals held and all three allowed operations worked.
- **Fixed: an isolation by an ARP spoof is now lifted automatically once the cause is verified gone.** Checked on a real Mac over Wi-Fi: the isolation degrades at the hard cap (default 3600 seconds; 300 seconds in the test) and the Wi-Fi radio, which the isolation turns off, comes back; the gateway's entry is refilled with the real address, and after three consecutive readings over 60 seconds the helper lifts it (8 minutes 31 seconds from isolation to release with the 300-second cap). **Changed (as in the Linux edition, checked on a real Mac over Wi-Fi with the radio left on and a 300-second cap: cleared after 3 minutes, lifted at the 5-minute re-check, 5 minutes 13 seconds from isolation to release, no degraded mode): from 10 minutes after the full cut, a high-confidence isolation is re-checked and lifted as soon as the cause is verified gone, without waiting for the hard cap** (only the cap moves it to degraded); before this it was never lifted before the cap (default 3600 seconds). The degraded notice now says that it is lifted automatically once the cause is verified gone (10 languages), and the app's Japanese wording says アップグレード (not アップデート) for its own upgrades. While the gateway's entry is missing the helper also sends one ARP request (link level, not IP, so the isolation does not drop it), at most once every 10 seconds; the frame is sent through BPF and was checked on a real Mac outside an isolation and during one (the gateway's entry vanished by itself after about 2 minutes of isolation with the radio left on; the request was sent, and the real address was back about 90 seconds later, though the log cannot tell whether the reply or something else refilled it). With the radio off there is nothing to send on. The check and its log lines are public (`category: arp-clearance`).
- **Changed: after a Homebrew upgrade of WireGuard or Tailscale, you are told once per release** (a notification with a "Confirm and pin" button that opens the confirmation, showing the pinned and the installed version). Pinning is still never done without your approval. The check runs at launch and every 30 minutes (10 languages).
- **Fixed: the uninstaller could undo itself and crash before showing its result.** Unregistering the helper drops the XPC connection, and the app answered by registering the helper again; once the app was in the Trash, `SMAppService.register()` crashed (SIGSEGV in ServiceManagement) before the result window. Nothing registers a service while the uninstall runs. **Fixed: with "also delete settings, history and license" ticked, the exit hook wrote the watchdog state file and its folder back.** The uninstaller now stops those writes and removes the user data once more after the result window. **Added: the uninstaller ends the running copies of the bundled MCP server.** An editor that started it from the app's path kept it running after the app was trashed, and System Settings kept showing RoamSwitch as running in the background. Only processes whose executable is this app's own server are ended. **Changed: the result window, the Help & Guide and the FAQ say that the system extension is removed at the next restart even when no approval is asked for**, as happened on a real Mac once the app was deleted. **Added: Help & Guide entries** for the isolation status and release guide, recovery and uninstall, the port-scan source-MAC check, the pinned VPN tools and the confirmation window (10 languages). Found and checked by running the uninstaller on a real Mac three times.
- **Added: recovery and uninstall.** A separate "Recovery and uninstall" menu puts the network back (isolation, VPN and Tailscale kill switches, port-scan blocks, the gateway ARP pin, DNS, the link guard's hosts entries, stopped services) and shows the current and trusted gateway MAC and whether the cause of an isolation is verified gone; without that verification it needs an acknowledgement. The uninstaller does the same first, then unregisters the helper's services, the system extension and the login item, removes the decoys and the shell aliases, and moves the app to the Trash.
- **Fixed (security): releasing an isolation adopted the gateway that was present as the new trusted one, and the gateway ARP pin froze a forged MAC permanently.** Found by sending a forged ARP from another machine: after the release, traffic did not come back and the connection stayed unstable until a restart.
- **Added: the port-scan auto-block checks the source MAC, like Linux.** The SYN frames are captured with `tcpdump -e`, the source MAC is kept briefly, and a block is refused when it does not match the neighbour entry of the claimed address. Tested against real `tcpdump -e` output from macOS.
- **Changed (security): talking to a Sensor no longer happens in the root helper.** The TLS handshake and the parsing of the reply, which come from another machine on the LAN, run in a short-lived child process that drops to `nobody` and is confined by a sandbox: it may open one outbound TCP connection to the Sensor control port and nothing else (no files, no other ports, no fork or exec). The helper keeps the signing key and the trust store, and receives the reply as one re-encoded JSON object.
- **Changed (security): the helper only serves the genuine app.** Besides the Team ID, it requires the hardened runtime, no entitlement that allows code injection, and build 122 or later. An older build or a re-signed copy cannot use it.
- **Fixed (security): the snapshot recovery writes into your folder with your own permissions.** If the destination was swapped for a link after the checks, root could have written outside it; now the kernel refuses. The link-filter feed is read without following links and only if it belongs to the user.
- **Fixed: a development-server port outside 1 to 65535, or an endless block time, could be persisted and make the firewall rules fail to rebuild.** They are limited to 1 to 65535 and 1 second to 24 hours.
- **Changed: the pinned VPN tools folder is refused if it holds a file the manifest does not list.**
- **Added to the release process: the built app is checked with Apple's tools (`codesign`, `spctl`, hardened runtime, entitlements, client build) and a failing check stops the release.**
- **Changed (security): the output of `eslogger` (the command line of every process that starts) and of `tcpdump` (packets from the LAN) is parsed outside the root helper**, by the same kind of `nobody`, sandboxed worker. The workers are started by a small spawner that also runs as `nobody`, so that they can enter a sandbox stricter than the helper's own.
- **Changed (security): the helper runs inside a sandbox from start-up, inherited by the programs it starts.** The kernel refuses running a program from a place a user or a download can write to, and writing LaunchDaemons, system programs, sudoers, PAM, sshd or the user database. Nothing the helper's operations use is denied.
- **Fixed: port scans over IPv6 were never detected.** The line parser cut an IPv6 address at its own colons.
- **Added: a notification, in 10 languages, when the VPN cannot connect because its tools are not pinned yet** (before, it was only in the log).

## 1.10.4

- **Changed (Mac): the Sensor control connection never falls back to plaintext.** A Sensor paired before TLS support is refused until its certificate fingerprint is pinned.
- **Added (Mac): while an isolation is active the menu bar shows whether it is full or degraded and what caused it.**
- **Changed (Mac, security): the root helper no longer runs Homebrew's VPN tools directly.** Anything running as your user can rewrite `/opt/homebrew`, so running `wg-quick`, `wg`, `wireguard-go`, bash and the Tailscale CLI from there as root handed that user a path to root. You now pin them once (after a confirmation): they are copied, with the libraries they load, to a root-only folder with their SHA-256 hashes recorded, verified before every run, and only those copies are executed. A connection is refused until the tools are pinned, and the menu asks you to pin them again after a Homebrew upgrade (10 languages).
- **Added (Mac): a window that explains the isolation state and how to release it** (menu: "Isolation state and how to release it…"): full or degraded, the cause, what to check for that cause before releasing, and a release button that works without Pro (10 languages).
- **Fixed (security): the helper (root) now enforces a floor on which processes it will signal.** `terminateProcess` refuses the helper itself, OS daemons under `/System/`, `/usr/libexec/`, `/usr/sbin/` and `/sbin/`, and RoamSwitch's own binaries. Ordinary tools such as `/bin/bash` and `/usr/bin/curl` can still be stopped.
- **Fixed (security): `setSecureDNSServers` accepted any string as a DNS server.** Only IPv4/IPv6 literals are accepted now.
- **Fixed (security): the WireGuard import used a substring blacklist (`postup`, `table`, ...).** It is now an allowlist of plain tunnel keys, so a legitimate config that merely mentions "table" in a comment is no longer refused and unknown directives are always refused.
- **Added: a menu-bar hint on a network that is not trusted while neither the VPN auto-connect nor the ARP/NDP lock is on.**

## 1.10.3

- **Fixed: the credential honeytokens (added in 1.10.0) could break real tools and trigger false alarms
  on themselves.** The ssh decoy moved from the default `~/.ssh/id_rsa` to `id_rsa_backup`, a name ssh does
  not look for by default (with mode 0600 a normal ssh run raised a false alarm, and with 0644 it printed a
  permissions warning). The AWS decoy is now a `[backup-admin]` profile instead of `[default]`, the Docker
  decoy points at a non-existent internal registry instead of Docker Hub, and decoys are planted with mode
  0600. Decoys planted by an older version are migrated to the new content (the old `id_rsa` decoy is
  removed; real files are never touched).
- **Fixed: honeytoken self-alarms.** After monitoring was re-enabled, the app's own read could be judged
  suspicious against a stale baseline time, so the baseline is now cleared on stop and re-taken on start.
  An access from RoamSwitch itself, or from the ssh tools in `/usr/bin/` (for the ssh decoy only), is no
  longer treated as suspicious. If the accessing executable's path can't be determined, it still warns as
  before.
- **Fixed: the secret-leak audit (SecretLeakScanning) read the honeytoken decoy files and triggered the
  very detection it sits beside.** It now skips only files whose path and byte size match a decoy (a real
  file with the same name is still audited).
- **Improved: identical threat notifications are no longer repeated for 10 minutes.** The sound and banner
  for a threat notification with the same content are suppressed for 10 minutes (a changed body notifies
  as usual; the notification history still records every occurrence, and isolation-state notices are
  exempt). Same design as the Linux edition's notification-flood fix.

## 1.10.2

- **Fixed: reachability checking for a Tailscale exit node (`tailscale ping`) misjudged an exit
  node that was working fine over a DERP relay as "unreachable," disconnecting even a legitimate
  manual connection.** `tailscale ping` returns a non-zero exit code whenever a direct (P2P)
  connection isn't established, even if a relayed pong actually came back. Since the check relied
  on the exit code alone, this wrongly tore down working exit-node connections on networks that
  could only reach the node via a DERP relay (e.g. away from home). Confirmed on a real device that
  a real pong still produced a false result, and fixed it to also check stdout for "pong from".
- **Fixed: once a Tailscale exit-node connection attempt on any network backed out due to a failure
  (unreachable / route unconfirmed), auto-connect stopped working on every subsequent network, not
  just the one where it failed.** The suppression flag set on backout was never reset except on app
  relaunch, so it carried over across unrelated network changes. It's now reset whenever a genuine
  network change is detected (an explicit manual "Connect now" intent is left untouched).
- **Fixed: browser credential-access monitoring kept a history record even when the accessing
  process couldn't be identified (which happens on nearly every browser quit and has nothing to do
  with an actual threat), even after the notification itself was already suppressed for this case.**
  Simplified so that an unattributed access does nothing at all — no notification, no record (a real
  attacking process is normally caught while it's actually running, so this doesn't reduce coverage).
- **Changed: aligned the VPN auto-connect trigger level with the Linux edition.** Auto-connect now
  fires only at "Maximum lockdown," not "Standard protection (balanced)" (both WireGuard and
  Tailscale). An explicit manual connect via "Connect now" still stays up regardless of level.
- **i18n: added the 9 missing language translations for the Tailscale notification strings
  (route-not-protected / network-recovery-failed) introduced in the previous update.**

## 1.10.1

- **Fixed: a program that rebinds to a random ephemeral UDP port through an interpreter (like
  `wsdd`) was treated as a different port on every restart, repeating the notification endlessly
  (ported from the Linux edition's fix, same design).** Introduced a fingerprint that excludes the
  port (executable path + script arguments); only the first occurrence raises an alert, and further
  occurrences with the same fingerprint are recorded to the notification history only.
- **Fixed: general-purpose entropy-based ransomware detection (added in 1.10.0) could miss a
  genuinely malicious process when a benign background process (such as Spotlight's mdworker) was
  also present.** Whether a process is safe is now decided while candidate processes are being
  collected, so if even one unsafe process is found, it is always the one flagged — even alongside
  benign processes in the same snapshot.
- **Fixed: credential honeytokens (added in 1.10.0) silently stopped monitoring after an app
  restart that happened after the honeytoken files had already been created.** On restart, a file
  is now resumed for monitoring whenever it's recognized as a honeytoken this app planted earlier.
- **Fixed: the process-execution recorder's DYLD_INSERT_LIBRARIES detection (added in 1.10.0)
  false-positived on every Xcode debug run.** The check now looks at whether the injected library
  itself lives somewhere trustworthy (system locations, inside Xcode.app), rather than at the
  signature of the binary being executed.
- **Fixed: Link Guard's brand-impersonation (homograph) detection had never worked at all for two
  brands, Apple and PayPal.** A character-normalization bug always remapped the letter "l" to
  another character, which made matching those two brand names structurally impossible. Also fixed
  a gap where swapping in a single look-alike character (`app1e.com`) went undetected, and added
  detection for a brand name combined with a word like "security" or "support" in a newly
  registered domain (`microsoft-security-alert.com`) — especially useful for domains too new for
  threat feeds to have caught yet.
- **Fixed: Web/mail download protection (instant scanning of files downloaded via a browser or mail
  app) had never actually run, due to an internal issue right at startup.** The timing of a one-time
  folder-access notice shown on first launch could crash the app during its own startup sequence.
  This — not a detection-accuracy problem — is why things like the EICAR test detection for this
  feature didn't fire.
- **Fixed: if the gateway MAC address lookup happened to fail right at launch, it stayed stuck as
  unresolved from then on, leaving "Register current network as trusted" unresponsive.** The retry
  now also covers that first, right-at-launch failure, and keeps self-healing in the background
  until it resolves.
- **Fixed: the Tailscale Exit Node feature only trusted tailscaled's own self-reported "connected"
  state, without verifying traffic was actually flowing through the exit node.** `tailscaled` itself
  has a known macOS bug where the OS's default route can stay on the physical network after an exit
  node is set, which meant RoamSwitch could show "protected" while nothing was actually protected — a
  silent failure. The real OS default route is now independently verified; the exit node is
  disconnected and a notification shown if it's never established. Also fixed a case where backing
  out of a broken connection didn't stop auto-retry, causing the notification to repeat, and a case
  where the network-recovery step after disconnecting (a DHCP renew) reported success purely from a
  command's exit code without confirming a real address had actually been obtained — left unfixed,
  this could leave the Mac with no internet connectivity at all.
- **Fixed: browser credential-store monitoring falsely flagged legitimate access by Chrome/Brave-family
  helper processes (renderer, GPU, etc.) as suspicious.** It read process names from `lsof`'s
  human-readable output, which truncates long names (e.g. "Google Chrome Helper (Renderer)"),
  breaking the allowlist match. Switched to `lsof`'s untruncated machine-readable output.

## 1.10.0

- **Added: general-purpose entropy-based ransomware detection.** Alongside decoy-file tampering, it
  analyzes the entropy (randomness) of writes to the Documents, Desktop, Downloads, and Pictures
  folders, and detects when a large number of apparently-encrypted files are written in a short
  time — catching encryption even in places with no decoy file. On detection, it triggers the same
  emergency network block as the existing ransomware detection (Pro, on by default).
- **Added: forensic evidence bundle.** When an emergency network block fires, it automatically saves
  a snapshot of the process list, network connections, and recently changed files, with SHA-256
  hashes.
- **Added: credential honeytokens.** Plants decoy credential files at `~/.aws/credentials`,
  `~/.ssh/id_rsa`, and `~/.docker/config.json`, and notifies you if they're accessed (Pro, on by
  default; never overwrites an existing real file).
- **Added: browser credential-access watch.** Notifies you when a process other than the browser
  itself accesses saved passwords/cookies in Chrome, Firefox, and similar browsers (off by default
  even within Pro; opt in from Settings).
- **Added: two more detection rules for the process-execution recorder.** Now detects python3, perl,
  ruby, php, or pwsh inline one-liners where a base64/eval decode and a `curl`/`wget`/etc. call
  appear on the same line, and dylib injection via the `DYLD_INSERT_LIBRARIES` environment variable
  (Pro).
- **Added: you can now check how long it's been since each vulnerability scan probe last ran.** For
  each item in the active vulnerability scan, the last recorded result and the days elapsed since
  are available from the MCP tools.
- **Added: NIST CSF 2.0 / CIS Controls v8 mappings for the health-check (18-item) diagnostics.**
  Useful for audit compliance and business use explanations.
- **Added: four AI-agent triage skill documents to roamswitch-mcp (the MCP server).**

## 1.9.6 - 1.9.54 (summarized)

Everything in these releases, grouped by topic. The full text of each entry is in the git history of this file.

- **Isolation (Air-Gap) reworked** (1.9.52, 1.9.23): what triggered an isolation decides how it ends. A tampered ransomware decoy, a confirmed XProtect detection and a manual isolation chosen from an ARP warning are "high confidence"; the rest (ClickFix, port anomalies, and so on) are "low confidence". Low confidence releases by itself after 10 minutes. High confidence does not: full isolation continues up to a limit (1 hour by default), then releases if the cause is confirmed gone, and otherwise moves to a "degraded mode" that keeps new connections blocked and never opens by time. Connections already open are cut when the isolation starts, and the state survives a helper restart. The Wi-Fi radio turned off by an isolation now comes back after an app crash or a restart (an independent watchdog, 1.9.23). (In 1.9.52 an isolation caused by ARP spoofing was not released automatically; 1.10.5 changed that.)
- **Ransomware** (1.9.50, 1.9.51): "Ransomware Recovery" (Pro) takes APFS local snapshots every 6 hours by default (off, 1, 3, 6, 12 or 24 hours), takes one at detection time, and pauses pruning for up to 7 days so the last generation before the encryption stays; recovery is manual, file by file, into `~/RoamSwitch-Recovered/`, never overwriting current files (needs Full Disk Access for the helper). The read-only MCP tool `get_ransomware_recovery_snapshots` lists the snapshots. The time from a decoy being tampered with to the emergency cutoff went from minutes to about 2 seconds (a code-signature check ran for every line of the open-files list).
- **Process execution recorder** (1.9.52, Pro): records process starts on this Mac only, with macOS's own `eslogger` (off by default, needs Full Disk Access), in a tamper-evident log; nothing is blocked. Seven behaviours notify (a browser, Office or mail app starting a shell; an unsigned binary run from a temp folder or with the quarantine flag; a download piped into a shell; `osascript` with base64 or eval; running a file right after its quarantine flag is removed; an unsigned binary started from a fresh launch agent; a non-Apple parent reading a keychain secret). Banners only for high severity and at most once per kind every 10 minutes; "Allow this program" allows one keychain item. MCP tools `search_exec_events` and `get_process_tree`.
- **Port scans and unknown ports** (1.9.32, 1.9.44 to 1.9.49, 1.9.54): automatic detection and 10-minute blocking of nmap/masscan-style scans (Pro); the block cannot be abused with a forged SYN claiming the gateway's address (only new inbound TCP is refused, and the gateway, DNS resolvers and the Mac's own addresses are exempt), detection no longer stops after start-up (`pflog0`), and a flood of forged SYNs can no longer fill pf's state table. Listeners of root programs are now seen through the privileged helper and read through libproc (about 2.4 ms against 16 ms for `lsof`, every 2 seconds); a signed executable swapped for an unsigned one with the modification time restored is noticed; UDP listeners from interpreters or unsigned programs are reported; alerts name the real program behind `python3` or `node`.
- **Active vulnerability checks and logs** (1.9.44, 1.9.53): unauthenticated Elasticsearch, CouchDB, Jenkins and VNC, SMBv1 and SMB signing were added; the CSV export explains safe and inconclusive results correctly, and every scan has an ID and a locked log.
- **RoamSwitch Sensor** (1.9.32 to 1.9.37, 1.9.52): mutual pairing moved from mDNS to a pairing code; an active audit can be requested from a Sensor and its result fetched later (MCP tool `get_sensor_audit_results`); with a pinned certificate fingerprint everything runs over TLS with Sensor 0.3.9 or later; a crash of the privileged helper on every successful pairing was fixed.
- **Supply chain and secrets** (1.9.27 to 1.9.30): dependency-lockfile tamper monitoring, install-script inventory, npm signature and provenance checks, the `roamswitch-npm` wrapper that runs installs in a network-denied sandbox, typosquat detection by edit distance, and detection of leaked crypto-wallet seed phrases and private keys (checksum-verified). Pro.
- **Log audit and notifications** (1.9.6 to 1.9.26): notification history for the past 7 days; Automatic Log Audit (Pro) scanning hourly for new patterns and frequency spikes, with each template compared against its own history; ClickFix-style commands on the clipboard (including the Script Editor pivot). Many false positives were removed (CoreAudio, loginwindow, `PersistentAppsSupport`/`BTMManager`, `CFPasteboardRef`, pointer addresses), notifications explain in plain language whether action is needed, EICAR test hits no longer raise a notification, and the log-audit window's cards became clickable.
- **Critical Path FIM** (1.9.16, Pro): SHA-256 baseline monitoring of files such as `/etc/sudoers`, SSH configuration, `/etc/hosts` and root's `authorized_keys`.
- **Reports that assumed success** (1.9.19): four items that reported success without confirming anything (automatic dev-server port blocking, malware-quarantine moves, the "macOS Accessory Connection Protection" check that was hard-coded to pass, Critical Path FIM helper-connection failures) now show the real outcome.
- **Updates and languages** (1.9.26, 1.9.34 to 1.9.43): the privileged helper is reliably restarted on update; warning bursts and a false "/etc/hosts tampered" warning right after an update were fixed; update prompts bring the app to the front; shared-service stop/restore checked `launchctl` exit codes; Link Guard's homograph detection and the ransomware guard's MITRE ATT&CK ID compared translated strings instead of a language-independent value, which broke them in most languages other than Japanese, English and French. CSV headers, the package-CVE tabs and several texts were fixed in all 10 languages.

## 1.0.0 - 1.9.5 (initial release through the stable era, summarized)

- **Initial release (1.0.0 - 1.3.0)**: autonomous network detection by
  gateway MAC, automatic firewall/sharing-service switching, port anomaly
  blocking, ARP spoof auto-containment, and foundational MCP integration.
- **Local AI/LLM server protection, clipboard secret protection, and the
  MCP server open-sourced (1.4.0 - 1.5.9)**.
- **VPN tunnel + killswitch (WireGuard), proactive gateway ARP/NDP
  pinning, BadUSB/USB storage authorization guards, passive Link Guard,
  Canary decoy-file persistence (1.6.0 - 1.7.6)**.
- **Topmost emergency alert overlays, one-click health-audit remediation,
  dual VPN backend support (WireGuard/Tailscale) (1.8.0 - 1.8.3)**.
- **Static-signature download detection, ClickFix protection, and Docker
  risk detection guards added; automatic Air-Gap isolation tied to Apple
  XProtect; the secret-leak auditor gained whole-folder scanning
  (1.8.4 - 1.8.9)**.
- **Active Vulnerability Scan and Package CVE Scan ported from the Linux
  edition, an Evil-Twin SSID warning, BadUSB keystroke-timing anomaly
  detection, and gaps in the MCP server closed (1.9.0 - 1.9.5)**.
