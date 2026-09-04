# Frequently Asked Questions (FAQ)

**English** | [日本語](FAQ.ja.md)

---

# 🍎 RoamSwitch for Mac Official FAQ (20 Questions)

## [Overview & Concept]

### Q1. What is RoamSwitch for Mac?
RoamSwitch for Mac is a zero-trust network autonomous defense and security diagnostic utility for macOS, designed around strict "Zero-Telemetry" (zero outbound data transmission). It automatically switches macOS kernel packet filter (`pf`) profiles in milliseconds based on the active Wi-Fi network, performs autonomous ransomware encryption detection & Air-Gap isolation, prevents dev-server LAN exposure, automatically blocks unknown listening ports, guards unauthorized USB keyboards and mass storage, provides a 10-point macOS health audit, and integrates with AI assistants via Model Context Protocol (MCP).

### Q2. What is the difference between the Free edition and Pro Lifetime?
The Free edition includes unlimited automatic Wi-Fi detection, 3-level profile switching via `pf`, automatic sharing service halt/restore, 10-point manual audit, Wi-Fi encryption strength warnings, and port/USB monitoring. Pro Lifetime ($24.99 / ¥2,980 one-time purchase with free lifetime updates) adds ransomware encryption detection & Air-Gap isolation, dev-server LAN exposure containment, automatic port anomaly blocking, ARP spoofing auto-containment, preventive gateway ARP/NDP lock, VPN tunnel + kill switch integration (WireGuard / Tailscale), unauthorized USB keyboard & storage guard, Web/mail download protection with automatic ClamAV scan/quarantine, dangerous AI model (.pkl/.pt) download detection, DNS threat protection, passive link guard (/etc/hosts sinkhole), link safety audits, clipboard secret leak protection, Bluetooth auto-off, autonomous sentinel background audits, CSV/JSON export, and dual-device licensing.

### Q3. How does it differ from traditional antivirus or firewall software (like Little Snitch)?
While traditional antivirus relies on passive file scanning against known signatures, RoamSwitch specializes in active, event-driven defense: it detects changes in the physical network environment in milliseconds and commands macOS kernel-level `pf` rules autonomously. Unlike Little Snitch, which interrupts workflow with repeated interactive prompt dialogs, RoamSwitch offers frictionless zero-click defense once trusted networks are saved.

### Q4. How is Zero-Telemetry guaranteed?
RoamSwitch contains zero tracking, analytics, or remote logging libraries. Lafine Systems Design publishes a full security whitepaper detailing exact packet capture procedures so users can independently verify with tools like Wireshark or `tcpdump` that no telemetry traffic is ever generated.

---

## [Features & Specifications]

### Q5. What is autonomous security profile switching (pf control)?
RoamSwitch immediately identifies the connected Wi-Fi by its gateway MAC address and SSID, applying the optimal `pf` kernel firewall profile among "Home/Office" (trusted), "Balanced", and "Lockdown" (public Wi-Fi / untrusted). Inbound network ports are locked down the instant you open your Mac at a cafe or hotel.

### Q6. How does autonomous ransomware isolation work?
Upon detecting suspicious processes exhibiting rapid file modifications or mass renaming against canary honeypot files in key user folders (Desktop, Documents, Downloads), or high-entropy encryption bursts via FSEvents, RoamSwitch instantly freezes the culprit processes (SIGSTOP) and activates an emergency Air-Gap (severing external network interfaces via `pf` and halting sharing services) to contain damage.

### Q7. What is Dev-Server LAN Exposure Containment?
When running local frontend development servers (e.g., Vite, Next.js, Webpack), backend APIs, or local AI inference servers (Ollama, LM Studio, etc.) bound to `0.0.0.0`, third parties on the same public Wi-Fi could access your work. RoamSwitch detects these listening services and isolates them from the public LAN while preserving localhost access.

### Q8. What is automatic sharing service control?
While file sharing or remote screen sharing may be desired at home, RoamSwitch automatically shuts down incoming SSH, SMB, Screen Sharing (VNC), and AirDrop services when connected to untrusted public networks, restoring them once you reconnect to a trusted network.

### Q9. What are the USB Storage Guard and BadUSB Keyboard Guard?
When an unapproved USB mass storage device is attached, RoamSwitch unmounts/ejects it automatically (or mounts read-only for ClamAV inspection before elevating access). Furthermore, if a malicious keystroke-injecting device (e.g., Rubber Ducky, BadUSB) is plugged in, RoamSwitch intercepts keystrokes via CGEventTap and displays a frontmost approval modal before permitting input.

### Q10. What is ARP Spoofing Detection and Preventive Lock?
RoamSwitch continuously monitors the local subnet for Man-in-the-Middle (MitM) attacks where malicious devices impersonate the default gateway, triggering an emergency Air-Gap upon detection. Additionally, it offers a "Preventive Gateway ARP/NDP Lock" that permanently pins the gateway and DNS resolver MAC addresses upon joining an untrusted network.

