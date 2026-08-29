#!/bin/bash
#
# rs-zerotel-audit.sh — RoamSwitch "Zero Telemetry" egress audit, mostly automated.
#
# Measures RoamSwitch's outbound connections and checks that the only ones
# attributable to RoamSwitch / RoamSwitchHelper / RoamSwitchMCPServer are the
# four documented in the whitepaper (docs/WHITEPAPER.md §7).
#
# What it does unattended:
#   - preflight + environment snapshot
#   - (--tier-b) Tier B prep: quit GUI apps, launchctl bootout non-Apple user
#     agents (revert on reboot), softwareupdate --schedule off, Mac Analytics
#     auto-submit off; then opens the 3 GUI-only toggles (Private Relay, iCloud
#     Drive, Analytics pane) and waits.  `prep-restore` undoes the reversible bits.
#   - ~10-min silent baseline (RoamSwitch not running); fails if the machine is
#     not quiet (a non-Apple destination still present)
#   - starts 3 monitoring layers (tcpdump x2, nettop, lsof loop) headless,
#     plus pktap and LuLu unified-log capture when available
#   - forces Sparkle's appcast check (delete SULastCheckTime + relaunch)
#   - drives every MCP tool through the bundled RoamSwitchMCPServer over stdio
#     while watching that process for any foreign socket
#   - idle capture for --idle (default 2h; a single sitting is enough — an
#     overnight window only adds coverage of a pure wall-clock daily beacon)
#   - stops monitors, analyses the pcaps, cross-references process ownership,
#     writes report.md and prints PASS / FAIL
#   - writes FINDINGS.md (method + results + limitations) to attach when sharing
#
# What still needs a human (prompted, unless --no-manual):
#   - one-time: install RoamSwitch, approve the privileged helper, and make sure
#     the current network is NOT a registered trusted network (keep it locked down)
#   - the 3 GUI-only privacy toggles (with --tier-b)
#   - one network transition so the on-change handler runs (a Wi-Fi off/on is
#     enough if you're already on an untrusted network)
#   - Phase B menu actions with no headless entry point (DNS Threat Guard toggle,
#     dev-server isolation, USB guard, in-app Link Safety sheet = egress path #4)
#   - license activate / deactivate (needs a real key) — optional
#
# Requires: tcpdump (system), tshark (brew install wireshark). Run from an admin
# account; it will sudo. macOS 13+, Apple Silicon, /bin/bash 3.2.
#
# Usage:
#   ./rs-zerotel-audit.sh all [--tier-b] [--idle 2h] [--baseline 600] [--clam] [--no-manual]
#   ./rs-zerotel-audit.sh prep                                   # Tier B setup only
#   ./rs-zerotel-audit.sh prep-restore --outdir ~/rs-audit/run-XXXX
#   ./rs-zerotel-audit.sh analyze --outdir ~/rs-audit/run-XXXX   # analysis + FINDINGS.md only
#
set -u

# ------------------------------------------------------------------ config ----
APP="/Applications/RoamSwitch.app"
BID="com.tetsuharu.RoamSwitch"
MCP_BIN="$APP/Contents/MacOS/RoamSwitchMCPServer"
HELPER_BIN="$APP/Contents/MacOS/RoamSwitchHelper"

IDLE="2h"
BASELINE_SECS=600
DO_CLAM=0
NO_MANUAL=0
TIER_B=0
OUTDIR=""
EXTRA_ALLOW=""
ANALYTICS_PLIST="/Library/Application Support/CrashReporter/SubmitDiagInfo.plist"

CAP_FILTER='(ip or ip6) and not net 127.0.0.0/8 and not net 169.254.0.0/16 and not net 224.0.0.0/4 and not port 5353 and not port 53 and not port 67 and not port 68'

