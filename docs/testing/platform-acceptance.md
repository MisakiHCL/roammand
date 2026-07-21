<!-- SPDX-License-Identifier: Apache-2.0 -->

# Platform acceptance matrix

Platform acceptance covers installed Host components, protected graphical sessions, physical Controllers, network paths, and clean removal.

| Area | Automated evidence | Target-system evidence |
| --- | --- | --- |
| Protocol and bridge | `make test-product` | Repeated route changes with no stale input or lease |
| macOS package | Manifest, install/uninstall dry-run, Release build | macOS 14.4+ install, permissions, Aqua, lock, LoginWindow |
| Windows package | Service contract, manifest, PowerShell `-WhatIf`, CI build | Windows 11 install, Default, lock, UAC, Winlogon, SendSAS |
| Host visibility | Flutter status/tray tests | Named Controller, close-to-hide, Stop, Emergency stop |
| Direct connection | Native WebRTC and reconnect tests | Two-network WSS direct session and recovery |
| Relay connection | TURN configuration and reconnect tests | Forced WSS/TURN relay session and recovery |
| iOS Controller | Flutter tests and Simulator build | Camera pairing, gestures, keyboard, rotation, background |
| Android Controller | Flutter tests and Debug build | Camera pairing, gestures, keyboard, rotation, background |
| Failure safety | Lease, route, process, and input property tests | Broker/Helper termination with immediate input release |
| Removal | Package contracts | macOS removes app data and app-specific TCC decisions; Windows removes program/service data but currently retains each user's identity and grants |

Record the operating-system version, device model, package identity, network path, date, and result. Follow the [manual acceptance checklist](../operations/final-product-acceptance.md) for the complete sequence.
