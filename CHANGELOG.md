# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch Sensor

Software you install on your own general-purpose hardware (PC, Raspberry
Pi, etc., x86_64/arm64) — a separate product: pairing-code-based mutual
trust (fixed IP + short-lived code) with RoamSwitch-equipped endpoints
(Mac / Linux Client / Server Edition) for active vulnerability audits,
plus detection of new devices and spoofing on the LAN. Still under
development — see
<https://lafine.net/roamswitch-sensor-manual.html> for current status and
setup instructions.

### 0.2.0

- **Added: IoT-device-security-focused ARP events, in four tiers.**
  Previously an ARP event was just a bare MAC/IP diff with nothing
  actionable in it.
  - Tier 1: MAC-vendor classification against a curated, verified subset
    of the IEEE OUI registry (camera/smart-plug/etc. categories), a
    persistent per-device inventory (`sensor-cli device-inventory`), and
    detection of a single MAC issuing ARP requests for an unusual number
    of distinct IPs (possible LAN-internal reconnaissance).
  - Tier 2: reads self-announced mDNS/SSDP/DHCP identifiers (extends the
    existing passive packet-capture path) for more precise, model-level
    device identification than the OUI alone.
  - Tier 3: cross-references classified IoT devices' traffic against
    known-malicious destinations and admin-port contact on other LAN
    devices, with device context attached (`sensor-cli iot-events`,
    requires passive-capture to be configured).
  - Tier 4: a small, hand-verified reference table of real public CVEs
    for a handful of IoT vendors (e.g. Hikvision camera auth-bypass/RCE
    flaws) via `sensor-cli iot-advisories` — static, not a
    network-refreshed feed; that's out of scope for this release.
  - All four tiers are detection/reference only — Sensor never blocks
    traffic. Device classification is also shown inline in the
    `sensor-tui` ARP events tab.

### 0.1.7

- **Fixed: an audit finding's "description" text was always missing.**
  The Sensor's internal `ScanFinding` struct had no description field at
  all — only the title and recommendation were ever recorded/sent. Added
  the field and threaded it through end-to-end to the client (Mac/Linux).

### 0.1.6

- **Fixed: the daemon could crash with "Too many open files," losing any
  in-flight audit requests.** The full-port scan (up to 512 concurrent
  connections) left little headroom against systemd's default
  file-descriptor limit (1024). Raised to 65536.

### 0.1.5

- **Fixed: firing off several audit requests in quick succession spawned
  that many concurrent audits (nmap, etc.) against the same endpoint.**
  Only one audit per endpoint can be in flight now — a repeat request
  while one is already running gets handed the existing request's id
  instead of starting another.

### 0.1.4

- **Added: paired-endpoint status badges, and a full audit report on
  Enter.** The trusted-endpoint list now shows at a glance which
  endpoints are unaudited, clean, or have findings.
- **Changed: removed manual pairing.** The old flow of entering a public
  key directly is gone; pairing-code is now the only path.
- **Changed: removed the "this Sensor's info" screen and show the IP
  address in the title bar at all times instead.** Also added the IP
  address to the pairing-code screen.

### 0.1.3

- **Added: removed the `--nse` flag for the nmap NSE supplementary scan —
  it now always runs.** There was no real reason to disable it, so an
  active-audit run now always includes NSE.
- **Added: replaced mDNS auto-discovery pairing with a pairing-code
  scheme.** mDNS only works within a single LAN segment (useless once a
  Sensor sits behind a router), constantly broadcasts (network noise +
  always-visible), and has no real authentication of its own — all three
  problems are gone now. The Sensor runs at a fixed IP; clients pair using
  a short-lived pairing code (8 characters, expires in 10 minutes) the
  operator issues (a TCP control API, Ed25519-signature authenticated).
- **Added: accepting audit requests from clients.** A RoamSwitch client
  can now request an active vulnerability audit from a paired Sensor; the
  result is recorded in the scan history along with how it was triggered
  (manual vs. client-requested).

### 0.1.0 (initial release)

- **Added: deb/rpm package distribution.** Runs as a systemd service
  (`roamswitch-sensor.service`) instead of the earlier verification-only
  Docker build.
