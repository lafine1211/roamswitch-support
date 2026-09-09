# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.7.0

- **New: incident history for the three guards behind an Air-Gap trigger,
  exposed via MCP and the CLI**. Investigating why an Air-Gap (emergency
  network isolation) fired used to be impossible from a separate process —
  the actual trigger reason for all three guards capable of causing one
  lived only in daemon memory:
  - **eBPF Runtime Guard** (Server Edition): new `get_ebpf_incidents` MCP
    tool and `roamswitch server ebpf` CLI command report the current
    containment status (isolation mode, isolated PIDs, maintenance ports
    kept reachable) and up to the 50 most recent containment decisions
    (trigger rule, process, action taken), now persisted to
    `/var/lib/roamswitch/{ebpf_status,ebpf_incidents}.json`.
  - **Port Anomaly Guard**: new `get_port_anomaly_incidents` MCP tool and
    `roamswitch port-anomaly` CLI command report baseline status,
    currently auto-isolated ports, and up to the 50 most recent detected
    incidents (previously-unseen executables that started listening on an
    externally-exposed port), now persisted to the existing
    `/var/lib/roamswitch/port_guard.json`.
  - **Ransomware Canary**: fixed `get_canary_status`'s `recent_incidents`,
    which had always come back empty (the MCP handler recreated the
    detection engine from scratch on every call, discarding its
    in-memory incident log) — it's now backed by a persisted
    `/var/lib/roamswitch/canary_incidents.json` and reflects real
    detections. `roamswitch canary` (unchanged code) automatically
    benefits from the same fix.
  - This closes a real gap for local-LLM/MCP-based offline triage during a
    network cutoff: previously none of these three primary trigger
    reasons were queryable from outside the daemon process.
- **SDK**: added `get_port_anomaly_incidents()` / `get_ebpf_incidents()` to
  both `roamswitchkit` (in-tree) and the public `roamswitch-linux-kit`
  crate; `canary_status()` automatically returns real incident data now
  that the underlying bug is fixed.
- **Fixed**: the CLI's own `--help` footer and the `roamswitch(1)` man
  page's `SEE ALSO` section pointed at a nonexistent headless-ops guide URL
  (a file that never existed, in the wrong repository). Both now point to
  <https://lafine.net/linux-cli.html>.
- **Docs**: the `roamswitch(1)` man page was missing several subcommands
  that already existed in the CLI (`server` and all its subcommands,
  `fim`, `emergency-restore`, `scan-vulns`, `scan-packages`) — added, along
  with the server-side files (`server.conf`, `fim_baseline.db`, the new
  incident-history JSON files) they read or write.

### 1.6.0

- **New: Log Audit anomaly detection & automatic secret masking**.
  `roamswitch audit-logs` and the `audit_security_logs` MCP tool now group
  log messages into templates (masking IPs, hex/hash tokens, and numbers)
  to flag two kinds of anomaly: a pattern never seen before on this host,
  and a frequency spike (Z-score > 3.0) within the scanned window. The
  known-template baseline is persisted at
  `~/.config/roamswitch/log_template_baseline.json` (template identities
  only, no time-series data).
  - **Security fix**: any API key, token, or private-key header that
    happened to appear in a log line is now scrubbed before it can reach
    the GUI, the "copy for AI consultation" clipboard text, or — more
    importantly — the raw JSON an MCP client (e.g. an AI agent) receives.
    Previously only the composed AI-consultation prompt was masked; the
    underlying event data handed to MCP callers was not.
  - The "copy for AI consultation" prompt is now hardcoded in English
    (previously Japanese), since it's meant to be pasted into an external
    AI chat and should stay independent of the app's own display language.
- **New: Server Edition Log Audit notifications**. A lightweight periodic
  `journalctl` scan (`log_audit_enabled`, default on;
  `log_audit_interval_secs`, default 1800s) dispatches a
  Telegram/LINE/Webhook alert through the same channels as File Scan Guard
  and FIM when a new pattern or frequency spike is detected.
- **New MCP tool: `verify_fim`**. Critical Path FIM verification (~150
  critical files) was previously CLI-only (`roamswitch fim verify`); it's
  now also reachable read-only via MCP and the Rust SDK, so AI agents and
  third-party tools can check file-integrity status without shelling out.
- **SDK: closed a gap where three existing MCP tools had no client
  wrapper**. Added `package_cve_scan()`, `package_cve_scan_languages()`,
  and `verify_fim()` to both `roamswitchkit` (in-tree) and the public
  `roamswitch-linux-kit` crate — these tools already existed in
  `roamswitch-mcp`, but were unreachable outside of hand-rolled JSON-RPC
  calls.

