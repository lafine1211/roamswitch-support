<!-- Language: **English** | [日本語](RESULTS-LINUX-2026-09-02.ja.md) -->

# RoamSwitch for Linux — Self-Penetration Test & Defense Verification Report (v1.0.0)

**Target:** RoamSwitch for Linux v1.0.0 (`roamswitch-daemon` / `roamswitch-app` / `roamswitch` / `roamswitch-mcp`)
**Host / attacker / target:** the same Linux machine (Ubuntu 26.04 preview, kernel 7.0.0, glibc 2.43) and a disposable `--privileged` Docker container built on Debian 12 (the release glibc floor)
**Audit date:** 2026-09-02
**Methodology:** whitebox (source inspection) + blackbox (live filesystem / network / USB attacks against the running daemon)

---

## 1. Executive Summary

Every defect found during the self-penetration test was **fixed and re-verified**. The
destructive self-test suite runs **14 / 15 PASS**; the one non-pass is a container
limitation (a container's overlayfs/tmpfs delivers no fanotify permission events), and
that check passes on real hardware (ext4).

| # | Test area | Attack method | Result |
|---|---|---|:---:|
| **SP-1** | Ransomware-decoy (canary) tamper detection | rename / delete / truncate a decoy in the user's Documents | **PASS** — detected in ~2 s → Air-Gap |
| **SP-2** | Ransomware bulk-encryption burst | one process writes 6+ distinct high-entropy files within 3 s | **PASS** (host) — process frozen with `SIGSTOP` → Air-Gap |
| **SP-2b** | No false positive on `shred` | `shred -n 3 -u` on several files | **PASS** — not flagged (allow-listed) |
| **SP-2c** | Critical processes never frozen | inspect the freeze target on a burst | **PASS** — `systemd` / `dockerd` / `NetworkManager` / `sshd` etc. never frozen |
| **SP-3** | Air-Gap enable → isolation | `enable_air_gap` IPC | **PASS** — `policy drop` on the output hook, all egress blocked |
| **SP-3b** | Air-Gap self-healing | external `nft delete table inet roamswitch` | **PASS** — re-asserted by the sentinel loop within 5 s |
| **SP-3c** | Air-Gap fail-closed | kill the daemon mid-Air-Gap, then restart | **PASS** — isolation persists across restart |
| **SP-3d** | Air-Gap disable → recovery | `disable_air_gap` IPC | **PASS** — drop policy lifted, all marker files removed, connectivity restored, automatic security level re-applied |
| **SP-4** | Malware quarantine | write the EICAR test string into Downloads | **PASS** — relocated to the Quarantine Vault |
| **SP-4b** | Quarantine Vault permission hardening | check vault directory + sample modes | **PASS** — directory `0700`, sample `0400` |
| **SP-5** | MCP `get_guard_status` accuracy | set a manual override, read the label | **PASS** — label correctly reads "manual override active: \<level\>" |
| **SP-6** | BadUSB | an unregistered keyboard present at daemon startup | **PASS** — treated as suspect, warning until explicitly authorized |
| **CLI** | every subcommand, both languages | `status` / `guards` / `wifi` / `ports` / `canary` / `quarantine` / `audit-url` / `audit-secrets` / `audit-logs` / `knowledge` / `sharing` | **PASS** — correct output in JA and EN; unknown command exits 1 |

---

## 2. Findings fixed during the audit

### F1 — Canary guard watched the wrong directories — FIXED ✅
- **Finding:** the daemon runs with `HOME=/root`, so the `$HOME`-relative canary paths
  resolved to `/root/{Documents,…}` (non-existent). Only 4 dedicated decoys were
  monitored; the real user's scattered decoys were not. Rename / delete / truncate went
  undetected across three test rounds.
- **Fix:** a shared `syspaths::user_homes()` helper enumerates `/home/*`; canaries are
  deployed into every real user's Documents / Desktop / Downloads / Pictures and chowned
  to the directory owner. Verified: 16 monitored decoys; rename → Air-Gap in ~2 s.

### F2 — MCP guard status always reported "not trusted / balanced" — FIXED ✅
- **Finding:** the MCP `NetworkConfig` struct carried `#[serde(rename_all = "camelCase")]`,
  so the config's snake_case keys (`trusted_networks`, `away_protection_level`) never
  deserialized — every field fell back to its default.
- **Fix:** removed the camelCase rule, added field aliases, made `away_protection_level`
  optional (the app writes `null`). Verified: `get_guard_status` now reflects the real
  trusted-network state and manual overrides.

### F3 — `disable_air_gap` did not re-assert the correct profile — FIXED ✅
- **Finding:** after a daemon restart while Air-Gap was active, the nft table was fresh
  (open) but the `/tmp/*airgap*` marker files persisted — the app showed "Air-Gap active"
  forever while traffic actually flowed.
- **Fix:** daemon-owned reconciliation — `reconcile_air_gap()` runs every cycle,
  re-asserts drop rules if a marker is set but rules are missing, auto-expires after
  600 s, and `disable_air_gap` removes **all** markers and re-applies the automatic
  security level. Verified: external clobber → re-asserted in 5 s; restart → isolation
  survives; disable → clean teardown.

### F4 — Over-permissive Quarantine Vault — FIXED ✅
- **Finding:** the vault directory was `0777` and stored payloads `0666` — a quarantined
  sample was world-readable and could be copied out or executed.
- **Fix:** vault directory `0700`, stored payload `0400` (read-only, non-executable);
  on restore the file is returned to `0644` and chowned to the destination owner.

### F5 — `shred` false-positive in the entropy guard — FIXED ✅
- **Finding:** `shred` overwriting a file with random data 3× looked like a
  mass-encryption burst and got frozen.
- **Fix:** ~60 tools that legitimately write high-entropy data (`shred`, `gpg`, `ffmpeg`,
  `tar`, `borg`, `restic`, container/VM runtimes, `apt`, …) are allow-listed; repeated
  overwrites of the same path count as one event; the entropy tracker keys by PID and
  triggers only on 6+ **distinct** high-entropy files within 3 s.

### F6 — Docker daemon frozen by the entropy guard mid-build — FIXED ✅
- **Finding:** a filesystem-wide fanotify mark saw Docker's overlay writes (compressed
  image layers = high entropy) with container-relative paths that no host path-prefix
  exclusion matched, so `dockerd` was `SIGSTOP`-ed and every container on the host hung.