- **Added: passive LAN visibility extension (opt-in).** When
  `ROAMSWITCH_SENSOR_PASSIVE_CAPTURE_IFACE` names an interface, Sensor
  observes raw Ethernet/IPv4 headers on it (no payload inspection) to
  detect new devices it has never directly communicated with, and flag
  contact with known-malicious IPs from the local threat feed. Works on a
  single NIC for broadcast/multicast-visible traffic; a switch mirror
  (SPAN) port or inline transparent bridge is needed to see general
  unicast traffic between two other hosts.
- **Fixed: the TUI's discover ('d') key looked unresponsive.** The IPC
  call ran synchronously on the UI thread, so nothing redrew while it was
  in flight. Moved to a background thread with a live elapsed-time status
  line, and the TUI now also auto-discovers once on launch.

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.9.84

- **Fix: the port-scan guard's auto-block could be abused with a forged
  source address.** A SYN scan's source address is unauthenticated, so an
  attacker on the same network could send SYNs to many ports with the
  gateway's address as the source and make this host block its own gateway
  (in an isolated lab, 20 forged SYNs cut the host off from its gateway for
  10 minutes). Three changes:
  - The block now refuses only new inbound connections. Replies to your own
    connections and established flows keep working.
  - The gateway, DNS resolvers and the host's own addresses are never
    blocked.
  - The SYNs' source MAC is checked against the neighbor table, and the
    block is withheld when the source looks forged (the alert and the
    incident record are still produced).

  Auto-block stays on by default. Applies to both Client and Server
  Editions.

### 1.9.74

- **Fixed: the Sensor pairing form's field order didn't match the Mac
  client or the Sensor's own code-issuance screen** — it was IP address
  → name → code instead of code → IP address → name (optional). Typing
  top-to-bottom out of habit landed the pairing code in the IP field,
  producing an "invalid IP address" error that pointed at the wrong
  cause.
- **Fixed: the "Pair" button was clickable even with the required code/
  IP fields empty.** The Mac client disables it proactively until both
  are filled; Linux now matches.
- **Renamed "Pair Manually" to "Pair"** — mDNS auto-discovery was
  already removed in favor of the pairing-code flow, so there's no
  longer a non-manual alternative to contrast against (fixed across all
  10 languages).
- **Fixed: the Link Audit "Verify Safety" button did nothing at all
  when clicked with an empty field.** Now disabled proactively until a
  URL is entered, matching Mac.
- **Fixed: the onboarding wizard registered the current network at the
  least-protected "Open" level by default.** Now defaults to "Balanced,"
  matching Mac's onboarding.
- **Fixed: the Secret Leak Audit "Audit Text" button** is also now
  disabled until there's text to audit, matching Mac.

Found during a GTK/Mac UX-parity audit.

### 1.9.72