### 1.5.4

- **Fixed `clamd` sitting resident using 1GB+ of RAM at all times even when
  never used, and made it opt-in**. Even if the ClamAV integration
  (clamdscan/clamscan) was never used, the package's `clamav-daemon`
  recommended dependency and the distro's own postinst unconditionally
  started the systemd service, so a plain install alone burned ~1.1GB of
  RAM continuously (verified live). Server Edition already had a proven fix
  for this (keep `clamd` masked+stopped while `clamav_enabled=false`, and
  self-heal it — run `freshclam`, unmask, start — the moment it flips to
  `true`); extracted that into a shared function and ported it to the
  desktop client too. The new `clamav_enabled` setting (default `true`,
  matching prior behavior) is now a checkbox in the GUI; turning it off
  stops `clamd` and frees its memory while the built-in YARA engine keeps
  running as the first line of defense. The toggle takes effect immediately
  with no restart needed. Note: the USB storage guard relies on ClamAV
  alone with no YARA fallback of its own, so disabling it means USB
  insertions go completely unscanned — a disclosed trade-off of turning
  this off, not a silent gap.

### 1.5.3

- **Important: fixed a bug where, with USB Zero-Trust enabled, newly
  connected USB devices other than keyboards (mice, etc.) could become
  permanently unusable**. Enabling `authorized_default=0` (USB Zero-Trust)
  makes every newly connected USB device come up kernel-unauthorized by
  default, but the guard's reconciliation loop only ever re-authorized USB
  hubs and allow-listed storage devices. Every other device class — mice,
  webcams, headsets, and so on — had no path to ever get authorized at
  all, so it simply stopped working the moment it was plugged in.
  Generalized the auto-authorize logic: everything except storage now gets
  authorized automatically (keyboards remain defended purely in software
  via `EVIOCGRAB` and are still never touched at the kernel-authorization
  level).
- **Fixed the RHEL known-CVE map, which had never actually been delivered
  even once**. The RHEL map reached ~130,000 package/CVE pairs, ~130MB as
  plain JSON — over GitHub's 100MB single-file limit — so every generation
  run's push had been silently failing. Switched to gzip delivery
  (~130MB → ~3.4MB): `roamswitch-updater` verifies the signature over the
  raw gzip bytes and only decompresses after verification, writing plain
  JSON to the install path as before. Also switched the map-generation
  pipeline's zstd extraction to a streaming approach that never writes the
  decompressed tarball to disk, fixing a silent, logless crash caused by
  GitHub Actions runners running out of disk space. This is the first
  release where RHEL, CentOS Stream, AlmaLinux, and Rocky Linux actually
  receive real package-CVE data.

### 1.5.2

- **Important: fixed known-CVE maps (Package CVE Scan, Active Vulnerability
  Scan) always reporting "not fetched" on their publish day**. The embedded
  seed's version string used a "`<date>-seed`" format; compared
  lexicographically against a published feed's date-only version, the seed
  would incorrectly win on the exact day it was published. Changed the seed
  version to an empty string so real data always wins, regardless of the
  date.
- **Fixed dependency package CVE scanning (npm/PyPI/crates.io, etc.)
  reporting "no vulnerabilities found" when the CVE data simply hadn't been
  fetched yet**: now correctly distinguishes "no data yet" from "clean",
  matching the OS-package tab's existing behavior.
- **Fixed a misleading "Delete" label on watched folders**: the button only
  removes a folder from RoamSwitch's watch list — it never deletes the
  folder itself. Relabeled to "Remove from list" (Package CVE Scan and
  malware-scan watched-folder tabs).
- **Fixed the openSUSE package-CVE map never successfully publishing**: map
  generation linked every package to every CVE within a single patch
  definition unconditionally, so large kernel/browser-engine patches with
  many sub-packages and CVEs exploded combinatorially into a 226MB file —
  exceeding GitHub's 100MB single-file limit and silently failing every
  publish attempt. Now skips linking when a patch definition's
  package×CVE fan-out is too large to trust, rather than publishing
  possibly-wrong associations.

### 1.5.1

