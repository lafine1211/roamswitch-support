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

### 0.3.8

- **Fix: slow ARP sweeps went undetected.** The short window (15 targets in 30 seconds)
  missed a scanner that probes one address every few seconds (24 addresses at 2.5 s each
  never fired). A long window now notifies once 64 distinct targets are reached within
  24 hours (a 2.5 s-per-address sweep fired at the 64th target, after 158 seconds on a
  real clock).
- **Change: requests for live hosts don't count toward the long window.** A gateway or
  DHCP server legitimately asks for many real clients. Requests for hosts known to be
  alive (from ARP senders and the device inventory) are ignored, so only sweeps that
  spend most requests on empty address space count. A sweep aimed only at inventoried live
  hosts can't be told apart.
- **Fix: a flood of spoofed sources can no longer grow memory without bound.** The number
  of tracked MAC addresses, targets per MAC, and the live-host table are capped.

### 0.3.7

- **Change: the apt and rpm repositories now hold only the latest version.** Every past
  version had been kept, which bloated the repository. Older versions can no longer be
  fetched from the repository.

### 0.2.1 - 0.3.5

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

### 1.9.94

- **Improved: unknown-port-listener alerts now identify the actual program.** A process listening via a
  generic interpreter (`python3`, `node`, …) previously showed only the interpreter name (e.g. `python3`)
  in the alert, leaving the real program (e.g. the WS-Discovery daemon `wsdd`) unidentifiable. The alert
  now resolves the script name from the command line and shows it as `wsdd (python3)` (Client and Server
  Edition alike).

### 1.9.93

- **Improved: Vulnerability scan log CSV export now shows appropriate descriptions for safe or inconclusive checks.** Previously, even when a check result was `safe` or `inconclusive`, the finding description and recommendation for the vulnerable case were displayed. Results now display appropriate explanations according to the outcome (e.g., "This check found no problem.", "No action needed.") across ten languages.
- **Improved: Vulnerability scan logging reliability and added scan IDs.** Introduced file locking during log append to prevent corruption from concurrent writes, and added a unique scan ID (UUID) per scan session to easily identify results from the same run. In addition, legacy logs or records with empty port numbers are now clearly displayed as "Unknown".

### 1.9.92

- **Fix: some notifications were Japanese-only (or Japanese/English-only).** These now appear in ten
  languages. Client: critical-file (FIM) tampering, dependency lockfile changes (including the note on
  whether a package manager was running), low-severity eBPF detections, and kernel-exploit detection
  (Air-Gap emergency isolation). Server Edition: every alert (Telegram, LINE, webhook), the test
  notification, and the Air-Gap notices. The triage summary attached to eBPF, FIM and lockfile
  notifications, and its detailed report, are also in ten languages.
- **Change: the Server Edition's notification language is set by `language`** (`system` follows the OS
  locale; `roamswitch server config set language <ja|en|zh-Hans|zh-Hant|ko|de|fr|es|it|pt-PT|system>`).
  Installs with no such key stay Japanese. Previously, any setting other than English still sent Japanese.
  One language per host.
- **Fix: the message printed when a second app instance is started was Japanese-only.** It is now in
  ten languages.
- **Fix: two health-check status lines (gateway ARP, /tmp noexec) were partly Japanese in other
  languages** on some machines. All their variants are now in ten languages, and a test covers every one.
- **Change: in the Sensor manual-pairing form, the fingerprint field now comes before the optional name.**
### 1.9.91

- **Fix: when pairing failed there was no way to tell why, and it looked like a wrong code or
  fingerprint.** Even when a firewall on the Sensor host blocked TCP 50543, the GUI always said "check
  the IP address, pairing code and public key". The GUI waited 6 s but the connection attempt waits 10 s,
  so it gave up before the daemon's actual reason arrived. The wait is now 30 s; an unreachable Sensor
  now lists the likely causes (firewall, Sensor stopped, plaintext-only) with a command to run on the
  Sensor host, and a separate message is shown when no answer comes back at all.
- **Fix: the notification history screen was so heavy it could freeze.** Some log-audit notifications
  had bodies of up to 99,000 characters and every entry was laid out in full. Bodies are now capped at
  2,000 characters when stored (oversized entries already on disk are truncated when read), desktop
  popups at 1,000. The screen draws the newest 200 entries; the full text stays in the CSV export.
