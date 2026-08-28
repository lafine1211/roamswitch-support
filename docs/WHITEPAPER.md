# RoamSwitch Architecture & Security Whitepaper

> This document explains what privileges RoamSwitch runs with and what it does at that boundary. It contains no marketing language; everything stated here can be verified against the shipping app binary and its actual behavior.

**Version** v1 (first edition) · **Covers** RoamSwitch 1.4.7 (build 21) · **Requires** macOS 13.0+ / Apple Silicon · **Published** 2026-08-28 · **Team ID** GV76B6G4YU

*Canonical (rendered): <https://lafine.net/security.en.html>. This Markdown mirror exists for its Git history; the content is identical.*

## §1. About this document

RoamSwitch is a menu-bar app for the Mac. Depending on how much you trust the network you are currently connected to, it automatically switches the macOS firewall, sharing services, AirDrop, and DNS. It also watches for ARP spoofing, ports open to the outside, USB storage, and ransomware-like encryption activity, and when it detects something dangerous it will go as far as cutting off traffic with the packet filter (`pf`) — an emergency air-gap.

In other words, RoamSwitch installs a root-privileged daemon and, if it wanted to, could stop all network traffic on the Mac. It is built by one person, and "please trust me" is not enough to justify that privilege. So instead, this document explains the design in a form you can verify.

### Who this is for

- Engineers deciding whether to install it
- Security researchers and journalists who want to understand the internals before a review or an article
- Security staff at partner companies evaluating an internal rollout or OEM bundling

### What this document does not cover

It does not go into detection-threshold tuning, false-positive statistics, or UI walkthroughs. What it explains is four things: **privileges, process boundaries, data flow, and cryptography**. The feature specifications themselves are in the bundled MCP resource `roamswitch://docs/features` and in the in-app help.

### What is disclosed, and how far (disclosure policy)

This document is written on the assumption that an attacker already has the distributed binary. Every endpoint URL, identifier, file path, XPC protocol, and embedded public key that appears here can be pulled out of the shipping `RoamSwitch.app` in a few minutes with `strings`, `codesign -d`, or a traffic proxy. Writing them down here therefore gives an attacker nothing new. The only thing it advances is a reviewer's understanding.

On the other hand, server-side implementation that cannot be seen from the binary — rate-limit thresholds, keys, admin endpoints, the DB schema, the Firebase project layout — is not included. The OEM and partner integration design is also out of scope here and is covered in a separate internal document. "What you can learn by observing the client" is the disclosure line for this document.

> **Note**
>
> This document corresponds to the source for the version noted at the top. Where behavior changes in a later version, the document is revised and the version number and target build are updated. If you find a discrepancy between the text and the code, please let us know at `lafine.net/contact.html`.

## §2. Components and the trust boundary

`RoamSwitch.app` is made up of three executables. Only one of them is privileged; the other two run with login-user rights. All three ship with Hardened Runtime enabled, Developer ID signed, and notarized.

_Diagram: RoamSwitch's components and trust boundary (MCP client → MCPServer / RoamSwitch.app ⇄ Helper(root) → system binaries)._

_* MCPServer does not connect to the app itself; it reads the shared preferences domain and the monitoring modules directly (§8)._

**Privileges and role of each component**

| Executable | Privilege | Can do | Cannot do |
| --- | --- | --- | --- |
| RoamSwitch .app | Login user | Monitor network state, run diagnostics, draw the UI, call the helper over XPC, change AirDrop via `defaults`, launch ClamAV (optional) | Directly operate the firewall, pf, or system daemons (all of this goes through the helper) |
| RoamSwitch Helper | **root** | Only the operations listed in `HelperProtocol` (§3 table): firewall/stealth, load/unload of the sharing daemons, applying the pf ruleset, changing DNS, sending signals to processes | Anything else. There is no interface for running arbitrary commands. It has no network-send entitlement either |
| RoamSwitch MCPServer | Login user | Read and format diagnostic values, search the local knowledge base; results are returned to the client over stdio | Change settings, toggle lockdown, isolate a port, eject a device. It opens no socket. It sends nothing over the network |

### Entitlements and signing

