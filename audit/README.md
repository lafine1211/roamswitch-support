<!-- Language: **English** | [日本語](README.ja.md) -->

# Zero Telemetry egress audit

**English** | [日本語](README.ja.md)

Tooling to **measure** — not just assert — that RoamSwitch's only outbound
connections are the four documented in the whitepaper
([`docs/WHITEPAPER.md`](../docs/WHITEPAPER.md) §7):

| # | destination | process | when |
|---|---|---|---|
| 1 | `lafine.net /api/v1/license/*` | RoamSwitch | license activate / deactivate only |
| 2 | `lafine.net /updates/appcast.xml` | RoamSwitch | Sparkle (launch + every 24 h) |
| 3 | ClamAV mirrors | `freshclam` (not the app) | only if ClamAV is installed |
| 4 | `HEAD` to a target URL | RoamSwitch | only when you use the in-app Link Safety sheet |

This is heavier than [`../verify.sh`](../verify.sh): it runs packet captures,
drives the bundled MCP server, and (with `--tier-b`) temporarily quiets the
machine. Use `verify.sh` for a quick read-only check; use this to produce a shareable
`FINDINGS.md` (or for a third-party retest).

## Files

- **`rs-zerotel-audit.sh`** — the audit. Mostly automated; prompts for the few
  steps that need a human (helper approval, a real network move, in-app menu
  actions, the three GUI-only privacy toggles).
- **`CHECKLIST.txt`** / **`CHECKLIST.ja.txt`** — plain-text run sheet (EN / JA).
  Readable on the test machine with `less` (do **not** open a browser there).

## Requirements

- macOS 13+, Apple Silicon, an **admin** account (the script uses `sudo`)
- `tcpdump` (system), `tshark` — `brew install wireshark`
- optional: [LuLu](https://objective-see.org/products/lulu.html) — if installed,
  the script records its per-process outbound events from the unified log
  (`lulu.log`) so the write-up can quote a log excerpt rather than a screenshot

## Run

```sh
cd ~/rs-audit                       # a scratch dir; the script writes run-<ts>/ here
cp /path/to/rs-zerotel-audit.sh .
chmod +x rs-zerotel-audit.sh

./rs-zerotel-audit.sh all --tier-b --idle 2h    # prep + capture + analysis
./rs-zerotel-audit.sh all --idle 2h             # you handle environment prep yourself
./rs-zerotel-audit.sh all --tier-b --idle 8h    # extend the idle window overnight (optional)
./rs-zerotel-audit.sh prep-restore --outdir ~/rs-audit/run-XXXX   # undo prep
./rs-zerotel-audit.sh analyze --outdir ~/rs-audit/run-XXXX        # re-run analysis + FINDINGS.md
```

Subcommands: `all`, `prep`, `prep-restore`, `baseline`, `monitors`, `stop`,
`sparkle`, `mcp`, `analyze`, `findings`.

The active work is one sitting (~3-4 h). The idle capture defaults to 2 h; an
overnight window is optional and only adds coverage of a pure wall-clock daily
beacon.

## Output (`run-<timestamp>/`)

- `report.md` — verdict (PASS/FAIL) + the process-attributed flow table
- `FINDINGS.md` — shareable summary: method, results, and a "what this audit
  cannot show" section
- `entitlements-helper.txt` / `entitlements-mcp.txt`
- `lulu.log` / `lulu-roamswitch.txt` — LuLu events, if LuLu was installed
- raw `cap-*.pcap`, `lsof.log`, `timeline.txt`, …

## What it can't prove

- Not "no traffic at all" — the four paths above are real. Zero Telemetry means
  no collection/transmission of usage or diagnostic data.
- Not "never" — the claim is scoped to the observed window.
- RoamSwitch does not use App Sandbox, so entitlements don't *enforce* the
  absence of egress; the behaviour has to be shown, which is what this does.
- Payloads aren't inspected (destination + TLS SNI only). The MCP server and the
  detection logic are open source, so "what is sent to the LLM" is checkable in
  code: <https://github.com/lafine1211/roamswitch-mcp>

---

## Defense & Penetration Verification (macOS VM)

In addition to the Zero Telemetry egress audit, we provide automated tooling to verify RoamSwitch's 5 core defense boundaries (XPC client authorization, Packet Filter Air-Gap priority, port anomaly detection, read-only MCP invariant, and ARP integrity) on a macOS VM or physical test Mac:

- **[Defense & Penetration Verification Guide (English)](README-SECURITY.md)** (`rs-defense-audit.sh`)
- **[Verification Checklist (English)](CHECKLIST-SECURITY.txt)**
