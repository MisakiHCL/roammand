// SPDX-License-Identifier: MPL-2.0

import 'package:device_info_plus/device_info_plus.dart';
import 'package:roammand/identity/device_display_name.dart';

abstract interface class DesktopDeviceNameSource {
  Future<String?> readName();
}

final class DeviceInfoDesktopNameSource implements DesktopDeviceNameSource {
  DeviceInfoDesktopNameSource({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  @override
  Future<String?> readName() async {
    final info = await _plugin.deviceInfo;
    if (info is MacOsDeviceInfo) return info.computerName;
    if (info is WindowsDeviceInfo) return info.computerName;
    return null;
  }
}

final class DesktopDeviceNameProvider {
  DesktopDeviceNameProvider({DesktopDeviceNameSource? source})
    : _source = source ?? DeviceInfoDesktopNameSource();

  final DesktopDeviceNameSource _source;

  Future<String?> read() async {
    try {
      return normalizeDeviceDisplayName(await _source.readName());
    } catch (_) {
      return null;
    }
  }
}