- **Fix: "suspected malware" notifications repeated for the same file.** The approval de-duplication
  included the modification time, so every save of a file you were editing looked like a new threat.
  A given file and threat family is now quiet for 30 minutes (and re-notified every 30 minutes while it is
  still detected). Exec denials and quarantine after confirmation are unaffected.
- **Add: the ARP re-check sends a direct ARP request when the gateway has no neighbour-cache entry**
  (`arp_recheck_active_probe`, on by default). This reduces ARP-triggered isolations that stay stuck
  needing a manual release even though the link is up. Any reply carrying a MAC other than the trusted one
  is a mismatch, and so is a reply whose Ethernet source disagrees with its ARP sender.
- **Change: screens are split into tabs.** Package CVE scan (six checks) and Ports & DevIsolator (checks,
  Sensor, port list).
- **Fix: the record text of a manual Air-Gap was a hard-coded Japanese string.** It now follows the
  language setting (ten languages).

### 1.9.90

- **Change: an isolation triggered by a high-confidence detection no longer releases itself on
  a timer.** Isolations caused by a tampered canary, suspected ransomware, or a critical eBPF
  detection used to be fully released by a short timer even while the cause continued. If a
  re-check shows the cause is still there, the host now moves to a "degraded" mode after a cap
  (1 hour by default) and never re-opens on a timer. It is released only by `roamswitch
  emergency-restore`, the GUI, the server's `roamswitch server ack`, or a verified-cleared
  re-check. Detections that are prone to false positives still release on the short timer.
  Settings: `airgap_low_confidence_secs` / `airgap_hard_cap_secs` (client),
  `isolation_hard_cap_secs` (server).
- **Fix: connections that were already open survived an isolation.** An attacker's reverse shell
  could keep running after the host was isolated. The server edition now cuts every established
  connection except the maintenance SSH and allowed IPs, and the client's degraded mode allows
  loopback only.
- **Add: a continuous process-execution record** (`roamswitch events
  search|tree|export|verify|status`). It records which programs ran, their parents, hashes and
  containers on the machine only (default retention 200 MB / 14 days; a hash chain detects
  tampering) and adds seven notify-only correlation rules (a shell under a web server, execution
  from a temporary directory, running a file right after download, and so on). It is on by default
  on the server and on the client (except clients with under 1 GiB of RAM). Turn it off with
  `exec_recorder_enabled=false`. Nothing is sent anywhere.
- **Add: event forwarding** (off by default). Send to a destination you configure — syslog
  (RFC 5424 over UDP/TCP/TLS), CEF, JSON Lines, or an HMAC-signed webhook.
  `roamswitch forward status|test|queue`. TLS and webhooks use the system `openssl` and `curl`
  (added as package dependencies).
- **Add: a full-coverage TUI for the Server Edition** (`roamswitch server tui`,
  `roamswitch-server-tui`). Every CLI operation and all 120 `server.conf` / `guard.yaml` keys can
  be viewed and edited from the screen. Risky actions ask for confirmation and non-root users get
  a read-only view. Ten languages.
- **Add: the Docker firewall-bypass guard now works with Docker's native nftables backend and
  IPv6.** It heals itself within a minute if Docker rewrites its rules. Containers that were
  already running when the daemon started are now watched, and the FIM scope grew
  (`authorized_keys`, `ld.so.preload`, new files in watched directories).
- **Fix (security): a local unprivileged user could send a forged critical event to Falco's event
  socket and trigger a full Air-Gap.** The socket is now mode 0600 and the peer UID is checked.
  Also fixed: look-alike names such as `sshd-x` escaping the protected-process list, allowlist
  entries being bypassed by renaming a process, isolating a UID 0 process cutting the admin
  channel, and isolations that were not recorded. Allowlist entries can be bound to the real
  executable with `--exe`.
- **Fix (security): Telegram and LINE tokens and webhook URLs were visible in the process list**
  as `curl` arguments. They are now passed on standard input.
- **Add**: `--json` / `--export` (`status`, `report`, `timeline`, `notifications`), resuming a
  frozen process now also lifts its isolation, `sensor pair --fingerprint` and `sensor repin`, and
  a notification when another program opens credential files such as SSH keys (off by default).