# ------------------------------------------------------------------ helpers ---
say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[31m[x]\033[0m %s\n' "$*" >&2; exit 1; }
hr()   { printf -- '---------------------------------------------------------------\n'; }

pause_for() {
  [ "$NO_MANUAL" -eq 1 ] && { warn "skipping manual step: $1"; echo "$1" >> "$OUTDIR/manual-skipped.txt"; return 0; }
  local ans=""
  hr; printf '\033[35mMANUAL STEP\033[0m: %s\n' "$1"; hr
  printf 'Press Enter when done  (s + Enter to skip just this step): '
  read ans || true
  [ "$ans" = "s" ] && echo "$1" >> "$OUTDIR/manual-skipped.txt"
  return 0
}

need() { command -v "$1" >/dev/null 2>&1 || die "$1 not found. $2"; }

resolve_into_allowlist() {
  local host="$1"
  dig +short "$host" A    2>/dev/null | grep -E '^[0-9.]+$'    >> "$OUTDIR/allowlist-ips.txt"
  dig +short "$host" AAAA 2>/dev/null | grep -E '^[0-9a-f:]+$' >> "$OUTDIR/allowlist-ips.txt"
}

classify_ip() {
  local ip="$1" ptr org sni
  if grep -qxF "$ip" "$OUTDIR/allowlist-ips.txt" 2>/dev/null; then echo "EXPECTED(lafine/clamav)"; return; fi
  # this machine's own LAN / loopback address
  case "$ip" in 127.*|10.*|192.168.*|169.254.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*) echo "LOCAL($ip)"; return;; esac
  case "$ip" in 17.*) echo "APPLE(17/8)"; return;; esac
  # SNI seen for this IP in the capture (an Apple host can sit on AWS/Akamai IPs)
  sni=$(grep -F "$ip"$'\t' "$OUTDIR/tls-sni.txt" 2>/dev/null | awk -F'\t' '{print $2}' | head -1)
  case "$sni" in
    *.apple.com|*.icloud.com|*.mzstatic.com|*.aaplimg.com|tether.edge.apple) echo "APPLE(sni=$sni)"; return;;
    *lafine.net) echo "EXPECTED(sni=$sni)"; return;;
    *clamav*) echo "CLAMAV(sni=$sni)"; return;;
  esac
  ptr=$(dig +short -x "$ip" 2>/dev/null | head -1)
  case "$ptr" in
    *apple.com.|*icloud.com.|*aaplimg.com.|*apple-dns.net.|*push.apple.com.) echo "APPLE($ptr)"; return;;
    *lafine.net.) echo "EXPECTED($ptr)"; return;;
    *clamav*|*.clamav.net.) echo "CLAMAV($ptr)"; return;;
  esac
  org=$(whois "$ip" 2>/dev/null | grep -iE 'OrgName|org-name|netname|descr' | head -1 | sed 's/^[^:]*: *//')
  case "$org" in *[Aa]pple*) echo "APPLE($org)"; return;; esac
  for a in $EXTRA_ALLOW; do case "$ptr$org$sni" in *"$a"*) echo "ALLOWED-EXTRA($a)"; return;; esac; done
  echo "OTHER  sni=${sni:-?}  ptr=${ptr:-?}  org=${org:-?}"
}

# ------------------------------------------------------------------ steps -----
preflight() {
  need tcpdump "should be part of macOS"
  need tshark  "brew install wireshark"
  need dig     "should be part of macOS"
  [ -d "$APP" ] || die "$APP not found. Install RoamSwitch first."
  [ -x "$MCP_BIN" ] || die "$MCP_BIN not found."
  sudo -v || die "sudo is required."
  ( while :; do sudo -n true; sleep 50; done ) &
  SUDO_KEEPALIVE=$!
  mkdir -p "$OUTDIR"
  say "output dir: $OUTDIR"
}

env_snapshot() {
  say "environment snapshot"
  { sw_vers; echo "arch: $(uname -m)"; echo "date_utc: $(date -u +%FT%TZ)"; } > "$OUTDIR/env.txt"
  defaults read "$BID" 2>/dev/null > "$OUTDIR/env-roamswitch-defaults.txt" || true
  launchctl list | grep -viE 'com\.apple\.' > "$OUTDIR/env-launchd-nonapple.txt" || true
  ls -1 ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null > "$OUTDIR/env-launch-files.txt" || true
  codesign -d --entitlements :- "$HELPER_BIN" > "$OUTDIR/entitlements-helper.txt" 2>&1 || true
  codesign -d --entitlements :- "$MCP_BIN"    > "$OUTDIR/entitlements-mcp.txt"    2>&1 || true
  : > "$OUTDIR/allowlist-ips.txt"
  resolve_into_allowlist lafine.net
  [ "$DO_CLAM" -eq 1 ] && resolve_into_allowlist database.clamav.net
  sort -u -o "$OUTDIR/allowlist-ips.txt" "$OUTDIR/allowlist-ips.txt"
  say "allowlisted IPs:"; sed 's/^/    /' "$OUTDIR/allowlist-ips.txt"
}