- **Fixed a structural race: manually switching security level (the
  Networks tab's Open/Balanced/Lockdown buttons, etc.) while the
  daemon's own 3-second autonomous reconciliation cycle was
  independently re-evaluating the network could apply nftables changes
  from both at once, with no serialization between them** — leaving the
  live ruleset and what the app believed was applied out of sync. The
  same failure pattern (two independent appliers fighting and
  "flapping") had already been observed and fixed for Air-Gap
  specifically; this closes the same gap in the ordinary profile-switch
  path by applying it inside the same lock the reconciliation cycle
  holds, so the two can never run concurrently.

### 1.9.71

A batch of fixes from a full audit of the network-control subsystem.

- **Fixed: right after a daemon restart, if the freshly-computed target
  level for the current network happened to match the internal
  "currently applied level" guess, the firewall/sharing-services
  re-apply was skipped entirely.** The guess defaulted to a real level
  name ("balanced"), so a match read as "nothing changed" and skipped
  verification — meaning a restart after a crash, a package upgrade, or
  a reboot could leave stale/missing rules in place with no self-heal
  until the network later changed to a genuinely different level.
- **Fixed: turning off sharing-service auto-control while it had SSH/
  SMB/etc. stopped left them stopped forever**, with no automatic path
  back. Now restores once on that OFF transition.
- **Fixed: the Updates tab's "Upgrade Now" button and spinner could fail
  to appear** (same `no_show_all` misuse pattern as the Sensor pairing
  form and Air-Gap card).
- **Fixed: VPN "Forget config," auto-VPN toggle, Tailscale exit-node
  change, and the Canary "Reset Baseline" button could briefly show
  stale state** — each refreshed its panel before the daemon had
  actually finished applying the change (same race class as the dev-
  server-isolation fix).
- Also fixed the same `no_show_all` pattern in the OS Hardening
  integration (not shipped in the standard edition): TPM2 Timeline Seal
  actions, the chkrootkit full-report panel, and the Lockdown report
  panel.

### 1.9.70

- **Fixed: the Sensor pairing form's fields and button could still fail to
  appear even with no Sensor paired.** 1.9.67's fix assumed calling
  `show_all()` directly on a widget sidesteps that widget's own
  `no_show_all` flag — it doesn't. GTK's `show_all()` checks the *target*
  widget's own `no_show_all` first and returns immediately, showing
  nothing, if it's still set. Now clears the flag before calling
  `show_all()`. Found and fixed the same bug pattern in the Air-Gap
  emergency-isolation card while at it.

### 1.9.69

- **Fixed: a Sensor audit finding's "description" text was always
  missing.** The Sensor's own internal struct had no description field —
  only the title and recommendation ever made it through (fixed
  upstream in Sensor 0.1.7).
- **Fixed: the npm lifecycle-script CSV export's "Danger" column was a
  bare true/false**, with no indication of which pattern (`curl | sh`,
  etc.) actually matched. Now shows the matched pattern's name.
- **Fixed: every CSV export's column headers were always in English.**
  The data rows already followed the app's language setting; the header
  row didn't. Now localized across all 10 languages.

### 1.9.68

- **Fixed: Sensor audit results and the probe log lacked enough
  information to actually act on.** Same fix as the macOS client (open
  ports, NSE results, and confirmed-safe checks now shown/exportable;
  the probe-log CSV export now includes the service name, vulnerability
  description, and recommendation).

### 1.9.67

- **Fixed: the Sensor manual pairing form's fields and button never
  actually appeared.** 1.9.66 made the form's container itself
  reappear, but the entries/button inside it had never been shown by
  GTK in the first place and stayed empty. Now shows the container's
  contents recursively.

### 1.9.66

- **Fixed: the Sensor pairing screen's manual pairing form always failed —
  it was calling an old IPC path that required the Sensor's public key up
  front.** Under the pairing-code scheme there's no way for the operator
  to know that key in advance, so this path could never succeed. Now uses
  the same correct path the CLI already used, and dropped the now-unneeded
  public-key field from the form.

### 1.9.65

- **Changed: removed the own-endpoint public-key display from the Sensor
  pairing screen.** No longer needed under the pairing-code scheme; the
  manual pairing form is now hidden once at least one Sensor is paired.
- **Changed: CVE-map components (kernel CVE map, all package-CVE maps)
  now check for updates once a month instead of daily.** The
  cloud-side republish cadence also moved from daily to weekly.

### 1.9.64

- **Added: removed the nmap NSE supplementary scan's on/off toggle — it
  now always runs.** There was no real reason to disable it, so an active
  audit now always includes NSE when it's enabled.
- **Added: replaced mDNS auto-discovery pairing with RoamSwitch Sensor
  with a pairing-code scheme.** mDNS only works within a single LAN
  segment (useless once a Sensor sits behind a router), constantly
  broadcasts (network noise + always-visible), and has no real
  authentication of its own — all three problems are gone now. The Sensor
  runs at a fixed IP; pairing now uses an issued pairing code. Also added
  requesting an active audit from a paired Sensor and later retrieving
  and storing the result.
- **Added the `get_sensor_audit_results` MCP tool**, so an AI agent can use
  a Sensor's outside-in findings as input for remediation planning.

### 1.9.56

- **Added: guard against the investigation agent recursively triggering
  itself.** The agent's own research activity (e.g. `grep`/`cat` scanning
  logs and config files) could itself get flagged as a new eBPF/FIM
  incident, spawning another investigation agent to look into the first
  agent's own activity, and so on — reproduced live (a `grep` run while
  investigating a `pkexec` alert triggered a fresh "Read sensitive file
  untrusted" detection against `/etc/pam.conf`). Now tracks the PID of any
  currently-running investigation-agent process; a new detection whose
  target process is a descendant of one skips spawning a second agent
  (the first-pass triage and its notification are unaffected).

### 1.9.55

