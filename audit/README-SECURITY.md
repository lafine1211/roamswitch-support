<!-- Language: **English** | [日本語](README-SECURITY.ja.md) -->

# RoamSwitch Defense & Penetration Verification Guide (macOS VM)

This guide and automated script (`rs-defense-audit.sh`) provide a repeatable, objective verification suite for testing RoamSwitch's core security boundaries on a target macOS Virtual Machine (VM).

It validates the architecture and security boundaries defined in the [RoamSwitch Whitepaper](../docs/WHITEPAPER.md) through live penetration probes and fault injection.

---

## Architecture Topology (Host Mac ⇄ Target Guest VM)

The verification topology is divided between the **Host Mac (Operator / Remote Attacker)** and the **macOS Guest VM (Target / Defense Under Test)**:

```
+------------------------------------+          +-----------------------------------------+
|          Host Mac (Host)           |          |         macOS VM (Target Guest)         |
|  - Boots VM with Tart / UTM        |  ----->  |  - Installs & launches RoamSwitch.app   |
|  - Transfers script via scp        |   SSH    |  - Executes rs-defense-audit.sh inside  |
|  - (Optional) Remote nmap/arpspoof |          |  - Validates 5 defense layers & reports |
+------------------------------------+          +-----------------------------------------+
```

---

## The 5 Defense Boundaries Under Test

| # | Defense Layer | Test & Attack Scenario | Whitepaper Reference | Expected Behavior |
|---|---|---|---|---|
| 1 | **Privileged Helper XPC Boundary** | Spoofed / ad-hoc caller attempting XPC command injection | §3 Privileged Helper Design | Strict rejection via Team ID & `audit_token` client validation |
| 2 | **Packet Filter (pf) Priority** | Air-Gap containment precedence over individual port rules | §4, §5 pf Handling & Containment | Fail-closed: all external egress is dropped (`block drop`) |
| 3 | **Port Anomaly Guard** | Detection of newly spawned `0.0.0.0` global listeners | §6 Untrusted Network Defense | Distinguishes globally exposed sockets from localhost (`127.0.0.1`) |
| 4 | **MCP Read-Only Invariant** | Verification of zero state-mutating APIs & JSON fuzzing | §8 MCP Security Model | 0 mutation tools exposed; resilient to deeply-nested JSON DoS |
| 5 | **ARP / Gateway Monitor** | Gateway MAC mismatch / spoofing detection | §11 Threat Model | Monitors ARP table integrity and triggers fail-safe containment |

---

## Step-by-Step Execution Guide

### Step 1: [Host Mac] Spin Up macOS Guest VM (Tart)

```sh
# Install Tart via Homebrew
brew trust cirruslabs/cli
brew install cirruslabs/cli/tart

# Clone and run a clean macOS VM
tart clone ghcr.io/cirruslabs/macos-sonoma-base:latest test-mac
tart run test-mac
```

---

### Step 2: [Inside VM] Install RoamSwitch & Approve Helper

Inside the VM's GUI or via SSH (`ssh admin@$(tart ip test-mac)`, password: `admin`):

```sh
# 1. Verify Swift command line tools
xcode-select --install

# 2. Download and install RoamSwitch
curl -sSL -o /tmp/RoamSwitch.dmg "https://lafine.net/downloads/RoamSwitch.dmg"
hdiutil attach /tmp/RoamSwitch.dmg
cp -R /Volumes/RoamSwitch/RoamSwitch.app /Applications/
hdiutil detach /Volumes/RoamSwitch

# 3. Launch RoamSwitch and approve privileged helper prompt
open /Applications/RoamSwitch.app
```

---

### Step 3: [Host Mac ➔ VM] Transfer Audit Script

From your Host terminal, transfer `rs-defense-audit.sh` into the VM:

```sh
# Obtain VM IP
VM_IP=$(tart ip test-mac)

# SCP into VM home directory
scp /Users/tetsuharu/Dev/roamswitch-support/audit/rs-defense-audit.sh admin@$VM_IP:~/
```

---

### Step 4: [Inside VM] Execute Audit Script

Inside the VM's terminal (or SSH session):

```sh
chmod +x ~/rs-defense-audit.sh

# Run full automated defense suite (generates report)
~/rs-defense-audit.sh all

# Or run individual boundary tests
~/rs-defense-audit.sh xpc      # XPC authorization boundary only
~/rs-defense-audit.sh pf       # Packet Filter & Air-Gap drop only
~/rs-defense-audit.sh port     # Port anomaly exposure detection only
~/rs-defense-audit.sh mcp      # MCP server Read-Only invariant & fuzzing
~/rs-defense-audit.sh arp      # ARP gateway monitoring only
```

---

## Artifacts & Report Output (Inside VM: `~/rs-defense-audit/run-<timestamp>/`)

- **`report.md`** — Comprehensive test execution table (PASS / FAIL) and environment metadata.
- **`FINDINGS-DEFENSE.md`** — Summary of findings for documentation and sharing.
- **`test_xpc.log`** / **`test_pf.log`** / **`test_port.log`** / **`test_mcp.log`** — Raw execution logs.

To destroy the test VM and revert completely to a pristine state:
```sh
# Run on Host Mac
tart delete test-mac
```

---

## Related Documentation

- [RoamSwitch Security Architecture Whitepaper](../docs/WHITEPAPER.md)
- [Zero Telemetry Egress Audit](README.md)
