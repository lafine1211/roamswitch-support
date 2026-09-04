# RoamSwitch for Linux — CLI / headless operations guide

**English** | [日本語](LINUX_CLI.ja.md)

How to run RoamSwitch for Linux without the GUI — on a server, over SSH, from
cron, or from a monitoring script. This covers the current **client edition**.
For the server edition (coming soon), see
<https://lafine.net/linux#editions>.

---

## 1. Components

| Component | Runs as | Role |
|---|---|---|
| `roamswitch-daemon` | root (systemd `Type=notify`) | Every privileged action: nftables control, network detection, ransomware/malware monitoring, fanotify, ARP/NDP pinning, DNS application. Opens no TCP/UDP socket. |
| `roamswitch` (CLI) | the login user | A thin front-end that reads the daemon's state. Uses only the Unix-domain-socket IPC at `/run/roamswitch/roamswitch.sock`. |
| `roamswitch-mcp` | spawned by an AI client | A read-only MCP server (stdio / JSON-RPC) for programmatic status. See [MCP setup](https://lafine.net/mcp-setup.html). |
| `roamswitch-app` | the login user | The GTK GUI. Not needed headless. |

**A headless deployment runs on `roamswitch-daemon` + `roamswitch` (plus
`roamswitch-mcp` if you want it).** All of the daemon's autonomous defense works
without `roamswitch-app`; actions that would raise an approval dialog either
fail open after 3 minutes or can be disabled in config.

---

## 2. The daemon (systemd service)

```sh
sudo systemctl status  roamswitch.service
sudo systemctl enable  roamswitch.service      # start at boot (enabled on install)
sudo systemctl restart roamswitch.service
journalctl -u roamswitch.service -f
journalctl -u roamswitch.service --since "1h ago"
```

What the daemon does on its own, at startup and every cycle (3 s):

- Identifies the connected gateway MAC and switches the nftables profile
  (`open` / `balanced` / `lockdown`) against `trusted_networks`
- Behavioural ransomware detection (fanotify + Shannon entropy + canaries)
- On-access malware scanning (fanotify, optionally ClamAV)
- ARP spoof monitoring; preventive gateway ARP/NDP pinning on untrusted networks
- Kernel hardening (sysctl / Yama / core dumps / `/tmp` noexec) per profile
- Applies / reverts threat-protection DNS (`dns_enabled` + `dns_scope`)
- Link guard (NFQUEUE) — warns about or blocks phishing connections
- Writes runtime state to `/run/roamswitch/state.json` every cycle

---

## 3. CLI command reference

`roamswitch <command> [options]`. No argument is the same as `status`. Output
language follows the OS locale (`LC_ALL` / `LC_MESSAGES` / `LANG`; `ja*` →
Japanese, anything else → English).

| Command | Description |
|---|---|
| `status` (alias `report`) | The 20-item security health assessment, a 0–100 score, a grade, and per-item advice |
| `ports [-a\|--all]` | TCP/UDP ports listening on 0.0.0.0, unauthenticated DBs, dev servers. `-a` also includes loopback-only ports |
| `guards` | Enabled/disabled state of each automatic guard (port anomaly, ARP, USB storage, download, DNS threat, canary, dev-server isolator, Bluetooth) |
| `wifi` | Current Wi-Fi encryption strength (Open / WEP / WPA / wired) and SSID |
| `sharing [status\|on\|off]` | Automatic stop/restore of SSH / Samba / RDP on untrusted networks. `on` writes `sharing_service_control_enabled` in `config.json` and asks the daemon to apply it now |
| `audit-url <URL>` | Score a URL's phishing / danger risk from the local feed + offline heuristics (never fetches the target) |
| `audit-secrets <text\|path>` | Detect API keys, private keys and tokens in text or a file (never transmits the content) |
| `audit-logs [hours]` | Aggregate and classify the last N hours (default 24) of journald / auth logs |
| `canary` | Ransomware canary (decoy file) deployment and integrity state |
| `quarantine [list]` | Contents of the malware Quarantine Vault (sample, original path, threat name, date) |
| `knowledge [query]` (alias `faq`) | Search the bundled offline knowledge base |
| `airgap [enable\|disable]` | Trigger / lift emergency Air-Gap isolation (hidden from `--help`). `enable` drops all external traffic; `disable` restores it |
| `help` (`--help` / `-h`) | Help |

### Examples

```sh
roamswitch status
roamswitch ports -a
roamswitch guards
roamswitch audit-url https://examp1e-login.com
roamswitch audit-secrets ./deploy.env
roamswitch audit-logs 72
roamswitch sharing on
roamswitch airgap enable
roamswitch airgap disable
```

### Caveats (current limitations)

- Some versions do not implement per-subcommand `--help` (`roamswitch status
  --help` runs the scan). Fixed in 1.0.43+.
- The CLI has **no `--json` output**. For machine-readable status use MCP (§6) or
  `/run/roamswitch/state.json` (§5).
- There is **no CLI command to switch the profile directly** (the daemon decides
  autonomously). To force it, set `manual_override` in `config.json` or call the
  `set_security_level` IPC directly (§5).
- `status` returns **exit code 0** regardless of the result. For monitoring,
  parse the score line (example in §7).

---

## 4. Configuration file

`~/.config/roamswitch/config.json` (JSON). **The daemon runs as root and scans
`/home/*/.config/roamswitch/config.json`, using the first one it finds** (on a
root-only headless server that is `/root/.config/roamswitch/config.json`). After
editing, either run a command that notifies the daemon (`roamswitch sharing …`)
or `sudo systemctl restart roamswitch.service`.

### Key fields

| Key | Type / default | Meaning |
|---|---|---|
| `language` | string / OS locale | Notification & CLI language (`ja` / `en` / `ko` / `zh-Hans` / `zh-Hant` / `de` / `fr` / `es` / `it` / `pt-PT`) |
| `trusted_networks` | `[{name, mac, level}]` | Trusted networks. `mac` is the gateway MAC; `level` is `open` / `balanced` / `lockdown` |
| `away_protection_level` | string / `lockdown` | Profile on an unregistered network |
| `manual_override` | string / null | Force `open` / `balanced` / `lockdown`; null = automatic |
| `dns_enabled` | bool / `true` | Threat-protection DNS |
| `dns_provider` | string / `quad9` | `quad9` / `cloudflare` / `adguard` / `cleanBrowsing` |
| `dns_scope` | string / `untrusted_only` | `untrusted_only` / `always_on` |
| `arp_spoof_guard_enabled` | bool / `true` | ARP spoof monitoring |
| `gateway_arp_lock_enabled` | bool / `true` | Preventive gateway ARP/NDP pinning on untrusted networks |
| `port_anomaly_guard_enabled` | bool / `true` | Auto-block new unknown listening ports |
| `system_wide_fanotify_enabled` | bool / `true` | System-wide fanotify malware guard |
| `pre_exec_blocking_enabled` | bool / `true` | Pre-execution blocking (FAN_DENY) |
| `entropy_freeze_enabled` | bool / `true` | Ransomware fast-freeze (SIGSTOP) |
| `mount_hardening_enabled` | bool / `true` | `noexec` on `/tmp` and `/dev/shm` (applied on non-`open` profiles) |
| `yama_memory_protect_enabled` | bool / `true` | Yama ptrace restriction |
| `usb_storage_guard_enabled` / `usb_keyboard_guard_enabled` | bool / `false` | USB storage / BadUSB keyboard guard (off by default) |
| `usb_zero_trust_enabled` | bool / `false` | USB bus authorized_default=0 |
| `bluetooth_guard_enabled` | bool / `false` | Stop the Bluetooth radio on untrusted networks (off by default) |
| `sharing_service_control_enabled` | bool / `true` | Auto stop/restore of SSH / Samba / RDP |
| `scan_exclusions` | `[string]` | Absolute paths excluded from both the YARA and ClamAV scanners (applied recursively) |
| `link_guard` | object | `{enabled, mode: "off"\|"warn"\|"block", allowlist, blocklist_extra, use_threat_dns}` |
| `vpn_on_untrusted_enabled` | bool / `false` | Bring the VPN tunnel up automatically on untrusted networks |
| `vpn_backend` | string / `wireguard` | `wireguard` / `tailscale` |

### Example (conservative settings for a headless server)

```jsonc
{
  "language": "en",
  "manual_override": "balanced",           // always balanced (pins the autonomous switch)
  "dns_enabled": true,
  "dns_scope": "always_on",
  "sharing_service_control_enabled": false, // don't cut SSH
  "system_wide_fanotify_enabled": true,
  "entropy_freeze_enabled": true,
  "mount_hardening_enabled": true,
  "link_guard": { "enabled": true, "mode": "block" },
  "scan_exclusions": ["/var/lib/myapp/cache", "/srv/backups"]
}
```

> ⚠️ With `sharing_service_control_enabled: true`, connecting to an untrusted
> network **disconnects any active SSH session**. Leave it off for remote
> operation.

---

## 5. Logs and runtime-state files

| Path | Contents |
|---|---|
| `journalctl -u roamswitch.service` | All daemon logs (profile switches, detections, errors) |
| `/run/roamswitch/state.json` | Updated every cycle: `{active_level, network_trusted, fanotify_ready}` |
| `/run/roamswitch/alerts.json` | Recent notification queue (the GUI reads it; headless you can watch it for detections) |
| `/run/roamswitch/approvals.json` | Pending-approval queue (malware confirmation, BadUSB, link_block, …) |
| `/run/roamswitch/fanotify.ready` | Present when the fanotify guard is actually running (contents: `content` / `notify`) |
| `~/.local/share/roamswitch/quarantine/` | Quarantine Vault (`0700`, samples `0400`) + `.metadata.json` |

### Calling the IPC directly (advanced)

The daemon accepts newline-delimited JSON on `/run/roamswitch/roamswitch.sock`
(a Unix stream). Examples of actions the CLI does not expose:

```sh
# Force a profile
printf '{"id":1,"method":"set_security_level","params":{"level":"lockdown"}}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock

# Reconcile the gateway ARP/NDP lock now
printf '{"id":1,"method":"reconcile_gateway_lock","params":null}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock
```

---

## 6. Programmatic status (MCP)

`roamswitch-mcp` exposes read-only tools over JSON-RPC on stdio
(`get_security_report` / `get_exposed_ports` / `get_guard_status` /
`get_quarantine_status` / `get_canary_status` / `audit_url_safety` /
`audit_secrets` / `audit_security_logs` / `get_app_help`). It uses no network —
it talks to the daemon's Unix socket or calls `roamswitch-core` directly. See
[MCP setup](https://lafine.net/mcp-setup.html).

---

## 7. Automation recipes

### Daily health check via cron → mail if the score drops below a threshold

```sh
#!/usr/bin/env bash
# /etc/cron.daily/roamswitch-health
out=$(runuser -u "$SUDO_USER" -- roamswitch status 2>&1)
score=$(printf '%s\n' "$out" | grep -oE '[0-9]+/100' | head -1 | cut -d/ -f1)
if [ -n "$score" ] && [ "$score" -lt 80 ]; then
  printf '%s\n' "$out" | mail -s "RoamSwitch health: ${score}/100" root
fi
```

### Watch for detection events (poll alerts.json)

```sh
#!/usr/bin/env bash
last=0
while :; do
  ts=$(jq -r 'max_by(.timestamp).timestamp // 0' /run/roamswitch/alerts.json 2>/dev/null || echo 0)
  if [ "$ts" -gt "$last" ]; then
    jq -c ".[] | select(.timestamp > $last)" /run/roamswitch/alerts.json | logger -t roamswitch-alert
    last=$ts
  fi
  sleep 10
done
```

### Verify the guard hasn't fallen over (state.json)

```sh
jq -e '.fanotify_ready == true' /run/roamswitch/state.json >/dev/null \
  || echo "WARNING: fanotify guard is not running" >&2
```

---

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| `roamswitch` exits with "check that roamswitch-mcp is installed" | The daemon isn't running → `sudo systemctl start roamswitch.service`. Check the socket `/run/roamswitch/roamswitch.sock` exists |
| `roamswitch status` shows the fanotify item 🔴 "guard stopped" | A transient `fs.fanotify.max_user_groups` (default 128) exhaustion. `sudo systemctl restart roamswitch.service`; confirm with `journalctl -u roamswitch \| grep "fanotify marks established"` |
| Profile stays `balanced`, never `open` | Check that the gateway MAC is registered in `trusted_networks` with `level: open` (if it's `balanced`, that is by design) |
| SSH drops suddenly | `sharing_service_control_enabled: true` plus an untrusted-network verdict. Run `roamswitch sharing off` for remote operation |
| Config change has no effect | The daemon reads the **first** `/home/*/.config/…` it finds. With multiple users, confirm it's the file you meant. Apply with `systemctl restart roamswitch.service` |

---

## 9. References

- Product page: <https://lafine.net/linux>
- Security whitepaper: <https://lafine.net/linux/whitepaper.en>
- MCP setup: <https://lafine.net/mcp-setup.html>
- FAQ: [FAQ.md](FAQ.md) · Privacy: [PRIVACY.md](PRIVACY.md)
