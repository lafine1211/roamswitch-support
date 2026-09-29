# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (1.x, a separate series) are versioned
independently. Older releases are summarized in ranges.

---

## PersonalSOC

### 0.1.0

- **New: "PersonalSOC", a personal security operations center**. It gathers this device's logs and defense status, read-only, into a report. It ships with RoamSwitch for Mac (DMG) and RoamSwitch for Linux (deb, rpm, tarball, AUR) as a separate app with its own icon. Open source under Apache-2.0.
- Findings, sources and IOCs are shown in a report with charts. The UI is available in 10 languages and follows the OS language automatically.
- Pressing "Check status" has your chosen LLM CLI (opencode, claude, codex, agy) investigate autonomously with read-only tools and write an audit report. LLM integration is optional and off by default. When on, the gathered information may be sent externally through the CLI you chose.
- RoamSwitch's own zero-telemetry is unaffected. PersonalSOC itself has no network permission.

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

### 0.3.12

- **Ran a false-positive/alert-fatigue audit and fixed 6 findings.** The detectors whose volume can spike (outbound fan-out, outbound flood, malicious-destination contact, IoT device behaviour) sent an empty destination identifier, so when a *different* device tripped the same kind of detection it could be silently suppressed as if it were still in cooldown (notifications now carry the correct MAC address). Those detectors' severity, and the DNS-tunneling detector's severity, are now downgraded for a device that's already registered in the device inventory (with an operator note). ARP event webhook/syslog notifications now carry the same context (vendor, registration status, history) the TUI/CLI already showed.

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

### 0.2.1 - 0.3.9

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
- **Control API TLS support, replay protection, and a fuller TUI** (0.3.9): the control API now speaks TLS 1.3 with certificate pinning (`control.tls`, default `optional`). Signed requests carry a timestamp (±300s) and a one-time value, with pairing brute force locked out per source and globally. The TUI now covers every function of the CLI and daemon (config editing, TLS management, manual pairing, event views, 10 languages). Added a bind-address setting, a switch to stop the CVE-map fetch, and a distinction between unpaired and unknown devices.

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

### 1.10.13

- **Added: a Security Activity Log tab.** It lets you search and filter across everything RoamSwitch has detected so far (ARP, FIM, port anomalies, recorded process execution, notification history, and more), with a time-series bar chart whose bars you can click to narrow the list to that time window.
- **Ran a false-positive/alert-fatigue audit and fixed 44 findings in the desktop edition and 7 in the server edition.** Highlights: fixed lockfile monitoring's "unreadable" verdict being treated at the same severity as tampering (a transient read race could be mistaken for tampering). Link protection now states which signal triggered it (a known threat-feed match, a TLS fingerprint match, or homograph similarity). Isolation-release checks now distinguish "the threat is still active" from "we simply couldn't complete a check" in what's shown. The gateway-MAC-change warning (which can also fire on an ordinary router reboot) now always includes the old MAC, the new MAC, and the target IP. Exec detection (the curl|sh pattern and others) now includes the download URL, the executed command, the parent process, and more. On the server edition, the risky-Docker-container notification now has deduplication, and the crash-loop/CPU-saturation headline wording softens when there's no corroborating evidence.

### 1.10.12

- **Fixed: right after resuming from suspend (closing the laptop lid), a false "protection is not responding" alert could appear.** The guard liveness check uses the wall clock, which keeps advancing during suspend, so the first monitoring cycle after resume treated the last heartbeat as missing for the whole suspend time. A gap far beyond the monitor loop's own call interval (normally 3 seconds) is now treated as a resume from suspend: every guard's timestamp is reset before normal checks continue.
- **Fixed: the order of items in the active-verification status changed from run to run when several items were checked on the same day.** The age was truncated to whole days, so every item from the same day tied. It now compares second-level timestamps.
- **Improved: the active-verification status now explains what active verification does** (GUI in 10 languages, CLI in Japanese and English). It sends real requests to see whether something is actually exploitable, not merely whether a port is open; "unverified / undeterminable" does not mean "safe"; and this screen itself does not run a scan.
- **Fixed: in port-anomaly detection, the record that suppresses duplicate notifications for UDP listeners (`udp_notified_fingerprints`) grew without limit.** It was also persisted in the state file (`/var/lib/roamswitch/port_guard.json`), so it kept growing for the whole life of the daemon. It is now trimmed to a fixed size, newest first, the same way the neighbouring incident list (at most 50) already was. The growth is slow, and it is unrelated to the helper's resource leak found on the Mac.
- **Fixed: in the popular-npm-packages feed, the manifest URL did not match the published file name.** Following a path that does not exist returned the home page, which the client showed as a false SHA-256 mismatch warning (possible tampering). It now points at the file name that is really published, verified by downloading it from production.

