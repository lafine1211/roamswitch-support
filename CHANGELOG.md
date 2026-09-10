# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.9.11

- **Fix: overlapping scan windows re-flagged the same event repeatedly**
  (paired with the Mac edition). The audit window deliberately overlaps
  the previous scheduled run's (to avoid missing anything at the
  boundary), so the same historical event (say, one `apt upgrade`) kept
  getting re-counted and re-alerted for as long as it stayed inside the
  "past 1 hour" window (confirmed live: the same 10 lines paged twice, 5
  minutes apart, on the production server). Now remembers the last
  processed line and only scores genuinely new lines next time; display
  stats still reflect the full requested window as before.

### 1.9.10

- **Fix: server daemon restart banner lines triggered false positives.**
  Unconditional startup lines (Docker protection enabling, kernel sysctl
  hardening, default-deny policy application, the startup message itself)
  were flagged as "new pattern" on every restart. Since restarts only
  happen on upgrade, this could have taken months to fully learn. Added to
  the exclusion list.

### 1.9.9

- **Fix: notification history (`roamswitch notifications`) was effectively
  always empty.** A daemon running as root (client or server edition)
  records notifications to `/var/lib/roamswitch/`, but running the CLI as a
  regular user only ever read `~/.config/roamswitch/`, so daemon-originated
  notifications (log-audit anomalies, ransomware detections, essentially
  everything that matters) never showed up. Reading now merges both
  locations.
- **Fix: two log-audit false positives.** The server daemon's own routine
  logging (FIM's periodic "all clear" sweep, the egress guard's periodic
  blocklist reload) and snapd's package-update churn weren't in the
  benign-noise exclusion list, so a freshly-rebuilt baseline flooded with
  "new pattern" hits for both. Added to the exclusion list.
