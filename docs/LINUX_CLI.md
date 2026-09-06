# RoamSwitch for Linux — CLI / Headless Operations Guide

**English** | [日本語](LINUX_CLI.ja.md)

How to operate RoamSwitch for Linux without the GUI — on a server, over SSH, from cron, or from monitoring scripts.

> [!TIP]
> **Choosing the Edition**:
> - **Client Edition (`roamswitch`)**: Designed for laptops, mobile workstations, and developer devices. Autonomously switches nftables firewall profiles based on the connected network's trust level. This guide focuses primarily on headless/CLI management of the Client Edition.
> - **Server Edition (`roamswitch-server`)**: Designed for cloud VPS instances (AWS, GCP, DigitalOcean, Linode, etc.) and on-premises servers exposed directly to the Internet. Features inbound default-drop filtering, SSH lockout prevention, Critical-Path File Integrity Monitoring (FIM), eBPF / Falco runtime integration, and instant notifications (Telegram / LINE / Webhooks). For full installation and management instructions, see the **[RoamSwitch Server Edition Operations Manual](SERVER_MANUAL.md)** (Web: <https://lafine.net/linux/server-manual.en>) and the [Server Security Whitepaper](https://lafine.net/linux/server-whitepaper.en).

---

## 1. Components

| Component | Runs as | Role |
|---|---|---|
| `roamswitch-daemon` (Client) | root (systemd `Type=notify`) | All client privileged operations: nftables control, network detection, ransomware/malware monitoring, fanotify, ARP/NDP pinning, DNS enforcement. Opens no TCP/UDP listening socket. |
| `roamswitch-server-daemon` (Server) | root (systemd `Type=notify`) | All server privileged operations: inbound default drop, SSH & admin bastion preservation, FIM (150+ critical binary hashes), Falco eBPF UNIX socket listener with autonomous `SIGSTOP` freezing, alert dispatching. |
| `roamswitch` (CLI) | login user (some actions require sudo) | Thin client reading daemon state. Uses `/run/roamswitch/roamswitch.sock` IPC on Client Edition, or provides `--server`, `server`, `fim`, and `emergency-restore` subcommands on Server Edition. |
| `roamswitch-mcp` | spawned by AI clients | Read-only MCP server (stdio / JSON-RPC) for programmatic status retrieval by AI agents. See [MCP setup](https://lafine.net/mcp-setup.html). |
| `roamswitch-app` | login user | GTK GUI (Client Edition only). Not needed in headless environments. |

**A headless deployment runs on the daemon + `roamswitch` CLI (plus `roamswitch-mcp` if desired).** All autonomous defense mechanisms work without any GUI.

> [!NOTE]
> Client Edition (`roamswitch`) and Server Edition (`roamswitch-server`) are mutually exclusive packages (`Conflicts`). Deploy `roamswitch-server` on server environments.

---

## 2. Daemon (systemd services)

### Client Edition
```sh
sudo systemctl status  roamswitch.service      # Status
sudo systemctl enable  roamswitch.service      # Auto-start on boot (enabled on install)
sudo systemctl restart roamswitch.service      # Restart
journalctl -u roamswitch.service -f            # Follow logs
journalctl -u roamswitch.service --since "1h ago"
```

What the client daemon does autonomously on startup and every cycle (3 s):
- Identifies the connected gateway MAC and applies nftables profiles (`open` / `balanced` / `lockdown`) against `trusted_networks`
- Behavioural ransomware detection (fanotify + Shannon entropy + canaries)
- On-access malware scanning (fanotify, optionally ClamAV)
- ARP spoof monitoring and preventive gateway ARP/NDP pinning on untrusted networks
- Kernel hardening (sysctl / Yama / core dumps / `/tmp` noexec) per profile
- Threat-protection DNS enforcement (`dns_enabled` + `dns_scope`)
- Link guard (NFQUEUE) for phishing interception
- Runtime state output to `/run/roamswitch/state.json`

### Server Edition
```sh
sudo systemctl status  roamswitch-server.service      # Status
sudo systemctl restart roamswitch-server.service      # Restart
sudo systemctl reload  roamswitch-server.service      # Reload configuration
journalctl -u roamswitch-server.service -f            # Follow logs
```

---

## 3. CLI Command Reference

`roamswitch <command> [options]`. Running without arguments defaults to `status`. Output language follows the OS locale (`LC_ALL` / `LC_MESSAGES` / `LANG`; `ja*` selects Japanese, other locales default to English).

| Command | Permissions | Description |
|---|---|---|
| `status [--server]` (alias `report` / `server-status`) | User | Security health assessment (20 checks on client, 25 checks with `--server`), 0–100 score, grade, and per-item recommendations |
| `server [config\|setup\|test-notify\|restart]` | User/root | Server Edition configuration management, interactive setup wizard, and test notifications |
| `fim [verify\|update]` | User/root | Critical-Path File Integrity Monitoring verification (`verify`) and baseline hash database update (`update`) |
| `emergency-restore` | root | Lift all emergency eBPF / firewall isolations and restore network baseline |
| `ports [-a\|--all]` | User | Listening ports on 0.0.0.0, unauthenticated DBs, and dev servers. `-a` includes loopback-only ports |
| `guards` | User | Status of automatic defense guards (port anomaly, ARP, USB storage, download, DNS threat, canary, dev-server isolator, Bluetooth) |
| `wifi` | User | Wi-Fi encryption strength (Open / WEP / WPA / wired) and SSID |
| `sharing [status\|on\|off]` | User | Auto-stop / restore of SSH / Samba / RDP on untrusted networks (`on` disconnects active SSH when untrusted) |
| `audit-url <URL>` | User | Inspect URL phishing and threat risk via local feed + heuristics (never fetches target) |
| `audit-secrets <text\|path>` | User | Detect API keys, private keys, and tokens in text or files (never transmits data) |
| `audit-logs [hours]` | User | Aggregate and classify system journald / auth logs from the last N hours (default 24) |
| `canary` | User | Ransomware canary decoy file status and integrity |
| `quarantine [list]` | User | Contents of malware quarantine vault (sample, original path, threat name, date) |
| `knowledge [query]` (alias `faq`) | User | Search the offline knowledge base |
| `airgap [enable\|disable]` | User/root | Trigger or lift emergency Air-Gap isolation (`enable` drops all external traffic) |
| `help` (`--help` / `-h`) | User | Show help (`roamswitch <command> --help` for subcommand help) |

### Examples

```sh
roamswitch status                      # Client health check (20 items)
roamswitch status --server             # Server health check (25 items)
roamswitch ports -a                    # All listening ports
roamswitch guards                      # Guard status
roamswitch audit-url https://examp1e-login.com
roamswitch audit-secrets ./deploy.env
roamswitch audit-logs 72               # Analyze last 72 hours of logs
roamswitch sharing on                  # Automatically stop SSH/Samba/RDP on untrusted networks
roamswitch fim verify                  # FIM file integrity verification
sudo roamswitch fim update             # Update FIM baseline hashes
sudo roamswitch emergency-restore      # Lift all emergency isolations
roamswitch airgap enable               # Trigger Air-Gap isolation
roamswitch airgap disable              # Restore traffic
```

### Caveats & Limitations

- Subcommand-specific help is supported via `roamswitch <command> --help`.
- Machine-readable status should be queried via MCP (§6) or `/run/roamswitch/state.json` (§5).
- In the Client Edition, there is no direct command to force a firewall profile; the daemon manages this autonomously based on network trust. To force a level, configure `manual_override` in `config.json` or call the `set_security_level` IPC directly (§5).
- `status` returns exit code 0 regardless of score. For automated monitoring, parse the score line (see §7).

---

## 4. Configuration Files

### Client Edition (`~/.config/roamswitch/config.json`)

The daemon runs as root and scans `/home/*/.config/roamswitch/config.json`, using the first valid file it finds (or `/root/.config/roamswitch/config.json` in root-only environments).

| Key | Type / Default | Description |
|---|---|---|
| `language` | string / OS locale | UI & CLI language (`ja` / `en` / `ko` / `zh-Hans` / `zh-Hant` / `de` / `fr` / `es` / `it` / `pt-PT`) |
| `trusted_networks` | `[{name, mac, level}]` | Trusted networks; `mac` is gateway MAC, `level` is `open` / `balanced` / `lockdown` |
| `away_protection_level` | string / `lockdown` | Default profile on unknown networks |
| `manual_override` | string / null | Force `open` / `balanced` / `lockdown` (null for automatic) |
| `dns_enabled` | bool / `true` | Threat-protection DNS enforcement |
| `dns_provider` | string / `quad9` | `quad9` / `cloudflare` / `adguard` / `cleanBrowsing` |
| `dns_scope` | string / `untrusted_only` | `untrusted_only` / `always_on` |
| `arp_spoof_guard_enabled` | bool / `true` | ARP spoof monitoring |
| `gateway_arp_lock_enabled` | bool / `true` | Preventive gateway ARP/NDP lock on untrusted networks |
| `port_anomaly_guard_enabled` | bool / `true` | Auto-block new listening ports |
| `system_wide_fanotify_enabled` | bool / `true` | System-wide fanotify malware guard |
| `pre_exec_blocking_enabled` | bool / `true` | Pre-execution blocking (`FAN_DENY`) |
| `entropy_freeze_enabled` | bool / `true` | Ransomware fast-freeze (`SIGSTOP`) |
| `mount_hardening_enabled` | bool / `true` | `noexec` on `/tmp` and `/dev/shm` (applied on non-open profiles) |
| `yama_memory_protect_enabled` | bool / `true` | Yama ptrace restrictions |
| `usb_storage_guard_enabled` / `usb_keyboard_guard_enabled` | bool / `false` | USB storage / BadUSB keyboard guard (off by default) |
| `usb_zero_trust_enabled` | bool / `false` | USB bus authorized_default=0 |
| `bluetooth_guard_enabled` | bool / `false` | Disable Bluetooth radio on untrusted networks |
| `sharing_service_control_enabled` | bool / `true` | Auto-stop/restore SSH / Samba / RDP |
| `scan_exclusions` | `[string]` | Absolute paths excluded from scanning |
| `link_guard` | object | `{enabled, mode: "off"\|"warn"\|"block", allowlist, blocklist_extra, use_threat_dns}` |
| `vpn_on_untrusted_enabled` | bool / `false` | Auto-start VPN tunnel on untrusted networks |
| `vpn_backend` | string / `wireguard` | `wireguard` / `tailscale` |

> ⚠️ With `sharing_service_control_enabled: true`, connecting to an untrusted network **disconnects active SSH sessions**. Leave it disabled on headless servers.

### Server Edition (`/etc/roamswitch/server.conf`)

Server Edition uses an INI-format configuration file with strict permissions (`0600`, root-only). Refer to **[SERVER_MANUAL.md](SERVER_MANUAL.md)** for complete parameter descriptions.

---

## 5. Logs & Runtime State Files

| Path | Target | Description |
|---|---|---|
| `journalctl -u roamswitch.service` | Client | Client daemon logs (profile switches, detections, errors) |
| `journalctl -u roamswitch-server.service` | Server | Server daemon logs (FIM events, Falco detections, isolations) |
| `/run/roamswitch/roamswitch.sock` | Client | Client daemon IPC Unix domain socket |
| `/run/roamswitch/events.sock` | Server | Falco / Tetragon eBPF integration socket (root:root, mode 0660; Falco runs as root by default, enabling zero-config direct socket writes) |
| `/run/roamswitch/state.json` | Client | Cycle state: `{active_level, network_trusted, fanotify_ready}` |
| `/run/roamswitch/alerts.json` | Client | Recent alert queue |
| `/run/roamswitch/approvals.json` | Client | Pending approval queue |
| `/run/roamswitch/fanotify.ready` | Client | Flag file indicating fanotify guard is running |
| `/var/lib/roamswitch/fim_baseline.db` | Server | FIM SHA-256 baseline hash database |
| `~/.local/share/roamswitch/quarantine/` | Both | Quarantine Vault (`0700`, samples `0400`) + `.metadata.json` |

### Calling IPC Directly (Advanced)

The daemon accepts newline-delimited JSON on `/run/roamswitch/roamswitch.sock`:

```sh
# Force a security level (Client Edition)
printf '{"id":1,"method":"set_security_level","params":{"level":"lockdown"}}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock

# Reconcile gateway ARP lock immediately
printf '{"id":1,"method":"reconcile_gateway_lock","params":null}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock
```

---

## 6. Programmatic Status (MCP)

`roamswitch-mcp` exposes read-only tools over JSON-RPC on stdio (`get_security_report` / `get_exposed_ports` / `get_guard_status` / `get_quarantine_status` / `get_canary_status` / `audit_url_safety` / `audit_secrets` / `audit_security_logs` / `get_app_help`). It uses no external network communication, connecting locally to the daemon socket or calling `roamswitch-core`. See [MCP Setup](https://lafine.net/mcp-setup.html).

---

## 7. Automation Recipes

### Daily cron health check → Email if score drops below threshold

```sh
#!/usr/bin/env bash
# /etc/cron.daily/roamswitch-health
out=$(runuser -u "$SUDO_USER" -- roamswitch status 2>&1)
score=$(printf '%s\n' "$out" | grep -oE '[0-9]+/100' | head -1 | cut -d/ -f1)
if [ -n "$score" ] && [ "$score" -lt 80 ]; then
  printf '%s\n' "$out" | mail -s "RoamSwitch health: ${score}/100" root
fi
```

### Monitor alerts queue (poll alerts.json)

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

### Verify fanotify guard health (state.json)

```sh
jq -e '.fanotify_ready == true' /run/roamswitch/state.json >/dev/null \
  || echo "WARNING: fanotify guard is not running" >&2
```

---

## 8. Troubleshooting

| Symptom | Resolution |
|---|---|
| `roamswitch` exits with "check that roamswitch-mcp is installed" | Daemon is not running → `sudo systemctl start roamswitch.service` (or `roamswitch-server.service`). Verify socket exists |
| `roamswitch status` shows fanotify 🔴 "guard stopped" | Transient `fs.fanotify.max_user_groups` exhaustion. Restart with `sudo systemctl restart roamswitch.service` and verify in journal |
| Profile stays in `balanced`, never reaches `open` | Verify gateway MAC is registered in `trusted_networks` with `level: open` |
| SSH disconnects unexpectedly | Client edition has `sharing_service_control_enabled: true` on an untrusted network. Disable via `roamswitch sharing off` |
| Config changes do not take effect | Client daemon reads the first `/home/*/.config/…` found; restart with `sudo systemctl restart roamswitch.service`. Server edition: edit `/etc/roamswitch/server.conf` and run `sudo systemctl reload roamswitch-server` |
| Server communications accidentally blocked | Access cloud console (VNC / Serial) and run `sudo roamswitch emergency-restore` |

---

## 9. References

- Product Page: <https://lafine.net/linux>
- Client Security Whitepaper: <https://lafine.net/linux/whitepaper.en>
- Server Security Whitepaper: <https://lafine.net/linux/server-whitepaper.en>
- Server Operations Manual: [SERVER_MANUAL.md](SERVER_MANUAL.md) (Web: <https://lafine.net/linux/server-manual.en>)
- MCP Setup: <https://lafine.net/mcp-setup.html>
- FAQ: [FAQ.md](FAQ.md) · Privacy: [PRIVACY.md](PRIVACY.md)
