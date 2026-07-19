// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

const macOsDownloadPageUrl =
    'https://github.com/MisakiHCL/roammand/releases/latest';
const roammandRepositoryUrl = 'https://github.com/MisakiHCL/roammand';
const _englishUserGuideUrl =
    'https://github.com/MisakiHCL/roammand/blob/main/docs/user-guide/README.md';
const _chineseUserGuideUrl =
    'https://github.com/MisakiHCL/roammand/blob/main/docs/user-guide/README.zh-CN.md';

typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

Future<bool> launchExternalLink(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

Uri get macOsDownloadPageUri => Uri.parse(macOsDownloadPageUrl);

Uri get roammandRepositoryUri => Uri.parse(roammandRepositoryUrl);

Uri roammandUserGuideUri(Locale locale) => Uri.parse(
  locale.languageCode == 'zh' ? _chineseUserGuideUrl : _englishUserGuideUrl,
);