- **Important: fixed a bug that could take down network connectivity right
  after install**. Link Guard (the phishing-protection feature that
  inspects HTTP/HTTPS/DNS traffic) queued *every* packet of *every*
  established connection to a single-threaded NFQUEUE consumer with no
  bound, forever. Under real traffic (page loads, video, downloads) that
  consumer could fall behind and jam the queue, causing lost connectivity
  or a guard crash. Fixed by capping queuing to the first few packets of
  each connection (enough to read the TLS SNI / HTTP Host) via a kernel-side
  `ct original packets` filter. Also moved the threat feed (840k+ domains)
  reload off the packet-processing thread onto a dedicated one, and made
  the queue loop self-heal (auto-restart) if it ever exits unexpectedly.
- **Made the 3-second USB Zero-Trust reconciliation idempotent**: it now
  skips the sysfs writes and log line entirely when the desired state
  already matches, instead of re-applying and re-logging on every tick.

### 1.5.0

- **New: Package CVE Scan**. Checks installed OS packages and your
  project's dependencies against a locally-held known-CVE map. No network
  activity at all (the embedded baseline ships deliberately empty; nothing
  is detected until `roamswitch-updater`'s daily fetch installs real data).
  - **OS packages**: auto-detects `dpkg` (Debian/Ubuntu), `pacman` (Arch
    Linux), `dnf` (RHEL, CentOS Stream, AlmaLinux, Rocky Linux — not
    Fedora, which Red Hat's own security data doesn't track), and `zypper`
    (openSUSE Leap — not SLES, whose feed requires a paid subscription).
  - **7 language ecosystems** (developer opt-in): parses dependency
    lockfiles for npm, PyPI, crates.io, RubyGems, Packagist, Go, and Maven
    (package-lock.json, requirements.txt, Pipfile.lock, poetry.lock,
    Cargo.lock, Gemfile.lock, composer.lock, go.sum, pom.xml) in project
    folders you specify.
  - CLI: `roamswitch scan-packages [FOLDER...]`. MCP tools:
    `run_package_cve_scan` and `run_package_cve_scan_languages`. New
    "📦 Package CVE Scan" tab in the GTK GUI.
  - If CVE data hasn't been fetched yet, running a scan now also kicks off
    a background fetch attempt, instead of waiting for the next scan or
    the next scheduled daily update.
- **Fixed a bug in the built-in help (`get_app_help`)**: filtering by
  `topic: "setting"` always returned nothing, since no matching content
  existed. Added a real settings guide sourced from actual config.json
  fields, plus a new matching MCP resource,
  `roamswitch://docs/settings-guide`.

### 1.4.3

- **Secret/API-key leak scanner: folder scanning added to the desktop GUI**:
  the GTK "Secret & API Key Leak Auditor" tab (previously text/clipboard
  only) now has a "Choose Folder to Scan" button, matching the CLI/MCP/SDK
  capability added below.
- **Docker firewall-bypass (`DOCKER-USER`) protection fixed and ported to the
  desktop client**: Server Edition's protection had no actual deny rule and
  matched the wrong (post-NAT) port, so it silently blocked nothing. Fixed
  with an interface-scoped deny rule and pre-NAT port matching, and the same
  protection now also runs on the desktop client (previously Server Edition
  only). Added as a new item to the security health check (now 28 items on
  Server Edition, was 27).
- **Real-time detection of risky Docker containers**: a new notify-only guard
  watches `docker events` and flags the instant a container starts with
  `--privileged` or a `/var/run/docker.sock` bind-mount — a container-escape
  risk. Runs on both the desktop client and Server Edition; no automatic
  blocking, since this flags a risky *configuration*, not confirmed
  compromise.
- **New File Scan Guard for Server Edition** (opt-in): the embedded YARA
  engine always scans configured directories (mail spool, file share, upload
  directory) with no external dependency; enabling `clamav_enabled` adds a
  ClamAV second opinion. Confirmed threats are quarantined and the operator
  is notified. Configurable via `roamswitch server config`, the interactive
  `roamswitch server setup` wizard, or the new `get_file_scan_guard_status`
  MCP tool. Fixed a sandboxing bug found while building this feature's
  regression test: the systemd service's `ProtectSystem=strict` didn't grant
  write access to ClamAV's own directories, so `freshclam`/`clamdscan`
  silently failed when launched by the daemon.
- **Secret/API-key leak scanner can now scan a whole directory**:
  `roamswitch audit-secrets <directory>` recursively scans a folder (e.g. a
  git checkout), skipping `.git`/`node_modules`/`target`/`vendor`/`dist`/
  `build`/`__pycache__`/`venv` and any file over 2MB or that looks binary.
  The same capability is now available to AI agents via the `audit_secrets`
  MCP tool's new `path` parameter, and to Python SDK users via
  `audit_secrets_directory()` — all running locally, with content never
  transmitted anywhere.
- **`get_quarantine_status` MCP tool now supports Server Edition**: a new
  `isServer` parameter reads the Server Edition quarantine vault
  (`/var/lib/roamswitch/quarantine`) instead of always assuming the desktop
  client's per-user vault.
- **Fixed: Docker risk notifications ignored the language setting** — they
  were always shown in Japanese regardless of the configured UI language.
  Desktop notifications are now fully localized (all 10 supported
  languages); Server Edition notifications follow its Japanese/English-only
  policy.
- **Fixed a dialog rendering bug**: on some display setups, a security alert
  dialog could leave a solid black window behind it that didn't disappear
  when closed.

### 1.4.1

- **Added container isolation posture auditing**: Docker socket-mount exposure
  and privileged-container checks now also run on the desktop client (previously
  Server Edition only). Detects the active container runtime (`runc` / gVisor /
  Kata Containers) to surface the container-escape risk of sharing the host
  kernel, on both editions. Added a known-kernel-CVE exposure check (on by
  default on the client; on Server Edition it follows the opt-in below).
- **Server Edition: explicit opt-in for CVE data updates**: the default
  zero-network-code posture is unchanged — only if the operator explicitly
  enables `cve_kernel_map_updates_enabled` (default false) does the one
  exception kick in: a daily anonymous fetch of the container-isolation kernel
  CVE database from lafine.net (no query string, cookies, or identifying
  headers; signature-verified). Toggle and inspect it via `roamswitch server
  config` or the `roamswitch server setup` interactive wizard.
- **Fixed a ransomware-freeze notification bug**: when a short-lived process
  exited before the burst detector finished evaluating it, the notification
  showed a confusing placeholder instead of the process name. The name is now
  snapshotted the moment the write is first observed, and an honest "unknown"
  is shown when it genuinely can't be determined.

### 1.1.1 - 1.3.2

- **Server Edition configuration & documentation overhaul**: every setting the
  operations manual documents is now real and functional — a Docker-bypass
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
  socket only — no TLS, no new listening port) on both editions.
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

