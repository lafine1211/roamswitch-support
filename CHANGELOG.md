# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (1.x, a separate series) are versioned
independently. Older releases are summarized in ranges.

---

## PersonalSOC

### 0.1.4

- **Fixed: secret masking in logs and detections now also covers quoted JSON (`"token": "abc"`) and `Authorization`, `Bearer` and `Basic` headers.** Before, only a value right after `=` or `:` was masked.
- **Fixed: log lines can no longer close the data fence handed to the LLM by containing the lookalike characters `<<<` and `>>>`.**
- **Fixed: scheduled runs (Mac) now work in folders whose path contains spaces or non-ASCII characters.** An app opened straight from the DMG (Gatekeeper translocation, where the app is run from a temporary location) is not registered, and you are asked to move it to the Applications folder (10 languages). If saving the settings fails, the registration is rolled back.
- **Fixed: when an LLM command times out, the child processes it started are terminated too.**
- **Changed: `opencode` is no longer treated as having its tools locked, because we have not yet confirmed that the setting really takes effect.** Using it now requires the confirmation in Settings, as with `agy` and `codex` (the README is updated).

### 0.1.3

- **Fixed: when an LLM's reply contained raw line breaks or invalid escapes and could not be read as JSON, it is now repaired and parsed again.**
- **Changed: the Gatekeeper source is now labelled "check the record of denials".** The screen and the README now state that Gatekeeper behaves the same whether this source is on or off (it only reads the record).

### 0.1.2

- **Added: PersonalSOC reads more from RoamSwitch's MCP**. Package CVE matches, the status of active vulnerability checks, what Sensor found when it audited this device from outside, protections switched off in settings, honeytoken, browser-credential and ransomware-write detections, recovery-snapshot readiness and preserved evidence (Mac), and an active Air-Gap (Linux) now show up as findings in the report.
- **Added: Gatekeeper denials on Mac, as an optional source** (off by default), because reading them takes about 10 seconds. You can turn it on in settings.
- **Changed: the LLM command's own tools are switched off at launch where possible**. `claude` starts with its built-in tools and MCP off, and `opencode` starts with every permission denied. `agy` and `codex` cannot be locked, so Settings shows "Tools cannot be locked" and using them requires a confirmation in Settings.
- **Fixed: the XProtect check matched process names (`XProtectRemediator*`) and treated harmless logs as suspected malware**.
- **Fixed: `codex` did not run in an empty temporary folder**.

### 0.1.1

- **Added: in-app updater (Mac)**. It fetches the latest version information only when you press "Check for updates" in Settings, and installs only after verifying the signature.
- **Changed: removed the fixed "Response" section from reports**. **Fixed: chart legends and axis labels overlapping in English and other languages**.

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

### 0.3.13

- **Audit report dates are now easy to read**. HTML and Markdown reports showed raw UTC strings such as `2026-09-19T08:00:03.415602838+00:00`. They now show this machine's local time in each language's order, with the weekday and the UTC offset (English: "Sat, 2026-09-19 17:00:03 (UTC+9)"). The "Generated (UTC)" heading is now just "Generated". CSV is meant for machines and stays in UTC as before.

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

### 1.10.18

- **Fixed (security): the daemon followed symbolic links when it placed decoys (canary files and honeytokens) in a user's folders.** A user could leave a link to a file that does not exist, and the root daemon would create an arbitrary file at the link's target and hand it to the user, which could lead to privilege escalation. Decoys are now created without following any link, and none is placed where a link is in the way.
- **Fixed (security): blocking a file's execution before it runs (fanotify) did not work when the daemon ran as a systemd service.** Inside the service's mount namespace, executions by host processes never reached the daemon. It now watches at the filesystem level, and we confirmed under the real service that execution of a flagged suspicious script is denied. The scan exclusions can also no longer be bypassed by faking a process name or by a partial path match.
- **Fixed (security): closed paths that exposed other users' information, allowed actions on their processes, or let a user load the daemon.** `get_canary_status` returns only the caller's own home and counts for the rest, except to administrators (root, and the sudo, wheel and roamswitch groups). `kill_process` refuses a process the caller does not own. An IPC line is limited to 1 MiB and a non-root user to 16 simultaneous connections. Refusals are remembered briefly so an external command is not started every time.
- **Fixed: switching the firewall profile could leave the host without rules in the middle of the switch or when it failed.** The switch is now one atomic batch (Air-Gap too).
- **Fixed: the pending-approvals record (`approvals.json`) could lose entries when updated concurrently, or be read half-written.**
- **Fixed: the event-forwarding output file is now limited to places only root can write (every ancestor owned by root).** This closes a way for a user to make root append to or rename an arbitrary file through the settings. `/var/log/roamswitch/` on Ubuntu works too. When a path is refused, the reason appears in `roamswitch forward status`.
- **Fixed: interface names and radio types passed to the DNS settings and to rfkill are validated, and values that would be read as options are refused.** Temporary-file creation in the updater was hardened, and an unparseable `generated` value is now rejected.
- **Added: the Client now sends a proof of possession of the key (PoP) when pairing with a Sensor.** A newer Sensor uses it to stop someone else's public key from being registered over a connection without a certificate pin.
- **Fixed: the notification for a failed quarantine now shows the reason in 10 languages when it was refused because there is no login session.**
- **The bundled PersonalSOC is now 0.1.4** (see PersonalSOC 0.1.4).

