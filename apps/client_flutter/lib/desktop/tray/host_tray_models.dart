// SPDX-License-Identifier: MPL-2.0

enum HostTrayCommand { showWindow, windowCloseRequested, exitApplication }

final class HostTraySnapshot {
  const HostTraySnapshot({
    required this.tooltipLabel,
    required this.exitLabel,
    required this.controlActive,
  });

  final String tooltipLabel;
  final String exitLabel;
  final bool controlActive;

  @override
  bool operator ==(Object other) =>
      other is HostTraySnapshot &&
      other.tooltipLabel == tooltipLabel &&
      other.exitLabel == exitLabel &&
      other.controlActive == controlActive;

  @override
  int get hashCode => Object.hash(tooltipLabel, exitLabel, controlActive);
}

final class HostTrayMenu {
  const HostTrayMenu({required this.tooltipLabel, required this.exitLabel});

  factory HostTrayMenu.fromSnapshot(HostTraySnapshot snapshot) => HostTrayMenu(
    tooltipLabel: snapshot.tooltipLabel,
    exitLabel: snapshot.exitLabel,
  );

  final String tooltipLabel;
  final String exitLabel;

  @override
  bool operator ==(Object other) =>
      other is HostTrayMenu &&
      other.tooltipLabel == tooltipLabel &&
      other.exitLabel == exitLabel;

  @override
  int get hashCode => Object.hash(tooltipLabel, exitLabel);
}