### 1.0.63 - 1.0.66

- **Streamlined update UX**: added a manual "🔍 Check for updates" button with
  a progress spinner, consolidated the app-upgrade and threat-feed-update
  status into a single "Automatic Update Status" card that only surfaces an
  "⬆️ Upgrade now" prompt when a newer version is actually available, and the
  app now restarts itself automatically after a package upgrade.
- **Native multi-distribution package manager support**: Fedora/RHEL (`dnf`),
  openSUSE (`zypper`), and Arch Linux (`pacman` / AUR) upgrade instructions
  now appear natively alongside Debian/Ubuntu (`apt`), fully localized across
  all 10 languages with update-check timestamps.

### 1.0.50 - 1.0.62

- **Strict Daemon IPC Authentication & Quarantine Vault Hardening**: Implemented kernel-level peer credential validation (`SO_PEERCRED`), symlink traversal prevention, canonical path validation against privilege escalation / arbitrary deletion, and WireGuard argument sanitization.
- **Diagnostic Calibration & SBC / Raspberry Pi Optimization**: Enforced unattended security upgrade checks (`unattended-upgrades` / `dnf-automatic`), recognized non-UEFI SBC architectures without false negatives, improved `/tmp` and `/dev/shm` noexec verification, and expanded SSH split configuration analysis (`/etc/ssh/sshd_config.d/`).
- **UI Refresh & Streamlined Upgrades**: Replaced multi-button layouts with compact dropdowns (`ComboBoxText`) for languages and DNS profiles, broadened main window to 1100px, and unified update checks and installation under a single "Upgrade" view.
- **Hardware Radio Restoration & Air-Gap Resilience**: Strengthened physical radio restoration pipelines (rfkill, NetworkManager, BlueZ), enriched Air-Gap incident context and remediation options, automated recovery following ARP spoofing cessation, and reduced UI latency during lockdowns.

### 1.0.41 - 1.0.49

- **Overhauled ARP Spoofing Detection and Mitigation**: Introduced combined spatial and temporal difference detection, ensured sticky Air-Gap release during ongoing attacks, prevented latching of unverified gateway MACs, and added one-click block confirmation dialogs on balanced/trusted networks.
- **Individual Hardening and Accurate Health Checks**: Added per-item "Fix" buttons in the Security Audit tab, refined audit criteria to recognize intentional trusted-network behaviors (noexec / ARP pinning), and verified active fanotify runtime status.
- **UI and IPC Responsiveness**: Ensured security alert dialogs always appear on top and decoupled daemon IPC operations from the GTK main thread.

