# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch Sensor

A dedicated node placed on the LAN: mDNS mutual-trust pairing with
RoamSwitch-equipped endpoints (Mac / Linux Client / Server Edition) for
active vulnerability audits, plus detection of new devices and spoofing on
the LAN. Still under development — see
<https://lafine.net/roamswitch-sensor-manual.html> for current status and
setup instructions.

### 0.1.0 (initial release)

- **Added: deb/rpm package distribution.** Runs as a systemd service
  (`roamswitch-sensor.service`) instead of the earlier verification-only
  Docker build.
- **Added: passive LAN visibility extension (opt-in).** When
  `ROAMSWITCH_SENSOR_PASSIVE_CAPTURE_IFACE` names an interface, Sensor
  observes raw Ethernet/IPv4 headers on it (no payload inspection) to
  detect new devices it has never directly communicated with, and flag
  contact with known-malicious IPs from the local threat feed. Works on a
  single NIC for broadcast/multicast-visible traffic; a switch mirror
  (SPAN) port or inline transparent bridge is needed to see general
  unicast traffic between two other hosts.
- **Fixed: the TUI's discover ('d') key looked unresponsive.** The IPC
  call ran synchronously on the UI thread, so nothing redrew while it was
  in flight. Moved to a background thread with a live elapsed-time status
  line, and the TUI now also auto-discovers once on launch.

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.9.56

- **Added: guard against the investigation agent recursively triggering
  itself.** The agent's own research activity (e.g. `grep`/`cat` scanning
  logs and config files) could itself get flagged as a new eBPF/FIM
  incident, spawning another investigation agent to look into the first
  agent's own activity, and so on — reproduced live (a `grep` run while
  investigating a `pkexec` alert triggered a fresh "Read sensitive file
  untrusted" detection against `/etc/pam.conf`). Now tracks the PID of any
  currently-running investigation-agent process; a new detection whose
  target process is a descendant of one skips spawning a second agent
  (the first-pass triage and its notification are unaffected).

### 1.9.55

- **Fixed: redesigned the investigation-agent handoff's `sudo` wrap.** The
  previous fix (1.9.54) baked both the PATH resolution and the `sudo`
  delegation directly into the `command`/`args` fields, which meant
  re-running the wizard could no longer recognize a saved preset
  (claude/agy/codex/opencode), always fell back to the custom-entry
  path, and — if confirmed as-is — wrapped an already-wrapped command a
  second time, breaking it (reproduced live). A new `run_as` field now
  holds the operator's username, and the `sudo` wrap is applied by the
  daemon at spawn time instead; `command`/`args` stay the tool's own
  clean invocation.
- **Added: extended the investigation-agent handoff to the Resource
  Exhaustion / Process Anomaly Guard too.** Previously wired into eBPF,
  Critical-Path FIM, and lockfile FIM only; now also covers sustained
  memory growth, sustained high CPU usage, crash loops, zombie-process
  growth, and rising system load.

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

### 1.9.27 - 1.9.38

- **Critical fix (1.9.31, Server Edition):** the Default-Deny firewall
  policy was blocking 100% of Docker containers' outbound traffic (the
  `forward` chain had no accept rule at all).
- **Added (1.9.37-1.9.38):** four features addressing npm-install
  supply-chain risk — Lockfile FIM, an install-script inventory, npm
  signature verification, and bubblewrap-sandboxed lifecycle-script
  execution. Pro-only.
- **Added (1.9.36):** the secret-leak auditor now detects cryptocurrency
  wallet seed phrases and private keys (checksum-verified, values never
  shown).
- **Added (1.9.34):** brought MCP/SDK/in-app Help fully up to date with
  current features, and localized URL-safety/secret-leak/log-audit
  results into all 10 languages (previously Japanese-only).
- **Fixed (1.9.32):** no way existed to release a process frozen by a
  false positive; duplicate notifications (every entry shown twice).
- **Improved (1.9.29-1.9.33):** clearer Log Audit anomaly notifications,
  an "Allow" action on port-anomaly-guard blocks, EICAR hits no longer
  raise a notification.
- **Fixed (1.9.27):** Log Audit's masking missed `0x`-prefixed addresses.

### 1.9.16 - 1.9.26

- **Added: Critical Path FIM (tamper detection) now also runs
  automatically in the background on the client edition** (1.9.17),
  bringing the same event-driven fanotify watch plus periodic backstop
  scan that was previously Server Edition-only.
- **Important: fixed a root-cause bug in Log Audit's template-masking
  regex** (1.9.18) — digits adjacent to a letter weren't masked at all, so
  timestamp differences alone kept re-flagging the same line as a "new
  pattern" forever. Verified against a live production server's 691
  learned templates collapsing to 285 (58.8%) once fixed.
- **Important: fixed Client-Edition-only commands returning fabricated
  information on Server Edition, and several security actions reporting
  success without confirming anything actually happened** (1.9.19) —
  `emergency-restore`, kernel/mount hardening, and `roamswitch airgap`
  among others now wait for and check the real result before claiming
  success.