- **Change: the RoamSwitch Sensor integration now speaks TLS 1.3 with certificate pinning.** When
  new pairings require Sensor 0.3.9 or later and you enter the Sensor's fingerprint (a Sensor
  older than 0.3.9 cannot be newly paired). Sensors that are already paired keep working in
  plaintext, with a warning, until you pin them with `roamswitch sensor repin`.

### 1.9.89

- **Fix: unknown-listening-port detection could be evaded with a system daemon's name.**
  A backdoor named like a daemon (`/tmp/sshd`, `/tmp/named`) was excluded from detection
  entirely. A listener is now trusted only if its executable sits in a system directory
  and its file name is that daemon. When the executable path is briefly unreadable, the
  listener is skipped for up to three scans so a restarting legitimate daemon isn't
  falsely flagged.
- **Fix: a listener started through an interpreter from a temporary directory looked like
  an ordinary dev server.** `python3 /tmp/x/evil.py` runs `/usr/bin/python3`, so the path
  alone didn't distinguish them. When the script lives in a temporary location it is
  always flagged and never absorbed into the baseline.
- **Fix: the dev-server block rules were briefly lifted while being re-applied.** Deleting
  and recreating the rules were separate operations, leaving about 16 ms unfiltered
  (7557 of 8112 connection attempts got through while re-applying in a loop). It is now
  one operation; the same test lets 0 through.
- **Fix: log-frequency anomaly detection went blind after one large burst.** After a
  10,000-line burst on a template that normally logs 35 lines, a later 200-line spike went
  unflagged. The value fed into the baseline is now capped. A lasting rise (35 to 50 lines)
  is still learned as normal within about four runs.
- **Change: stronger port-scan detection.** Memory no longer grows under a flood of spoofed
  sources; listening ports count 1/8 as much as closed ones, cutting false positives from
  ordinary clients; a 24-hour window catches slow scans; IPv6 is aggregated per /64.
- **Change: unknown-listening-port detection covers more.** Binds to a non-wildcard LAN
  address and listeners from temporary, in-memory or deleted binaries are flagged. New UDP
  listeners from interpreters or non-packaged binaries are reported (notification only).
  Scans run every 5 seconds.

### 1.9.88

- **Change: the apt and rpm repositories now hold only the latest version.** The
  publishing job rebuilt and kept every past version, which bloated the repository until
  the job failed partway. As a result, the changes in 1.9.86 and 1.9.87 reach apt and rpm
  with this version. Older versions can no longer be fetched from the repository.

### 1.9.87

- **Fix: a flood of forged SYNs could push port-scan records out of the log.** The
  detection rule's log limit was written after the log statement and limited nothing.
  The limit now comes first (200 per second) and anything above it is counted. In an
  isolated lab, a flood of about 70,000 forged SYNs per second now produces about 900
  log lines. Detection of ordinary scans, and of fast scans without a flood, is unchanged.
- **Added: a notification when detection is saturated.** When SYNs arrive above 2,000
  per second and use up the log budget, you are told that port scans in that window may
  have been missed (at most once per 6 hours, in 10 languages). A flood can hide a real
  scan, which no finite budget can prevent, so the notification tells you when it may
  have happened.
- **Fix: the paired-Sensor exemption.** A scan that merely claimed the Sensor's address
  escaped both the block and the strong warning. The Sensor's MAC is now recorded at
  pairing, and only SYNs from that MAC are exempt (for a Sensor on the same segment;
  behind a router, the address and a check that it is not forged still apply).
- **Fix: the block notification text.** It said all traffic was blocked, but only new
  connections are. The text is corrected in 10 languages.
- **Fix: on the client edition, the Frag Gap mitigation (denying user namespaces) was
  applied on every network except "open", which broke apps that build their sandbox
  from user namespaces, such as browsers, Flatpak, Electron and rootless containers.**
  The mitigation is now opt-in (setting `auto_enable_userns_restriction`) instead of on
  by default. The Server edition's permanent disabling is unchanged.
- **Fix: the root daemon created directories under `~/.local` owned by root, making the
  desktop unstable.**

### 1.9.85 - 1.9.86

- **Fix** (1.9.85): the client edition's diagnostics recommended
  `max_user_namespaces=0` on desktops.
- **Fixes** (1.9.86): ARP false positives triggering Air-Gap again under VirtualBox NAT
  (DHCP-lease infrastructure IPs are now excluded); RoamSwitch not starting at boot and
  missing from the taskbar; the health check advising apt on Arch-based systems; and
  an administrator password being requested every time Air-Gap was released.

