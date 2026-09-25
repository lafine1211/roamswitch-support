<!-- Language: **English** | [日本語](CONTINUITY.ja.md) -->

# If RoamSwitch development stops

**English** | [日本語](CONTINUITY.ja.md)

RoamSwitch is a security product that runs with root privileges on your machine and is bought
once, for life. You should not be left with an unmaintained root component you cannot inspect,
patch or replace. This is what happens if development ends.

## What is not a trigger

A long gap between releases is not a trigger. A finished product may go a year without a release,
and the maintainer may be away for weeks. Silence in the release history proves nothing, so it is
not measured.

## When this applies

Either of these:

1. **An announcement.** Lafine Systems Design announces that development or support is ending, or that
   the business is closing.
2. **An unanswered report.** A security report or support request that was accepted (an
   [Issue](../../issues), or a report sent to the address in <https://lafine.net/.well-known/security.txt>)
   gets **no response for 90 days**, and there is no dated maintainer statement after it (see below).
   The dates come from the Issue itself; anyone can point it out there.

## The maintainer statement

The maintainer can show they are present by updating the line below. A statement dated after a
report starts that report's 90 days again. It is for leave, illness or a quiet period, and it should
say when the maintainer expects to be back.

> Last confirmed maintained: **2026-09-25**

## Notice first, then publication

Meeting condition 2 does not publish anything at once. The order is:

1. **Notice.** A public notice is posted in this repository (an Issue and a line in the README) naming
   the unanswered report and the date.
2. **30 days.** If the maintainer responds to the report or posts a statement during these 30 days,
   the notice is withdrawn and nothing is published.
3. **Publication.** Otherwise, within **90 days** of the notice, we publish as described below.

Condition 1 (an announcement) skips the notice and the 30 days: the 90 days start at the announcement.

## What we commit to do

1. **Publish the source** of the macOS app, its root helper, the Linux edition (core, daemon, CLI,
   server edition), the Sensor and the MCP server in a public repository, with build instructions.
2. **Publish a last release that needs no server of ours.** A licence token is verified on your Mac
   against an embedded public key, so an installed, activated copy keeps working when our servers
   go away. Only *new* activations depend on the server, so the last release also runs without
   activation.
3. **Say so here**, in the README and on https://lafine.net/, and keep the last downloads and
   their SHA-256 checksums available for as long as the domain is held.

## Licence

The published source is released under the **Apache License 2.0**, so you may use, modify, build
and redistribute it, including a fork that continues the project.

## What is not published

Signing identities and private keys (Developer ID, notarization credentials, the licence-signing
private key, the update-signing key), customer records, and payment or account credentials. A
fork signs with its own identities; those secrets never belong in a repository.

## Until then

Nothing changes. Security fixes are released as they are found; the changelog is in
[CHANGELOG.md](CHANGELOG.md). If you depend on RoamSwitch for a company, you can ask for a copy of
this commitment in writing at https://lafine.net/business.
