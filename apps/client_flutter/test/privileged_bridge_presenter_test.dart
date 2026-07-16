// SPDX-License-Identifier: MPL-2.0

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/host_agent/privileged_bridge_presenter.dart';
import 'package:roammand_protocol/roammand_protocol.dart';

void main() {
  test(
    'maps install, approval, permission, direct, failure and unknown states',
    () {
      final expected =
          <PrivilegedBridgeState, PrivilegedBridgePresentationKind>{
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED:
                PrivilegedBridgePresentationKind.notInstalled,
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED:
                PrivilegedBridgePresentationKind.approvalRequired,
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED:
                PrivilegedBridgePresentationKind.permissionRequired,
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY:
                PrivilegedBridgePresentationKind.userSessionOnly,
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_FAILED:
                PrivilegedBridgePresentationKind.failed,
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_UNSPECIFIED:
                PrivilegedBridgePresentationKind.unknown,
          };
      for (final entry in expected.entries) {
        expect(
          presentPrivilegedBridge(
            PrivilegedBridgeStatusSnapshot(state: entry.key),
          ).kind,
          entry.value,
        );
      }
      expect(
        presentPrivilegedBridge(null).kind,
        PrivilegedBridgePresentationKind.unknown,
      );
    },
  );

  test('maps ready desktop, migration, reconnect and controlled state', () {
    for (final entry
        in <InteractiveDesktopKind, PrivilegedBridgePresentationKind>{
          InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_NORMAL:
              PrivilegedBridgePresentationKind.readyNormal,
          InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_LOCKED_LOGIN:
              PrivilegedBridgePresentationKind.readyLockedLogin,
          InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_SECURE:
              PrivilegedBridgePresentationKind.readySecure,
          InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_UNAVAILABLE:
              PrivilegedBridgePresentationKind.readyUnavailable,
          InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_UNSPECIFIED:
              PrivilegedBridgePresentationKind.unknown,
        }.entries) {
      final presentation = presentPrivilegedBridge(
        _snapshot(
          PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_READY,
          desktop: entry.key,
        ),
      );
      expect(presentation.kind, entry.value);
      expect(presentation.showEmergencyStop, isFalse);
    }

    expect(
      presentPrivilegedBridge(
        _snapshot(PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_TRANSITIONING),
      ).showEmergencyStop,
      isTrue,
    );
    expect(
      presentPrivilegedBridge(
        _snapshot(
          PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED,
          helperConnected: false,
        ),
      ).kind,
      PrivilegedBridgePresentationKind.reconnecting,
    );
    final controlled = presentPrivilegedBridge(
      _snapshot(
        PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED,
        helperConnected: true,
        controllerName: 'My phone',
      ),
    );
    expect(controlled.kind, PrivilegedBridgePresentationKind.controlled);
    expect(controlled.controllerDisplayName, 'My phone');
    expect(controlled.showEmergencyStop, isTrue);
  });

  test('never presents unsafe controller names', () {
    for (final invalid in [
      '',
      'bad\nname',
      List<String>.filled(129, 'x').join(),
    ]) {
      expect(
        presentPrivilegedBridge(
          _snapshot(
            PrivilegedBridgeState.PRIVILEGED_BRIDGE_STATE_CONTROLLED,
            helperConnected: true,
            controllerName: invalid,
          ),
        ).controllerDisplayName,
        isNull,
      );
    }
  });
}

PrivilegedBridgeStatusSnapshot _snapshot(
  PrivilegedBridgeState state, {
  InteractiveDesktopKind desktop =
      InteractiveDesktopKind.INTERACTIVE_DESKTOP_KIND_NORMAL,
  bool helperConnected = true,
  String controllerName = '',
}) => PrivilegedBridgeStatusSnapshot(
  state: state,
  helperConnected: helperConnected,
  activeControllerDisplayName: controllerName,
  interactiveSession: PrivilegedSessionDescriptor(
    osSessionId: Int64(7),
    desktopKind: desktop,
    generation: Int64(1),
  ),
);