### 1.9.84

- **Fix: the port-scan guard's auto-block could be abused with a forged
  source address.** A SYN scan's source address is unauthenticated, so an
  attacker on the same network could send SYNs to many ports with the
  gateway's address as the source and make this host block its own gateway
  (in an isolated lab, 20 forged SYNs cut the host off from its gateway for
  10 minutes). Three changes:
  - The block now refuses only new inbound connections. Replies to your own
    connections and established flows keep working.
  - The gateway, DNS resolvers and the host's own addresses are never
    blocked.
  - The SYNs' source MAC is checked against the neighbor table, and the
    block is withheld when the source looks forged (the alert and the
    incident record are still produced).

  Auto-block stays on by default. Applies to both Client and Server
  Editions.

### 1.9.75 - 1.9.83

- **Broader active vulnerability checks** (1.9.82): probes for Elasticsearch, CouchDB,
  Jenkins, VNC, RDP (NLA) and SMB (SMBv1, signing) were added (10 languages).
- **Running alongside a Sensor** (1.9.78 to 1.9.79): the Server setup wizard checks for
  a RoamSwitch Sensor on the same host and offers a preset, and nmap was added to the
  eBPF guard's allowlist.
- **Automatic-update fixes** (1.9.80 to 1.9.81): the periodic nmap NSE script DB update
  was failing silently in systemd's sandbox, and CVE map updates were held back a
  month by a shared marker. The boilerplate in generated CVE maps is now translated
  into 10 languages.
- **Other fixes** (1.9.75 to 1.9.77, 1.9.83): the notification history tab being
  squeezed to a fixed height; the active-scan tests polluting the real probe log; FIM
  (critical-path tamper detection) warning after every update; the first-run setup's
  "Done" button jumping to the last page, "Apply" freezing, and ARP false positives
  triggering Air-Gap in NAT environments.

### 1.9.55 - 1.9.74

- **RoamSwitch Sensor integration reworked** (1.9.64 to 1.9.70, 1.9.74): pairing moved
  from mDNS to a pairing code (mDNS works only within one LAN, advertises constantly,
  and is weakly authenticated). You can now request an active vulnerability audit from
  a Sensor and fetch and store the result later, and the MCP tool
  `get_sensor_audit_results` was added. Results can be shown and exported down to open
  ports, NSE output and confirmed-safe checks. The pairing screen's field order, the
  button being disabled while required fields were empty, the form not appearing at
  all, and the confusing "manual pairing" label were fixed.
- **The nmap NSE supplementary scan is always on** (1.9.64). Automatic update checks
  for the CVE maps run monthly (1.9.65).
- **Investigation agent integration extended** (1.9.55 to 1.9.56): a redesign of the
  sudo wrapping, support for notifications about sustained memory growth, high CPU, crash
  loops, zombie processes and rising system load, and a fix for the recursion where an
  agent's own investigation was detected as a new incident.
- **A full review of network control** (1.9.71 to 1.9.72): firewall settings not being
  re-applied right after a daemon restart; services stopped at the time shared-service
  control was turned off never being restored; and a manual security-level change
  racing the daemon's 3-second autonomous patrol over nftables.
- **UI fixes** (1.9.69 to 1.9.74): CSV column headers in 10 languages, input fields and
  buttons not showing in GTK (a `no_show_all` misuse), the URL safety button doing
  nothing, and the onboarding wizard defaulting to the most permissive "open" level
  (now "standard protection").

### 1.9.48 - 1.9.54

- **Added: this endpoint's own public key/address display, needed for
  mutual pairing with RoamSwitch Sensor** (1.9.48–1.9.50): both a CLI
  command (`roamswitch sensor key`) and a GUI display in the Sensor
  pairing card. Also fixed the GUI's own public key not actually being
  copyable via label selection alone.
- **Expanded the investigation-agent handoff** (eBPF/FIM deep-dive
  investigation, Server Edition only) (1.9.51–1.9.54): fixed the setup
  wizard's tool-choice prompt not remembering the previous selection,
  extended it beyond eBPF to Critical-Path FIM and lockfile FIM tampering
  detections, added the same first-pass triage report to FIM detections,
  and fixed it never actually working in practice under root (unresolved
  `PATH`, inaccessible keyring credentials).

### 1.9.39 - 1.9.47

