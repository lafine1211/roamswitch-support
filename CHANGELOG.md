# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. Dates are release dates.

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
