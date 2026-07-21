<!-- SPDX-License-Identifier: Apache-2.0 -->

# Security Policy

## Supported versions

Security fixes target the `main` branch and the latest non-prerelease version
listed in [GitHub Releases](https://github.com/MisakiHCL/roammand/releases).
Older releases do not receive routine security maintenance; reproduce against a
supported revision before reporting when it is safe to do so.

## Report a vulnerability privately

Do not open a public issue, discussion, or pull request containing vulnerability
details, exploit code, sensitive logs, or a proposed security patch.

1. If the repository **Security** page shows **Report a vulnerability**, use
   GitHub private vulnerability reporting. Do not use an ordinary GitHub issue.
2. If that private option is unavailable, open only a minimal public issue titled
   `Security contact requested`. State that details are being withheld and ask a
   maintainer to establish a private channel. Do not name the vulnerable
   component, affected endpoint, reproduction steps, impact, or workaround if
   any of those facts would help exploitation.
3. Wait until the maintainer confirms the private channel before sharing the
   report. If information is accidentally posted publicly, remove it where
   possible and notify the maintainer without repeating it.

The repository does not publish a response-time or bounty commitment. The
maintainer and reporter should coordinate scope, remediation, release timing,
and any GitHub Security Advisory or CVE before public disclosure.

## What to include

Use synthetic data and provide the smallest reproducible case. A useful private
report includes:

- affected release, commit, platform, and component;
- security impact and the trust boundary crossed;
- minimal reproduction steps or a test that demonstrates the issue;
- required permissions, user interaction, and network position;
- whether the issue is reproducible on the latest supported revision;
- suggested mitigation, if known, and a safe way to validate a fix.

Do not include real private keys, pairing codes or secrets, authentication
transcripts, device identifiers, credentials, SDP, ICE candidates, IP addresses,
typed text, pointer coordinates, screen captures, or private diagnostic bundles.
Replace them with clearly marked synthetic values.

## Research boundaries

Avoid accessing another person's device or data, degrading the public service,
creating persistent access, social engineering users, or testing at a scale that
could affect availability. Stop once the minimum evidence needed to demonstrate
the issue has been collected.

Roammand's intended guarantees, trust assumptions, metadata exposure, and known
limits are documented in the [security guide](docs/security/README.md). A design
limitation already disclosed there may still be worth a private report if the
implementation behaves more broadly or less safely than documented.
