# RoamSwitch Server Edition — Operations Manual

**English** | [日本語](SERVER_MANUAL.ja.md)

This document is the official operations manual for **RoamSwitch Server Edition**, running on Cloud VPS (AWS, GCP, Azure, Linode, DigitalOcean, etc.), on-premise data centers, and container hosts. It covers installation, initial configuration, routine operations, security monitoring, and troubleshooting.

---

## 1. Overview & System Requirements

RoamSwitch Server Edition is a **completely headless (zero GUI dependencies) autonomous security and integrity defense suite** engineered for Linux servers continuously exposed to the public Internet.

### 1.1 Core Capabilities
- **Zero Telemetry**: Transmits zero telemetry, crash reports, or logs to third-party or vendor servers. Runs 100% locally.
- **Inbound Default Drop**: Drops all inbound packets via `nftables` by default, stealthing unexposed ports. Only administrator-approved ports (e.g. 22, 80, 443) are permitted.
- **SSH Lockout Prevention Failsafe**: Preserves established and authorized SSH management sessions even during emergency isolation (Air-Gap), preventing accidental lockouts.
- **Critical Path File Integrity Monitoring (FIM)**: Tracks 150+ critical system binaries and authentication configurations with SHA-256 hashes. Synchronizes baselines automatically during system upgrades via APT/DNF hooks.
- **eBPF Runtime Guard & Falco Integration**: Connects via a dedicated UNIX domain socket (`/run/roamswitch/events.sock`) to eliminate disk I/O and log bloat. Detects kernel LPEs (such as Frag Gap CVE-2026-53362) and freezes hostile processes (`SIGSTOP`) in milliseconds.
- **Docker / Podman Container Protection**: Integrates with the `DOCKER-USER` chain to prevent containers from bypassing the host firewall.
- **Emergency Notifications**: Immediate alerts sent directly to Telegram, LINE Messaging API, or generic Webhooks (Slack, Discord, PagerDuty).
- **AI / MCP Native**: Built-in read-only Model Context Protocol (MCP) server for autonomous AI management agents.

### 1.2 System Requirements
- **Supported Distributions**:
  - Ubuntu 22.04 / 24.04 LTS
  - Debian 12 (Bookworm)+
  - AlmaLinux / Rocky Linux / RHEL 9+
  - Fedora 39+
  - openSUSE Leap 15.5+ / Tumbleweed
  - Raspberry Pi OS (64-bit)
- **Architectures**: `x86_64` (amd64) or `aarch64` (arm64)
- **Kernel Requirements**: Linux 5.10+ (`nftables`, `cgroups v2`, eBPF BTF recommended)
- **Resource Footprint**: 20–30 MB resident memory, <0.1% CPU under idle/normal operation

---

## 2. Installation Procedures

### 2.1 APT (Ubuntu / Debian / Raspberry Pi OS)

```bash
# 1. Register official archive signing key
curl -fsSL https://lafine.net/apt/roamswitch-archive-keyring.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/roamswitch-archive-keyring.gpg

# 2. Add repository source
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/roamswitch-archive-keyring.gpg] https://lafine.net/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/roamswitch.list

# 3. Update index and install
sudo apt update
sudo apt install roamswitch-server
```

### 2.2 DNF / RPM (Fedora / RHEL / AlmaLinux / Rocky Linux)

```bash
# 1. Import repository GPG key
sudo rpm --import https://lafine.net/rpm/RPM-GPG-KEY-roamswitch

# 2. Add repository config
sudo curl -fsSL -o /etc/yum.repos.d/roamswitch.repo https://lafine.net/rpm/fedora/roamswitch.repo

# 3. Install
sudo dnf install roamswitch-server
```

### 2.3 openSUSE (zypper)

```bash
sudo rpm --import https://lafine.net/rpm/RPM-GPG-KEY-roamswitch
sudo zypper addrepo https://lafine.net/rpm/opensuse/roamswitch.repo
sudo zypper refresh
sudo zypper install roamswitch-server
```

> [!NOTE]
> `roamswitch` (Client Edition) and `roamswitch-server` (Server Edition) are mutually exclusive packages (`Conflicts`). Always select `roamswitch-server` on server systems.

---

## 3. Service Verification & Initial Setup

### 3.1 Verify Service Status

Upon installation, `roamswitch-server.service` starts automatically and is enabled on system boot:

```bash
sudo systemctl status roamswitch-server.service
```

### 3.2 Interactive Setup Wizard

Run the interactive setup wizard to configure exposed ports and notifications:

```bash
sudo roamswitch setup --server
```

The wizard guides you through:
1. **Public Listening Ports**: e.g., `22, 80, 443`
2. **Authorized Bastion IPs**: e.g., `203.0.113.50/32` (leave blank to allow SSH from any source)
3. **Emergency Alert Webhooks**: Telegram / LINE / Generic Webhook
4. **Initial FIM Snapshot Generation**: Generating the SHA-256 database for critical path binaries

### 3.3 25-Item Server Security Assessment

```bash
roamswitch status --server
```

Audits firewall state, Frag Gap mitigation, permissions, Docker exposure, SSH configuration, returning a score (0–100) and actionable remediation recommendations.

---