### 1.10.17

- **Improved: the calm wording of alerts during a Sensor audit now returns to normal as soon as the report arrives** (client edition). Before, it stayed calm for a fixed 25 minutes from the request. The 25 minutes is now only an upper bound for when no report ever comes. Reports are fetched every 5 minutes, so the normal wording returns at most about 5 minutes after the audit finishes.
- **The bundled PersonalSOC is now 0.1.3.** It repairs malformed LLM replies and relabels the Gatekeeper source (see PersonalSOC 0.1.3).

### 1.10.17

- **Fixed (security): the link guard let a hostname with a trailing dot (`evil.com.`) through.** Hostnames are normalized before the block decision.
- **Fixed (security): a scanned file's name containing a line break and a fake detection line could make RoamSwitch quarantine any file of the user's.** Before quarantining, only the detected paths are scanned again, and only what is really detected is quarantined.
- **Fixed (security): the privileged helper now verifies the link guard's threat feed by signature before publishing it.** Before, the feed was verified at download and then used as-is from a place the user can write, so a program of the same user could empty the feed to disable the link guard, or add hosts. If verification fails, the previous feed is kept and protection is not removed. A feed older than the recorded one, replayed with its genuine signed manifest, is refused too.
- **Fixed (security): in MCP exec-log search, secrets in command lines can no longer be guessed from whether a search matches.** Searches run on the masked text, and the app itself now masks output and rate-limits searches (so another program of the same user cannot read the raw records through the relay). The masking now covers API keys such as `sk-svcacct-`, tokens from GitHub, GitLab, npm, Slack and Google, `mysql -ppassword`, `DB_PASS=` and similar. Verifying the exec log's integrity chain now detects a rewritten sealed segment and a deleted oldest segment.
- **Fixed: when importing a WireGuard configuration failed, the saved endpoint was overwritten with that of the rejected configuration.** Also fixed: when `wg-quick up` failed, the previous kill switch was not restored and traffic stayed blocked.
- **Fixed: state is now saved atomically** (kill switch, port protection, Sensor pairings and others). An interruption can no longer bring the app back from a corrupted state with the kill switch off.
- **Fixed: a malware scan could hang when its output was large.**
- **Fixed: the Mac now sends a proof of possession of the key (PoP) when pairing with a Sensor.** The control-channel signature version once confirmed is saved, and no fallback to an older signature format is made over a connection without a certificate pin.
- **Fixed: a TLS ClientHello split across several records is now inspected, up to 16 KB.**
- **Fixed: the check of the SSH remote-login state, DNS restoration (disabled services and others), restarting port-scan detection, and the handling of symbolic links when the exec recorder checks plists.**
- **The bundled PersonalSOC is now 0.1.4** (see PersonalSOC 0.1.4). If 0.1.1 or later is installed, you can update from inside the app.

## 1.10.16

- **The bundled PersonalSOC is now 0.1.2**. It reads more from RoamSwitch's MCP (package CVE matches, the status of active vulnerability checks, Sensor's outside audit results, protections switched off in settings, recovery readiness and more) and starts LLM commands with their own tools switched off where possible. Using `agy` or `codex`, whose tools cannot be locked, now requires a confirmation in Settings. See the PersonalSOC 0.1.2 entry for details.

### 1.10.15