### Q11. What are DNS Threat Protection and Download Guard?
DNS Threat Protection blocks name resolution to known malware distribution and C2 domains locally (via Quad9, Cloudflare Security, or AdGuard). Web & Mail Download Guard uses FSEvents to immediately evaluate files and dangerous AI models (.pkl/.pt) downloaded via browsers or email clients, executing automatic ClamAV quarantine isolation.

### Q12. What are Link Safety Audit and Passive Link Guard?
Link Safety Audit safely inspects unverified links in emails or chats (unfolding shortened URLs, analyzing redirect chains, homograph lookalikes, and risk TLDs) entirely offline without telemetry. Passive Link Guard automatically blocks egress connections to known phishing/malicious domains via an `/etc/hosts` sinkhole.

---

## [System Requirements & Installation]

### Q13. Which macOS versions and processors are supported?
macOS 13 Ventura and newer (Sonoma, Sequoia, etc.) are supported. It is exclusively designed for Apple Silicon Macs (M1 / M2 / M3 / M4 or newer). Intel-based Macs are not supported.

### Q14. Why is it distributed as a direct .dmg rather than via the Mac App Store?
Core capabilities like millisecond kernel packet filter (`pf`) manipulation and privileged helper daemon management (`SMAppService.daemon`) cannot operate within the rigid sandboxing restrictions of the Mac App Store. RoamSwitch is digitally signed with an official Apple Developer ID and notarized by Apple for safe installation from https://lafine.net.

### Q15. What should I do if "Helper connection failed" or "Operation not permitted" appears?
Open **System Settings → General → Login Items & Extensions**, find RoamSwitch under "Allow in the Background", and ensure the toggle is turned ON. Then quit and relaunch the app. Make sure the app is placed in `/Applications`.

### Q16. Can I transfer my license to a new Mac or use multiple Macs?
A single Pro Lifetime license covers up to 2 Macs owned by the same user. To migrate to a new Mac, simply deactivate the license in the app menu on your older machine, or contact support via https://lafine.net.

---

## [Diagnostics & AI Integration (MCP)]

### Q17. What does the macOS Security Audit check?
It performs a 10-point diagnostic inspection covering FileVault full-disk encryption, System Integrity Protection (SIP), Gatekeeper status, automatic updates, XProtect definitions, macOS firewall state, stealth mode, Wi-Fi encryption strength, ARP spoofing detection, and open listening port exposure, scoring your Mac's posture.

### Q18. What is the bundled MCP server? Which AI clients are supported?
It is a standardized Model Context Protocol (MCP) server (`RoamSwitchMCPServer`) that enables AI assistants (such as Claude Desktop, Claude Code, Cursor, OpenCode, or Antigravity) to query live diagnostic reports and port exposure directly over standard input/output.

### Q19. Is there any risk that AI can modify system settings via MCP?
None. The bundled `RoamSwitchMCPServer` operates strictly in read-only mode over local stdio. Even if the AI is subjected to prompt injection attacks, it cannot modify packet filters, alter settings, or execute privileged commands.

### Q20. Can I build custom apps or scripts using RoamSwitch diagnostics?
Yes! An official Swift client SDK, **`RoamSwitchKit`** (open source, Swift Package Manager compatible), is available. You can fetch diagnostic scores, exposed ports, guard statuses, and URL safety reports with just a few lines of Swift concurrency code.

---
---

# 🐧 RoamSwitch for Linux Official FAQ (20 Questions)

## [Overview & Concept]

### Q1. What is RoamSwitch for Linux?
RoamSwitch for Linux is a free zero-trust network autonomous defense and security diagnostic tool featuring strict "Zero-Telemetry" (zero external data transmission). It provides automated `nftables` firewall switching, autonomous ransomware isolation, a 20-point security audit, and AI integration via Model Context Protocol (MCP) in a single lightweight binary.

### Q2. How does it differ from other security tools like ClamAV or Lynis?
While many tools focus on malware scanning or manual audit reports, RoamSwitch specializes in active autonomous defense: real-time firewall profile switching via `nftables` triggered by network changes, and immediate isolation (air-gap network severance and process freezing) upon detecting ransomware behavior.

### Q3. Is the source code open source (OSS)?
The core software binary is proprietary freeware (Community Edition). However, surrounding developer tooling, client SDKs (such as RoamSwitchKit), and MCP integration interfaces are open source.

### Q4. If the source code is closed, how can I verify that it is safe?
To ensure complete transparency, Lafine Systems Design publishes a comprehensive whitepaper detailing exact packet capture and system behavior verification procedures. Users can independently inspect and verify with network analyzers (e.g., tcpdump / Wireshark) that zero outbound network traffic is generated.

## [Features & Specifications]

### Q5. What exactly does "Zero-Telemetry" mean?
It means that security logs, system diagnostics, connection history, and audit results are never transmitted to any external server or cloud—including Lafine. All evaluation and enforcement occur strictly locally on the Linux machine, making it safe for air-gapped and confidential environments.