- **Added: Resource Exhaustion / Process Anomaly Guard (Server Edition
  only)** (1.9.20 - 1.9.22): detects memory-exhaustion DoS, use-after-free
  crash loops, sustained zombie-process growth, and system-load growth,
  correlated against eBPF Runtime Guard / Critical Path FIM events for a
  confidence tier. The same window also fixed a notification-history gap
  affecting 26 of 28 client daemon call sites, a DOCKER-USER chain
  startup-order race, and 7 false-verdict bugs in the 28-item security
  audit.
- **Fixed a wide range of Log Audit and ransomware-detection false
  positives** (1.9.20 - 1.9.25): `cp`/`mv`/`pip` ransomware false-freezes,
  routine noise from anacron/tailscaled/cron sessions and more,
  generalized AppArmor-profile matching, Log Audit re-detecting its own
  past alerts as new patterns forever, and the ransomware allowlist not
  applying to already-exited short-lived processes.
- **Fixed: ARP-spoofing detection false-flagging Docker bridge-internal
  IPs** (1.9.24), plus the GUI's notification-history tab never updating
  on its own.
- **Important: fixed `audit-secrets`'s recursive directory scan recursing
  forever through a symlink cycle**, pinning a live host at ~96% CPU for
  over 95 minutes (1.9.26). Switched to the lstat-based
  `DirEntry::file_type()`, which never follows symlinks.

### 1.9.6 - 1.9.15

- **Added the log audit's background schedule to the client daemon too**:
  resolves the asymmetry where only Server Edition ran it automatically.
- **Added notification history (keeps the past 7 days)**: available via
  `roamswitch notifications`, the GUI, MCP, and the SDK.
- **Added detection of ClickFix-style malicious commands on the
  clipboard**.
- **Resolved many log-audit false positives**: excluded the daemon's own
  startup banner and self-narration, snapd/gnome-shell OS noise, and
  Ollama's/Ubuntu Pro's own routine logging. Replaced the one-by-one
  enumeration of systemd unit-lifecycle lines with a structural check
  instead (the sending process is genuinely systemd itself, verified via
  journald's kernel-tied credentials, and the message matches systemd's
  own fixed phrasing) so a not-yet-catalogued service is covered
  automatically.
- **Resolved duplicate notifications and lost learning progress** from an
  old/new process race on daemon restart, and from overlapping scan
  windows re-flagging the same event.
- **Fixed notification history appearing empty from a regular user's
  CLI** (a location mismatch with the root-privileged daemon).
- **Improved notification bodies**: now show a "N new patterns, K
  frequency spikes" breakdown plus readable example log lines.

### 1.9.0 - 1.9.5

- **Added an Evil-Twin SSID warning** learned from past {SSID, gateway
  MAC} history, **keystroke-timing anomaly detection for the BadUSB
  keyboard guard**, **blast-radius evidence for Ransomware Canary
  detections**, and **JA3 TLS-fingerprint matching groundwork for Link
  Guard**.
- **Redesigned the log audit's frequency-spike detection to compare each
  template against its own history**, resolving repeated false positives
  from legitimate recurring jobs and `apt upgrade` bursts.
- **Fixed `upower.service`'s crash-restart loop** and **package-upgrade
  bursts** each being misreported as a log-audit anomaly.
- **Fixed Link Guard's NFQUEUE worker needlessly crashing and
  reinstalling its nftables table** on ordinary packet bursts.

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
  operations manual documents is now real and functional: a Docker-bypass
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
  socket only, no TLS, no new listening port) on both editions.
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

### 1.0.31 - 1.0.66

- **Streamlined update UX**: a manual "check for updates" button with a
  progress spinner, a single status card for updates, an upgrade button
  shown only when a newer version is actually available, and the app
  restarting itself automatically after a package upgrade.
- **Native multi-distribution package manager support**: Fedora/RHEL
  (`dnf`), openSUSE (`zypper`), and Arch Linux (`pacman`/AUR) upgrade
  instructions now appear natively alongside Debian/Ubuntu (`apt`),
  across all 10 languages.
- **Strict Daemon IPC Authentication & Quarantine Vault Hardening**: kernel-level peer credential validation (`SO_PEERCRED`), symlink traversal prevention, canonical path validation against privilege escalation / arbitrary deletion, and WireGuard argument sanitization.
- **Diagnostic Calibration & SBC / Raspberry Pi Optimization**: enforced unattended security upgrade checks, recognized non-UEFI SBC architectures without false negatives, and expanded SSH split configuration analysis.
- **Fully Asynchronous UI Threading**: GNOME / KDE / XFCE / Wayland desktop
  integration, and hardware radio restoration & Air-Gap resilience.
- **Overhauled ARP Spoofing Detection and Mitigation**: combined spatial
  and temporal difference detection, prevented latching of unverified
  gateway MACs, and added per-item "Fix" buttons in the Security Audit tab.

### 1.0.1 - 1.0.30

- **Core defense capabilities**: VPN tunnels (WireGuard/Tailscale) with a
  killswitch, Port Anomaly Guard (auto-blocking unknown listening ports),
  passive link protection, daily threat feed updater, BadUSB keyboard /
  USB storage authorization dialogs, and automatic sharing-service
  control (SSH, Samba).