- All three targets have `ENABLE_HARDENED_RUNTIME = true`.
- App Sandbox is disabled (`com.apple.security.app-sandbox = false`). The helper's and MCPServer's entitlements are empty dictionaries.
- Distribution builds are Developer ID Application signed, Apple notarized, and stapled (§10).

> **Design trade-off**
>
> App Sandbox is not used. RoamSwitch needs to read the hardware UUID from IOKit, use CoreWLAN and DiskArbitration, enumerate other processes' listening sockets (`lsof`), open an XPC connection to a LaunchDaemon, and spawn system binaries. None of this is possible inside the sandbox, so it is left disabled.
>
> Four things compensate for that. First, Hardened Runtime. Second, Developer ID signing and notarization. Third, only one executable runs as root — the helper — and what that helper can do is fixed and enumerated (the §3 table). Fourth, connections to the helper are restricted by code signature (§3).

## §3. The privileged helper

### How it is registered

The helper is registered as a LaunchDaemon using `SMAppService.daemon(plistName:)`. The plist embedded in the app (`Contents/Library/LaunchDaemons/com.tetsuharu.RoamSwitch.Helper.plist`) declares only `Label`, `BundleProgram`, a single `MachServices` entry, and `AssociatedBundleIdentifiers`. Because of how `SMAppService` works, registration is not even possible unless the app is in `/Applications`. On the first registration, the helper does not become active until the user approves it by hand in System Settings.

### Whose connections it accepts (`ClientValidator`)

The helper inspects the connecting process in `NSXPCListener`'s `shouldAcceptNewConnection` and hands out `HelperProtocol` only to those that pass. The inspection uses the **`audit_token`** rather than the PID, to avoid PID reuse and TOCTOU.

```sh
# Code-signing requirement demanded of the caller in Release builds
identifier "com.tetsuharu.RoamSwitch"
  and anchor apple generic
  and certificate leaf[subject.OU] = "GV76B6G4YU"
```

This requirement is checked with `SecCodeCopyGuestWithAttributes` and `SecStaticCodeCheckValidity`, and the connection is dropped if it does not pass. Only DEBUG builds drop the team-ID pin, for development convenience. What actually ships is always a Release build.

> **The crux of the boundary**
>
> The helper's safety rests on this single code-signing requirement. Anything that satisfies it (a properly signed `RoamSwitch.app`) can call every operation in the table below. There is no channel for feeding it arbitrary commands, but the operations in that table are not weak in themselves. If `RoamSwitch.app` itself is taken over, these operations pass to the attacker.

### What the helper can do (the complete list)

The privileged operations defined in `Shared/HelperProtocol.swift` are all of them. There is no privileged API that is not listed here.

**HelperProtocol — everything that runs as root**

| Method | What it does | Binary / API invoked |
| --- | --- | --- |
| setBlockAll(_:) | Turns the application firewall and stealth mode on or off | /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall / --setstealthmode |
| getBlockAllStatus(...) | Reads the current values of the above | socketfilterfw --getblockall |
| setSharingServicesEnabled(_:) | unload / load of the SSH / SMB / Screen Sharing daemons. When stopping, it records only "the ones that were running" and restores only those | /bin/launchctl list / unload -w / load -w (fixed to the three: `ssh.plist` / `com.apple.smbd.plist` / `com.apple.screensharing.plist`) |
| enableNetworkAirGap(...) disableNetworkAirGap(...) | Applies and lifts the emergency full block (`block drop all`). Goes through `PFRulesetCoordinator` (§4) | /sbin/pfctl -f / -e / -sr |
| setGuardedDevServerPorts(_:) | Uses pf to block only **external** connections to the given dev-server ports (localhost passes through). Passing an empty array lifts all of them | /sbin/pfctl (also via the Coordinator) |
| setSecureDNSServers(_:) restoreOriginalDNSServers(...) getCurrentDNSServers(...) | Switches the DNS of active network services to malware-blocking DNS (Quad9 `9.9.9.9` / Cloudflare `1.1.1.2`), backing up the original settings and restoring them | /usr/sbin/networksetup -listallnetworkservices / -getdnsservers / -setdnsservers |
| terminateProcess(pid:forceKill:) | Suspends (SIGSTOP) or force-quits (SIGKILL) a process. Used to contain ransomware-like processes. `pid > 1` only | kill(2) system call (not a subprocess) |
| getHelperVersion(...) | Returns the helper's version string (used for app-compatibility checks) | — |

