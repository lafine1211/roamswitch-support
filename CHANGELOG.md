# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.0.59

- **Fixed the Yama LSM diagnostic item never turning green on a device whose
  kernel doesn't have Yama LSM active** (reported live on a Raspberry Pi) —
  neither the per-item nor the batch kernel-hardening button ever fixed it,
  since it was silently writing to a sysctl path that doesn't exist on such
  a kernel and reporting success anyway. The health check now tells you
  honestly that this device's kernel wasn't booted with Yama LSM active and
  can't be fixed automatically (with the Raspberry Pi OS workaround: add
  `yama` to the `lsm=` list in `/boot/cmdline.txt` and reboot), instead of
  repeating a "click harden" recommendation that could never work, and no
  longer shows a harden button for this specific state.
- **DNS Threat Guard now reverts to your network's actual DNS servers**
  instead of a bare `resolvectl revert`, which didn't always restore the
  pre-override servers correctly — it now resolves the real DHCP/
  NetworkManager-assigned servers first. Switching the DNS protection scope
  in the DNS tab also now applies immediately instead of waiting for the
  next cycle.
- Reduced the default window size and several column widths so the app fits
  comfortably on smaller displays without clipping.

### 1.0.58

- **Fixed Physical Radio Restore Button on Main Window**:
  Resolved a UI race condition where clicking the "📡 Restore Radio (Enable Wi-Fi & Bluetooth)" button on the Overview dashboard immediately reverted the button back to the "Restore" state before background unblocking finished, causing restoration to fail and potentially re-killing the radio on a subsequent click.
- **Enhanced Hardware Radio & Network Reconnection Pipeline**:
  Ensured both the root daemon (`roamswitch-daemon`) and the user application execute full hardware unblocking via rfkill, re-enable NetworkManager radios (`nmcli radio all on` / `wifi on`), power up Bluetooth controllers (`bluetoothctl power on`), and trigger automatic reconnection for Wi-Fi interfaces (`nmcli device connect`). Integrated automatic cleanup of residual Air-gap lock files upon restore.
- **Improved Visual Feedback during Radio Toggles**:
  Temporarily disables the button upon clicking and displays a localized in-progress indicator ("⏳ Restoring Radios..." / "⏳ Severing Radios...") across all 10 languages. Thread-safely refreshes dashboard cards and security audit scores upon completion.

### 1.0.57

- **Unified Physical Radio (Wi-Fi & Bluetooth) Terminology and One-Click Restoration**:
  Standardized terminology across the UI and documentation to "Physical Radio (Wi-Fi & Bluetooth) Kill / Restore". Added dedicated one-click "Restore Radios (Wi-Fi & Bluetooth)" controls across the Dashboard, Emergency Air-Gap Dialog, Networks tab, and System Tray menu for instant recovery from hardware radio kill. Added clear desktop notifications when toggling hardware radios on and off.
- **Exhaustive 10-Language Localization Verification**:
  Completed a comprehensive localization audit across all 10 supported languages (ja, en, zh-Hans, zh-Hant, ko, de, fr, es, it, pt), ensuring full translation coverage for incident details (spoofed IP, attacker MAC, legitimate router MAC, target file, suspicious process) and all tray/dialog/window elements.

### 1.0.56

- **Expanded Situational Context, Decision Guidance, and Quick Actions during Air-Gap**:
  The emergency alert dialog and Networks tab now display concrete incident details, including spoofed IP/MAC addresses for ARP spoofing or altered path/process name/PID for canary file integrity violations. Packet-level isolation (nftables) and data leak prevention guarantees are explicitly communicated, alongside contextual decision guidance (risks of Man-in-the-Middle on public Wi-Fi vs legitimate router changes on home/office networks). Added four quick-action options: "Disconnect Wi-Fi", "View Detailed Logs", "Close (Keep Blocked)", and "Release Air-Gap".
- **Enhanced Connectivity Recovery After Releasing Air-Gap**:
  Automatically triggers NetworkManager connectivity checks and flushes local DNS caches upon Air-Gap release, instantly clearing the question mark ("?") icon on desktop taskbars. Instantly dismisses the emergency alert modal upon releasing Air-Gap.
- **System Tray Menu (ksni / DBusMenu) Stability Fix**:
  Vendored and patched the `ksni` crate to eliminate potential out-of-bounds `id2index` panic crashes during dynamic menu rebuilds.
