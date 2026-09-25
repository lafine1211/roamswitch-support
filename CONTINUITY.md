<!-- Language: **English** | [日本語](CONTINUITY.ja.md) -->

# If RoamSwitch development stops

**English** | [日本語](CONTINUITY.ja.md)

RoamSwitch is a security product that runs with root privileges on your machine and is bought
once, for life. You should not be left with an unmaintained root component you cannot inspect,
patch or replace. This is what happens if development ends.

## When this applies

Either of these:

1. Lafine Systems Design announces that development or support is ending, or the business is closing.
2. There has been **no release for 12 months** *and* **no reply to a support request for 90 days**.
   Anyone can point this out in an [Issue](../../issues); the dates come from the public release
   history and the Issues themselves.

## What we commit to do

Within **90 days** of the trigger:

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