> **Design trade-off**
>
> `terminateProcess` can send `SIGKILL` to any process, as long as `pid > 1`. `setSecureDNSServers` accepts any DNS-server string. That is the width the feature needs, but it is not narrow. Judge it with the understanding that the code-signing check in front of it (`ClientValidator`) is the only gate.

### State inside the helper

- `HelperTool.shared` is a single instance shared across connections. It used to be a separate instance per connection, so an emergency containment that opened a new connection could hit a race that lost track of "which services to bring back."
- The sharing-service and DNS backups are only mutated on a serial queue (`stateQueue`).

## §4. How the packet filter (pf) is handled

Two features touch pf: the emergency air-gap, and the dev-server port guard. Both of them always go through a single entry point, **`PFRulesetCoordinator`**, and never run `pfctl -f` themselves.

### Why there is a single entry point

Previously the two features each loaded rules with `pfctl -f` independently, competing over pf's single main ruleset. If the port guard's narrow rule `block ... port {…}` was loaded after the air-gap's `block drop all`, you could end up in a state where the screen said "isolated" but the Mac was still reachable. This bug was found by actually attacking the machine from another host, and was fixed in 1.4.3 (the story is written up in `docs/marketing/zenn/03_lan_side_attack_test.md`).

### How it works now

- **Rebuilt in full every time.** The entire required ruleset is rebuilt from the current state and applied in one shot. It is never applied as a diff.
- **One serial queue.** Every pf change runs on the same `DispatchQueue`, so whether it came from an XPC connection, the helper's startup, or the failsafe timer, changes are processed in order.
- **The priority is as follows (higher wins):** Emergency air-gap → `set skip on lo0` and `block drop all` (nothing else is considered)
- Dev-server guard → `block drop in quick proto tcp ... port { … }`
- Neither → reload `/etc/pf.conf` and return pf to its original state
- **Read back after applying.** `pfctl -sr` reads the rules back to confirm that `block drop all`, or each port's rule, is actually loaded. A case where `pfctl -f` was silently ignored is not treated as success.
- **The temp file is written to a path containing a `UUID` and deleted once applied** (v1.4.5 dropped the fixed path in favor of a hard-to-guess one). The state directory is `/Library/Application Support/RoamSwitch`.

> **API behavior**
>
> The XPC responses from `enableNetworkAirGap` and `setGuardedDevServerPorts`, `(Bool, String?)`, report whether the operation passed all the way through the read-back. The caller (such as `ARPSpoofContainmentManager`) retries on failure, and if it still fails it puts the message straight on screen: "Traffic is not stopped yet. Turn off Wi-Fi now."

## §5. How a block is applied, and how it lifts

### The three kinds of block are each different

**Kinds of block**

| Kind | Scope | Trigger | loopback |
| --- | --- | --- | --- |
| Emergency air-gap | Stops all traffic, incoming and outgoing | When ransomware-like encryption activity, or ARP spoofing (= a man-in-the-middle attack), is detected. **Not used for everyday away-from-home protection** (outgoing browsing needs to stay available) | Passed through with `set skip on lo0` |
| Dev-server port guard | Only **external** TCP connections to the given ports | A one-click manual isolation, or automatic blocking when an unfamiliar listening port is detected (Pro) | From localhost, unchanged |
| Everyday untrusted-network protection | Firewall and stealth, sharing stopped (§6). pf is not used | When you connect to a network you have not registered | — |

### How the air-gap is kept from lingering