- **Added: the honeytokens now include `~/.pypirc` and `~/.env.backup`.** They target scans for PyPI tokens, .env files and AI API keys. `~/.npmrc` is not used, because npm reads it on every run. Uninstall removes only the files that carry the marker.
- **Fixed: log-audit notifications were reporting changes caused by the OS's normal operation, causing alert fatigue.** Only security-relevant anomalies (failed authentication such as `Failed password`, `Invalid user` or a sudo failure; AppArmor denials; segfaults; malware detections) now reach desktop notifications, server notifications and the notification history. Everything else stays in `roamswitch audit-logs`, the on-screen list and MCP.
- **Fixed: the "detection saturated by a SYN flood" warning within about 25 minutes after a Sensor audit was requested is now worded calmly as most likely caused by the audit, and its urgency is lowered** (client edition). Port-scan detection already used calm wording through a source IP and MAC match. Outside that window nothing changes, and audits a Sensor starts on its own are not covered. The Server Edition does not request audits, so it is unchanged.

### 1.10.0 - 1.10.14 (summarized)

Everything in these releases, grouped by topic (Client and Server Edition unless marked). The full text of each entry is in the git history of this file.

- **Detections and features added** (1.10.0, 1.10.7, 1.10.11): DNS tunneling and exfiltration detection (only the host's own DNS queries; name resolution is never blocked). A forensic evidence bundle (with a SHA-256 manifest) when containment fires. Honeytokens. The age of the last proven vulnerability check (`roamswitch vuln-status`) and a mapping of diagnostic items to NIST CSF 2.0 and CIS Controls v8. Detection of LockBit-style partial encryption (16 of every 32 bytes, 1.10.7). Detection of the ransomware-recovery snapshots being deleted or thinned by anything other than RoamSwitch or the known managers snapper and timeshift (T1490, 1.10.11).
- **Honeytoken and evidence-bundle fixes** (1.10.4, 1.10.5, 1.10.8): so that real tools are not broken, the AWS decoy uses a separate profile name and the Docker decoy a non-existent registry name. Mode is 0600, and access by OpenSSH and by RoamSwitch itself is not flagged (1.10.8 also fixed a false positive from RoamSwitch's own process). The 1.10.0–1.10.4 packages did not include `roamswitch-honeytokens` and `roamswitch-incident-capture`, so decoys and evidence bundles never ran. 1.10.5 ships both in the client and server packages, and CI fails a build that lacks them.
- **Isolation (Air-Gap) and host defense** (Server Edition, 1.10.5): fixed host isolation cutting the management SSH it should keep, port 22 being opened even with `preserve_ssh_on_isolation=false`, and the operator's acknowledgement (`roamswitch server ack`) being ignored. Evidence is now collected before blocking on more paths, and the settings `honeytokens_enabled` and `harden_userns_enabled` were added.
- **Security fixes** (1.10.4–1.10.7): state-changing IPC can be called only by root or a user with a local login session. The root daemon no longer reads `~/.config/roamswitch/config.json` without checking ownership or follows symlinks when writing. The daemon runs inside a systemd sandbox. `rustls` was updated to 0.23.45 (RUSTSEC-2026-0285). Fixed: treating a gateway MAC change alone as "moved to another network", isolation release trusting the current gateway unconditionally, and the ransomware burst detector excluding processes that carry an allow-listed name. Link-guard packet parsing runs in a sandboxed child process outside root.
- **Malware detection** (1.10.0–1.10.6): fixed a fallback hiding `clamdscan --fdpass` failures, a USB scan treating exit code 2 (failed to run) as malware and running `umount -f`, and the daily update not being able to update ClamAV signatures. An EICAR self-test of the detection path was added. fanotify now uses permission events only for execution.
- **Network, DNS, Docker, link guard** (1.10.1–1.10.4): DNS enforcement no longer flushes the DNS cache every 3 seconds (it runs only when the state changes). The Docker protection self-heals every 60 seconds. The link guard's packet wait and queue length were revised, and it reassembles the ClientHello from TCP sequence numbers. An option to block UDP/443 (QUIC) was added (`linkGuard.blockQuic`, off by default). Fixed: a `clamav.net` false positive in DNS tunneling detection, the Sensor control port (50543) being blocked permanently on a co-located host (Server Edition), and an endless repeat of notifications for programs that bind a different UDP port on every restart.
- **Notifications, diagnostics, UI** (1.10.3, 1.10.4, 1.10.9, 1.10.11): identical notifications are only recorded in the history for 10 minutes. On Arch-based systems the "automatic security updates" check is "not applicable". Fixed: port blocking reporting success even when nftables was not updated, Wi-Fi safety always being "unknown" on iwd systems (RoamSwitch OS), guidance for Validity fingerprint sensors, and tabs cut off at 1280 px. The tray language switcher gained Italian and Portuguese, and the ransomware-recovery screen now describes its real scope (the logged-in user's home only, 1.10.11).
- **Recovery, uninstall, upgrade** (1.10.7, 1.10.10): a dedicated tab in the main window, and `roamswitch emergency-restore` plus a tray menu entry undo isolation, firewall, gateway pinning, DNS and connection tracking. `roamswitch uninstall` does this first and then removes the decoys and files it added. The license signing key was regenerated (both old and new public keys are accepted). Three GUI upgrade problems were fixed: stopping on one unreachable mirror, reporting success when nothing changed, and not restarting the app. The restore path is now a real file picker (1.10.10).
- **PersonalSOC bundled** (1.10.14): a separate app that gathers this machine's logs and defense status read-only into a report is now bundled in the packages (deb, rpm, tarball, AUR). 10 languages, Apache-2.0. Its LLM integration is optional and off by default. The Server edition does not include it.
- **Packages, tests, other** (1.10.5–1.10.10): apt and rpm keep the latest three versions of each package. The pentest suite was re-run (Server 19/19, Client 11/11). External commands called by the resident daemon now have a time limit (a `bluetoothctl` that did not answer for 1 hour 41 minutes on a system without bluetoothd stalled IPC). RoamSwitch OS hides the uninstall entry points. The Server investigation-agent report now includes the host name and IP address.
- **Activity log and false-positive audit** (1.10.13): a Security Activity Log tab to search and filter past detections (ARP, FIM, port anomalies, recorded process execution, notification history and more). An alert-fatigue audit fixed 44 findings in the desktop edition and 7 in the server edition: lockfile monitoring's "unreadable" verdict is no longer treated as tampering, notifications for link protection, isolation-release checks, gateway-MAC changes and exec detection now carry more to judge them by (the triggering signal, old and new MAC, the download source), and the server edition's Docker notification is deduplicated.
- **Resume from suspend, diagnostics, feed** (1.10.12): fixed a false "protection is not responding" alert right after resuming from suspend (a gap far beyond the monitor loop's interval is treated as a resume, and every guard's timestamp is reset). Also fixed the order and explanation of the active-verification status, a UDP-listener notification record that grew without limit, and the popular-npm-packages feed's manifest URL not matching the published file name, which showed a false SHA-256 mismatch warning.

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

## 1.10.16

- **Improved: the calm wording of alerts during a Sensor audit now returns to normal as soon as the report arrives.** Before, it stayed calm for a fixed 25 minutes from the request. The 25 minutes is now only an upper bound for when no report ever comes. Reports are fetched every 5 minutes, so the normal wording returns at most about 5 minutes after the audit finishes.
- **The bundled PersonalSOC is now 0.1.3.** It repairs malformed LLM replies and relabels the Gatekeeper source (see PersonalSOC 0.1.3). If 0.1.1 or later is already installed, it can be updated from inside the app.

## 1.10.15

- **Added: the honeytokens now include `~/.pypirc` and `~/.env.backup`.** They target scans for PyPI tokens, .env files and AI API keys. `~/.npmrc` is not used because it would cause endless false positives (npm reads it on every run), and GCP credentials are not used because a fake file would break genuine authentication.
- **Added: when a decoy is actually accessed, exactly one related decoy (`~/.aws/config`, `~/.ssh/config` or `~/.kube/config`) is planted and watched as well.** The chain stops after one step and no existing file is overwritten. Uninstall removes only the files that carry the marker.
- **Added: a new rule in the process-execution recorder (Pro) detects a command line that directly names a decoy credential file RoamSwitch planted (for example `cat ~/.aws/credentials`).** The recorder now has 11 rules. A real file with the same name never matches, because only files that carry the marker count. Reads through a library are left to the existing decoy watcher.
- **Fixed: for about 25 minutes after a Sensor audit was requested, port-scan detections from the Sensor's address and the "detection saturated by a SYN flood" warning (which has no source address) were shown with attack-like wording.** Within that window they are now worded calmly as most likely caused by the audit (and still recorded). Outside it nothing changes, and audits the Sensor starts on its own are not covered.
- **Fixed: log-audit notifications were reporting changes caused by the OS's normal operation, causing alert fatigue.** Only security-relevant anomalies, such as failed authentication or XProtect detections, reach notifications and the notification history. Everything else appears only in the audit window.
- **Improved: the Full Disk Access guidance is now consistent.** The privileged helper's permission is decided by "RoamSwitch" in the System Settings list (there is no separate helper entry). If it is not listed, add `/Applications/RoamSwitch.app` with "+". The screen text, the help and the knowledge base were updated in 10 languages.
- **The bundled PersonalSOC is now 0.1.2**. It reads more from RoamSwitch's MCP and starts LLM commands with their own tools switched off where possible (see the PersonalSOC 0.1.2 entry).

## 1.10.14

- **Added: PersonalSOC now has an in-app updater (Mac)**. In Settings under Updates, it connects to lafine.net to fetch the latest version information only when you press "Check for updates" (nothing about this device or its logs is sent). If a newer version exists you can download and install it. The downloaded file is verified with a signature before it is installed, and nothing is installed if the check fails. It is a separate mechanism from RoamSwitch's own in-app updater (Sparkle). For now only Apple Silicon (M1 and later) is covered.
- **Changed: removed the fixed "Response" section from PersonalSOC reports**. It was the same sentence in every report. When the LLM proposes a response, it appears inside its audit report.
- **Fixed: in PersonalSOC in English and other languages, chart legends and axis labels overlapped or were cut off**. Also fixed the "Recent events" text in reports being cut in the middle of a word.
- PersonalSOC is now 0.1.1. If 0.1.0 is already installed, installing the new DMG updates it. From 0.1.1 on you can update from inside the app.

## 1.10.0 - 1.10.13 (summarized)

The contents of these releases, grouped by theme. The full text of each entry is in this file's git history.

- **Privileged helper hardening** (1.10.5): the helper now runs inside a sandbox from launch and self-checks it. It only talks to the genuine app, and Mach-O, `eslogger`, `tcpdump` and Sensor traffic are parsed outside root. Snapshot restore runs with the user's own privileges.
- **Quarantine and port scans** (1.10.5, 1.10.6): ARP-spoofing quarantine is lifted automatically once the cause is confirmed gone. Fixed quarantine release trusting a spoofed gateway and ARP pinning locking in a forged MAC. Automatic port-scan blocking now verifies the source MAC, and IPv6 scans are detected. A manual quarantine that failed no longer keeps showing "quarantined".
- **Ransomware defense and recovery** (1.10.0 to 1.10.8): added generic entropy-based detection and reworked decoy files so they no longer break real tools. "Ransomware Recovery" lets you pick deleted files from snapshot contents, and detects deletion of recovery snapshots by a third party. Added a separate "Recovery and Uninstall" menu.
- **Tailscale and VPN** (1.10.1 to 1.10.5): the Exit Node is now checked against the real OS route rather than tailscaled's self-report. VPN tool upgrades are announced, and a pinned folder with files outside the manifest is rejected.
- **Link guard and download guard** (1.10.1): fixed brand-impersonation (homograph) detection that never worked for Apple and PayPal.
- **Notifications and UI** (1.10.0 to 1.10.9): identical notifications stay silent for 10 minutes (history keeps them all). Fixed a sound with no banner. Added explanations and confirmations when toggling features, showed block state in the exposed-port list, and separated "cannot verify" from "failed" in the overall diagnosis.
- **Security fixes** (1.10.4, 1.10.5): Sensor control traffic never falls back to plaintext. The license signing key was rotated (both old and new public keys are accepted). Out-of-range settings (ports, block durations) can no longer break firewall rule rebuilds.
- **Privileged-helper resource leak and busy loop** (1.10.10, 1.10.11): fixed pipes for external-command output not being closed, so open file descriptors reached the limit (256) and the app showed "helper not connected"; the firewall and DNS being rewritten roughly every 2 seconds; the helper possibly stalling on large output; and the gateway pinning being deleted and re-added on every re-evaluation even when already pinned.
- **NDP pinning and diagnostics** (1.10.10, 1.10.11): pinning the IPv6 router's NDP entry did not actually work (`ndp -s` without an interface returns exit code 0 but does not pin). It now pins with `fe80::…%en0` and verifies afterwards. Also fixed: critical-file tamper monitoring reporting "deleted" for a file that was merely unreadable for a moment because of a race, and the ordering of the "proven vulnerability check" status.
- **Activity log and false-positive audit** (1.10.12): a Security Activity Log screen to search and filter past detections. An alert-fatigue audit fixed 27 findings: the ransomware emergency-containment banner now names the affected file and the suspected process, ClickFix protection only notifies when a command matches a known installer's pattern, the risky-Docker-container notification has a 24-hour cooldown, link protection states its triggering signal, and the Pickle-format AI model download warning shows where the file came from.
- **PersonalSOC bundled** (1.10.13): a separate app that gathers this machine's logs and defense status read-only into a report is now bundled in the DMG. 10 languages, Apache-2.0. Its LLM integration is optional and off by default. It is not updated by the in-app updater (Sparkle) but by a new DMG (from 0.1.1 it also has its own updater).

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
