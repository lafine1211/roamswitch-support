# Changelog

**English** | [日本語](CHANGELOG.ja.md)

All notable user‑facing changes to RoamSwitch. The Mac
edition (1.x) and the Linux edition (1.x, a separate series) are versioned
independently. Older releases are summarized in ranges.

---

## AccessScope

A security diagnosis tool for access logs. It is a separate app (Apache-2.0): the Server Edition .deb / .rpm packages carry only the command (`accessscope`); the Linux client edition and the Mac app carry the command and a window app.

### 0.1.0

- **First release.** From web server access logs (Apache and Nginx common/combined, nginx / Caddy / Traefik JSON, gzip) and SSH authentication logs (sshd logs, and journald on Linux) it finds attack attempts and shows them with the evidence log lines, the MITRE ATT&CK technique ID and a confidence level (confirmed, likely, hypothesis). It is read-only: it never changes logs and never raises privileges. The analysis uses neither an LLM nor the network.
- **What it finds**: SQL injection, path traversal, XSS, command and code injection, Log4Shell, Shellshock, template injection, SSRF, exploit paths of known vulnerabilities (Apache 2.4.49/50, PHPUnit, Laravel Ignition, Citrix, FortiOS, Spring4Shell, Confluence, Exchange and others), probing for secret files and admin pages, attack-tool User-Agents, mass attempts on non-existent paths, login brute force and distributed credential stuffing, possible web shell access, chains from reconnaissance to exploitation, high request rates, SSH brute force, username enumeration, a success after failures, root password logins, and instructions to an AI planted in the logs.
- **An HTTP 200 is not treated as success.** If a 2xx response to an attack-looking request is the same size as the normal page, it is reported as "the payload was probably ignored" and does not raise the severity. The overall risk (0 to 100) is weighted per kind of finding, so the number of attacking IPs does not inflate it.
- **It looks for the logs.** Besides standard locations it checks the places named by nginx, Apache, Caddy and Traefik configs (including rotated files) and, on Linux, journald. Optionally an LLM is given only facts about the environment (names of running servers, log locations named in configs, file names such as under `/var/log`; never file contents) and suggests missing locations. A suggestion is shown only after it is verified to be readable as a log, and nothing is read until you pick and add it.
- **Analysis by an LLM (optional, off by default).** Only a summary and a few evidence log lines are passed to an LLM (claude, opencode, codex, agy) to write a report. Raw logs are not sent; secrets are masked and IPs are defanged (or pseudonymized). `--show-prompt` shows exactly what would be sent. Logs are attacker-controlled, so text that looks like instructions to an AI is reported as a finding and the LLM output is treated as an untrusted quotation. It does not run as root. When enabled, the summary may be sent to an external service through the LLM command you chose.
- The Mac app can update itself (Settings → Update). On Linux it is updated by the package.
- The screens and the command line are in 10 languages (translations are machine-made and have not been reviewed by native speakers).

## PathScope

### 0.1.6

- **Added: when PathScope itself is the subject of a finding, an explanation is added** (macOS). The finding that an app with Full Disk Access can be overwritten by an ordinary user also applies to PathScope itself, which asks you to allow it so that it can read the privacy settings data (TCC.db). The finding is not hidden: it is marked as being about PathScope itself, with what to do (remove the permission in System Settings once the reading is done; making root the owner also works, but the in-app update then asks for the administrator password and the owner may revert after an update). It is shown in both the app and the command line. The text was added in 10 languages (the translations are based on machine translation and have not been checked by native speakers).

### 0.1.5

- **Added: it checks the versions of installed software against known vulnerabilities.** It compares the versions of packages, the running kernel and macOS with known vulnerabilities that were exploited in real attacks (50 entries from the CISA KEV catalog that let a regular user become root), and adds the ones that are not yet fixed to the paths to root. There is one path per package, the unit you fix, listing the matching CVE numbers. The suggested fix is an update command (apt, dnf, zypper, pacman, apk or softwareupdate); nothing is run automatically. "Fix this?" lets you analyze the result of updating without changing anything.
- **Supported environments**: macOS, and on Linux the releases of Debian, Ubuntu, RHEL-compatible systems (including AlmaLinux and Rocky Linux), SUSE (SLES and openSUSE Leap), Arch and Alpine for which fixed-version data exists. Releases without data (Debian 11 and older, Fedora, openSUSE Tumbleweed, derivatives other than those above) are shown as "unchecked", not as "no problem".
- **What it does not do**: it is not a complete vulnerability scan. Only entries in the KEV catalog that let a local user gain privileges are covered; vulnerabilities attacked remotely and application packages are not checked. It judges by version only, so it does not check whether the affected component is actually in use. For entries that need an extra condition (a SUID executable, or unprivileged user namespaces for regular users), a path appears only when the condition is met. For the kernel, only the running one is checked, not every installed kernel.
- **The data is bundled with the app.** Nothing is looked up over the network during an analysis. The result shows the date of the data, and warns when it is more than 45 days old. New data arrives with app updates.
- The screens and the command line were added in 10 languages (the translations are based on machine translation and have not been reviewed by native speakers).

### 0.1.4

- **Added: PathScope can now be bundled in RoamSwitch's Linux packages (deb, rpm and tarball) on Linux.** It installs a launcher entry and icons so that it opens from the application menu, the `pathscope` command, the `pathscope-gui` window and the Apache-2.0 texts. An install made by a package does not use Settings > Update; it says that updates come with that package's updates.
- **Fixed: on Linux (WebKitGTK) in dark mode, a closed drop-down kept a white background and its text was unreadable.**
- **Fixed: depending on the startup order, the text in the update section could stay as a raw key name.** It could happen when the update information arrived before the text catalog was loaded (on both Mac and Linux).

### 0.1.0 - 0.1.3 (summarized)

The contents of these releases, grouped by theme. The full text of each entry is in this file's git history.

