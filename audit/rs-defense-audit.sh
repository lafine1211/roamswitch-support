#!/bin/bash
#
# rs-defense-audit.sh — RoamSwitch Defense & Penetration Verification Suite
#
# Automated security validation suite for testing RoamSwitch's core defense
# boundaries on macOS (VM or physical test Mac).
#
# Verifies the 5 security boundaries documented in the Whitepaper:
#   1. XPC Client Authorization Boundary (§3) — Unsigned/unauthorized caller rejection
#   2. Packet Filter (pf) Priority & Air-Gap Containment (§4, §5) — Fail-closed traffic drop
#   3. Port Anomaly & Global Exposure Detection (§6) — Detection of 0.0.0.0 vs 127.0.0.1
#   4. MCP Read-Only Invariant & Parser Robustness (§8) — Zero mutation API & hostile JSON handling
#   5. ARP Anomaly & Fail-Safe Recovery (§5, §11) — Crash resilience and containment trigger
#
# Usage:
#   ./rs-defense-audit.sh all                 # Run full automated defense suite
#   ./rs-defense-audit.sh xpc                 # Test XPC authorization boundary only
#   ./rs-defense-audit.sh pf                  # Test Packet Filter & Air-Gap containment
#   ./rs-defense-audit.sh port                # Test Port Anomaly & global exposure detection
#   ./rs-defense-audit.sh mcp                 # Test MCP Read-Only invariant & parser robustness
#   ./rs-defense-audit.sh arp                 # Test ARP monitoring & anomaly detection
#   ./rs-defense-audit.sh report --outdir DIR # Re-generate markdown report from logs
#
set -u

VERSION="1.4.8"
APP_PATH="/Applications/RoamSwitch.app"
HELPER_LABEL="com.tetsuharu.RoamSwitch.Helper"
HELPER_BIN="/Library/PrivilegedHelperTools/$HELPER_LABEL"
MCP_BIN="$APP_PATH/Contents/MacOS/RoamSwitchMCPServer"
TEAM_ID="GV76B6G4YU"
OUTDIR=""
OVERALL=""
MCP_INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"defense-audit","version":"1"}}}'

