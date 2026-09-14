# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.9.38

- **Added: sandboxed execution of npm/pnpm install lifecycle scripts
  (Client Edition only, Pro).** Where the previous three features only
  detected and warned, this one actually confines the execution of
  preinstall/install/postinstall/prepare scripts under a bubblewrap
  (bwrap) filesystem restriction. The download phase runs normally with
  network access (`--ignore-scripts`); only the subsequent script phase
  shadows credential paths (`~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.netrc`,
  `~/.npmrc`, etc.) with an empty tmpfs (files use `--ro-bind /dev/null`
  instead). Network access itself is not blocked, so legitimate packages
  like sharp/esbuild that fetch platform-specific binaries in postinstall
  keep working. Adds a new `roamswitch install [--pm npm|pnpm]`
  subcommand. Supports npm/pnpm; yarn is not supported. Refuses to run
  lifecycle scripts if bwrap isn't installed, rather than silently
  falling back to running unsandboxed.

### 1.9.37

- **Added: three features addressing npm-install supply-chain risk
  (Client Edition, two of them also on Server Edition).** "Lockfile FIM"
  continuously watches dependency lockfiles (package-lock.json/yarn.lock/
  pnpm-lock.yaml/npm-shrinkwrap.json) for external tampering via a SHA-256
  baseline (Client + Server, `roamswitch lockfile-fim`). "Install Script
  Inventory" statically lists preinstall/install/postinstall/prepare
  scripts declared by package.json files under node_modules (Client only,
  an inventory rather than a threat verdict, `roamswitch scan-scripts`).
  "npm Signature Verification" contacts the npm registry to verify
  installed packages' signatures/provenance (Client + Server, opt-in,
  `roamswitch audit-npm-signatures`) — the only RoamSwitch feature that
  talks to npmjs.com, disabled by default and requiring a confirmation on
  every run. All three are Pro-only.

### 1.9.36

- **Added: the secret & API key leak auditor now also detects cryptocurrency
  wallet seed phrases and private keys.** Prompted by Microsoft's June 2026
  writeup on "Crypto Clipper" malware, which watches the clipboard for wallet
  seed phrases and private keys and swaps in the attacker's own address when
  you paste a payment destination. BIP39 mnemonic seed phrases (12–24 words)
  are verified against their real SHA-256-based checksum, so ordinary prose
  that happens to contain a few of the same words is never mistaken for one.
  Bitcoin private keys (WIF format) and extended private keys
  (xprv/yprv/zprv/tprv) are also detected, checksum-verified. Unlike an API
  key, a detected value is never shown at all — not even partially — and the
  advice is to move funds to a brand-new wallet rather than "revoke" it.

### 1.9.35

- **Fixed: the EULA's description of network communication no longer
  matched reality.** EULA §5 said update checks happen only via apt, which
  contradicted the receive-only traffic that already occurs for the
  threat-feed fetch and ClamAV definition updates.
- **Added third-party license notices to the in-app Help screen**
  (ClamAV (GPLv2), Tailscale (BSD-3-Clause), GTK3 (LGPL-2.1)), localized
  into all 10 languages.

### 1.9.34

- **Brought the MCP server, SDK, and in-app Help & Guide fully up to date
  with current features.** The read-only MCP server grew from 19 to 25
  tools, adding status reads for VPN (WireGuard/Tailscale), the passive
  Link Guard, emergency network cutoff (Air-Gap, including frozen
  processes), automatic sharing-service shutdown, the Bluetooth guard, and
  USB guards. The guard-status listing now also reports more of the
  settings actually available in the app.
- URL safety checks, the secret-leak auditor, the security log auditor, and
  the Ransomware Canary Guard used to always answer in Japanese regardless
  of the app's language; they now support all 10 UI languages (Japanese,
  English, Simplified Chinese, Traditional Chinese, Korean, German, French,
  Spanish, Italian, Portuguese), matching the corresponding app tabs.
- Fixed the Server Edition diagnostics' item count (it said 28; the real
  count is 30) and localized its full text into all 10 languages (it was
  previously Japanese/English only). Also fixed a handful of Client
  Edition items (Docker socket, privileged containers, runtime isolation,
  kernel CVE) that stayed in Japanese in every other language.
