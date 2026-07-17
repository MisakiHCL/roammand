// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:roammand/desktop/remote/peer_session.dart';
import 'package:roammand/desktop/remote/remote_desktop_controller.dart';
import 'package:roammand/desktop/remote/retryable_remote_desktop_controller.dart';
import 'package:roammand/mobile/identity/mobile_device_identity.dart';
import 'package:roammand/mobile/remote/mobile_controller_session_identity.dart';
import 'package:roammand/mobile/remote/mobile_remote_desktop_page.dart';
import 'package:roammand/network/network_service_configuration.dart';

const _compiledIceTransportPolicy = String.fromEnvironment(
  'ROAMMAND_ICE_TRANSPORT_POLICY',
  defaultValue: 'all',
);
const _compiledStunUrls = String.fromEnvironment(
  'ROAMMAND_STUN_URLS',
  defaultValue: 'stun:stun.hcl.life:3478',
);
const _compiledTurnUrls = String.fromEnvironment('ROAMMAND_TURN_URLS');
const _compiledTurnUsername = String.fromEnvironment('ROAMMAND_TURN_USERNAME');
const _compiledTurnPassword = String.fromEnvironment('ROAMMAND_TURN_PASSWORD');

typedef MobileRemoteLauncher =
    Future<bool> Function(BuildContext context, RemoteDesktopTarget target);

ControllerPeerConfiguration mobilePeerConfiguration({
  String iceTransportPolicy = _compiledIceTransportPolicy,
  String stunUrls = _compiledStunUrls,
  String turnUrls = _compiledTurnUrls,
  String turnUsername = _compiledTurnUsername,
  String turnPassword = _compiledTurnPassword,
}) {
  final policy = switch (iceTransportPolicy.trim().toLowerCase()) {
    '' || 'all' => DesktopIceTransportPolicy.all,
    'relay' => DesktopIceTransportPolicy.relay,
    _ => throw const PeerSessionException(PeerSessionErrorCode.configuration),
  };
  final rawStunUrls = stunUrls.trim();
  final rawUrls = turnUrls.trim();
  final username = turnUsername.trim();
  final hasAnyTurnValue =
      rawUrls.isNotEmpty || username.isNotEmpty || turnPassword.isNotEmpty;
  final servers = <DesktopIceServer>[];
  if (rawStunUrls.isNotEmpty) {
    servers.add(
      DesktopIceServer(
        urls: rawStunUrls
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
      ),
    );
  }
  if (hasAnyTurnValue) {
    if (rawUrls.isEmpty || username.isEmpty || turnPassword.isEmpty) {
      throw const PeerSessionException(PeerSessionErrorCode.configuration);
    }
    servers.add(
      DesktopIceServer(
        urls: rawUrls
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
        username: username,
        credential: turnPassword,
      ),
    );
  }
  final configuration = ControllerPeerConfiguration(
    iceTransportPolicy: policy,
    iceServers: servers,
  );
  configuration.validate();
  return configuration;
}

Future<bool> launchMobileRemoteDesktop(
  BuildContext context, {
  required MobileDeviceIdentity identity,
  required RemoteDesktopTarget target,
  NetworkServiceConfiguration? networkConfiguration,
}) async {
  target.validate();
  final peerConfiguration =
      networkConfiguration?.toPeerConfiguration() ?? mobilePeerConfiguration();
  final controller = RetryableRemoteDesktopController(
    createController: () => RemoteDesktopController(
      identity: MobileControllerSessionIdentity(identity),
      signaling: WebSocketControllerSignalingLink(
        endpoint: target.signalingEndpoint,
      ),
      peer: ControllerPeerSession.production(configuration: peerConfiguration),
    ),
  );
  var connected = false;
  void observeConnection() {
    if (controller.state == RemoteDesktopState.connected) {
      connected = true;
    }
  }

  controller.addListener(observeConnection);
  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            MobileRemoteDesktopPage(target: target, controller: controller),
      ),
    );
  } finally {
    controller.removeListener(observeConnection);
  }
  return connected;
}
