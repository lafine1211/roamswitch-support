# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.9.17

- **Added: Critical Path FIM (tamper detection) now runs automatically in
  the background on the client edition too.** Previously FIM was
  Server-Edition-only, so a day-to-day client machine had no ongoing
  integrity monitoring at all if its root account got compromised (only a
  manual `roamswitch fim verify`). Added the same event-driven fanotify
  watch plus periodic backstop scan the server daemon already runs, and
  added the systemd binary itself (`/usr/lib/systemd/systemd`) to the
  monitored set. A legitimate file replacement during an apt/dnf/zypper
  package upgrade is now distinguished from real tampering by checking, via
  a structural lock-file probe, whether a package-manager transaction is
  actually in progress (not by matching the writing process's name
  against an enumerated list), so a transient false "tampering" alert
  mid-upgrade is deferred (the periodic scan still re-verifies regardless,
  so nothing is ever missed). The tampering warning log now also records
  the actual writing process's name for context. Packaging (the apt
  Post-Invoke hook, and the RPM-family path unit) now ships in the client
  edition's .deb/.rpm too.

### 1.9.16

- **Added: a warmup protection that skips the automatic notification for
  new-pattern-only anomalies (no genuine frequency spike among them)
  during a host's first 7 days after baseline capture.** The individual
  known-noise exclusions and the structural systemd-lifecycle exclusion
  (1.9.13-1.9.15) are already in place, but a host with many not-yet-seen
  OS or third-party components still saw a burst of "new pattern"
  notifications right after its first learning cycle, and that burst had
  real operational cost (people disabling the feature from alert
  fatigue). Frequency-spike detection, the USB/port/FIM guards, and
  viewing the full log-audit results manually or via MCP are all
  unaffected. Only the automatic notification is gated, and only for a
  bounded window.

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

### 1.9.13 - 1.9.15

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

### 1.9.6 - 1.9.12

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

### 1.9.0 - 1.9.5

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

### 1.8.4 - 1.8.9

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

### 1.8.0 - 1.8.3

- **Topmost Emergency Alert Overlays**: threat confirmation dialogs (BadUSB, ransomware, ARP spoofing, link hold) display as topmost overlays across all macOS spaces and full-screen apps.
- **Direct Health Audit Remediation**: added per-item remediation buttons to immediately enable internal guards or open relevant macOS System Settings panes with automatic re-evaluation.
- **Malware Scanner False-Positive Mitigation**: benign EICAR test strings trigger informational notices rather than quarantine (matching Linux behavior).
- **Enhanced Link Guard via Content Filter**: outbound connection inspection post-DNS (blocking phishing across DoH/DoT and TLS SNI) and interactive foreground warning panels with safe defaults.
- **Dual VPN Backend Support**: added Tailscale Exit Node integration alongside WireGuard tunnels.

### 1.6.0 - 1.7.6

- **Integrated VPN Killswitch**: automatic WireGuard tunnels with packet-level killswitch enforcement on untrusted networks.
- **Proactive Gateway ARP/NDP Pinning**: hardens local neighbor tables on untrusted networks to prevent MITM attacks before they happen.
- **BadUSB Physical Keyboard Guard** and **non-destructive USB storage prompts** (mount unapproved drives read-only, with granular choices).
- **Passive Link Guard**: real-time outbound filtering against phishing and scam domains.
- **Canary baseline persistence** (decoy file hashes saved to disk for strict tamper detection) and **Quarantine Vault hardening** (`chmod 000` on quarantined files).

### 1.4.0 - 1.5.9

- **Local AI / LLM server protection**: automated exposure detection and blocking for Ollama, LM Studio, Gradio, and vLLM on `0.0.0.0`.
- **Clipboard secret protection**: real-time on-device regex scanning for exposed API keys and private keys.
- **Open Source MCP Server**: released a read-only MCP server and heuristics on GitHub.
- **Web & Mail triple protection**, **privileged helper hardening**, and **a crash watchdog** with autonomous auto-recovery.

### 1.0.0 - 1.3.0

- **Initial Releases**: autonomous network environment detection by gateway MAC, automatic firewall/sharing service profile switching, port anomaly blocking, ARP spoof auto-containment, and foundational MCP integration.
