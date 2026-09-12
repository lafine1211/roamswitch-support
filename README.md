<!-- Language: **English** | [日本語](README.ja.md) -->

# RoamSwitch — Support & Announcements

**English** | [日本語](README.ja.md)

Autonomous network‑boundary security for your Mac. RoamSwitch is a menu‑bar app that
recognizes the networks you trust (home LAN, office, tethering, …) by their default
gateway MAC address and automatically switches the macOS firewall, stealth mode,
sharing services (SSH / SMB / Screen Sharing) and AirDrop policy the moment you move
between them.

> This repository is **not the source code**. It is the public home for
> **downloads, release notes, the FAQ, the privacy policy, and support** (bug reports
> and feature requests via [Issues](../../issues)).

<p align="center">
  <img src="docs/img/menu-en.png" alt="RoamSwitch menu bar" width="360">
</p>

## Download

**https://lafine.net/**

- Signed & notarized `.dmg`, distributed outside the Mac App Store
- Requires **macOS 13 Ventura or later**, Apple silicon only (M1 / M2 / M3 / M4 and later)
- Latest version: **1.9.24**

## What it does

| Layer | Free | Pro Lifetime |
| :--- | :---: | :---: |
| Wi‑Fi auto‑detection & kernel packet blocking (`pf`) | ✅ | ✅ |
| Per‑profile security levels (Trusted / Standard / Lockdown) | ✅ | ✅ |
| Auto stop & restore of SSH / SMB / Screen Sharing / AirDrop | ✅ | ✅ |
| 18‑point Mac security health check (FileVault / SIP / Gatekeeper / updates / XProtect / firewall / stealth / Wi‑Fi / ARP / SSH / sudo / ports / download, DNS & link protection / USB & accessory guards) | ✅ manual | ✅ + autonomous background sweep |
| Malware tooling (XProtect / ClamAV status & scan) | ✅ manual | ✅ + auto virus‑definition updates |
| Wi‑Fi encryption‑strength warnings, ARP‑spoofing detection, exposed‑port & USB monitoring | ✅ | ✅ |
| 🚨 Ransomware‑like behavior detection → emergency Air‑Gap isolation (`pf`) | ❌ | 🚀 |
| 🛡️ Dev & Local AI server (Ollama/LM Studio etc.) `0.0.0.0` quarantine guard | ❌ (list only) | 🚀 one‑click block |
| 🕳️ Port‑anomaly guard — auto‑block newly exposed listening ports (signature‑free) | ❌ | 🚀 |
| ⚡ ARP‑spoofing auto‑containment + real‑time notifications | ❌ (menu only) | 🚀 |
| 🔌 Unauthorized USB / BadUSB storage guard + auto ClamAV scan on mount | ❌ | 🚀 |
| 🌐 Web/Mail download guard (incl. Pickle AI model detection), DNS threat protection, link‑safety auditor | ❌ | 🚀 |
| 🔑 API Key & Secret leak prevention checker (Zero Telemetry clipboard protection) | ✅ | ✅ |
| 🧬 Runtime threat containment — auto Air‑Gap the moment Apple's XProtect convicts a file | ❌ | 🚀 |
| 🪤 Ransomware canary (decoy bait files) with incident history | ❌ | 🚀 |
| 🔒 VPN tunnel + kill switch (WireGuard / Tailscale) on untrusted networks | ❌ | 🚀 |
| 🎣 Link guard — block phishing/scam destinations via `/etc/hosts` sinkhole + content‑filter extension | ❌ | 🚀 |
| 🧩 Persistence monitoring (new LaunchAgents/Daemons) & ClickFix shell‑history guard | ❌ | 🚀 |
| 📂 Critical Path FIM — SHA‑256 baseline of root‑only system files, checked in the background | ❌ | 🚀 |
| 🧾 Security log audit with automatic secret masking + log‑template anomaly detection | ✅ | ✅ |
| 🧯 Unified containment incident timeline & 7‑day notification history | ✅ | ✅ |
| 🐞 Local CVE matching for Homebrew formulae and dependency lockfiles (no network) | ✅ | ✅ |
| 🧪 Active vulnerability verification, `127.0.0.1` only (opt‑in, off by default) | ✅ | ✅ |
| 📄 Log & diagnostics export (CSV / JSON) | ❌ | 🚀 |
| Devices | 1 | 2 |

## Pricing

One‑time purchase — no subscription.

| Plan | Price | Devices |
| :--- | :--- | :--- |
| **Free** | $0 | 1 |
| **Pro Lifetime** | **$19.99** | 2 |

Pro is a lifetime license with free updates. Purchase at **https://lafine.net/**.
Prices are shown in USD; checkout is billed in your local currency where supported.

## Privacy — Zero Telemetry

