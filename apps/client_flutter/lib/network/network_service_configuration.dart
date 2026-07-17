// SPDX-License-Identifier: MPL-2.0

import 'package:roammand/desktop/remote/peer_session.dart';
import 'package:roammand/desktop/remote/signaling_client.dart';

const networkServiceConfigurationVersion = 1;
const officialNetworkServiceProfileId = 'official';
const customNetworkServiceProfileId = 'custom';
const _maximumStunUrlBytes = 2048;

const _officialSignalingEndpoint = String.fromEnvironment(
  'ROAMMAND_SIGNALING_ENDPOINT',
  defaultValue: 'wss://signal.hcl.life/v1/connect',
);
const _officialStunUrls = String.fromEnvironment(
  'ROAMMAND_STUN_URLS',
  defaultValue: 'stun:stun.hcl.life:3478',
);

enum NetworkServiceProfileKind { official, custom }

enum NetworkServiceConfigurationError {
  invalidVersion,
  invalidProfile,
  invalidSignalingEndpoint,
  invalidStunUrls,
  invalidPeerConfiguration,
}

final class NetworkServiceConfigurationException implements Exception {
  const NetworkServiceConfigurationException(this.code);

  final NetworkServiceConfigurationError code;

  @override
  String toString() => 'NetworkServiceConfigurationException(${code.name})';
}

final class NetworkServiceConfiguration {
  NetworkServiceConfiguration({
    required this.kind,
    required this.signalingEndpoint,
    Iterable<String> stunUrls = const <String>[],
    this.version = networkServiceConfigurationVersion,
  }) : stunUrls = List<String>.unmodifiable(
         stunUrls
             .map((value) => value.trim())
             .where((value) => value.isNotEmpty),
       );

  factory NetworkServiceConfiguration.official() {
    final configuration = NetworkServiceConfiguration(
      kind: NetworkServiceProfileKind.official,
      signalingEndpoint: Uri.parse(_officialSignalingEndpoint),
      stunUrls: _splitUrls(_officialStunUrls),
    );
    configuration.validate();
    return configuration;
  }

  factory NetworkServiceConfiguration.fromJson(Map<String, dynamic> json) {
    try {
      final version = json['version'] as int;
      if (version != networkServiceConfigurationVersion) {
        throw const NetworkServiceConfigurationException(
          NetworkServiceConfigurationError.invalidVersion,
        );
      }
      final kind = switch (json['profileId']) {
        officialNetworkServiceProfileId => NetworkServiceProfileKind.official,
        customNetworkServiceProfileId => NetworkServiceProfileKind.custom,
        _ => throw const NetworkServiceConfigurationException(
          NetworkServiceConfigurationError.invalidProfile,
        ),
      };
      final urls = (json['stunUrls'] as List<dynamic>).cast<String>();
      final configuration = NetworkServiceConfiguration(
        kind: kind,
        signalingEndpoint: Uri.parse(json['signalingEndpoint'] as String),
        stunUrls: urls,
        version: version,
      );
      configuration.validate();
      return configuration;
    } on NetworkServiceConfigurationException {
      rethrow;
    } catch (_) {
      throw const NetworkServiceConfigurationException(
        NetworkServiceConfigurationError.invalidProfile,
      );
    }
  }

  final int version;
  final NetworkServiceProfileKind kind;
  final Uri signalingEndpoint;
  final List<String> stunUrls;

  String get profileId => kind == NetworkServiceProfileKind.official
      ? officialNetworkServiceProfileId
      : customNetworkServiceProfileId;

  void validate() {
    if (version != networkServiceConfigurationVersion) {
      throw const NetworkServiceConfigurationException(
        NetworkServiceConfigurationError.invalidVersion,
      );
    }
    try {
      validateSignalingEndpoint(signalingEndpoint);
    } catch (_) {
      throw const NetworkServiceConfigurationException(
        NetworkServiceConfigurationError.invalidSignalingEndpoint,
      );
    }
    if (stunUrls.any((value) => !_validStunUrl(value))) {
      throw const NetworkServiceConfigurationException(
        NetworkServiceConfigurationError.invalidStunUrls,
      );
    }
    try {
      toPeerConfiguration().validate();
    } catch (_) {
      throw const NetworkServiceConfigurationException(
        NetworkServiceConfigurationError.invalidPeerConfiguration,
      );
    }
  }

  ControllerPeerConfiguration toPeerConfiguration() {
    final servers = stunUrls.isEmpty
        ? const <DesktopIceServer>[]
        : <DesktopIceServer>[DesktopIceServer(urls: stunUrls)];
    return ControllerPeerConfiguration(iceServers: servers);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'profileId': profileId,
    'signalingEndpoint': signalingEndpoint.toString(),
    'stunUrls': stunUrls,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkServiceConfiguration &&
          version == other.version &&
          kind == other.kind &&
          signalingEndpoint == other.signalingEndpoint &&
          _listEquals(stunUrls, other.stunUrls);

  @override
  int get hashCode =>
      Object.hash(version, kind, signalingEndpoint, Object.hashAll(stunUrls));
}

List<String> _splitUrls(String value) => value
    .split(RegExp(r'[,\n]'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList(growable: false);

bool _validStunUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      const <String>{'stun', 'stuns'}.contains(uri.scheme) &&
      uri.path.isNotEmpty &&
      uri.fragment.isEmpty &&
      value.length <= _maximumStunUrlBytes &&
      !value.contains(RegExp(r'[@\s]'));
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