### 1.10.11

- **Added: detects when a local ransomware-recovery snapshot (btrfs/LVM) is deleted or thinned by anything other than RoamSwitch itself or a known third-party snapshot manager (snapper, timeshift).** The same technique as Windows's `vssadmin delete shadows` (MITRE ATT&CK T1490). Verified against a real captured exec pipeline, not just hand-built test fixtures.
- **Fixed: the notification for the detection above showed the previous rule's label instead of its own.** A missing entry in the label-mapping table when a new rule is added; fixed in all 10 languages.
- **Improved: the ransomware recovery screen's description now states the real scope (each login user's home directory only)** instead of the vaguer "data on btrfs/LVM", which read as covering more than it actually protects.
- **Fixed: the tray menu's language switcher was missing Italian and Portuguese.** The main window's language setting and the i18n catalog itself already supported all 10 languages, but the tray menu's hand-written item list was never updated with these two, so they weren't selectable there.

### 1.10.0 - 1.10.10 (summarized)

Everything in these releases, grouped by topic (Client and Server Edition unless marked). The full text of each entry is in the git history of this file.

- **Recovery UI file picker, OS-integrated-build differentiation, external command timeouts** (1.10.10): the "Recovery & Uninstall" restore path became a real file picker instead of free text (10 languages). On RoamSwitch OS (the OS-integrated build), `roamswitch uninstall` and its button/tray item are hidden (the app is part of the OS), and upgrade detection now also covers the OS-integrated package name. External commands the resident daemon calls now have a time limit (fixes bluetoothctl jamming every lock-requiring IPC, including port blocking, for 1h41m when bluetoothd wasn't running). The AUR publish job is now skipped by default (AUR has stopped new registrations).

- **New detection and recording** (1.10.0): DNS tunneling and exfiltration detection (it looks only at DNS queries this host sends itself and never blocks name resolution; Server Edition: `dns_tunnel_detect_enabled`). A forensic evidence bundle saved when containment fires on a ransomware canary or a critical eBPF detection (process list, recent file changes, a SHA-256 manifest). Decoy files (honeytokens) placed at `.aws/credentials`, `.ssh/id_rsa`, `.docker/config.json` and similar. The age of the last active vulnerability check (`roamswitch vuln-status`). A NIST CSF 2.0 and CIS Controls v8 mapping for each health check. Four triage skills for roamswitch-mcp.
- **Honeytoken and evidence-bundle fixes** (1.10.4, 1.10.5): so the decoys do not break real tools, the AWS decoy no longer uses `[default]` and the Docker decoy points at a registry name that does not exist. Permissions are 0600, and access by OpenSSH clients and by RoamSwitch itself is recognized by executable path and not reported. The 1.10.0 to 1.10.4 packages did not contain `roamswitch-honeytokens` or `roamswitch-incident-capture`, so the decoys and the evidence bundle never ran. 1.10.5 ships both in the client and server packages, and CI now fails a build that lacks them. A new health check, "helper programs installed" (27 client items, 33 server items), was added. Also fixed: the systemd sandbox blocked decoy creation (Server), and FIM reported RoamSwitch's own decoy as a new file.
- **Isolation (Air-Gap) and host defense** (Server, 1.10.5): host isolation cut off the management SSH it was meant to keep (the isolation output chain priority moved from -300 to -100). Port 22 was opened even with `preserve_ssh_on_isolation=false`. For a high-confidence isolation, the operator's acknowledgement (`roamswitch server ack`) was ignored once the cause looked gone. Evidence is now collected before the cut on more paths: host-wide Air-Gap, escalation of a per-process isolation, and canary tampering. At startup it warns when the maintenance SSH port stays open to every address during isolation, and when egress blocking is on but the feed is empty. New settings: `honeytokens_enabled`, and `harden_userns_enabled` (a permanent ban on unprivileged user namespaces, which breaks rootless containers, so it can be turned off).
- **Security fixes** (1.10.4 to 1.10.6): IPC calls that change state are limited to root and to users with a local login session (1.10.4). The root daemon read `~/.config/roamswitch/config.json` under `/home/*` without checking the owner and followed symlinks when writing; settings that stop a guard are now accepted only from root or from a UID with a local login session (1.10.5). The daemon now runs inside a systemd sandbox (`systemd-analyze security` went from 9.3 to 5.4, 1.10.6). `rustls` was updated to 0.23.45 (RUSTSEC-2026-0285, 1.10.6). An investigation agent that runs as root with permission checks skipped is refused (Server, 1.10.5). External commands are started by absolute path (1.10.4).
- **Malware detection (ClamAV, fanotify, USB)** (1.10.0, 1.10.3, 1.10.4, 1.10.6): a fallback had hidden failures of `clamdscan --fdpass`, and a USB disk scan treated exit code 2 (the scan failed) as malware and ran `umount -f`; both are fixed, and a self-test of the detection path with EICAR was added (26 client items, 32 server items). fanotify now blocks only on exec (`FAN_OPEN_EXEC_PERM`) and only notifies on `open`. The BadUSB guard no longer releases an unapproved keyboard after the 3-minute approval wait. The daily update could not refresh ClamAV signatures because of `NoNewPrivileges=yes` (1.10.6). Also fixed: `clamdscan`'s own file opens feeding back into notifications and pinning the CPU (1.10.0), and YARA false positives on development build output (1.10.3).
- **Network, DNS, Docker, Link Guard** (1.10.1 to 1.10.4): DNS enforcement ran `resolvectl` every 3 seconds and kept flushing the DNS cache; it now runs only when the state changes. The Docker protection (`DOCKER-USER`) repairs itself every 60 seconds. Link Guard waits for packets with `poll(2)`, uses a queue length of 4096 and reassembles the ClientHello from TCP sequence numbers; block mode has an option to block UDP/443 (QUIC), `linkGuard.blockQuic`, off by default. Fixed: DNS tunneling detection flagged `clamav.net` TXT answers (1.10.3); the unknown-exposed-port guard could permanently block the control port (50543) of a Sensor on the same host, depending on startup timing (Server, 1.10.2); and programs such as `wsdd` that rebind to a new ephemeral UDP port on every restart caused endless repeat notifications (1.10.1).
- **Notifications and health checks** (1.10.3, 1.10.4): a notification with the same title and body is kept out of the popup and the IPC queue for 10 minutes and only recorded in the history. Low-urgency notifications go to the history only. On Arch-based systems the "automatic security updates" check counts as not applicable (an unattended `pacman -Syu` on a rolling release can cause a partial upgrade). Removed the places that fell back to a hard-coded developer home path when `HOME` was unset. Fixed the advanced settings dropping unknown keys when saving.
- **Packages and tests** (1.10.5, 1.10.6): apt and rpm keep the latest 3 versions of each package (previously 1). The pentest suite was rerun on 2026-09-25 (Docker Desktop, Ubuntu 24.04 containers: 19 of 19 server items and 11 of 11 client items passed; the Frag Gap mitigation and SSH during isolation were also checked on a real VM). Tests now check that the Link Guard packet parsers do not panic on hostile input (1.10.6).
- **Licensing and GUI upgrades** (1.10.7): the license signing key was replaced; the app accepts both the old and the new public key, so licenses activated before keep verifying. Fixed three ways a GUI upgrade could go wrong: hanging on one unreachable mirror, reporting success when nothing changed, and not restarting the app (checked on apt, dnf, zypper and pacman).
- **Recovery and uninstall** (1.10.7): a new tab in the main window. `roamswitch emergency-restore` and the tray menu put isolation, firewall rules, the gateway pin, DNS and connection tracking back; `roamswitch uninstall` does that first and then removes the decoys and the files setup added. Both refuse without an explicit acknowledgement when the gateway is not the trusted one or the isolation's cause is not verified gone. Also fixed a low-resolution screen hiding the tray's submenus.
- **Ransomware: partial-encryption detection** (1.10.7): detects the technique used by LockBit-style families, where 16 of every 32 bytes are encrypted (94% of simulated files, 0.01% false positives on ordinary files). Three other patterns are still only counted in shadow mode.
- **Security fixes (continued)** (1.10.7): fixed a changed gateway MAC alone being read as a move to another network, a release adopting whatever gateway was present as the new trusted one, the isolation record being lost on every service restart, and the ransomware burst check exempting any process whose name matched the allowlist regardless of its actual executable (renaming a process was enough to slip past it). The Link Guard's packet parser no longer runs as root; it runs in a sandboxed, privilege-dropped child process.
- **Decoy-file false positive** (1.10.8): RoamSwitch's own processes could trigger a Critical false positive just by opening a decoy file. The path resolved for the same PID and start time within the last 10 seconds is now reused for allow-list checks.
- **Server investigation-agent reports** (1.10.8): the report and the "agent handoff failed" notification now carry the host name and IP address, so a fleet of servers can be told apart.
- **Port-block result and Wi-Fi detection** (1.10.9): blocking a port reported success even when it could not be applied to nftables, and the window did not look at the result; on failure it now shows the reason, separating "could not connect" from "could not apply". On systems that use iwd (RoamSwitch OS) the Wi-Fi security check always said "unknown", so the connected SSID and security type are now read from `iwctl station show`.
- **Checks, window and packages** (1.10.9): a dedicated message when a Validity fingerprint sensor on USB is not supported by the stock driver (10 languages). Main-window tabs that were cut off at 1280 pixels wide now scroll with arrows. Client dependencies now include `conntrack-tools` (Arch), `bluez` and `lsof`. The Server Edition's stopped-eBPF-guard alert no longer points at a command that does not exist; it now says `roamswitch status --server`.

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

## 1.10.12

- **Added: a Security Activity Log screen.** It lets you search and filter across everything RoamSwitch has detected so far (ransomware containment, ARP spoofing, port anomalies, ClickFix protection, recorded process execution, and more), with a time-series chart whose bars you can click to narrow the list to that time window (reachable from the menu bar).
- **Ran a false-positive/alert-fatigue audit and fixed 27 findings.** Highlights: the ransomware protection's emergency containment banner (decoy-file tampering, high-entropy write bursts) now names the affected file and the suspected process (previously this was captured internally but never shown). ClickFix protection now sends a notify-only alert instead of cutting the network when a command matches a known installer's pattern (e.g. sh.rustup.rs). The risky-Docker-container notification now has a 24-hour cooldown so the same container no longer re-notifies on every restart. Link protection now states which signal triggered it (a known threat-feed match, a TLS fingerprint match, or brand-impersonation similarity). The Pickle-format AI model file (.pt/.pkl/.ckpt, etc.) download warning now includes where the file came from, and its wording was softened. Many other notifications (ARP spoofing, port anomalies, USB detections) now include more of what's needed to judge them — the old/new MAC address, the executable's path, sample targeted ports, and more.

## 1.10.11

- **Fixed: the NDP pin of the gateway's IPv6 router never actually took effect.** Passing a link-local address (fe80::…) to `ndp -s` without its interface exits 0 but only creates an expired entry that is not pinned (confirmed on a real Mac running macOS 27). The old code looked only at the exit status and reported the pin as done. The pin is now made with the interface (`fe80::…%en0`) and checked afterwards for `permanent`; if it cannot be confirmed, it counts as a failure.
- **Fixed: the gateway ARP/NDP pin deleted and re-added the entry on every policy re-evaluation, even when it was already pinned.** The gateway's entry vanished for a moment each time. When the entry is already pinned to the same MAC, nothing is done.
- **Fixed: the code that collects the pin targets left the output pipe of each external command open and waited for the command to exit before reading its output.** That could grow the number of open file descriptors in the app itself, so the pipes are now closed after use and the output is read before waiting for the exit.

## 1.10.10

- **Fixed: the privileged helper showed "Helper not connected", and restarting, reinstalling or approving it again did not help.** Every time the helper ran an external command (arp, ndp, networksetup, launchctl and others) it left the output pipe open, so open file descriptors grew with each network change until the limit (256) was reached, after which every connection from the app was refused. Even when the helper was approved, the menu showed "⚠️ Approve the helper…". Pipes are now closed explicitly after use.
- **Fixed: even when the network had not changed, the firewall (block all and stealth mode) and DNS were rewritten about every 2 seconds.** Writing the settings makes macOS announce a network configuration change, and the app answered that by writing the settings again. A setting that already has the wanted value is no longer written.
- **Fixed: a large output from an external command could stall the helper.** It waited for the command to exit before reading its output, so once the pipe was full the command could not write and never finished. It now reads the output first and then waits for the exit.
- **Fixed: the "Critical Path FIM" could report `/etc/hosts` or `/etc/ssh/sshd_config` as "deleted" when another process merely made them unreadable for a moment.** A file that really does not exist is judged immediately; only a file that exists but cannot be read is retried a few times at short intervals.
- **Fixed: the order of items in the "Active Vulnerability Verification" status changed from run to run when several items were checked on the same day.** The status window also now explains what active verification does, that "unverified" does not mean "safe", and that this screen itself does not run a scan (9 languages).

## 1.10.0 - 1.10.9 (summarized)

The contents of these releases, grouped by theme. The full text of each entry is in this file's git history.

- **Privileged helper hardening** (1.10.5): the helper now runs inside a sandbox from launch and self-checks it. It only talks to the genuine app, and Mach-O, `eslogger`, `tcpdump` and Sensor traffic are parsed outside root. Snapshot restore runs with the user's own privileges.
- **Quarantine and port scans** (1.10.5, 1.10.6): ARP-spoofing quarantine is lifted automatically once the cause is confirmed gone. Fixed quarantine release trusting a spoofed gateway and ARP pinning locking in a forged MAC. Automatic port-scan blocking now verifies the source MAC, and IPv6 scans are detected. A manual quarantine that failed no longer keeps showing "quarantined".
- **Ransomware defense and recovery** (1.10.0 to 1.10.8): added generic entropy-based detection and reworked decoy files so they no longer break real tools. "Ransomware Recovery" lets you pick deleted files from snapshot contents, and detects deletion of recovery snapshots by a third party. Added a separate "Recovery and Uninstall" menu.
- **Tailscale and VPN** (1.10.1 to 1.10.5): the Exit Node is now checked against the real OS route rather than tailscaled's self-report. VPN tool upgrades are announced, and a pinned folder with files outside the manifest is rejected.
- **Link guard and download guard** (1.10.1): fixed brand-impersonation (homograph) detection that never worked for Apple and PayPal.
- **Notifications and UI** (1.10.0 to 1.10.9): identical notifications stay silent for 10 minutes (history keeps them all). Fixed a sound with no banner. Added explanations and confirmations when toggling features, showed block state in the exposed-port list, and separated "cannot verify" from "failed" in the overall diagnosis.
- **Security fixes** (1.10.4, 1.10.5): Sensor control traffic never falls back to plaintext. The license signing key was rotated (both old and new public keys are accepted). Out-of-range settings (ports, block durations) can no longer break firewall rule rebuilds.

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