- **It lifts after 10 minutes at most.** Right after startup, and on a 60-second timer, the helper runs `releaseAirGapIfExpired()`, and if the timestamp in `/Library/Application Support/RoamSwitch/pf_airgap_since` is older than 10 minutes it force-lifts the block. Even if the app crashed or was killed and never reached the "lift" button, traffic returns on its own.
- **It re-applies after a reboot or a daemon respawn.** On startup the helper reads the on-disk state with `reapplyFromDisk()` and restores it itself, in the order air-gap, port guard, system default (the 10-minute rule applies here too).
- **A failed lift is treated as a failure.** If `block drop all` could not actually be removed, the timestamp is written back so that the failsafe timer and the retry have something to converge on. The screen never falsely shows "lifted."
- You can take back control at any time — with the lift button in the modal, or simply by turning off Wi-Fi.

### How a port-guard false positive is recovered

The unknown-port auto-block (Pro, on by default once Pro is activated) can stop a legitimate LAN receiver — LocalSend, Syncthing, anything started after the guard was enabled. When that happens, allow it from the "Allow" button on the notification banner or the matching row in the "Exposed ports" screen. An executable allowed once is recorded as known and is not blocked again (`PortAnomalyGuard.allowPort(_:)`). Apple system daemons that satisfy `anchor apple` (`rapportd`, which backs Handoff, and the like) are not watched in the first place.

## §6. Everyday untrusted-network protection

When you connect to a network you have not registered, the "protection level" switch does not use pf. It simply changes standard OS settings in a way that can be reversed later.

**Operations per protection level**

| Operation | Implementation | Privilege | How it is restored |
| --- | --- | --- | --- |
| Firewall + stealth mode ON | socketfilterfw --setblockall on / --setstealthmode on | root (helper) | `off` when you return to a safe network |
| Stop SSH / SMB / Screen Sharing | launchctl unload -w | root (helper) | Records **only the ones that were running** when stopped, and `load -w` on return |
| Disable AirDrop | defaults write com.apple.sharingd DiscoverableMode | User (the app itself) | Saves the previous value and writes it back on return |

None of this is a new blocking mechanism that RoamSwitch adds — it is just toggling OS settings. If you delete the app, the only thing that stops is the network-dependent switching; the last OS settings that were applied stay as they are. Nothing is left locked, but if you want to err on the safe side, set it back to "Open" on a trusted network before uninstalling.

## §7. Data handling and Zero Telemetry

### What stays on the Mac

**Data stored on disk**

| Data | Location | Contents |
| --- | --- | --- |
| License token | Keychain com.tetsuharu.RoamSwitch.license | An Ed25519-signed token. `kSecAttrAccessibleAfterFirstUnlock` |
| App settings / guard on-off | UserDefaults suite com.tetsuharu.RoamSwitch | Trusted-network registrations, protection policy, exclusion lists, and so on |
| pf state | /Library/Application Support/RoamSwitch/ | The air-gap timestamp, JSON of the guarded ports, the temp file for the ruleset being applied |
| Device fallback UUID | UserDefaults | A random value, generated only when IOKit does not return a UUID (§9) |
| Logs | os.Logger / NSLog | Unified logging. Nothing is sent externally |

### Traffic that leaves the machine (the complete list)

There is no code anywhere that collects and sends diagnostic results, port information, URLs, or logs. No analytics SDK and no crash-reporter SDK are included. The only external library is Sparkle (updates). What goes out to the network is these four, and that is all.

**Outbound connections RoamSwitch makes**