### 1.0.31 - 1.0.40

- **Enhanced Passive Link Guard**: Switched warning mode to fail-closed, shortened hold times to 8 seconds, and deduplicated notifications.
- **Malware and Ransomware False-Positive Prevention**: Exempted package managers (apt, dpkg, rpm), browser caches, and benign EICAR test strings from quarantine/blocking; added custom scan exclusion paths.
- **VPN / Tailscale Optimization**: Optimized Tailscale Exit Node sequencing and killswitch rules; refined layout margins and dropdown widths.
- **Expanded Localization**: Full translation coverage across all 10 supported languages (ja, en, zh-Hans, zh-Hant, ko, de, fr, es, it, pt).

### 1.0.21 - 1.0.30

- **Fully Asynchronous UI Threading**: Eliminated window freezing during profile switching and VPN connections.
- **Desktop Environment Integration**: Dynamic taskbar and system tray icon updates across GNOME, KDE, XFCE, and Wayland environments.
- **Tailscale and WireGuard Hardening**: Auto-detection of snap-installed Tailscale, argument resolution fallbacks, and streamlined VPN configuration UI.

### 1.0.11 - 1.0.20

- **VPN Tunnels and Killswitch**: Introduced automatic WireGuard and Tailscale Exit Node tunnels with packet-level killswitches on untrusted networks.
- **Refined Detection Thresholds**: Calibrated ransomware entropy thresholds (20 files in 5s with entropy >= 7.92), resolved Raspberry Pi OS packaging dependencies, and introduced proactive gateway ARP pinning.

### 1.0.1 - 1.0.10

- **Core Defense Capabilities**: Added Port Anomaly Guard (auto-blocking unknown listening ports), passive link protection, daily threat feed updater, BadUSB keyboard / USB storage authorization dialogs, and automatic sharing services control (SSH, Samba).
- **Setup and Distribution**: Introduced initial setup wizard and official signed repositories for apt, dnf, and zypper.

### 1.0.0

- Initial Linux release. Ported RoamSwitch zero-trust networking architecture to Linux (systemd + nftables), featuring autonomous network profile switching, ransomware behavior detection, emergency Air-Gap isolation, 20-item health audits, and embedded read-only MCP server.

---

## RoamSwitch for Mac

## 1.9.4

- **Fixed: releasing an Air-Gap isolation triggered by Ransomware Canary
  protection could repeatedly re-trigger false detections — and repeated
  network cutoffs — even though no decoy file had actually been tampered
  with**: depending on timing, the release-time self-heal (regenerating
  decoy files, then rebuilding the real-time file watchers) could itself
  produce a spurious detection event for a file that was never actually
  modified. Detections occurring in a brief grace window right after the
  watchers are rebuilt are now ignored, breaking this false-positive loop.

## 1.9.3

- **New: incident history for the three guards behind an Air-Gap trigger,
  exposed via MCP**: investigating why an Air-Gap (emergency network
  isolation) fired was previously impossible from the separate MCP server
  process — the actual trigger reason for all three guards capable of
  causing one lived only in the main app process's memory.
  `get_canary_status` now includes `recentIncidents`; two new MCP tools,
  `get_port_anomaly_incidents` and `get_runtime_threat_status`, were added;
  `get_guard_status`'s guard list now includes `runtimeThreatContainment`.
  Each incident is persisted to the app's shared UserDefaults, so the MCP
  server can report recent detections on its own without going through the
  main app.
- **Fixed a bug found while building the above: the Runtime Threat
  Containment simulation path could leave the detected incident's detail
  (`lastIncident`) missing from the MCP response**: the real
  XProtect-detection path recorded incident details before triggering
  containment, but the built-in "simulation" test path (used to safely
  exercise the Air-Gap flow) skipped that step, so the containment date was
  recorded but the incident detail wasn't. Fixed so every trigger path
  records incident details consistently.

## 1.9.2

- **Important: fixed secret masking not being applied to the "Copy AI
  Consultation Material" text and the log audit's MCP response**: the "Mac
  Security Log Audit" feature already had a mechanism to detect and mask
  secrets (`SecretLeakScanning`), but neither the clipboard-copy path nor
  the JSON response returned by the MCP server actually used it. If a raw
  system log happened to contain something like an API key, it could be
  passed through unmasked when pasted into an external AI chat or consumed
  by an AI agent over MCP. Masking is now applied to every message the log
  audit extracts, consistently across both the clipboard copy and the MCP
  response.