- **Fix:** `freeze_process()` checks a hard-coded NEVER_FREEZE list (`systemd`,
  `dockerd`, `containerd`, `NetworkManager`, `sshd`, `gnome-shell`, the RoamSwitch
  binaries, …) and refuses to freeze them or PID ≤ 1; container/VM runtimes are also on
  the entropy allow-list. The canary-guard SIGSTOP path was routed through the same
  guard. Verified: `dockerd` is not frozen during a full image rebuild.

---

## 3. Verify "zero data sent off the machine" yourself

Runs on the installed package alone (the source is not published):

```sh
# The shipped binary links no HTTP / TLS library
ldd "$(command -v roamswitch-daemon)" | grep -iE 'curl|ssl|crypto|nghttp|http'   # -> empty

# The running daemon holds no internet socket
sudo lsof -p "$(pgrep -x roamswitch-daemon)" -a -i                               # -> empty
sudo lsof -p "$(pgrep -x roamswitch-daemon)" -a -U | grep roamswitch             # -> only roamswitch.sock

# Live: no RoamSwitch-owned outbound connection appears
watch -n 5 'sudo ss -tupn | grep roamswitch || echo "(no external sockets)"'

# Syscall level: connect() targets AF_UNIX only
sudo strace -f -e trace=connect -p "$(pgrep -x roamswitch-daemon)" 2>&1 | grep -i connect
```

The full dependency-tree and source audit (performed by lafine, since the source is not
public) is in whitepaper §9: <https://lafine.net/linux/whitepaper>.

---

## 4. Known limitations (not defects)

| Limitation | Impact | Handling |
|---|---|---|
| Some kernels do not deliver `FAN_MARK_MOUNT` events on tmpfs (`/tmp`) | file writes under `/tmp` are not watched by fanotify | `/tmp` is ephemeral and not a monitored user folder; ransomware targets `~/`. Mark failures are logged, not silently ignored |
| No fanotify event delivery on container overlayfs / tmpfs | in-container entropy-burst detection (SP-2) cannot be validated | the harness auto-detects this with a probe and marks SP-2 SKIP; it is validated on real hardware (ext4) instead |
| RoamSwitch's `nftables` operations share the netfilter space with Docker's `iptables-nft` backend | RoamSwitch rule operations can interfere with Docker's NAT rules | isolated in the dedicated `inet roamswitch` table; whole-ruleset operations (`nft flush ruleset`) are avoided |

---

*Canonical whitepaper: <https://lafine.net/linux/whitepaper>. Source: `roamswitch-linux/docs/WHITEPAPER.md` (§9, Appendix C).*