- **Improved: notification readability.** Notifications now lead with the
  actual, unmasked log line instead of our internal masked (`<NUM>`, etc.)
  template string, and show a one-line breakdown ("N new patterns, K
  frequency spikes") up front (server and client both).

### 1.9.8

- **Improved: the log audit (new-pattern / frequency-anomaly detection) now
  runs on a background schedule in the client edition too**. Previously the
  frequency-anomaly baseline (each template's historical frequency) never
  learned anything unless a user manually ran `roamswitch audit-logs` or an
  AI agent called it via MCP. Server Edition already ran this in the
  background; the client edition just sat idle instead. The client daemon
  now runs the same scheduler Server Edition already had (every 1800
  seconds by default, can be disabled), sending a desktop notification when
  it finds something.

### 1.9.7

- **New: notification history (keeps the past 7 days)**. Adds a way to look
  back through the notifications RoamSwitch has sent (log-audit anomalies,
  ClickFix detections, and the like). Previously a desktop notification
  just vanished once it was shown, with no way to check "wait, what did
  that notification a minute ago actually say." Available via the
  `roamswitch notifications` command, a new "Notifications" tab in the GUI
  app, the MCP tool `get_notification_history`, and the SDK
  (roamswitchkit)'s `notification_history()` method. Entries older than
  the retention window are pruned automatically.

### 1.9.6

- **New: detects ClickFix-style malicious commands on the clipboard**
  (paired with the Mac edition). Addresses a scam technique (ClickFix)
  where a fake ad or CAPTCHA page, reached by searching for a name like
  "ChatGPT," tells the victim to paste a "verification code" that's
  actually a malicious command into the GNOME/KDE run dialog or similar.
  The Linux edition previously had no defense of this kind at all (no
  shell-history watcher, no clipboard monitor). Polls the clipboard via
  `gtk::Clipboard` (works transparently across both X11 and Wayland) and
  warns at copy-time, so it catches the paste destination uniformly
  whether it's a terminal, the GNOME/KDE run dialog, or anywhere else.

### 1.9.5

- **Improved: Log Audit alerts now show a template's learning progress**.
  A template flagged as a "frequency spike" gave no way to tell whether it
  was only judged provisionally by the cross-template fallback (its own
  frequency history is still under 3 observations), or whether it has
  actually deviated from an already-established baseline of its own. When
  applicable, both the notification and `roamswitch audit-logs` now note,
  per anomaly line, that its baseline is still learning (N of 3
  observations so far) and expected to stop paging on its own once
  learned.

### 1.9.4

- **Important: fixed the Server Edition Log Audit's baseline (known
  patterns, frequency history) never actually persisting**.
  `roamswitch-server.service` runs as `User=root` (so `$HOME` is `/root`)
  inside a systemd sandbox (`ProtectHome=read-only` +
  `ProtectSystem=strict`) that only permits writes to `/etc/roamswitch`,
  `/var/lib/roamswitch`, and `/run/roamswitch`. The Log Audit baseline file
  was designed to live under `~/.config/roamswitch/` (i.e.
  `/root/.config/roamswitch/`), so every write from the daemon silently
  failed. Neither "new pattern" detection nor the per-template frequency
  history added in 1.9.3 could ever actually learn anything, so a user's
  own legitimate recurring job kept re-triggering a "frequency spike" no
  matter how many days it had already been running. When running as root,
  the baseline now lives under `/var/lib/roamswitch/`, the same location
  already used by the other state files. Manual invocation via the CLI,
  GUI, or MCP (as a non-root user) is unaffected.

### 1.9.3

- **Improved: the Log Audit's frequency-spike detection now compares each
  template against its own history** (paired with the Mac edition): the
  previous Z-score was only a comparison against other templates seen
  within the same scan window, with no per-template frequency history kept
  at all. A user's own legitimate cron job, or a burst of `sudo`/`systemctl
  reload` activity from an `apt upgrade`, could therefore keep
  re-triggering a "frequency spike" every single day, no matter how long
  it had been running (several repeat alerts on the same host on
  2026-09-10). Each template's historical occurrence count is now learned
  and persisted, and once a pattern has been observed consistently enough
  (3 times), it's judged against that history instead. A template still
  building up history falls back to the previous cross-template
  comparison, so detection of a genuinely new pattern is unchanged.
- **Improved: the daily updater timer switched from a fixed time of day to
  a boot-relative interval**: the `systemd` timer previously used
  `OnCalendar=daily` (a fixed time, defaulting to just after midnight), so
  a host that's only powered on during certain hours (e.g. a laptop run
  only during the day) could go indefinitely without ever hitting that
  slot. `Persistent=` only covers missed `OnCalendar=` elapses, not this
  case, so the timer now uses `OnBootSec=`/`OnUnitActiveSec=` instead,
  which fires reliably every day regardless of the host's actual uptime
  hours.

### 1.9.2

- **Improved: Log Audit alerts now include a package-manager correlation
  hint**: an `apt`/`dnf`/`zypper`/`pacman` upgrade can trigger a burst of
  `sudo` sessions and `systemctl daemon-reload` calls from its own
  postinst/trigger scripts, which the frequency-spike detector could
  misreport as an anomaly. The template text alone gave no way to tell
  that apart from an actual attack (discovered right after the v1.9.1
  upgrade itself triggered exactly this). If a package-manager log file
  (e.g. `dpkg.log`) was touched during the scanned window, both the
  Server Edition notification and `roamswitch audit-logs` now note that
  package-management activity coincided with the alert. The anomaly
  itself is still detected and reported as before; this only adds
  context, and it never suppresses a real spike, so a genuine unauthorized
  `sudo` escalation is still flagged.

### 1.9.1

- **Fixed: `upower.service` crash-restart loop from a conflict with the
  Server Edition's user-namespace hardening, which false-triggered the
  log-audit anomaly detector**: Server Edition permanently sets
  `user.max_user_namespaces=0` to close off a privilege-escalation attack
  surface, but `upower.service` (the power-management daemon) requests
  `PrivateUsers=yes` (its own private user namespace) to start. On laptop
  hardware the two collided: namespace creation was refused and the unit
  kept failing to start. The log-audit frequency-spike detector was
  misreporting this known-benign noise as a new anomaly; that false
  positive is now suppressed. `upower.service` itself (battery status,
  etc.) is unaffected.

### 1.9.0

- **New: SSID/gateway history learning with an Evil-Twin SSID warning**:
  Learns the {SSID, gateway MAC} pairs of networks you've connected to
  before, and warns when connecting to an unknown SSID whose name is a
  near-miss (edit-distance) for one already known — e.g. "Airport_WiFi"
  vs. "Airport_WlFi".
- **New: keystroke-timing anomaly detection for the BadUSB keyboard guard
  (advisory signal)**: While a keyboard is held blocked pending approval,
  its keystroke timing (mean interval + coefficient of variation) is
  analyzed for the near-constant, unnaturally uniform pattern typical of
  a scripted injection attack (Rubber Ducky and similar BadUSB tools).
  When detected, the approval notification gets stronger wording — the
  existing block/approve flow itself is unaffected. Holding a key down
  (OS autorepeat) is correctly excluded, not miscounted as a fast burst.
- **New: blast-radius evidence for Ransomware Canary detections**: On a
  hit, the number of other files changed in the watched directories
  within the last 60 seconds is now recorded and appended to the
  notification. A wide blast radius is strong evidence of a live
  encryption attack; a narrow one is the profile of most false positives
  — quicker evidence for deciding whether to release containment. Shared
  by the Server Edition canary engine, so this applies there too.
- **New: JA3 TLS-client fingerprint matching for Link Guard traffic
  classification (mechanism only)**: Adds matching against a feed of
  known-malicious JA3 fingerprints (a hash computed from the TLS
  ClientHello), extracted in the same single pass over the ClientHello
  bytes already used for SNI — negligible added cost. No feed data is
  shipped yet, so this cannot produce a real hit today.
- **Fixed: Link Guard's NFQUEUE worker crashed and needlessly reinstalled
  its nftables table on ordinary packet bursts**: When several packets
  from the same connection arrived within a short burst, the kernel could
  already resolve an earlier packet via the rule's `bypass` (fail-open)
  flag before the daemon's verdict for it arrived, and would answer that
  now-stale verdict with `NLMSG_ERROR(ENOENT)`. The packet itself was
  already safely resolved either way, but this was previously treated as
  a fatal queue error, tearing down and reinstalling the whole table.
  Connectivity was never actually affected (the same `bypass` fail-open
  design already covers that), but this eliminated the needless
  reinstall churn and error-log noise.

### 1.4.1 - 1.8.0

- **Added Package CVE Scan**: matches installed OS packages (dpkg/pacman/
  dnf/zypper) and 7 language-ecosystem dependencies (npm/PyPI/crates.io,
  etc.) against a locally-held known-CVE map. No network activity at all
  (1.5.0).
- **Added Log Audit template anomaly detection + automatic secret
  masking**: flags previously-unseen patterns and frequency spikes
  (Z-score), and masks API keys etc. in log lines across both the
  clipboard-copy path and the raw JSON an MCP client receives (1.6.0).
- **Exposed incident history for the three guards behind an Air-Gap
  trigger (eBPF Runtime Guard / Port Anomaly / Ransomware Canary) via
  MCP and the CLI**: trigger reasons are now queryable from outside the
  daemon process (1.7.0).
- **Added File Scan Guard, Docker risk detection, and container isolation
  posture auditing**; the secret/API-key leak scanner can now recursively
  scan a whole directory (1.4.1, 1.4.3).
- **Improved malware-detection notifications with a ClamAV second
  opinion**, lowering alert urgency on a false positive (1.8.0).
- **Important fixes**: an NFQUEUE queue jam that could take down network
  connectivity right after install (1.5.1), USB Zero-Trust leaving every
  non-storage device (mice, etc.) permanently unusable (1.5.3), known-CVE
  maps always reporting "not fetched" on their publish day (1.5.2), the
  RHEL/openSUSE package-CVE maps never actually publishing due to
  GitHub's file-size limit (1.5.2, 1.5.3), and `clamd` sitting resident
  using 1GB+ of RAM even when never used (1.5.4).

### 1.1.1 - 1.3.2

- **Server Edition configuration & documentation overhaul**: every setting the
  operations manual documents is now real and functional — a Docker-bypass
  protection toggle, an SSH-preservation toggle, an `isolate`/`freeze`/`alert_only`
  containment mode, a configurable eBPF socket path, and a new optional
  `guard.yaml` policy file for per-severity actions (with automatic escalation
  after a repeated incident and a safety timer that auto-restores an Air-Gap
  isolation if never acknowledged).
- **Event-driven File Integrity Monitoring**: tampering is now detected the
  instant a monitored file's write finishes, instead of waiting for the next
  periodic scan. Fedora/RHEL/openSUSE now get an automatic FIM baseline
  refresh after every package transaction, matching the existing Debian/Ubuntu hook.
- **Egress / C2 containment for servers**: a local malicious-IP blocklist and
  an optional DNS sinkhole (off by default, to avoid breaking servers that
  rely on internal DNS), plus ransomware canary decoys and permanent kernel
  hardening now running on Server Edition as well.
- **Tetragon sensor support**: the eBPF Runtime Guard can now use Cilium's
  Tetragon as an alternative to Falco (its native gRPC API, over a local UNIX
  socket only — no TLS, no new listening port) on both editions.
- **Safer autonomous containment**: a shared protected-process safety list
  (init, container runtimes, package managers, browsers, ...) now guards every
  place RoamSwitch can freeze or terminate a process, and per-process network
  isolation was corrected to target the process's real UID or container
  instead of a rule that could silently match nothing.
- **Client: safer Air-Gap recovery & adaptive detection**: the "release"
  action now terminates the offending process (when known) before lifting an
  Air-Gap isolation, instead of only lifting the network block. eBPF detection
  sensitivity now automatically tightens on an untrusted network and relaxes
  back on a trusted one.
- **Diagnostics and notifications cleanup**: shortened the "CVE-2026-53362"
  reference in the security health check to just "Frag Gap" for readability,
  and stopped showing a "protection profile switched" notification the moment
  the daemon settles into an already-known network right after startup.

### 1.1.0

- **Official Release of RoamSwitch Server Edition**:
  - Falco eBPF runtime threat detection and automatic container/process isolation via UNIX domain socket (`/var/run/roamswitch/events.sock`).
  - Critical Path File Integrity Monitoring (FIM with SHA-256 baseline) and automatic recovery.
  - 25-item server security health check (kernel parameters, Docker privileged containers/exposed socket, eBPF LSM, SYN cookies, empty password accounts, etc.).
  - Webhook (Slack, Discord, Microsoft Teams, Generic) and PagerDuty alert integrations.
- **MCP Server (`roamswitch-mcp`) Server Edition Support**:
  - Added optional `isServer: true` argument to `get_security_report` tool, enabling Claude and AI agents to query the 25-item server security posture.
- **SDK (`roamswitchkit` / Python `roamswitch`) Server Health Methods**:
  - Rust SDK: Added `client.server_security_report().await?`.
  - Python SDK: Added `client.server_security_report()` and `is_server` option in `client.security_report(is_server=True)`.
- **Extended CLI Server Management**:
  - Added `roamswitch status --server`, `roamswitch server [config|setup|test-notify|restart]`, `roamswitch fim [verify|update]`, and `roamswitch emergency-restore` commands.

### 1.0.63 - 1.0.66

- **Streamlined update UX**: added a manual "🔍 Check for updates" button with
  a progress spinner, consolidated the app-upgrade and threat-feed-update
  status into a single "Automatic Update Status" card that only surfaces an
  "⬆️ Upgrade now" prompt when a newer version is actually available, and the
  app now restarts itself automatically after a package upgrade.
- **Native multi-distribution package manager support**: Fedora/RHEL (`dnf`),
  openSUSE (`zypper`), and Arch Linux (`pacman` / AUR) upgrade instructions
  now appear natively alongside Debian/Ubuntu (`apt`), fully localized across
  all 10 languages with update-check timestamps.

### 1.0.50 - 1.0.62

- **Strict Daemon IPC Authentication & Quarantine Vault Hardening**: Implemented kernel-level peer credential validation (`SO_PEERCRED`), symlink traversal prevention, canonical path validation against privilege escalation / arbitrary deletion, and WireGuard argument sanitization.
- **Diagnostic Calibration & SBC / Raspberry Pi Optimization**: Enforced unattended security upgrade checks (`unattended-upgrades` / `dnf-automatic`), recognized non-UEFI SBC architectures without false negatives, improved `/tmp` and `/dev/shm` noexec verification, and expanded SSH split configuration analysis (`/etc/ssh/sshd_config.d/`).
- **UI Refresh & Streamlined Upgrades**: Replaced multi-button layouts with compact dropdowns (`ComboBoxText`) for languages and DNS profiles, broadened main window to 1100px, and unified update checks and installation under a single "Upgrade" view.
- **Hardware Radio Restoration & Air-Gap Resilience**: Strengthened physical radio restoration pipelines (rfkill, NetworkManager, BlueZ), enriched Air-Gap incident context and remediation options, automated recovery following ARP spoofing cessation, and reduced UI latency during lockdowns.

### 1.0.41 - 1.0.49

- **Overhauled ARP Spoofing Detection and Mitigation**: Introduced combined spatial and temporal difference detection, ensured sticky Air-Gap release during ongoing attacks, prevented latching of unverified gateway MACs, and added one-click block confirmation dialogs on balanced/trusted networks.
- **Individual Hardening and Accurate Health Checks**: Added per-item "Fix" buttons in the Security Audit tab, refined audit criteria to recognize intentional trusted-network behaviors (noexec / ARP pinning), and verified active fanotify runtime status.
- **UI and IPC Responsiveness**: Ensured security alert dialogs always appear on top and decoupled daemon IPC operations from the GTK main thread.

### 1.0.31 - 1.0.40

- **Enhanced Passive Link Guard**: Switched warning mode to fail-closed, shortened hold times to 8 seconds, and deduplicated notifications.
- **Malware and Ransomware False-Positive Prevention**: Exempted package managers (apt, dpkg, rpm), browser caches, and benign EICAR test strings from quarantine/blocking; added custom scan exclusion paths.
- **VPN / Tailscale Optimization**: Optimized Tailscale Exit Node sequencing and killswitch rules; refined layout margins and dropdown widths.
- **Expanded Localization**: Full translation coverage across all 10 supported languages (ja, en, zh-Hans, zh-Hant, ko, de, fr, es, it, pt).

### 1.0.21 - 1.0.30

- **Fully Asynchronous UI Threading**: Eliminated window freezing during profile switching and VPN connections.
- **Desktop Environment Integration**: Dynamic taskbar and system tray icon updates across GNOME, KDE, XFCE, and Wayland environments.
- **Tailscale and WireGuard Hardening**: Auto-detection of snap-installed Tailscale, argument resolution fallbacks, and streamlined VPN configuration UI.

### 1.0.11 - 1.0.20

- **VPN Tunnels and Killswitch**: Introduced automatic WireGuard and Tailscale Exit Node tunnels with packet-level killswitches on untrusted networks.
- **Refined Detection Thresholds**: Calibrated ransomware entropy thresholds (20 files in 5s with entropy >= 7.92), resolved Raspberry Pi OS packaging dependencies, and introduced proactive gateway ARP pinning.

### 1.0.1 - 1.0.10

- **Core Defense Capabilities**: Added Port Anomaly Guard (auto-blocking unknown listening ports), passive link protection, daily threat feed updater, BadUSB keyboard / USB storage authorization dialogs, and automatic sharing services control (SSH, Samba).
- **Setup and Distribution**: Introduced initial setup wizard and official signed repositories for apt, dnf, and zypper.

### 1.0.0

- Initial Linux release. Ported RoamSwitch zero-trust networking architecture to Linux (systemd + nftables), featuring autonomous network profile switching, ransomware behavior detection, emergency Air-Gap isolation, 20-item health audits, and embedded read-only MCP server.

---

## RoamSwitch for Mac

## 1.9.13

- **Fix: login/logout false positives.** macOS's internal
  `PersistentAppsSupport` (the reopen-apps-at-login feature) and
  `BTMManager` (Background Task Management) events were flagged as
  "frequency spike" despite having nothing to do with security (they're
  nearly absent the rest of the time, so the very next login produced an
  extreme z-score). Added to the exclusion list.

## 1.9.12

- **Fix: Automatic Log Audit notification body and a false positive**
  (paired with the Linux edition). The notification body was showing our
  internal masked template text twice; it now leads with the actual,
  readable log line and shows a one-line breakdown ("N new patterns, K
  frequency spikes") plus up to 3 examples. Also fixed: AppKit's internal
  focus-change KVO notification ("firstResponder changed") is harmless
  noise unrelated to security, but wasn't in the exclusion list, so a real
  notification once highlighted it as the unrelated representative
  example.

## 1.9.11

- **Fix: two Automatic Log Audit notification strings were missing
  translations.** The notification's title and body, added in 1.9.10,
  displayed in Japanese regardless of the selected language. Fixed.

## 1.9.10

- **New: Automatic Log Audit (Pro)** (paired with the Linux edition).
  Previously the Mac security log audit only ever ran when opened manually
  from the menu bar or called by an AI agent via MCP, so the frequency
  baseline (each log template's historical frequency) never learned
  anything for a user who never triggered it. Adds an option to scan in the
  background every hour and notify on new patterns or frequency spikes
  (menu bar → Malware Protection, on by default for Pro).

## 1.9.9

- **New: notification history (keeps the past 7 days)** (paired with the
  Linux edition). Adds a way to look back through the notifications
  RoamSwitch has sent (security log-audit anomalies, ClickFix detections,
  and the like). Previously a desktop notification just vanished once it
  was shown, with no way to check "wait, what did that notification a
  minute ago actually say." Available from the menu bar's "🔔 Notification
  History…" and the MCP tool `get_notification_history`. Entries older
  than the retention window are pruned automatically.

## 1.9.8

- **New: detects ClickFix-style malicious commands on the clipboard**.
  Addresses a scam technique (ClickFix) where a fake ad or CAPTCHA page,
  reached by searching for a name like "ChatGPT," tells the victim to
  open Spotlight and paste a "verification code" that's actually a
  malicious command. The existing ClickFix guard only watched terminal
  history (`~/.zsh_history`, `~/.bash_history`), so once attackers pivoted
  to Script Editor to dodge Terminal's multi-line-paste warning, it had no
  visibility at all (Script Editor writes to neither history file). The
  same detection logic is now wired into the clipboard monitor already
  running for API-key leak detection, so it warns at copy-time. This
  covers Terminal, Script Editor, Spotlight, or any other paste
  destination uniformly, since the check happens before the paste.

## 1.9.7

- **Improved: the "Copy AI Consultation Material" text now shows a
  template's learning progress** (paired with the Linux edition). A
  template flagged as a "frequency spike" gave no way to tell whether it
  was only judged provisionally by the cross-template fallback (its own
  frequency history is still under 3 observations), or whether it has
  actually deviated from an already-established baseline of its own.
  Affected anomaly lines now note that the baseline is still learning (N
  of 3 observations so far) and expected to stop appearing on its own once
  learned.

## 1.9.6

- **Improved: the Mac Security Log Audit's frequency-spike detection now
  compares each template against its own history** (paired with the Linux
  edition): the previous Z-score was only a comparison against other
  templates seen within the same scan window, with no per-template
  frequency history kept at all. A legitimate recurring job, or a burst of
  log lines from an OS component, could therefore keep re-triggering a
  "frequency spike" every single time, no matter how many times it had
  already happened. Each template's historical occurrence count is now
  learned and retained, and once a pattern has been observed consistently
  enough (3 times), it's judged against that history instead. A template
  still building up history falls back to the previous cross-template
  comparison, so detection of a genuinely new pattern is unchanged.

## 1.9.5

- **New: Wi-Fi history learning with an Evil Twin (SSID spoofing) warning**:
  RoamSwitch now learns the {SSID, gateway MAC} of networks you've
  previously connected to, and warns when an unfamiliar SSID is
  edit-distance-close to one you already trust (e.g. "Airport_WiFi" vs.
  "Airport_WlFi").
- **Improved: reduced ARP-spoofing false positives from legitimate network
  roaming**: when the gateway IP stays the same but its MAC address
  changes, the guard now treats it as a legitimate roam between two
  different networks (rather than spoofing) if the SSID changed at the
  same time — many routers reuse the same private IP (e.g. 192.168.1.1)
  across unrelated networks, which previously triggered false alarms.
- **New: keystroke-timing anomaly detection for Bad USB (auxiliary
  signal)**: input from a keyboard currently blocked as unauthorized is now
  analyzed for inter-keystroke timing; a pattern consistent with scripted
  input (as produced by Rubber-Ducky-style BadUSB attack devices) adds a
  warning to the notification text. Purely informational — the existing
  block/approve flow is unchanged.
- **New: JA3 TLS client-fingerprint matching for Link Guard traffic
  classification (groundwork only)**: added the matching machinery against
  known-malware JA3 fingerprints (a hash derived from the TLS ClientHello).
  No feed data is distributed yet, so this can't actually flag anything in
  practice today.
- **Improved: Log Audit's template anomaly detection no longer flags the
  burst of routine Gatekeeper assessment log lines a package manager
  update (Homebrew, etc.) can produce** (parity with the Linux edition).
- **Important: fixed a bug that could crash the MCP server under certain
  conditions**: the localized-string cache added in 1.9.3 wasn't safe for
  concurrent access from background queues. Some MCP tool calls (e.g.
  `get_exposed_ports`) could corrupt the cache's internal state and crash
  the server when multiple threads wrote to it at once. Fixed by adding
  proper locking.
- **Improved: the Download Guard's static-signature detection now gets a
  ClamAV second opinion**: when `StaticSignatureScanner` (a lightweight,
  hand-rolled heuristic) flagged a downloaded file as a threat, it was
  quarantined immediately with only the internal detection name shown to
  the user. The same file is now also scanned with ClamAV before that
  notification goes out; if ClamAV agrees, its detection name is included,
  and if it disagrees, the notification says so and points to the
  Quarantine Vault ("likely a false positive — check the contents and
  Restore if it looks fine"). The alert sound is softened from
  `defaultCritical` to `default` when ClamAV disagrees. Whether the file is
  quarantined, and the existing ability to restore a false positive, are
  both unchanged.

## 1.9.4

- **Fixed: releasing an Air-Gap isolation triggered by Ransomware Canary
  protection could repeatedly re-trigger false detections — and repeated
  network cutoffs — even though no decoy file had actually been tampered
  with**: depending on timing, the release-time self-heal (regenerating
  decoy files, then rebuilding the real-time file watchers) could itself
  produce a spurious detection event for a file that was never actually
  modified. Detections occurring in a brief grace window right after the
  watchers are rebuilt are now ignored, breaking this false-positive loop.

### 1.9.0 - 1.9.3

- **Added Active Vulnerability Scan and Package CVE Scan** (ported from
  the Linux edition, off by default): harmless read-only probes against
  local services, and dependency/OS-package matching against a known-CVE
  map. Network activity is receive-only and signature-verified (1.9.0).
- **Closed gaps in the MCP server**: secret-leak scanning, log auditing,
  quarantine listing, canary status, and incident history for the three
  guards behind an Air-Gap trigger are now all reachable via MCP (1.9.0,
  1.9.3).
- **Added Log Audit automatic secret masking + template anomaly
  detection** (parity with the Linux edition): masks API keys etc. across
  both the clipboard-copy path and the MCP response (1.9.2).
- **Important fixes**: known-CVE maps always reporting "not fetched" on
  their publish day (1.9.1, paired with Linux 1.5.2), an external keyboard
  already connected when the Bad USB guard was enabled never getting
  allow-listed (1.9.2), the Log Audit window freezing under the "All"
  filter (1.9.2), and the Runtime Threat Containment simulation path
  leaving incident detail missing from the MCP response (1.9.3).

### 1.8.4 - 1.8.9

- **Added static-signature detection for downloads, ClickFix protection
  (off by default), and a Docker risk detection guard (off by default)**:
  EICAR/reverse-shell one-liner detection, an emergency lockdown on
  suspicious Terminal commands, and container-escape configuration alerts
  (1.8.7, 1.8.9).
- **Added automatic Air-Gap isolation tied to Apple XProtect detections**
  (Pro, on by default). Redesigned the air-gap failsafe as a fully
  independent watchdog daemon so its lockdown deadline lifts reliably even
  if the helper process crashes (1.8.4 - 1.8.6).
- **The secret/API-key leak auditor can now scan a whole folder** (1.8.9).
- **Link Guard's "warn" mode now fails closed**, with a shorter hold
  window (25s → 8s); hardened the privileged helper's code-signature
  verification (dynamic `audit_token`) and pre-execution checks for
  external binaries (1.8.4 - 1.8.7).
- Several minor fixes in this span too: dialog rendering glitches, 92
  missing translations, and a helper version-sync bug.

- **Air-gap failsafe redesigned to be safe**: A fix to make sure the air-gap's
  10-minute network-lockdown deadline lifts on its own even if the helper
  process crashes mid-lockdown. The first attempt (1.8.5) used
  `KeepAlive.PathState` in the privileged helper's own LaunchDaemon plist,
  which occasionally caused the app to restart itself after a normal Quit —
  that was reverted and replaced (1.8.6) with a fully independent watchdog
  daemon that never touches the interactive helper's own launch
  configuration. It wakes on its own every 3 minutes, checks whether the
  deadline has passed, and — if so — restores the network and exits, with no
  way to interfere with a normal app quit. The underlying timestamp check
  was also hardened to stay correct across NTP corrections, manual clock
  changes, and right after a reboot, by pairing a monotonic uptime counter
  with the wall clock.
  *(Special thanks to [Super Funicular](https://dev.to/superfunicular) for raising the edge-case inquiry during our discussion on [Dev.to](https://dev.to/superfunicular/turn-an-old-android-phone-into-a-screen-off-security-camera-no-cloud-lan-only-5cll).)*
- **Automatic Air-Gap isolation tied to Apple XProtect detections**: Without
  requiring the EndpointSecurity entitlement, RoamSwitch now triggers an
  emergency network air-gap the moment Apple's own XProtect engine logs an
  actual malware detection/remediation (Pro, on by default). A simulation
  menu item was also added to verify the behavior safely.
- **Manual secret/API-key leak audit tool**: Paste any text to instantly
  audit it for leaked API keys and tokens, with line numbers, masked values,
  and per-type remediation advice.
- **Link Guard "warn" mode now fails closed**: An unanswered warn prompt
  used to let the connection through (fail-open); it now matches the Linux
  client and blocks it instead (fail-closed, not cached, so the next attempt
  re-prompts). The hold window was also shortened from 25s to 8s.
- **Ephemeral Cookie Separation in Port Security Audits**:
  Isolated HTTP probing routines to use ephemeral, sandboxed cookie storage during local port audits. Prevents credential leakage and cross-service session contamination between audit probes and user web sessions.
- **Dynamic XPC Code Signature Verification (audit_token)**:
  Enforced strict runtime validation of Apple Developer ID code signatures via `audit_token` on all XPC connections to `RoamSwitchHelper`, preventing unauthorized or injected processes from dispatching privileged tasks.
- **Pre-execution Permission Verification & Configuration Sanitization**:
  Added comprehensive file permission and ownership checks prior to spawning external helper binaries, and strengthened WireGuard configuration sanitization against argument injection.

### 1.8.0 - 1.8.3

- **Topmost Emergency Alert Overlays**: Threat confirmation dialogs (BadUSB, ransomware, ARP spoofing, link hold) display as topmost overlays across all macOS spaces and full-screen apps.
- **Direct Health Audit Remediation**: Added per-item remediation buttons to immediately enable internal guards or open relevant macOS System Settings panes with automatic re-evaluation.
- **Malware Scanner False-Positive Mitigation**: Benign EICAR test strings trigger informational notices rather than quarantine (matching Linux behavior).
- **Enhanced Link Guard via Content Filter**: Outbound connection inspection post-DNS (blocking phishing across DoH/DoT and TLS SNI) and interactive foreground warning panels with safe defaults.
- **Dual VPN Backend Support**: Added Tailscale Exit Node integration alongside WireGuard tunnels.

### 1.7.0 - 1.7.6

- **Integrated VPN Killswitch:** Introduced automatic WireGuard tunnels with packet-level killswitch enforcement on untrusted networks.
- **Proactive Gateway ARP/NDP Pinning:** Hardens local neighbor tables on untrusted networks to prevent MITM attacks before they happen.
- **BadUSB Physical Keyboard Guard:** Detects unauthorized external keyboards and hardware inject tools, dropping keystrokes until authorized.
- **Passive Link Guard:** Real-time outbound filtering against phishing and scam domains using zero-telemetry heuristics.
- **Non-destructive USB Storage Prompts:** Mounts unapproved drives read-only while offering granular read/write or eject choices.

### 1.6.0 - 1.6.4

- **Canary Baseline Persistence:** Persisted decoy file hashes to disk for strict tamper detection and reliable self-healing.
- **Quarantine Vault Hardening:** Fully revoked execution and read permissions (`chmod 000`) on quarantined files.
- **Port Anomaly Guard Cleanups:** Automated migration for legacy executable records and notification deduplication.

### 1.5.0 - 1.5.9

- **Local AI / LLM Server Protection:** Automated exposure detection and blocking for Ollama, LM Studio, Gradio, and vLLM on `0.0.0.0`.
- **Clipboard Secret Protection:** Real-time on-device regex scanning for exposed API keys and private keys.
- **ClamAV Quarantine Enhancements:** Closed bypass paths for `.tmp` extensions and direct terminal downloads (`curl`/`cp`).
- **Crash Watchdog:** Autonomous LaunchAgent monitor with exponential backoff auto-recovery.

### 1.4.0 - 1.4.8

- **Open Source MCP Server:** Released read-only MCP server and heuristics on GitHub; introduced `get_app_help` knowledge base search.
- **Web & Mail Triple Protection:** Implemented automated download scanning, DNS threat protection, and link safety diagnostics.
- **Privileged Helper Hardening:** Enforced `audit_token` validation and Team ID pinning against PID reuse attacks.

### 1.0.0 - 1.3.0

- **Initial Releases:** Autonomous network environment detection by gateway MAC, automatic firewall/sharing service profile switching, port anomaly blocking, ARP spoof auto-containment, and foundational MCP integration.
