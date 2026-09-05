# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

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
  windows that open by themselves in response to a threat — the BadUSB keyboard
  approval, the ransomware and ARP-spoofing emergency dialogs, and Link Guard's
  "connection on hold" prompt — now present as a top-most overlay that stays
  above other apps' windows and full-screen apps, on whichever Space you're on,
  even when RoamSwitch is a background menu-bar app.

## 1.8.2

- **Malware scan no longer quarantines the harmless EICAR test file.** A file
  that merely contains the industry-standard EICAR test string (a security
  how-to, a signature sample, this site itself) now only raises an
  informational "🧪 EICAR test signature detected (harmless)" notification — it
  is never quarantined or blocked. Same behaviour for the download auto-scan,
  the scheduled scan, and a manual scan. A genuine malware sample is still
  moved to the Quarantine Vault (reversible). Matches the Linux edition 1.0.34.
- **Per-item fix buttons in the Security Diagnostic.** Each failed (🔴) item now
  has a one-click button: RoamSwitch's own guards (DNS Threat Guard, Web/Mail
  protection, USB guard) get a "🔧 Enable" that turns them on in place; OS-level
  items (FileVault, Gatekeeper, …) get "Open Settings" that jumps to the right
  System Settings pane. The check re-runs automatically afterwards.

## 1.8.1

- Link Guard "Warn only" mode refinements. The "Allow / Block" choice for a
  held connection now also appears as a foreground panel, not just a
  notification (a "banner"-style notification only shows its action buttons on
  hover). The panel's default action is the safe one — Block.
- Fixed: in "Warn only" mode a site you had previously blocked by hand could be
  dropped immediately instead of prompting (warn mode never hard-blocks).

## 1.8.0

- **Link Guard is now enforced by a content-filter system extension** (Pro). It
  inspects the actual outbound connection *after* name resolution, so it blocks
  phishing/scam sites even when the browser does its own encrypted DNS
  (DoH/DoT); it also parses the TLS ClientHello (SNI). It needs a one-time
  approval in System Settings (no Apple review required). The previous
  `/etc/hosts` method stays as a fallback until the extension is approved.
- **"Warn only" mode is now a real warning.** On a suspicious connection the
  extension pauses that connection and raises a notification with "Allow" /
  "Block" buttons; your choice resumes or drops the held connection (no answer
  within 25 s lets it through). The decision is remembered per site, so the
  page's other requests and later visits apply instantly.
- **The VPN tunnel backend is now selectable between WireGuard and Tailscale**
  (Pro, off by default). Under "Ports & Device Monitoring" → "VPN Tunnel" →
  "Backend". With Tailscale you pick an **exit node** from your existing tailnet
  to route all traffic through the tunnel on untrusted networks. RoamSwitch
  never runs `tailscale up` / logs in / installs it — it reads status and sets
  the exit node. The standalone CLI (`brew install tailscale`) is recommended.
- Helper updated to 1.8.2 — re-approve on first launch.

## 1.7.6