- **Localization**:
  All new dialogs and actions fully localized across 10 languages (ja, en, zh-Hans, zh-Hant, ko, de, fr, es, it, pt).

### 1.0.50 - 1.0.51

- **Reduced UI Latency During Air-Gap**: Replaced synchronous ARP cache ping checks in the Networks tab with background thread processing to prevent UI blocking.
- **Automatic Recovery After ARP Spoofing Stops**: Actively flushes the gateway neighbor cache so the system automatically returns from lockdown to normal operation without requiring manual network reconnection.

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

## 1.8.3

- **Emergency confirmation dialogs now always come to the front.** The four
  alert dialogs that trigger automatically upon threat detection (BadUSB
  keyboard authorization, ransomware emergency air-gap, ARP spoofing
  air-gap, and link guard connection hold) are presented as topmost overlays
  across all macOS spaces and full-screen apps, even when RoamSwitch is
  idling in the menu bar.

## 1.8.2

- **Malware scanning no longer quarantines benign EICAR test files.** Files
  containing industry-standard EICAR test strings now trigger informational
  notices without blocking or quarantine across all scan modes.
- **Added direct remediation buttons to Security Health checks.** Items needing
  attention (🔴) provide one-click buttons to enable internal guards directly
  or open relevant System Settings panes.

## 1.8.1

- Improved Link Guard "Warn Only" mode with interactive foreground panels
  defaulting to safe blocking.
- Fixed an issue where manually blocked sites were prematurely hard-blocked in
  warn mode.

## 1.8.0

- **Content Filter Network Extension for Link Guard (Pro):** Inspects outbound
  connections post-DNS, blocking phishing and malicious hosts even under DoH/DoT
  encrypted DNS or TLS SNI.
- **Interactive Warn Mode:** Suspends suspicious connections and presents
  interactive allow/block prompts.
- **Dual VPN Backend Support:** Added Tailscale Exit Node support alongside
  WireGuard tunnels for untrusted networks.
- Updated privileged helper tool to 1.8.2.

## 1.7.0 - 1.7.6

- **Integrated VPN Killswitch:** Introduced automatic WireGuard tunnels with packet-level killswitch enforcement on untrusted networks.
- **Proactive Gateway ARP/NDP Pinning:** Hardens local neighbor tables on untrusted networks to prevent MITM attacks before they happen.
- **BadUSB Physical Keyboard Guard:** Detects unauthorized external keyboards and hardware inject tools, dropping keystrokes until authorized.
- **Passive Link Guard:** Real-time outbound filtering against phishing and scam domains using zero-telemetry heuristics.
- **Non-destructive USB Storage Prompts:** Mounts unapproved drives read-only while offering granular read/write or eject choices.

## 1.6.0 - 1.6.4

- **Canary Baseline Persistence:** Persisted decoy file hashes to disk for strict tamper detection and reliable self-healing.
- **Quarantine Vault Hardening:** Fully revoked execution and read permissions (`chmod 000`) on quarantined files.
- **Port Anomaly Guard Cleanups:** Automated migration for legacy executable records and notification deduplication.

## 1.5.0 - 1.5.9

- **Local AI / LLM Server Protection:** Automated exposure detection and blocking for Ollama, LM Studio, Gradio, and vLLM on `0.0.0.0`.
- **Clipboard Secret Protection:** Real-time on-device regex scanning for exposed API keys and private keys.
- **ClamAV Quarantine Enhancements:** Closed bypass paths for `.tmp` extensions and direct terminal downloads (`curl`/`cp`).
- **Crash Watchdog:** Autonomous LaunchAgent monitor with exponential backoff auto-recovery.

## 1.4.0 - 1.4.8

- **Open Source MCP Server:** Released read-only MCP server and heuristics on GitHub; introduced `get_app_help` knowledge base search.
- **Web & Mail Triple Protection:** Implemented automated download scanning, DNS threat protection, and link safety diagnostics.
- **Privileged Helper Hardening:** Enforced `audit_token` validation and Team ID pinning against PID reuse attacks.

## 1.0.0 - 1.3.0

- **Initial Releases:** Autonomous network environment detection by gateway MAC, automatic firewall/sharing service profile switching, port anomaly blocking, ARP spoof auto-containment, and foundational MCP integration.