- Overhauled the MCP's built-in knowledge base (used by `get_app_help`) for
  full 10-language coverage, adding previously-missing topics: VPN, the
  secret-leak auditor, log auditing, notification history, ARP
  monitoring/gateway pinning, Air-Gap, sharing-service control, the
  Bluetooth guard, and the active vulnerability scan.
- Rewrote the app's built-in "Help & Guide" tab to cover features it never
  mentioned: VPN, ARP monitoring/gateway pinning, the passive Link Guard's
  fail-closed behavior, the secret-leak auditor, clipboard monitoring,
  emergency network cutoff, notification history, and the unified incident
  timeline. The diagnostics item count (24) is now consistent across all
  10 languages.
- `server.conf`'s `language` setting now accepts all 10 languages plus the
  system locale, instead of only Japanese/English.

### 1.9.33

- **Improved: EICAR test-signature hits no longer raise a notification.**
  EICAR is the industry-standard string for checking that an antivirus
  scanner is live — not a real threat. It was already never quarantined or
  blocked, but every hit still popped a "🧪 EICAR test signature seen
  (harmless)" desktop notification. Alerts that need no action bury the
  ones that do, so these are now recorded in notification history only
  (`roamswitch notifications`, the app's history view, MCP). Applies to both
  the fanotify guard and the download guard.

### 1.9.32

- **Fixed: there was no way to release a process frozen by a false
  positive.** When the rapid-encryption detector fires, the suspected
  process is frozen with SIGSTOP rather than killed — the whole point being
  that the freeze can be undone if the detection was wrong. In practice it
  could not be: nothing recorded *which* process had been frozen, and
  neither the app nor the CLI offered any way to release one. So when a
  legitimate program tripped the detector (anything that writes a lot of
  high-entropy files quickly — making a backup, installing packages), it
  stayed stopped until the user copied the PID out of the notification and
  ran `kill -CONT` by hand in a terminal. Frozen processes are now recorded;
  the app's Canary tab lists them with a release button, and the CLI gains
  `roamswitch frozen [list|resume <PID>|resume all]`. `roamswitch
  emergency-restore` also used to resume only processes frozen by some of
  the detection paths — it now covers all of them. **A freeze is not a kill:
  a released process picks up exactly where it stopped.**
- **Fixed: every notification appeared twice in the history.** The daemon
  recorded a detection into the notification history and then asked the app
  to display the desktop notification; the app recorded the same thing a
  second time as it displayed it. The result was the same entry listed
  twice, about half a second apart, in the history view, in `roamswitch
  notifications` and over MCP. It is now recorded once, by the side that
  detected it. Duplicates already on disk (up to a week's worth) also stop
  being shown.
- **Improved: ransomware alerts no longer describe containment that didn't
  happen.** If the process had already exited by the time the burst was
  evaluated, or was a protected process (a container runtime, for example),
  no freeze took place — but the notification said "frozen instantly with
  SIGSTOP" regardless. The wording now depends on whether the freeze
  actually took, and when it did, the alert also carries the command that
  undoes it. Relatedly, a detection whose process could not be identified
  (already gone, and therefore never frozen) is now recorded in the
  notification history without raising a popup: those alerts named a PID the
  user could neither inspect nor release, and repeated often enough to bury
  the alerts that did need attention.

### 1.9.31 (urgent update recommended for Server Edition)

- **Fixed: the Default-Deny firewall policy was blocking 100% of Docker
  containers' outbound API traffic.** The `forward` chain that
  `roamswitch-server` (re-)applies via nftables on every start/restart was
  being created with `policy drop` and zero rules in it — no `ct state
  established,related accept` at all — so every packet a container sent
  outbound (to an exchange API, an external webhook, anything) and every
  reply to it was unconditionally dropped at the kernel netfilter layer.
  Root-caused after two independent live reports of "every Docker
  container's outbound call times out / 502s." Fixed by adding `ct state
  established,related accept` to the forward chain, plus a rule accepting
  forwarded traffic that didn't arrive on the external interface — so
  container egress and inter-container traffic work again while traffic
  arriving directly from the external interface (the thing this policy was
  actually meant to stop) still gets dropped. If the external interface
  can't be auto-detected, it now fails closed (forwarded traffic stays
  blocked) with a warning logged, rather than guessing. **If you run
  Server Edition with the nftables Default-Deny policy enabled and have
  Docker containers (or anything else) that need outbound network access,
  update to this version.**

### 1.9.30

- **Added: newly-detected template anomalies now persist to notification
  history.** A "template anomaly" gets absorbed into the known-template
  baseline the instant it's first seen, so re-scanning never flagged the
  same content as "new" a second time, leaving no way to look it back up
  later. Now recorded to notification history at the moment a new pattern
  (`is_new`) is detected (frequency-spike anomalies are excluded by design,
  since those can legitimately re-trigger on repeated scans). Pairs with
  the same fix on the macOS edition.
- **Maintenance: hardened the apt/rpm publish pipeline.** Added a
  concurrency lock so releases can't overlap, and a post-publish
  verification step that hashes the just-built packages against what's
  actually served at the published URLs. Also revisited the CDN cache
  settings for these paths. Prompted by a brief window during this release
  where CDN mirror-sync timing caused some packages to fail downloading.
- Experimental: added MITRE ATT&CK mapping to eBPF Guard's ptrace-family
  alerts (continued, unverified prototype).

### 1.9.29

- **Improved: Log Audit's anomaly notification was incomprehensible — and
  just anxiety-inducing — to a non-expert user.** Same fix as the Mac
  edition, applied to the client daemon, Server Edition, the CLI, and the
  GTK app. Fixed a misleading "still learning frequency" note that was
  wrongly applied to first-sightings (a "new pattern" hit is a one-shot
  detection), and added a plain-language line to the notification body.
  Template anomalies — previously visible only as a bare count on a KPI
  card — are now shown and searchable in the CLI's `audit-logs` output and
  the GTK app's own Log Audit tab.
- **Added: an "Allow" action on the port-anomaly-guard's auto-block
  notification.** The safe-by-default behavior (block a newly-listening
  process immediately, even on a trusted network) is unchanged; clicking
  Allow releases that specific block on the spot for a legitimate dev
  server, reusing the same path as the GUI's port-audit "allow" button.
- Several experimental features landed (a unified incident timeline, an
  XDP boot-time default-deny gate, malicious-IP egress blocking, prioritizing
  pinpoint isolation in the eBPF Guard's critical-tier response, expanded
  MITRE ATT&CK mapping, and more) — some as unverified prototypes.

### 1.9.27

- **Fixed: Log Audit's masking couldn't catch `0x`-prefixed pointer
  addresses.** The existing hex regex (`\b[0-9a-fA-F]{8,}\b`) never fires
  right after "0x" (no word boundary between the "x" and the hex digits
  that follow), so XPC connection IDs and similar `0x...` addresses passed
  through completely unmasked, the same root cause as the digit/hostname
  fusion bug in a different shape. Found live on the macOS edition: lines
  like `[0xbb38aae40] invalidated because the current process cancelled
  the connection by calling xpc_connection_cancel()` kept re-triggering as
  a "new pattern" forever since the address changes on every connection.
  Added a dedicated regex that masks `0x`-prefixed hex first. Ported the
  identical fix to the macOS edition too.

### 1.9.16 - 1.9.26

- **Added: Critical Path FIM (tamper detection) now also runs
  automatically in the background on the client edition** (1.9.17),
  bringing the same event-driven fanotify watch plus periodic backstop
  scan that was previously Server Edition-only.
- **Important: fixed a root-cause bug in Log Audit's template-masking
  regex** (1.9.18) — digits adjacent to a letter weren't masked at all, so
  timestamp differences alone kept re-flagging the same line as a "new
  pattern" forever. Verified against a live production server's 691
  learned templates collapsing to 285 (58.8%) once fixed.
- **Important: fixed Client-Edition-only commands returning fabricated
  information on Server Edition, and several security actions reporting
  success without confirming anything actually happened** (1.9.19) —
  `emergency-restore`, kernel/mount hardening, and `roamswitch airgap`
  among others now wait for and check the real result before claiming
  success.
- **Added: Resource Exhaustion / Process Anomaly Guard (Server Edition
  only)** (1.9.20 - 1.9.22): detects memory-exhaustion DoS, use-after-free
  crash loops, sustained zombie-process growth, and system-load growth,
  correlated against eBPF Runtime Guard / Critical Path FIM events for a
  confidence tier. The same window also fixed a notification-history gap
  affecting 26 of 28 client daemon call sites, a DOCKER-USER chain
  startup-order race, and 7 false-verdict bugs in the 28-item security
  audit.
- **Fixed a wide range of Log Audit and ransomware-detection false
  positives** (1.9.20 - 1.9.25): `cp`/`mv`/`pip` ransomware false-freezes,
  routine noise from anacron/tailscaled/cron sessions and more,
  generalized AppArmor-profile matching, Log Audit re-detecting its own
  past alerts as new patterns forever, and the ransomware allowlist not
  applying to already-exited short-lived processes.
- **Fixed: ARP-spoofing detection false-flagging Docker bridge-internal
  IPs** (1.9.24), plus the GUI's notification-history tab never updating
  on its own.
- **Important: fixed `audit-secrets`'s recursive directory scan recursing
  forever through a symlink cycle**, pinning a live host at ~96% CPU for
  over 95 minutes (1.9.26). Switched to the lstat-based
  `DirEntry::file_type()`, which never follows symlinks.

### 1.9.6 - 1.9.15

- **Added the log audit's background schedule to the client daemon too**:
  resolves the asymmetry where only Server Edition ran it automatically.
- **Added notification history (keeps the past 7 days)**: available via
  `roamswitch notifications`, the GUI, MCP, and the SDK.
- **Added detection of ClickFix-style malicious commands on the
  clipboard**.
- **Resolved many log-audit false positives**: excluded the daemon's own
  startup banner and self-narration, snapd/gnome-shell OS noise, and
  Ollama's/Ubuntu Pro's own routine logging. Replaced the one-by-one
  enumeration of systemd unit-lifecycle lines with a structural check
  instead (the sending process is genuinely systemd itself, verified via
  journald's kernel-tied credentials, and the message matches systemd's
  own fixed phrasing) so a not-yet-catalogued service is covered
  automatically.
- **Resolved duplicate notifications and lost learning progress** from an
  old/new process race on daemon restart, and from overlapping scan
  windows re-flagging the same event.
- **Fixed notification history appearing empty from a regular user's
  CLI** (a location mismatch with the root-privileged daemon).
- **Improved notification bodies**: now show a "N new patterns, K
  frequency spikes" breakdown plus readable example log lines.

### 1.9.0 - 1.9.5

- **Added an Evil-Twin SSID warning** learned from past {SSID, gateway
  MAC} history, **keystroke-timing anomaly detection for the BadUSB
  keyboard guard**, **blast-radius evidence for Ransomware Canary
  detections**, and **JA3 TLS-fingerprint matching groundwork for Link
  Guard**.
- **Redesigned the log audit's frequency-spike detection to compare each
  template against its own history**, resolving repeated false positives
  from legitimate recurring jobs and `apt upgrade` bursts.
- **Fixed `upower.service`'s crash-restart loop** and **package-upgrade
  bursts** each being misreported as a log-audit anomaly.
- **Fixed Link Guard's NFQUEUE worker needlessly crashing and
  reinstalling its nftables table** on ordinary packet bursts.

### 1.4.1 - 1.8.0

- **Added Package CVE Scan**: matches installed OS packages (dpkg/pacman/
  dnf/zypper) and 7 language-ecosystem dependencies (npm/PyPI/crates.io,
  etc.) against a locally-held known-CVE map. No network activity at all
  (1.5.0).
- **Added Log Audit template anomaly detection + automatic secret
  masking**: flags previously-unseen patterns and frequency spikes
  (Z-score), and masks API keys etc. in log lines across both the
  clipboard-copy path and the raw JSON an MCP client receives (1.6.0).
- **Exposed incident history for the three guards behind an Air-Gap
  trigger (eBPF Runtime Guard / Port Anomaly / Ransomware Canary) via
  MCP and the CLI**: trigger reasons are now queryable from outside the
  daemon process (1.7.0).
- **Added File Scan Guard, Docker risk detection, and container isolation
  posture auditing**; the secret/API-key leak scanner can now recursively
  scan a whole directory (1.4.1, 1.4.3).
- **Improved malware-detection notifications with a ClamAV second
  opinion**, lowering alert urgency on a false positive (1.8.0).
- **Important fixes**: an NFQUEUE queue jam that could take down network
  connectivity right after install (1.5.1), USB Zero-Trust leaving every
  non-storage device (mice, etc.) permanently unusable (1.5.3), known-CVE
  maps always reporting "not fetched" on their publish day (1.5.2), the
  RHEL/openSUSE package-CVE maps never actually publishing due to
  GitHub's file-size limit (1.5.2, 1.5.3), and `clamd` sitting resident
  using 1GB+ of RAM even when never used (1.5.4).

### 1.1.1 - 1.3.2

- **Server Edition configuration & documentation overhaul**: every setting the
  operations manual documents is now real and functional: a Docker-bypass
  protection toggle, an SSH-preservation toggle, an `isolate`/`freeze`/`alert_only`
  containment mode, a configurable eBPF socket path, and a new optional
  `guard.yaml` policy file for per-severity actions (with automatic escalation
  after a repeated incident and a safety timer that auto-restores an Air-Gap
  isolation if never acknowledged).
- **Event-driven File Integrity Monitoring**: tampering is now detected the
  instant a monitored file's write finishes, instead of waiting for the next
  periodic scan. Fedora/RHEL/openSUSE now get an automatic FIM baseline
  refresh after every package transaction, matching the existing Debian/Ubuntu hook.
- **Egress / C2 containment for servers**: a local malicious-IP blocklist and
  an optional DNS sinkhole (off by default, to avoid breaking servers that
  rely on internal DNS), plus ransomware canary decoys and permanent kernel
  hardening now running on Server Edition as well.
- **Tetragon sensor support**: the eBPF Runtime Guard can now use Cilium's
  Tetragon as an alternative to Falco (its native gRPC API, over a local UNIX
  socket only, no TLS, no new listening port) on both editions.
- **Safer autonomous containment**: a shared protected-process safety list
  (init, container runtimes, package managers, browsers, ...) now guards every
  place RoamSwitch can freeze or terminate a process, and per-process network
  isolation was corrected to target the process's real UID or container
  instead of a rule that could silently match nothing.
- **Client: safer Air-Gap recovery & adaptive detection**: the "release"
  action now terminates the offending process (when known) before lifting an
  Air-Gap isolation, instead of only lifting the network block. eBPF detection
  sensitivity now automatically tightens on an untrusted network and relaxes
  back on a trusted one.
- **Diagnostics and notifications cleanup**: shortened the "CVE-2026-53362"
  reference in the security health check to just "Frag Gap" for readability,
  and stopped showing a "protection profile switched" notification the moment
  the daemon settles into an already-known network right after startup.

### 1.1.0

- **Official Release of RoamSwitch Server Edition**:
  - Falco eBPF runtime threat detection and automatic container/process isolation via UNIX domain socket (`/var/run/roamswitch/events.sock`).
  - Critical Path File Integrity Monitoring (FIM with SHA-256 baseline) and automatic recovery.
  - 25-item server security health check (kernel parameters, Docker privileged containers/exposed socket, eBPF LSM, SYN cookies, empty password accounts, etc.).
  - Webhook (Slack, Discord, Microsoft Teams, Generic) and PagerDuty alert integrations.
- **MCP Server (`roamswitch-mcp`) Server Edition Support**:
  - Added optional `isServer: true` argument to `get_security_report` tool, enabling Claude and AI agents to query the 25-item server security posture.
- **SDK (`roamswitchkit` / Python `roamswitch`) Server Health Methods**:
  - Rust SDK: Added `client.server_security_report().await?`.
  - Python SDK: Added `client.server_security_report()` and `is_server` option in `client.security_report(is_server=True)`.
- **Extended CLI Server Management**:
  - Added `roamswitch status --server`, `roamswitch server [config|setup|test-notify|restart]`, `roamswitch fim [verify|update]`, and `roamswitch emergency-restore` commands.

### 1.0.31 - 1.0.66

- **Streamlined update UX**: a manual "check for updates" button with a
  progress spinner, a single status card for updates, an upgrade button
  shown only when a newer version is actually available, and the app
  restarting itself automatically after a package upgrade.
- **Native multi-distribution package manager support**: Fedora/RHEL
  (`dnf`), openSUSE (`zypper`), and Arch Linux (`pacman`/AUR) upgrade
  instructions now appear natively alongside Debian/Ubuntu (`apt`),
  across all 10 languages.
- **Strict Daemon IPC Authentication & Quarantine Vault Hardening**: kernel-level peer credential validation (`SO_PEERCRED`), symlink traversal prevention, canonical path validation against privilege escalation / arbitrary deletion, and WireGuard argument sanitization.
- **Diagnostic Calibration & SBC / Raspberry Pi Optimization**: enforced unattended security upgrade checks, recognized non-UEFI SBC architectures without false negatives, and expanded SSH split configuration analysis.
- **Fully Asynchronous UI Threading**: GNOME / KDE / XFCE / Wayland desktop
  integration, and hardware radio restoration & Air-Gap resilience.
- **Overhauled ARP Spoofing Detection and Mitigation**: combined spatial
  and temporal difference detection, prevented latching of unverified
  gateway MACs, and added per-item "Fix" buttons in the Security Audit tab.

### 1.0.1 - 1.0.30

- **Core defense capabilities**: VPN tunnels (WireGuard/Tailscale) with a
  killswitch, Port Anomaly Guard (auto-blocking unknown listening ports),
  passive link protection, daily threat feed updater, BadUSB keyboard /
  USB storage authorization dialogs, and automatic sharing-service
  control (SSH, Samba).
- **Refined detection thresholds**: calibrated ransomware entropy
  thresholds (20 files in 5s with entropy >= 7.92), and proactive gateway
  ARP pinning.
- **UI and desktop integration**: fully asynchronous UI threading,
  dynamic taskbar/tray icon updates, and Tailscale/WireGuard hardening.
- **Setup and distribution**: initial setup wizard and official signed
  repositories for apt, dnf, and zypper.

### 1.0.0

- Initial Linux release. Ported RoamSwitch zero-trust networking architecture to Linux (systemd + nftables), featuring autonomous network profile switching, ransomware behavior detection, emergency Air-Gap isolation, 20-item health audits, and embedded read-only MCP server.

---

## RoamSwitch for Mac

## 1.9.29

- **Added: sandboxed npm/pnpm install (roamswitch-npm, Pro).** Adds a
  command-line wrapper, `roamswitch-npm`, that confines the execution of
  preinstall/install/postinstall/prepare scripts inside a network-denied
  sandbox (`sandbox-exec`, Seatbelt). Where the previous three features
  only detected and warned, this one actually runs the install on your
  behalf. The Linux edition uses bwrap for filesystem restriction, but
  since macOS has no equivalent technology, this uses network blocking
  instead, verified to actually work on real hardware
  (`(allow default)` + `(deny network-outbound)`). Install the wrapper
  from "📦 Package CVE Scan" → "Sandboxed Install (npm/pnpm) (Pro)", with
  an optional shell alias for `npm`/`pnpm`. Supports npm/pnpm; yarn is
  not supported. Since the Mac edition has no CLI binary, this ships as a
  lightweight command-line tool placed at
  `~/Library/Application Support/RoamSwitch/bin/`.

## 1.9.28

- **Added: three features addressing npm-install supply-chain risk (Pro).**
  "Dependency Lockfile Tamper Monitoring" continuously watches
  package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json for
  external tampering via a SHA-256 baseline. "Install Script Inventory"
  statically lists preinstall/install/postinstall/prepare scripts declared
  by package.json files under node_modules — an inventory rather than a
  threat verdict, and nothing is ever executed. "npm Signature / Provenance
  Verification" contacts the npm registry to verify installed packages'
  signatures/provenance (opt-in, with a per-run confirmation) — the only
  RoamSwitch feature that talks to npmjs.com. All three are available from
  the "📦 Package CVE Scan" window.

## 1.9.27

- **Added: detection of leaked crypto-wallet seed phrases and private keys
  (BIP39/WIF/BIP32).** The secret-leak auditor only recognized API keys and
  SSH private keys, with no detection at all for wallet recovery material —
  a gap prompted by Microsoft's June 2026 report on "Crypto Clipper"
  malware, which steals seed phrases and private keys via clipboard
  monitoring and swaps in attacker-controlled payout addresses. BIP39
  mnemonics (12/15/18/21/24 words) are verified against their actual
  SHA-256-based checksum rather than matched as a plain word list, so
  ordinary prose that happens to contain BIP39 words doesn't false-positive
  unless the checksum genuinely validates. Bitcoin WIF private keys and
  BIP32 extended private keys (xprv/yprv/zprv/tprv) are detected with
  Base58Check checksum verification. Unlike an API key, a detected value is
  fully hidden rather than partially masked — showing even part of it would
  hand an attacker a head start on brute-forcing the rest. Uses the same
  algorithm and verified test vectors as the Linux edition.

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

## 1.9.0 - 1.9.5

- **Added Active Vulnerability Scan and Package CVE Scan** (ported from
  the Linux edition, off by default).
- **Closed gaps in the MCP server**: secret-leak scanning, log auditing,
  quarantine listing, canary status, and Air-Gap-trigger incident history
  are all reachable via MCP now.
- **Added an Evil-Twin SSID warning**, **keystroke-timing anomaly
  detection for Bad USB**, and **JA3 TLS-fingerprint matching groundwork
  for Link Guard**.
- **Improved the Download Guard's static-signature detection with a
  ClamAV second opinion**.
- **Fixed repeated false Air-Gap re-triggers right after a Ransomware
  Canary release**, even with no decoy file actually tampered with.
- **Important: fixed a bug that could crash the MCP server under certain
  conditions**: the localized-string cache wasn't safe for concurrent
  access.

## 1.8.4 - 1.8.9

- **Added static-signature detection for downloads, ClickFix protection
  (off by default), and a Docker risk detection guard (off by default)**:
  EICAR/reverse-shell one-liner detection, an emergency lockdown on
  suspicious Terminal commands, and container-escape configuration alerts.
- **Added automatic Air-Gap isolation tied to Apple XProtect detections**
  (Pro, on by default). Redesigned the air-gap failsafe as a fully
  independent watchdog daemon so its lockdown deadline lifts reliably even
  if the helper process crashes.
  *(Special thanks to [Super Funicular](https://dev.to/superfunicular) for raising the edge-case inquiry during our discussion on [Dev.to](https://dev.to/superfunicular/turn-an-old-android-phone-into-a-screen-off-security-camera-no-cloud-lan-only-5cll).)*
- **The secret/API-key leak auditor can now scan a whole folder**.
- **Link Guard's "warn" mode now fails closed**, with a shorter hold
  window (25s -> 8s); hardened the privileged helper's code-signature
  verification and pre-execution checks for external binaries.
- **Isolated local port audit probes with ephemeral, sandboxed cookie
  storage**, preventing credential leakage and session contamination.
- Several minor fixes in this span too: dialog rendering glitches, 92
  missing translations, and a helper version-sync bug.

## 1.8.0 - 1.8.3

- **Topmost Emergency Alert Overlays**: threat confirmation dialogs (BadUSB, ransomware, ARP spoofing, link hold) display as topmost overlays across all macOS spaces and full-screen apps.
- **Direct Health Audit Remediation**: added per-item remediation buttons to immediately enable internal guards or open relevant macOS System Settings panes with automatic re-evaluation.
- **Malware Scanner False-Positive Mitigation**: benign EICAR test strings trigger informational notices rather than quarantine (matching Linux behavior).
- **Enhanced Link Guard via Content Filter**: outbound connection inspection post-DNS (blocking phishing across DoH/DoT and TLS SNI) and interactive foreground warning panels with safe defaults.
- **Dual VPN Backend Support**: added Tailscale Exit Node integration alongside WireGuard tunnels.

## 1.6.0 - 1.7.6

- **Integrated VPN Killswitch**: automatic WireGuard tunnels with packet-level killswitch enforcement on untrusted networks.
- **Proactive Gateway ARP/NDP Pinning**: hardens local neighbor tables on untrusted networks to prevent MITM attacks before they happen.
- **BadUSB Physical Keyboard Guard** and **non-destructive USB storage prompts** (mount unapproved drives read-only, with granular choices).
- **Passive Link Guard**: real-time outbound filtering against phishing and scam domains.
- **Canary baseline persistence** (decoy file hashes saved to disk for strict tamper detection) and **Quarantine Vault hardening** (`chmod 000` on quarantined files).

## 1.4.0 - 1.5.9

- **Local AI / LLM server protection**: automated exposure detection and blocking for Ollama, LM Studio, Gradio, and vLLM on `0.0.0.0`.
- **Clipboard secret protection**: real-time on-device regex scanning for exposed API keys and private keys.
- **Open Source MCP Server**: released a read-only MCP server and heuristics on GitHub.
- **Web & Mail triple protection**, **privileged helper hardening**, and **a crash watchdog** with autonomous auto-recovery.

## 1.0.0 - 1.3.0

- **Initial Releases**: autonomous network environment detection by gateway MAC, automatic firewall/sharing service profile switching, port anomaly blocking, ARP spoof auto-containment, and foundational MCP integration.