- **Refined detection thresholds**: calibrated ransomware entropy
  thresholds (20 files in 5s with entropy >= 7.92), and proactive gateway
  ARP pinning.
- **UI and desktop integration**: fully asynchronous UI threading,
  dynamic taskbar/tray icon updates, and Tailscale/WireGuard hardening.
- **Setup and distribution**: initial setup wizard and official signed
  repositories for apt, dnf, and zypper.

### 1.0.0

- Initial Linux release. Ported RoamSwitch zero-trust networking architecture to Linux (systemd + nftables), featuring autonomous network profile switching, ransomware behavior detection, emergency Air-Gap isolation, 20-item health audits, and embedded read-only MCP server.

---

## RoamSwitch for Mac

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

## 1.9.0 - 1.9.5

- **Added Active Vulnerability Scan and Package CVE Scan** (ported from
  the Linux edition, off by default).
- **Closed gaps in the MCP server**: secret-leak scanning, log auditing,
  quarantine listing, canary status, and Air-Gap-trigger incident history
  are all reachable via MCP now.
- **Added an Evil-Twin SSID warning**, **keystroke-timing anomaly
  detection for Bad USB**, and **JA3 TLS-fingerprint matching groundwork
  for Link Guard**.
- **Improved the Download Guard's static-signature detection with a
  ClamAV second opinion**.
- **Fixed repeated false Air-Gap re-triggers right after a Ransomware
  Canary release**, even with no decoy file actually tampered with.
- **Important: fixed a bug that could crash the MCP server under certain
  conditions**: the localized-string cache wasn't safe for concurrent
  access.

## 1.8.4 - 1.8.9

- **Added static-signature detection for downloads, ClickFix protection
  (off by default), and a Docker risk detection guard (off by default)**:
  EICAR/reverse-shell one-liner detection, an emergency lockdown on
  suspicious Terminal commands, and container-escape configuration alerts.
- **Added automatic Air-Gap isolation tied to Apple XProtect detections**
  (Pro, on by default). Redesigned the air-gap failsafe as a fully
  independent watchdog daemon so its lockdown deadline lifts reliably even
  if the helper process crashes.
  *(Special thanks to [Super Funicular](https://dev.to/superfunicular) for raising the edge-case inquiry during our discussion on [Dev.to](https://dev.to/superfunicular/turn-an-old-android-phone-into-a-screen-off-security-camera-no-cloud-lan-only-5cll).)*
- **The secret/API-key leak auditor can now scan a whole folder**.
- **Link Guard's "warn" mode now fails closed**, with a shorter hold
  window (25s -> 8s); hardened the privileged helper's code-signature
  verification and pre-execution checks for external binaries.
- **Isolated local port audit probes with ephemeral, sandboxed cookie
  storage**, preventing credential leakage and session contamination.
- Several minor fixes in this span too: dialog rendering glitches, 92
  missing translations, and a helper version-sync bug.

## 1.8.0 - 1.8.3

- **Topmost Emergency Alert Overlays**: threat confirmation dialogs (BadUSB, ransomware, ARP spoofing, link hold) display as topmost overlays across all macOS spaces and full-screen apps.
- **Direct Health Audit Remediation**: added per-item remediation buttons to immediately enable internal guards or open relevant macOS System Settings panes with automatic re-evaluation.
- **Malware Scanner False-Positive Mitigation**: benign EICAR test strings trigger informational notices rather than quarantine (matching Linux behavior).
- **Enhanced Link Guard via Content Filter**: outbound connection inspection post-DNS (blocking phishing across DoH/DoT and TLS SNI) and interactive foreground warning panels with safe defaults.
- **Dual VPN Backend Support**: added Tailscale Exit Node integration alongside WireGuard tunnels.

## 1.6.0 - 1.7.6

- **Integrated VPN Killswitch**: automatic WireGuard tunnels with packet-level killswitch enforcement on untrusted networks.
- **Proactive Gateway ARP/NDP Pinning**: hardens local neighbor tables on untrusted networks to prevent MITM attacks before they happen.
- **BadUSB Physical Keyboard Guard** and **non-destructive USB storage prompts** (mount unapproved drives read-only, with granular choices).
- **Passive Link Guard**: real-time outbound filtering against phishing and scam domains.
- **Canary baseline persistence** (decoy file hashes saved to disk for strict tamper detection) and **Quarantine Vault hardening** (`chmod 000` on quarantined files).

## 1.4.0 - 1.5.9

- **Local AI / LLM server protection**: automated exposure detection and blocking for Ollama, LM Studio, Gradio, and vLLM on `0.0.0.0`.
- **Clipboard secret protection**: real-time on-device regex scanning for exposed API keys and private keys.
- **Open Source MCP Server**: released a read-only MCP server and heuristics on GitHub.
- **Web & Mail triple protection**, **privileged helper hardening**, and **a crash watchdog** with autonomous auto-recovery.

## 1.0.0 - 1.3.0

- **Initial Releases**: autonomous network environment detection by gateway MAC, automatic firewall/sharing service profile switching, port anomaly blocking, ARP spoof auto-containment, and foundational MCP integration.
