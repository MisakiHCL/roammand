// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:roammand/desktop/remote/peer_session.dart';
import 'package:roammand/mobile/remote/mobile_remote_launcher.dart';

void main() {
  test('builds official STUN and optional developer TURN configurations', () {
    final direct = mobilePeerConfiguration();
    expect(direct.iceTransportPolicy, DesktopIceTransportPolicy.all);
    expect(direct.iceServers.single.urls, <String>['stun:stun.hcl.life:3478']);

    final relay = mobilePeerConfiguration(
      iceTransportPolicy: 'relay',
      turnUrls: 'turns:one.example.test:5349, turn:two.example.test:3478',
      turnUsername: 'short-lived-user',
      turnPassword: 'short-lived-password',
    );
    expect(relay.iceTransportPolicy, DesktopIceTransportPolicy.relay);
    expect(relay.iceServers, hasLength(2));
    expect(relay.iceServers.first.urls, <String>['stun:stun.hcl.life:3478']);
    expect(relay.iceServers.last.urls, <String>[
      'turns:one.example.test:5349',
      'turn:two.example.test:3478',
    ]);
    expect(relay.iceServers.last.username, 'short-lived-user');
    expect(relay.iceServers.last.credential, 'short-lived-password');
  });

  test('rejects invalid policy and every partial TURN configuration', () {
    expect(
      () => mobilePeerConfiguration(iceTransportPolicy: 'invalid'),
      throwsA(isA<PeerSessionException>()),
    );
    expect(
      () => mobilePeerConfiguration(stunUrls: 'https://not-stun.example.test'),
      throwsA(isA<PeerSessionException>()),
    );
    for (final values in <(String, String, String)>[
      ('turns:turn.example.test:5349', '', ''),
      ('', 'user', ''),
      ('', '', 'password'),
      ('turns:turn.example.test:5349', 'user', ''),
      ('turns:turn.example.test:5349', '', 'password'),
    ]) {
      expect(
        () => mobilePeerConfiguration(
          turnUrls: values.$1,
          turnUsername: values.$2,
          turnPassword: values.$3,
        ),
        throwsA(isA<PeerSessionException>()),
      );
    }
  });
}