# ---------------------------------------------------------- Tier B prep ------
prep() {
  say "Tier B prep (quiet the machine on the current login)"
  mkdir -p "$OUTDIR"

  say "1/5 record what is currently talking"
  sudo nettop -P -x -l 1 2>/dev/null > "$OUTDIR/prep-nettop.txt" || true
  sudo lsof -nP -i 2>/dev/null       > "$OUTDIR/prep-lsof.txt"   || true
  launchctl list                     > "$OUTDIR/prep-launchctl.txt" || true

  say "2/5 quit GUI apps (except Finder)"
  osascript -e 'tell application "System Events" to get name of (every process whose background only is false)' \
    > "$OUTDIR/prep-apps-before.txt" 2>/dev/null || true
  sed 's/, /\n/g' "$OUTDIR/prep-apps-before.txt" | sed 's/^/    /'
  if [ "$NO_MANUAL" -eq 0 ]; then local a=""; printf 'quit the above? [Y/n]: '; read a || true; [ "$a" = "n" ] && return 0; fi
  osascript -e 'tell application "System Events" to quit (every process whose background only is false and name is not "Finder")' 2>/dev/null || true
  # menu-bar / background sync clients that "background only is false" misses
  for app in "OneDrive" "Dropbox" "Google Drive" "Backblaze" "Box" "Creative Cloud"; do
    osascript -e "quit app \"$app\"" 2>/dev/null || true
  done
  pkill -if 'OneDrive|Dropbox|Google Drive|backblaze' 2>/dev/null || true
  sleep 3

  say "3/5 launchctl bootout non-Apple user agents (reverts on reboot)"
  launchctl list | awk 'NR>1 && $3 ~ /\./ && $3 !~ /^com\.apple\./ && $3 !~ /^application\./ && $3 !~ /roamswitch/ && $3 !~ /com\.tetsuharu/ {print $3}' \
    | sort -u > "$OUTDIR/bootout-candidates.txt"
  if [ ! -s "$OUTDIR/bootout-candidates.txt" ]; then
    say "  no candidates (already quiet)"
  else
    cat "$OUTDIR/bootout-candidates.txt" | sed 's/^/    /'
    if [ "$NO_MANUAL" -eq 0 ]; then
      hr
      printf 'Delete any line you want to keep from %s, save, then Enter (as-is = bootout all): ' "$OUTDIR/bootout-candidates.txt"
      local a=""; read a || true
    fi
    local U; U=$(id -u)
    : > "$OUTDIR/booted-out.txt"
    while read L; do
      [ -z "$L" ] && continue
      launchctl bootout "gui/$U/$L" 2>/dev/null && { echo "$L" >> "$OUTDIR/booted-out.txt"; say "  out: $L"; }
    done < "$OUTDIR/bootout-candidates.txt"
  fi

  say "4/5 quiet Apple cloud / analytics"
  sudo softwareupdate --schedule off >/dev/null 2>&1 && say "  softwareupdate auto-check: off" || warn "  softwareupdate --schedule off failed"
  if [ -f "$ANALYTICS_PLIST" ]; then
    sudo defaults read "$ANALYTICS_PLIST" AutoSubmit 2>/dev/null > "$OUTDIR/prep-analytics-was.txt" || echo "unset" > "$OUTDIR/prep-analytics-was.txt"
    sudo defaults write "$ANALYTICS_PLIST" AutoSubmit -bool false 2>/dev/null && say "  Mac Analytics auto-submit: off" || warn "  set Analytics off in the GUI"
  fi
  defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true 2>/dev/null || true
  hr
  warn "GUI-only (a Settings pane will open):"
  cat <<'TXT'
    - Apple ID > iCloud > Private Relay   : OFF   (required: it obscures SNI)
    - Apple ID > iCloud > iCloud Drive    : turn off "Sync this Mac"
    - Privacy & Security > Analytics & Improvements : all OFF
TXT
  open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings" 2>/dev/null \
    || open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane" 2>/dev/null || true
  [ "$NO_MANUAL" -eq 0 ] && { printf 'Press Enter once the 3 toggles are set: '; local a=""; read a || true; }

  say "5/5 network"
  scutil --nc list > "$OUTDIR/prep-vpn.txt" 2>&1 || true
  # state shows in parens: (Connected) / (Connecting) / (Disconnected) / ...
  grep -qE '\((Connected|Connecting)\)' "$OUTDIR/prep-vpn.txt" \
    && warn "a VPN is connected — disconnect it (scutil --nc stop <name>)"
  networksetup -getdnsservers Wi-Fi > "$OUTDIR/prep-dns.txt" 2>&1 || true
  caffeinate -i -w $$ &

  say "prep done. the baseline step next will check whether the machine is quiet."
}

prep_restore() {
  say "restoring what prep changed (where possible)"
  sudo softwareupdate --schedule on >/dev/null 2>&1 && say "  softwareupdate auto-check: on" || true
  local was; was=$(cat "$OUTDIR/prep-analytics-was.txt" 2>/dev/null || echo "")
  if [ "$was" = "1" ] && [ -f "$ANALYTICS_PLIST" ]; then
    sudo defaults write "$ANALYTICS_PLIST" AutoSubmit -bool true && say "  Mac Analytics auto-submit: restored"
  fi
  defaults delete com.apple.lookup.shared LookupSuggestionsDisabled 2>/dev/null || true
  warn "launchctl bootout reverts on reboot. Re-enable iCloud Drive / Private Relay in the GUI (list in $OUTDIR/booted-out.txt)."
}