# ------------------------------------------------------------------ styling ---
say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
pass() { printf '\033[32m[PASS]\033[0m %s\n' "$*"; }
fail() { printf '\033[31m[FAIL]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
hr()   { printf -- '---------------------------------------------------------------\n'; }

# ------------------------------------------------------------------ helpers ---
need() { command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed ($2)"; }

init_outdir() {
  if [ -z "$OUTDIR" ]; then
    local ts
    ts=$(date "+%Y%m%d-%H%M%S")
    OUTDIR="$HOME/rs-defense-audit/run-$ts"
  fi
  mkdir -p "$OUTDIR"
  # a stale result from an earlier run in the same dir must never be reported as this run's
  rm -f "$OUTDIR"/result_*.txt
  say "Audit output directory: $OUTDIR"
}

# ---------------------------------------------------------------- preflight ---
preflight_check() {
  say "Running Preflight Checks..."
  need swift "Install Xcode Command Line Tools: xcode-select --install"
  need python3 "Python 3 is required for network probe simulations"
  need curl "curl is required for connectivity checks"

  [ -d "$APP_PATH" ] || warn "$APP_PATH not found in standard location. (Running standalone tests)"
  [ -x "$MCP_BIN" ] || warn "MCP binary not found at $MCP_BIN"
}

# -------------------------------------------------- 1. XPC Boundary Test ---
test_xpc_boundary() {
  hr
  say "1. Testing XPC Authorization Boundary (§3)..."
  local log="$OUTDIR/test_xpc.log"
  local src="$OUTDIR/xpc_probe.swift"
  local bin="$OUTDIR/xpc_probe"

  cat > "$src" << 'SWIFT'
import Foundation

@objc protocol RoamSwitchHelperTestProtocol {
    func enableAirGap(reason: String, reply: @escaping (NSError?) -> Void)
    func restoreRules(reply: @escaping (NSError?) -> Void)
}

let serviceName = "com.tetsuharu.RoamSwitch.Helper"
let connection = NSXPCConnection(machServiceName: serviceName, options: [])
let iface = NSXPCInterface(with: RoamSwitchHelperTestProtocol.self)
connection.remoteObjectInterface = iface

var rejected = false
let sema = DispatchSemaphore(value: 0)

connection.invalidationHandler = {
    rejected = true
    sema.signal()
}
connection.interruptionHandler = {
    rejected = true
    sema.signal()
}

connection.resume()

let proxy = connection.remoteObjectProxyWithErrorHandler { error in
    rejected = true
    sema.signal()
} as? RoamSwitchHelperTestProtocol

proxy?.enableAirGap(reason: "unauthorized_security_audit") { error in
    if error == nil {
        print("VULNERABLE: Helper accepted call from unauthorized ad-hoc client!")
        exit(2)
    } else {
        rejected = true
        sema.signal()
    }
}

_ = sema.wait(timeout: .now() + 3.0)

if rejected {
    print("REJECTED: Helper rejected unauthorized client as expected.")
    exit(0)
} else {
    print("NO_RESPONSE: Helper did not answer within timeout.")
    exit(1)
}
SWIFT

  # The probe cannot tell "helper rejected me" from "helper is not installed" (both invalidate the
  # connection), so a not-installed helper must be ruled out first or it would be a false PASS.
  if [ ! -e "$HELPER_BIN" ] || ! launchctl print "system/$HELPER_LABEL" >/dev/null 2>&1; then
    warn "Privileged helper is not installed/loaded ($HELPER_LABEL): XPC boundary NOT tested."
    echo "SKIPPED (helper not installed)" > "$OUTDIR/result_xpc.txt"
    return 0
  fi

  # Compile ad-hoc binary (without valid Apple Developer ID / Team ID signature)
  swiftc "$src" -o "$bin" > "$log" 2>&1 || {
    warn "Swift compilation failed. Check Xcode Command Line Tools."
    echo "FAIL (probe did not compile)" > "$OUTDIR/result_xpc.txt"
    return 1
  }

  say "Attempting XPC connection from unauthorized client to $HELPER_BIN..."
  "$bin" >> "$log" 2>&1
  local ret=$?

  if [ $ret -eq 0 ]; then
    pass "Privileged helper correctly rejected unauthorized XPC caller (audit_token / Team ID check passed)"
    echo "PASS" > "$OUTDIR/result_xpc.txt"
  elif [ $ret -eq 2 ]; then
    fail "Privileged helper ACCEPTED unauthorized XPC caller!"
    echo "FAIL" > "$OUTDIR/result_xpc.txt"
  else
    warn "Helper did not respond (return code: $ret). Verify helper installation."
    echo "INCONCLUSIVE (no response, rc=$ret)" > "$OUTDIR/result_xpc.txt"
  fi
}

# --------------------------------------------- 2. PF & Air-Gap Priority ---
test_pf_airgap() {
  hr
  say "2. Testing Packet Filter (pf) Priority & Air-Gap Containment (§4, §5)..."
  local log="$OUTDIR/test_pf.log"

  # Check pf status
  say "Inspecting active pf anchors..."
  sudo pfctl -s Anchors 2>&1 | tee "$log" | grep -E "com.tetsuharu.roamswitch" || true

  # Check loopback policy: refused (7) or answered (0) means loopback works; a timeout (28) means it is dropped.
  say "Verifying loopback connectivity policy..."
  curl -s --connect-timeout 2 http://127.0.0.1:80 >/dev/null 2>&1
  local lo_rc=$?
  local lo_ok=0
  if [ $lo_rc -eq 0 ] || [ $lo_rc -eq 7 ]; then
    pass "Loopback interface (127.0.0.1) policy is responsive (Connection Refused / OK)"
    lo_ok=1
  else
    fail "Loopback 127.0.0.1 did not answer (curl rc=$lo_rc): loopback may be blocked"
  fi

  # Check outbound drop simulation under air-gap if enabled
  if sudo pfctl -s rules -a "com.tetsuharu.roamswitch/airgap" 2>/dev/null | grep -q "block drop"; then
    say "Air-Gap anchor is ACTIVE. Verifying fail-closed outbound drop..."
    curl -I --connect-timeout 2 https://1.1.1.1 >/dev/null 2>&1
    local ret=$?
    if [ $ret -eq 0 ]; then
      fail "Outbound traffic passed through while Air-Gap was active!"
      echo "FAIL" > "$OUTDIR/result_pf.txt"
    elif [ $ret -eq 28 ] && [ $lo_ok -eq 1 ]; then
      # a silent drop shows up as a connect timeout; DNS/route errors (6/7) would not prove the pf drop
      pass "Outbound connection timed out under Air-Gap (consistent with pf block drop)"
      echo "PASS" > "$OUTDIR/result_pf.txt"
    else
      warn "Outbound failed with curl rc=$ret, which does not by itself show a pf drop"
      echo "INCONCLUSIVE (curl rc=$ret)" > "$OUTDIR/result_pf.txt"
    fi
  else
    warn "Air-Gap anchor is inactive: the fail-closed drop was NOT exercised."
    if [ $lo_ok -eq 1 ]; then echo "SKIPPED (Air-Gap dormant; only loopback checked)" > "$OUTDIR/result_pf.txt"
    else echo "FAIL (loopback unresponsive)" > "$OUTDIR/result_pf.txt"; fi
  fi
}

# --------------------------------------------- 3. Port Anomaly Guard ---
test_port_anomaly() {
  hr
  say "3. Testing Port Anomaly & Global Exposure Detection (§6)..."
  local log="$OUTDIR/test_port.log"
  local test_port=18888
  local loop_port=18889

  say "Starting test listeners on port $test_port (0.0.0.0) and $loop_port (127.0.0.1)..."
  # serve an EMPTY directory: http.server would otherwise list the current directory on 0.0.0.0
  mkdir -p "$OUTDIR/empty-web"
  python3 -m http.server "$test_port" --bind 0.0.0.0 -d "$OUTDIR/empty-web" >/dev/null 2>&1 &
  local pid_global=$!
  python3 -m http.server "$loop_port" --bind 127.0.0.1 -d "$OUTDIR/empty-web" >/dev/null 2>&1 &
  local pid_local=$!

  sleep 1

  say "Verifying listening sockets with lsof (ground truth)..."
  lsof -nP -iTCP -sTCP:LISTEN | grep -E ":$test_port|:$loop_port" | tee "$log"
  local lsof_global=0 lsof_local=0
  grep -Eq "(\*|0\.0\.0\.0):$test_port " "$log" && lsof_global=1
  grep -Eq "127\.0\.0\.1:$loop_port " "$log" && lsof_local=1

  if [ $lsof_global -ne 1 ] || [ $lsof_local -ne 1 ]; then
    fail "Test listeners are not in the expected state (global=$lsof_global local=$lsof_local); nothing to assert against"
    echo "INCONCLUSIVE (test listeners not up)" > "$OUTDIR/result_port.txt"
  elif [ -x "$MCP_BIN" ]; then
    say "Querying RoamSwitchMCPServer get_exposed_ports tool..."
    local mcp_res
    mcp_res=$({ printf '%s\n' "$MCP_INIT" '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
      '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_exposed_ports","arguments":{"includeLocalOnly":true}}}'; sleep 3; } \
      | "$MCP_BIN" 2>/dev/null || true)
    echo "$mcp_res" >> "$log"
    # The tool result is JSON embedded as a STRING in the content text, so the quotes arrive backslash-escaped
    # (\"port\":18888). Match with or without the escaping.
    if echo "$mcp_res" | grep -Eq "port\\\\?\"? *: *$test_port([^0-9]|$)"; then
      pass "MCP server detected globally exposed port $test_port"
      echo "PASS" > "$OUTDIR/result_port.txt"
    else
      fail "MCP server did not report the globally exposed port $test_port (lsof confirms it is listening)"
      echo "FAIL (MCP missed port $test_port)" > "$OUTDIR/result_port.txt"
    fi
  else
    warn "MCP binary missing: only lsof was checked, detection by RoamSwitch NOT tested"
    echo "SKIPPED (no MCP binary; lsof only)" > "$OUTDIR/result_port.txt"
  fi

  kill "$pid_global" "$pid_local" 2>/dev/null || true
}

# -------------------------------------- 4. MCP Read-Only & Robustness ---
test_mcp_readonly() {
  hr
  say "4. Testing MCP Server Read-Only Invariant & Parser Robustness (§8)..."
  local log="$OUTDIR/test_mcp.log"

  if [ ! -x "$MCP_BIN" ]; then
    warn "MCP server binary not found at $MCP_BIN. Skipping MCP tests."
    echo "SKIPPED" > "$OUTDIR/result_mcp.txt"
    return 0
  fi

  say "Querying tools/list to enforce Read-Only invariant..."
  local tools_json
  tools_json=$({ printf '%s\n' "$MCP_INIT" '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'; sleep 3; } | "$MCP_BIN" 2>/dev/null || true)
  echo "$tools_json" > "$log"

  local all_names
  all_names=$(echo "$tools_json" | grep -oE '"name" *: *"[^"]+"' | sed -E 's/.*: *"([^"]+)"/\1/')
  local total_count
  total_count=$(printf '%s\n' "$all_names" | grep -c . || true)
  if [ "${total_count:-0}" -lt 2 ]; then
    # an empty/garbled catalog would otherwise "pass" with 0 mutating tools
    fail "tools/list returned no usable tool catalog; the invariant could not be checked"
    echo "INCONCLUSIVE (no tool catalog)" > "$OUTDIR/result_mcp.txt"
    return 1
  fi

  # Mutating verbs as a name PREFIX. Read-only scanners named run_*_scan are intentionally excluded.
  local forbidden
  forbidden=$(printf '%s\n' "$all_names" | grep -E '^(enable|disable|set|write|delete|update|modify|change|exec|run)([_A-Z]|$)' | grep -vE '^run_.*_scan$' || true)
  local forbidden_count
  forbidden_count=$(printf '%s\n' "$forbidden" | grep -c . || true)
  if [ "${forbidden_count:-0}" -eq 0 ]; then
    pass "Read-Only Invariant Confirmed: 0 mutating tools among $total_count in MCP catalog"
  else
    fail "Read-Only Violation: Found $forbidden_count mutating tool(s) in MCP catalog: $(echo $forbidden)"
    echo "FAIL" > "$OUTDIR/result_mcp.txt"
    return 1
  fi

  say "Fuzz testing: Deeply nested JSON-RPC payload, then a follow-up request to prove it survived..."
  # url is a genuinely nested OBJECT (60 levels), not a broken string
  local nested_json='{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":'
  local i
  for i in $(seq 1 60); do nested_json="${nested_json}{\"a\":"; done
  nested_json="${nested_json}\"http://example.com\""
  for i in $(seq 1 60); do nested_json="${nested_json}}"; done
  nested_json="${nested_json}}}}"

  local fuzz_res
  fuzz_res=$({ printf '%s\n' "$MCP_INIT" '{"jsonrpc":"2.0","method":"notifications/initialized"}' "$nested_json" \
    '{"jsonrpc":"2.0","id":4,"method":"tools/list","params":{}}'; sleep 3; } | "$MCP_BIN" 2>"$OUTDIR/test_mcp_fuzz_stderr.log")
  local fuzz_ret=$?
  echo "$fuzz_res" >> "$log"

  # Survived = the server answered the request that came AFTER the hostile one.
  if [ $fuzz_ret -eq 0 ] && echo "$fuzz_res" | grep -Eq '"id" *: *4[,}]'; then
    pass "Parser Robustness Confirmed: pathological JSON handled and the server kept answering"
    echo "PASS" > "$OUTDIR/result_mcp.txt"
  else
    fail "MCP server crashed or stopped answering after the nested JSON payload (exit: $fuzz_ret)"
    echo "FAIL" > "$OUTDIR/result_mcp.txt"
  fi
}

# --------------------------------------------- 5. ARP Anomaly Check ---
test_arp_anomaly() {
  hr
  say "5. Testing ARP Anomaly Detection & Gateway Consistency (§11)..."
  local log="$OUTDIR/test_arp.log"

  say "Inspecting system ARP table and default gateway MAC..."
  arp -an 2>&1 | tee "$log" | head -n 10

  local gw_ip
  gw_ip=$(netstat -nr -f inet | grep -E '^default' | awk '{print $2}' | head -n 1)
  # NOTE: this only observes the gateway; it does not exercise RoamSwitch's ARP anomaly detection.
  if [ -n "$gw_ip" ]; then
    local gw_mac
    gw_mac=$(arp -n "$gw_ip" 2>/dev/null | awk '{print $4}' | grep -iE "^([0-9a-f]{1,2}:){5}[0-9a-f]{1,2}$" || true)
    if [ -n "$gw_mac" ]; then
      pass "Default gateway ($gw_ip -> $gw_mac) resolved in the ARP table (observation only)"
      echo "PASS (observation only)" > "$OUTDIR/result_arp.txt"
    else
      warn "Gateway IP ($gw_ip) found, but MAC not in ARP cache."
      echo "INCONCLUSIVE (gateway MAC not resolved)" > "$OUTDIR/result_arp.txt"
    fi
  else
    warn "No default gateway found (offline/host-only VM). ARP check not performed."
    echo "SKIPPED (no default gateway)" > "$OUTDIR/result_arp.txt"
  fi
}

# ------------------------------------------------------ Report Generation ---
generate_report() {
  hr
  say "Generating Defense Audit Report..."
  local report="$OUTDIR/report.md"
  local findings="$OUTDIR/FINDINGS-DEFENSE.md"

  local res_xpc; res_xpc=$(cat "$OUTDIR/result_xpc.txt" 2>/dev/null || echo "N/A")
  local res_pf; res_pf=$(cat "$OUTDIR/result_pf.txt" 2>/dev/null || echo "N/A")
  local res_port; res_port=$(cat "$OUTDIR/result_port.txt" 2>/dev/null || echo "N/A")
  local res_mcp; res_mcp=$(cat "$OUTDIR/result_mcp.txt" 2>/dev/null || echo "N/A")
  local res_arp; res_arp=$(cat "$OUTDIR/result_arp.txt" 2>/dev/null || echo "N/A")

  # Overall verdict derived from the recorded results (never assumed).
  local overall="PASS"
  local r
  for r in "$res_xpc" "$res_pf" "$res_port" "$res_mcp" "$res_arp"; do
    case "$r" in
      FAIL*) overall="FAIL"; break;;
      PASS*) ;;
      *) overall="INCOMPLETE";;
    esac
  done
  OVERALL="$overall"

  cat > "$report" << EOF
