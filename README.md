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
- Requires **macOS 13 Ventura or later** (Apple silicon & Intel)
- Latest version: **1.4.2**

## What it does

| Layer | Free | Pro Lifetime |
| :--- | :---: | :---: |
| Wi‑Fi auto‑detection & kernel packet blocking (`pf`) | ✅ | ✅ |
| Per‑profile security levels (Trusted / Standard / Lockdown) | ✅ | ✅ |
| Auto stop & restore of SSH / SMB / Screen Sharing / AirDrop | ✅ | ✅ |
| Mac security health check (FileVault / SIP / Gatekeeper / updates) | ✅ manual | ✅ + autonomous background sweep |
| Malware tooling (XProtect / ClamAV status & scan) | ✅ manual | ✅ + auto virus‑definition updates |
| Wi‑Fi encryption‑strength warnings, ARP‑spoofing detection, exposed‑port & USB monitoring | ✅ | ✅ |
| 🚨 Ransomware‑like behavior detection → emergency Air‑Gap isolation (`pf`) | ❌ | 🚀 |
| 🛡️ Dev‑server (`0.0.0.0`) LAN‑exposure quarantine guard | ❌ (list only) | 🚀 one‑click block |
| 🕳️ Port‑anomaly guard — auto‑block newly exposed listening ports (signature‑free) | ❌ | 🚀 |
| ⚡ ARP‑spoofing auto‑containment + real‑time notifications | ❌ (menu only) | 🚀 |
| 🔌 Unauthorized USB / BadUSB storage guard + auto ClamAV scan on mount | ❌ | 🚀 |
| 🌐 Web/Mail download guard, DNS threat protection, link‑safety auditor | ❌ | 🚀 |
| 📄 Log & diagnostics export (CSV / JSON) | ❌ | 🚀 |
| Devices | 1 | 2 |

## Pricing

One‑time purchase — no subscription.

| Plan | Price (JPY, incl. tax) | Price (USD) | Devices |
| :--- | :--- | :--- | :--- |
| **Free** | ¥0 | $0 | 1 |
| **Pro Lifetime** | **¥2,980** | **$19.99** | 2 |
| **Team / Family** | ¥6,980 | $49.99 | 5 |

Pro is a lifetime license with free updates. Purchase at **https://lafine.net/**.

## Privacy — Zero Telemetry

RoamSwitch performs **no external network communication of its own**: no analytics,
no crash reporting, no license "phone home" beyond the one‑time purchase checkout on
the website. The bundled MCP server is read‑only and speaks local stdio only. See
[docs/PRIVACY.md](docs/PRIVACY.md).

## MCP server (for Claude Desktop / Claude Code)

RoamSwitch ships a **read‑only** Model Context Protocol server so MCP clients can query
your Mac's security posture. No lockdown/quarantine/eject actions are exposed.

```sh
claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
```

Tools: `get_security_report`, `get_exposed_ports`, `get_guard_status`, `audit_url_safety`.

## Support

- **Bug reports & feature requests:** open an [Issue](../../issues) (templates provided)
- **Questions & discussion:** [Discussions](../../discussions)
- Release notes: [CHANGELOG.md](CHANGELOG.md) · Help: [docs/FAQ.md](docs/FAQ.md)

Japanese and English are both welcome in Issues.

## Links

- Website & download: https://lafine.net/
- [FAQ](docs/FAQ.md) · [Privacy Policy](docs/PRIVACY.md) · [Changelog](CHANGELOG.md)

---

RoamSwitch is proprietary software. © Lafine. This repository's documentation may be
quoted for the purpose of discussing or supporting the app.
