// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:roammand_protocol/roammand_protocol.dart';

const _maximumControllerNameBytes = 128;

enum PrivilegedBridgePresentationKind {
  notInstalled,
  approvalRequired,
  permissionRequired,
  userSessionOnly,
  readyNormal,
  readyLockedLogin,
  readySecure,
  readyUnavailable,
  transitioning,
  reconnecting,
  controlled,
  failed,
  unknown,
}

final class PrivilegedBridgePresentation {
  const PrivilegedBridgePresentation({
    required this.kind,
    required this.showEmergencyStop,
    this.controllerDisplayName,
  });

  final PrivilegedBridgePresentationKind kind;
  final bool showEmergencyStop;
  final String? controllerDisplayName;
}

PrivilegedBridgePresentation presentPrivilegedBridge(
  PrivilegedBridgeStatusSnapshot? snapshot,
) {
  if (snapshot == null) {
    return const PrivilegedBridgePresentation(
      kind: PrivilegedBridgePresentationKind.unknown,
      showEmergencyStop: false,
    );
  }
  final state = snapshot.state;
  if (state == PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED) {
    return _presentation(PrivilegedBridgePresentationKind.notInstalled);
  }
  if (state ==
      PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED) {
    return _presentation(PrivilegedBridgePresentationKind.approvalRequired);
  }
  if (state ==
      PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED) {
    return _presentation(PrivilegedBridgePresentationKind.permissionRequired);
  }
  if (state ==
      PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY) {
    return _presentation(PrivilegedBridgePresentationKind.userSessionOnly);
  }
  if (state == PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY) {
    return _presentation(_readyKind(snapshot));
  }
  if (state == PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_TRANSITIONING) {
    return _presentation(
      PrivilegedBridgePresentationKind.transitioning,
      showEmergencyStop: true,
    );
  }
  if (state == PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED) {
    final kind = snapshot.helperConnected
        ? PrivilegedBridgePresentationKind.controlled
        : PrivilegedBridgePresentationKind.reconnecting;
    return _presentation(
      kind,
      showEmergencyStop: true,
      controllerDisplayName: _safeControllerName(
        snapshot.activeControllerDisplayName,
      ),
    );
  }
  if (state == PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_FAILED) {
    return _presentation(PrivilegedBridgePresentationKind.failed);
  }
  return _presentation(PrivilegedBridgePresentationKind.unknown);
}

PrivilegedBridgePresentationKind _readyKind(
  PrivilegedBridgeStatusSnapshot snapshot,
) {
  if (!snapshot.hasInteractiveSession()) {
    return PrivilegedBridgePresentationKind.unknown;
  }
  final desktop = snapshot.interactiveSession.desktopKind;
  if (desktop == InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_NORMAL) {
    return PrivilegedBridgePresentationKind.readyNormal;
  }
  if (desktop == InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_LOCKED_LOGIN) {
    return PrivilegedBridgePresentationKind.readyLockedLogin;
  }
  if (desktop == InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_SECURE) {
    return PrivilegedBridgePresentationKind.readySecure;
  }
  if (desktop == InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_UNAVAILABLE) {
    return PrivilegedBridgePresentationKind.readyUnavailable;
  }
  return PrivilegedBridgePresentationKind.unknown;
}

PrivilegedBridgePresentation _presentation(
  PrivilegedBridgePresentationKind kind, {
  bool showEmergencyStop = false,
  String? controllerDisplayName,
}) => PrivilegedBridgePresentation(
  kind: kind,
  showEmergencyStop: showEmergencyStop,
  controllerDisplayName: controllerDisplayName,
);

String? _safeControllerName(String value) {
  if (value.isEmpty ||
      utf8.encode(value).length > _maximumControllerNameBytes ||
      value.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    return null;
  }
  return value;
}