### Q6. What is autonomous firewall (nftables) profile switching?
RoamSwitch detects the current network gateway (by MAC address and SSID) in milliseconds, automatically applying the appropriate `nftables` rule set for "Home" (open), "Work" (balanced), or "Public Wi-Fi" (lockdown). No manual firewall reconfiguration is needed when changing locations.

### Q7. How does autonomous ransomware isolation work?
When canary honeypot files or fanotify/inotify with Shannon entropy detect rapid file encryption or mass tampering patterns, RoamSwitch immediately freezes suspect processes (SIGSTOP) and activates an emergency Air-Gap (severing external networking and file sharing services) to stop lateral movement across the local subnet.

### Q8. What is the Unauthorized USB / BadUSB Guard?
When an unapproved USB mass storage device is attached, `udev` integration holds the mount until user confirmation is given (with automatic ClamAV scanning). Additionally, for keystroke-injection devices (BadUSB), RoamSwitch temporarily captures input via `evdev` (`EVIOCGRAB`) and presents an approval dialog to suppress unauthorized commands (without physically disconnecting ports).

### Q9. How do the VPN Tunnel and Kill Switch features work?
When connected to an untrusted network, RoamSwitch automatically connects to your configured WireGuard (`.conf` file) or Tailscale (Exit Node) encrypted tunnel. The `nftables` kill switch blocks unencrypted traffic outside the tunnel, ensuring a fail-closed posture even if the tunnel drops (opt-in).

### Q10. What is the Passive Link Guard (Phishing Protection)?
It inspects egress destination hostnames via `nftables` NFQUEUE (DNS queries, TLS SNI, HTTP Host) locally, using signed threat feeds and brand homograph heuristics to alert or block connections to known phishing sites without transmitting any URLs externally.

## [System Requirements & Supported OS]

### Q11. Which Linux distributions are supported?
Major distributions utilizing systemd and nftables—including Ubuntu 22.04 / 24.04, Debian 12+, Linux Mint, Pop!_OS, Fedora, RHEL, CentOS Stream, openSUSE, Arch Linux, and Raspberry Pi OS (64-bit)—are supported.

### Q12. How do I install RoamSwitch for Linux?
Official repositories are provided for standard package managers: APT (`lafine.net/apt` for Ubuntu/Debian/Mint/Pop!_OS/Raspberry Pi OS), DNF (`lafine.net/rpm` for Fedora/RHEL), zypper (`lafine.net/rpm` for openSUSE), and AUR PKGBUILD / signed tarballs (`lafine.net/linux/dl/` for Arch Linux).

### Q13. Can it run in a headless environment (CLI / CUI only)?
Yes. While a native GTK GUI and system tray icon are provided for desktop users, headless environments can run the background daemon (`roamswitch-daemon`), the CLI (`roamswitch`), and the MCP server seamlessly without X11 or Wayland.

### Q14. Can RoamSwitch be used on Linux servers?
The Community Edition is designed primarily for client workstations, laptops, and single-board computers that roam between networks. While it functions on headless servers, its default behavior is optimized for endpoint roaming.

### Q15. Will there be an official Server Edition?
Yes. A specialized server/infrastructure edition with default-deny posture, static policy enforcement, and remote fleet management/audit capabilities is planned for upcoming release.

## [Diagnostics & AI Integration (MCP)]

### Q16. What does the "20-Point Security Diagnostic" check?
It evaluates 20 critical system posture items, including Secure Boot, LUKS disk encryption, LSM (AppArmor/SELinux), automatic security updates, SSH/Sudo hardening, sysctl parameters, listening ports, browser Safe Browsing, ARP lock, and DNS threat protection, producing an overall health score.

### Q17. How do I view the diagnostic results?
You can view them in the GTK GUI application or simply run `roamswitch status` in your terminal to view the full CUI diagnostic report and security score anytime.

### Q18. What is the bundled MCP (Model Context Protocol) server?
It is a standardized, secure interface (`roamswitch-mcp`) that allows AI assistants (such as Claude Desktop, Claude Code, Cursor, or Antigravity) to directly query the local Linux security status and diagnostic results over stdio JSON-RPC.

### Q19. What workflows are possible with AI (MCP) integration?
You can ask your AI assistant in plain language: *"What is my system's security score?"* or *"Are there any misconfigured listening ports?"* The AI retrieves RoamSwitch's local audit data and produces clear vulnerability summaries and remediation steps.

### Q20. Can AI tamper with system settings through MCP?
No. The bundled MCP server operates exclusively in read-only mode over local standard I/O (stdio). Even in the event of prompt injection or AI hallucinations, the AI cannot modify firewall rules, change system settings, or compromise the host.

---

## Bug Reporting & Support
- **macOS Edition**: Open an [Issue](../../issues).
- **Linux Edition**: Open an [Issue](../../issues) with `[Linux]` in the title and attach `journalctl -u roamswitch -b` plus `roamswitch status` output (redact MACs / SSIDs / IPs).