- **Added (1.9.39):** typosquat detection (npm/pnpm package.json, static,
  Pro) — flags dependency names close to popular npm packages by edit
  distance (e.g. `expres`→`express`), no network access, list distributed
  via the daily signed updater pipeline.
- **Fixed (1.9.40):** a log-audit frequency-spike notification couldn't be
  corroborated right after it fired (the causing log lines were already
  consumed) — now recorded into notification history like new-pattern
  detections.
- **Fixed (1.9.41):** a layout bug collapsed the kernel-CVE detail column
  into single characters when many CVEs matched. **Improved:** added
  section headers to the Network Management tab.
- **Fixed (1.9.42):** the running-kernel CVE check false-flagged
  distro-specific security backports that only bump the ABI build number,
  not the upstream major/minor version.
- **Added (1.9.43, Server Edition):** Container Exec Guard — tracks
  container start/stop and marks each container's rootfs with fanotify's
  notify-only `FAN_OPEN_EXEC`, reading the executed file from the event's
  own file descriptor so a self-deleting attacker binary is still
  captured. Prompted by a real intrusion (RCE → in-container cryptominer
  → self-delete). Also: Egress Guard now covers container-originated
  (`forward`-chain) traffic, added per-process CPU-saturation detection,
  and fixed a false "eBPF Runtime Guard active" health-check result when
  Falco/Tetragon wasn't actually installed.
- **Fixed (1.9.44, Server Edition):** FIM/Lockfile FIM re-sent the same
  tampering notification every check interval instead of once; corrected
  the lockfile-tampering guidance to the proper two-step verify→update
  flow; fixed eBPF alerts showing "PID: none" when Falco reported the PID
  as a JSON string; added a Falco exception for `systemd-executor`
  (false-positived on every SSH login on systemd ≥255); separated
  updater integrity-failure messaging from generic connectivity errors.
- **Added (1.9.45):** automated local first-pass triage for eBPF alerts
  (false-positive likelihood + reasons + next-check commands, Markdown
  report saved) and an optional handoff to an agentic CLI (`guard.yaml`
  `investigation`, Server Edition, off by default, skipped right before
  host Air-Gap isolation); detection of secret exfiltration via `env`/
  `.env` reads (custom Falco rule); fixed the Linux client's own
  FIM/Lockfile FIM re-notify loop and `lockfile-fim verify`'s `$HOME`
  resolution under `sudo`.
- **Added (1.9.46):** interactive setup for the investigation-agent
  handoff in `roamswitch server setup` (preset menu: Claude Code / agy /
  Codex CLI / OpenCode / custom).
- **Fixed (1.9.47):** running `lockfile-fim` without `sudo` failed with a
  confusing bare "Permission denied" instead of a clear error.

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

## 1.9.54

- **Improved: unknown-port-listener alerts now identify the actual program.** A process listening via a generic interpreter (`python3`, `node`, …) previously showed only the interpreter name (e.g. `python3`) in alerts and incident history, leaving the real program (e.g. `wsdd`) unidentifiable. The alert now resolves the script name from the command line and shows it as `wsdd (python3)`.

## 1.9.53

- **Improved: Active vulnerability scan log CSV export now shows appropriate descriptions for safe or inconclusive checks.** Previously, even when a check result was `safe` or `inconclusive`, the finding description and recommendation for the vulnerable case were displayed. Results now display appropriate explanations according to the outcome (e.g., "This check found no problem.", "No action needed.") across ten languages.
- **Improved: Active vulnerability scan logging reliability and added scan IDs.** Introduced file locking during log append to prevent corruption from concurrent writes, and added a unique scan ID (UUID) per scan session to easily identify results from the same run. In addition, legacy logs or records with empty port numbers are now clearly displayed as "Unknown".

## 1.9.52

- **Changed: the network isolation (Air-Gap) was reworked.** What triggered it now decides how it ends.
  A tampered ransomware decoy, a confirmed XProtect detection and a manual isolation chosen from an ARP
  warning are "high confidence"; the rest (ClickFix, port anomalies and so on) are "low confidence".
  Low confidence still releases by itself after 10 minutes. High confidence does not release at 10
  minutes: full isolation continues up to a limit (1 hour by default). At the limit it releases if the
  cause is confirmed gone, and otherwise moves to "degraded mode", which keeps new connections blocked,
  never opens by time, and comes back only when you release it or the cause is confirmed gone.
  Connections that were already open are cut when the isolation starts. The state survives a helper restart.
