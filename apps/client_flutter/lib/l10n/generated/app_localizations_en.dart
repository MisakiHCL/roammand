// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Roammand';

  @override
  String get brandTagline => 'Leave the desk. Keep work moving.';

  @override
  String get brandPrivacyLabel => 'Private · Account-free';

  @override
  String get mobileHomeSubtitle => 'Your computers, ready wherever you are.';

  @override
  String get desktopHomeSubtitle =>
      'Continue work on your own computers from anywhere.';

  @override
  String get mobileIdentitySecurityNote =>
      'No account. This device identity stays protected on your phone.';

  @override
  String get computerReadyLabel => 'Ready to connect';

  @override
  String get developmentStatus => 'Remote control is not available yet.';

  @override
  String get desktopHostTitle => 'Desktop Host';

  @override
  String get hostAgentConnectingTitle => 'Connecting to Host Agent…';

  @override
  String get hostAgentConnectingBody =>
      'Reading this computer\'s local identity and authorizations.';

  @override
  String get hostAgentOfflineTitle => 'Host Agent is not running';

  @override
  String get hostAgentOfflineBody =>
      'Roammand could not reach the local Host Agent. Retry or reinstall Roammand if the problem continues.';

  @override
  String get hostAgentProtectedSessionUnavailableTitle =>
      'Protected-session Agent is not running';

  @override
  String get hostAgentProtectedSessionUnavailableBody =>
      'The component for the current macOS session is unavailable. Retry or reinstall Roammand if the problem continues.';

  @override
  String get hostAgentPrivilegedBridgeUnavailableTitle =>
      'Privileged bridge is unavailable';

  @override
  String get hostAgentPrivilegedBridgeUnavailableBody =>
      'The installed privileged bridge could not be verified or reached. Reinstall Roammand, then retry.';

  @override
  String get hostAgentComponentMissingTitle => 'Host Agent is missing';

  @override
  String get hostAgentComponentMissingBody =>
      'The installed Host Agent executable was not found. Reinstall Roammand, then retry.';

  @override
  String get hostAgentLaunchFailedTitle => 'Host Agent could not start';

  @override
  String get hostAgentLaunchFailedBody =>
      'macOS could not launch the installed Host Agent. Reinstall Roammand, then retry.';

  @override
  String get hostAgentConfigurationInvalidTitle =>
      'Connection configuration is invalid';

  @override
  String get hostAgentConfigurationInvalidBody =>
      'Check the signaling and STUN settings, then retry.';

  @override
  String get hostAgentUnexpectedExitTitle => 'Host Agent exited unexpectedly';

  @override
  String get hostAgentUnexpectedExitBody =>
      'The Host Agent stopped during startup. Retry or reinstall Roammand if the problem continues.';

  @override
  String get hostAgentErrorTitle => 'Host status is unavailable';

  @override
  String get hostAgentErrorBody =>
      'The local Host Agent returned an invalid or temporary error.';

  @override
  String get retryAction => 'Retry';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get privilegedBridgeSectionTitle => 'Privileged session bridge';

  @override
  String get privilegedBridgeNotInstalledTitle => 'Not installed';

  @override
  String get privilegedBridgeNotInstalledBody =>
      'Install the privileged Host components to keep remote control available at lock, login, and protected system screens.';

  @override
  String get privilegedBridgeApprovalRequiredTitle =>
      'Administrator approval required';

  @override
  String get privilegedBridgeApprovalRequiredBody =>
      'Complete the operating-system approval for the installed Host service.';

  @override
  String get privilegedBridgePermissionRequiredTitle =>
      'System permissions required';

  @override
  String get privilegedBridgePermissionRequiredBody =>
      'Allow the requested screen recording and accessibility permissions in system settings.';

  @override
  String get privilegedBridgeUserSessionOnlyTitle =>
      'Current user session only';

  @override
  String get privilegedBridgeUserSessionOnlyBody =>
      'Normal desktop control is available, but lock, login, and protected system screens are not.';

  @override
  String get privilegedBridgeReadyNormalTitle => 'Ready for remote control';

  @override
  String get privilegedBridgeReadyNormalBody =>
      'The privileged bridge is installed and the normal desktop is available.';

  @override
  String get privilegedBridgeReadyLockedTitle =>
      'Ready on the lock or login screen';

  @override
  String get privilegedBridgeReadyLockedBody =>
      'The protected session Helper is connected without moving device identity or permanent grants out of the Host Agent.';

  @override
  String get privilegedBridgeReadySecureTitle =>
      'Ready on a protected system screen';

  @override
  String get privilegedBridgeReadySecureBody =>
      'The protected session Helper is connected with a short-lived local lease.';

  @override
  String get privilegedBridgeReadyUnavailableTitle => 'No interactive desktop';

  @override
  String get privilegedBridgeReadyUnavailableBody =>
      'Remote input remains disabled until the operating system publishes an interactive session.';

  @override
  String get privilegedBridgeTransitioningTitle => 'Switching desktop session…';

  @override
  String get privilegedBridgeTransitioningBody =>
      'Input is released while the Host authenticates a Helper in the new desktop session.';

  @override
  String get privilegedBridgeReconnectingTitle =>
      'Reconnecting protected session…';

  @override
  String get privilegedBridgeReconnectingBody =>
      'Input remains disabled until the new protected session is authenticated.';

  @override
  String privilegedBridgeControlledTitle(String controllerName) {
    return 'Controlled by $controllerName';
  }

  @override
  String get privilegedBridgeControlledUnknownTitle =>
      'Remote control is active';

  @override
  String get privilegedBridgeControlledBody =>
      'Use Emergency stop below to end every active remote session immediately.';

  @override
  String get privilegedBridgeFailedTitle => 'Privileged bridge unavailable';

  @override
  String get privilegedBridgeFailedBody =>
      'Remote input is disabled. Check the local Host installation and system permissions.';

  @override
  String get privilegedBridgeUnknownTitle => 'Bridge status unavailable';

  @override
  String get privilegedBridgeUnknownBody =>
      'Remote input is not reported as protected. Refresh the Host status or check the installation.';

  @override
  String get emergencyStopAction => 'Emergency stop';

  @override
  String get emergencyStoppingAction => 'Stopping…';

  @override
  String get emergencyStopDialogTitle => 'Stop remote control?';

  @override
  String get emergencyStopDialogBody =>
      'This immediately closes every active remote session and releases all remote input. Permanent device authorizations are preserved.';

  @override
  String get confirmEmergencyStopAction => 'Stop now';

  @override
  String get emergencyStopSucceeded => 'Remote control stopped.';

  @override
  String get emergencyStopFailed =>
      'Remote control could not be stopped. Use the system tray or stop the Host service locally.';

  @override
  String get trayShowAction => 'Show Roammand';

  @override
  String get trayExitAction => 'Exit';

  @override
  String get trayExitControlledTitle => 'Exit while remote control is active?';

  @override
  String get trayExitControlledBody =>
      'Exiting will first stop every remote session and release all remote input.';

  @override
  String get trayConfirmExitAction => 'Stop and exit';

  @override
  String get hostIdentitySectionTitle => 'This computer';

  @override
  String hostShortFingerprint(String fingerprint) {
    return 'Short fingerprint: $fingerprint';
  }

  @override
  String get authorizedControllersSectionTitle => 'Authorized controllers';

  @override
  String authorizedControllerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count authorized controllers',
      one: '1 authorized controller',
      zero: 'No authorized controllers',
    );
    return '$_temp0';
  }

  @override
  String get noAuthorizedControllers => 'No controllers are authorized yet.';

  @override
  String get unknownControllerName => 'Unknown controller';

  @override
  String grantCreatedLabel(String date) {
    return 'Authorized: $date';
  }

  @override
  String grantLastConnectedLabel(String date) {
    return 'Last connected: $date';
  }

  @override
  String get neverConnected => 'Never';

  @override
  String get unknownDate => 'Unknown';

  @override
  String get revokeAction => 'Revoke';

  @override
  String revokeDialogTitle(String controllerName) {
    return 'Revoke $controllerName?';
  }

  @override
  String get revokeDialogBody =>
      'This controller will immediately lose permanent access to this Host. Reconnecting requires a new pairing.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get confirmRevokeAction => 'Revoke access';

  @override
  String get revokingAction => 'Revoking…';

  @override
  String get hostPairingSectionTitle => 'Add a new device';

  @override
  String get hostPairingSectionBody =>
      'Pair a phone with this QR code or a computer with a one-time code. Only this Host can approve permanent access.';

  @override
  String get hostPairingEndpointMissing =>
      'Configure a secure signaling endpoint before starting pairing.';

  @override
  String get hostPairingStartQrAction => 'Show mobile QR code';

  @override
  String get hostPairingStartCodeAction => 'Generate computer pairing code';

  @override
  String get hostPairingViewActiveAction => 'View current pairing';

  @override
  String get hostPairingQrTitle => 'Pair a phone';

  @override
  String get hostPairingCodeTitle => 'Pair a computer';

  @override
  String get hostPairingQrInstructions =>
      'Scan this code with the Roammand camera scanner.';

  @override
  String get hostPairingCodeInstructions =>
      'Enter this one-time code on the other computer.';

  @override
  String get hostPairingQrSemantics => 'Mobile pairing QR code';

  @override
  String hostPairingExpiresIn(String remaining) {
    return 'Expires in $remaining';
  }

  @override
  String get hostPairingCreating => 'Creating a private pairing invitation…';

  @override
  String get hostPairingWaitingController => 'Waiting for the other device…';

  @override
  String get hostPairingVerifyingController => 'Verifying the other device…';

  @override
  String get hostPairingPendingControllerTitle => 'Device requesting access';

  @override
  String hostPairingControllerFingerprint(String fingerprint) {
    return 'Short fingerprint: $fingerprint';
  }

  @override
  String get hostPairingCompareSas => 'Compare these four words';

  @override
  String get hostPairingSasInstructions =>
      'Confirm that all four words match on both computers. If any word differs, reject the request.';

  @override
  String get hostPairingOneWayGrant =>
      'Allowing creates permanent, one-way permission for this device to view the screen and control input. Reverse control requires a separate pairing.';

  @override
  String get hostPairingAllowAction => 'Allow control';

  @override
  String get hostPairingRejectAction => 'Reject';

  @override
  String get hostPairingCancelAction => 'Cancel pairing';

  @override
  String get hostPairingActionPending => 'Applying…';

  @override
  String get hostPairingAccepted => 'Device allowed';

  @override
  String get hostPairingRejected => 'Device rejected';

  @override
  String get hostPairingExpired => 'Pairing expired';

  @override
  String get hostPairingCancelled => 'Pairing cancelled';

  @override
  String get hostPairingFailed => 'Pairing failed';

  @override
  String get closeAction => 'Close';

  @override
  String get devicePlatformIos => 'iPhone or iPad';

  @override
  String get devicePlatformAndroid => 'Android';

  @override
  String get devicePlatformMacos => 'Mac';

  @override
  String get devicePlatformWindows => 'Windows PC';

  @override
  String get devicePlatformUnknown => 'Unknown platform';

  @override
  String get trustedComputersTitle => 'My computers';

  @override
  String get trustedComputersEmptyTitle => 'No computers paired yet';

  @override
  String get trustedComputersEmptyBody =>
      'Pair a computer with its one-time code. Future connections use the saved public identity on this device.';

  @override
  String get pairComputerAction => 'Pair a computer';

  @override
  String get trustedComputersLoadFailed => 'Saved computers are unavailable.';

  @override
  String get desktopPairingDialogTitle => 'Pair a computer';

  @override
  String get desktopPairingCodeLabel => 'One-time pairing code';

  @override
  String get desktopPairingCodeHint => 'ABCD-EFGH';

  @override
  String get invalidDesktopPairingCode => 'Pairing code is invalid.';

  @override
  String get pairAction => 'Pair';

  @override
  String get desktopPairingConnecting =>
      'Joining the private pairing invitation…';

  @override
  String get desktopPairingVerifying => 'Verifying the Host identity…';

  @override
  String get desktopPairingWaitingApproval =>
      'Waiting for approval on the Host…';

  @override
  String get desktopPairingSuccess => 'Computer paired';

  @override
  String get desktopPairingRejected => 'The Host rejected pairing';

  @override
  String get desktopPairingExpired => 'Pairing expired';

  @override
  String get desktopPairingFailed => 'Pairing failed';

  @override
  String trustedHostPairedLabel(String date) {
    return 'Paired: $date';
  }

  @override
  String trustedHostLastConnectedLabel(String date) {
    return 'Last connected: $date';
  }

  @override
  String get openRemoteAction => 'Connect';

  @override
  String get deleteTrustedHostAction => 'Delete';

  @override
  String deleteTrustedHostTitle(String hostName) {
    return 'Delete $hostName from this device?';
  }

  @override
  String get deleteTrustedHostBody =>
      'This only deletes the saved Host record on this Controller. It does not revoke the permanent grant on the Host.';

  @override
  String get confirmDeleteAction => 'Delete locally';

  @override
  String get mobileDeviceFallbackName => 'My phone';

  @override
  String get mobileOnboardingTitle => 'Name this phone';

  @override
  String get mobileOnboardingBody =>
      'This name is shown only to computers you pair with. Your private identity stays on this device.';

  @override
  String get mobileDeviceNameLabel => 'Device name';

  @override
  String get mobileConfirmIdentityAction => 'Continue';

  @override
  String get mobileIdentityLoading => 'Loading this device identity…';

  @override
  String get mobileIdentityFailed =>
      'The protected device identity is unavailable.';

  @override
  String get mobileHomeTitle => 'My computers';

  @override
  String get mobileHomeEmptyTitle => 'No computers paired yet';

  @override
  String get mobileHomeEmptyBody =>
      'Scan a QR code shown by your computer to pair it with this phone.';

  @override
  String get mobileScanQrAction => 'Scan computer QR code';

  @override
  String get mobileScannerTitle => 'Scan QR code';

  @override
  String get mobileScannerInstructions =>
      'Point the camera at the QR code shown on your computer.';

  @override
  String get mobileScannerTorchAction => 'Toggle flashlight';

  @override
  String get mobileScannerSwitchCameraAction => 'Switch camera';

  @override
  String get mobileScannerPermissionDenied =>
      'Camera access was denied. Allow camera access in system settings to scan a pairing QR code.';

  @override
  String get mobileScannerRestricted =>
      'Camera access is restricted on this device.';

  @override
  String get mobileScannerNoCamera => 'No usable camera is available.';

  @override
  String get mobileScannerInitializationFailed =>
      'The camera could not be started.';

  @override
  String get mobileInvalidQr =>
      'This pairing QR code is invalid or expired. Scan a new code.';

  @override
  String get mobilePairingJoining => 'Joining the private pairing invitation…';

  @override
  String get mobilePairingVerifying => 'Verifying the computer identity…';

  @override
  String get mobilePairingWaitingApproval =>
      'Waiting for approval on the computer…';

  @override
  String get mobilePairingSuccess => 'Computer paired';

  @override
  String get mobilePairingRejected => 'The computer rejected pairing';

  @override
  String get mobilePairingExpired => 'Pairing expired';

  @override
  String get mobilePairingCancelled => 'Pairing cancelled';

  @override
  String get mobilePairingFailed => 'Pairing failed';

  @override
  String get mobilePairingSignalingFailed =>
      'Could not communicate with the signaling service. Check the signaling address and local network access.';

  @override
  String get mobilePairingAuthenticationFailed =>
      'Could not verify the computer\'s pairing identity. Generate a new QR code and try again.';

  @override
  String get mobilePairingPersistenceFailed =>
      'Pairing was approved, but this computer could not be saved securely.';

  @override
  String get mobilePairingInternalFailed =>
      'Pairing encountered an internal error. Please try again.';

  @override
  String pairingSecondsRemaining(int seconds) {
    return '${seconds}s remaining';
  }

  @override
  String get mobileControlLaterNotice =>
      'Paired and ready for a private remote session.';

  @override
  String get mobileGestureHint => 'Tap, double-tap, drag, scroll, or pinch';

  @override
  String get mobileKeyboardAction => 'Keyboard';

  @override
  String get mobileHideKeyboardAction => 'Hide keyboard';

  @override
  String get mobileTextInputLabel => 'Text to computer';

  @override
  String get mobileSendTextAction => 'Send text';

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
  String get mobileKeyArrowLeft => 'Left';

  @override
  String get mobileKeyArrowUp => 'Up';

  @override
  String get mobileKeyArrowRight => 'Right';

  @override
  String get mobileKeyArrowDown => 'Down';

  @override
  String get remoteControlTab => 'Remote control';

  @override
  String get thisComputerTab => 'This computer';

  @override
  String get languageMenuTooltip => 'Change language';

  @override
  String get languageSystemOption => 'Follow system';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get languageSimplifiedChineseOption => '简体中文';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneralSection => 'General';

  @override
  String get settingsConnectionSection => 'Connection';

  @override
  String get settingsAdvancedSection => 'Advanced';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageBody => 'Choose the language used by Roammand.';

  @override
  String get uninstallSettingsTitle => 'Uninstall Roammand';

  @override
  String get uninstallSettingsBody =>
      'Remove the app and installed background components from this Mac.';

  @override
  String get uninstallDevelopmentBuildBody =>
      'Uninstall is available from the installed macOS app, not a development build.';

  @override
  String get uninstallUnavailableBody =>
      'The protected uninstaller is missing. Reinstall Roammand before uninstalling.';

  @override
  String get uninstallCheckingBody => 'Checking the installed uninstaller…';

  @override
  String get uninstallConfirmTitle => 'Uninstall Roammand?';

  @override
  String get uninstallConfirmBody =>
      'Remote sessions will stop and the app, Host Agent, privileged bridge, and protected-session Agent will be removed.';

  @override
  String get uninstallPreserveDataNotice =>
      'This keeps this Mac’s device identity, pairing records, and preferences so they can be restored after reinstalling.';

  @override
  String get uninstallConfirmAction => 'Uninstall';

  @override
  String get uninstallFailed =>
      'Roammand could not be uninstalled. No personal data was removed.';

  @override
  String get desktopControlTitle => 'Control a computer';

  @override
  String get desktopControlBody =>
      'Paste a connection descriptor from an authorized computer to start a private remote session.';

  @override
  String get hostConnectionDescriptorLabel => 'Host connection descriptor';

  @override
  String get hostConnectionDescriptorHint =>
      'Paste the public Host descriptor here';

  @override
  String get hostConnectionDescriptorPrivacy =>
      'The descriptor contains only the Host public identity and signaling address. It never contains a private key.';

  @override
  String get invalidHostDescriptor => 'Connection descriptor is invalid.';

  @override
  String get connectAction => 'Connect';

  @override
  String get connectingAction => 'Connecting…';

  @override
  String remoteDesktopTitle(String hostName) {
    return 'Remote desktop — $hostName';
  }

  @override
  String get closeSessionAction => 'Close connection';

  @override
  String get remoteInputHint =>
      'Click the desktop to send mouse and keyboard input.';

  @override
  String get localExitShortcutHint => 'Local exit: Ctrl+Alt+Shift+Esc';

  @override
  String get remoteIdle => 'Ready';

  @override
  String get remoteConnecting => 'Connecting to local identity and signaling…';

  @override
  String get remoteReconnectingPending =>
      'Connection interrupted. Preparing a secure retry…';

  @override
  String remoteReconnecting(int attempt, int maximum, int seconds) {
    return 'Reconnecting… attempt $attempt of $maximum. $seconds seconds remaining.';
  }

  @override
  String get remoteAuthenticating => 'Signing the session offer locally…';

  @override
  String get remoteNegotiating => 'Waiting for the Host to verify and answer…';

  @override
  String get remoteConnected => 'Connected';

  @override
  String get remoteClosing => 'Closing and releasing input…';

  @override
  String get remoteAuthenticationFailed => 'Host authentication failed.';

  @override
  String get remoteHostAgentFailed => 'The local Host Agent is unavailable.';

  @override
  String get remoteLocalIdentityFailed =>
      'This Controller identity is unavailable.';

  @override
  String get remoteSignalingFailed => 'The signaling connection failed.';

  @override
  String get remoteConfigurationFailed =>
      'Remote connection settings are invalid.';

  @override
  String get remoteConnectionFailed => 'The remote session failed.';

  @override
  String get retryRemoteAction => 'Try again';

  @override
  String get diagnosticsAction => 'Diagnostics';

  @override
  String get diagnosticsTitle => 'Privacy-safe diagnostics';

  @override
  String get diagnosticsPreviewBody =>
      'When a connection or reconnect fails, save this local report to troubleshoot session state, timing, and aggregate WebRTC health. Review exactly what it includes and excludes before saving. Nothing is uploaded or copied to the clipboard.';

  @override
  String get diagnosticsIncludedTitle => 'Included';

  @override
  String get diagnosticsExcludedTitle => 'Excluded';

  @override
  String get diagnosticsIncludedVersions => 'App, protocol, and OS versions';

  @override
  String get diagnosticsIncludedSession =>
      'Session states and stable error codes';

  @override
  String get diagnosticsIncludedReconnect => 'Reconnect attempts and timing';

  @override
  String get diagnosticsIncludedWebRtc => 'Aggregate WebRTC metrics';

  @override
  String get diagnosticsExcludedDeviceIdentifiers => 'Device identifiers';

  @override
  String get diagnosticsExcludedDeviceNames => 'Device names';

  @override
  String get diagnosticsExcludedKeys => 'Keys and signatures';

  @override
  String get diagnosticsExcludedTokens => 'Nonces, tokens, and passwords';

  @override
  String get diagnosticsExcludedSdpIce => 'SDP and ICE candidates';

  @override
  String get diagnosticsExcludedNetworkAddresses => 'IP addresses and ports';

  @override
  String get diagnosticsExcludedInput => 'Input content and coordinates';

  @override
  String get diagnosticsExcludedScreen => 'Screen content';

  @override
  String get diagnosticsExcludedRawPayloads =>
      'Raw signaling and data-channel payloads';

  @override
  String get diagnosticsExcludedRawStats => 'Raw WebRTC statistics';

  @override
  String diagnosticsEventSummary(int count, String truncated) {
    return 'Captured events: $count. Truncated: $truncated.';
  }

  @override
  String get diagnosticsTruncatedYes => 'yes';

  @override
  String get diagnosticsTruncatedNo => 'no';

  @override
  String get diagnosticsSaveAction => 'Save report';

  @override
  String get diagnosticsSavingAction => 'Saving…';

  @override
  String diagnosticsSaved(String path) {
    return 'Saved locally to $path';
  }

  @override
  String get diagnosticsSaveFailed => 'Unable to save the diagnostics report.';

  @override
  String get networkSettingsTooltip => 'Network service settings';

  @override
  String get networkSettingsTitle => 'Network services';

  @override
  String get networkSettingsBody =>
      'Choose the signaling and STUN services used to find devices and establish direct connections.';

  @override
  String get networkProfileLabel => 'Service profile';

  @override
  String get networkOfficialProfile => 'Official service';

  @override
  String get networkOfficialProfileBody =>
      'Use the built-in Roammand service defaults.';

  @override
  String get networkCustomProfile => 'Custom service';

  @override
  String get networkCustomProfileBody =>
      'Use a development or self-hosted signaling and STUN service.';

  @override
  String get networkSignalingEndpointLabel => 'Signaling WebSocket address';

  @override
  String get networkSignalingEndpointHint =>
      'wss://signal.example.com/v1/connect';

  @override
  String get networkStunUrlsLabel => 'STUN addresses';

  @override
  String get networkStunUrlsHint => 'One stun: or stuns: address per line';

  @override
  String get networkStunOptionalNotice =>
      'STUN is optional for local testing. This release has no TURN fallback, so some restrictive networks cannot connect.';

  @override
  String get networkMobileHostBindingNotice =>
      'A paired computer keeps its signaling address from the QR code. This profile supplies the STUN service used for direct connections and the default for new manual pairing flows.';

  @override
  String get networkSaveAction => 'Save configuration';

  @override
  String get networkSavingAction => 'Saving…';

  @override
  String get networkRestoreAction => 'Restore official defaults';

  @override
  String get networkInvalidSignaling =>
      'Enter a valid secure signaling WebSocket address. Private ws:// addresses are allowed only in an explicitly enabled debug build.';

  @override
  String get networkInvalidStun =>
      'Enter only valid stun: or stuns: addresses, one per line.';

  @override
  String get networkInvalidConfiguration =>
      'The signaling or STUN configuration is invalid.';

  @override
  String get networkSaveFailed =>
      'The network configuration could not be saved.';

  @override
  String get networkChangeHostTitle =>
      'Change this computer\'s network service?';

  @override
  String get networkChangeHostBody =>
      'The managed Host Agent will restart and active remote sessions will end. If the signaling address changes, previously paired devices must scan a new QR code before they can find this computer again.';

  @override
  String get networkConfirmChangeAction => 'Save and restart';

  @override
  String get networkConfigurationSaved => 'Network configuration saved.';

  @override
  String get networkHostMigrationSaved =>
      'Server changed. Show a new QR code to previously paired phones.';

  @override
  String get networkExternalHostRestartRequired =>
      'Configuration saved. The currently connected development Host Agent is independently managed; restart it with the same settings.';

  @override
  String get networkHostRestartFailed =>
      'Configuration saved, but the managed Host Agent could not restart. Exit and reopen Roammand, then verify the service settings.';

  @override
  String get mobileUnfamiliarServerTitle =>
      'Connect to a different signaling service?';

  @override
  String mobileUnfamiliarServerBody(String endpoint) {
    return 'This QR code will connect to $endpoint. The service can observe connection metadata and disrupt availability. Continue only if you trust the computer and service operator.';
  }

  @override
  String get mobileTrustServerAction => 'Trust and continue';
}
