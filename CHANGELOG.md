# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (1.x, a separate series) are versioned
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

### 1.10.10

- **Added: the "Recovery & Uninstall" restore path is now a real GTK file picker instead of a free-text field.** It calls roamswitch-os's mount-for-browsing/unmount-browse and points the dialog straight at the snapshot's actual contents, so a deleted file can be selected directly. A preview pane (icon, size, kind, modified date) was added too (10 languages).
- **Added: on RoamSwitch OS (the OS-integrated build), `roamswitch uninstall` can no longer be run directly by the user** (and is removed from Help). The app is part of the OS. The standalone build behaves as before; the scripted cleanup path (`--scripted`) is unchanged.
- **Fixed: on RoamSwitch OS (the OS-integrated build), upgrade detection only looked at the standalone package names (roamswitch-bin/roamswitch) and could not see updates.** It now also checks the OS-integrated package name (roamswitch-linux-os-integration) and the OS tooling (roamswitch-os).
- **Changed: on RoamSwitch OS (the OS-integrated build), the uninstall button and tray item are no longer shown** (the app is part of the OS). The standalone build shows them as before.
- **Fixed: external commands the resident daemon calls on its periodic cycle (bluetoothctl, nmcli, lsof, conntrack, mokutil, iwctl, wpa_cli) had no time limit.** On a real RoamSwitch OS machine with bluetoothd not running, `bluetoothctl discoverable off` did not return even after 1h41m, and every lock-requiring IPC — including port blocking — jammed behind the cycle's shared lock (the GUI looked unresponsive). Commands that exceed the limit now have their child process killed and return a timeout.
- **Changed: the AUR (roamswitch-bin) publish job is now skipped by default** (AUR has stopped new registrations and the SSH key can no longer be fetched). To resume, set the repository variable `AUR_PUBLISH_ENABLED=true` and rerun the job.

### 1.10.0 - 1.10.9 (summarized)

Everything in these releases, grouped by topic (Client and Server Edition unless marked). The full text of each entry is in the git history of this file.

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

## 1.10.9

- **Fixed: a threat-detection notification could play its sound without ever showing a banner.** Every threat notification requested a "Critical Alerts"-only sound without the entitlement that makes it work (RoamSwitch does not have that entitlement). Unified on the regular sound.
- **Fixed: eight features, including "Active Vulnerability Verification" and "Auto-isolate on a suspicious Terminal command (ClickFix protection)", showed no explanation or confirmation when turned on or off, unlike every other similar toggle.** Added a confirmation dialog to each, explaining what it actually does (10 languages).
- **Improved: each row in the menu bar's "Exposed Ports" list now shows 🔒/🌐 for whether that specific port is actually blocked or still open.** Previously only the overall firewall state at the top was shown, with no way to read an individual port's real status.
- **Fixed: the alert for an unauthenticated database or similar service exposed externally did not account for ports already individually isolated via Dev Server Isolator.** The "Exposed Ports" checks in the health dashboard, the menu list and the MCP server were already fixed in the previous release; this alert had the same gap left over. Isolated ports are now excluded.

## 1.10.0 - 1.10.8 (summarized)

Everything in these releases, grouped by topic. The full text of each entry is in the git history of this file.

**1.10.5:**

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

**1.10.6:**

- **Fixed: when you isolated a port by hand and the privileged helper failed, the window kept showing it as "isolated".** The result was never checked. On failure the display is now reverted and the reason is shown (10 languages). This follows the same bug found on a real RoamSwitch OS machine on the Linux side.

**1.10.7:**

- **Added: the "Recovery from Ransomware" file picker now points at the snapshot's real contents, with a preview.** It used to show only the current contents of your home directory, so a deleted file itself could not be selected. The helper now keeps the snapshot open through new mount/unmount XPC calls, and a preview shows the selected item's icon, size, kind and modification date (9 languages).
- **Fixed: the overall health check for "macOS accessory-connection protection" had a branch that could never run, always showing "not applicable" on Intel Macs.** Intel Macs are already unsupported, so the branch was removed.

**1.10.8:**