- **Changed: an isolation caused by ARP spoofing is not released automatically.** While isolated, the
  gateway's ARP entry disappears, so the cause cannot be confirmed gone without traffic. Release it by hand.
- **New (Pro): process execution recorder.** It records process starts, on this Mac only, with macOS's own
  `eslogger` (off by default; the helper needs Full Disk Access). The log is stored in a tamper-evident
  form, and nothing is blocked. It notifies on seven behaviours: a browser, Office or mail app starting a
  shell directly; an unsigned binary run from a temp folder or with the quarantine flag; a one-liner that
  downloads and pipes into a shell; osascript with base64 or eval; running a file right after its
  quarantine flag is removed; an unsigned binary started from a freshly written launch agent; and a
  non-Apple parent reading a keychain secret. The read-only Pro MCP tools `search_exec_events` and
  `get_process_tree` search the record.
- **New: quieter notifications, and an allow action.** Execution-recorder notifications show a banner only for
  high severity, and at most once per kind every 10 minutes (everything stays in the record). Claude Code
  and `gh` (GitHub CLI) reading their own credentials are not reported. When another program reads a
  keychain item, "Allow this program" on the notification allows that one item only.
- **New: TLS and v2 signatures for the Sensor.** With a pinned certificate fingerprint, pairing, audit
  requests and result retrieval work over TLS with Sensor 0.3.9 or later. A Sensor without a fingerprint
  is still reached as before, with a warning. When a certificate changes, the fingerprint must be
  registered again; the pin is never updated automatically.
- **Fix: the rule for running a file after its quarantine flag is removed missed files under `/tmp`.**
- **Fix: ransomware recovery showed the reason for a failure in English.** It is now shown in ten
  languages, as are the Sensor connection errors. When pairing, a wrong fingerprint is explained as a typing
  mistake.
- **Fix: some Korean and Chinese texts contained the Japanese middle dot.**
- **Limits**: the recorder does not capture what ran before the helper started or before it was
  enabled. It does not run without Full Disk Access and resumes within about a minute after the permission
  is restored. Removing the helper's permission takes effect only after the helper restarts.

## 1.9.51

- **Fix: it could take minutes from a ransomware decoy being tampered with to the emergency cutoff.**
  The step that looks for the suspicious process ran a full code-signature check, which
  hashes the whole executable, for every line of the open-files list (about 29,000 lines
  on the test Mac). It now checks only lines that involve a decoy or a watched folder,
  and only once per process. The detection rule is unchanged. On the test Mac, the time
  from tampering to the cutoff went from minutes to about 2 seconds.

## 1.9.50

- **New: "Ransomware Recovery" lets you get back just the files you need after a ransomware attack.**
  Independently of any detection, APFS local snapshots are taken every 6 hours by default
  (off, 1, 3, 6, 12 or 24 hours). A snapshot taken after a detection already holds the files
  that were encrypted, so it is not a recovery source. A snapshot is also taken at detection
  time, and while it is the newest one, new scheduled snapshots and pruning pause for up to
  7 days so the last pre-encryption generation is not pushed out.
- **Recovery is always manual and file-level.** From "Ransomware Recovery..." in the menu (Pro),
  files and folders from the recommended snapshot (the newest pre-detection one that still
  exists) are copied to `~/RoamSwitch-Recovered/`. Current files are never overwritten and
  no whole-volume restore is offered.
- **Limits**: taking files out needs Full Disk Access for the RoamSwitch helper (creating
  snapshots does not). macOS may delete local snapshots after about 24 hours, sooner when
  free space is low.
- **MCP: added the read-only tool `get_ransomware_recovery_snapshots` (Pro).** It returns the
  snapshot list, the recommended one, retention mode and the interval. It cannot restore anything.

## 1.9.49

- **Fix: right after updating, a root program's UDP listener was reported as unknown.**
  1.9.48 quietly adds the existing listeners the privileged helper sees for the first time
  to the baseline, but only for TCP; UDP was missed (for example `tailscaled` raised one
  "unknown UDP listener" notification right after the update). Both TCP and UDP are now
  added. It was a notification only; nothing was blocked.

## 1.9.48