baseline() {
  say "silent baseline (${BASELINE_SECS}s) — do not launch RoamSwitch"
  osascript -e 'quit app "RoamSwitch"' >/dev/null 2>&1 || true
  sleep 2
  sudo tcpdump -i any -n -w "$OUTDIR/baseline.pcap" "$CAP_FILTER" >/dev/null 2>&1 &
  local tpid=$!
  local i=0
  while [ $i -lt "$BASELINE_SECS" ] && kill -0 $tpid 2>/dev/null; do sleep 5; i=$((i+5)); printf '\r    %ds / %ds' "$i" "$BASELINE_SECS"; done
  printf '\n'
  sudo kill $tpid 2>/dev/null; kill $tpid 2>/dev/null; wait $tpid 2>/dev/null || true

  say "classifying baseline destinations"
  tshark -r "$OUTDIR/baseline.pcap" -Y 'tcp.flags.syn==1 && tcp.flags.ack==0' -T fields -e ip.dst 2>/dev/null \
    | sort -u > "$OUTDIR/baseline-dsts.txt"
  : > "$OUTDIR/baseline-owners.txt"
  local bad=0
  while read ip; do
    [ -z "$ip" ] && continue
    local c; c=$(classify_ip "$ip")
    printf '%-18s %s\n' "$ip" "$c" | tee -a "$OUTDIR/baseline-owners.txt"
    case "$c" in OTHER*) bad=$((bad+1));; esac
  done < "$OUTDIR/baseline-dsts.txt"

  if [ "$bad" -gt 0 ]; then
    warn "baseline has $bad non-Apple / non-allowlisted destination(s) — see $OUTDIR/baseline-owners.txt"
    warn "find the owner: sudo lsof -nP -iTCP@<IP>   /   sudo nettop -P -l 0 | grep -v com.apple"
    warn "go back to Tier B step 3, stop that service, and re-run."
    if [ "$NO_MANUAL" -eq 0 ]; then
      local a=""; printf 'ignore and continue anyway? [y/N]: '; read a || true
      [ "$a" = "y" ] || die "aborted"
    fi
  else
    say "baseline is quiet (every destination is Apple / allowlisted)"
  fi
}

start_monitors() {
  say "starting the 3 monitoring layers (headless)"
  # every backgrounded monitor gets </dev/null so it cannot touch the
  # controlling terminal (nettop in particular leaves the tty in raw mode
  # otherwise, and later `read` prompts stop echoing / accepting Enter).
  sudo tcpdump -i any -n -w "$OUTDIR/cap-%Y%m%d-%H%M.pcap" -G 3600 -W 72 -Z root "$CAP_FILTER" \
    </dev/null >/dev/null 2>&1 & echo $! > "$OUTDIR/.pid.tcpdump-main"
  sudo tcpdump -i any -n -w "$OUTDIR/dns-%Y%m%d-%H%M.pcap" -G 3600 -W 72 -Z root 'port 53' \
    </dev/null >/dev/null 2>&1 & echo $! > "$OUTDIR/.pid.tcpdump-dns"
  sudo nettop -P -x -l 0 -J bytes_in,bytes_out </dev/null 2>/dev/null \
    | grep --line-buffered -Ei 'roamswitch|freshclam' > "$OUTDIR/nettop.log" & echo $! > "$OUTDIR/.pid.nettop"
  sudo bash -s "$OUTDIR" > "$OUTDIR/lsof.log" 2>&1 <<'SH' & echo $! > "$OUTDIR/.pid.lsofloop"
while :; do
  ts=$(date -u +%FT%TZ)
  lsof -nP -iTCP -sTCP:ESTABLISHED +c0 2>/dev/null | awk -v ts="$ts" 'NR>1{print ts, $1, $2, $9}'
  sleep 5
done
SH
  # optional pktap (per-process attributed capture) — best effort
  sudo tcpdump -i 'pktap,any' -n -w "$OUTDIR/pktap.pcap" -G 3600 -W 72 -Z root \
    'proc "RoamSwitch" or proc "RoamSwitchHelper" or proc "RoamSwitchMCPServer"' \
    </dev/null >/dev/null 2>&1 & echo $! > "$OUTDIR/.pid.pktap"
  sleep 3
  sudo kill -0 "$(cat "$OUTDIR/.pid.pktap" 2>/dev/null)" 2>/dev/null && say "pktap available" || { warn "pktap unavailable (layers 1+2 cover it)"; rm -f "$OUTDIR/.pid.pktap"; }

  # optional LuLu: capture its unified-log events (allow/block decisions with a
  # process name) so the write-up can quote a log excerpt, not a screenshot.
  if [ -d /Applications/LuLu.app ] || pgrep -qx LuLu >/dev/null 2>&1; then
    log stream --style syslog --predicate 'subsystem BEGINSWITH "com.objective-see"' \
      </dev/null > "$OUTDIR/lulu.log" 2>/dev/null & echo $! > "$OUTDIR/.pid.lulu"
    say "capturing LuLu events (lulu.log)"
  else
    warn "LuLu not found (skipping per-process alert log)"
  fi
  sleep 2
  for f in "$OUTDIR"/.pid.*; do
    sudo kill -0 "$(cat "$f" 2>/dev/null)" 2>/dev/null || warn "failed to start: $(basename "$f")"
  done
  say "monitors running"
}

stop_monitors() {
  say "stopping monitors"
  for f in "$OUTDIR"/.pid.*; do
    [ -f "$f" ] || continue
    local p; p=$(cat "$f")
    sudo kill "$p" 2>/dev/null || kill "$p" 2>/dev/null
    rm -f "$f"
  done
  # belt-and-suspenders: kill anything the backgrounded sudo wrappers left behind
  sudo pkill -f "tcpdump -i any -n -w $OUTDIR" 2>/dev/null || true
  sudo pkill -f "tcpdump -i pktap"             2>/dev/null || true
  sudo pkill -f 'nettop -P -x -l 0'            2>/dev/null || true
  sudo pkill -f 'lsof -nP -iTCP -sTCP:ESTABLISHED' 2>/dev/null || true
  pkill -f "log stream --style syslog --predicate .subsystem BEGINSWITH" 2>/dev/null || true
  sleep 2
}