- **Changed: even with "unrestricted", private key files and API key or password values are not sent.** Until now, choosing "unrestricted" turned off both the replacement of values and the exclusion of files such as private keys. From now on, the following are kept whatever the setting. Private key files (a renamed key, or a key pasted into a config file, is found by its content, `-----BEGIN … PRIVATE KEY-----`). API keys in well-known formats (AWS, GitHub, Slack, OpenAI/Anthropic, Google, GitLab, npm, Stripe, JWT, `Bearer`), passwords inside URLs, and values whose name means a password or key (`name=value`, `name: value`, JSON, `--name value`) are replaced with `[REDACTED]`. What "unrestricted" still turns off is the exclusion of things like password hashes and `.env`, and the guess that treats long alphanumeric strings as secrets. Because this works by names and shapes, some secrets can still be missed. （0.1.2）
- **Fixed: the German label for "unrestricted" is now "Uneingeschränkt".** The earlier "Unbegrenzt" reads as "unlimited in quantity". The settings screen now matches the wording on the website and in the EULA. （0.1.3）
- **Fixed: even in standard mode, a renamed private key or a key pasted into a config file is no longer sent.** Files were excluded only by name and location, so a key with a name such as `backup.conf` could have part of its content sent (the replacement of long alphanumeric strings does not apply to lines that contain `/`). JSON `"password": "…"` and tokens that contain `.`, such as JWTs, are now replaced too. （0.1.2）
- **Fixed: with "unrestricted", the protection against instructions planted in config files (removing invisible characters, defusing the data fence marks) was also turned off.** It is now always applied, whatever the setting. （0.1.2）
- **Fixed: the result of "Fix everything?" is shown in plain sentences instead of internal wording.** （0.1.2）
- **Added: have an LLM read your config files to find easily missed risks (LLM assist).** Files such as sudoers, cron and scripts are written in many different styles, so a program alone cannot always read them. The LLM looks for entries that involve root privileges (for example, a sudo setting that needs no password, or a file that root runs periodically). Before anything it finds is used in the analysis, PathScope checks that the line really exists in the original file. Before sending, you confirm which LLM will receive how many files. Values that look like passwords or keys are replaced with `[REDACTED]`, and files such as private keys are not sent (for a local LLM whose content never leaves your machine, you can choose "unrestricted" in Settings). Files that could not be read or were not sent are listed as "unchecked" with the reason. The LLM integration is still off by default. (0.1.1)
- **Added: the app is available in 10 languages** (Japanese, English, Korean, Simplified Chinese, Traditional Chinese, German, French, Spanish, Italian, Portuguese). It follows the OS language and can be changed in Settings → Language. The command line supports Japanese and English (`--lang=ja|en`). The translations started as machine translations and have not been reviewed by native speakers. The macOS screen names (System Settings, Privacy & Security, Full Disk Access) match the wording macOS itself uses in each language. (0.1.1)
- **Added: in-app updates on Linux.** The update is installed only after its signature is verified; updates with a wrong signature or a tampered file are refused. The Linux package (.deb) in this release is for delivering in-app updates; it is not yet offered as an installer. (0.1.1)
- **Fixed: the macOS privacy settings data (TCC.db) is now read correctly from real data**, including apps that are allowed by bundle ID. Commands in the suggested fixes are safely quoted even when the path contains spaces or symbols. (0.1.1)
- **Changed: the wording of the app and the command line is easier to understand** (the reason for each step is shown as a sentence instead of an internal name; "choke point" became "fix point", and so on). Settings is organized into tabs by function, overlapping text in the diagram is fixed, and a confirmation that explains the reason appears before opening the Full Disk Access settings. (0.1.1)
- **First release.** Bundled in the Mac 1.10.19 DMG. It analyzes, read-only, the paths by which privileges can be escalated on this machine (the routes to root or to sensitive data) and shows which places to fix first. (0.1.0)

## PersonalSOC

### 0.1.8

- **Fixed: the details of a CVE (known vulnerability) finding now show the package name and version.** The report table shows only the details, not the finding's title, so it was not clear which package a finding was about.

### 0.1.7

- **Fixed: on Linux, the drop-down lists (update interval, LLM choice, display language) had a white background, so their text could not be read in dark mode.**

### 0.1.6

- **Changed: removed the margin around the app icon and made its background transparent.** It used to come with a white margin. The rounded square now fills the whole icon on Mac, Linux and in the app window.

### 0.1.0 - 0.1.5 (summarized)

- **0.1.0**: first release of "PersonalSOC", a personal security operations center that gathers this device's logs and defense status, read-only, into a report. Findings, sources and IOCs are shown with charts; the UI has 10 languages and follows the OS language. "Check status" has your chosen LLM CLI (opencode, claude, codex, agy) investigate autonomously with read-only tools and write an audit report. LLM integration is optional and off by default. PersonalSOC itself has no network permission.
- **0.1.1**: in-app updater (Mac), which fetches version information only when you press the button and verifies the signature before installing. Removed the fixed "Response" section from reports and fixed chart legends and axis labels overlapping in English and other languages.
- **0.1.2**: reads more from RoamSwitch's MCP (package CVE matches, active vulnerability check status, what Sensor found from outside, protections switched off, honeytoken, browser-credential and ransomware detections, recovery readiness, preserved evidence, Air-Gap). Gatekeeper denials on Mac became an optional source (off by default). The LLM command's own tools are switched off at launch where possible (`claude` starts with built-in tools and MCP off; `agy` and `codex` cannot be locked, so they need the confirmation in Settings). Fixed the XProtect check matching process names and `codex` not running in an empty temporary folder.
- **0.1.3**: an LLM reply that contains raw line breaks or invalid escapes is repaired and parsed again. The Gatekeeper source is now labelled "check the record of denials", and the screen and README state that Gatekeeper behaves the same whether it is on or off (it only reads the record).
- **0.1.4**: secret masking now also covers quoted JSON and `Authorization`, `Bearer` and `Basic` headers. Log lines can no longer close the data fence handed to the LLM using the lookalike characters `<<<` and `>>>`. Scheduled runs (Mac) work in folders with spaces or non-ASCII characters, and an app opened straight from the DMG is told to move to the Applications folder (10 languages). When an LLM command times out, its child processes are terminated too. `opencode` is no longer treated as having its tools locked, because we have not confirmed the setting takes effect, so using it requires the confirmation in Settings (the README is updated too).
- **0.1.5**: Settings is split into tabs by function (Automatic status check, LLM integration, Updates, Display language); the Updates tab appears only where updating is supported (Mac). Removed the "it contains unverified text, so please check…" note from the message shown when a report has been created (10 languages).

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

### 0.3.16