- **Fixed: redesigned the investigation-agent handoff's `sudo` wrap.** The
  previous fix (1.9.54) baked both the PATH resolution and the `sudo`
  delegation directly into the `command`/`args` fields, which meant
  re-running the wizard could no longer recognize a saved preset
  (claude/agy/codex/opencode), always fell back to the custom-entry
  path, and — if confirmed as-is — wrapped an already-wrapped command a
  second time, breaking it (reproduced live). A new `run_as` field now
  holds the operator's username, and the `sudo` wrap is applied by the
  daemon at spawn time instead; `command`/`args` stay the tool's own
  clean invocation.
- **Added: extended the investigation-agent handoff to the Resource
  Exhaustion / Process Anomaly Guard too.** Previously wired into eBPF,
  Critical-Path FIM, and lockfile FIM only; now also covers sustained
  memory growth, sustained high CPU usage, crash loops, zombie-process
  growth, and rising system load.

### 1.9.48 - 1.9.54

- **Added: this endpoint's own public key/address display, needed for
  mutual pairing with RoamSwitch Sensor** (1.9.48–1.9.50): both a CLI
  command (`roamswitch sensor key`) and a GUI display in the Sensor
  pairing card. Also fixed the GUI's own public key not actually being
  copyable via label selection alone.
- **Expanded the investigation-agent handoff** (eBPF/FIM deep-dive
  investigation, Server Edition only) (1.9.51–1.9.54): fixed the setup
  wizard's tool-choice prompt not remembering the previous selection,
  extended it beyond eBPF to Critical-Path FIM and lockfile FIM tampering
  detections, added the same first-pass triage report to FIM detections,
  and fixed it never actually working in practice under root (unresolved
  `PATH`, inaccessible keyring credentials).

### 1.9.39 - 1.9.47

- **Added (1.9.39):** typosquat detection (npm/pnpm package.json, static,
  Pro) — flags dependency names close to popular npm packages by edit
  distance (e.g. `expres`→`express`), no network access, list distributed
  via the daily signed updater pipeline.
- **Fixed (1.9.40):** a log-audit frequency-spike notification couldn't be
  corroborated right after it fired (the causing log lines were already
  consumed) — now recorded into notification history like new-pattern
  detections.
- **Fixed (1.9.41):** a layout bug collapsed the kernel-CVE detail column
  into single characters when many CVEs matched. **Improved:** added
  section headers to the Network Management tab.
- **Fixed (1.9.42):** the running-kernel CVE check false-flagged
  distro-specific security backports that only bump the ABI build number,
  not the upstream major/minor version.
- **Added (1.9.43, Server Edition):** Container Exec Guard — tracks
  container start/stop and marks each container's rootfs with fanotify's
  notify-only `FAN_OPEN_EXEC`, reading the executed file from the event's
  own file descriptor so a self-deleting attacker binary is still
  captured. Prompted by a real intrusion (RCE → in-container cryptominer
  → self-delete). Also: Egress Guard now covers container-originated
  (`forward`-chain) traffic, added per-process CPU-saturation detection,
  and fixed a false "eBPF Runtime Guard active" health-check result when
  Falco/Tetragon wasn't actually installed.
- **Fixed (1.9.44, Server Edition):** FIM/Lockfile FIM re-sent the same
  tampering notification every check interval instead of once; corrected
  the lockfile-tampering guidance to the proper two-step verify→update
  flow; fixed eBPF alerts showing "PID: none" when Falco reported the PID
  as a JSON string; added a Falco exception for `systemd-executor`
  (false-positived on every SSH login on systemd ≥255); separated
  updater integrity-failure messaging from generic connectivity errors.
- **Added (1.9.45):** automated local first-pass triage for eBPF alerts
  (false-positive likelihood + reasons + next-check commands, Markdown
  report saved) and an optional handoff to an agentic CLI (`guard.yaml`
  `investigation`, Server Edition, off by default, skipped right before
  host Air-Gap isolation); detection of secret exfiltration via `env`/
  `.env` reads (custom Falco rule); fixed the Linux client's own
  FIM/Lockfile FIM re-notify loop and `lockfile-fim verify`'s `$HOME`
  resolution under `sudo`.
- **Added (1.9.46):** interactive setup for the investigation-agent
  handoff in `roamswitch server setup` (preset menu: Claude Code / agy /
  Codex CLI / OpenCode / custom).