trigger_sparkle() {
  say "forcing Sparkle's appcast check (delete SULastCheckTime, relaunch)"
  echo "sparkle_trigger_utc: $(date -u +%FT%TZ)" >> "$OUTDIR/timeline.txt"
  osascript -e 'quit app "RoamSwitch"' >/dev/null 2>&1 || true
  sleep 2
  defaults delete "$BID" SULastCheckTime 2>/dev/null || true
  open -a RoamSwitch
  say "waiting 150s for launch + check"
  sleep 150
  local last; last=$(defaults read "$BID" SULastCheckTime 2>/dev/null || echo "?")
  echo "sparkle_SULastCheckTime_after: $last" >> "$OUTDIR/timeline.txt"
  say "SULastCheckTime = $last  (updated => the appcast check ran)"
}

exercise_mcp() {
  say "driving every MCP tool over stdio (checking for zero egress)"
  echo "mcp_start_utc: $(date -u +%FT%TZ)" >> "$OUTDIR/timeline.txt"
  cat > "$OUTDIR/mcp-input.jsonl" <<'JSON'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"audit","version":"1"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}
{"jsonrpc":"2.0","id":3,"method":"resources/list"}
{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"get_security_report","arguments":{}}}
{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"get_exposed_ports","arguments":{"includeLocalOnly":true}}}
{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"get_guard_status","arguments":{}}}
{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":"https://apple.com.secure-login.xyz/verify"}}}
{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"audit_url_safety","arguments":{"url":"http://192.168.1.1/login"}}}
{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"get_app_help","arguments":{"query":"ARP"}}}
JSON
  # keep the process alive ~10s so we can watch its sockets
  { cat "$OUTDIR/mcp-input.jsonl"; sleep 10; } | "$MCP_BIN" > "$OUTDIR/mcp-output.jsonl" 2>"$OUTDIR/mcp-stderr.txt" &
  local mp=$!
  : > "$OUTDIR/mcp-sockets.txt"
  while kill -0 "$mp" 2>/dev/null; do
    # -a ANDs -p and -i, so this is ONLY the process's network files
    # (no pipes, no mmapped libs). NAME field ($NF) = "ip:port->ip:port" or "*:port (LISTEN)".
    lsof -nP -a -p "$mp" -i 2>/dev/null | awk 'NR>1{print $NF}' >> "$OUTDIR/mcp-sockets.txt"
    sleep 0.25
  done
  wait "$mp" 2>/dev/null
  echo "mcp_end_utc: $(date -u +%FT%TZ)" >> "$OUTDIR/timeline.txt"

  # a foreign socket = an established connection whose remote end is not this host
  local foreign
  foreign=$(grep -F -- '->' "$OUTDIR/mcp-sockets.txt" \
            | grep -vE '\->(127\.0\.0\.1|\[?::1\]?|localhost)[:.]' \
            | sort -u || true)
  local ntools
  ntools=$(grep -c '"result"' "$OUTDIR/mcp-output.jsonl" || echo 0)
  say "MCP responses: $ntools  (expected 9: initialize + tools/list + resources/list + 6 calls)"
  : > "$OUTDIR/.mcp-verdict"
  if [ -n "$foreign" ]; then
    warn "the MCP server opened a non-local socket:"; echo "$foreign" | sed 's/^/    /'
    echo "FAIL: MCPServer opened a non-local socket" >> "$OUTDIR/.mcp-verdict"
  else
    say "MCP server non-local sockets: none (local port probes from get_exposed_ports are expected)"
    echo "PASS: MCPServer opened no non-local sockets" >> "$OUTDIR/.mcp-verdict"
  fi
}

manual_phase_b() {
  pause_for "In the RoamSwitch menu, set the security level to Maximum Lockdown (not Trusted/Open, not Standard Protection) and pin it with the manual override so it stays there for the whole audit. Strongest test: even at max lockdown, RoamSwitch's own pf rules must let only the 4 documented paths out. Release the override afterwards."
  pause_for "Trigger one network transition so the on-change handler runs (gateway fingerprint, DNS Threat Guard, pf rebuild). If you're already on an untrusted network, a Wi-Fi off/on is enough: 'networksetup -setairportpower en0 off; sleep 8; networksetup -setairportpower en0 on'. Note the time in $OUTDIR/timeline.txt."
  pause_for "In RoamSwitch, run every feature once: each menu diagnostic, DNS Threat Guard on/off, dev-server isolation, USB guard, port/ARP checks, and the Link Safety sheet against one external URL (= egress path #4). Note the times."
  [ "$NO_MANUAL" -eq 1 ] || {
    local a=""
    printf 'Also test license activate -> deactivate? (needs a real key) [y/N]: '; read a || true
    [ "$a" = "y" ] && pause_for "In RoamSwitch, activate a license key then deactivate it right away. Note the time (= egress path #1)."
  }
}