- **Added a VPN tunnel with a kill-switch** (Pro, off by default). Import a
  WireGuard config (`.conf`) and RoamSwitch brings an encrypted tunnel up
  automatically when you join an untrusted network. A pf kill-switch blocks
  everything except the tunnel and its handshake until the tunnel is
  established (and while it's down), so ARP/NDP spoofing or sniffing sees only
  ciphertext. This is the primary anti-MITM defence; the ARP/NDP lock and
  detection are secondary to it. Trusted networks are left alone. Backed by
  Homebrew's `wireguard-tools` (`brew install wireguard-tools`) — no Apple
  Network Extension entitlement required. Under "Ports & Device Monitoring" →
  "VPN Tunnel".

## 1.7.5

- **Added a preventive gateway ARP/NDP lock** (Pro, off by default). When you
  join an unregistered network (a café, public Wi-Fi), the MAC address of the
  gateway, the IPv6 router, and any DNS server on the same network is pinned so
  ARP/NDP spoofing can't set up a man-in-the-middle attack in the first place.
  Enable it under "Ports & Device Monitoring" → "Pin gateway ARP/NDP on
  untrusted networks (preventive)".
- **Reworked the ARP spoofing auto-containment response.** In Lockdown it still
  cuts all traffic immediately; on Balanced / trusted networks it now
  **notifies instead of cutting**, with a "Cut all network now" item in the
  menu. This stops a router reboot or access-point switch from triggering it by
  mistake, and stops an attacker from using a single spoofed ARP packet to
  knock you offline.

## 1.7.4

- **USB Storage Guard no longer ejects an unknown drive outright.** An
  unrecognised external drive is now mounted read-only and an approval prompt
  is shown — "Allow read-write", "Allow read-only", or "Eject". Approving adds
  it to the allow-list and applies the chosen permission (after the usual
  ClamAV scan). This matches the Linux edition's insert-time prompt and means a
  mistaken eject can't lose in-flight work.

## 1.7.3

- Fixed "Link Guard" (added in 1.7.2) not appearing in the menu bar. The
  blocking engine itself was running in 1.7.2, but the UI for the mode switch
  (Off / Warn only / Auto-block), the scam-list version, and the auto-update
  toggle was missing. It's now under "Malware Protection" → "Link Guard".
- Renamed the manual check item to "Check a link manually…".

## 1.7.2

- 🔗 Added the passive Link Guard (auto-blocks phishing connections) (Pro):
  - Automatically blocks connections to phishing and scam sites on-device, based on a list of known scam sites and brand-impersonation domain checks. The privileged helper adds the domains to a managed section of `/etc/hosts` pointing at `0.0.0.0` — no Apple Network Extension entitlement required — so the block applies across every browser and app.
  - From "Link Guard" in the menu bar you can choose "Off", "Warn only (don't block)", or "Auto-block obvious scam sites (recommended)". **The default is now auto-block.** Only clear cases are blocked — a listing in the threat feed, or a brand-name homograph — everything else is a warning. A wrong block can be allowed in one click from the notification or the menu (5 minutes or permanent).
  - The verdict engine and threat feed are shared with the Linux edition.
- 📡 The threat feed now uses a dedicated Ed25519 signing key, separate from the app-update key. The feed is fetched once a day, receive-only (nothing sent, no identifiers). Turning off "Auto-update" drops external traffic to zero; the feature runs on bundled data (~280 entries) plus homograph detection.
- 🌐 New UI and help strings localized in all 10 languages.

## 1.7.1

- 🚀 Smoother first-time setup (privileged helper approval):
  - Added a gate that detects when RoamSwitch is running from outside the Applications folder (Downloads, the disk image, etc.) — macOS won't let the helper register from there — and guides you to fix it before the approval step, with a "Move to Applications & relaunch" button.
  - Added recovery paths when helper approval doesn't complete: a retry button on registration failure, clearer guidance on exactly which switch to turn on, and a re-download prompt if the helper is missing.
  - When the helper is not connected, the menu bar now shows an "⚠️ Approve the helper…" item that takes you straight to the right Settings pane.
  - If the helper stays unapproved for a few days, the app shows one quiet on-device reminder (nothing is sent anywhere).
  - New screens and strings localized in all 10 languages.

## 1.7.0

- 🔌 BadUSB & Physical Keyboard Approval Guard (`USBKeyboardGuard`):
  - Dynamic real-time monitoring of newly connected HID keyboards and modified cables (Rubber Ducky, O.MG Cable, etc.) via IOKit (`IOHIDManager`).
  - Built-in MacBook keyboards are automatically allowlisted to ensure uninterrupted daily workflows.
  - Intercepts and drops keystrokes from unapproved keyboards instantly via `CGEventTap`, stopping malicious automated keystroke/command injection attacks at the physical boundary.
  - Displays a dedicated approval modal allowing users to review and authorize trusted devices with a single click.
- 🛡️ Unified USB & BadUSB Guard Settings UI:
  - Segmented tab navigation for seamlessly managing both Keyboard and Storage allowlists in one place.
  - Added live real-time detection of macOS Accessibility permissions and direct Settings navigation.
- 📊 Enhanced Security Health Checks:
  - Added audit checks for "Unauthorized USB / BadUSB Physical Port Guard" and "macOS Accessory Security (Apple Silicon)".
- 🌐 Full 10-Language Localization:
  - Added comprehensive translations across all 10 supported languages: English, Japanese, German, French, Spanish, Italian, Korean, Portuguese, Simplified Chinese, and Traditional Chinese.

## 1.6.4

- Ransomware Canary Baseline Hash Disk Persistence & Lifecycle Optimization:
  - Persisted baseline expected SHA-256 hashes per canary bait file to disk (`UserDefaults`).
  - Missing or tampered decoy files are no longer prematurely overwritten on routine app launches, strictly preserving tamper/deletion detection against the persisted baseline.
  - Full self-healing regeneration from embedded pristine templates is executed exclusively upon explicit user containment release ("緊急隔離を解除").

## 1.6.3

- Menu Bar Icon State Stability & Immediate Manual Override Updates:
  - Enhanced state publisher bindings and immediate icon refresh on manual security level overrides, eliminating lingering busy spinner icons.
  - Added failsafe timeout to diagnostic passes (`isDiagnosing`) to guarantee the busy state never gets permanently stuck.
- Hardened Threat Quarantine Permissions:
  - Quarantined files in `~/Library/Application Support/RoamSwitch/Quarantine` now have all read and execute permissions stripped (`chmod 000`) to render isolated threats completely inert.

## 1.6.2

- Automatic Legacy Data Migration for Port Anomaly Guard:
  - Added startup migration in `PortAnomalyGuard` to purge legacy portless interpreter identities (e.g. bare `"Python"`) from `KnownExecutablesV2`.
  - Ensures seamless precision and strict per-port scoping across version upgrades.

## 1.6.1

- Suppress Redundant Notifications During Active Ransomware Containment:
  - Fixed an issue where 60-second periodic integrity checks repeatedly dispatched threat alerts while emergency isolation was already active.
  - Pauses background polling and duplicate notifications until isolation is resolved.

## 1.6.0

- Resilient Quarantine Fallback for Existing Filename Collisions:
  - Added automatic collision resolution in QuarantineManager: if a previously quarantined file with the exact same name already exists, RoamSwitch isolates the newly flagged threat under a timestamped unique filename.
  - Guarantees zero residual infected files remaining at the original path upon re-download or duplicate attacks.

## 1.5.9

- Comprehensive ClamAV Quarantine Coverage (Bypass Prevention):
  - Added instant inspection for `.tmp` files to catch payload downloads attempting extension evasion.
  - Enabled active scanning across all watched directories (Desktop, Documents, Downloads) regardless of `com.apple.quarantine` attributes, ensuring tools copying via terminal (`cp`, `curl`, `wget`) or external media are immediately audited and quarantined.

## 1.5.8

- Robust Remote Login (SSH) & Sharing Service State Restoration:
  - Upgraded service load detection (`launchctl print`, `print-disabled`, `systemsetup`) to reliably track `com.openssh.sshd` across modern macOS versions.
  - Coupled `launchctl load -w` with `/usr/sbin/systemsetup -setremotelogin on` upon lockdown release and trusted network transition to guarantee Remote Login (SSH) restoration.
- ClamAV Download Quarantine Deduplication & Multi-scan Prevention:
  - Fixed duplicate quarantine entry bug caused by concurrent FSEvents file write/flush triggers.
  - Added in-flight scan and recently-quarantined file caching to eliminate redundant scans and quarantine folder ballooning.

## 1.5.7

- Security Guard Architecture & Robustness Enhancements based on VM Penetration Audit:
  - **Ransomware Canary Bait Self-Healing**: Automatically regenerates and restores the baseline hash of any missing or tampered canary decoy files upon emergency isolation release, immediately reinstating kqueue real-time monitoring.
  - **Strict Per-Port Identity for Generic Interpreters**: Generic script interpreters and networking shells (Python, Node.js, Ruby, PHP, Netcat, etc.) are now identified by path:port rather than path alone, preventing living-off-the-land attackers from exploiting a previously-allowed interpreter binary to open unmonitored backdoors on new ports.
  - **Baseline Poisoning Prevention & Reset**: Eliminated unconditional whitelisting of unverified userland listeners on first-time guard activation; added baseline reset capability.
  - **Download Guard Hidden File (Dotfile) Detection**: Refined exclusion filters to only ignore macOS system metadata (.DS_Store, ._*), ensuring hidden payload downloads (e.g. .hidden_eicar.txt, .payload.sh) are reliably inspected in real time by ClamAV.

## 1.5.6

- Improved Automatic Restoration of Sharing Services (SSH / SMB / Screen Sharing) upon Emergency Isolation Release:
  - Fixed an issue where previously active sharing services (such as Remote Login / SSH and SMB file sharing) were not reliably restored after releasing emergency containment (Air-Gap / Lockdown) from ARP spoofing or ransomware detection.
  - Strengthened helper daemon service state persistence and state protection against duplicate isolation invocations.
- Performance & Responsiveness Enhancements during Emergency Containment and Background Monitoring:
  - Offloaded process enumeration and file inspection in port monitoring and canary guard to background queues to prevent main-thread UI hangs and spinning beachballs.
  - Enhanced trusted signature verification for macOS system daemons (such as photoanalysisd) to eliminate false attribution.

## 1.5.5

- Web & Mail Download Guard (ClamAV Real-Time Scan) Detection & Alert Improvements:
  - Improved file path parsing logic when processing ClamAV threat scan outputs. Fixed an issue where quarantined threat files were misidentified in the recent scan history, ensuring high-priority banner notifications ("🚨 Quarantined Malicious Download File") and threat status indicators are reliably dispatched upon detection.

## 1.5.4

- Added Confirmation & Risk Warning Dialogs When Turning Off Critical Security Guards:
  - When disabling crucial autonomous protection features such as "Auto-Contain ARP Spoofing", "Auto-Block Unknown Listening Ports", or "Auto-Block Unauthorized USB Storage", RoamSwitch now presents a confirmation dialog with full risk explanations (localized in 10 languages).
  - Prevents accidental deactivation and ensures users are aware of potential security risks before turning off guards.
- Menu Bar UI Enhancements:
  - Added guard toggles for ARP spoofing and port anomaly containment directly into the SwiftUI menu bar interface for consistent usability.

## 1.5.3

- MCP (Model Context Protocol) Server Integration Enhancements:
  - `get_exposed_ports` now covers local AI inference servers (Ollama, LM Studio, Gradio, vLLM) exposure audits.
  - `get_guard_status` and `get_app_help` updated with full knowledge coverage for clipboard secret leak prevention and Pickle AI model download guard.

## 1.5.2

- Confidential API Key & Secret Leak Prevention (Clipboard Protection):
  - Automatically scans clipboard contents on-device (Zero Telemetry) for OpenAI, Anthropic, GitHub, AWS, HuggingFace, Google Gemini keys, and private keys to prevent accidental pasting into AI chats or public websites.
- Unsafe AI Model File (Pickle / PyTorch) Download Protection:
  - Detects arbitrary code execution risks in downloaded `.pkl`, `.pickle`, and `.pt` model files, prompting recommendations to use SafeTensors or GGUF formats.

## 1.5.1

- Added Local AI / LLM Server Exposure Detection & Protection (Ollama / LM Studio / Gradio / vLLM):
  - Added detection and proactive alerts for local AI inference servers accidentally bound to `0.0.0.0` (accessible across the entire LAN), including Ollama (port 11434), LM Studio (1234), Gradio / AI WebUI (7860), and vLLM (8000).
  - Prevents unauthorized remote model execution/download/deletion, GPU compute theft, and prompt eavesdropping over the local network with one-click `pf` isolation and configuration guidance.
- Added Crash Watchdog & Auto-Recovery:
  - Introduced a background watchdog agent (LaunchAgent) that automatically detects unexpected terminations and restarts the application.
  - Built-in exponential backoff (2s, 4s, 8s, 16s, 32s) and a 5-attempt retry limit to prevent infinite restart loops.
  - Native macOS notifications (UNUserNotificationCenter) alert you when an auto-restart occurs or if the crash limit is reached.
  - Clean user quits are recognized and will not trigger restarts.

## 1.4.8

- Onboarding: Added an animated video guide demonstrating the macOS system approval steps for the helper tool.

## 1.4.7

- Added an **"Allow" button** to the "auto‑block unknown listening ports" notification. If a
  legitimate LAN receiver started after the guard was enabled — LocalSend, Syncthing — gets
  blocked, you can now allow it permanently straight from the notification banner (Apple system
  daemons that satisfy `anchor apple` remain out of scope, as before).
- Updated the in‑app help and the MCP knowledge base (the auto‑block guards are on by default once
  Pro is active; how to recover from a false positive).

## 1.4.6

- Open source:
  - The bundled read-only MCP server and the detection logic behind it are now published under the MIT license at <https://github.com/lafine1211/roamswitch-mcp>, so you can verify in code what the server exposes to an AI client and that it sends nothing out.
- Fixed:
  - A single crafted JSON-RPC line with deeply-nested objects could crash the MCP server (a stack overflow inside Apple's JSON parser). The server now rejects pathologically nested input before parsing. Found by fuzzing the parser after open-sourcing it; details in the repository's `SECURITY_TESTING.md`.

## 1.4.5

- Security audit and hardening:
  - Hardened privileged helper XPC authentication by switching from PID to `audit_token_t` validation and enforcing Apple Developer Team ID pinning to eliminate PID-reuse / TOCTOU risks.
  - Relocated temporary packet-filter (pf) rule generation to a root-protected directory.
  - Added SSRF protection to the link safety auditor to block unintended internal/private network redirects.
  - Enhanced quarantine metadata integrity to prevent collisions and unintended deletions when multiple files share the same filename.

## 1.4.4

- Expanded MCP Server capabilities:
  - Added an authoritative built-in knowledge base covering all security features, notification catalogs, and troubleshooting guides.
  - Added the `get_app_help` tool for AI agents to query application mechanisms and alert explanations.
  - Added MCP resources (`roamswitch://docs/...`) for documentation inspection.

## 1.4.3

- Fixed: the emergency network isolation (air‑gap) triggered on ARP‑spoofing and
  ransomware detection did not engage correctly when the unknown‑port auto‑block
  guard was also on. Air‑gap engagement is now verified, and a failure is shown
  honestly in the modal instead of claiming full isolation.
- Fixed: "auto‑block unknown listening ports" mis‑flagged legitimate processes that
  rotate their port between launches (including built‑in macOS features like
  Handoff). Apple system daemons are now out of scope.
- Fixed: disabling "auto‑block unknown listening ports" left the block rules it had
  created in place.
- Pro: "auto‑block unknown listening ports" and "auto‑air‑gap on ARP spoofing" are
  now on by default once a Pro license is active (your explicit choice is respected
  after that).
- Added a once‑daily background virus scan to the autonomous patrol (a quiet
  notification when clean, auto‑quarantine plus an alert on a hit).
- A ClamAV scan that finishes clean now reports via a notification instead of a
  modal dialog.

## 1.4.2

- MCP server: protocol‑version negotiation and JSON‑RPC batch support.

## 1.4.1

- In‑app Help & Guide expanded: Web/Mail download guard, DNS threat protection,
  link‑safety auditor, editable watch folders.

## 1.4.0

- Web/Mail triple guard: download auto‑scan, DNS threat protection, link‑safety auditor.
- New MCP tools; custom watch‑folder editor with restore‑to‑default.

## 1.3.0

- Read‑only MCP server; instant alert for `0.0.0.0`‑exposed database ports.

## 1.2.0

- Auto‑block unknown listening ports; ARP‑spoofing auto‑containment guard.
- ClamAV scan on USB mount documented in Help.

## 1.1.x

- Onboarding: added "launch at login" step; fixed helper‑not‑connected cases.

## 1.0.0

- Initial public release: trusted‑network detection by gateway MAC, per‑profile
  firewall / stealth / sharing / AirDrop switching, Mac security health check.