- **Added template-based log anomaly detection**: in addition to the
  existing 6 hardcoded categories (sudo/ssh/gatekeeper/xprotect, etc.), the
  "Mac Security Log Audit" now templatizes log messages and detects
  frequency spikes and previously-unseen patterns (ported from the
  already-shipped Linux edition). Surfaced in the KPI card, the
  AI-consultation text, and the MCP response (`templateAnomalies`).
- **Added an audit `timestamp` to the MCP `get_security_report` response.**
- **Fixed a Bad USB guard bug where an external keyboard already connected
  at the moment the guard was enabled wasn't added to the allowlist**: with
  an external keyboard plugged in, enabling the guard didn't auto-approve
  it — it merely happened not to be blocked yet. The next time it was
  unplugged and replugged, it would be treated as an unapproved device,
  triggering the approval dialog and briefly blocking keystrokes even
  though it was the user's own everyday keyboard. Fixed by auto-registering
  all currently-connected keyboards to the allowlist the moment the guard
  is enabled.
- **Fixed the "Mac Security Log Audit" window freezing when the "All"
  category filter was selected on a day with a large number of events**:
  capped the number of rendered rows and made the localization lookup used
  by each row far cheaper.

## 1.9.1

- **Important: fixed known-CVE maps (Package CVE Scan, Active Vulnerability
  Scan) always reporting "not fetched" on their publish day** (paired with
  the Linux 1.5.2 fix). The embedded seed's version string used a
  "`<date>-seed`" format; compared lexicographically against a published
  feed's date-only version, the seed would incorrectly win on the exact day
  it was published. Changed the seed version to an empty string so real
  data always wins, regardless of the date.
- **Fixed raw Markdown (headings, bold, code spans) showing up in the
  Package CVE Scan findings table's summary column**: now stripped to
  plain text for display.

## 1.9.0

- **New: Active Vulnerability Scan (off by default)**. Ported from the
  Linux edition. For a service found listening on `127.0.0.1` during a
  port scan, sends a single harmless, read-only probe to confirm it's
  actually reachable without authentication — not just "the port is
  open." Covers Redis, Memcached, MongoDB, and dockerd (services that are
  unauthenticated by default), plus CORS misconfiguration, path
  traversal, and open-redirect checks against arbitrary local dev
  servers. Redis (CVE-2022-24834 and 7 others) and Memcached
  (CVE-2018-1000115) are additionally checked against known-CVE version
  ranges using only a harmless version-query command — no exploit payload
  is ever sent. Opt in from the menu bar's Ports submenu, then run it
  manually from the port detail sheet. The known-CVE map updates via the
  same daily, receive-only, signature-verified feed as the ransomware
  kernel-CVE map.
- **New: Package CVE Scan**. Same design as the Linux edition, ported to
  macOS. Checks installed Homebrew packages and dependency lockfiles for
  npm, PyPI, crates.io, RubyGems, Packagist, Go, and Maven against a
  locally-held known-CVE map. No network activity at all; if the data
  hasn't been fetched yet, running a scan now also kicks off a background
  fetch attempt.
- **Closed 4 gaps in the MCP server**. The AI-agent-facing MCP server now
  exposes secret/API-key leak scanning (`audit_secrets`), security-log
  auditing (`audit_security_logs`), quarantined-file listing
  (`get_quarantine_status`), and ransomware-canary monitoring status
  (`get_canary_status`) — all of which already existed in the desktop
  GUI. Also fixed the MCP server always reporting its version as
  "1.0.0", and fixed responses always coming back in Japanese regardless
  of the language selected in the app.
- **Fixed 2 Pro default-value inconsistencies**. The ransomware
  canary-file guard, unlike the app's other auto-containment guards,
  didn't persist an explicit OFF choice across restarts — it's now
  consistent with the others, and can be toggled from the menu bar (there
  was previously no way to change it at all). Separately, ARP-spoofing
  containment and XProtect-triggered auto-containment could kick in
  without warning the first time Pro was enabled; a one-time notification
  now explains what happened and how to undo it.
- **Filled in gaps in Help & Guide**. Added entries for Package CVE Scan,
  Active Vulnerability Scan, ClickFix protection, persistence monitoring,
  and XProtect-triggered auto-containment — all already implemented but
  missing from the in-app help.

### 1.8.9

