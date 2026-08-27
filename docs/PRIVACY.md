<!-- [日本語](PRIVACY.ja.md) -->

# Privacy Policy

**English** | [日本語](PRIVACY.ja.md)

_Last updated: 2026-08-27_

RoamSwitch is built on a **Zero Telemetry** principle.

## What the app sends

**Nothing.** RoamSwitch performs no external network communication of its own:

- No analytics or usage tracking
- No crash reporting
- No advertising identifiers
- No background "phone home"

All security analysis (network detection, port scanning, health checks, ClamAV
scans, link auditing) runs **locally on your Mac**.

## Data stored on your Mac

RoamSwitch stores configuration locally (registered network fingerprints, guard
settings, allow‑lists, logs). This data never leaves your device. Uninstalling the
app and removing its Application Support folder deletes it.

## DNS threat protection

When enabled (Pro), this feature changes your system DNS resolver to a public
security resolver (e.g. Quad9 / Cloudflare Security) while you are on an untrusted
network, and restores your original settings when you return to a trusted network.
DNS queries are then handled by that resolver under **its** privacy policy;
RoamSwitch itself neither logs nor transmits your queries.

## Purchases

Buying a license happens on **https://lafine.net/** through a third‑party payment
processor. That transaction is governed by the website's and the processor's
privacy policies. License validation does not require ongoing communication.

## The MCP server

The bundled `RoamSwitchMCPServer` is read‑only and communicates only over local
standard input/output with an MCP client you configure. It has no network access.

## Contact

Questions about privacy: open an [Issue](../../issues) or contact us via
https://lafine.net/.
