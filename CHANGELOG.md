# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.0.63

- **Manual Immediate Update Button & Real-time Progress Spinner for Threat Feeds**:
  Added a dedicated "🔄 Update Definitions Now" button inside the "Automatic update status" card in the Updates tab. Users can now immediately fetch and verify the latest manifest, scam-site feed, and ClamAV definitions on demand. The active operation displays an animated GTK spinner and status label, instantly updating the displayed feed timestamp upon completion.
- **Automatic Application Restart After Package Upgrade**:
  Following a successful package upgrade (`apt` / `dnf` / `zypper`) from the "Upgrade now" button, RoamSwitch now automatically restarts itself smoothly and brings the main window back up, eliminating the need for manual restarts. Also added an active spinner indicator while checking and executing upgrades.

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

### 1.8.4

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
