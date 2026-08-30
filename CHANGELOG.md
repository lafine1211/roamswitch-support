# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. Dates are release dates.

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