- **Fixed (1.9.47):** running `lockfile-fim` without `sudo` failed with a
  confusing bare "Permission denied" instead of a clear error.

### 1.0.0 - 1.9.38 (initial release through the stable era, summarized)

- **Initial release (1.0.0)**: ported the macOS edition's zero-trust
  architecture to Linux (systemd + nftables). Followed by the core
  defense capabilities — VPN tunnel + killswitch (WireGuard/Tailscale),
  unknown-port auto-blocking, passive link protection, daily threat feed,
  BadUSB/USB storage authorization, autonomous ARP-spoofing detection
  (1.0.1 - 1.0.66).
- **Official launch of RoamSwitch Server Edition (1.1.0)**: Falco eBPF
  runtime threat detection & auto-isolation, Critical Path FIM, a 25-item
  server security health check, Webhook/PagerDuty alerts. Followed by
  event-driven FIM, Egress/C2 containment, Tetragon sensor support, and
  fine-grained `guard.yaml` policy configuration (1.1.1 - 1.3.2).
- **Package CVE Scan (1.5.0)**, **Log Audit template anomaly detection +
  automatic secret masking (1.6.0)**, **incident history for Air-Gap
  trigger guards exposed via MCP/CLI (1.7.0)**, **File Scan Guard &
  Docker risk detection (1.4.1 - 1.8.0)**.
- **Evil-Twin SSID warning, BadUSB keystroke-timing anomaly detection,
  Ransomware Canary blast-radius evidence (1.9.0 - 1.9.5)**; **notification
  history, ClickFix detection, and the log audit's background schedule
  added to the client edition (1.9.6 - 1.9.15)**.
- **Critical Path FIM extended to the client edition, Resource Exhaustion
  / Process Anomaly Guard (Server Edition), a root-cause fix for Log
  Audit's masking regex, and fixes for several Server Edition
  success-without-verification bugs (1.9.16 - 1.9.26)**.
- **Four npm-install supply-chain-risk features (Lockfile FIM,
  install-script inventory, npm signature verification, bubblewrap
  sandboxing), typosquat detection, crypto-wallet seed-phrase leak
  detection, and a critical fix for the Default-Deny firewall blocking
  100% of Docker containers' outbound traffic (1.9.27 - 1.9.38)**.

---

## RoamSwitch for Mac

## 1.9.46

- **Fix: incoming port-scan detection was not running (confirmed on macOS 27).**
  `pflog0`, the interface pf writes its log to, was not created automatically,
  so the detector stopped right after starting. The helper now creates `pflog0`
  when it is needed. We also confirmed on a real Mac that a forged scan claiming
  the gateway's address is not blocked, and that the block stops only new TCP
  connections while replies keep working.

## 1.9.45