- **Added: detects when a local ransomware-recovery snapshot is deleted by anything other than RoamSwitch itself or an Apple process** (the same technique as Windows's `vssadmin delete shadows`, MITRE ATT&CK T1490).
- **Fixed: the health check list showed the same ⚠️ for an item that could not be determined as for a real failure** (it now shows ➖), and the "Exposed Ports" check kept counting ports already isolated via Dev Server Isolator (including in the MCP server's `get_security_report`).
- **Improved: the knowledge base description of "Process Execution Recording" now lists the three detection rules that were missing (10 languages), with a test that fails if this happens again, and the "Ransomware Recovery" screen explains what a snapshot covers.**

**1.10.0 - 1.10.4:**

- **New detection** (1.10.0): generic entropy-based ransomware detection (it analyzes the entropy of writes to Documents, Desktop, Downloads and Pictures, so it also catches encryption where no decoy exists; Pro, on by default). A forensic evidence bundle at emergency network isolation (process list, network connections, recently changed files, with SHA-256). Credential decoys (honeytokens at `~/.aws/credentials`, `~/.ssh/id_rsa`, `~/.docker/config.json`; Pro, on by default). Monitoring of access to browser credentials (off by default, even in Pro). Two process-execution rules (base64/eval with curl/wget in inline scripts, and `DYLD_INSERT_LIBRARIES`). The age of the last vulnerability check. A NIST CSF 2.0 and CIS Controls v8 mapping for each health check. Four triage skills for roamswitch-mcp.
- **Decoy and ransomware-detection fixes** (1.10.1, 1.10.3): because the decoys broke real tools, the ssh decoy is now `id_rsa_backup`, the AWS decoy uses `[backup-admin]`, and the Docker decoy points at an internal registry name that does not exist, all written with 0600. Fixed: false alarms from RoamSwitch's own reads when monitoring was re-enabled, the secret-leak audit reading the decoys and triggering detection, and monitoring stopping silently after an app restart. Also fixed (1.10.1): entropy-based ransomware detection missing a real attack because of a harmless resident process (such as Spotlight's mdworker), and the `DYLD_INSERT_LIBRARIES` rule firing on every debug run from Xcode.
- **Tailscale and VPN** (1.10.1, 1.10.2, 1.10.4): the Exit Node trusted tailscaled's own report and never checked the real OS default route; if the route is not established it now drops the selection and notifies. Network recovery after a disconnect (DHCP renewal) reported success from a command's exit code alone; fixed (1.10.1). `tailscale ping` misjudged a healthy Exit Node behind a DERP relay as unreachable and disconnected it, and a single back-out disabled auto-connect on every later network; both fixed (1.10.2). VPN auto-connect now matches the Linux edition and runs only at "Maximum Lockdown" (1.10.2). The root helper no longer runs Homebrew VPN tools directly; it runs only a root-owned copy that you "pinned" after review, checked with SHA-256 on every run (1.10.4).
- **Link protection, download protection, startup** (1.10.1): brand-impersonation (homoglyph) detection never worked for Apple and PayPal (it now also catches one-character swaps such as `app1e.com` and brand-plus-word domains such as `microsoft-security-alert.com`). Web and mail download protection crashed at startup because of when the first-launch folder-access prompt was shown, so it never ran. Also fixed: a failed gateway MAC lookup right after launch stuck and made "trust the current network" unresponsive, and browser-credential monitoring flagged Chrome helper processes (the `lsof` output was truncating names).
- **Notifications and windows** (1.10.1 to 1.10.4): threat notifications with the same content are silenced (sound and banner) for 10 minutes; the notification history keeps all of them. A repeating notification for the same port is shown only the first time (`wsdd`, 1.10.1). Browser-credential monitoring does nothing, not even a history entry, when it cannot identify the accessing process (1.10.2). During isolation the menu bar shows whether it is full or degraded and why, and there is a new "Isolation status and how to release it..." window. On an untrusted network with both VPN auto-connect and ARP/NDP pinning off, a hint is shown (1.10.4).
- **Security fixes** (1.10.4): control traffic with a Sensor never falls back to plaintext (a Sensor paired before TLS support cannot connect until its certificate fingerprint is registered). The root helper has a floor on which processes it may signal (it refuses itself, OS daemons such as those under `/System/`, and RoamSwitch's own binaries). `setSecureDNSServers` accepts only IPv4/IPv6 addresses, and WireGuard import accepts only plain tunnel keys.

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