- **Fix: automatic blocking of unknown ports couldn't see ports opened by root
  programs.** The app runs as the logged-in user, so root-owned listeners (the daemons a
  remote exploit tends to land in) never appeared in its list. The privileged helper now
  lists them as root and hands the list to the app. Existing listeners the helper finds for
  the first time are quietly added to the baseline once, so an update doesn't block your
  own VPN or similar.
- **Fix: the cache of signature results couldn't notice a swap.** Replace a signed
  executable with an unsigned one and restore only its modification time, and the old
  "signed" answer was returned. Change time, size and inode are now compared as well.
- **Change: faster listener lookup, scanning every 2 seconds.** Listeners are read through
  libproc without starting a process (about 2.4 ms, against about 16 ms for `lsof`). It
  falls back to `lsof` only if libproc returns nothing.
- **Change: stronger port-scan and unknown-port detection.** Memory no longer grows under a
  flood of spoofed sources; listening ports count 1/8 as much as closed ones, cutting false
  positives; a 24-hour window catches slow scans. Binds to a non-wildcard LAN address,
  listeners run from temporary folders, and changed or broken signatures are flagged. UDP
  listeners from interpreters or unsigned programs are reported (notification only).

## 1.9.44 - 1.9.47

- **Broadened active vulnerability checks** (1.9.44): the manual active scan now also detects
  unauthenticated Elasticsearch, CouchDB, Jenkins and VNC services, plus SMBv1 being enabled and
  SMB signing not being required on `smbd`.
- **Hardened incoming port-scan detection's reliability** (1.9.45-1.9.47): fixed the auto-block
  being abusable via a forged SYN claiming the gateway's address (the block now only refuses new
  TCP connections, and the gateway, DNS resolvers and the Mac's own addresses are exempt), fixed
  detection stopping right after startup (`pflog0` was not created automatically), and fixed a
  flood of forged SYNs being able to fill pf's state table. Also adds a notification when
  detection is saturated and fixes a paired Sensor's audit being incorrectly blocked.

## 1.9.33 - 1.9.43

- **RoamSwitch Sensor integration reworked** (1.9.33 to 1.9.37): pairing moved from
  mDNS to a pairing code. You can request an active vulnerability audit from a Sensor
  and fetch the result later, and the MCP tool `get_sensor_audit_results` was added. A
  serious bug that crashed the privileged helper on every successful pairing (a
  deadlock from a re-entrant lock) was fixed. Results can be shown and exported down
  to open ports, NSE output, confirmed-safe checks and detailed descriptions.
- **The nmap NSE supplementary scan is always on** (1.9.33). Automatic update checks
  for the CVE maps run monthly (1.9.34).
- **Update-related fixes** (1.9.34, 1.9.35, 1.9.42, 1.9.43): the privileged helper is
  now reliably restarted on update. The burst of warning notifications right after an
  update was fixed with automatic retries of transient connection drops and throttling
  of same-kind warnings, and a false "/etc/hosts tampered" warning right after an
  update was fixed. Update prompts that were easy to miss in a menu-bar app now bring
  the app to the front.
- **Incoming port-scan detection fixes** (1.9.35, 1.9.38): the log feature being
  disabled by a pf reload while `tcpdump` retried forever and burned helper resources,
  and a failure to enable detection never reaching the user.
- **Shared-service stop/restore fix** (1.9.38): `launchctl` exit codes were never
  checked, so failures were reported as success.
- **UI fixes** (1.9.37, 1.9.39 to 1.9.41): CSV column headers in 10 languages, the
  package CVE tabs overflowing so the last tab couldn't be opened, the security-log
  filter not looking scrollable, and the active-scan tests writing fake results into
  the real scan log.

## 1.9.27 - 1.9.32

- **Expanded npm/pnpm-install supply-chain risk coverage** (1.9.28–1.9.30,
  Pro): following dependency-lockfile tamper monitoring, install-script
  inventory, and npm signature/provenance verification, added a
  `roamswitch-npm` wrapper that actually runs installs inside a
  network-denied sandbox, plus edit-distance typosquat detection (e.g.
  `expres`→`express`). Detection of leaked crypto-wallet seed phrases and
  private keys (BIP39/WIF/BIP32, checksum-verified) also shipped in 1.9.27.
- **Added: RoamSwitch Sensor pairing and incoming port scan detection**
  (1.9.32, Pro): mDNS mutual-trust pairing with the separate RoamSwitch
  Sensor product for active vulnerability audits, plus automatic
  detection and 10-minute blocking of nmap/masscan-style reconnaissance.
  Also added CSV export for notification history, package CVE scan, and
  active vulnerability scan logs.