- **Fixed (data protection): the collector's retention prune could delete the records after a bad line.** A single line with invalid UTF-8 stopped the read, and `scans.jsonl` and `events.jsonl` were replaced with the shortened content, losing every later record. Only the damaged line is skipped now and the other records are kept.
- **Fixed (data protection): the collector reported success even when appending a record failed.** Only the state was saved, and the Sensor did not resend, so the record was lost. A failed append now returns a storage error and does not advance the state.
- **Fixed: after a crash in the middle of an append, the next record was glued onto the torn fragment and became unreadable** (the collector's records and the audit log).
- **Fixed (data protection): in the audit log, one line with invalid UTF-8 hid all later entries and made a sequence number get reused, and an unreadable log "verified" as empty and fine.** Only the bad line is skipped, an unreadable log counts as a failed verification, and a new chain is never started.
- **Fixed (data protection): an evidence export could come out empty, like a clean "no scans, no devices" report, when a stored file was damaged.** The export is now aborted with an error when a stored file is damaged (the IPC has a new `strict` parameter that reads strictly; the TUI shows it in 10 languages and the CLI in Japanese and English).
- **Fixed (security): the CLI's `export --out` and `scan report --out` followed symbolic links, kept an existing file's mode, and defaulted to 0644.** A symbolic link or a non-regular file is now refused (with the reason shown in Japanese or English), the file is written to a temporary file and then replaced, and the mode is 0600. Under sudo, a link planted in a shared directory could have redirected the write.
- **Fixed (robustness): a crash in the middle of `tls rotate` (the key and certificate update) can no longer leave a mismatched key and certificate that stops the Sensor from starting.** The new key and certificate are written to temporary files, checked to match, and only then put in place. At startup, an interrupted rotation is either completed or discarded so that the pair is consistent (a working pair is never replaced by one that cannot be verified). When it cannot be recovered, the Sensor stops with an error as before and keeps the files.
- **Fixed: when an older version saved a configuration or data written by a newer version, the newer fields were dropped** (after a downgrade). The configuration, trusted endpoints, scan history, device inventory, the ARP and passive baselines, the collector's per-Sensor state and the push cursor now keep unknown fields when saved (the audit log is unchanged because of its hash chain). When unknown fields are present, the keys of the configuration file are written in alphabetical order.
- **Fixed: in the TUI, overwriting a credential file (`collector-token.txt`) did not tighten its mode to 0600, and a crash while creating the identity file could stop the next start.**
- **Changed: the collector's state, `enrolled` and push-cursor files are written pretty-printed** (the content is the same).

### 0.3.15

- **Fixed (data protection): when a state file was unreadable or corrupted, it was treated as empty and saved, wiping the other data.** With a corrupted file, a change such as a pairing or a new record replaced the valid data that was left (the list of trusted endpoints, for example) with just the one new entry. This affected the list of trusted endpoints, the scan history, the device inventory, the configuration (`config set`), the ARP and passive baselines, the audit log (a corrupted line was silently dropped), the collector's per-Sensor state, and the daemon's push position. Only a missing file is treated as empty. A file that exists but cannot be read is not rewritten: a copy is kept as `<file>.corrupt-<time>` (mode 0600, the three newest), and a change fails with a clear error.
- **Fixed (security): when the list of trusted endpoints cannot be read, nobody is trusted, the file is kept as it is, and pairing is refused** (reason `sensor_storage_unavailable`). The daemon does not crash. The pairing code is used up in that case, so issue a new one after repairing the file.
- **Fixed: with a damaged private key, the TLS certificate was silently replaced and its fingerprint changed.** It now fails with an error instead (if only the certificate is missing and the key is left, it is recreated).
- **Fixed: hardening of the collector.** When a Sensor's state was damaged, a replayed push was accepted and the state rebuilt from empty; it now returns 500 and keeps the state (the overview shows "stale"). When the token file cannot be read, an empty value is no longer written and an error is shown.
- **Note: while a file is damaged, some detections stop.** With the ARP baseline, comparison and spoofing detection stop; with the passive baseline, new-device detection stops (malicious-IP matching continues). They resume once the file is repaired or deleted.
- **Changed: the new errors are shown in 10 languages in the TUI and in Japanese and English in the CLI.**

### 0.3.14

- **Added (security): control API signatures now have a v3 that is bound to the Sensor's public key.** v1 and v2 did not say which Sensor a signature was for, so an intercepted signature could be reused on another path. A new install refuses v1 (`control.allow_legacy_signatures`) and refuses v2 (`control.allow_v2_signatures`) on a plaintext connection (existing installs keep their current values). We tested that a downgrade from v3 to v2 or v1 is refused. Mac 1.10.17 and later and Linux 1.10.18 and later send v3.
- **Added (security): when pairing, the client now sends a proof of possession of its key (PoP).** Over a connection without a certificate pin, this stops someone who has a pairing code from registering another party's public key. The setting `control.require_pairing_pop` refuses a request without the proof (on for new installs, unchanged for existing ones). A wrong proof does not consume the pairing code. Mac 1.10.17 and later and Linux 1.10.18 and later send the proof, and we confirmed on a real Mac that the Sensor verifies it.
- **Changed: the defaults for a new install are stricter.** The control API TLS is required (`control.tls=required`). When the configuration file is corrupted, the previous configuration is kept.
- **Fixed (security): the local IPC is authorized per connection by the caller's uid.** Write operations and active scans are limited to root or the `roamswitch-sensor` group. `get_config` masks the webhook destination. We fixed a race where the administrator check depended on a reused PID after the peer disconnected (it now uses the uid and groups seen at connect time). A line length, a connection count and the number of pairing codes outstanding at once are now capped.
- **Fixed (security): added protections against load on the control API.** A read timeout, limits on requests and simultaneous connections, a per-IP lockout, a per-key nonce limit and an expiry for pending audits. `last_addr` is updated only over TLS, and a change is recorded.
- **Fixed (security): hardened the collector.** To stop an endless pre-authentication body read, all connections share a read budget (32 MiB) with a per-body deadline (20 s), and a stalled, timed-out or short body counts as a failure for the source IP. We also added per-IP connection limits, trusted-proxy support, replay rejection, a push limit, a default retention, streaming body reads, and a refusal of new `http://` settings.
- **Added: a v2 of the push signature that is bound to the receiving collector.** It stops a replay to another collector. The operator sets `--collector-id` (or the environment variable `ROAMSWITCH_COLLECTOR_ID`) on the collector and `collector.collector_id` on the Sensor. `--require-collector-binding` refuses an unbound (v1) push (off by default).
- **Fixed: a failed webhook notification could put the URL, which carries a secret token, into the error text.** Only the kind of error is shown.
- **Fixed: persistence is more robust.** State files are written atomically and a corrupted one is moved aside. The private key is created exclusively with mode 0600. Control characters are stripped, and a failed append to the audit log is reported.
- **Changed: the TUI settings screen has rows for the settings above** (10 languages).

### 0.3.13

- **Audit report dates are now easy to read**. HTML and Markdown reports showed raw UTC strings such as `2026-09-19T08:00:03.415602838+00:00`. They now show this machine's local time in each language's order, with the weekday and the UTC offset (English: "Sat, 2026-09-19 17:00:03 (UTC+9)"). The "Generated (UTC)" heading is now just "Generated". CSV is meant for machines and stays in UTC as before.

### 0.2.1 - 0.3.12

- **Better network inventory** (0.2.1 to 0.2.7): always-on tracking of the network
  layout, plus extended detection (botnet/DDoS participation, DNS tunneling). An active
  ARP sweep equivalent to `nmap -sn` closed detection gaps (and a bug that dropped the
  Sensor itself from the list was fixed), and the network layout and ARP events were
  reworked to carry enough information to act on (refreshed hourly). Device notes were
  added, and TUI display bugs were fixed.
- **Audit operations features for security teams at larger organizations** (0.3.0):
  scheduled audits, diffs against the previous run, notifications (webhook and syslog),
  a tamper-evident operation log, export, retention, and a central collector that
  aggregates several Sensors. Everything is opt-in, and nothing is sent anywhere by
  default.
- **Fixed automatic updates of the CVE maps and the NSE script DB failing silently**
  under systemd's write restrictions (0.3.1 to 0.3.2).
- **Added a diff tab, an operation-log tab and export to the TUI** (0.3.4).
- **Broader active audits** (0.3.5): Elasticsearch, CouchDB, VNC, RDP and SMB added.
- **Slow ARP sweeps detected** (0.3.8): a long window notifies once 64 distinct targets are reached within 24 hours (a 2.5 s-per-address sweep fired at the 64th target). Requests for hosts known to be alive do not count toward it, and the number of tracked MAC addresses, targets per MAC and the live-host table are capped, so a flood of spoofed sources cannot grow memory without bound.
- **Repository size** (0.3.7): the apt and rpm repositories had kept every past version, so they were cut to the latest one (1.10.5 and later keep the latest three).
- **Control API TLS support, replay protection, and a fuller TUI** (0.3.9): the control API now speaks TLS 1.3 with certificate pinning (`control.tls`, default `optional`). Signed requests carry a timestamp (±300s) and a one-time value, with pairing brute force locked out per source and globally. The TUI now covers every function of the CLI and daemon (config editing, TLS management, manual pairing, event views, 10 languages). Added a bind-address setting, a switch to stop the CVE-map fetch, and a distinction between unpaired and unknown devices.
- **Pairing command guidance fixed** (0.3.10): the pairing command shown by the TUI and `sensor-cli issue-code` did not include the Sensor's own fingerprint (`--fingerprint`), so it always failed with Linux 1.9.90 and later clients. This is fixed.
- **Manual pairing screen explanation improved** (0.3.11): it now says that the fingerprint field is for the GUI (Mac) input field.
- **False-positive and alert-fatigue audit** (0.3.12): fixed 6 issues, including detections that spike in count (destination spread, destination concentration flood, malicious-destination contact, IoT behavior) sending an empty destination identity, so that the same kind of detection on another device was taken to be in cooldown and silently suppressed.

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

### 0.1.0 - 0.1.7

- **Distributed as deb/rpm packages** (0.1.0), running as a systemd service. Extended
  passive LAN visibility (opt-in) was added too.
- **Pairing moved from mDNS discovery to a pairing code** (0.1.3). mDNS works only
  within one LAN segment, broadcasts constantly, and has no strong authentication by
  default. The Sensor sits at a fixed IP and issues a one-time code (8 characters,
  expires in 10 minutes), authenticated with Ed25519 signatures. Accepting audit
  requests from clients and making the nmap NSE supplementary scan always-on came in
  the same release.
- **Audit status badges for paired endpoints, and viewing the latest report** (0.1.4).
  Manual pairing was removed in favor of the code method, and the IP address is always
  shown.
- **Fixes** (0.1.5 to 0.1.7): several audits running in parallel against the same
  endpoint; the daemon crashing on `Too many open files` and losing in-flight audits
  (the file descriptor limit is now 65536); the detailed description missing from
  audit findings.

## RoamSwitch for Linux

The Linux edition (systemd + nftables), distributed via apt / dnf / zypper
(GPG‑signed). See <https://lafine.net/linux>.

### 1.10.27

- **AccessScope 0.1.0 is now bundled.** A separate tool that finds attack attempts in web server and SSH access logs and shows the evidence. The Server Edition gets only the command (`accessscope`); the client edition gets the command and a window app (see AccessScope 0.1.0).
- **Fix: addressed the app not starting automatically at login on some desktop environments.** Looking into a report from a real machine, the `NoDisplay=true` in the autostart `.desktop` file was suspected: some environments, such as lxqt-session, treat it as a reason to skip autostart. The file already lives where the application menu never lists it, so the unneeded setting is removed. Re-checking on a real machine is still to be done.
- **Change: the MCP tool `run_package_cve_scan_languages`, when called with an empty folder, now scans the registered project folders (`pkgcve_watched_folders`).** This matches the Mac tool of the same name, so the watched folders can be used without passing a path.
- **Change: the apt and rpm repositories now keep only the newest version of each package.** Three versions used to be kept, so `apt install roamswitch=<version>` or `dnf downgrade` could roll back. To save storage that is no longer possible. If a release turns out to be defective, a fixed version will be published instead.
- The contact details in the EULA and README changed from an address that cannot receive mail to the contact form (with an email as a fallback); the terms of the EULA themselves did not change. Product-page URLs in the app, the command line, the screens and the package notes now point to roamswitch.com.

### 1.10.26

- **The bundled PersonalSOC is now 0.1.8.** The details of a CVE (known vulnerability) finding now show the package name and version (see PersonalSOC 0.1.8).

### 1.10.25

- **Copying many compressed or media files, or copying in a file manager, no longer gets the writer frozen as ransomware.** A file whose first bytes are a genuine compressed or media format (gzip, zip and its relatives, JPEG, PNG, mp4/mov/heic, xz, zstd, 7z, lz4 and so on) is left out of the burst check. Encryption destroys those first bytes, so detection of real encryption is not weakened; documents such as docx and xlsx are still tracked. File managers (Nautilus, Nemo, Thunar, Dolphin, Caja, GVfs, KDE's KIO) are now on the allowlist, like `cp`: a GUI copy is written by the file manager itself, so it could be frozen before. `.heic`, `.avif`, `.mov`, `.webm`, `.m4a`, `.rar`, `.whl`, `.lz4` and others were added to the skipped extensions. Checked on a real Linux kernel, before and after: ciphertext without a header, and `cp` run under another name, are still detected after the fix.
- **The bundled PathScope is now 0.1.6.** The added explanation is for macOS, so the Linux screens hardly change (see PathScope 0.1.6).

### 1.10.0 - 1.10.24 (summarized)

Everything in these releases, grouped by topic (Client and Server Edition unless marked). The full text of each entry is in the git history of this file.

- **PathScope bundled** (1.10.23 to 1.10.24): a separate app that works out the paths by which an ordinary user could reach root and shows where to fix first (a privilege-escalation path analysis tool) is now bundled in the Client Edition deb, rpm and tarball (and the AUR package). It opens from the application menu as "PathScope"; the command is `pathscope`. It is licensed under the Apache License 2.0, and Section 4-3 was added to the EULA. It is updated together with the RoamSwitch package, and replaces a standalone `pathscope` package of the same name if one is installed. The Server Edition does not include it (see PathScope 0.1.4). 1.10.24 checks the versions of installed packages and of the running kernel against known vulnerabilities (0.1.5).
- **Bundled PersonalSOC** (1.10.21, 1.10.22): The white margin around the app icon is gone (see PersonalSOC 0.1.6). On Linux, the drop-down lists no longer have a white background that made their text unreadable in dark mode (0.1.7).
- **Detections and features added** (1.10.0, 1.10.7, 1.10.11): DNS tunneling and exfiltration detection (only the host's own DNS queries; name resolution is never blocked). A forensic evidence bundle (with a SHA-256 manifest) when containment fires. Honeytokens. The age of the last proven vulnerability check (`roamswitch vuln-status`) and a mapping of diagnostic items to NIST CSF 2.0 and CIS Controls v8. Detection of LockBit-style partial encryption (16 of every 32 bytes, 1.10.7). Detection of the ransomware-recovery snapshots being deleted or thinned by anything other than RoamSwitch or the known managers snapper and timeshift (T1490, 1.10.11).
- **Honeytoken and evidence-bundle fixes** (1.10.4, 1.10.5, 1.10.8): so that real tools are not broken, the AWS decoy uses a separate profile name and the Docker decoy a non-existent registry name. Mode is 0600, and access by OpenSSH and by RoamSwitch itself is not flagged (1.10.8 also fixed a false positive from RoamSwitch's own process). The 1.10.0–1.10.4 packages did not include `roamswitch-honeytokens` and `roamswitch-incident-capture`, so decoys and evidence bundles never ran. 1.10.5 ships both in the client and server packages, and CI fails a build that lacks them.
- **Isolation (Air-Gap) and host defense** (Server Edition, 1.10.5): fixed host isolation cutting the management SSH it should keep, port 22 being opened even with `preserve_ssh_on_isolation=false`, and the operator's acknowledgement (`roamswitch server ack`) being ignored. Evidence is now collected before blocking on more paths, and the settings `honeytokens_enabled` and `harden_userns_enabled` were added.
- **Security fixes** (1.10.4–1.10.7): state-changing IPC can be called only by root or a user with a local login session. The root daemon no longer reads `~/.config/roamswitch/config.json` without checking ownership or follows symlinks when writing. The daemon runs inside a systemd sandbox. `rustls` was updated to 0.23.45 (RUSTSEC-2026-0285). Fixed: treating a gateway MAC change alone as "moved to another network", isolation release trusting the current gateway unconditionally, and the ransomware burst detector excluding processes that carry an allow-listed name. Link-guard packet parsing runs in a sandboxed child process outside root.
- **Malware detection** (1.10.0–1.10.6): fixed a fallback hiding `clamdscan --fdpass` failures, a USB scan treating exit code 2 (failed to run) as malware and running `umount -f`, and the daily update not being able to update ClamAV signatures. An EICAR self-test of the detection path was added. fanotify now uses permission events only for execution.
- **Network, DNS, Docker, link guard** (1.10.1–1.10.4): DNS enforcement no longer flushes the DNS cache every 3 seconds (it runs only when the state changes). The Docker protection self-heals every 60 seconds. The link guard's packet wait and queue length were revised, and it reassembles the ClientHello from TCP sequence numbers. An option to block UDP/443 (QUIC) was added (`linkGuard.blockQuic`, off by default). Fixed: a `clamav.net` false positive in DNS tunneling detection, the Sensor control port (50543) being blocked permanently on a co-located host (Server Edition), and an endless repeat of notifications for programs that bind a different UDP port on every restart.
- **Notifications, diagnostics, UI** (1.10.3, 1.10.4, 1.10.9, 1.10.11): identical notifications are only recorded in the history for 10 minutes. On Arch-based systems the "automatic security updates" check is "not applicable". Fixed: port blocking reporting success even when nftables was not updated, Wi-Fi safety always being "unknown" on iwd systems (RoamSwitch OS), guidance for Validity fingerprint sensors, and tabs cut off at 1280 px. The tray language switcher gained Italian and Portuguese, and the ransomware-recovery screen now describes its real scope (the logged-in user's home only, 1.10.11).
- **Recovery, uninstall, upgrade** (1.10.7, 1.10.10): a dedicated tab in the main window, and `roamswitch emergency-restore` plus a tray menu entry undo isolation, firewall, gateway pinning, DNS and connection tracking. `roamswitch uninstall` does this first and then removes the decoys and files it added. The license signing key was regenerated (both old and new public keys are accepted). Three GUI upgrade problems were fixed: stopping on one unreachable mirror, reporting success when nothing changed, and not restarting the app. The restore path is now a real file picker (1.10.10).
- **PersonalSOC bundled** (1.10.14): a separate app that gathers this machine's logs and defense status read-only into a report is now bundled in the packages (deb, rpm, tarball, AUR). 10 languages, Apache-2.0. Its LLM integration is optional and off by default. The Server edition does not include it.
- **Packages, tests, other** (1.10.5–1.10.10): apt and rpm keep the latest three versions of each package. The pentest suite was re-run (Server 19/19, Client 11/11). External commands called by the resident daemon now have a time limit (a `bluetoothctl` that did not answer for 1 hour 41 minutes on a system without bluetoothd stalled IPC). RoamSwitch OS hides the uninstall entry points. The Server investigation-agent report now includes the host name and IP address.
- **Activity log and false-positive audit** (1.10.13): a Security Activity Log tab to search and filter past detections (ARP, FIM, port anomalies, recorded process execution, notification history and more). An alert-fatigue audit fixed 44 findings in the desktop edition and 7 in the server edition: lockfile monitoring's "unreadable" verdict is no longer treated as tampering, notifications for link protection, isolation-release checks, gateway-MAC changes and exec detection now carry more to judge them by (the triggering signal, old and new MAC, the download source), and the server edition's Docker notification is deduplicated.
- **Resume from suspend, diagnostics, feed** (1.10.12): fixed a false "protection is not responding" alert right after resuming from suspend (a gap far beyond the monitor loop's interval is treated as a resume, and every guard's timestamp is reset). Also fixed the order and explanation of the active-verification status, a UDP-listener notification record that grew without limit, and the popular-npm-packages feed's manifest URL not matching the published file name, which showed a false SHA-256 mismatch warning.
- **Decoys and notification tuning** (1.10.15): the honeytokens now include `~/.pypirc` and `~/.env.backup`. Log-audit notifications are limited to security-relevant anomalies such as authentication failures and malware detections. For about 25 minutes after a Sensor audit is requested, the warning is worded calmly (Client edition).
- **Security fixes** (1.10.16 to 1.10.19): when the daemon placed decoys (canary files, honeytokens) in a user's folder it followed symbolic links, which could lead to privilege escalation; it now creates them without following links. `get_canary_status` returns only the caller's own entries to non-admins, `kill_process` refuses processes the caller does not own, an IPC line is capped at 1 MiB and non-root users at 16 concurrent connections. Event-forwarding file output is limited to locations only root can write. Values passed to DNS settings and rfkill are validated, ClamAV and YARA scans validate the path and put `--` before it. Webhook `curl` is limited to http and https, and a new option (`webhook_block_private_addresses`, off by default, with DNS-rebinding protection) refuses internal addresses. The quarantine store moved to a root-only `/var/lib/roamswitch/quarantine` (migrated automatically from the old location at start-up), and restore and delete verify the store path and ownership.
- **Blocking file execution (fanotify)** (1.10.18): it was not effective when run as a systemd service because executions never reached the daemon. It now watches per filesystem, and we confirmed under the real service that a detected suspicious script is refused. Scan exclusions can no longer be bypassed by spoofing a process name or matching part of a path.
- **Data protection and integrity** (1.10.16 to 1.10.19): firewall profile switches are atomic in one batch (also for Air-Gap), so rules can no longer disappear midway or on failure. Concurrent updates to the pending approvals record (`approvals.json`) no longer lose data. When the trusted-Sensor file cannot be read, other pairings are no longer erased by overwriting with an empty list; a copy is kept (`<file>.corrupt-<time>`, 0600, latest 3) and the operation fails with a clear error. The audit-results file got the same protection.
- **Secret masking in the execution record** (1.10.19, same rules as Mac): command lines in the execution record hide `mysql -ppassword`, `sshpass`, `docker login -p`, sensitive flags, URL credentials, bearer and basic headers, known API key and token formats, and cryptocurrency private keys and seed phrases (only when the checksum matches). Wrappers such as `sudo` and `env`, interpreters such as `sh` and `python`, and the contents of `sh -c '…'` are seen through. It covers MCP, the CLI, the TUI and incident evidence, and search runs on the masked text.
- **Working with Sensor** (1.10.16 to 1.10.19): pairing sends a proof of key possession (PoP). Control-API signature v3 (bound to Sensor's public key) is sent and never downgraded to v2 once it has worked. The reason "Sensor's own storage file is corrupt, so pairing is impossible" returned by Sensor 0.3.15 is shown in 10 languages. The GUI no longer says "removed" when removing a Sensor failed. The calmer warning during a Sensor audit returns to the normal warning as soon as the report arrives.
- **Ransomware detection and notifications** (1.10.18): a stale verdict left over when a process ID (PID) was reused could freeze a legitimate `cp`; the process start time is now checked as well. A process released with `roamswitch frozen resume` is not frozen again for 600 seconds. The notification for a failed isolation shows the reason in 10 languages when it was refused for lack of a login session. `roamswitch forward status` puts a translated heading before the reason a forwarding target was refused.
- **OS Hardening** (1.10.18): fixed the "do not use Secure Boot" checkbox missing when re-enrolling TPM2, and the contradictory fingerprint (Validity 138a:0090) guidance.
- **Bundled PersonalSOC** (1.10.16 to 1.10.20): 0.1.2 to 0.1.5 in turn (see each PersonalSOC release). In 1.10.20, Settings is split into tabs by function and the message after a report is created is shorter (0.1.5).

### 1.9.39 - 1.9.94 (summarized)

Everything in these releases, grouped by topic (Client and Server Edition unless marked). The full text of each entry is in the git history of this file.

- **Isolation (Air-Gap) reworked** (1.9.90, 1.9.91): an isolation caused by a high-confidence detection (a tampered canary, suspected ransomware, a critical eBPF detection) no longer releases itself on a timer. After a cap (1 hour by default) without a verified-cleared re-check it moves to a "degraded" mode that never re-opens on a timer, and it is released only by `roamswitch emergency-restore`, the GUI, the server's `roamswitch server ack`, or a verified-cleared re-check. Detections prone to false positives still release on the short timer. Connections that were already open no longer survive an isolation (the server keeps only the maintenance SSH and allowed IPs; the client's degraded mode allows loopback only). The ARP re-check sends a direct ARP request when the gateway has no neighbour entry (`arp_recheck_active_probe`), so ARP-triggered isolations stop getting stuck.
- **Process-execution record, forwarding and Server TUI** (1.9.90): a continuous record of which programs ran, with parents, hashes and containers, on the machine only (default 200 MB / 14 days, hash chain), and seven notify-only correlation rules; event forwarding (off by default: syslog, CEF, JSON Lines, HMAC-signed webhook); and a full-coverage TUI for the Server Edition (`roamswitch server tui`). Also `--json`/`--export`, and a notification when another program opens credential files (off by default).
- **Containers and network** (1.9.43, 1.9.44, 1.9.90): the Docker firewall-bypass guard works with Docker's native nftables backend and IPv6 and heals itself within a minute; Container Exec Guard (Server) marks each container's rootfs with fanotify's notify-only `FAN_OPEN_EXEC` and captures even a self-deleting attacker binary; the Egress Guard covers container traffic; per-process CPU-saturation detection; a wider FIM scope (`authorized_keys`, `ld.so.preload`, new files in watched directories).
- **Investigation agent** (Server, 1.9.45 to 1.9.56): automated first-pass triage of eBPF, FIM and lockfile detections (false-positive likelihood, reasons, next commands, Markdown report) and an optional, off-by-default handoff to an agentic CLI (Claude Code, agy, Codex CLI, OpenCode, custom), skipped right before a host isolation; fixes for it never working under root, for the sudo wrapping, and for the recursion where an agent's own investigation looked like a new incident.
- **Security fixes** (1.9.84 to 1.9.90): a local user could send a forged critical event to Falco's socket and trigger a full Air-Gap (the socket is now mode 0600 with a peer-UID check); look-alike names such as `sshd-x` escaped the protected-process list; allowlist entries could be bypassed by renaming a process (entries can be bound to the real executable with `--exe`); Telegram and LINE tokens and webhook URLs were visible in the process list; the port-scan auto-block could be abused with a forged source address (it now refuses only new inbound connections, never blocks the gateway, DNS resolvers or the host's own addresses, and checks the SYNs' source MAC); a flood of forged SYNs could push scan records out of the log (200 per second limit first, and a notification when detection is saturated); a scan claiming the Sensor's address escaped the block (the Sensor's MAC is recorded at pairing); unknown-listening-port detection could be evaded with a system daemon's name (`/tmp/sshd`) or by an interpreter script from a temporary directory; the dev-server block rules were briefly lifted while being re-applied; log-frequency detection went blind after one large burst; the root daemon created root-owned directories under `~/.local`.
- **Port scans, listeners and vulnerability checks** (1.9.39 to 1.9.94): stronger port-scan detection (memory bounded under a flood, a 24-hour window, IPv6 per /64), unknown-listening-port detection for non-wildcard binds and temporary, in-memory or deleted binaries, UDP listeners from interpreters, alerts that name the real program (`wsdd (python3)`); active checks for Elasticsearch, CouchDB, Jenkins, VNC, RDP (NLA) and SMB (SMBv1, signing); CSV export that explains safe and inconclusive results, scan IDs and locked logs; typosquat detection for npm packages (Pro); the kernel-CVE check no longer flags distro backports that only bump the ABI number; the nmap NSE scan is always on and the CVE maps update monthly.
- **RoamSwitch Sensor** (1.9.55 to 1.9.91): pairing moved from mDNS to a pairing code; an active audit can be requested from a Sensor and its result fetched later (MCP tool `get_sensor_audit_results`); TLS 1.3 with certificate pinning (`roamswitch sensor pair --fingerprint`, `sensor repin`; new pairings need Sensor 0.3.9 or later, existing plaintext pairings keep working with a warning); the setup wizard offers a preset when a Sensor runs on the same host; a failed pairing now says why (30 seconds of waiting, likely causes, a command for the Sensor host).
- **Network control review** (1.9.71 to 1.9.72, 1.9.85 to 1.9.87): firewall settings not re-applied right after a daemon restart, services stopped by shared-service control never restored, and a manual security-level change racing the daemon's patrol; ARP false positives triggering Air-Gap under VirtualBox NAT and in NAT environments; the Frag Gap mitigation (denying user namespaces) became opt-in (`auto_enable_userns_restriction`) because it broke browsers, Flatpak, Electron and rootless containers on the client.
- **Notifications, screens and languages** (1.9.40 to 1.9.94): every notification is in ten languages (FIM, lockfile, eBPF, kernel exploit, all Server alerts, the second-instance message, health-check lines), and the Server Edition's language is set with `language`; the notification history no longer freezes (bodies capped at 2,000 characters, newest 200 drawn); "suspected malware" notifications no longer repeat for a file you keep saving; screens split into tabs (package CVE scan, Ports & DevIsolator); the onboarding wizard defaults to standard protection instead of "open"; several GTK layout, CSV-header and translation fixes.
- **Packaging and updates** (1.9.75 to 1.9.88): the periodic nmap NSE database update and the CVE map updates were failing silently in systemd's sandbox or held back by a shared marker; RoamSwitch did not start at boot on some systems; the health check advised apt on Arch-based systems; an administrator password was requested every time Air-Gap was released; and the apt and rpm repositories held every past version until the publishing job failed, so they were cut to the latest version (1.10.5 keeps the latest three).

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

## 1.10.28

- **AccessScope 0.1.0 is now in the DMG.** It sits next to RoamSwitch.app. A separate app that finds attack attempts in web server and SSH access logs and shows the evidence (see AccessScope 0.1.0). You can update it from inside the app (Settings → Update).
- **Fixed the MCP `get_security_report` always reporting the gateway ARP lock as "disabled", even when it was on.** The report was generated without the ARP lock setting. `get_guard_status` already returned the correct value.
- **Change: the links to the purchase page, help and the MCP knowledge base inside the app now point to roamswitch.com.**

## 1.10.27

- **The bundled PersonalSOC is now 0.1.8.** The details of a CVE (known vulnerability) finding now show the package name and version (see PersonalSOC 0.1.8). You can update from inside the app (Settings → Update).

## 1.10.26

- **Fixed a false ransomware detection when copying many compressed files.** When a lot of files were copied, already-compressed files such as `.gz` and `.jpg` (which have high entropy by nature) were counted as "encrypted file writes", and this could even trigger the full network cut-off (air-gap isolation), naming Spotlight's indexer as the culprit. A file whose first bytes are a genuine compressed or media format (gzip, zip, JPEG, PNG, mp4 and so on) is now left out of the check. Encryption destroys those first bytes, so detection of real encryption is not weakened. Folders such as `.venv`, `node_modules` and `.git` are skipped, and Spotlight's worker processes (`mdworker_shared` and the like) and any process started from macOS's own locations (`/System`, `/usr`) are treated as safe.
- **Fixed the exit node reconnecting and disconnecting about every 40 seconds after a Tailscale disconnect.** While the network service reconnected after the disconnect, the gateway's MAC address could not be read for about 40 seconds; the 30-second grace period ran out first and the network was judged to be an unknown one (Lockdown). So even at a Standard-protection home network, it briefly went to Lockdown and the VPN connected, then disconnected when the MAC came back, and reconnected again, with traffic stopping on and off. The grace period is now 90 seconds and ends as soon as the gateway is back.
- **Added protection against the app quitting after an isolation is released.** When the app reached its limit of open files (256), starting ClamAV raised an exception and the app quit. The crash report does not prove that this limit was the cause. The limit is now raised, and the pipe for ClamAV's output is always closed, even when the launch fails.
- **The bundled PathScope is now 0.1.6.** When PathScope itself is the subject of a finding, an explanation is added (see PathScope 0.1.6). If 0.1.0 or later is already installed, you can update from inside the app (Settings → Update).

## 1.10.0 - 1.10.25 (summarized)

The contents of these releases, grouped by theme. The full text of each entry is in this file's git history.

- **Bundled PathScope** (1.10.22 to 1.10.25): Even with "unrestricted", private key files and API keys are no longer sent (see PathScope 0.1.2). 1.10.23 fixes one German label (0.1.3). 1.10.24 fixes the update section text and the unreadable drop-down text on Linux, among other things (0.1.4; the Mac screens hardly change). If 0.1.0 or later is already installed, you can update from inside the app (Settings → Update). 1.10.25 adds checking installed software versions against known vulnerabilities (0.1.5).
- **Privileged helper hardening** (1.10.5): the helper now runs inside a sandbox from launch and self-checks it. It only talks to the genuine app, and Mach-O, `eslogger`, `tcpdump` and Sensor traffic are parsed outside root. Snapshot restore runs with the user's own privileges.
- **Quarantine and port scans** (1.10.5, 1.10.6): ARP-spoofing quarantine is lifted automatically once the cause is confirmed gone. Fixed quarantine release trusting a spoofed gateway and ARP pinning locking in a forged MAC. Automatic port-scan blocking now verifies the source MAC, and IPv6 scans are detected. A manual quarantine that failed no longer keeps showing "quarantined".
- **Ransomware defense and recovery** (1.10.0 to 1.10.8): added generic entropy-based detection and reworked decoy files so they no longer break real tools. "Ransomware Recovery" lets you pick deleted files from snapshot contents, and detects deletion of recovery snapshots by a third party. Added a separate "Recovery and Uninstall" menu.
- **Tailscale and VPN** (1.10.1 to 1.10.5): the Exit Node is now checked against the real OS route rather than tailscaled's self-report. VPN tool upgrades are announced, and a pinned folder with files outside the manifest is rejected.
- **Link guard and download guard** (1.10.1): fixed brand-impersonation (homograph) detection that never worked for Apple and PayPal.
- **Notifications and UI** (1.10.0 to 1.10.9): identical notifications stay silent for 10 minutes (history keeps them all). Fixed a sound with no banner. Added explanations and confirmations when toggling features, showed block state in the exposed-port list, and separated "cannot verify" from "failed" in the overall diagnosis.
- **Security fixes** (1.10.4, 1.10.5): Sensor control traffic never falls back to plaintext. The license signing key was rotated (both old and new public keys are accepted). Out-of-range settings (ports, block durations) can no longer break firewall rule rebuilds.
- **Privileged-helper resource leak and busy loop** (1.10.10, 1.10.11): fixed pipes for external-command output not being closed, so open file descriptors reached the limit (256) and the app showed "helper not connected"; the firewall and DNS being rewritten roughly every 2 seconds; the helper possibly stalling on large output; and the gateway pinning being deleted and re-added on every re-evaluation even when already pinned.
- **NDP pinning and diagnostics** (1.10.10, 1.10.11): pinning the IPv6 router's NDP entry did not actually work (`ndp -s` without an interface returns exit code 0 but does not pin). It now pins with `fe80::…%en0` and verifies afterwards. Also fixed: critical-file tamper monitoring reporting "deleted" for a file that was merely unreadable for a moment because of a race, and the ordering of the "proven vulnerability check" status.
- **Activity log and false-positive audit** (1.10.12): a Security Activity Log screen to search and filter past detections. An alert-fatigue audit fixed 27 findings: the ransomware emergency-containment banner now names the affected file and the suspected process, ClickFix protection only notifies when a command matches a known installer's pattern, the risky-Docker-container notification has a 24-hour cooldown, link protection states its triggering signal, and the Pickle-format AI model download warning shows where the file came from.
- **PersonalSOC bundled** (1.10.13): a separate app that gathers this machine's logs and defense status read-only into a report is now bundled in the DMG. 10 languages, Apache-2.0. Its LLM integration is optional and off by default. It is not updated by the in-app updater (Sparkle) but by a new DMG (from 0.1.1 it also has its own updater).
- **PersonalSOC in-app updater and more** (1.10.14): PersonalSOC got an in-app updater (Mac): it fetches the latest version information only when you press "Check for updates" in Settings, and verifies the signature before installing. The fixed "Response" section was removed from the reports, and chart legends and axis labels that overlapped in English and other languages were fixed.
- **Link guard and threat feed** (1.10.17): hostnames with a trailing dot (`evil.com.`) no longer slip past (they are normalized before the decision). The privileged helper now verifies the threat feed's signature before publishing it; before, a program running as the same user could empty the feed to disable the link guard or add hosts. When verification fails the previous feed is kept and protection is not removed, and a swap to a feed older than the recorded manifest is refused. A TLS ClientHello split across several records is now inspected up to 16 KB.
- **Quarantine and malware scanning** (1.10.17): a scanned file name containing line breaks and a fake detection line could make RoamSwitch quarantine an arbitrary user file; only the detected path is now scanned again before quarantine. Scans no longer hang on large output.
- **Secret masking in the execution record** (1.10.17 to 1.10.18): MCP execution-record search runs on the masked content, so secrets in command lines cannot be guessed from search hits, and the app itself applies output masking and the search rate limit. Masking now covers API keys such as `sk-svcacct-`, GitHub, GitLab, npm, Slack and Google tokens, `mysql -ppassword`, `DB_PASS=` and more. In 1.10.18 wrappers such as `sudo`, `env` and `nohup`, interpreters such as `sh`, `python`, `ruby`, `perl` and `node`, and the contents of `sh -c '…'` are seen through so the real command's rules apply. The integrity chain detects rewriting of a sealed segment and deletion of the oldest segment.
- **Data protection and state saving** (1.10.17 to 1.10.18): state saving (kill switch, port protection, Sensor pairing and more) is atomic, so an interruption cannot restore a state with the kill switch off. Fixed the stored endpoint being overwritten when a WireGuard import failed, and traffic staying blocked when `wg-quick up` failed and the previous kill switch was not restored. When the trusted-Sensor list cannot be read, other pairings are no longer erased by overwriting with an empty list; a copy is kept in `trusted_sensors.json.corrupt-<time>` (0600, latest 3) and the operation fails with a clear error (shown in 10 languages).
- **Working with Sensor** (1.10.17 to 1.10.18): pairing sends a proof of key possession (PoP). The control signature version is remembered at the highest confirmed level and is not downgraded on connections without a pinned certificate. The reason "Sensor's own storage file is corrupt, so pairing is impossible" returned by Sensor 0.3.15 is shown in 10 languages. The calmer warning during a Sensor audit returns to the normal warning once the report arrives (1.10.16).
- **Other fixes** (1.10.17): SSH remote-login state detection, DNS restore (disabled services and the like), resuming port-scan detection, and symlink handling in the process-execution record's plist check.
- **Decoys and notifications** (1.10.15): added `~/.pypirc` and `~/.env.backup` as decoys (honeytokens). A real access to a decoy places and watches one related decoy (the chain stops after one step). The process-execution record (Pro) gained a rule that detects commands naming a decoy file directly (11 rules). Log-audit notifications are limited to security-relevant anomalies such as authentication failures and XProtect detections. Warnings in the roughly 25 minutes after requesting a Sensor audit use calmer wording. Full Disk Access guidance was unified (the permission is decided by "RoamSwitch" in the System Settings list).
- **Bundled PersonalSOC** (1.10.15 to 1.10.21): 0.1.2 to 0.1.7 in turn (see each PersonalSOC release). In 1.10.21, the unreadable drop-down text on Linux was fixed (0.1.7; the Mac screens do not change). In 1.10.19, Settings is split into tabs by function, the message after a report is created is shorter, and the white margin around the app icon is gone (0.1.6).
- **Bundled PathScope** (1.10.19 to 1.10.20): 0.1.0 and 0.1.1 (see each PathScope release). In 1.10.20, 0.1.1 added reading config files with an LLM to find risks, 10 languages in the app, and in-app updates on Linux.

## 1.9.6 - 1.9.54 (summarized)

Everything in these releases, grouped by topic. The full text of each entry is in the git history of this file.

- **Isolation (Air-Gap) reworked** (1.9.52, 1.9.23): what triggered an isolation decides how it ends. A tampered ransomware decoy, a confirmed XProtect detection and a manual isolation chosen from an ARP warning are "high confidence"; the rest (ClickFix, port anomalies, and so on) are "low confidence". Low confidence releases by itself after 10 minutes. High confidence does not: full isolation continues up to a limit (1 hour by default), then releases if the cause is confirmed gone, and otherwise moves to a "degraded mode" that keeps new connections blocked and never opens by time. Connections already open are cut when the isolation starts, and the state survives a helper restart. The Wi-Fi radio turned off by an isolation now comes back after an app crash or a restart (an independent watchdog, 1.9.23). (In 1.9.52 an isolation caused by ARP spoofing was not released automatically; 1.10.5 changed that.)
- **Ransomware** (1.9.50, 1.9.51): "Ransomware Recovery" (Pro) takes APFS local snapshots every 6 hours by default (off, 1, 3, 6, 12 or 24 hours), takes one at detection time, and pauses pruning for up to 7 days so the last generation before the encryption stays; recovery is manual, file by file, into `~/RoamSwitch-Recovered/`, never overwriting current files (needs Full Disk Access for the helper). The read-only MCP tool `get_ransomware_recovery_snapshots` lists the snapshots. The time from a decoy being tampered with to the emergency cutoff went from minutes to about 2 seconds (a code-signature check ran for every line of the open-files list).
- **Process execution recorder** (1.9.52, Pro): records process starts on this Mac only, with macOS's own `eslogger` (off by default, needs Full Disk Access), in a tamper-evident log; nothing is blocked. Seven behaviours notify (a browser, Office or mail app starting a shell; an unsigned binary run from a temp folder or with the quarantine flag; a download piped into a shell; `osascript` with base64 or eval; running a file right after its quarantine flag is removed; an unsigned binary started from a fresh launch agent; a non-Apple parent reading a keychain secret). Banners only for high severity and at most once per kind every 10 minutes; "Allow this program" allows one keychain item. MCP tools `search_exec_events` and `get_process_tree`.
- **Port scans and unknown ports** (1.9.32, 1.9.44 to 1.9.49, 1.9.54): automatic detection and 10-minute blocking of nmap/masscan-style scans (Pro); the block cannot be abused with a forged SYN claiming the gateway's address (only new inbound TCP is refused, and the gateway, DNS resolvers and the Mac's own addresses are exempt), detection no longer stops after start-up (`pflog0`), and a flood of forged SYNs can no longer fill pf's state table. Listeners of root programs are now seen through the privileged helper and read through libproc (about 2.4 ms against 16 ms for `lsof`, every 2 seconds); a signed executable swapped for an unsigned one with the modification time restored is noticed; UDP listeners from interpreters or unsigned programs are reported; alerts name the real program behind `python3` or `node`.
- **Active vulnerability checks and logs** (1.9.44, 1.9.53): unauthenticated Elasticsearch, CouchDB, Jenkins and VNC, SMBv1 and SMB signing were added; the CSV export explains safe and inconclusive results correctly, and every scan has an ID and a locked log.
- **RoamSwitch Sensor** (1.9.32 to 1.9.37, 1.9.52): mutual pairing moved from mDNS to a pairing code; an active audit can be requested from a Sensor and its result fetched later (MCP tool `get_sensor_audit_results`); with a pinned certificate fingerprint everything runs over TLS with Sensor 0.3.9 or later; a crash of the privileged helper on every successful pairing was fixed.
- **Supply chain and secrets** (1.9.27 to 1.9.30): dependency-lockfile tamper monitoring, install-script inventory, npm signature and provenance checks, the `roamswitch-npm` wrapper that runs installs in a network-denied sandbox, typosquat detection by edit distance, and detection of leaked crypto-wallet seed phrases and private keys (checksum-verified). Pro.
- **Log audit and notifications** (1.9.6 to 1.9.26): notification history for the past 7 days; Automatic Log Audit (Pro) scanning hourly for new patterns and frequency spikes, with each template compared against its own history; ClickFix-style commands on the clipboard (including the Script Editor pivot). Many false positives were removed (CoreAudio, loginwindow, `PersistentAppsSupport`/`BTMManager`, `CFPasteboardRef`, pointer addresses), notifications explain in plain language whether action is needed, EICAR test hits no longer raise a notification, and the log-audit window's cards became clickable.
- **Critical Path FIM** (1.9.16, Pro): SHA-256 baseline monitoring of files such as `/etc/sudoers`, SSH configuration, `/etc/hosts` and root's `authorized_keys`.
- **Reports that assumed success** (1.9.19): four items that reported success without confirming anything (automatic dev-server port blocking, malware-quarantine moves, the "macOS Accessory Connection Protection" check that was hard-coded to pass, Critical Path FIM helper-connection failures) now show the real outcome.
- **Updates and languages** (1.9.26, 1.9.34 to 1.9.43): the privileged helper is reliably restarted on update; warning bursts and a false "/etc/hosts tampered" warning right after an update were fixed; update prompts bring the app to the front; shared-service stop/restore checked `launchctl` exit codes; Link Guard's homograph detection and the ransomware guard's MITRE ATT&CK ID compared translated strings instead of a language-independent value, which broke them in most languages other than Japanese, English and French. CSV headers, the package-CVE tabs and several texts were fixed in all 10 languages.

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