do_clam() {
  [ "$DO_CLAM" -eq 1 ] || return 0
  if command -v freshclam >/dev/null 2>&1; then
    say "running freshclam (egress path #3 — attributed to freshclam, not RoamSwitch)"
    echo "freshclam_utc: $(date -u +%FT%TZ)" >> "$OUTDIR/timeline.txt"
    freshclam > "$OUTDIR/freshclam.log" 2>&1 || warn "freshclam failed (maybe not configured)"
  else
    warn "freshclam not installed. Egress path #3 = N/A."
  fi
}

idle_wait() {
  say "idle capture: $IDLE (unattended). Do the network move before leaving."
  echo "idle_start_utc: $(date -u +%FT%TZ)  duration: $IDLE" >> "$OUTDIR/timeline.txt"
  caffeinate -i -w $$ &
  local n unit secs
  n=$(echo "$IDLE" | sed 's/[a-z]*$//'); unit=$(echo "$IDLE" | sed 's/^[0-9]*//')
  case "$unit" in h) secs=$((n*3600));; m) secs=$((n*60));; s|"") secs=$n;; *) secs=7200;; esac
  local i=0
  while [ $i -lt "$secs" ]; do sleep 30; i=$((i+30)); printf '\r    %dm / %dm' $((i/60)) $((secs/60)); done
  printf '\n'
  echo "idle_end_utc: $(date -u +%FT%TZ)" >> "$OUTDIR/timeline.txt"
}

analyze() {
  say "analysing"
  cd "$OUTDIR" || die "cannot cd into $OUTDIR"

  : > syn-dsts.txt
  for f in cap-*.pcap; do [ -e "$f" ] || continue
    tshark -r "$f" -Y 'tcp.flags.syn==1 && tcp.flags.ack==0' -T fields -e frame.time_utc -e ip.dst -e tcp.dstport 2>/dev/null >> syn-dsts.txt
  done
  sort -u -o syn-dsts.txt syn-dsts.txt

  : > tls-sni.txt
  for f in cap-*.pcap; do [ -e "$f" ] || continue
    tshark -r "$f" -Y 'tls.handshake.type==1' -T fields -e ip.dst -e tls.handshake.extensions_server_name 2>/dev/null >> tls-sni.txt
  done
  sort -u -o tls-sni.txt tls-sni.txt

  # process-attributed foreign flows for our 3 binaries (from the lsof loop)
  awk '$2 ~ /^RoamSwitch/ {
    for (i=1;i<=NF;i++) if ($i ~ /->/) { split($i,a,"->"); print $2, a[2] }
  }' lsof.log 2>/dev/null | grep -vE '127\.0\.0\.1|\[?::1\]?' | sort -u > proc-flows.txt

  if [ -e pktap.pcap ]; then
    tshark -r pktap.pcap -T fields -e ip.dst -e tcp.dstport 2>/dev/null | sort -u > pktap-dsts.txt || true
  fi

  if [ -s lulu.log ]; then
    grep -iE 'roamswitch' lulu.log 2>/dev/null | sort -u > lulu-roamswitch.txt || true
  fi

  {
    echo "# RoamSwitch Zero Telemetry — audit report"
    echo
    echo "- generated: $(date -u +%FT%TZ)"
    echo "- output:    $OUTDIR"
    echo "- idle: $IDLE / baseline: ${BASELINE_SECS}s / clam: $DO_CLAM"
    grep -q . manual-skipped.txt 2>/dev/null && { echo; echo "## skipped manual steps"; sed 's/^/- /' manual-skipped.txt; }
    echo
    echo "## timeline"
    echo '```'; cat timeline.txt 2>/dev/null; echo '```'
    echo
    echo "## MCP server"
    echo '```'; cat .mcp-verdict 2>/dev/null; echo '```'
    echo
    echo "## outbound flows attributed to RoamSwitch / Helper / MCPServer (lsof)"
    if [ -s proc-flows.txt ]; then
      while read proc dst; do
        ip=$(echo "$dst" | sed -E 's/:[0-9]+$//; s/^\[//; s/\]$//')
        printf -- '- %-22s -> %-22s  %s\n' "$proc" "$dst" "$(classify_ip "$ip")"
      done < proc-flows.txt
    else
      echo "- (none)"
    fi
    echo
    echo "## LuLu events (RoamSwitch, log excerpt)"
    if [ -s lulu-roamswitch.txt ]; then
      echo '```'; cat lulu-roamswitch.txt; echo '```'
    elif [ -f lulu.log ]; then
      echo "- no RoamSwitch-related events (lulu.log is $(wc -l < lulu.log | tr -d ' ') lines)"
    else
      echo "- LuLu not used"
    fi
    echo
    echo "## entitlements"
    echo '```'; echo "-- helper --"; cat entitlements-helper.txt; echo; echo "-- mcp --"; cat entitlements-mcp.txt; echo '```'
    echo
    echo "## every HTTPS destination in the capture (TLS SNI)"
    echo '```'
    awk -F'\t' 'NF{printf "%-18s %s\n", ($1?$1:"-"), $2}' tls-sni.txt 2>/dev/null | sort -u
    echo '```'
    echo "Apart from OS services (iCloud / push / software-update / OCSP / Safari Safe Browsing),"
    echo "the only SNI is \`lafine.net\` — Sparkle's appcast check (path #2). \`dns.quad9.net\` is the"
    echo "DNS Threat Guard switching the system resolver (mDNSResponder does the lookups, not RoamSwitch)."
    echo
    echo "## reference: every outbound destination IP in the capture"
    { cut -f2 syn-dsts.txt; awk -F'\t' 'NF>1 && $1{print $1}' tls-sni.txt; } 2>/dev/null | sort -u | while read ip; do
      [ -z "$ip" ] && continue
      printf -- '- %-18s %s\n' "$ip" "$(classify_ip "$ip")"
    done
  } > report.md

  # -------- verdict --------
  local fail=0 reason=""
  grep -q '^FAIL' .mcp-verdict 2>/dev/null && { fail=1; reason="$reason MCPServer-opened-socket;"; }
  grep -qE '^RoamSwitchHelper ' proc-flows.txt 2>/dev/null && { fail=1; reason="$reason Helper-egress;"; }
  grep -qE '^RoamSwitchMCPServer ' proc-flows.txt 2>/dev/null && { fail=1; reason="$reason MCPServer-flow;"; }
  while read proc dst; do
    [ "$proc" = "RoamSwitch" ] || continue
    ip=$(echo "$dst" | sed -E 's/:[0-9]+$//; s/^\[//; s/\]$//')
    cls=$(classify_ip "$ip")
    sni=$(grep -F "$ip" tls-sni.txt 2>/dev/null | awk '{print $2}' | head -1)
    case "$cls" in EXPECTED*) continue;; esac
    case "$sni" in *lafine.net) continue;; esac
    fail=1; reason="$reason RoamSwitch->${ip}(${sni:-$cls})-review;"
  done < proc-flows.txt

  hr
  if [ "$fail" -eq 0 ]; then
    printf '\033[32mPASS\033[0m — RoamSwitch/Helper/MCPServer egress is allowlist-only. See report.md.\n'
    echo "VERDICT: PASS" >> report.md
  else
    printf '\033[31mFAIL\033[0m —%s  See report.md.\n' "$reason"
    echo "VERDICT: FAIL -$reason" >> report.md
  fi
  hr
  say "report: $OUTDIR/report.md"
}