| Connection | Destination | When it happens | What is sent |
| --- | --- | --- | --- |
| License activation / deactivation | lafine.net /api/v1/license/* | Only when the user enters a license key, or deactivates Pro | License key, device hash, host name, app version. Personal information is handled by Stripe at purchase; the app does not handle it |
| Update check | lafine.net /updates/appcast.xml | Sparkle, every 24 hours and at launch | An HTTP request (a standard UA and version). The downloaded item is verified by EdDSA signature (§10) |
| ClamAV virus-definition update | ClamAV official mirrors | Only when the user has installed ClamAV and uses the scan feature. It launches `freshclam` | A standard ClamAV definition fetch. It contains no RoamSwitch-derived information |
| Checkout page | Stripe Checkout | Only when the user presses the buy button (it opens in the browser) | — (a browser navigation) |

> **The scope of "Zero Telemetry"**
>
> "Zero Telemetry" here means that there is no telemetry that collects and sends usage data or diagnostic results. It does not mean there is no network traffic at all. The four paths in the table above do exist. But each of them is either something the user initiates or a signature-verified update check, and the diagnostic results, ports, URLs, and file contents on the Mac never leave it.
>
> The in-app "link safety check" sheet sends a `HEAD` request to the target URL to see where a shortened URL lands (following redirects to private or local addresses is stopped by the v1.4.5 SSRF mitigation). The MCP `audit_url_safety`, by contrast, is offline analysis that completes on the spot and sends the URL nowhere (§8).

## §8. The MCP server security model

`RoamSwitchMCPServer` is a standalone command-line tool bundled at `RoamSwitch.app/Contents/MacOS/`. An MCP client such as Claude Desktop or Claude Code launches it as a subprocess and talks to it over **stdio (newline-delimited JSON-RPC 2.0)**. The official SDK would not build against this machine's macOS SDK, so it is implemented by hand on top of Foundation's `JSONSerialization`.

### What the design constrains

- **It is read-only.** There is simply no API for changing the security level, isolating a port, or ejecting a device. This is not something forgotten in v1 — it is left out deliberately. Letting external code (here, an LLM) rewrite a security tool's protection state would break trust for every user.
- **It opens no socket.** It neither registers a service nor listens. It reads one line from stdin, returns one line on stdout, and then the client ends the process.
- **It sends nothing out.** All diagnostics complete inside the Mac.
- **It reads settings from a different domain.** `UserDefaults(suiteName: "com.tetsuharu.RoamSwitch")` reads the app's domain explicitly (its own bundle-ID domain is empty). It only reads; it does not write.

### The tools it exposes

**The tools tools/list returns, and the data they return**

| Tool | What it returns | Traffic |
| --- | --- | --- |
| get_security_report | A 10-item check (FileVault / SIP / Gatekeeper / auto-update / XProtect / firewall / Wi-Fi encryption / ARP / exposed ports / guard configuration) with a score and per-item remediation advice | Local only |
| get_exposed_ports | A list of listening TCP ports. For any exposed beyond localhost, it cross-references a known-dangerous-service DB and checks CORS / headers with an HTTP probe to `127.0.0.1:port` (local, closed) | Only the probe to 127.0.0.1 |
| get_guard_status | The on/off state of the Pro auto-response guards (port anomaly / ARP / USB / Bluetooth / Web+Mail download / DNS threat protection), the current protection level, and the trusted-network state | Local only |
| audit_url_safety | A judgement of a URL for phishing / homograph (Unicode spoofing) / brand-subdomain spoofing / high-risk TLD / plaintext HTTP. It is **synchronous and fully offline** (`analyzeURL`; it does not follow redirects) | None |
| get_app_help | A full-text search of the bundled knowledge base (feature specs / settings / troubleshooting / notification-message explanations) | None |

The `instructions` field in the `initialize` response also states plainly, "Cannot change security level, isolate ports, or eject devices," communicating the capability boundary to the client-side LLM. The MCP resources (`roamswitch://docs/*`) are read-only Markdown documents as well.

> **The point: the source is public**
>
> The source for this server, and for the detection logic it uses (ARP monitoring, port scanning, port audit, the 10-point health check, URL safety analysis), is published at `github.com/lafine1211/roamswitch-mcp` (MIT, a mirror of the shipping code, tagged per release). You can check directly in code that it is read-only, what it passes to the LLM, and that it sends nothing out. It does not include the privileged helper, pf control, the guards that act, or licensing — those stay in the app repository.
>
> The tests ship with it too — mirrored unit tests, adversarial-input tests, and mutation fuzzing, run by `swift test` and verified in CI. Fuzzing turned up one unguarded crash (`JSONSerialization` stack-overflows on a deeply-nested JSON object); it is fixed with a nesting-depth check ahead of the parser, and recorded in `SECURITY_TESTING.md`.

## §9. License activation cryptography

### The token

- **It uses Ed25519 (Curve25519 signatures).** The public key is embedded in the app (`LicenseVerifier.embeddedPublicKeyBase64`). The corresponding private key exists only in the license backend (a Firebase Functions environment variable) and is not in the repository.
- **The signed data is canonical JSON.** The signature is created and verified over the exact bytes produced by encoding `LicensePayload` (license key, tier, device hash, issued-at, expiry, seat count) with `JSONEncoder`'s `.sortedKeys` and `.withoutEscapingSlashes`.
- **It is designed to fail closed.** If the embedded key is missing or malformed, or if the signature or the canonical JSON cannot be produced, the result is not "verified" — it returns `invalidSignature`.

### Device binding

```sh
device_hash = SHA-256( "RoamSwitch-LifetimeSalt-v1" : lowercase(IOPlatformUUID) )
```

The raw hardware UUID is not sent to the server. In the rare case where IOKit does not return a UUID, it falls back to a random UUID kept in `UserDefaults`. At verification time, if the token's `device_hash` does not match the current device hash, the result is `deviceMismatch`.

### It works offline

> **The point: it works with no server**
>
> All `validateSavedLicense()` does at startup is read the token from the Keychain and verify it locally with the embedded public key. It does not connect to the network. If the license server is ever shut down, Pro features keep working on a Mac that is already activated. The server is contacted only for a new activation and for an explicit deactivation. The deactivation notice to the server is best-effort — even if it fails, the local deactivation always completes.

The default is a one-time (Lifetime) purchase; `expires_at` is checked only when `is_lifetime` is false. Seat count is expressed by tier — 2 for personal Pro, 5 for Team.

## §10. Distribution and updates

### Signing and notarization (`scripts/release.sh`)

1. Run `xcodebuild archive` (Release, manual signing, Developer ID Application).
2. Export with `-exportArchive` as `method: developer-id`.
3. After `notarytool submit --wait`, run `stapler staple` on the .app.
4. Verify with `spctl -a -t exec -vv`.
5. **Re-zip after stapling** to produce the Sparkle update artifact (so the notarization ticket is included and it runs offline without a Gatekeeper warning).
6. Build the DMG, notarize and staple the DMG as well, and verify with `stapler validate`.

### Updates (Sparkle 2.9.6)

**Update settings in Info.plist**

| Key | Value |
| --- | --- |
| SUFeedURL | https://lafine.net/updates/appcast.xml |
| SUPublicEDKey | CNxzwijMzMCJzliId76Yl88S/9np6t/xg/zQ9YbYzHs= |
| SUEnableAutomaticChecks | true |
| SUScheduledCheckInterval | 86400 |

Before an update is applied, the **EdDSA signature** listed in the appcast is verified against the `SUPublicEDKey` embedded in the app. The private signing key exists only in the build environment. The appcast is served over HTTPS. Delta updates are signature-verified the same way.

> **The point: the appcast is meant to be public**
>
> The fact that the `appcast.xml` URL is public is not a weakness in itself. Its contents are only version numbers, release notes, download URLs, file sizes, and the EdDSA signature of each build — nothing secret. The anchor of trust is not "is the appcast authentic in transit" but verifying the artifact's signature with the public key baked into the app. An attacker who can completely replace the appcast (MITM, DNS hijacking, compromising the web host) still cannot push a malicious update without the signing key. Gatekeeper (Developer ID and notarization) is a second gate.
>
> Two risks remain. One is updates not arriving, because the host is down or the appcast is broken (no bad install happens — you simply do not get updated). The other is a freeze attack that deliberately withholds a security update. Sparkle 2.x rejects downgrades and replays by checking version ordering, but a complete defense against freezing needs a dedicated update server with expiry. That is on our list to address.

## §11. Threat model, and what we don't do

### What RoamSwitch is meant to handle

- Probing and attacks from an attacker on the same LAN, or from a compromised IoT device. It responds with stealth, exposed-port auditing, and isolation from outside.
- Exposure on a network you don't trust. It automatically stops sharing services and AirDrop.
- Detecting ARP spoofing (a man-in-the-middle attack), and an emergency air-gap on detection. "Preventing" it on a home router is essentially impossible, so the approach is to "notice it and cut faster than a human would."
- Finding dev servers and databases (Redis, MongoDB, Elasticsearch, and so on) exposed on `0.0.0.0` without authentication, and blocking them from outside.
- Catching ransomware-like unauthorized encryption activity early and stopping all traffic (it does not rely on signatures).
- Auto-ejecting USB storage that is not allowed, and automatically running a ClamAV scan on attached storage (optional).

### What we have decided not to do

- **It is not a replacement for antivirus.** ClamAV and XProtect are used as auxiliaries; RoamSwitch on its own is not a general-purpose malware detector.
- **It is not a guarantee.** It is one layer in a defense-in-depth stack, not something that "completely prevents ransomware." Marketing copy is reviewed on this premise too.
- **It cannot protect an already-compromised root or kernel.** If an attacker already has root, they can remove the helper's pf rules too.
- **It does not prevent ARP spoofing** (only detection and after-the-fact blocking).
- It is not a substitute for enterprise DHCP snooping or Dynamic ARP Inspection.

### Attack surface that installing RoamSwitch adds

**Attack surface added, and how it is contained**

| Attack surface | How it is contained |
| --- | --- |
| A LaunchDaemon that runs as root, and its mach service (`com.tetsuharu.RoamSwitch.Helper`) | The operation surface is fixed to `HelperProtocol` (the §3 table). There is no arbitrary-command channel. Connections are authorized by a code-signing requirement, using `audit_token`. |
| If `RoamSwitch.app` itself is compromised, all of the helper's operations pass to the attacker | Hardened Runtime is enabled, and the app is given no unnecessary privileges. Outbound traffic is limited to the four paths above. We plan to have this reviewed by a third party. |
| The system-binary paths the helper spawns | Absolute paths like `/sbin/pfctl` are specified directly, with no dependence on `PATH`. Arguments are hard-coded too (apart from port numbers and DNS strings). |
| The MCP server passing system state to an LLM (a confused deputy) | It is read-only, with no write API implemented. URL checks are offline. The settings domain is referenced read-only. |
| Hijacking the update path | EdDSA signature verification (`SUPublicEDKey`), plus a bundled notarization ticket. The appcast is over HTTPS. |

## Appendix A. Check it yourself

Everything stated in this document can be verified against the distributed artifact with the following commands.

### Signing and notarization

```sh
# Developer ID signature and team ID
codesign -dvvv /Applications/RoamSwitch.app 2>&1 | grep -E 'Authority|TeamIdentifier|flags'

# whether the notarization ticket is stapled
stapler validate /Applications/RoamSwitch.app
spctl -a -t exec -vvv /Applications/RoamSwitch.app

# signatures of the bundled helper / MCP server
codesign -dvvv /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchHelper
codesign -dvvv /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
```

### Entitlements (no network-send permission)

```sh
codesign -d --entitlements :- /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchHelper
codesign -d --entitlements :- /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
# → an empty entitlements dictionary. There are no app-sandbox / network-client keys
```

### Measuring the traffic

```sh
# Run Little Snitch / tcpdump alongside and confirm no traffic during normal use
sudo tcpdump -i any -n 'host not 127.0.0.1' and 'not port 53'
# No traffic other than license activation, the update check, and ClamAV updates
```

### The privileged helper itself

```sh
# the registered LaunchDaemon
sudo launchctl print system/com.tetsuharu.RoamSwitch.Helper

# the pf rules currently loaded (the real state of the air-gap / port guard)
sudo pfctl -sr

# the helper's state directory
ls -la "/Library/Application Support/RoamSwitch/"
```

### The MCP server's response (offline check)

```sh
BIN=/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
              '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | "$BIN"
# serverInfo and the definitions of the 5 tools come back. No network connection happens
```

### The MCP server's source and tests

```sh
git clone https://github.com/lafine1211/roamswitch-mcp
cd roamswitch-mcp
swift build -c release        # same source as the shipping binary
swift test                    # unit, adversarial-input, stdio, mutation fuzzing
# SECURITY_TESTING.md has what's tested and the issues found so far
```

### Device identifier

```sh
# the raw value bound into the token (only the salted SHA-256 is ever sent)
ioreg -d2 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}'
```
