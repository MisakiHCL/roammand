<!-- SPDX-License-Identifier: Apache-2.0 -->

# macOS release entitlements

Roammand is distributed outside the Mac App Store and intentionally does not
enable App Sandbox. Hardened Runtime is enabled independently for every signed
code object.

- The Flutter app uses `Runner/Release.entitlements`. It contains no Hardened
  Runtime exception.
- Host Agent has an empty entitlement set. Screen Recording and Accessibility
  are user-approved TCC permissions, not code-signing entitlements for this
  non-sandboxed executable.
- Privileged Bridge has an empty entitlement set. Root execution is granted by
  the signed installer and launchd ownership, not an entitlement.
- The Session Agent is a nested background app with a stable bundle identifier.
  It has an empty entitlement set and no runtime exception, allowing the
  uninstaller to reset only its TCC decisions before removing it.
- Frameworks receive no custom entitlements and are signed before the app.

Do not add `get-task-allow`, disable library validation, unsigned executable
memory, DYLD environment, or JIT exceptions to Release without a documented
requirement and clean-machine verification.