RoamSwitch performs **no external network communication of its own**: no analytics,
no crash reporting, no license "phone home" beyond the one‑time purchase checkout on
the website. The bundled MCP server is read‑only and speaks local stdio only. See
the [Privacy Policy](https://lafine.net/privacy.html).

## MCP server (for Claude Desktop / Claude Code)

RoamSwitch ships a **read‑only** Model Context Protocol server so MCP clients can query
your Mac's security posture. No lockdown/quarantine/eject actions are exposed.

```sh
claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
```

15 tools, all read‑only: `get_security_report`, `get_exposed_ports`, `get_guard_status`,
`audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_app_help`,
`run_active_vuln_scan`, `run_package_cve_scan`, `run_package_cve_scan_languages`,
`get_quarantine_status`, `get_canary_status`, `get_port_anomaly_incidents`,
`get_runtime_threat_status`, `get_notification_history` — plus four `roamswitch://docs/*` resources. The incident‑state
tools read only local state, so they still answer while RoamSwitch has air‑gapped the network.
Setup for Claude Desktop, Claude Code, Codex CLI, OpenCode and Antigravity:
<https://lafine.net/mcp-setup.html>.

The server and the detection logic behind it are **open source** (MIT):
[github.com/lafine1211/roamswitch-mcp](https://github.com/lafine1211/roamswitch-mcp) —
`swift test` runs its unit, adversarial-input and mutation-fuzz suites.

## RoamSwitch for Linux

A separate edition for **Linux** (systemd + nftables) reproduces the same zero‑trust
model — autonomous `nftables` profile switching by gateway MAC, ransomware behaviour
detection with emergency Air‑Gap isolation, unauthorized‑USB / BadUSB guard, a VPN tunnel
with an nftables kill switch (WireGuard / Tailscale), a passive link guard, local CVE
matching, a 24‑item security audit, a full CLI (`roamswitch`, `man roamswitch`) and a
read‑only MCP server with 19 tools.

There are two mutually exclusive packages: **Client Edition** (`roamswitch`, tray app +
web UI, 24‑item audit) and **Server Edition** (`roamswitch-server`, fully headless for
cloud VPS/data centers — inbound default drop with SSH lockout prevention, Critical Path
FIM, eBPF intrusion detection via Falco or Tetragon with autonomous containment, a
resource‑exhaustion guard, Telegram/LINE/webhook alerts, and a 30‑item audit).

- **Free — "Community Edition"**, every feature unlocked, no activation. Proprietary
  freeware (bundled EULA); the source is not published.
- **Download & docs:** <https://lafine.net/linux>
- **Install:** APT (`lafine.net/apt`) or DNF / zypper (`lafine.net/rpm`); on Arch,
  build from the bundled PKGBUILD (the AUR package `roamswitch-bin` is pending).
  Requires Ubuntu 22.04+ / Debian 12+ or a compatible systemd + nftables distro;
  x86_64 / aarch64 (incl. Raspberry Pi 4 / 5).
- **Docs:** [CLI / headless operations](https://lafine.net/linux-cli.html) ·
  [Server Edition manual](https://lafine.net/linux/server-manual) ·
  [Server Edition whitepaper](https://lafine.net/linux/server-whitepaper)
- **Rust SDK (MIT):** [roamswitch-linux-kit](https://github.com/lafine1211/roamswitch-linux-kit)
- **Security whitepaper:** <https://lafine.net/linux/whitepaper>
  ([EN](https://lafine.net/linux/whitepaper.en)) — includes a code‑level audit of
  "zero data sent off the machine" and the destructive self‑test results
  ([audit/RESULTS-LINUX-2026-09-02.md](audit/RESULTS-LINUX-2026-09-02.md)).
- **RoamSwitch Business** (planned, paid) adds fleet management, signed policy
  distribution, a signed internal APT repository and SLA support for organizations:
  <https://lafine.net/business>. Holders of a macOS **Pro Lifetime** license get
  Business features free on their own Linux machines.
- **Support:** same [Issues](../../issues) tracker — please label Linux reports and
  attach `journalctl -u roamswitch -b` and `roamswitch status` output (redacted).

## Security & verification

- **Architecture & security whitepaper** — what privileges RoamSwitch holds and what it
  does at that boundary, at a level you can check against the shipping binary:
  <https://lafine.net/security.html> (English/日本語, switchable on the page)
- **[`verify.sh`](verify.sh)** — runs the whitepaper's Appendix A checks against your
  installed copy (signature, notarization, entitlements, the MCP server's offline
  response, pf state). It's ~90 lines of read-only shell — read it first, then:

  ```sh
  git clone https://github.com/lafine1211/roamswitch-support && cd roamswitch-support
  ./verify.sh            # NO_SUDO=1 to skip the two sudo steps
  ```
- **[`audit/`](audit/)** — a heavier, repeatable **Zero Telemetry egress audit**:
  it captures traffic and attributes it per-process to check that the only
  outbound connections from RoamSwitch's binaries are the four documented in
  whitepaper §7. Latest run: [**PASS, 2026-08-29**](audit/RESULTS-2026-08-29.md).
  Reproduce with `./audit/rs-zerotel-audit.sh all`.
- **[`test/docker/`](test/docker/)** — reproducible Docker test suite verifying all Linux
  defense mechanisms & penetration scenarios (Air-Gap enforcement, self-healing against
  firewall clobbering, ransomware canary tampering, `/tmp` noexec, Yama LSM, homograph detection,
  and credential leak detection — 17 items total). Run safely in an isolated container without
  affecting the host:

  ```sh
  cd test/docker
  docker build -t roamswitch-test .
  docker run --rm --privileged roamswitch-test
  ```
- Vulnerability reports: <https://lafine.net/.well-known/security.txt>

## Support

- **Bug reports & feature requests:** open an [Issue](../../issues) (templates provided)
- **Questions & discussion:** [Discussions](../../discussions)
- Release notes: [CHANGELOG.md](CHANGELOG.md) · Help: [FAQ](https://lafine.net/faq.html)

Japanese and English are both welcome in Issues.

## Links

- Website & download: https://lafine.net/
- [FAQ](https://lafine.net/faq.html) · [Privacy Policy](https://lafine.net/privacy.html) · [Changelog](CHANGELOG.md)

---

RoamSwitch is proprietary software. © Lafine Systems Design. This repository's documentation may be
quoted for the purpose of discussing or supporting the app.
