<!-- SPDX-License-Identifier: Apache-2.0 -->

# macOS privileged Host package

> Installing system components requires administrator approval. Validate the
> complete protected-session behavior on the target macOS version before use.

The staged package contains the Flutter application, current-user Host Agent,
root bridge daemon, Aqua/LoginWindow session agent, fixed launchd definitions,
licenses, and a sorted SHA-256 manifest.

Installation requires explicit administrator consent. It installs only under
`/Applications`, `/Library/PrivilegedHelperTools`, `/Library/LaunchDaemons`,
`/Library/LaunchAgents`, and `/Library/Application Support/Roammand`.
Uninstall preserves each user's device identity and Controller grants unless the
user deletes that application data separately.

Use the repository scripts to stage, verify, install, or uninstall. Run the
install and uninstall scripts with `--dry-run` first to inspect every action.
