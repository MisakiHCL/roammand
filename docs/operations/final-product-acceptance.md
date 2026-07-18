<!-- SPDX-License-Identifier: Apache-2.0 -->

# Release acceptance

This checklist validates installed product behavior on target systems. Record
each result as Passed, Failed, or Pending with the operating-system version,
device type, network path, and date. Automated and target-system evidence remain
independent.

Use an installed package for protected-session acceptance. Direct source runs
report `user_session_only`; protected-session checks require an installed Host
that reports Ready on the target operating system.

## Before you start

Prepare two supported desktop computers, one physical iOS or Android device,
an administrator account on each Host, and a WSS signaling/UDP STUN deployment
reachable by every device. The macOS Host must be 14.4 or newer and needs Screen
Recording and Accessibility approval. The Windows 11 Host must allow the
installed service; software Ctrl+Alt+Del additionally depends on SendSAS group
policy.

Build and verify the checkout first:

```bash
make doctor
make test
make test-m8
```

Follow [Building from source](../BUILDING.md) to stage and inspect the package.
Run every install/uninstall dry-run before allowing administrator changes. Do
not treat a staged package as proof of protected-desktop runtime behavior.

## Installation and readiness

1. Install the Host package with administrator consent. Expected: program and
   service files are installed only in the documented platform locations; the
   device identity and grants are not placed in service data.
2. Restart/sign out and in if the platform instructions request it, then open
   Roammand. Expected: the GUI starts its installed Host Agent while the broker
   and graphical-session Helper are available through the platform services.
3. On macOS, open **This computer** and grant Screen Recording and
   Accessibility only through the installed Host permission checklist.
   Expected: denying either permission keeps pairing and inbound connections
   unavailable; attempting a Controller connection never opens a permission
   prompt.
4. On Windows, inspect the service. Expected: `RoammandPrivilegedBridge`
   is automatic, running as LocalSystem, and non-interactive.
5. Open **This computer**. Expected: installed systems report a specific Ready
   state. `user_session_only`, Not installed, Approval required, Permission
   required, or Failed means protected-session acceptance cannot proceed and
   must remain Pending or Failed.
6. Close the Host window. Expected: it hides while the tray remains visible.
   The Host Agent remains available. Use the tray to show it again. Explicit
   Exit is the only normal UI exit and stops the Agent owned by that GUI.

## Pairing and normal control

7. On the Host, create a desktop pairing code. Expected: it expires within 120
   seconds and creates no grant by itself.
8. On a desktop Controller, enter the code. Expected: both desktops display the
   same fixed four English SAS words and the Host names the Controller when a
   safe device name is available.
9. Approve locally on the Host. Expected: one permanent Controller → Host grant
   appears; reverse control is not granted.
10. On a physical phone, choose QR pairing and grant camera access. Expected:
    pairing works only by scanning the live Host QR with the camera; there is no
    paste, gallery, file, or manual QR-data path.
11. Connect from the saved Host card. Expected: video appears and pointer,
    click, drag, scroll, keyboard, text, and modifiers work. The Host page and
    tray show the bounded Controller name and an Emergency stop action.
12. Verify mobile gestures in portrait and landscape, with the keyboard shown
    and hidden. Expected: targeting remains aligned; backgrounding releases all
    input and closes rather than silently reconnecting.

## Protected desktop transitions

13. Lock and unlock the Windows Host during control. Expected: input freezes,
    all held keys/buttons are released, the Controller reconnects through a
    newer protected route, and a local control indicator remains visible.
14. Open a Windows UAC prompt. Expected: the secure desktop is visible and
    controllable only when the installed Helper and policy allow it; otherwise
    the session fails closed with a stable state.
15. From the connected Controller, request Ctrl+Alt+Del. Expected: Windows uses
    SendSAS, not synthetic keystrokes. The request succeeds only on the current
    controlled Winlogon route with input permission and enabled policy.
16. Lock and unlock the macOS Host during control. Expected: migration between
    Aqua and LoginWindow releases input first, reconnects with a new generation,
    and keeps a local control panel visible.
17. Exercise the macOS LoginWindow credential surface. Expected: only public
    platform APIs and already granted permissions are used. FileVault preboot
    is not expected to work.

Mark steps 13–17 Pending unless they were actually run on the named system. A
simulation, unit test, cross-compile, or package dry-run is not a substitute.

## Network recovery and safety

18. Run once on the same LAN and once across independent public networks with
    the configured STUN service. Expected: both routes authenticate when direct
    ICE succeeds, and diagnostics identify a stable connection failure on a
    restrictive path instead of claiming that a TURN relay was attempted.
19. Interrupt signaling or the Controller network, then restore it within 30
    seconds. Expected: input is released and blocked during the 1/2/4/8/15
    second recovery schedule, and reconnect uses fresh authentication.
20. Leave the interruption unresolved. Expected: recovery ends in a stable
    failure and requires explicit Retry or Connect; there is no unbounded loop.
21. Use Emergency stop on the Host page, tray, and protected indicator in
    separate runs. Expected: each local action closes control once, releases
    input, prevents automatic reconnect, and preserves the permanent grant.
22. Reconnect, then revoke the Controller on the Host. Expected: the session
    closes and future control is rejected. Deleting a Host card on the
    Controller alone must not revoke the Host grant.
23. Crash/restart the session Helper, then the broker, during separate sessions.
    Expected: every path releases input and closes or authentically reconnects;
    no stale Helper or lease remains usable.
24. Repeat connect → lock/protected transition → unlock → disconnect ten times
    on each Host platform. Expected: no stuck key/button, orphan indicator,
    duplicate tray item, stale session, or steadily growing process/resource
    count.

## Cleanup

25. Preview uninstall (`--dry-run` on macOS or `-WhatIf` on Windows). Expected:
    no system state changes.
26. Use **Settings → Advanced → Uninstall Roammand**, or the terminal fallback,
    and approve administrator access. Expected: services, Helpers, package data,
    application files, device identity, grants, saved Hosts, preferences,
    caches, and Roammand-specific TCC decisions are removed.
27. Confirm the GUI-owned Host Agent, service/launchd jobs, and tray are gone.
    In System Settings, confirm neither the Session Agent nor Roammand remains
    under Screen Recording or Accessibility. Reinstalling must create a new
    identity and require pairing again.

The supported boundary excludes cold-start access before the Host owner has
ever logged in, continued control after full logout or Host Agent exit,
FileVault preboot, bypassing TCC/UAC/SAS policy, invisible control, file
transfer, clipboard, audio, multi-display selection, accounts, cloud sync,
multi-controller control, and automatic updates.