- **New Docker risk detection guard (Pro, off by default)**: detects the
  instant a container starts with `--privileged` or a `/var/run/docker.sock`
  bind-mount — a container-escape risk — and sends a notification. This
  flags a risky *configuration*, not confirmed compromise, so no automatic
  action is taken. Mirrors the equivalent guard on the Linux edition, using
  the same detection logic. Most users don't run Docker, which is why this
  stays opt-in even on Pro.
- **Secret/API-key leak auditor can now scan a whole folder**: previously
  limited to pasted text or the clipboard, the "Secret Leak Audit" window
  now has a "Choose Folder to Scan" option that recursively audits a
  directory (e.g. a source checkout), skipping `.git`/`node_modules`/
  `target`/`vendor`/`dist`/`build`/`__pycache__`/`venv` and any file over
  2MB or that looks binary. Runs entirely on-device, as before.
- **Fixed a dialog rendering bug**: on setups without an active compositor,
  a security alert dialog could leave a solid black window behind it that
  didn't disappear when closed.
- **Added an explainer dialog before folder-access prompts**: macOS's
  "would like to access files in your Desktop folder" prompt — triggered
  when Web & Mail Protection starts monitoring, or when scanning a folder
  in the Secret/API-key leak auditor — used to appear with no context,
  which could look suspicious. The app now shows a one-time explainer
  first, describing why and confirming scanning stays fully on-device
  (Zero Telemetry).
- **Fixed missing translations across the UI**: 92 menu items and dialog
  strings that were falling back to Japanese in non-Japanese locales now
  have translations in all 9 supported languages.

### 1.8.8

- **Fixed helper version sync**: the privileged helper method backing the
  1.8.7 sudo NOPASSWD audit could fail to take effect after upgrading an
  existing install, because the helper's own version string wasn't bumped
  alongside it. When this happened, the "Sudo Privilege Escalation Audit"
  item in the comprehensive security report stayed stuck on "not yet
  checked" (fresh installs were unaffected).

### 1.8.7

- **Static-signature detection for downloaded files**: without requiring the
  EndpointSecurity entitlement, a lightweight static signature layer now
  checks downloads for the industry-standard EICAR test string and a set of
  well-documented, publicly known reverse-shell one-liners (bash/sh
  `/dev/tcp/`, netcat `-e`, Python `pty.spawn`, Perl `Socket`, PHP
  `fsockopen`). Runs alongside ClamAV and keeps working even when ClamAV
  isn't installed.
- **New login-item persistence monitoring**: detects the moment a new
  LaunchAgent/LaunchDaemon plist is installed, and flags it when it invokes
  a raw script interpreter (`/bin/bash` and similar) directly — malicious
  content is usually hidden in the interpreter's arguments rather than in a
  signed executable, so a validly-signed interpreter alone isn't a clean
  bill of health.
- **Emergency lockdown on suspicious Terminal commands (off by default)**:
  targets "ClickFix" — the social-engineering technique where a fake
  warning page talks the user into pasting and running a command
  themselves. Watches shell history for known-bad patterns and triggers an
  emergency network air-gap on a match. A bare `curl | bash` (used by many
  legitimate installers) is deliberately not flagged on its own — only
  narrower combinations, like decoding base64 straight into a shell or
  AppleScript, are. Off by default given the disruption a false positive
  would cause.
- **Three additions to the comprehensive security report**: gateway ARP
  pinning status, an SSH Remote Login configuration audit (root login
  disabled, key-only auth), and a sudo NOPASSWD audit.

### 1.8.4 - 1.8.6

