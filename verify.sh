#!/bin/bash
# verify.sh — check an installed RoamSwitch against the claims in the
# architecture & security whitepaper (docs/WHITEPAPER.md, §Appendix A).
#
# Read-only. Two steps optionally use sudo (pfctl / launchctl print); skip them
# with:  NO_SUDO=1 ./verify.sh
#
#   https://github.com/lafine1211/roamswitch-support
#   https://lafine.net/security.html

APP="${ROAMSWITCH_APP:-/Applications/RoamSwitch.app}"
HELPER="$APP/Contents/MacOS/RoamSwitchHelper"
MCP="$APP/Contents/MacOS/RoamSwitchMCPServer"
EXPECTED_TEAM="GV76B6G4YU"

bold()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$1"; }
info()  { printf '    %s\n' "$1"; }

[ -d "$APP" ] || { echo "RoamSwitch not found at $APP (set ROAMSWITCH_APP)"; exit 1; }

bold "Code signature & notarization"
codesign -dvvv "$APP" 2>&1 | grep -E 'Authority|TeamIdentifier|flags' | sed 's/^/  /'
if codesign -dvvv "$APP" 2>&1 | grep -q "TeamIdentifier=$EXPECTED_TEAM"; then
  ok "Team ID is $EXPECTED_TEAM"
else
  warn "Team ID does not match $EXPECTED_TEAM — this is not an official build"
fi
if xcrun stapler validate "$APP" >/dev/null 2>&1; then ok "notarization ticket stapled"; else warn "stapler validate failed"; fi
spctl -a -t exec -vv "$APP" 2>&1 | sed 's/^/  /'

bold "Bundled helper & MCP server signatures"
for b in "$HELPER" "$MCP"; do
  [ -x "$b" ] || { warn "missing: $b"; continue; }
  codesign -dvvv "$b" 2>&1 | grep -E 'Identifier|TeamIdentifier' | sed "s#^#  $(basename "$b"): #"
done

bold "Entitlements (expect: no sandbox, no network-client keys)"
for b in "$HELPER" "$MCP"; do
  [ -x "$b" ] || continue
  ent=$(codesign -d --entitlements :- "$b" 2>/dev/null)
  if echo "$ent" | grep -qE 'network|sandbox'; then
    warn "$(basename "$b"): found network/sandbox entitlement:"; echo "$ent" | sed 's/^/    /'
  else
    ok "$(basename "$b"): no network or sandbox entitlements"
  fi
done

bold "MCP server responds offline (initialize + tools/list)"
if [ -x "$MCP" ]; then
  out=$(printf '%s\n' \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | "$MCP" 2>/dev/null)
  echo "$out" | grep -o '"name":"[a-z_]*"' | sed 's/^/  tool: /'
  echo "$out" | grep -q '"serverInfo"' && ok "initialize answered" || warn "no initialize response"
fi

bold "Privileged helper (LaunchDaemon)"
if [ -z "${NO_SUDO:-}" ]; then
  sudo launchctl print system/com.tetsuharu.RoamSwitch.Helper 2>/dev/null \
    | grep -E 'state =|program =|active count' | sed 's/^/  /' \
    || warn "helper not registered (or run with sudo)"
else
  info "skipped (NO_SUDO)"
fi

bold "pf rules currently loaded (air-gap / dev-server guard state)"
if [ -z "${NO_SUDO:-}" ]; then
  rules=$(sudo pfctl -sr 2>/dev/null)
  if echo "$rules" | grep -q 'block drop all'; then warn "emergency air-gap is ACTIVE"; fi
  echo "$rules" | grep -E 'block drop' | sed 's/^/  /' || ok "no RoamSwitch block rules loaded"
else
  info "skipped (NO_SUDO)"
fi

bold "Helper state directory"
ls -la "/Library/Application Support/RoamSwitch/" 2>/dev/null | sed 's/^/  /' || info "(not present — nothing engaged)"

bold "Traffic (manual)"
info "Run alongside for a while, then use RoamSwitch normally:"
info "  sudo tcpdump -i any -n 'host not 127.0.0.1' and 'not port 53'"
info "Expect: only license activation, the Sparkle update check, and ClamAV updates."

bold "MCP server source & tests"
info "git clone https://github.com/lafine1211/roamswitch-mcp && cd roamswitch-mcp"
info "swift build -c release   # same source as the shipping binary"
info "swift test               # unit + adversarial-input + stdio + mutation fuzz"

printf '\nDone. See docs/WHITEPAPER.md for what each of these confirms.\n'