# RoamSwitch Defense & Penetration Verification Report

- **Date**: $(date "+%Y-%m-%d %H:%M:%S %Z")
- **Target App**: $APP_PATH (RoamSwitch $VERSION)
- **Host / VM**: $(uname -srm) / $(sw_vers -productVersion 2>/dev/null || echo "macOS")
- **Audit Directory**: \`$OUTDIR\`

## Overall verdict: **$overall**

(PASS = every check passed; INCOMPLETE = no failure but at least one check was skipped, inconclusive or missing; FAIL = at least one check failed)

## Test Execution Summary

| # | Defense Layer | Target Specification | Result |
|---|---|---|---|
| 1 | **XPC Authorization Boundary** | §3 Privileged Helper (Team ID & \`audit_token\` check) | **$res_xpc** |
| 2 | **pf Ruleset & Air-Gap Priority** | §4, §5 Packet Filter priority & Fail-closed containment | **$res_pf** |
| 3 | **Port Anomaly Guard** | §6 Global exposure detection (\`0.0.0.0\` vs \`127.0.0.1\`) | **$res_port** |
| 4 | **MCP Read-Only Invariant** | §8 Read-Only MCP catalog & Parser fuzz robustness | **$res_mcp** |
| 5 | **ARP Anomaly & Gateway Monitor** | §11 Gateway MAC monitoring & Fail-safe containment | **$res_arp** |

---

## Log Artifacts
- XPC Probe: \`test_xpc.log\`
- pf Ruleset Dump: \`test_pf.log\`
- Port Exposure Probe: \`test_port.log\`
- MCP Query & Fuzz Log: \`test_mcp.log\`
- ARP Diagnostics: \`test_arp.log\`
EOF

  cat > "$findings" << EOF
# Summary of Security & Defense Audit Findings

**Overall verdict: $overall**

Per-check results (see report.md for the log artifacts). Only PASS lines count as verified;
SKIPPED / INCONCLUSIVE mean the boundary was not actually exercised in this run.

1. Privileged Helper Authorization (unapproved caller, Team ID \`$TEAM_ID\`): $res_xpc
2. Firewall Fail-Closed Invariant (Air-Gap drop): $res_pf
3. Port Anomaly Containment (global vs localhost listeners, detected by the MCP server): $res_port
4. MCP Read-Only Protection (no mutating tools; survives hostile JSON): $res_mcp
5. Gateway Integrity (ARP table observation only): $res_arp
EOF

  say "Report generated at: $report"
  say "Findings summary at: $findings"
}

# ----------------------------------------------------------- Entry Point ---
case "${1:-all}" in
  all)
    init_outdir
    preflight_check
    test_xpc_boundary
    test_pf_airgap
    test_port_anomaly
    test_mcp_readonly
    test_arp_anomaly
    generate_report
    [ "$OVERALL" = "FAIL" ] && exit 1
    ;;
  xpc)
    init_outdir; preflight_check; test_xpc_boundary
    ;;
  pf)
    init_outdir; preflight_check; test_pf_airgap
    ;;
  port)
    init_outdir; preflight_check; test_port_anomaly
    ;;
  mcp)
    init_outdir; preflight_check; test_mcp_readonly
    ;;
  arp)
    init_outdir; preflight_check; test_arp_anomaly
    ;;
  report)
    shift
    while [ $# -gt 0 ]; do
      case "$1" in
        --outdir) OUTDIR="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    [ -n "$OUTDIR" ] || die "--outdir is required for report subcommand"
    generate_report
    [ "$OVERALL" = "FAIL" ] && exit 1
    ;;
  *)
    echo "Usage: $0 {all|xpc|pf|port|mcp|arp|report} [--outdir DIR]"
    exit 1
    ;;
esac
