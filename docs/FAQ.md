<!-- [日本語](FAQ.ja.md) -->

# FAQ

**English** | [日本語](FAQ.ja.md)

### What does the free version include?

Wi‑Fi auto‑detection with kernel packet blocking (`pf`), the three profile security
levels, automatic stop/restore of SSH / SMB / Screen Sharing / AirDrop, the 10‑point
manual Mac security diagnostic, XProtect status checks, Wi‑Fi encryption warnings,
ARP‑spoofing detection and exposed‑port / USB monitoring (view‑only).

### What does Pro Lifetime ($19.99) add?

Ransomware‑behavior detection with Air‑Gap isolation, dev‑server LAN‑exposure
quarantine, port‑anomaly auto‑blocking, ARP‑spoofing auto‑containment, real‑time
notifications, the unauthorized‑USB storage guard, DNS threat protection, Web/Mail
download guard, link‑safety auditor, autonomous background sweeps, CSV/JSON export,
and use on 2 Macs. It is a one‑time purchase with free updates.

### Which macOS versions are supported?

macOS 13 Ventura or later, on both Apple silicon and Intel Macs.

### Is it on the Mac App Store?

No. It is distributed as a signed and notarized `.dmg` from https://lafine.net/
because it needs a privileged helper (`SMAppService.daemon`) and `pf` control that
the App Store sandbox does not allow.

### The helper won't connect / "Operation not permitted"

Open **System Settings → General → Login Items & Extensions**, approve the RoamSwitch
helper, then quit and relaunch the app. The app must be in `/Applications`.

### Does it send any of my data anywhere?

No. See the [Privacy Policy](PRIVACY.md). Zero Telemetry.

### How do I move my license to a new Mac?

Pro covers 2 devices. Deactivate on the old Mac (or contact support via
https://lafine.net/) and activate on the new one.

### How do I report a bug or request a feature?

Open an [Issue](../../issues) — templates are provided. Japanese or English is fine.

## RoamSwitch for Linux

### Is there a Linux version?

Yes. **RoamSwitch for Linux** (systemd + nftables) is a separate edition with the same
zero‑trust model: autonomous `nftables` profile switching, ransomware behaviour
detection with Air‑Gap isolation, USB / BadUSB guard, a 20‑item audit and an MCP
server. Download and docs at <https://lafine.net/linux>.

### Is the Linux version free?

Yes — the **Community Edition** is free with every feature unlocked and no activation.
It is proprietary freeware (bundled EULA); the source is not published. A paid
**RoamSwitch Business** tier (fleet management, signed policy distribution, signed
internal APT, SLA) is planned for organizations: <https://lafine.net/business>.

### Which distributions are supported?

Ubuntu 22.04 / 24.04, Debian 12+, Linux Mint, Pop!_OS, elementary, Zorin, Raspberry
Pi OS 64‑bit and Ubuntu for Raspberry Pi (x86_64 / aarch64). Install via APT
(`lafine.net/apt`), DNF / zypper (`lafine.net/rpm`) or AUR (`roamswitch-bin`).
`systemd` and `nftables` are required; non‑systemd distros (Alpine / Void / Devuan)
are not supported. Fedora / Arch / openSUSE work from a source build.

### Can it run without a desktop (headless)?

Yes. The tray UI needs an AppIndicator/StatusNotifierItem desktop, but the
`roamswitch-daemon` + CLI (`roamswitch`) + MCP server run headless.

### Does the Linux version send any data anywhere?

No. It uses no HTTP client and opens no TCP/UDP socket of its own — everything is
local IPC over a Unix socket. Update checks read the local apt cache only. See the
whitepaper's audit and self‑check: <https://lafine.net/linux/whitepaper>.

### How do I report a Linux bug?

Open an [Issue](../../issues) with `[Linux]` in the title and attach
`journalctl -u roamswitch -b` plus `roamswitch status` output (redact MACs / SSIDs / IPs).
