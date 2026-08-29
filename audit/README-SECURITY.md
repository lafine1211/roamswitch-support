<!-- Language: **English** | [日本語](README-SECURITY.ja.md) -->

# RoamSwitch Defense & Penetration Verification Guide (macOS VM)

This guide and automated script (`rs-defense-audit.sh`) provide a repeatable, objective verification suite for testing RoamSwitch's core security boundaries on macOS (VM or physical test Mac).

It validates the architecture and security boundaries defined in the [RoamSwitch Whitepaper](../docs/WHITEPAPER.md) through live penetration probes and fault injection.

---

## The 5 Defense Boundaries Under Test

| # | Defense Layer | Test & Attack Scenario | Whitepaper Reference | Expected Behavior |
|---|---|---|---|---|
| 1 | **Privileged Helper XPC Boundary** | Spoofed / ad-hoc caller attempting XPC command injection | §3 Privileged Helper Design | Strict rejection via Team ID & \`audit_token\` client validation |
| 2 | **Packet Filter (pf) Priority** | Air-Gap containment precedence over individual port rules | §4, §5 pf Handling & Containment | Fail-closed: all external egress is dropped (\`block drop\`) |
| 3 | **Port Anomaly Guard** | Detection of newly spawned \`0.0.0.0\` global listeners | §6 Untrusted Network Defense | Distinguishes globally exposed sockets from localhost (\`127.0.0.1\`) |
| 4 | **MCP Read-Only Invariant** | Verification of zero state-mutating APIs & JSON fuzzing | §8 MCP Security Model | 0 mutation tools exposed; resilient to deeply-nested JSON DoS |
| 5 | **ARP / Gateway Monitor** | Gateway MAC mismatch / spoofing detection | §11 Threat Model | Monitors ARP table integrity and triggers fail-safe containment |

---

## Recommended Test Environment (macOS VM Setup)

To safely test firewall containment and system hooks without impacting your primary development machine, we recommend running on a macOS virtual machine via **Tart** or **UTM**.

### Using Tart (Apple Silicon)

```sh
# 1. Install Tart via Homebrew
brew trust cirruslabs/cli
brew install cirruslabs/cli/tart

# 2. Clone and launch a clean macOS VM
tart clone ghcr.io/cirruslabs/macos-sonoma-base:latest rs-test-vm
tart run rs-test-vm

# 3. Teardown / reset after testing
tart delete rs-test-vm
```

---

## Running the Automated Audit Script

```sh
# Copy script into the test environment
cp audit/rs-defense-audit.sh ~/
chmod +x ~/rs-defense-audit.sh

# Run full automated defense suite (generates report)
./rs-defense-audit.sh all

# Or run individual boundary tests
./rs-defense-audit.sh xpc      # XPC authorization boundary only
./rs-defense-audit.sh pf       # Packet Filter & Air-Gap drop only
./rs-defense-audit.sh port     # Port anomaly exposure detection only
./rs-defense-audit.sh mcp      # MCP server Read-Only invariant & fuzzing
./rs-defense-audit.sh arp      # ARP gateway monitoring only
```

---

## Artifacts & Report Output (`~/rs-defense-audit/run-<timestamp>/`)

- **`report.md`** — Comprehensive test execution table (PASS / FAIL) and environment metadata.
- **`FINDINGS-DEFENSE.md`** — Summary of findings for documentation and sharing.
- **`test_xpc.log`** / **`test_pf.log`** / **`test_port.log`** / **`test_mcp.log`** — Raw execution logs.

---

## Related Documentation

- [RoamSwitch Security Architecture Whitepaper](../docs/WHITEPAPER.md)
- [Zero Telemetry Egress Audit](README.md)