- **Fixed:** a log-audit frequency-spike notification couldn't be
  corroborated right after it fired (1.9.31); the secret leak auditor
  missed Google AI Studio's new API key format (1.9.32).
- **Improved:** the automatic log audit's "new pattern" detection no
  longer pops a Notification Center alert every time (1.9.32) — a batch
  with a frequency spike still alerts, new-patterns-only batches are
  recorded to history without a popup.

## 1.9.16 - 1.9.26

- **Added: Critical Path FIM, a background tamper-detection guard for
  critical system files** (Pro, 1.9.16): SHA-256 baseline monitoring of
  low-churn paths (`/etc/sudoers`, SSH config, `/etc/hosts`, root's
  `authorized_keys`) that no routine OS update or Homebrew install ever
  touches.
- **Important: fixed four security items that reported success without
  confirming anything actually happened** (1.9.19): automatic dev-server
  port blocking, malware-quarantine file moves, the Security Dashboard's
  "macOS Accessory Connection Protection" check (previously hardcoded
  `isPassed: true`), and Critical Path FIM's helper-connection failures
  now all reflect the real outcome instead of an assumed one.
- **Fixed a wide range of Log Audit false positives** (1.9.16 - 1.9.22):
  CoreAudio HAL traces, loginwindow's `Application`/`ApplicationManager`
  bookkeeping (replaced with a class-level structural rule), a root-cause
  template-masking bug shared with the Linux edition, lock-screen
  wallpaper-rendering and sleep/wake internals, and `0x`-prefixed pointer
  addresses that the masking regex couldn't catch.
- **Improved: Log Audit's anomaly notification, previously just a raw
  template string and z-score, now explains in plain language whether
  action is needed** (1.9.23), and template anomalies are now shown and
  searchable in the Log Audit window itself instead of only a KPI-card
  count.
- **Fixed: the Wi-Fi radio killed during an automatic Air-Gap didn't come
  back on its own after an app crash or Mac restart** (1.9.23) — folded
  into the same pf air-gap state so the independent AirGapFailsafe
  watchdog covers restoring Wi-Fi too, verified live within the 10-minute
  bound.
- **Added: newly-detected template anomalies are now persisted to
  notification history** (1.9.24), and the KPI cards on the Log Audit
  window became clickable (previously purely decorative).
- **Improved: EICAR test-signature hits no longer raise a notification**
  (1.9.25) — recorded to history only, so a real threat alert isn't
  buried among no-action ones.
- **Fixed: Link Guard's homograph detection and the Ransomware Canary
  Guard's MITRE ATT&CK ID were both comparing translated display strings
  instead of a language-independent value, silently breaking in most
  non-JA/EN/FR languages** (1.9.26). Also brought the MCP server, SDK,
  Help & Guide, and built-in knowledge base up to date with current
  features across all 10 languages, and fixed some regional locales
  (e.g. pt-BR) falling back to Japanese.

## 1.9.13 - 1.9.15

- **Resolved false positives and duplicate notifications around Automatic
  Log Audit (1.9.10)**: the kickoff scan right after enabling now learns
  silently instead of notifying; a transient pasteboard-server hiccup
  (`CFPasteboardRef`) and AppKit's internal focus-change KVO notification
  (`firstResponder changed`) were added to the exclusion list; overlapping
  scan windows no longer re-flag the same event.
- **Resolved login/logout false positives** from macOS's internal
  `PersistentAppsSupport`/`BTMManager` events.
- **Improved notification bodies**: now show a "N new patterns, K
  frequency spikes" breakdown plus readable example log lines.

## 1.9.6 - 1.9.12

- **Added detection of ClickFix-style malicious commands on the
  clipboard**, including the Script Editor pivot used to dodge Terminal's
  history-based detection.
- **Added notification history (keeps the past 7 days)**.
- **Added Automatic Log Audit (Pro)**: scans in the background every hour
  and notifies on new patterns or frequency spikes (on by default for
  Pro).
- **Redesigned the log audit's frequency-spike detection to compare each
  template against its own history**, resolving repeated false positives
  from legitimate recurring jobs.
- **Fixed two Automatic Log Audit notification strings missing
  translations**.

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
