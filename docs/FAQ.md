<!-- [日本語](FAQ.ja.md) -->

# FAQ

**English** | [日本語](FAQ.ja.md)

### What does the free version include?

Wi‑Fi auto‑detection with kernel packet blocking (`pf`), the three profile security
levels, automatic stop/restore of SSH / SMB / Screen Sharing / AirDrop, the 10‑point
manual Mac security diagnostic, XProtect status checks, Wi‑Fi encryption warnings,
ARP‑spoofing detection and exposed‑port / USB monitoring (view‑only).

### What does Pro Lifetime ($19.99) add?

Ransomware‑behavior detection with Air‑Gap isolation, dev‑server LAN‑exposure
quarantine, port‑anomaly auto‑blocking, ARP‑spoofing auto‑containment, real‑time
notifications, the unauthorized‑USB storage guard, DNS threat protection, Web/Mail
download guard, link‑safety auditor, autonomous background sweeps, CSV/JSON export,
and use on 2 Macs. It is a one‑time purchase with free updates.

### Which macOS versions are supported?

macOS 13 Ventura or later, on both Apple silicon and Intel Macs.

### Is it on the Mac App Store?

No. It is distributed as a signed and notarized `.dmg` from https://lafine.net/
because it needs a privileged helper (`SMAppService.daemon`) and `pf` control that
the App Store sandbox does not allow.

### The helper won't connect / "Operation not permitted"

Open **System Settings → General → Login Items & Extensions**, approve the RoamSwitch
helper, then quit and relaunch the app. The app must be in `/Applications`.

### Does it send any of my data anywhere?

No. See the [Privacy Policy](PRIVACY.md). Zero Telemetry.

### How do I move my license to a new Mac?

Pro covers 2 devices. Deactivate on the old Mac (or contact support via
https://lafine.net/) and activate on the new one.

### How do I report a bug or request a feature?

Open an [Issue](../../issues) — templates are provided. Japanese or English is fine.
