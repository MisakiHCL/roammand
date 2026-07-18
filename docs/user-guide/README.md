<!-- SPDX-License-Identifier: Apache-2.0 -->

# Roammand user guide

**English** · [简体中文](README.zh-CN.md)

> Roammand is preparing its first public release. The macOS installer is ready
> for distribution, but its public download link has not been published. The
> iPhone and iPad app is not yet available on the App Store.

## Before you start

- The current macOS release requires macOS 14.4 or later.
- The Mac must grant Roammand Screen Recording and Accessibility access before
  it can accept a connection.
- The current release attempts direct ICE connections and has no TURN relay
  fallback. Some restrictive or symmetric network combinations may not connect.

## Install and authorize the Mac

1. Download the signed and notarized `.pkg` from the official download channel
   after that link is published.
2. Open the package and approve the administrator prompt to install the app and
   its required Host components.
3. Start Roammand and open **This computer**.
4. Use the two **Set up** actions to grant Screen Recording and Accessibility
   access in System Settings.
5. Return to Roammand. Pairing and incoming connections become available only
   after both permissions are ready.

Permission requests are initiated only by these local setup actions. An incoming
connection does not request permissions on the user's behalf.

## Install the iPhone or iPad app

Version 1.0.0 is not yet publicly available. The
[App Store listing](https://apps.apple.com/app/id6792014935) is reserved for the
upcoming release, and TestFlight access is limited to invited testers.

After installation, open the app and choose a device name. This name is shown on
the Mac when approving the Controller.

## Pair the devices

1. On the Mac, open **This computer** and create a phone QR invitation.
2. Scan the QR code from the iPhone or iPad.
3. Compare the four verification words on both devices.
4. Approve the named Controller on the Mac.
5. Select the Mac under **My computers** and choose **Connect**.

Pairing authorization is one-way. Reversing which device controls which Host
requires a separate pairing and approval.

## If a connection fails

- If the Mac shows incomplete permissions, finish both setup items before trying
  to connect again.
- Confirm that Roammand is running on the Mac and that the Host is shown as
  available.
- Try another network on either device. Without TURN, direct connectivity can
  fail on restrictive networks even when both devices can reach signaling.
- Stop an active session locally from the Mac if the Controller is unexpected.

## Uninstall from macOS

Open **Settings → Advanced → Uninstall Roammand**. The protected uninstaller
removes the app, Host components, launchd configuration, runtime files, logs,
device identity, pairing grants, saved Hosts, preferences, caches, and
Roammand-specific Screen Recording and Accessibility decisions. Reinstalling
creates a new identity and requires pairing again.

For technical security boundaries, see the [security guide](../security/README.md).
Developers and source builders should use the [build guide](../BUILDING.md).