## 4. Configuration Reference (`/etc/roamswitch/server.conf`)

Protected by `0600` permissions (readable and writable only by `root`):

```ini
[network]
# Permitted inbound TCP/UDP ports
allowed_ports = 22, 80, 443

# Authorized admin/bastion CIDRs for SSH access
admin_source_ips = 203.0.113.10/32, 198.51.100.0/24

# Prevent Docker port bypass (injects rules into DOCKER-USER chain)
protect_docker_ports = true

# Maintain active SSH sessions during Air-Gap isolation
preserve_ssh_on_isolation = true

[fim]
# Enable critical path file integrity monitoring
enabled = true
# Hash scan interval in seconds
scan_interval = 300
# Excluded paths
exclude_paths = /var/log, /tmp, /run

[ebpf]
# Falco / Tetragon event socket
socket_path = /run/roamswitch/events.sock
# Autonomous containment action: "isolate" (Air-Gap) | "freeze" (SIGSTOP) | "alert_only"
action_on_critical = isolate

[notifications]
# Alert language: "en" | "ja"
language = en
# Telegram Bot
telegram_bot_token = 
telegram_chat_id = 
# LINE Messaging API
line_channel_access_token = 
line_user_id = 
# Generic Webhook (Slack, Discord, monitoring systems)
webhook_url = https://hooks.slack.com/services/XXXXX/YYYYY/ZZZZZ
```

Reload daemon after manual modifications:
```bash
sudo systemctl reload roamswitch-server
```

---

## 5. Critical Path File Integrity Monitoring (FIM)

Monitors essential system binaries (`/bin/login`, `/usr/bin/sudo`), authentication configs (`/etc/shadow`, `/etc/pam.d/`), and systemd units.

### 5.1 Manual Verification
```bash
roamswitch fim verify
```

### 5.2 Automatic Baseline Updating
On Debian/Ubuntu, `/etc/apt/apt.conf.d/99roamswitch-fim` updates the baseline automatically after `apt upgrade`.

To update the baseline manually after software modifications:
```bash
sudo roamswitch fim update
```

---

## 6. eBPF Runtime Guard & Falco Integration

Detects kernel-level system calls, container escapes, and Frag Gap (CVE-2026-53362) privilege escalation attacks.

### 6.1 Anti-Bloat Configuration
Included out of the box:
- `/etc/falco/config.d/99-roamswitch-optimized.yaml`:
  - Routes alerts directly to `/run/roamswitch/events.sock` over a UNIX domain socket.
  - Zero disk I/O, preventing disk bloat.
- `/etc/logrotate.d/roamswitch-falco`:
  - Daily rotation with 3 compressed generation retentions.

### 6.2 Autonomous Reaction on Incident
When Falco detects critical events (e.g. reverse shell, Frag Gap payload execution):
1. **Freeze**: Issues `SIGSTOP` immediately to freeze the offending process PID.
2. **Isolate**: Dynamically drops outbound and inbound traffic for the offender or entire host.
3. **Notify**: Broadcasts rich incident telemetry to Telegram/LINE/Webhook.

---

## 7. AI Agent / MCP Integration (Model Context Protocol)

Bundled with `roamswitch-mcp` for autonomous AI infrastructure managers (Claude, Gemini, Cursor, etc.).

### 7.1 Security & Safety Design (Read-Only)
The MCP interface is strictly read-only (`get_*`, `audit_*`). AI agents cannot mutate firewall rules, disable isolation, or expose ports via MCP, neutralizing prompt injection risks.

### 7.2 Configuration Example (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "roamswitch": {
      "command": "/usr/bin/roamswitch-mcp",
      "args": []
    }
  }
}
```

---

## 8. CLI Command Cheat Sheet

| Command | Privileges | Description |
|---|---|---|
| `roamswitch status --server` | User | Show 25-item server posture score & status |
| `roamswitch ports` | User | Audit open listening ports and bound processes |
| `roamswitch fim verify` | User | Verify integrity of critical path binaries & configs |
| `sudo roamswitch setup --server` | Root | Interactive initial configuration wizard |
| `sudo roamswitch fim update` | Root | Refresh FIM SHA-256 baseline database |
| `sudo roamswitch emergency-allow` | Root | Temporary 15-minute complete firewall bypass for troubleshooting |
| `sudo roamswitch isolate` | Root | Trigger immediate emergency Air-Gap host isolation |
| `sudo roamswitch un-isolate` | Root | Disarm isolation and restore standard protection policy |

---

## 9. Troubleshooting

### Q1. Will RoamSwitch drop my current SSH session?
A. No. RoamSwitch explicitly preserves existing ESTABLISHED/RELATED states and allows configured management ports (`allowed_ports`, default 22). Even during Air-Gap isolation, `preserve_ssh_on_isolation = true` protects your connection.

### Q2. How to recover if accidentally locked out?
A. Access the host via your cloud provider's VNC / serial web console, then execute `sudo roamswitch emergency-allow` or `sudo systemctl stop roamswitch-server`.

### Q3. Opening ports for a new service (e.g., Nginx)?
A. Append the required ports (e.g., `80, 443`) to `allowed_ports` in `/etc/roamswitch/server.conf`, then run `sudo systemctl reload roamswitch-server`.