- **Air-gap failsafe redesigned to be safe**: A fix to make sure the air-gap's
  10-minute network-lockdown deadline lifts on its own even if the helper
  process crashes mid-lockdown. The first attempt (1.8.5) used
  `KeepAlive.PathState` in the privileged helper's own LaunchDaemon plist,
  which occasionally caused the app to restart itself after a normal Quit —
  that was reverted and replaced (1.8.6) with a fully independent watchdog
  daemon that never touches the interactive helper's own launch
  configuration. It wakes on its own every 3 minutes, checks whether the
  deadline has passed, and — if so — restores the network and exits, with no
  way to interfere with a normal app quit. The underlying timestamp check
  was also hardened to stay correct across NTP corrections, manual clock
  changes, and right after a reboot, by pairing a monotonic uptime counter
  with the wall clock.
  *(Special thanks to [Super Funicular](https://dev.to/superfunicular) for raising the edge-case inquiry during our discussion on [Dev.to](https://dev.to/superfunicular/turn-an-old-android-phone-into-a-screen-off-security-camera-no-cloud-lan-only-5cll).)*
- **Automatic Air-Gap isolation tied to Apple XProtect detections**: Without
  requiring the EndpointSecurity entitlement, RoamSwitch now triggers an
  emergency network air-gap the moment Apple's own XProtect engine logs an
  actual malware detection/remediation (Pro, on by default). A simulation
  menu item was also added to verify the behavior safely.
- **Manual secret/API-key leak audit tool**: Paste any text to instantly
  audit it for leaked API keys and tokens, with line numbers, masked values,
  and per-type remediation advice.
- **Link Guard "warn" mode now fails closed**: An unanswered warn prompt
  used to let the connection through (fail-open); it now matches the Linux
  client and blocks it instead (fail-closed, not cached, so the next attempt
  re-prompts). The hold window was also shortened from 25s to 8s.
- **Ephemeral Cookie Separation in Port Security Audits**:
  Isolated HTTP probing routines to use ephemeral, sandboxed cookie storage during local port audits. Prevents credential leakage and cross-service session contamination between audit probes and user web sessions.
- **Dynamic XPC Code Signature Verification (audit_token)**:
  Enforced strict runtime validation of Apple Developer ID code signatures via `audit_token` on all XPC connections to `RoamSwitchHelper`, preventing unauthorized or injected processes from dispatching privileged tasks.
- **Pre-execution Permission Verification & Configuration Sanitization**:
  Added comprehensive file permission and ownership checks prior to spawning external helper binaries, and strengthened WireGuard configuration sanitization against argument injection.

### 1.8.0 - 1.8.3

- **Topmost Emergency Alert Overlays**: Threat confirmation dialogs (BadUSB, ransomware, ARP spoofing, link hold) display as topmost overlays across all macOS spaces and full-screen apps.
- **Direct Health Audit Remediation**: Added per-item remediation buttons to immediately enable internal guards or open relevant macOS System Settings panes with automatic re-evaluation.
- **Malware Scanner False-Positive Mitigation**: Benign EICAR test strings trigger informational notices rather than quarantine (matching Linux behavior).
- **Enhanced Link Guard via Content Filter**: Outbound connection inspection post-DNS (blocking phishing across DoH/DoT and TLS SNI) and interactive foreground warning panels with safe defaults.
- **Dual VPN Backend Support**: Added Tailscale Exit Node integration alongside WireGuard tunnels.

### 1.7.0 - 1.7.6

- **Integrated VPN Killswitch:** Introduced automatic WireGuard tunnels with packet-level killswitch enforcement on untrusted networks.
- **Proactive Gateway ARP/NDP Pinning:** Hardens local neighbor tables on untrusted networks to prevent MITM attacks before they happen.
- **BadUSB Physical Keyboard Guard:** Detects unauthorized external keyboards and hardware inject tools, dropping keystrokes until authorized.
- **Passive Link Guard:** Real-time outbound filtering against phishing and scam domains using zero-telemetry heuristics.
- **Non-destructive USB Storage Prompts:** Mounts unapproved drives read-only while offering granular read/write or eject choices.

### 1.6.0 - 1.6.4

- **Canary Baseline Persistence:** Persisted decoy file hashes to disk for strict tamper detection and reliable self-healing.
- **Quarantine Vault Hardening:** Fully revoked execution and read permissions (`chmod 000`) on quarantined files.
- **Port Anomaly Guard Cleanups:** Automated migration for legacy executable records and notification deduplication.

### 1.5.0 - 1.5.9

- **Local AI / LLM Server Protection:** Automated exposure detection and blocking for Ollama, LM Studio, Gradio, and vLLM on `0.0.0.0`.
- **Clipboard Secret Protection:** Real-time on-device regex scanning for exposed API keys and private keys.
- **ClamAV Quarantine Enhancements:** Closed bypass paths for `.tmp` extensions and direct terminal downloads (`curl`/`cp`).
- **Crash Watchdog:** Autonomous LaunchAgent monitor with exponential backoff auto-recovery.

### 1.4.0 - 1.4.8

- **Open Source MCP Server:** Released read-only MCP server and heuristics on GitHub; introduced `get_app_help` knowledge base search.
- **Web & Mail Triple Protection:** Implemented automated download scanning, DNS threat protection, and link safety diagnostics.
- **Privileged Helper Hardening:** Enforced `audit_token` validation and Team ID pinning against PID reuse attacks.

### 1.0.0 - 1.3.0

- **Initial Releases:** Autonomous network environment detection by gateway MAC, automatic firewall/sharing service profile switching, port anomaly blocking, ARP spoof auto-containment, and foundational MCP integration.
