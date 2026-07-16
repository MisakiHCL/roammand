// SPDX-License-Identifier: MPL-2.0

enum HostTrayCommand {
  showWindow,
  windowCloseRequested,
  emergencyStop,
  exitApplication,
}

final class HostTraySnapshot {
  const HostTraySnapshot({
    required this.statusLabel,
    required this.showLabel,
    required this.emergencyStopLabel,
    required this.exitLabel,
    required this.controlActive,
  });

  final String statusLabel;
  final String showLabel;
  final String emergencyStopLabel;
  final String exitLabel;
  final bool controlActive;

  @override
  bool operator ==(Object other) =>
      other is HostTraySnapshot &&
      other.statusLabel == statusLabel &&
      other.showLabel == showLabel &&
      other.emergencyStopLabel == emergencyStopLabel &&
      other.exitLabel == exitLabel &&
      other.controlActive == controlActive;

  @override
  int get hashCode => Object.hash(
    statusLabel,
    showLabel,
    emergencyStopLabel,
    exitLabel,
    controlActive,
  );
}

final class HostTrayMenu {
  const HostTrayMenu({
    required this.statusLabel,
    required this.showLabel,
    required this.emergencyStopLabel,
    required this.exitLabel,
    required this.emergencyStopEnabled,
  });

  factory HostTrayMenu.fromSnapshot(HostTraySnapshot snapshot) => HostTrayMenu(
    statusLabel: snapshot.statusLabel,
    showLabel: snapshot.showLabel,
    emergencyStopLabel: snapshot.emergencyStopLabel,
    exitLabel: snapshot.exitLabel,
    emergencyStopEnabled: snapshot.controlActive,
  );

  final String statusLabel;
  final String showLabel;
  final String emergencyStopLabel;
  final String exitLabel;
  final bool emergencyStopEnabled;
}
