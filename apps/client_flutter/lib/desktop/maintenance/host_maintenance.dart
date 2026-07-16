// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:roammand_protocol/roammand_protocol.dart';

import '../home/host_connection_descriptor.dart';
import '../host_agent/host_agent_models.dart';
import '../remote/signaling_client.dart';

const _authorizedOutput = <String, String>{'status': 'authorized'};
const _viewAndControlPermissions = <SessionPermission>[
  SessionPermission.SESSION_PERMISSION_VIEW_SCREEN,
  SessionPermission.SESSION_PERMISSION_CONTROL_INPUT,
];

typedef MaintenanceOutput = void Function(String value);

final class HostMaintenanceRunner {
  factory HostMaintenanceRunner({
    required HostAgentApi Function() clientFactory,
    required MaintenanceOutput writeOutput,
    required MaintenanceOutput writeError,
  }) => HostMaintenanceRunner._(clientFactory, writeOutput, writeError);

  HostMaintenanceRunner._(
    this._clientFactory,
    this._writeOutput,
    this._writeError,
  );

  final HostAgentApi Function() _clientFactory;
  final MaintenanceOutput _writeOutput;
  final MaintenanceOutput _writeError;

  Future<int> run(List<String> arguments) async {
    final command = _parse(arguments);
    if (command == null) {
      return _fail('invalid_arguments');
    }
    HostAgentApi? client;
    try {
      final controller = switch (command) {
        _AuthorizeControllerCommand(:final descriptor) =>
          parsePublicHostConnectionDescriptor(descriptor).identity,
        _DescribeCommand() => null,
      };
      client = _clientFactory();
      await client.connect();
      switch (command) {
        case _DescribeCommand(:final signalingEndpoint):
          final status = await client.getHostStatus();
          if (!status.hasIdentity()) {
            return _fail('host_agent_protocol');
          }
          _writeOutput(
            encodePublicHostConnectionDescriptor(
              PublicHostConnectionDescriptor(
                identity: status.identity,
                signalingEndpoint: signalingEndpoint,
              ),
            ),
          );
        case _AuthorizeControllerCommand():
          await client.createControllerGrant(
            controller!,
            _viewAndControlPermissions,
          );
          _writeOutput(jsonEncode(_authorizedOutput));
      }
      return 0;
    } on HostConnectionDescriptorException {
      return _fail('invalid_descriptor');
    } on Object {
      return _fail('host_agent_unavailable');
    } finally {
      await client?.close();
    }
  }

  _MaintenanceCommand? _parse(List<String> arguments) {
    if (arguments.length != 2) {
      return null;
    }
    switch (arguments.first) {
      case 'describe':
        try {
          final endpoint = Uri.parse(arguments[1]);
          validateSignalingEndpoint(endpoint);
          return _DescribeCommand(endpoint);
        } catch (_) {
          return null;
        }
      case 'authorize-controller':
        return _AuthorizeControllerCommand(arguments[1]);
      default:
        return null;
    }
  }

  int _fail(String code) {
    _writeError(jsonEncode(<String, String>{'error': code}));
    return 2;
  }
}

sealed class _MaintenanceCommand {
  const _MaintenanceCommand();
}

final class _DescribeCommand extends _MaintenanceCommand {
  const _DescribeCommand(this.signalingEndpoint);

  final Uri signalingEndpoint;
}

final class _AuthorizeControllerCommand extends _MaintenanceCommand {
  const _AuthorizeControllerCommand(this.descriptor);

  final String descriptor;
}
