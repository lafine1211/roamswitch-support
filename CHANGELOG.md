# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (a separate 1.0.x series) are versioned
independently.

---

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.0.57

- **Unified Physical Radio (Wi-Fi & Bluetooth) Terminology and One-Click Restoration**:
  Standardized terminology across the UI and documentation to "Physical Radio (Wi-Fi & Bluetooth) Kill / Restore". Added dedicated one-click "Restore Radios (Wi-Fi & Bluetooth)" controls across the Dashboard, Emergency Air-Gap Dialog, Networks tab, and System Tray menu for instant recovery from hardware radio kill. Added clear desktop notifications when toggling hardware radios on and off.
- **Exhaustive 10-Language Localization Verification**:
  Completed a comprehensive localization audit across all 10 supported languages (ja, en, zh-Hans, zh-Hant, ko, de, fr, es, it, pt), ensuring full translation coverage for incident details (spoofed IP, attacker MAC, legitimate router MAC, target file, suspicious process) and all tray/dialog/window elements.

### 1.0.56

- **Expanded Situational Context, Decision Guidance, and Quick Actions during Air-Gap**:
  The emergency alert dialog and Networks tab now display concrete incident details, including spoofed IP/MAC addresses for ARP spoofing or altered path/process name/PID for canary file integrity violations. Packet-level isolation (nftables) and data leak prevention guarantees are explicitly communicated, alongside contextual decision guidance (risks of Man-in-the-Middle on public Wi-Fi vs legitimate router changes on home/office networks). Added four quick-action options: "Disconnect Wi-Fi", "View Detailed Logs", "Close (Keep Blocked)", and "Release Air-Gap".
- **Enhanced Connectivity Recovery After Releasing Air-Gap**:
  Automatically triggers NetworkManager connectivity checks and flushes local DNS caches upon Air-Gap release, instantly clearing the question mark ("?") icon on desktop taskbars. Instantly dismisses the emergency alert modal upon releasing Air-Gap.
- **System Tray Menu (ksni / DBusMenu) Stability Fix**:
  Vendored and patched the `ksni` crate to eliminate potential out-of-bounds `id2index` panic crashes during dynamic menu rebuilds.
- **Localization**:
  All new dialogs and actions fully localized across 10 languages (ja, en, zh-Hans, zh-Hant, ko, de, fr, es, it, pt).

### 1.0.51

- **Fixed the main window freezing whenever the Networks tab was open during
  Air-Gap.** That tab's 800ms refresh looks up the current Wi-Fi security,
  which pings the gateway to nudge the ARP cache before ever checking whether
  a cached answer already exists — and a `ping` given a target that never
  answers (exactly what happens under Air-Gap, which drops every outbound
  packet) blocks for its full 1-second timeout. Repeated every 800ms, that
  left the window blocked almost continuously for as long as Air-Gap was
  engaged and that tab stayed open. The lookup now checks the existing ARP
  cache first (only pinging when there's genuinely nothing cached yet) and
  runs on a background thread, so it can no longer block the window at all.

### 1.0.50

- **Fixed the security level staying at "lockdown" after an ARP-spoofing
  attack actually stopped, requiring a manual network reconnect to recover.**
  Nothing was forcing the kernel to re-verify a spoofed gateway's cached ARP
  entry — it isn't refreshed just because it's read, and the kernel's own
  reachability timers can keep trusting the last answer for a while (or
  indefinitely, if the attacker keeps sending unsolicited replies) even after
  the attacker stops. The gateway's neighbour entry is now actively flushed
  both on every cycle it's still implicated in a spoofing signal (so the
  system can notice on its own once the attacker really stops, no manual
  reconnect needed) and when you click "release" on the emergency dialog (so
  an attack that already ended doesn't still read back as lockdown and look
  like release did nothing).

### 1.0.49

- **Added a "Block now" button to the ARP-spoofing warning on
  balanced/trusted networks.** Previously this was a desktop toast only —
  blocking required opening RoamSwitch and manually triggering the
  emergency Air-Gap. The toast is now paired with a modal confirmation
  dialog offering a one-click "Block now" / "Later" choice (lockdown still
  auto-blocks without confirmation, as before).

### 1.0.48

- **Fixed Air-Gap recovery never sticking during an ongoing ARP-spoofing
  attack.** The lockdown+spoofing-detected branch re-engaged Emergency
  Air-Gap unconditionally on every 3-second cycle for as long as both
  conditions held. Since an active attacker doesn't stop spoofing on
  request, clicking "release" on the emergency dialog was undone within
  seconds — the security level never actually returned to normal. A release
  now sticks for the remainder of that spoofing episode; a genuinely new,
  later attack still engages Air-Gap fresh.
- The emergency Air-Gap dialog no longer forces the main window to pop up
  alongside it — only the dialog itself is raised now.

### 1.0.47

- **Fixed `set_security_level` silently overriding — and fighting — an
  active Air-Gap.** Any profile-switch call arriving while Air-Gap was
  engaged replaced its drop-policy firewall table with a normal profile;
  the security-check loop then saw the drop rules missing and kept
  re-asserting Air-Gap every cycle, flapping the network open and closed
  instead of recovering. `set_security_level` now refuses while Air-Gap is
  active — only the dedicated release action can lift it.

### 1.0.46

- **Fixed "Allow" on a malware-detection dialog not actually clearing the
  pending approval.** "隔離" (Quarantine) always worked correctly. "許可する"
  (Allow), however, sent the daemon a generic `resolve_approval` call that was
  only ever wired up for USB device approvals — it silently mis-routed the
  malware file's approval id into the USB-keyboard code path instead of
  resolving it, so the approval stayed stuck internally until a 3-minute
  fail-open timeout quietly cleared it rather than resolving immediately when
  you clicked Allow.

### 1.0.45

- **Fixed a black area rendering behind security approval dialogs**
  (malware quarantine, USB device authorize, link-guard warn/block, blocked
  port). The app's dark theme was applied screen-wide to every window it
  creates, including plain system-style confirmation dialogs that have none
  of the app's own styling — leaving them with a near-black backdrop behind
  unstyled text and buttons. These dialogs now render with the normal GTK
  theme instead.
- Finished localizing several dialogs (log AI-assist copy, CSV export, VPN
  errors, Air-Gap header) that were still hardcoded to Japanese, to all 10
  supported languages — in both the GUI and `roamswitch` CLI output.

### 1.0.44

- **Fixed ARP-spoofing detection that could structurally never trigger.**
  Found live during an external penetration test: the guard looked for one IP
  resolving to two different MACs within a single read of the kernel's ARP
  table — impossible, since the table holds exactly one MAC per IP and a
  poisoned entry always *replaces* the legitimate one rather than sitting next
  to it. Replaced with a real spatial check (one MAC serving several IPs at
  once — catches broad LAN poisoning) plus a new temporal check that diffs the
  ARP cache across polling cycles (catches a single targeted host, e.g.
  `arpspoof -t <you> <gateway>`), corroborated against a Wi-Fi SSID signal so
  a spoof isn't silently absorbed as an ordinary network move.
