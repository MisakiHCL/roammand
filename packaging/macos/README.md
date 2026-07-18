<!-- SPDX-License-Identifier: Apache-2.0 -->

# macOS privileged Host package

> Installing system components requires administrator approval. Validate the
> complete protected-session behavior on the target macOS version before use.

The staged package contains the Universal Flutter application, Universal
current-user Host Agent, root bridge daemon, Aqua/LoginWindow session agent,
fixed launchd definitions, licenses, a protected uninstaller, and a sorted
SHA-256 manifest.

Installation requires explicit administrator consent. It installs only under
`/Applications`, `/Library/PrivilegedHelperTools`, `/Library/LaunchDaemons`,
`/Library/LaunchAgents`, and `/Library/Application Support/Roammand`.
The installed GUI exposes the protected uninstaller under **Settings → Advanced**.
It removes the program, device identity, Controller grants, saved Hosts,
preferences, caches, and Roammand-specific Screen Recording and Accessibility
decisions. It never resets another app's privacy decisions. The repository
script remains the terminal fallback and supports `--dry-run`.

Use the repository scripts to stage, verify, install, or uninstall. Run the
install and uninstall scripts with `--dry-run` first to inspect every action.

Direct website distribution uses `make package-macos-signed` to sign all code
with Developer ID Application and Hardened Runtime, regenerate the manifest,
and create a Developer ID Installer-signed `dist/apple-release/Roammand.pkg`.
`make release-macos` submits that package with the configured notarytool
Keychain profile, staples the accepted ticket, and performs Gatekeeper
assessment. See [BUILDING.md](../../docs/BUILDING.md) for the privacy-safe
credential and release workflow.
