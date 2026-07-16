// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Roammand';

  @override
  String get brandTagline => '离开桌面，工作仍在继续。';

  @override
  String get brandPrivacyLabel => '隐私优先 · 无需账号';

  @override
  String get mobileHomeSubtitle => '无论身在何处，你的电脑都触手可及。';

  @override
  String get desktopHomeSubtitle => '随时继续操作只属于你的电脑。';

  @override
  String get mobileIdentitySecurityNote => '无需账号，设备身份只受保护地保存在这台手机上。';

  @override
  String get computerReadyLabel => '可以连接';

  @override
  String get developmentStatus => '远程控制功能尚未开放。';

  @override
  String get desktopHostTitle => '桌面主机';

  @override
  String get hostAgentConnectingTitle => '正在连接主机代理…';

  @override
  String get hostAgentConnectingBody => '正在读取此电脑的本地身份与授权记录。';

  @override
  String get hostAgentOfflineTitle => '主机代理未运行';

  @override
  String get hostAgentOfflineBody => '请先启动主机代理，然后重试。本应用不会自动启动它。';

  @override
  String get hostAgentErrorTitle => '无法获取主机状态';

  @override
  String get hostAgentErrorBody => '本地主机代理返回了无效响应或临时错误。';

  @override
  String get retryAction => '重试';

  @override
  String get refreshAction => '刷新';

  @override
  String get privilegedBridgeSectionTitle => '特权会话桥接';

  @override
  String get privilegedBridgeNotInstalledTitle => '尚未安装';

  @override
  String get privilegedBridgeNotInstalledBody =>
      '请安装特权主机组件，以便在锁屏、登录和系统保护界面继续远程控制。';

  @override
  String get privilegedBridgeApprovalRequiredTitle => '需要管理员批准';

  @override
  String get privilegedBridgeApprovalRequiredBody => '请完成操作系统对已安装主机服务的批准。';

  @override
  String get privilegedBridgePermissionRequiredTitle => '需要系统权限';

  @override
  String get privilegedBridgePermissionRequiredBody =>
      '请在系统设置中允许所需的屏幕录制与辅助功能权限。';

  @override
  String get privilegedBridgeUserSessionOnlyTitle => '仅限当前用户会话';

  @override
  String get privilegedBridgeUserSessionOnlyBody =>
      '普通桌面可远程控制，但锁屏、登录和系统保护界面不可用。';

  @override
  String get privilegedBridgeReadyNormalTitle => '可以远程控制';

  @override
  String get privilegedBridgeReadyNormalBody => '特权桥接已安装，普通桌面可用。';

  @override
  String get privilegedBridgeReadyLockedTitle => '锁屏或登录界面已就绪';

  @override
  String get privilegedBridgeReadyLockedBody =>
      '受保护会话助手已连接，设备身份和永久授权仍只保留在主机代理中。';

  @override
  String get privilegedBridgeReadySecureTitle => '系统保护界面已就绪';

  @override
  String get privilegedBridgeReadySecureBody => '受保护会话助手已使用短期本地租约连接。';

  @override
  String get privilegedBridgeReadyUnavailableTitle => '没有交互式桌面';

  @override
  String get privilegedBridgeReadyUnavailableBody => '在操作系统发布交互式会话前，远程输入保持禁用。';

  @override
  String get privilegedBridgeTransitioningTitle => '正在切换桌面会话…';

  @override
  String get privilegedBridgeTransitioningBody => '主机验证新桌面会话中的助手期间，所有输入均已释放。';

  @override
  String get privilegedBridgeReconnectingTitle => '正在重连受保护会话…';

  @override
  String get privilegedBridgeReconnectingBody => '新受保护会话完成身份验证前，远程输入保持禁用。';

  @override
  String privilegedBridgeControlledTitle(String controllerName) {
    return '“$controllerName”正在控制';
  }

  @override
  String get privilegedBridgeControlledUnknownTitle => '远程控制正在进行';

  @override
  String get privilegedBridgeControlledBody => '可使用下方的“紧急停止”立即结束所有远程会话。';

  @override
  String get privilegedBridgeFailedTitle => '特权桥接不可用';

  @override
  String get privilegedBridgeFailedBody => '远程输入已禁用。请检查本地主机安装与系统权限。';

  @override
  String get privilegedBridgeUnknownTitle => '无法获取桥接状态';

  @override
  String get privilegedBridgeUnknownBody => '当前未确认远程输入受到保护。请刷新主机状态或检查安装。';

  @override
  String get emergencyStopAction => '紧急停止';

  @override
  String get emergencyStoppingAction => '正在停止…';

  @override
  String get emergencyStopDialogTitle => '停止远程控制？';

  @override
  String get emergencyStopDialogBody => '这会立即关闭所有远程会话并释放全部远程输入；永久设备授权会保留。';

  @override
  String get confirmEmergencyStopAction => '立即停止';

  @override
  String get emergencyStopSucceeded => '远程控制已停止。';

  @override
  String get emergencyStopFailed => '无法停止远程控制。请使用系统托盘，或在本机停止主机服务。';

  @override
  String get trayShowAction => '显示 Roammand';

  @override
  String get trayExitAction => '退出';

  @override
  String get trayExitControlledTitle => '远程控制进行中，仍要退出？';

  @override
  String get trayExitControlledBody => '退出前会先停止所有远程会话并释放全部远程输入。';

  @override
  String get trayConfirmExitAction => '停止并退出';

  @override
  String get hostIdentitySectionTitle => '此电脑';

  @override
  String hostShortFingerprint(String fingerprint) {
    return '短指纹：$fingerprint';
  }

  @override
  String get authorizedControllersSectionTitle => '已授权控制设备';

  @override
  String authorizedControllerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已授权 $count 台控制设备',
      zero: '没有已授权控制设备',
    );
    return '$_temp0';
  }

  @override
  String get noAuthorizedControllers => '尚未授权任何控制设备。';

  @override
  String get unknownControllerName => '未知控制设备';

  @override
  String grantCreatedLabel(String date) {
    return '授权时间：$date';
  }

  @override
  String grantLastConnectedLabel(String date) {
    return '最近连接：$date';
  }

  @override
  String get neverConnected => '从未连接';

  @override
  String get unknownDate => '未知';

  @override
  String get revokeAction => '撤销';

  @override
  String revokeDialogTitle(String controllerName) {
    return '撤销“$controllerName”的授权？';
  }

  @override
  String get revokeDialogBody => '此控制设备将立即失去对本主机的永久访问权。若要重新连接，必须再次配对。';

  @override
  String get cancelAction => '取消';

  @override
  String get confirmRevokeAction => '撤销授权';

  @override
  String get revokingAction => '正在撤销…';

  @override
  String get hostPairingSectionTitle => '添加新设备';

  @override
  String get hostPairingSectionBody => '手机可扫描此二维码，电脑可使用一次性配对码。只有本主机能够批准永久访问。';

  @override
  String get hostPairingEndpointMissing => '开始配对前，请先配置安全的信令地址。';

  @override
  String get hostPairingStartQrAction => '显示手机二维码';

  @override
  String get hostPairingStartCodeAction => '生成电脑配对码';

  @override
  String get hostPairingViewActiveAction => '查看当前配对';

  @override
  String get hostPairingQrTitle => '配对手机';

  @override
  String get hostPairingCodeTitle => '配对电脑';

  @override
  String get hostPairingQrInstructions => '请使用 Roammand 的相机扫码器扫描此二维码。';

  @override
  String get hostPairingCodeInstructions => '请在另一台电脑上输入此一次性配对码。';

  @override
  String get hostPairingQrSemantics => '手机配对二维码';

  @override
  String hostPairingExpiresIn(String remaining) {
    return '剩余 $remaining';
  }

  @override
  String get hostPairingCreating => '正在创建私密配对邀请…';

  @override
  String get hostPairingWaitingController => '正在等待另一台设备…';

  @override
  String get hostPairingVerifyingController => '正在验证另一台设备…';

  @override
  String get hostPairingPendingControllerTitle => '请求访问的设备';

  @override
  String hostPairingControllerFingerprint(String fingerprint) {
    return '短指纹：$fingerprint';
  }

  @override
  String get hostPairingCompareSas => '核对这四个单词';

  @override
  String get hostPairingSasInstructions => '请确认两台电脑显示的四个单词完全相同；任一单词不同都应拒绝请求。';

  @override
  String get hostPairingOneWayGrant => '允许后，将永久、单向授权此设备查看屏幕并控制输入。反向控制需要另行配对。';

  @override
  String get hostPairingAllowAction => '允许控制';

  @override
  String get hostPairingRejectAction => '拒绝';

  @override
  String get hostPairingCancelAction => '取消配对';

  @override
  String get hostPairingActionPending => '正在处理…';

  @override
  String get hostPairingAccepted => '已允许此设备';

  @override
  String get hostPairingRejected => '已拒绝此设备';

  @override
  String get hostPairingExpired => '配对已过期';

  @override
  String get hostPairingCancelled => '配对已取消';

  @override
  String get hostPairingFailed => '配对失败';

  @override
  String get closeAction => '关闭';

  @override
  String get devicePlatformIos => 'iPhone 或 iPad';

  @override
  String get devicePlatformAndroid => 'Android 设备';

  @override
  String get devicePlatformMacos => 'Mac';

  @override
  String get devicePlatformWindows => 'Windows 电脑';

  @override
  String get devicePlatformUnknown => '未知平台';

  @override
  String get trustedComputersTitle => '我的电脑';

  @override
  String get trustedComputersEmptyTitle => '尚未配对电脑';

  @override
  String get trustedComputersEmptyBody =>
      '使用电脑上的一次性配对码完成配对。以后将使用保存在本机的公开身份直接连接。';

  @override
  String get pairComputerAction => '配对电脑';

  @override
  String get trustedComputersLoadFailed => '无法读取已保存的电脑。';

  @override
  String get desktopPairingDialogTitle => '配对电脑';

  @override
  String get desktopPairingCodeLabel => '一次性配对码';

  @override
  String get desktopPairingCodeHint => 'ABCD-EFGH';

  @override
  String get invalidDesktopPairingCode => '配对码无效。';

  @override
  String get pairAction => '配对';

  @override
  String get desktopPairingConnecting => '正在加入私密配对邀请…';

  @override
  String get desktopPairingVerifying => '正在验证主机身份…';

  @override
  String get desktopPairingWaitingApproval => '正在等待主机批准…';

  @override
  String get desktopPairingSuccess => '电脑已配对';

  @override
  String get desktopPairingRejected => '主机已拒绝配对';

  @override
  String get desktopPairingExpired => '配对已过期';

  @override
  String get desktopPairingFailed => '配对失败';

  @override
  String trustedHostPairedLabel(String date) {
    return '配对时间：$date';
  }

  @override
  String trustedHostLastConnectedLabel(String date) {
    return '最近连接：$date';
  }

  @override
  String get openRemoteAction => '连接';

  @override
  String get deleteTrustedHostAction => '删除';

  @override
  String deleteTrustedHostTitle(String hostName) {
    return '从本机删除“$hostName”？';
  }

  @override
  String get deleteTrustedHostBody => '这只会删除此控制端保存的主机记录，不会撤销主机上的永久授权。';

  @override
  String get confirmDeleteAction => '仅在本机删除';

  @override
  String get mobileDeviceFallbackName => '我的手机';

  @override
  String get mobileOnboardingTitle => '为此手机命名';

  @override
  String get mobileOnboardingBody => '此名称只会显示给你配对的电脑。私有身份始终保存在本机。';

  @override
  String get mobileDeviceNameLabel => '设备名称';

  @override
  String get mobileConfirmIdentityAction => '继续';

  @override
  String get mobileIdentityLoading => '正在加载本机身份…';

  @override
  String get mobileIdentityFailed => '无法使用受保护的设备身份。';

  @override
  String get mobileHomeTitle => '我的电脑';

  @override
  String get mobileHomeEmptyTitle => '尚未配对电脑';

  @override
  String get mobileHomeEmptyBody => '扫描电脑上显示的二维码，将其与此手机配对。';

  @override
  String get mobileScanQrAction => '扫描电脑二维码';

  @override
  String get mobileScannerTitle => '扫描二维码';

  @override
  String get mobileScannerInstructions => '请将相机对准电脑上显示的配对二维码。';

  @override
  String get mobileScannerTorchAction => '开关手电筒';

  @override
  String get mobileScannerSwitchCameraAction => '切换摄像头';

  @override
  String get mobileScannerPermissionDenied => '相机权限已被拒绝。请在系统设置中允许相机权限后再扫码。';

  @override
  String get mobileScannerRestricted => '此设备上的相机访问受到限制。';

  @override
  String get mobileScannerNoCamera => '没有可用的相机。';

  @override
  String get mobileScannerInitializationFailed => '无法启动相机。';

  @override
  String get mobileInvalidQr => '此配对二维码无效或已过期，请扫描新二维码。';

  @override
  String get mobilePairingJoining => '正在加入私密配对邀请…';

  @override
  String get mobilePairingVerifying => '正在验证电脑身份…';

  @override
  String get mobilePairingWaitingApproval => '正在等待电脑批准…';

  @override
  String get mobilePairingSuccess => '电脑已配对';

  @override
  String get mobilePairingRejected => '电脑已拒绝配对';

  @override
  String get mobilePairingExpired => '配对已过期';

  @override
  String get mobilePairingCancelled => '配对已取消';

  @override
  String get mobilePairingFailed => '配对失败';

  @override
  String get mobilePairingSignalingFailed => '无法与信令服务通信。请检查信令地址和本地网络权限。';

  @override
  String get mobilePairingAuthenticationFailed => '无法验证电脑的配对身份。请重新生成二维码后再试。';

  @override
  String get mobilePairingPersistenceFailed => '配对已获批准，但无法安全保存这台电脑。';

  @override
  String get mobilePairingInternalFailed => '配对遇到内部错误，请重试。';

  @override
  String pairingSecondsRemaining(int seconds) {
    return '剩余 $seconds 秒';
  }

  @override
  String get mobileControlLaterNotice => '已配对，可以建立私密远程会话。';

  @override
  String get mobileGestureHint => '轻点、双击、拖动、滚动或双指缩放';

  @override
  String get mobileKeyboardAction => '键盘';

  @override
  String get mobileHideKeyboardAction => '隐藏键盘';

  @override
  String get mobileTextInputLabel => '发送文字到电脑';

  @override
  String get mobileSendTextAction => '发送文字';

  @override
  String get mobileModifierControl => 'Ctrl';

  @override
  String get mobileModifierShift => 'Shift';

  @override
  String get mobileModifierAlt => 'Alt';

  @override
  String get mobileModifierCommand => 'Command';

  @override
  String get mobileKeyEscape => 'Esc';

  @override
  String get mobileKeyTab => 'Tab';

  @override
  String get mobileKeyArrowLeft => '左';

  @override
  String get mobileKeyArrowUp => '上';

  @override
  String get mobileKeyArrowRight => '右';

  @override
  String get mobileKeyArrowDown => '下';

  @override
  String get remoteControlTab => '远程控制';

  @override
  String get thisComputerTab => '此电脑';

  @override
  String get languageMenuTooltip => '切换语言';

  @override
  String get languageSystemOption => '跟随系统';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get languageSimplifiedChineseOption => '简体中文';

  @override
  String get desktopControlTitle => '控制一台电脑';

  @override
  String get desktopControlBody => '粘贴来自已授权电脑的连接描述符，以启动私密远程会话。';

  @override
  String get hostConnectionDescriptorLabel => '主机连接描述符';

  @override
  String get hostConnectionDescriptorHint => '在此粘贴主机的公开描述符';

  @override
  String get hostConnectionDescriptorPrivacy => '描述符只包含主机公开身份与信令地址，绝不包含私钥。';

  @override
  String get invalidHostDescriptor => '连接描述符无效。';

  @override
  String get connectAction => '连接';

  @override
  String get connectingAction => '正在连接…';

  @override
  String remoteDesktopTitle(String hostName) {
    return '远程桌面 — $hostName';
  }

  @override
  String get closeSessionAction => '关闭连接';

  @override
  String get remoteInputHint => '点击桌面后可发送鼠标和键盘输入。';

  @override
  String get localExitShortcutHint => '本地退出：Ctrl+Alt+Shift+Esc';

  @override
  String get remoteIdle => '就绪';

  @override
  String get remoteConnecting => '正在连接本地身份与信令服务…';

  @override
  String get remoteReconnectingPending => '连接已中断，正在准备安全重连…';

  @override
  String remoteReconnecting(int attempt, int maximum, int seconds) {
    return '正在重连…第 $attempt/$maximum 次尝试，剩余 $seconds 秒。';
  }

  @override
  String get remoteAuthenticating => '正在本地签署会话请求…';

  @override
  String get remoteNegotiating => '正在等待主机验证并响应…';

  @override
  String get remoteConnected => '已连接';

  @override
  String get remoteClosing => '正在关闭并释放输入…';

  @override
  String get remoteAuthenticationFailed => '主机身份验证失败。';

  @override
  String get remoteHostAgentFailed => '本地主机代理不可用。';

  @override
  String get remoteLocalIdentityFailed => '无法使用此控制端身份。';

  @override
  String get remoteSignalingFailed => '信令连接失败。';

  @override
  String get remoteConfigurationFailed => '远程连接设置无效。';

  @override
  String get remoteConnectionFailed => '远程会话失败。';

  @override
  String get retryRemoteAction => '重试';

  @override
  String get diagnosticsAction => '诊断';

  @override
  String get diagnosticsTitle => '隐私安全诊断';

  @override
  String get diagnosticsPreviewBody =>
      '连接或重连失败时，可保存这份本地报告，用于排查会话状态、耗时和 WebRTC 聚合健康指标。保存前可明确查看包含与排除的数据；报告不会上传，也不会复制到剪贴板。';

  @override
  String get diagnosticsIncludedTitle => '包含';

  @override
  String get diagnosticsExcludedTitle => '排除';

  @override
  String get diagnosticsIncludedVersions => '应用、协议和操作系统版本';

  @override
  String get diagnosticsIncludedSession => '会话状态和稳定错误代码';

  @override
  String get diagnosticsIncludedReconnect => '重连次数和时间信息';

  @override
  String get diagnosticsIncludedWebRtc => 'WebRTC 聚合指标';

  @override
  String get diagnosticsExcludedDeviceIdentifiers => '设备标识符';

  @override
  String get diagnosticsExcludedDeviceNames => '设备名称';

  @override
  String get diagnosticsExcludedKeys => '密钥和签名';

  @override
  String get diagnosticsExcludedTokens => 'Nonce、令牌和密码';

  @override
  String get diagnosticsExcludedSdpIce => 'SDP 和 ICE candidate';

  @override
  String get diagnosticsExcludedNetworkAddresses => 'IP 地址和端口';

  @override
  String get diagnosticsExcludedInput => '输入内容和坐标';

  @override
  String get diagnosticsExcludedScreen => '屏幕内容';

  @override
  String get diagnosticsExcludedRawPayloads => '原始信令和数据通道载荷';

  @override
  String get diagnosticsExcludedRawStats => '原始 WebRTC 统计数据';

  @override
  String diagnosticsEventSummary(int count, String truncated) {
    return '已采集事件：$count。已截断：$truncated。';
  }

  @override
  String get diagnosticsTruncatedYes => '是';

  @override
  String get diagnosticsTruncatedNo => '否';

  @override
  String get diagnosticsSaveAction => '保存报告';

  @override
  String get diagnosticsSavingAction => '正在保存…';

  @override
  String diagnosticsSaved(String path) {
    return '已在本地保存到 $path';
  }

  @override
  String get diagnosticsSaveFailed => '无法保存诊断报告。';
}