- **Stopped permanently pinning an unconfirmed (possibly spoofed) gateway
  MAC.** A second bug found in the same incident: the preventive gateway-ARP
  lock feature re-pinned whatever MAC the ARP table currently reported as
  `PERMANENT` on every profile switch, with no check against whether that
  change looked like spoofing — so a successful spoof got cemented into the
  kernel by RoamSwitch itself, turning a transient attack into a persistent
  one. A gateway-MAC change is now only pinned once it's corroborated as a
  genuine network move; an unconfirmed one is left alone and reported by the
  ARP guard instead.
- **Fixed a daemon/GUI responsiveness issue** surfaced while verifying the
  above live: a burst of profile switches and an Air-Gap engage in quick
  succession could stall the daemon's IPC listener long enough to freeze
  `roamswitch-app`'s main window. The security-check cycle's `ip`/`nft`/`nmcli`
  calls now run off the daemon's core async threads, and GUI actions that
  don't need the daemon's reply no longer block the window waiting for one.

### 1.0.43

- **`roamswitch <command> --help` now shows that command's usage.** Previously
  `roamswitch status --help` just ran the scan. Works without the daemon.
- **Added a `roamswitch(1)` man page**, bundled by every package (deb / rpm /
  tarball).
- **New CLI / headless operations guide** ([LINUX_CLI.md](docs/LINUX_CLI.md)):
  the daemon service, every subcommand, `config.json` fields, runtime-state
  files, calling the IPC directly, and cron / monitoring recipes.

### 1.0.42

- **Security confirmation dialogs now always come to the front.** A blocked-port
  / Air-Gap / malware / phishing approval dialog could open *behind* other
  windows while the main window stopped repainting behind it — which looked like
  the app had frozen. These dialogs now raise the (de-iconified) app window and
  present themselves on top with an urgency hint.
- **Threat-protection DNS reconcile moved off the sentinel lock.** Since 1.0.40
  it ran `resolvectl` per interface every 3 seconds while holding the internal
  lock, which could stall the IPC the GUI uses. It now runs detached, one pass
  at a time, and a quiet trusted network stops shelling out after the first
  pass.

### 1.0.41

- **Per-item "Harden" buttons in the Security Diagnostic tab.** In addition to
  the single "Apply Kernel Hardening" button, each failed item that has an
  automated fix now has its own one-click button: kernel sysctl / Yama / core
  dumps, `/tmp` & `/dev/shm` noexec, USB zero-trust, gateway ARP pinning, DNS
  Threat Guard, and restarting the daemon if the fanotify guard is down.
- **Fixed a recommendation that pointed to a screen that doesn't exist.** The
  Yama and noexec items advised opening a "System Defense" section; they now
  point to the actual button in the Security Diagnostic tab.
- **`/tmp` noexec hardening is now trust-aware.** RoamSwitch deliberately leaves
  `/tmp` executable on a trusted network (a noexec `/tmp` breaks package builds
  and some installers) and applies noexec automatically when you connect to an
  untrusted network. This state now shows green with an explanation instead of a
  red "needs hardening". The check also now requires both `/tmp` and `/dev/shm`
  to be noexec, not just `/dev/shm`.

### 1.0.40

- **Security health check now reflects what is actually running.** Several
  items were graded on capability alone:
  - **fanotify pre-execution blocking** now checks that the RoamSwitch guard is
    actually marked and running, not just that the kernel supports it — it went
    green even while the guard was down after a failed init.
  - **Exposed Ports** no longer assumes the firewall is up (one code path
    hard-coded that); it reads the daemon's live profile.
  - **SSH audit** no longer misreads "inactive" as "active"; with no SSH server
    running it now passes as "not applicable".
- **Trust-aware wording.** On a trusted (home) network RoamSwitch deliberately
  does not pin the gateway MAC (a permanent ARP entry would break the LAN on a
  router reboot) and, with the default DNS scope, keeps DNS Threat Guard on
  standby. These now show green with an explanation instead of a red
  "unprotected".
- **DNS Threat Guard now works on wired / multi-NIC machines.** It was hard-wired
  to an interface named `wlan0`; it now applies to every physical interface that
  carries a default route (Ethernet + Wi-Fi both, ignoring `tailscale0`,
  `docker0`, VPN and bridge interfaces). The "always-on" scope is now actually
  enforced on every network switch.
- **Fewer false positives from fileless-execution detection.** A binary updated
  in place while running (Chrome, Electron apps, Flatpak/Snap) is no longer
  flagged as an anti-forensics "deleted binary" — only genuinely suspicious
  locations (`/tmp`, `/dev/shm`, `/run`, hidden paths) are.

### 1.0.39

- **Bug fix: the on-access malware guard could stay off until the next daemon
  restart.** `fanotify_init` can fail transiently when the per-user group limit
  (`fs.fanotify.max_user_groups`, default 128) is briefly exhausted. The daemon
  now retries with backoff and recovers within about a minute instead of leaving
  the guard down.
- **Approval dialog button colors.** In the "dangerous file blocked" and malware
  prompts, "Allow" (the risky choice) is now a neutral dark button and the safe
  choice ("Keep blocking" / "Move to Quarantine") is green and the default.

### 1.0.38

- **Link protection: a blocked phishing site no longer spams notifications.**
  When link protection blocks a dangerous host in `block` mode, a browser opens
  many connections to it — you now get one notification per host, not one per
  connection attempt.
- **`block` mode now shows an Allow dialog too** (previously only a
  notification): when a site is hard-blocked you get a prompt to allow it (which
  adds it to the allow-list) or keep blocking.
- **Dangerous approval dialogs now default to the safe choice.** For a blocked
  dangerous site the highlighted / Enter-key button is now "Keep blocking", and
  "Allow" is styled as a destructive action. Same for the malware prompt:
  "Move to Quarantine" is the default, "Allow" is destructive.

### 1.0.37

- **The app is now fully translated into all 10 supported languages.** The Help
  tab (product overview, the 10-step getting-started guide, CLI command
  reference, the three protection-level cards) and the About tab (privacy
  policy, EULA, disclaimer) were previously Japanese-only or covered only 6
  languages; Traditional Chinese, Korean, Italian and European Portuguese are
  now complete. Traditional Chinese readers get a proper Traditional
  translation rather than a Simplified fallback.

### 1.0.36

- **Link guard "warn" mode now fails *closed*, not open**. When link protection
  is set to *warn* and you open a flagged site, the connection is held while you
  decide. Previously, if you didn't answer within the hold window, the
  connection was let through (fail-open). Now it is **blocked** — not answering
  "is this dangerous site safe?" shouldn't count as "yes". The Allow / Block
  prompt stays up; if you allow it afterwards, your next request goes through.
  (`warn` is not the default mode; it still never hard-blocks on its own.)
- Link guard: a timed-out verdict is no longer remembered, so your next attempt
  to reach the host prompts you again rather than staying silently blocked.
- **More of the app is now translated into all 10 languages**: the Away
  Protection Level tab, the VPN Tunnel status readout, the Canary Guard tab, the
  security-log audit report you can copy, and the Air-Gap dialogs were
  previously Japanese-only or Japanese/English-only.
- Fixed: a "ransomware process frozen" notification (freeze only, no Air-Gap)
  could pop the full Air-Gap recovery dialog. The app now decides which dialog
  to show from a language-independent tag instead of matching Japanese text in
  the notification title.

### 1.0.35