- **Fix: the port-scan guard's auto-block could be abused with a forged
  source address.** A SYN scan's source address is unauthenticated, so an
  attacker on the same network could send SYNs "from" the gateway and make
  the Mac block its own gateway (the same structure was reproduced in the
  Linux edition's isolated lab). The block now refuses only new TCP
  connections, and the gateway, DNS resolvers and the Mac's own addresses
  are never blocked. Auto-block stays on by default. Unlike the Linux
  edition, source-MAC verification is not done here because pf's log
  carries no Ethernet header.

## 1.9.44

- **Added: broader active vulnerability checks.** The manual active scan now
  also detects unauthenticated Elasticsearch, CouchDB, Jenkins and VNC
  services, plus SMBv1 being enabled and SMB signing not being required on
  `smbd`. Each check is a single read-only connection with no login attempt and
  no writes. Translations for all 10 languages are included.

## 1.9.43

- **Fixed: a "Critical system file tampering detected (/etc/hosts: modified)"
  warning appeared right after every update.** Link Guard's hosts fallback
  rewrites its managed section of `/etc/hosts` (the `0.0.0.0 <domain>` lines
  RoamSwitch itself writes) on launch and on every feed refresh. Critical Path
  FIM hashed the whole file, so it flagged the app's own routine edits as
  tampering. The routine contents of the managed section (`0.0.0.0 <domain>`
  lines and comments) are now excluded from the comparison; every other change
  is still detected — including an entry written outside the section (for
  example one redirecting a site to another IP) and any non-`0.0.0.0` line
  hidden inside it. Because the comparison changed, the `/etc/hosts` baseline is
  re-captured once, on the first check after this update (baselines for the other
  files are unchanged).

## 1.9.42

- **Fixed: every app update showed a burst of "Failed to toggle sharing
  services" / "Failed to enable incoming port-scan detection" warning
  notifications.** Right after an update the privileged helper is replaced
  and relaunched, so for a few seconds calls to it fail even though nothing
  is wrong. Those transient failures were reported immediately as warnings,
  and because the security level is applied several times around launch, the
  same notification appeared repeatedly. Transient connection drops are now
  retried automatically (up to ~7 seconds), and if a call still fails the
  same warning is shown at most once per 10 minutes. Operations that must
  not run twice (such as redeeming a single-use pairing code) are never
  retried.

## 1.9.41

- **Fixed: the active-verification unit tests wrote their fake results into
  the real diagnostic log (`active_vuln_scan_log.json`).** Tests that probe a
  local stub server (a fake redis-server on an ephemeral port) recorded
  their results to the production log location, so exporting that log on a
  development machine showed findings that never existed. Tests now write to
  a temporary file, and no longer depend on whether `nmap` is installed.
  There is no change to the app's behavior and no impact on normal use.

## 1.9.40

- **Fixed: the Mac Security Log Audit window's category-filter button
  row was horizontally scrollable to handle its 7 categories not
  fitting the window width, but had no scroll indicator at all** —
  with truncated fragments visible at both edges and nothing showing
  it could scroll, it read as broken rather than "swipe for more."
  This happened routinely even in a wide window, since the row
  competes with a fixed-width search field. Now shows the scrollbar.

## 1.9.39

- **Fixed: the "Package CVE Scan" window's tab switcher could overflow
  the window width as sections were added, making the last tab
  ("Sandboxed Install") completely unreachable.** A segmented control
  just clips whatever doesn't fit, with no way to reach it — and the
  window itself wasn't even resizable, so there was no user-side
  workaround either. Switched the tab switcher to a dropdown (always
  fits, regardless of section count or label length/language) and made
  the window resizable.

## 1.9.38

A batch of fixes from a full audit of the network-control subsystem.

- **Fixed: stopping/restoring sharing services never checked launchctl's
  exit code and always reported "success" regardless.** Away from
  home, the app could claim sharing services were stopped while SSH
  etc. was actually still running. Now verifies against actual service
  state (`isServiceLoaded`) and notifies on failure.
- **Fixed: clicking "Release isolation" in the port audit sheet looked
  like it did nothing.** The underlying release genuinely worked; the
  sheet itself just had no SwiftUI observation wired up, so it never
  re-rendered to show it.
- **Fixed: a helper-side failure to enable incoming port-scan detection
  was only logged, never surfaced to the user** — the toggle could read
  "on" while detection silently wasn't running.

## 1.9.37

- **Fixed: a Sensor audit finding's "description" text was always
  missing.** The Sensor's own internal struct had no description field —
  only the title and recommendation ever made it through (fixed
  upstream in Sensor 0.1.7).
- **Fixed: the npm lifecycle-script CSV export's "Danger Pattern" column
  was a bare true/false**, with no indication of which pattern
  (`curl | sh`, etc.) actually matched. Now shows the matched pattern's
  name.
- **Fixed: every CSV export's column headers were always in English.**
  The data rows already followed the app's language setting; the header
  row didn't. Now localized across all 10 languages.
- **Fixed: the "Recommendation" label in a Sensor audit's Markdown
  export never translated outside Japanese**, due to a mismatched
  catalog key.

## 1.9.36

- **Fixed: Sensor audit results and the Active Vulnerability Scan log
  lacked enough information to actually act on.** A Sensor audit result
  only ever showed the flagged findings — the open-port list, NSE safe-
  script results, and confirmed-safe checks the same scan produced
  weren't displayed or exportable. The Active Vulnerability Scan log's
  CSV export only had an internal probe id, with no indication of which
  port, which service, or what the actual issue was. Both now show which
  port, which service, what was found, and what to do about it.

## 1.9.35

- **Fixed: the helper crashed on every successful Sensor pairing.** A
  reentrant lock in the pairing-completion path triggered libdispatch's
  deadlock detection, killing the helper process — the Sensor correctly
  recorded the pairing while the Mac side always lost it. Found and fixed
  via a real crash report.
- **Fixed: incoming port-scan detection's logging silently stopped working
  in the common case (no other firewall tier engaged) because reloading
  pf's own stock ruleset right afterward wiped the rules it had just
  loaded.** `tcpdump` kept failing to start and retrying forever, burning
  helper resources; retries are now capped at 5 in a row.
- **Fixed: the update-available alert was easy to miss on this
  Dock-icon-less, menu-bar-only app.** Implemented Sparkle's gentle
  reminders so a background update check brings the app forward when it
  finds one.

## 1.9.34

- **Fixed: the helper now reliably restarts on app update.** Its version
  string was a hand-maintained literal that fell out of sync with each
  update, so a stale pre-update helper process kept running after an
  update and failed to communicate over XPC (interface mismatch). It now
  reads the real version from the app bundle at runtime instead.
- **Changed: removed the own-endpoint public-key display from the Sensor
  pairing screen.** No longer needed under the pairing-code scheme; the
  manual pairing form is now hidden once at least one Sensor is paired.
- **Changed: the CVE map now checks for updates once a month instead of
  daily.** The cloud-side republish cadence also moved from daily to
  weekly.

## 1.9.33

- **Added: removed the nmap NSE supplementary scan's on/off toggle — it
  now always runs.** Root-caused a bug where the toggle showed "on" but
  an MCP-triggered audit never actually ran NSE: `RoamSwitchMCPServer`
  runs as a separate process from the main app, so its direct
  `UserDefaults` read always saw an empty domain. Removing the toggle
  entirely resolves this along with the underlying cross-process bug.
- **Added: replaced mDNS auto-discovery pairing with RoamSwitch Sensor
  with a pairing-code scheme.** mDNS only works within a single LAN
  segment (useless once a Sensor sits behind a router), constantly
  broadcasts (network noise + always-visible), and has no real
  authentication of its own — all three problems are gone now. The Sensor
  runs at a fixed IP; pairing now uses an issued pairing code. Also added
  requesting an active audit from a paired Sensor and later retrieving
  and storing the result, plus the `get_sensor_audit_results` MCP tool.

## 1.9.27 - 1.9.32

- **Expanded npm/pnpm-install supply-chain risk coverage** (1.9.28–1.9.30,
  Pro): following dependency-lockfile tamper monitoring, install-script
  inventory, and npm signature/provenance verification, added a
  `roamswitch-npm` wrapper that actually runs installs inside a
  network-denied sandbox, plus edit-distance typosquat detection (e.g.
  `expres`→`express`). Detection of leaked crypto-wallet seed phrases and
  private keys (BIP39/WIF/BIP32, checksum-verified) also shipped in 1.9.27.
- **Added: RoamSwitch Sensor pairing and incoming port scan detection**
  (1.9.32, Pro): mDNS mutual-trust pairing with the separate RoamSwitch
  Sensor product for active vulnerability audits, plus automatic
  detection and 10-minute blocking of nmap/masscan-style reconnaissance.
  Also added CSV export for notification history, package CVE scan, and
  active vulnerability scan logs.
- **Fixed:** a log-audit frequency-spike notification couldn't be
  corroborated right after it fired (1.9.31); the secret leak auditor
  missed Google AI Studio's new API key format (1.9.32).
- **Improved:** the automatic log audit's "new pattern" detection no
  longer pops a Notification Center alert every time (1.9.32) — a batch
  with a frequency spike still alerts, new-patterns-only batches are
  recorded to history without a popup.

## 1.9.16 - 1.9.26

- **Added: Critical Path FIM, a background tamper-detection guard for
  critical system files** (Pro, 1.9.16): SHA-256 baseline monitoring of
  low-churn paths (`/etc/sudoers`, SSH config, `/etc/hosts`, root's
  `authorized_keys`) that no routine OS update or Homebrew install ever
  touches.
- **Important: fixed four security items that reported success without
  confirming anything actually happened** (1.9.19): automatic dev-server
  port blocking, malware-quarantine file moves, the Security Dashboard's
  "macOS Accessory Connection Protection" check (previously hardcoded
  `isPassed: true`), and Critical Path FIM's helper-connection failures
  now all reflect the real outcome instead of an assumed one.
- **Fixed a wide range of Log Audit false positives** (1.9.16 - 1.9.22):
  CoreAudio HAL traces, loginwindow's `Application`/`ApplicationManager`
  bookkeeping (replaced with a class-level structural rule), a root-cause
  template-masking bug shared with the Linux edition, lock-screen
  wallpaper-rendering and sleep/wake internals, and `0x`-prefixed pointer
  addresses that the masking regex couldn't catch.
- **Improved: Log Audit's anomaly notification, previously just a raw
  template string and z-score, now explains in plain language whether
  action is needed** (1.9.23), and template anomalies are now shown and
  searchable in the Log Audit window itself instead of only a KPI-card
  count.
- **Fixed: the Wi-Fi radio killed during an automatic Air-Gap didn't come
  back on its own after an app crash or Mac restart** (1.9.23) — folded
  into the same pf air-gap state so the independent AirGapFailsafe
  watchdog covers restoring Wi-Fi too, verified live within the 10-minute
  bound.
- **Added: newly-detected template anomalies are now persisted to
  notification history** (1.9.24), and the KPI cards on the Log Audit
  window became clickable (previously purely decorative).
- **Improved: EICAR test-signature hits no longer raise a notification**
  (1.9.25) — recorded to history only, so a real threat alert isn't
  buried among no-action ones.
- **Fixed: Link Guard's homograph detection and the Ransomware Canary
  Guard's MITRE ATT&CK ID were both comparing translated display strings
  instead of a language-independent value, silently breaking in most
  non-JA/EN/FR languages** (1.9.26). Also brought the MCP server, SDK,
  Help & Guide, and built-in knowledge base up to date with current
  features across all 10 languages, and fixed some regional locales
  (e.g. pt-BR) falling back to Japanese.

## 1.9.13 - 1.9.15

- **Resolved false positives and duplicate notifications around Automatic
  Log Audit (1.9.10)**: the kickoff scan right after enabling now learns
  silently instead of notifying; a transient pasteboard-server hiccup
  (`CFPasteboardRef`) and AppKit's internal focus-change KVO notification
  (`firstResponder changed`) were added to the exclusion list; overlapping
  scan windows no longer re-flag the same event.
- **Resolved login/logout false positives** from macOS's internal
  `PersistentAppsSupport`/`BTMManager` events.
- **Improved notification bodies**: now show a "N new patterns, K
  frequency spikes" breakdown plus readable example log lines.

## 1.9.6 - 1.9.12

- **Added detection of ClickFix-style malicious commands on the
  clipboard**, including the Script Editor pivot used to dodge Terminal's
  history-based detection.
- **Added notification history (keeps the past 7 days)**.
- **Added Automatic Log Audit (Pro)**: scans in the background every hour
  and notifies on new patterns or frequency spikes (on by default for
  Pro).
- **Redesigned the log audit's frequency-spike detection to compare each
  template against its own history**, resolving repeated false positives
  from legitimate recurring jobs.
- **Fixed two Automatic Log Audit notification strings missing
  translations**.

## 1.0.0 - 1.9.5 (initial release through the stable era, summarized)

- **Initial release (1.0.0 - 1.3.0)**: autonomous network detection by
  gateway MAC, automatic firewall/sharing-service switching, port anomaly
  blocking, ARP spoof auto-containment, and foundational MCP integration.
- **Local AI/LLM server protection, clipboard secret protection, and the
  MCP server open-sourced (1.4.0 - 1.5.9)**.
- **VPN tunnel + killswitch (WireGuard), proactive gateway ARP/NDP
  pinning, BadUSB/USB storage authorization guards, passive Link Guard,
  Canary decoy-file persistence (1.6.0 - 1.7.6)**.
- **Topmost emergency alert overlays, one-click health-audit remediation,
  dual VPN backend support (WireGuard/Tailscale) (1.8.0 - 1.8.3)**.
- **Static-signature download detection, ClickFix protection, and Docker
  risk detection guards added; automatic Air-Gap isolation tied to Apple
  XProtect; the secret-leak auditor gained whole-folder scanning
  (1.8.4 - 1.8.9)**.
- **Active Vulnerability Scan and Package CVE Scan ported from the Linux
  edition, an Evil-Twin SSID warning, BadUSB keystroke-timing anomaly
  detection, and gaps in the MCP server closed (1.9.0 - 1.9.5)**.
