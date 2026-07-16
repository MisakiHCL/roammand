// SPDX-License-Identifier: MPL-2.0

import 'package:device_info_plus/device_info_plus.dart';

import 'mobile_device_identity.dart';

abstract interface class DeviceNameSource {
  Future<String?> readName();
}

final class DeviceInfoNameSource implements DeviceNameSource {
  DeviceInfoNameSource({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  @override
  Future<String?> readName() async {
    final info = await _plugin.deviceInfo;
    if (info is IosDeviceInfo) {
      return info.name;
    }
    if (info is AndroidDeviceInfo) {
      return normalizeDeviceName(info.name) ?? info.model;
    }
    return null;
  }
}

final class DeviceNameProvider {
  DeviceNameProvider({DeviceNameSource? source})
    : _source = source ?? DeviceInfoNameSource();

  final DeviceNameSource _source;

  Future<String> suggest({required String localizedFallback}) async {
    final fallback = validateConfirmedDeviceName(localizedFallback);
    try {
      return normalizeDeviceName(await _source.readName()) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