- **Link guard: "warn" mode is now usable**. When link protection is set to
  *warn* and you open a flagged site, the connection is held while you decide —
  but the hold was 30 seconds, longer than a browser or server keeps a half-open
  connection alive, so that first request died before it could be let through.
  The hold is now **8 seconds**: with no answer it fails open and connects, and
  the Allow / Block prompt stays up so your later choice applies to the next
  request. (`warn` is not the default mode.)
- Link guard: the danger verdict for a host is re-evaluated after you change the
  link-protection mode or the allow / block lists (it was previously cached and
  could keep applying the old decision).
- Link guard: its five notifications (dangerous DNS lookup, blocked connection,
  connection-on-hold ×2, possible-danger warning) are now localized in all 10
  languages (previously Japanese only).

### 1.0.34

- **Malware scan no longer quarantines files by surprise**:
  - **The EICAR test string is now notify-only.** A file that merely contains
    the industry-standard EICAR test string (a security how-to, a signature
    sample, this project's own site) is surfaced with an informational
    notification and is **never quarantined or blocked**. Previously the
    system-wide on-access guard moved such a file to the Quarantine Vault and
    denied every open of it — restoring it from git just fed the loop.
  - **A real signature match asks first.** Instead of silently quarantining,
    the guard raises a modal prompt: *Quarantine* (move to the vault),
    *Allow* (add the file to the scan-exclusion list), or *Later*. No answer
    within 3 minutes → the file is left in place (fail-open) with a notice.
    An actual `execve` of a flagged file is still denied at the kernel when
    "pre-execution blocking" is enabled.
  - **Scan-exclusion paths.** A new list in the Quarantine tab (and the
    `scan_exclusions` config key) — absolute paths, applied to everything under
    them — are skipped by both the built-in YARA scanner and ClamAV. Choosing
    *Allow* on a prompt, and restoring a file from the vault, both add to it.
  - The **"System-wide fanotify"** and **"Pre-execution blocking"** toggles in
    the GUI now actually take effect (they were previously inert).
- **Bug fix — a heavy build could make the machine unresponsive / drop the
  network**: the guard was reading its configuration on the fanotify
  permission-event loop, which must never touch the filesystem; under load this
  stalled every process opening a file. Config is now refreshed on a dedicated
  background thread.
- Download-guard and ransomware-freeze notifications are now fully localized
  (10 languages; previously 6 with an English fallback).
- Whitepaper updated to v1.5 (§5.2, §5.4, §5.5, SP-4).

### 1.0.33

- **Optimize window dimensions for 1280x720 displays & adjust VPN/DNS dropdown widths**:
  - Refined base window metrics and dynamic CSS scale factors so that on 1280x720 displays the main window fits comfortably with generous margins (~360px horizontal, ~200px vertical) rather than overflowing screen edges.
  - Adjusted dropdown combo-box layouts in VPN settings (Tailscale Exit Node / Backend selector) and DNS settings so they no longer expand across the entire window width, aligning neatly with a natural fixed width (260–320px).

### 1.0.32

- **Prevent false positive ransomware detection during package manager operations (apt / dpkg / rpm / dnf / pacman)**:
  - Fixed an issue where `apt upgrade` or package extractions (`dpkg`, `rpm`, etc.) writing numerous compressed documentation files (e.g. `.gz.dpkg-new`) triggered ransomware mass-encryption burst heuristics and frozen the process via `SIGSTOP`.
  - Added Linux package managers and installers (`dpkg`, `apt`, `rpm`, `dnf`, `pacman`, `zypper`, `flatpak`, `snapd`, etc.) to the entropy analysis allowlist and critical non-freezable process list, and excluded temporary package extract suffixes (`.dpkg-new`, `.rpmnew`, etc.) from high-entropy evaluation.

### 1.0.31

- **Tailscale VPN connection sequence & kill-switch rule optimization & VPN UI fix**:
  - Reordered Tailscale reconciliation to set the exit node before activating the kill-switch, and permitted STUN (UDP 3478) and WireGuard (UDP 41641) in kill-switch ruleset to eliminate connection timeouts/freezes.
  - Offloaded VPN tab periodic status refresh onto a background async channel and added button state management for responsive UI interactions.
  - Fixed GTK3 container visibility behavior so the Exit Node selection dropdown in the Tailscale settings panel renders reliably.

### 1.0.30

- **Immediate StatusNotifierItem icon resolution on Ubuntu GNOME at startup**:
  - Fixed an issue where the tray icon initially showed a placeholder "..." on GNOME Shell AppIndicator until the security profile changed.
  - Added immediate DBus signal broadcast on startup and normalized icon lookup across `/usr/share/pixmaps` and scalable icon directories.

### 1.0.29

- **Fully asynchronous UI actions to prevent GTK thread blocking**:
  - Offloaded manual security profile switching (Lockdown / Balanced / Open / Auto) and VPN connect/disconnect IPC operations onto background threads with `glib::MainContext::channel`.
  - Prevents window freeze/hang during nftables rule flush, service isolation, and Tailscale routing adjustments.

### 1.0.28

- **Adjusted VPN reconciliation for trusted networks and balanced protection (Standby by default)**:
  - Preserved VPN standby state on trusted networks and under Open / Balanced protection levels.
  - VPN tunnel only activates when explicitly requested via the "Connect" button or automatically upon entering Lockdown (highest protection).

### 1.0.27

- **Optimized Tailscale Exit Node parameter resolution (Verified on local live system)**:
  - Added multi-candidate resolution (Tailscale IP `100.x.y.z`, base host name, stripped domain) for `tailscale set --exit-node` to comply with Tailscale CLI syntax requirements.
  - Verified end-to-end functionality on live system for `vpn_up`, `vpn_down`, profile-level switching (Open ⇔ Lockdown), kill-switch attachment, and status synchronization.

### 1.0.26

- **Hardened Tailscale Exit Node application and active status reconciliation**:
  - Added `--accept-risk=lose-ssh` fallback to `tailscale set --exit-node` command execution, preventing silent exit node activation blocks on systems with Tailscale SSH enabled.
  - Rewrote exit node identifier matching (`find_node` / `matches`) to reliably correlate `ExitNodeStatus`, Peer `ExitNode`, and internal state across host names, fully-qualified DNS names, and peer IDs.

### 1.0.25

- **Enhanced StatusNotifierItem tray icon updates across all Linux desktop environments**:
  - Implemented embedded ARGB `icon_pixmap` rendering from vector SVG assets and normalized `icon_theme_path`, ensuring immediate tray icon transitions on GNOME, KDE, Wayfire, Sway, and XFCE upon security profile changes.

### 1.0.24

- **Fixed WireGuard configuration buttons appearing when Tailscale backend is active**:
  - Configured GTK subpanels with proper `no_show_all` properties so WireGuard buttons (import/remove config) are strictly hidden when Tailscale is selected as the VPN backend.

### 1.0.23

- **Added auto-detection for Snap-based Tailscale installations (`/snap/bin/tailscale`)**:
  - RoamSwitch daemon now automatically searches `/snap/bin/tailscale` and `/var/lib/snapd/snap/bin/tailscale` in addition to standard `/usr/bin` locations, ensuring full compatibility on Ubuntu and Snap-managed setups.

### 1.0.22

- **Enhanced VPN / Tailscale automatic reconciliation on profile switch & manual connection controls**:
  - Fixed daemon logic so manually switching security level (Balanced / Lockdown) immediately triggers VPN / Tailscale Exit Node reconciliation.
  - Enabled manual "Connect now" and "Disconnect" controls for Tailscale, allowing instant activation and testing of Exit Node tunnels directly from any network.
  - Improved active Exit Node matching logic to handle hostname / DNS name and case differences reliably.

### 1.0.21

- **Fixed VPN backend switching UI synchronization & resolved main window freeze**:
  - Fixed an issue where WireGuard descriptions and instructions remained visible when switching between WireGuard and Tailscale, making explanation cards dynamically adapt to the active backend.
  - Eliminated recursive GTK signal loops during VPN widget updates that could cause the main window to freeze.

### 1.0.20

- **Fixed VPN status daemon IPC response parsing & upgraded Exit Node input UI**:
  - Resolved an IPC response decoding defect where Tailscale and WireGuard tabs incorrectly reported "Cannot reach the daemon" despite the daemon service running properly.
  - Upgraded the Tailscale Exit Node selector to an editable combo box, allowing direct manual text input of arbitrary hostnames or IP addresses in addition to auto-detected candidates.

### 1.0.19

- **Optimized ransomware encryption thresholds & streamlined detection architecture**:
  - Replaced ad-hoc per-application path exclusions with robust, realistic detection thresholds (**20 distinct files within 5 seconds with Shannon entropy ≥ 7.92**).
  - Prevents false-positive SIGSTOP freezes from normal desktop apps and developer tools while reliably capturing genuine mass-encryption attacks.
  - Streamlined and cleaned up path filter heuristics for a cleaner, more resilient security design.
  - Canary decoy file monitoring and universal YARA malware scanning remain actively enforced.

### 1.0.18

- **Prevent false positive ransomware detections & Air-Gap triggers on Chrome / Chromium**:
  - Excluded web browser HTTP disk caches (`~/.cache/`), GPU shader caches, and IndexedDB / LevelDB storage (`.ldb`, `.sst` files) from ransomware Shannon-entropy burst heuristics.
  - Added major web browsers (`chromium-browse`, `chrome`, `google-chrome`, `firefox`, `brave`, etc.) and Raspberry Pi OS desktop shell components (`wayfire`, `labwc`, `wf-panel-pi`, `pcmanfm-pi`, etc.) to the entropy allowlist and non-freezable process protection list.
  - All file writes across the entire filesystem remain strictly inspected by YARA with zero bypass.

### 1.0.17

- **Fixed task and tray icon display issues on Raspberry Pi OS & Linux desktop environments**:
  - Ensured status SVG icons (`roamswitch-open.svg`, etc.) are packaged into standard hicolor icon paths.
  - Added `librsvg2-common` to `.deb` package dependencies to guarantee SVG rendering on Raspberry Pi OS (Wayfire / Labwc).
  - Enhanced runtime icon search fallback to properly display window and brand icons even when run directly from source (`cargo run`).
- **Improved notification and confirmation dialog for Port Anomaly Guard auto-blocks**:
  - When an unknown `0.0.0.0` port is auto-blocked, a confirmation dialog now pops up allowing you to permanently whitelist the port with a single click ("Allow This Port").
  - Fixed alert queue polling timestamp synchronization to millisecond accuracy to prevent missed event notifications.
- **Enhanced file protection precision (Separation of YARA scanning & Ransomware entropy tracking)**:
  - All filesystem writes across user directories, caches (`~/.cache/`), and `node_modules/` are strictly scanned by YARA with zero bypass.
  - Refined ransomware entropy burst heuristics to exclude naturally compressed archives (`.tgz`, `.zip`) and verified package manager caches (npm, cargo) to eliminate false-positive SIGSTOP process freezes.

### 1.0.16

- **The VPN backend is now selectable — WireGuard or Tailscale** (the backend
  chooser in the "VPN Tunnel" tab).
  - **WireGuard**: import a config file (`.conf`) as before.
  - **Tailscale**: if you already use Tailscale, just pick an **exit node** that
    routes all traffic. On an untrusted network RoamSwitch routes everything
    through that exit node and arms a kill-switch. Log in first with
    `sudo tailscale up`. With no exit node there is no MITM protection (the UI
    says "not protected"). If the chosen exit node goes offline, protection is
    disarmed automatically and you're notified.
  - The Tailscale kill-switch is looser than the WireGuard one (its transport
    can't be pinned to one endpoint): it allows only `tailscale0`, the tailnet
    (`100.64.0.0/10`), STUN, DERP (tcp/443), DHCP and MagicDNS — everything
    else, DNS included, is dropped.
  - The `tailscale` package was added to Recommends / optdepends.
- **Verified the Tailscale kill-switch in isolated network namespaces** (SP-10,
  16/16 PASS): off-tunnel plaintext traffic and DNS to a local resolver are
  blocked, DERP-shaped traffic and MagicDNS are allowed, and connectivity is
  restored correctly across enable/disable.

### 1.0.15

- **Bug fix — the VPN tunnel would not connect on Ubuntu 24.04+**: the
  WireGuard config was stored under `/etc/roamswitch/wireguard/`, which the
  AppArmor `wg-quick` profile on Ubuntu 24.04+ / Debian 13 does not allow
  `wg-quick` to read, so the tunnel never came up. It is now stored at the
  standard `/etc/wireguard/roamswitch.conf`.
- **Bug fix — the kill-switch could fail to apply**: when installing the
  nftables kill-switch before the tunnel interface exists, the interface-name
  match style could make the ruleset fail to load.
- **The "protection profile switched" notification now states the reason** —
  "an unregistered network", "your setting for the registered network X", or
  "no network connection" (all 10 languages).
- **Ran the hardware-equivalent verification**: in isolated network
  namespaces, confirmed that the preventive ARP/NDP lock ignores a spoofed
  ARP, that the kill-switch blocks off-tunnel traffic while letting the
  WireGuard handshake through, that nothing leaks when the tunnel drops, and
  that connectivity is restored on disconnect.

### 1.0.14

- **Bug fix**: with a manually pinned protection level ("until next
  disconnect"), every boot printed "Manual override cleared" and dropped the
  setting. It is now kept when you reconnect to the same network and only
  cleared when you actually move to a different network.
- **Silenced the apt Notice** printed on every `apt update` about skipping
  `main/binary-i386/Packages` because the repository does not support the
  `i386` architecture. The apt source line is now scoped to
  `arch=amd64,arm64` (upgrading to this version also fixes an existing
  `/etc/apt/sources.list.d/roamswitch.list` automatically). To fix it by hand:
  `sudo sed -i 's|deb \[signed-by=|deb [arch=amd64,arm64 signed-by=|' /etc/apt/sources.list.d/roamswitch.list`

### 1.0.13

- **Added a VPN tunnel with a kill-switch** (the "VPN Tunnel" tab). Import a
  WireGuard config (`.conf`) and RoamSwitch brings an encrypted tunnel up
  automatically when you join an untrusted network (a café, public Wi-Fi). A
  **kill-switch** blocks everything except the tunnel and its handshake until
  the tunnel is established (and while it's down), so ARP/NDP spoofing or
  packet sniffing sees only ciphertext. This is the primary anti-MITM defence;
  the ARP/NDP lock and detection are secondary to it. Trusted networks are left
  alone. Requires `wireguard-tools` (`sudo apt install wireguard-tools`, etc.).

### 1.0.12

- **ARP spoofing detection now matches the macOS response model.** In Lockdown
  it still cuts all traffic (Air-Gap) immediately; on Balanced / trusted
  networks it **notifies instead of cutting**, and you trigger the emergency
  Air-Gap from RoamSwitch yourself. This stops a router reboot or access-point
  switch from triggering it by mistake, and stops an attacker from using a
  single spoofed ARP packet to knock you offline.
- **Bug fix**: the ARP spoofing auto-containment ran even when the setting was
  turned off (the daemon wasn't checking the config switch).

### 1.0.11

- **The gateway ARP lock is now a full preventive anti-MITM measure.** On an
  untrusted network (a café, public Wi-Fi), the MAC address of the IPv4
  gateway — **plus the IPv6 default router and any DNS server on the same
  network** — is pinned into the kernel neighbour table, so ARP/NDP spoofing
  can't set up a man-in-the-middle attack. Trusted networks are never pinned.
  Re-pinned on every network change.
- **Bug fix**: this setting used to run for the gateway only and on every
  network; it's now scoped to untrusted networks.

### 1.0.10

- **Added an "Upgrade now" button to the Updates tab.** When the update check
  finds a newer version, one click (after a graphical administrator‑password
  prompt) runs the upgrade via apt / dnf / zypper. Copying the command to run in
  a terminal still works as before.
- **Reconciled behaviour with the macOS version** (`docs/MAC_PARITY.md`):
  - Confirmation dialogs when toggling a guard on/off are back, for the same
    guards as macOS (Port Anomaly, ARP auto‑containment, USB Storage, BadUSB
    keyboard, Bluetooth). The 1.0.9 "dialog on every launch" bug is fixed at its
    root cause (GTK re‑emits the toggle signal even for a programmatic state
    sync) and the confirm was re‑implemented correctly. Bluetooth confirms on
    enable only, matching macOS.
  - **USB Storage Guard and Bluetooth Guard now default to OFF**, matching the
    macOS version. Turning either on shows a confirmation dialog.
  - Toggling DNS threat protection no longer shows a confirmation dialog
    (matches macOS).
- **Bug fix**: the Bluetooth guard and "gateway ARP lock" ran when joining an
  untrusted network even if you had turned them off — the daemon was not
  checking the config switches.

### 1.0.9

- Fixed a confirmation dialog ("Enable / Disable this protection?") popping up
  on app launch and on every screen refresh even though no guard switch was
  touched (a 1.0.7 implementation mistake). Confirmation dialogs now appear only
  on **events** — an unknown USB keyboard connecting, a USB drive being
  inserted, an emergency Air-Gap.
- **An approval dialog is now shown when you insert an unregistered USB drive.**
  "Allow" makes the device usable and adds it to the allow-list; "Deny" keeps it
  held (the same mechanism as the USB keyboard approval).

### 1.0.8

- Fixed the first-run setup wizard sometimes freezing on the final "Apply" (the
  wizard re-entered its own teardown while applying).
- **The setup wizard now starts automatically on your next login after
  installing** (a `/etc/xdg/autostart` entry is included). After setup it runs
  silently in the system tray.
- Fixed untranslated parts of the setup wizard (the away-protection level
  choices were English-only; page 2's body text repeated the title).

### 1.0.7

- **Important bug fix**: the BadUSB / USB keyboard guard, when it saw a keyboard
  that wasn't on the allow‑list, disconnected that device at the kernel level.
  On a combined keyboard+mouse receiver (common on Raspberry Pi and mini PCs)
  **the mouse went with it**, and a machine with no built‑in input became
  unusable. Now:
  - Kernel‑level disconnection of a keyboard is gone. Instead, only the
    **keystrokes** of an unapproved keyboard are held (the device stays powered;
    the mouse and any other keyboard keep working) and an **approval dialog** is
    shown (the same model as the Mac edition). "Allow" enables input and adds it
    to the allow‑list; "Deny" keeps it blocked. If nothing answers within 3
    minutes it releases automatically (so a headless box is never stuck). It
    does not block if there is no other usable keyboard.
  - Fixed a plain USB mouse being mistaken for a keyboard and blocked.
  - Devices disconnected by a previous version are restored automatically on
    the first launch after updating.
  - The BadUSB keyboard guard now **defaults to off** (add your keyboards to
    the allow‑list in the first‑run wizard, then enable it).
- **Added confirmation dialogs when toggling a guard** (matching the Mac
  edition): ARP auto‑containment, the port anomaly guard, the USB storage /
  keyboard guards, Bluetooth auto‑off, DNS threat protection, and weakening the
  link‑protection mode all now ask first.

### 1.0.6

- **Added the port anomaly guard** (on by default). It learns which programs
  are listening when you enable it ("known"), then detects any *new, unknown*
  program that starts exposing a port to the LAN (a backdoor / C2, a dev server
  accidentally bound to `0.0.0.0`, …) and automatically blocks external access
  to just that port — this machine and localhost keep working. A notification
  lets you allow it from the "Port & DevIsolator" tab if you started it
  yourself. It runs regardless of whether the network is trusted. Disable it
  with `portAnomalyGuardEnabled: false` in `config.json` (which also releases
  every port it blocked); "Re-learn baseline" re-captures what's listening.
- Fixed the bundled threat feed being empty: a fresh install now blocks
  phishing / scam sites immediately (previously only the offline heuristics
  worked until the first daily-updater run or `apt upgrade`).
- Fixed an internal firewall helper table sometimes lingering after switching
  link protection to `off`.
- Tidied up UI copy (the Linux edition is a fully free Community Edition, so a
  few stray "(Pro)" labels were removed).

### 1.0.5

- **Added the passive link guard** (on by default). It watches where outbound
  connections are going and warns you about connections to phishing / scam
  sites. Clear phishing (a host on the threat feed, or a brand‑impersonation
  domain) is blocked by default, with a one‑tap allow from the notification.
  Verdicts use offline heuristics (confusable IDN characters, raw‑IP hosts,
  high‑risk TLDs, …) and never send the target anywhere. It replaces the old
  paste‑a‑URL checker. Switch off / warn / block in the settings tab or via
  `linkGuard.mode` in `config.json`.
- **Added the daily updater** (`roamswitch-update.timer`). Once a day it
  receives a signed phishing‑site list, the ClamAV signature version, and the
  latest app version. It is receive‑only and sends nothing about you or your
  machine (no query string, no cookies, no identifiers). Turn it off entirely
  with `systemctl disable --now roamswitch-update.timer` or `"enabled": false`
  in `updates.json`; the product then runs on the data bundled in the package.
- Fixed a bug where the whole desktop could freeze for tens of seconds shortly
  after boot and RoamSwitch would crash (and auto‑restart). The cause was the
  ransomware heuristic misfiring on apps that write many encrypted local files
  in a short burst (e.g. Telegram); the exclusion list has also been widened.

### 1.0.4

- Fixed a display bug in the "Check for updates" tab where the suggested command
  was sometimes not shown.
- "Open release notes" opened the product page; it now opens the public
  changelog (the CHANGELOG on GitHub).
- Fixed the window subtitle staying in the launch-time language after switching
  languages.

### 1.0.2

- Automatic stop/restore of sharing services is now on by default: on an
  untrusted network SSH / Samba / remote desktop are stopped, and restored when
  you return to a trusted network (matches the Mac edition; toggle it off in the
  Networks tab or with `roamswitch sharing off`).
- Protection‑level names are localized in all 10 languages; set custom names via
  `level_labels` in `config.json`.
- Registered‑network names are localized, and the Name cell in the list is now
  editable inline (double‑click to rename).
- Added an explanation of the URL Safety Audit tab.
- Larger, clearer security‑score display on the dashboard.
- Fixed the About screen showing a stale version number; tidied up copy.

### 1.0.1

- First published release. The apt (`lafine.net/apt`) and dnf/zypper
  (`lafine.net/rpm`) repositories are published with an RSA‑4096 signature.
  GitHub Releases carry the `.deb` / `.rpm` / signed tarball.
- The AUR package `roamswitch-bin` is being set up (build from the bundled
  PKGBUILD for now).
- Fixed a package‑build CI failure.

### 1.0.0

- Initial release. Brings the zero‑trust network defense model of macOS
  RoamSwitch to Linux.
- Identifies the connected Wi‑Fi / wired network by gateway MAC and autonomously
  switches `nftables` profiles (Trusted / Standard / Away).
- Behavioral ransomware detection (fanotify + Shannon entropy + canaries) with
  emergency Air‑Gap isolation, an unauthorized‑USB / BadUSB guard, a 20‑item
  security health assessment, and a read‑only MCP server.
- Free Community Edition (proprietary freeware). All 10 languages.

---

## RoamSwitch for Mac

## 1.8.3

- **Emergency confirmation dialogs now always come to the front.** The four
  windows that open by themselves in response to a threat — the BadUSB keyboard
  approval, the ransomware and ARP-spoofing emergency dialogs, and Link Guard's
  "connection on hold" prompt — now present as a top-most overlay that stays
  above other apps' windows and full-screen apps, on whichever Space you're on,
  even when RoamSwitch is a background menu-bar app.

## 1.8.2

- **Malware scan no longer quarantines the harmless EICAR test file.** A file
  that merely contains the industry-standard EICAR test string (a security
  how-to, a signature sample, this site itself) now only raises an
  informational "🧪 EICAR test signature detected (harmless)" notification — it
  is never quarantined or blocked. Same behaviour for the download auto-scan,
  the scheduled scan, and a manual scan. A genuine malware sample is still
  moved to the Quarantine Vault (reversible). Matches the Linux edition 1.0.34.
- **Per-item fix buttons in the Security Diagnostic.** Each failed (🔴) item now
  has a one-click button: RoamSwitch's own guards (DNS Threat Guard, Web/Mail
  protection, USB guard) get a "🔧 Enable" that turns them on in place; OS-level
  items (FileVault, Gatekeeper, …) get "Open Settings" that jumps to the right
  System Settings pane. The check re-runs automatically afterwards.

## 1.8.1

- Link Guard "Warn only" mode refinements. The "Allow / Block" choice for a
  held connection now also appears as a foreground panel, not just a
  notification (a "banner"-style notification only shows its action buttons on
  hover). The panel's default action is the safe one — Block.
- Fixed: in "Warn only" mode a site you had previously blocked by hand could be
  dropped immediately instead of prompting (warn mode never hard-blocks).

## 1.8.0

- **Link Guard is now enforced by a content-filter system extension** (Pro). It
  inspects the actual outbound connection *after* name resolution, so it blocks
  phishing/scam sites even when the browser does its own encrypted DNS
  (DoH/DoT); it also parses the TLS ClientHello (SNI). It needs a one-time
  approval in System Settings (no Apple review required). The previous
  `/etc/hosts` method stays as a fallback until the extension is approved.
- **"Warn only" mode is now a real warning.** On a suspicious connection the
  extension pauses that connection and raises a notification with "Allow" /
  "Block" buttons; your choice resumes or drops the held connection (no answer
  within 25 s lets it through). The decision is remembered per site, so the
  page's other requests and later visits apply instantly.
- **The VPN tunnel backend is now selectable between WireGuard and Tailscale**
  (Pro, off by default). Under "Ports & Device Monitoring" → "VPN Tunnel" →
  "Backend". With Tailscale you pick an **exit node** from your existing tailnet
  to route all traffic through the tunnel on untrusted networks. RoamSwitch
  never runs `tailscale up` / logs in / installs it — it reads status and sets
  the exit node. The standalone CLI (`brew install tailscale`) is recommended.
- Helper updated to 1.8.2 — re-approve on first launch.

## 1.7.6

- **Added a VPN tunnel with a kill-switch** (Pro, off by default). Import a
  WireGuard config (`.conf`) and RoamSwitch brings an encrypted tunnel up
  automatically when you join an untrusted network. A pf kill-switch blocks
  everything except the tunnel and its handshake until the tunnel is
  established (and while it's down), so ARP/NDP spoofing or sniffing sees only
  ciphertext. This is the primary anti-MITM defence; the ARP/NDP lock and
  detection are secondary to it. Trusted networks are left alone. Backed by
  Homebrew's `wireguard-tools` (`brew install wireguard-tools`) — no Apple
  Network Extension entitlement required. Under "Ports & Device Monitoring" →
  "VPN Tunnel".

## 1.7.5

- **Added a preventive gateway ARP/NDP lock** (Pro, off by default). When you
  join an unregistered network (a café, public Wi-Fi), the MAC address of the
  gateway, the IPv6 router, and any DNS server on the same network is pinned so
  ARP/NDP spoofing can't set up a man-in-the-middle attack in the first place.
  Enable it under "Ports & Device Monitoring" → "Pin gateway ARP/NDP on
  untrusted networks (preventive)".
- **Reworked the ARP spoofing auto-containment response.** In Lockdown it still
  cuts all traffic immediately; on Balanced / trusted networks it now
  **notifies instead of cutting**, with a "Cut all network now" item in the
  menu. This stops a router reboot or access-point switch from triggering it by
  mistake, and stops an attacker from using a single spoofed ARP packet to
  knock you offline.

## 1.7.4

- **USB Storage Guard no longer ejects an unknown drive outright.** An
  unrecognised external drive is now mounted read-only and an approval prompt
  is shown — "Allow read-write", "Allow read-only", or "Eject". Approving adds
  it to the allow-list and applies the chosen permission (after the usual
  ClamAV scan). This matches the Linux edition's insert-time prompt and means a
  mistaken eject can't lose in-flight work.

## 1.7.3

- Fixed "Link Guard" (added in 1.7.2) not appearing in the menu bar. The
  blocking engine itself was running in 1.7.2, but the UI for the mode switch
  (Off / Warn only / Auto-block), the scam-list version, and the auto-update
  toggle was missing. It's now under "Malware Protection" → "Link Guard".
- Renamed the manual check item to "Check a link manually…".

## 1.7.2

- 🔗 Added the passive Link Guard (auto-blocks phishing connections) (Pro):
  - Automatically blocks connections to phishing and scam sites on-device, based on a list of known scam sites and brand-impersonation domain checks. The privileged helper adds the domains to a managed section of `/etc/hosts` pointing at `0.0.0.0` — no Apple Network Extension entitlement required — so the block applies across every browser and app.
  - From "Link Guard" in the menu bar you can choose "Off", "Warn only (don't block)", or "Auto-block obvious scam sites (recommended)". **The default is now auto-block.** Only clear cases are blocked — a listing in the threat feed, or a brand-name homograph — everything else is a warning. A wrong block can be allowed in one click from the notification or the menu (5 minutes or permanent).
  - The verdict engine and threat feed are shared with the Linux edition.
- 📡 The threat feed now uses a dedicated Ed25519 signing key, separate from the app-update key. The feed is fetched once a day, receive-only (nothing sent, no identifiers). Turning off "Auto-update" drops external traffic to zero; the feature runs on bundled data (~280 entries) plus homograph detection.
- 🌐 New UI and help strings localized in all 10 languages.

## 1.7.1

- 🚀 Smoother first-time setup (privileged helper approval):
  - Added a gate that detects when RoamSwitch is running from outside the Applications folder (Downloads, the disk image, etc.) — macOS won't let the helper register from there — and guides you to fix it before the approval step, with a "Move to Applications & relaunch" button.
  - Added recovery paths when helper approval doesn't complete: a retry button on registration failure, clearer guidance on exactly which switch to turn on, and a re-download prompt if the helper is missing.
  - When the helper is not connected, the menu bar now shows an "⚠️ Approve the helper…" item that takes you straight to the right Settings pane.
  - If the helper stays unapproved for a few days, the app shows one quiet on-device reminder (nothing is sent anywhere).
  - New screens and strings localized in all 10 languages.

## 1.7.0

- 🔌 BadUSB & Physical Keyboard Approval Guard (`USBKeyboardGuard`):
  - Dynamic real-time monitoring of newly connected HID keyboards and modified cables (Rubber Ducky, O.MG Cable, etc.) via IOKit (`IOHIDManager`).
  - Built-in MacBook keyboards are automatically allowlisted to ensure uninterrupted daily workflows.
  - Intercepts and drops keystrokes from unapproved keyboards instantly via `CGEventTap`, stopping malicious automated keystroke/command injection attacks at the physical boundary.
  - Displays a dedicated approval modal allowing users to review and authorize trusted devices with a single click.
- 🛡️ Unified USB & BadUSB Guard Settings UI:
  - Segmented tab navigation for seamlessly managing both Keyboard and Storage allowlists in one place.
  - Added live real-time detection of macOS Accessibility permissions and direct Settings navigation.
- 📊 Enhanced Security Health Checks:
  - Added audit checks for "Unauthorized USB / BadUSB Physical Port Guard" and "macOS Accessory Security (Apple Silicon)".
- 🌐 Full 10-Language Localization:
  - Added comprehensive translations across all 10 supported languages: English, Japanese, German, French, Spanish, Italian, Korean, Portuguese, Simplified Chinese, and Traditional Chinese.

## 1.6.4

- Ransomware Canary Baseline Hash Disk Persistence & Lifecycle Optimization:
  - Persisted baseline expected SHA-256 hashes per canary bait file to disk (`UserDefaults`).
  - Missing or tampered decoy files are no longer prematurely overwritten on routine app launches, strictly preserving tamper/deletion detection against the persisted baseline.
  - Full self-healing regeneration from embedded pristine templates is executed exclusively upon explicit user containment release ("緊急隔離を解除").

## 1.6.3

- Menu Bar Icon State Stability & Immediate Manual Override Updates:
  - Enhanced state publisher bindings and immediate icon refresh on manual security level overrides, eliminating lingering busy spinner icons.
  - Added failsafe timeout to diagnostic passes (`isDiagnosing`) to guarantee the busy state never gets permanently stuck.
- Hardened Threat Quarantine Permissions:
  - Quarantined files in `~/Library/Application Support/RoamSwitch/Quarantine` now have all read and execute permissions stripped (`chmod 000`) to render isolated threats completely inert.

## 1.6.2

- Automatic Legacy Data Migration for Port Anomaly Guard:
  - Added startup migration in `PortAnomalyGuard` to purge legacy portless interpreter identities (e.g. bare `"Python"`) from `KnownExecutablesV2`.
  - Ensures seamless precision and strict per-port scoping across version upgrades.

## 1.6.1

- Suppress Redundant Notifications During Active Ransomware Containment:
  - Fixed an issue where 60-second periodic integrity checks repeatedly dispatched threat alerts while emergency isolation was already active.
  - Pauses background polling and duplicate notifications until isolation is resolved.

## 1.6.0

- Resilient Quarantine Fallback for Existing Filename Collisions:
  - Added automatic collision resolution in QuarantineManager: if a previously quarantined file with the exact same name already exists, RoamSwitch isolates the newly flagged threat under a timestamped unique filename.
  - Guarantees zero residual infected files remaining at the original path upon re-download or duplicate attacks.

## 1.5.9

- Comprehensive ClamAV Quarantine Coverage (Bypass Prevention):
  - Added instant inspection for `.tmp` files to catch payload downloads attempting extension evasion.
  - Enabled active scanning across all watched directories (Desktop, Documents, Downloads) regardless of `com.apple.quarantine` attributes, ensuring tools copying via terminal (`cp`, `curl`, `wget`) or external media are immediately audited and quarantined.

## 1.5.8

- Robust Remote Login (SSH) & Sharing Service State Restoration:
  - Upgraded service load detection (`launchctl print`, `print-disabled`, `systemsetup`) to reliably track `com.openssh.sshd` across modern macOS versions.
  - Coupled `launchctl load -w` with `/usr/sbin/systemsetup -setremotelogin on` upon lockdown release and trusted network transition to guarantee Remote Login (SSH) restoration.
- ClamAV Download Quarantine Deduplication & Multi-scan Prevention:
  - Fixed duplicate quarantine entry bug caused by concurrent FSEvents file write/flush triggers.
  - Added in-flight scan and recently-quarantined file caching to eliminate redundant scans and quarantine folder ballooning.

## 1.5.7

- Security Guard Architecture & Robustness Enhancements based on VM Penetration Audit:
  - **Ransomware Canary Bait Self-Healing**: Automatically regenerates and restores the baseline hash of any missing or tampered canary decoy files upon emergency isolation release, immediately reinstating kqueue real-time monitoring.
  - **Strict Per-Port Identity for Generic Interpreters**: Generic script interpreters and networking shells (Python, Node.js, Ruby, PHP, Netcat, etc.) are now identified by path:port rather than path alone, preventing living-off-the-land attackers from exploiting a previously-allowed interpreter binary to open unmonitored backdoors on new ports.
  - **Baseline Poisoning Prevention & Reset**: Eliminated unconditional whitelisting of unverified userland listeners on first-time guard activation; added baseline reset capability.
  - **Download Guard Hidden File (Dotfile) Detection**: Refined exclusion filters to only ignore macOS system metadata (.DS_Store, ._*), ensuring hidden payload downloads (e.g. .hidden_eicar.txt, .payload.sh) are reliably inspected in real time by ClamAV.

## 1.5.6

- Improved Automatic Restoration of Sharing Services (SSH / SMB / Screen Sharing) upon Emergency Isolation Release:
  - Fixed an issue where previously active sharing services (such as Remote Login / SSH and SMB file sharing) were not reliably restored after releasing emergency containment (Air-Gap / Lockdown) from ARP spoofing or ransomware detection.
  - Strengthened helper daemon service state persistence and state protection against duplicate isolation invocations.
- Performance & Responsiveness Enhancements during Emergency Containment and Background Monitoring:
  - Offloaded process enumeration and file inspection in port monitoring and canary guard to background queues to prevent main-thread UI hangs and spinning beachballs.
  - Enhanced trusted signature verification for macOS system daemons (such as photoanalysisd) to eliminate false attribution.

## 1.5.5

- Web & Mail Download Guard (ClamAV Real-Time Scan) Detection & Alert Improvements:
  - Improved file path parsing logic when processing ClamAV threat scan outputs. Fixed an issue where quarantined threat files were misidentified in the recent scan history, ensuring high-priority banner notifications ("🚨 Quarantined Malicious Download File") and threat status indicators are reliably dispatched upon detection.

## 1.5.4

- Added Confirmation & Risk Warning Dialogs When Turning Off Critical Security Guards:
  - When disabling crucial autonomous protection features such as "Auto-Contain ARP Spoofing", "Auto-Block Unknown Listening Ports", or "Auto-Block Unauthorized USB Storage", RoamSwitch now presents a confirmation dialog with full risk explanations (localized in 10 languages).
  - Prevents accidental deactivation and ensures users are aware of potential security risks before turning off guards.
- Menu Bar UI Enhancements:
  - Added guard toggles for ARP spoofing and port anomaly containment directly into the SwiftUI menu bar interface for consistent usability.

## 1.5.3

- MCP (Model Context Protocol) Server Integration Enhancements:
  - `get_exposed_ports` now covers local AI inference servers (Ollama, LM Studio, Gradio, vLLM) exposure audits.
  - `get_guard_status` and `get_app_help` updated with full knowledge coverage for clipboard secret leak prevention and Pickle AI model download guard.

## 1.5.2

- Confidential API Key & Secret Leak Prevention (Clipboard Protection):
  - Automatically scans clipboard contents on-device (Zero Telemetry) for OpenAI, Anthropic, GitHub, AWS, HuggingFace, Google Gemini keys, and private keys to prevent accidental pasting into AI chats or public websites.
- Unsafe AI Model File (Pickle / PyTorch) Download Protection:
  - Detects arbitrary code execution risks in downloaded `.pkl`, `.pickle`, and `.pt` model files, prompting recommendations to use SafeTensors or GGUF formats.

## 1.5.1

- Added Local AI / LLM Server Exposure Detection & Protection (Ollama / LM Studio / Gradio / vLLM):
  - Added detection and proactive alerts for local AI inference servers accidentally bound to `0.0.0.0` (accessible across the entire LAN), including Ollama (port 11434), LM Studio (1234), Gradio / AI WebUI (7860), and vLLM (8000).
  - Prevents unauthorized remote model execution/download/deletion, GPU compute theft, and prompt eavesdropping over the local network with one-click `pf` isolation and configuration guidance.
- Added Crash Watchdog & Auto-Recovery:
  - Introduced a background watchdog agent (LaunchAgent) that automatically detects unexpected terminations and restarts the application.
  - Built-in exponential backoff (2s, 4s, 8s, 16s, 32s) and a 5-attempt retry limit to prevent infinite restart loops.
  - Native macOS notifications (UNUserNotificationCenter) alert you when an auto-restart occurs or if the crash limit is reached.
  - Clean user quits are recognized and will not trigger restarts.

## 1.4.8

- Onboarding: Added an animated video guide demonstrating the macOS system approval steps for the helper tool.

## 1.4.7

- Added an **"Allow" button** to the "auto‑block unknown listening ports" notification. If a
  legitimate LAN receiver started after the guard was enabled — LocalSend, Syncthing — gets
  blocked, you can now allow it permanently straight from the notification banner (Apple system
  daemons that satisfy `anchor apple` remain out of scope, as before).
- Updated the in‑app help and the MCP knowledge base (the auto‑block guards are on by default once
  Pro is active; how to recover from a false positive).

## 1.4.6

- Open source:
  - The bundled read-only MCP server and the detection logic behind it are now published under the MIT license at <https://github.com/lafine1211/roamswitch-mcp>, so you can verify in code what the server exposes to an AI client and that it sends nothing out.
- Fixed:
  - A single crafted JSON-RPC line with deeply-nested objects could crash the MCP server (a stack overflow inside Apple's JSON parser). The server now rejects pathologically nested input before parsing. Found by fuzzing the parser after open-sourcing it; details in the repository's `SECURITY_TESTING.md`.

## 1.4.5

- Security audit and hardening:
  - Hardened privileged helper XPC authentication by switching from PID to `audit_token_t` validation and enforcing Apple Developer Team ID pinning to eliminate PID-reuse / TOCTOU risks.
  - Relocated temporary packet-filter (pf) rule generation to a root-protected directory.
  - Added SSRF protection to the link safety auditor to block unintended internal/private network redirects.
  - Enhanced quarantine metadata integrity to prevent collisions and unintended deletions when multiple files share the same filename.

## 1.4.4

- Expanded MCP Server capabilities:
  - Added an authoritative built-in knowledge base covering all security features, notification catalogs, and troubleshooting guides.
  - Added the `get_app_help` tool for AI agents to query application mechanisms and alert explanations.
  - Added MCP resources (`roamswitch://docs/...`) for documentation inspection.

## 1.4.3

- Fixed: the emergency network isolation (air‑gap) triggered on ARP‑spoofing and
  ransomware detection did not engage correctly when the unknown‑port auto‑block
  guard was also on. Air‑gap engagement is now verified, and a failure is shown
  honestly in the modal instead of claiming full isolation.
- Fixed: "auto‑block unknown listening ports" mis‑flagged legitimate processes that
  rotate their port between launches (including built‑in macOS features like
  Handoff). Apple system daemons are now out of scope.
- Fixed: disabling "auto‑block unknown listening ports" left the block rules it had
  created in place.
- Pro: "auto‑block unknown listening ports" and "auto‑air‑gap on ARP spoofing" are
  now on by default once a Pro license is active (your explicit choice is respected
  after that).
- Added a once‑daily background virus scan to the autonomous patrol (a quiet
  notification when clean, auto‑quarantine plus an alert on a hit).
- A ClamAV scan that finishes clean now reports via a notification instead of a
  modal dialog.

## 1.4.2

- MCP server: protocol‑version negotiation and JSON‑RPC batch support.

## 1.4.1

- In‑app Help & Guide expanded: Web/Mail download guard, DNS threat protection,
  link‑safety auditor, editable watch folders.

## 1.4.0

- Web/Mail triple guard: download auto‑scan, DNS threat protection, link‑safety auditor.
- New MCP tools; custom watch‑folder editor with restore‑to‑default.

## 1.3.0

- Read‑only MCP server; instant alert for `0.0.0.0`‑exposed database ports.

## 1.2.0

- Auto‑block unknown listening ports; ARP‑spoofing auto‑containment guard.
- ClamAV scan on USB mount documented in Help.

## 1.1.x

- Onboarding: added "launch at login" step; fixed helper‑not‑connected cases.

## 1.0.0

- Initial public release: trusted‑network detection by gateway MAC, per‑profile
  firewall / stealth / sharing / AirDrop switching, Mac security health check.