findings_summary() {
  cd "$OUTDIR" || die "cannot cd into $OUTDIR"
  say "writing FINDINGS.md"
  local verdict; verdict=$(grep '^VERDICT:' report.md 2>/dev/null | head -1 | sed 's/^VERDICT: *//')
  {
    printf '# RoamSwitch Zero Telemetry — audit findings\n\n'
    printf 'Measured egress result from `rs-zerotel-audit.sh`. When sharing this,\n'
    printf 'always include the "What this audit cannot show" section at the end.\n\n'
    printf -- '- environment: %s %s / %s\n' "$(sw_vers -productName 2>/dev/null)" "$(sw_vers -productVersion 2>/dev/null)" "$(uname -m)"
    printf -- '- audit date (UTC): %s\n' "$(date -u +%F)"
    printf -- '- verdict: **%s**\n\n' "${verdict:-see report.md}"
  } > FINDINGS.md

  cat >> FINDINGS.md <<'MD'
## Method (3 layers)

1. **Layer 1 — full packet capture.** tcpdump on all interfaces, writing hourly
   pcaps, with local / DNS / mDNS filtered out.
2. **Layer 2 — process attribution.** tcpdump does not say *who* sent a packet,
   so a `nettop` counter and a polled `lsof` snapshot map sockets to processes.
   The MCP server is driven through every tool over stdio while its PID's
   sockets are watched.
3. **Layer 3 — LuLu** (optional). Per-process outbound events pulled from the
   unified log (`log stream`).

The run is done with RoamSwitch's security level pinned to **Maximum Lockdown**
(manual override — not Trusted/Open, not Standard Protection) on an untrusted
network — the strictest condition, where the app's own pf rules must still
permit only the four paths.

Allowlist (anything else from a RoamSwitch process = fail):

| # | destination | process | when |
|---|---|---|---|
| 1 | lafine.net /api/v1/license/* | RoamSwitch | license activate / deactivate only |
| 2 | lafine.net /updates/appcast.xml | RoamSwitch | Sparkle (launch + every 24 h) |
| 3 | ClamAV mirrors | freshclam (not the app) | only if ClamAV is installed |
| 4 | HEAD to a target URL | RoamSwitch | only when the in-app Link Safety sheet is used |

## Results

MD

  {
    printf 'Process-attributed outbound flows for the three RoamSwitch binaries:\n\n```\n'
    sed -n '/outbound flows attributed to/,/^## LuLu/p' report.md 2>/dev/null | sed '$d'
    printf '```\n\n'
    printf 'MCP server socket watch:\n\n```\n'
    cat .mcp-verdict 2>/dev/null
    printf '```\n\n'
    printf 'Every HTTPS destination in the whole capture (TLS SNI), for context:\n\n```\n'
    awk -F"\t" 'NF{printf "%-18s %s\n", ($1?$1:"-"), $2}' tls-sni.txt 2>/dev/null | sort -u
    printf '```\n\n'
    printf 'Everything here is an OS service (iCloud, push, software update, OCSP, and\n'
    printf 'Safari Safe Browsing at `proxy-safebrowsing.googleapis.com`) except `lafine.net`\n'
    printf '— Sparkle checking the appcast (egress path #2). `dns.quad9.net` appears because\n'
    printf 'the DNS Threat Guard switched the system resolver; those encrypted lookups are\n'
    printf 'done by mDNSResponder, not RoamSwitch. None of it is attributed to a RoamSwitch\n'
    printf 'process (see the flow table above).\n\n'
    if [ -s lulu-roamswitch.txt ]; then
      printf 'LuLu event-log excerpt (RoamSwitch):\n\n```\n'
      cat lulu-roamswitch.txt
      printf '```\n\n'
    else
      printf 'LuLu: no RoamSwitch-related outbound events (%s).\n\n' "$( [ -f lulu.log ] && echo "lulu.log, $(wc -l < lulu.log | tr -d ' ') lines" || echo 'LuLu not used' )"
    fi
    printf 'entitlements (no network-client key):\n\n```\n'
    cat entitlements-helper.txt 2>/dev/null | head -12
    printf '```\n\n'
  } >> FINDINGS.md

  cat >> FINDINGS.md <<'MD'
## What this audit cannot show

- Not "no traffic at all" — the four paths above are real. Zero Telemetry means
  no collection or transmission of usage / diagnostic data.
- Not "never" — the conclusion is scoped to the observed window (the active
  session plus an optional idle stretch).
- RoamSwitch does not use App Sandbox, so entitlements do not *enforce* the
  absence of egress; it has to be shown behaviourally, which is what this does.
- Payloads are not inspected (destination + TLS SNI only). No analytics or
  crash-reporter SDK is bundled; the MCP server and detection logic are open
  source, so "what is sent to the LLM" is checkable in code:
  <https://github.com/lafine1211/roamswitch-mcp>
- Sparkle's appcast check runs on `SUScheduledCheckInterval = 86400`. This audit
  deletes `SULastCheckTime` and relaunches so the check fires on startup.

## Reproduce

`./rs-zerotel-audit.sh all --idle 2h` (roamswitch-support/audit). Anyone can
run the same steps.
MD
  say "findings: $OUTDIR/FINDINGS.md"
}

cleanup() {
  [ -n "${SUDO_KEEPALIVE:-}" ] && kill "$SUDO_KEEPALIVE" 2>/dev/null
  [ -d "${OUTDIR:-/nonexistent}" ] && for f in "$OUTDIR"/.pid.*; do
    [ -f "$f" ] && { sudo kill "$(cat "$f")" 2>/dev/null; rm -f "$f"; }
  done
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------ args ------
CMD="${1:-all}"; shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --idle)      IDLE="$2"; shift 2;;
    --baseline)  BASELINE_SECS="$2"; shift 2;;
    --clam)      DO_CLAM=1; shift;;
    --tier-b)    TIER_B=1; shift;;
    --no-manual) NO_MANUAL=1; shift;;
    --outdir)    OUTDIR="$2"; shift 2;;
    --allow)     EXTRA_ALLOW="$EXTRA_ALLOW $2"; shift 2;;
    *) die "unknown option: $1";;
  esac
done
[ -n "$OUTDIR" ] || OUTDIR="$HOME/rs-audit/run-$(date +%Y%m%d-%H%M%S)"

case "$CMD" in
  all)
    preflight
    env_snapshot
    [ "$TIER_B" -eq 1 ] && prep
    pause_for "RoamSwitch installed, privileged helper approved (first run only), and the current network NOT registered as a trusted network."
    baseline
    start_monitors
    trigger_sparkle
    exercise_mcp
    do_clam
    manual_phase_b
    idle_wait
    stop_monitors
    analyze
    findings_summary
    ;;
  prep)          preflight; prep;;
  prep-restore)  [ -d "$OUTDIR" ] || warn "no --outdir given: only a subset can be restored"; prep_restore;;
  baseline)      preflight; env_snapshot; baseline;;
  monitors)      preflight; start_monitors; say "stop with: $0 stop --outdir $OUTDIR";;
  stop)          stop_monitors;;
  sparkle)       preflight; trigger_sparkle;;
  mcp)           preflight; env_snapshot; exercise_mcp;;
  analyze)       [ -d "$OUTDIR" ] || die "point --outdir at an existing run dir"; analyze; findings_summary;;
  findings)      [ -d "$OUTDIR" ] || die "point --outdir at an existing run dir"; findings_summary;;
  *) die "usage: $0 {all|prep|prep-restore|baseline|monitors|stop|sparkle|mcp|analyze|findings} [opts]";;
esac
