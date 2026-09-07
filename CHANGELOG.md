# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.4.3

- **Secret/API-key leak scanner: folder scanning added to the desktop GUI**:
  the GTK "Secret & API Key Leak Auditor" tab (previously text/clipboard
  only) now has a "Choose Folder to Scan" button, matching the CLI/MCP/SDK
  capability added below.
- **Docker firewall-bypass (`DOCKER-USER`) protection fixed and ported to the
  desktop client**: Server Edition's protection had no actual deny rule and
  matched the wrong (post-NAT) port, so it silently blocked nothing. Fixed
  with an interface-scoped deny rule and pre-NAT port matching, and the same
  protection now also runs on the desktop client (previously Server Edition
  only). Added as a new item to the security health check (now 28 items on
  Server Edition, was 27).
- **Real-time detection of risky Docker containers**: a new notify-only guard
  watches `docker events` and flags the instant a container starts with
  `--privileged` or a `/var/run/docker.sock` bind-mount — a container-escape
  risk. Runs on both the desktop client and Server Edition; no automatic
  blocking, since this flags a risky *configuration*, not confirmed
  compromise.
- **New File Scan Guard for Server Edition** (opt-in): the embedded YARA
  engine always scans configured directories (mail spool, file share, upload
  directory) with no external dependency; enabling `clamav_enabled` adds a
  ClamAV second opinion. Confirmed threats are quarantined and the operator
  is notified. Configurable via `roamswitch server config`, the interactive
  `roamswitch server setup` wizard, or the new `get_file_scan_guard_status`
  MCP tool. Fixed a sandboxing bug found while building this feature's
  regression test: the systemd service's `ProtectSystem=strict` didn't grant
  write access to ClamAV's own directories, so `freshclam`/`clamdscan`
  silently failed when launched by the daemon.
- **Secret/API-key leak scanner can now scan a whole directory**:
  `roamswitch audit-secrets <directory>` recursively scans a folder (e.g. a
  git checkout), skipping `.git`/`node_modules`/`target`/`vendor`/`dist`/
  `build`/`__pycache__`/`venv` and any file over 2MB or that looks binary.
  The same capability is now available to AI agents via the `audit_secrets`
  MCP tool's new `path` parameter, and to Python SDK users via
  `audit_secrets_directory()` — all running locally, with content never
  transmitted anywhere.
- **`get_quarantine_status` MCP tool now supports Server Edition**: a new
  `isServer` parameter reads the Server Edition quarantine vault
  (`/var/lib/roamswitch/quarantine`) instead of always assuming the desktop
  client's per-user vault.
- **Fixed: Docker risk notifications ignored the language setting** — they
  were always shown in Japanese regardless of the configured UI language.
  Desktop notifications are now fully localized (all 10 supported
  languages); Server Edition notifications follow its Japanese/English-only
  policy.
- **Fixed a dialog rendering bug**: on some display setups, a security alert
  dialog could leave a solid black window behind it that didn't disappear
  when closed.

### 1.4.1

- **Added container isolation posture auditing**: Docker socket-mount exposure
  and privileged-container checks now also run on the desktop client (previously
  Server Edition only). Detects the active container runtime (`runc` / gVisor /
  Kata Containers) to surface the container-escape risk of sharing the host
  kernel, on both editions. Added a known-kernel-CVE exposure check (on by
  default on the client; on Server Edition it follows the opt-in below).
- **Server Edition: explicit opt-in for CVE data updates**: the default
  zero-network-code posture is unchanged — only if the operator explicitly
  enables `cve_kernel_map_updates_enabled` (default false) does the one
  exception kick in: a daily anonymous fetch of the container-isolation kernel
  CVE database from lafine.net (no query string, cookies, or identifying
  headers; signature-verified). Toggle and inspect it via `roamswitch server
  config` or the `roamswitch server setup` interactive wizard.
- **Fixed a ransomware-freeze notification bug**: when a short-lived process
  exited before the burst detector finished evaluating it, the notification
  showed a confusing placeholder instead of the process name. The name is now
  snapshotted the moment the write is first observed, and an honest "unknown"
  is shown when it genuinely can't be determined.

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

## 1.8.9

- **New Docker risk detection guard (Pro, off by default)**: detects the
  instant a container starts with `--privileged` or a `/var/run/docker.sock`
  bind-mount — a container-escape risk — and sends a notification. This
  flags a risky *configuration*, not confirmed compromise, so no automatic
  action is taken. Mirrors the equivalent guard on the Linux edition, using
  the same detection logic. Most users don't run Docker, which is why this
  stays opt-in even on Pro.
- **Secret/API-key leak auditor can now scan a whole folder**: previously
  limited to pasted text or the clipboard, the "Secret Leak Audit" window
  now has a "Choose Folder to Scan" option that recursively audits a
  directory (e.g. a source checkout), skipping `.git`/`node_modules`/
  `target`/`vendor`/`dist`/`build`/`__pycache__`/`venv` and any file over
  2MB or that looks binary. Runs entirely on-device, as before.
- **Fixed a dialog rendering bug**: on setups without an active compositor,
  a security alert dialog could leave a solid black window behind it that
  didn't disappear when closed.

## 1.8.8

- **Fixed helper version sync**: the privileged helper method backing the
  1.8.7 sudo NOPASSWD audit could fail to take effect after upgrading an
  existing install, because the helper's own version string wasn't bumped
  alongside it. When this happened, the "Sudo Privilege Escalation Audit"
  item in the comprehensive security report stayed stuck on "not yet
  checked" (fresh installs were unaffected).

## 1.8.7

- **Static-signature detection for downloaded files**: without requiring the
  EndpointSecurity entitlement, a lightweight static signature layer now
  checks downloads for the industry-standard EICAR test string and a set of
  well-documented, publicly known reverse-shell one-liners (bash/sh
  `/dev/tcp/`, netcat `-e`, Python `pty.spawn`, Perl `Socket`, PHP
  `fsockopen`). Runs alongside ClamAV and keeps working even when ClamAV
  isn't installed.
- **New login-item persistence monitoring**: detects the moment a new
  LaunchAgent/LaunchDaemon plist is installed, and flags it when it invokes
  a raw script interpreter (`/bin/bash` and similar) directly — malicious
  content is usually hidden in the interpreter's arguments rather than in a
  signed executable, so a validly-signed interpreter alone isn't a clean
  bill of health.
- **Emergency lockdown on suspicious Terminal commands (off by default)**:
  targets "ClickFix" — the social-engineering technique where a fake
  warning page talks the user into pasting and running a command
  themselves. Watches shell history for known-bad patterns and triggers an
  emergency network air-gap on a match. A bare `curl | bash` (used by many
  legitimate installers) is deliberately not flagged on its own — only
  narrower combinations, like decoding base64 straight into a shell or
  AppleScript, are. Off by default given the disruption a false positive
  would cause.
- **Three additions to the comprehensive security report**: gateway ARP
  pinning status, an SSH Remote Login configuration audit (root login
  disabled, key-only auth), and a sudo NOPASSWD audit.

### 1.8.4 - 1.8.6

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
