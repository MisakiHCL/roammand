// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:roammand/desktop/host_agent/host_agent_client.dart';
import 'package:roammand/desktop/maintenance/host_maintenance.dart';

Future<void> main(List<String> arguments) async {
  final runner = HostMaintenanceRunner(
    clientFactory: HostAgentClient.new,
    writeOutput: stdout.writeln,
    writeError: stderr.writeln,
  );
  exitCode = await runner.run(arguments);
}
