import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Roammand'**
  String get appTitle;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Leave the desk. Keep work moving.'**
  String get brandTagline;

  /// No description provided for @brandPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private · Account-free'**
  String get brandPrivacyLabel;

  /// No description provided for @mobileHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your computers, ready wherever you are.'**
  String get mobileHomeSubtitle;

  /// No description provided for @desktopHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue work on your own computers from anywhere.'**
  String get desktopHomeSubtitle;

  /// No description provided for @mobileIdentitySecurityNote.
  ///
  /// In en, this message translates to:
  /// **'No account. This device identity stays protected on your phone.'**
  String get mobileIdentitySecurityNote;

  /// No description provided for @computerReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready to connect'**
  String get computerReadyLabel;

  /// No description provided for @developmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Remote control is not available yet.'**
  String get developmentStatus;

  /// No description provided for @desktopHostTitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop Host'**
  String get desktopHostTitle;

  /// No description provided for @hostAgentConnectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Host Agent…'**
  String get hostAgentConnectingTitle;

  /// No description provided for @hostAgentConnectingBody.
  ///
  /// In en, this message translates to:
  /// **'Reading this computer\'s local identity and authorizations.'**
  String get hostAgentConnectingBody;

  /// No description provided for @hostAgentOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Agent is not running'**
  String get hostAgentOfflineTitle;

  /// No description provided for @hostAgentOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Roammand could not reach the local Host Agent. Retry or reinstall Roammand if the problem continues.'**
  String get hostAgentOfflineBody;

  /// No description provided for @hostAgentProtectedSessionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected-session Agent is not running'**
  String get hostAgentProtectedSessionUnavailableTitle;

  /// No description provided for @hostAgentProtectedSessionUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The component for the current macOS session is unavailable. Retry or reinstall Roammand if the problem continues.'**
  String get hostAgentProtectedSessionUnavailableBody;

  /// No description provided for @hostAgentPrivilegedBridgeUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Privileged bridge is unavailable'**
  String get hostAgentPrivilegedBridgeUnavailableTitle;

  /// No description provided for @hostAgentPrivilegedBridgeUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The installed privileged bridge could not be verified or reached. Reinstall Roammand, then retry.'**
  String get hostAgentPrivilegedBridgeUnavailableBody;

  /// No description provided for @hostAgentComponentMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Agent is missing'**
  String get hostAgentComponentMissingTitle;

  /// No description provided for @hostAgentComponentMissingBody.
  ///
  /// In en, this message translates to:
  /// **'The installed Host Agent executable was not found. Reinstall Roammand, then retry.'**
  String get hostAgentComponentMissingBody;

  /// No description provided for @hostAgentLaunchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Agent could not start'**
  String get hostAgentLaunchFailedTitle;

  /// No description provided for @hostAgentLaunchFailedBody.
  ///
  /// In en, this message translates to:
  /// **'macOS could not launch the installed Host Agent. Reinstall Roammand, then retry.'**
  String get hostAgentLaunchFailedBody;

  /// No description provided for @hostAgentConfigurationInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection configuration is invalid'**
  String get hostAgentConfigurationInvalidTitle;

  /// No description provided for @hostAgentConfigurationInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'Check the signaling and STUN settings, then retry.'**
  String get hostAgentConfigurationInvalidBody;

  /// No description provided for @hostAgentUnexpectedExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Agent exited unexpectedly'**
  String get hostAgentUnexpectedExitTitle;

  /// No description provided for @hostAgentUnexpectedExitBody.
  ///
  /// In en, this message translates to:
  /// **'The Host Agent stopped during startup. Retry or reinstall Roammand if the problem continues.'**
  String get hostAgentUnexpectedExitBody;

  /// No description provided for @hostAgentErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Host status is unavailable'**
  String get hostAgentErrorTitle;

  /// No description provided for @hostAgentErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The local Host Agent returned an invalid or temporary error.'**
  String get hostAgentErrorBody;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @privilegedBridgeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privileged session bridge'**
  String get privilegedBridgeSectionTitle;

  /// No description provided for @privilegedBridgeNotInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get privilegedBridgeNotInstalledTitle;

  /// No description provided for @privilegedBridgeNotInstalledBody.
  ///
  /// In en, this message translates to:
  /// **'Install the privileged Host components to keep remote control available at lock, login, and protected system screens.'**
  String get privilegedBridgeNotInstalledBody;

  /// No description provided for @privilegedBridgeApprovalRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Administrator approval required'**
  String get privilegedBridgeApprovalRequiredTitle;

  /// No description provided for @privilegedBridgeApprovalRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Complete the operating-system approval for the installed Host service.'**
  String get privilegedBridgeApprovalRequiredBody;

  /// No description provided for @privilegedBridgePermissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'System permissions required'**
  String get privilegedBridgePermissionRequiredTitle;

  /// No description provided for @privilegedBridgePermissionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Allow the requested screen recording and accessibility permissions in system settings.'**
  String get privilegedBridgePermissionRequiredBody;

  /// No description provided for @privilegedBridgeUserSessionOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Current user session only'**
  String get privilegedBridgeUserSessionOnlyTitle;

  /// No description provided for @privilegedBridgeUserSessionOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Normal desktop control is available, but lock, login, and protected system screens are not.'**
  String get privilegedBridgeUserSessionOnlyBody;

  /// No description provided for @privilegedBridgeReadyNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for remote control'**
  String get privilegedBridgeReadyNormalTitle;

  /// No description provided for @privilegedBridgeReadyNormalBody.
  ///
  /// In en, this message translates to:
  /// **'The privileged bridge is installed and the normal desktop is available.'**
  String get privilegedBridgeReadyNormalBody;

  /// No description provided for @privilegedBridgeReadyLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready on the lock or login screen'**
  String get privilegedBridgeReadyLockedTitle;

  /// No description provided for @privilegedBridgeReadyLockedBody.
  ///
  /// In en, this message translates to:
  /// **'The protected session Helper is connected without moving device identity or permanent grants out of the Host Agent.'**
  String get privilegedBridgeReadyLockedBody;

  /// No description provided for @privilegedBridgeReadySecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready on a protected system screen'**
  String get privilegedBridgeReadySecureTitle;

  /// No description provided for @privilegedBridgeReadySecureBody.
  ///
  /// In en, this message translates to:
  /// **'The protected session Helper is connected with a short-lived local lease.'**
  String get privilegedBridgeReadySecureBody;

  /// No description provided for @privilegedBridgeReadyUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'No interactive desktop'**
  String get privilegedBridgeReadyUnavailableTitle;

  /// No description provided for @privilegedBridgeReadyUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Remote input remains disabled until the operating system publishes an interactive session.'**
  String get privilegedBridgeReadyUnavailableBody;

  /// No description provided for @privilegedBridgeTransitioningTitle.
  ///
  /// In en, this message translates to:
  /// **'Switching desktop session…'**
  String get privilegedBridgeTransitioningTitle;

  /// No description provided for @privilegedBridgeTransitioningBody.
  ///
  /// In en, this message translates to:
  /// **'Input is released while the Host authenticates a Helper in the new desktop session.'**
  String get privilegedBridgeTransitioningBody;

  /// No description provided for @privilegedBridgeReconnectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting protected session…'**
  String get privilegedBridgeReconnectingTitle;

  /// No description provided for @privilegedBridgeReconnectingBody.
  ///
  /// In en, this message translates to:
  /// **'Input remains disabled until the new protected session is authenticated.'**
  String get privilegedBridgeReconnectingBody;

  /// No description provided for @privilegedBridgeControlledTitle.
  ///
  /// In en, this message translates to:
  /// **'Controlled by {controllerName}'**
  String privilegedBridgeControlledTitle(String controllerName);

  /// No description provided for @privilegedBridgeControlledUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote control is active'**
  String get privilegedBridgeControlledUnknownTitle;

  /// No description provided for @privilegedBridgeControlledBody.
  ///
  /// In en, this message translates to:
  /// **'Use Emergency stop below to end every active remote session immediately.'**
  String get privilegedBridgeControlledBody;

  /// No description provided for @privilegedBridgeFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Privileged bridge unavailable'**
  String get privilegedBridgeFailedTitle;

  /// No description provided for @privilegedBridgeFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Remote input is disabled. Check the local Host installation and system permissions.'**
  String get privilegedBridgeFailedBody;

  /// No description provided for @privilegedBridgeUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Bridge status unavailable'**
  String get privilegedBridgeUnknownTitle;

  /// No description provided for @privilegedBridgeUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Remote input is not reported as protected. Refresh the Host status or check the installation.'**
  String get privilegedBridgeUnknownBody;

  /// No description provided for @emergencyStopAction.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop'**
  String get emergencyStopAction;

  /// No description provided for @emergencyStoppingAction.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get emergencyStoppingAction;

  /// No description provided for @emergencyStopDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop remote control?'**
  String get emergencyStopDialogTitle;

  /// No description provided for @emergencyStopDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This immediately closes every active remote session and releases all remote input. Permanent device authorizations are preserved.'**
  String get emergencyStopDialogBody;

  /// No description provided for @confirmEmergencyStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop now'**
  String get confirmEmergencyStopAction;

  /// No description provided for @emergencyStopSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Remote control stopped.'**
  String get emergencyStopSucceeded;

  /// No description provided for @emergencyStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Remote control could not be stopped. Use the system tray or stop the Host service locally.'**
  String get emergencyStopFailed;

  /// No description provided for @trayShowAction.
  ///
  /// In en, this message translates to:
  /// **'Show Roammand'**
  String get trayShowAction;

  /// No description provided for @trayExitAction.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get trayExitAction;

  /// No description provided for @trayExitControlledTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit while remote control is active?'**
  String get trayExitControlledTitle;

  /// No description provided for @trayExitControlledBody.
  ///
  /// In en, this message translates to:
  /// **'Exiting will first stop every remote session and release all remote input.'**
  String get trayExitControlledBody;

  /// No description provided for @trayConfirmExitAction.
  ///
  /// In en, this message translates to:
  /// **'Stop and exit'**
  String get trayConfirmExitAction;

  /// No description provided for @hostIdentitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get hostIdentitySectionTitle;

  /// No description provided for @hostShortFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Short fingerprint: {fingerprint}'**
  String hostShortFingerprint(String fingerprint);

  /// No description provided for @authorizedControllersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorized controllers'**
  String get authorizedControllersSectionTitle;

  /// No description provided for @authorizedControllerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No authorized controllers} =1{1 authorized controller} other{{count} authorized controllers}}'**
  String authorizedControllerCount(int count);

  /// No description provided for @noAuthorizedControllers.
  ///
  /// In en, this message translates to:
  /// **'No controllers are authorized yet.'**
  String get noAuthorizedControllers;

  /// No description provided for @unknownControllerName.
  ///
  /// In en, this message translates to:
  /// **'Unknown controller'**
  String get unknownControllerName;

  /// No description provided for @grantCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorized: {date}'**
  String grantCreatedLabel(String date);

  /// No description provided for @grantLastConnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last connected: {date}'**
  String grantLastConnectedLabel(String date);

  /// No description provided for @neverConnected.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverConnected;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownDate;

  /// No description provided for @revokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeAction;

  /// No description provided for @revokeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke {controllerName}?'**
  String revokeDialogTitle(String controllerName);

  /// No description provided for @revokeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This controller will immediately lose permanent access to this Host. Reconnecting requires a new pairing.'**
  String get revokeDialogBody;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @confirmRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get confirmRevokeAction;

  /// No description provided for @revokingAction.
  ///
  /// In en, this message translates to:
  /// **'Revoking…'**
  String get revokingAction;

  /// Heading for starting device pairing; authorization is confirmed later.
  ///
  /// In en, this message translates to:
  /// **'Add a new device'**
  String get hostPairingSectionTitle;

  /// No description provided for @hostPairingSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Pair a phone with this QR code or a computer with a one-time code. Only this Host can approve permanent access.'**
  String get hostPairingSectionBody;

  /// No description provided for @hostPairingEndpointMissing.
  ///
  /// In en, this message translates to:
  /// **'Configure a secure signaling endpoint before starting pairing.'**
  String get hostPairingEndpointMissing;

  /// No description provided for @hostPairingStartQrAction.
  ///
  /// In en, this message translates to:
  /// **'Show mobile QR code'**
  String get hostPairingStartQrAction;

  /// No description provided for @hostPairingStartCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Generate computer pairing code'**
  String get hostPairingStartCodeAction;

  /// No description provided for @hostPairingViewActiveAction.
  ///
  /// In en, this message translates to:
  /// **'View current pairing'**
  String get hostPairingViewActiveAction;

  /// No description provided for @hostPairingQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a phone'**
  String get hostPairingQrTitle;

  /// No description provided for @hostPairingCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a computer'**
  String get hostPairingCodeTitle;

  /// No description provided for @hostPairingQrInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with the Roammand camera scanner.'**
  String get hostPairingQrInstructions;

  /// No description provided for @hostPairingCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter this one-time code on the other computer.'**
  String get hostPairingCodeInstructions;

  /// No description provided for @hostPairingQrSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mobile pairing QR code'**
  String get hostPairingQrSemantics;

  /// No description provided for @hostPairingExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {remaining}'**
  String hostPairingExpiresIn(String remaining);

  /// No description provided for @hostPairingCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating a private pairing invitation…'**
  String get hostPairingCreating;

  /// No description provided for @hostPairingWaitingController.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other device…'**
  String get hostPairingWaitingController;

  /// No description provided for @hostPairingVerifyingController.
  ///
  /// In en, this message translates to:
  /// **'Verifying the other device…'**
  String get hostPairingVerifyingController;

  /// No description provided for @hostPairingPendingControllerTitle.
  ///
  /// In en, this message translates to:
  /// **'Device requesting access'**
  String get hostPairingPendingControllerTitle;

  /// No description provided for @hostPairingControllerFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Short fingerprint: {fingerprint}'**
  String hostPairingControllerFingerprint(String fingerprint);

  /// No description provided for @hostPairingCompareSas.
  ///
  /// In en, this message translates to:
  /// **'Compare these four words'**
  String get hostPairingCompareSas;

  /// No description provided for @hostPairingSasInstructions.
  ///
  /// In en, this message translates to:
  /// **'Confirm that all four words match on both computers. If any word differs, reject the request.'**
  String get hostPairingSasInstructions;

  /// No description provided for @hostPairingOneWayGrant.
  ///
  /// In en, this message translates to:
  /// **'Allowing creates permanent, one-way permission for this device to view the screen and control input. Reverse control requires a separate pairing.'**
  String get hostPairingOneWayGrant;

  /// No description provided for @hostPairingAllowAction.
  ///
  /// In en, this message translates to:
  /// **'Allow control'**
  String get hostPairingAllowAction;

  /// No description provided for @hostPairingRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get hostPairingRejectAction;

  /// No description provided for @hostPairingCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel pairing'**
  String get hostPairingCancelAction;

  /// No description provided for @hostPairingActionPending.
  ///
  /// In en, this message translates to:
  /// **'Applying…'**
  String get hostPairingActionPending;

  /// No description provided for @hostPairingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Device allowed'**
  String get hostPairingAccepted;

  /// No description provided for @hostPairingRejected.
  ///
  /// In en, this message translates to:
  /// **'Device rejected'**
  String get hostPairingRejected;

  /// No description provided for @hostPairingExpired.
  ///
  /// In en, this message translates to:
  /// **'Pairing expired'**
  String get hostPairingExpired;

  /// No description provided for @hostPairingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Pairing cancelled'**
  String get hostPairingCancelled;

  /// No description provided for @hostPairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get hostPairingFailed;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @devicePlatformIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone or iPad'**
  String get devicePlatformIos;

  /// No description provided for @devicePlatformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get devicePlatformAndroid;

  /// No description provided for @devicePlatformMacos.
  ///
  /// In en, this message translates to:
  /// **'Mac'**
  String get devicePlatformMacos;

  /// No description provided for @devicePlatformWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows PC'**
  String get devicePlatformWindows;

  /// No description provided for @devicePlatformUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown platform'**
  String get devicePlatformUnknown;

  /// No description provided for @trustedComputersTitle.
  ///
  /// In en, this message translates to:
  /// **'My computers'**
  String get trustedComputersTitle;

  /// No description provided for @trustedComputersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No computers paired yet'**
  String get trustedComputersEmptyTitle;

  /// No description provided for @trustedComputersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pair a computer with its one-time code. Future connections use the saved public identity on this device.'**
  String get trustedComputersEmptyBody;

  /// No description provided for @pairComputerAction.
  ///
  /// In en, this message translates to:
  /// **'Pair a computer'**
  String get pairComputerAction;

  /// No description provided for @trustedComputersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved computers are unavailable.'**
  String get trustedComputersLoadFailed;

  /// No description provided for @desktopPairingDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a computer'**
  String get desktopPairingDialogTitle;

  /// No description provided for @desktopPairingCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'One-time pairing code'**
  String get desktopPairingCodeLabel;

  /// No description provided for @desktopPairingCodeHint.
  ///
  /// In en, this message translates to:
  /// **'ABCD-EFGH'**
  String get desktopPairingCodeHint;

  /// No description provided for @invalidDesktopPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code is invalid.'**
  String get invalidDesktopPairingCode;

  /// No description provided for @pairAction.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pairAction;

  /// No description provided for @desktopPairingConnecting.
  ///
  /// In en, this message translates to:
  /// **'Joining the private pairing invitation…'**
  String get desktopPairingConnecting;

  /// No description provided for @desktopPairingVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying the Host identity…'**
  String get desktopPairingVerifying;

  /// No description provided for @desktopPairingWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval on the Host…'**
  String get desktopPairingWaitingApproval;

  /// No description provided for @desktopPairingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Computer paired'**
  String get desktopPairingSuccess;

  /// No description provided for @desktopPairingRejected.
  ///
  /// In en, this message translates to:
  /// **'The Host rejected pairing'**
  String get desktopPairingRejected;

  /// No description provided for @desktopPairingExpired.
  ///
  /// In en, this message translates to:
  /// **'Pairing expired'**
  String get desktopPairingExpired;

  /// No description provided for @desktopPairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get desktopPairingFailed;

  /// No description provided for @trustedHostPairedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paired: {date}'**
  String trustedHostPairedLabel(String date);

  /// No description provided for @trustedHostLastConnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last connected: {date}'**
  String trustedHostLastConnectedLabel(String date);

  /// No description provided for @openRemoteAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get openRemoteAction;

  /// No description provided for @deleteTrustedHostAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTrustedHostAction;

  /// No description provided for @deleteTrustedHostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {hostName} from this device?'**
  String deleteTrustedHostTitle(String hostName);

  /// No description provided for @deleteTrustedHostBody.
  ///
  /// In en, this message translates to:
  /// **'This only deletes the saved Host record on this Controller. It does not revoke the permanent grant on the Host.'**
  String get deleteTrustedHostBody;

  /// No description provided for @confirmDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete locally'**
  String get confirmDeleteAction;

  /// No description provided for @mobileDeviceFallbackName.
  ///
  /// In en, this message translates to:
  /// **'My phone'**
  String get mobileDeviceFallbackName;

  /// No description provided for @mobileOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this phone'**
  String get mobileOnboardingTitle;

  /// No description provided for @mobileOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'This name is shown only to computers you pair with. Your private identity stays on this device.'**
  String get mobileOnboardingBody;

  /// No description provided for @mobileDeviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get mobileDeviceNameLabel;

  /// No description provided for @mobileConfirmIdentityAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get mobileConfirmIdentityAction;

  /// No description provided for @mobileIdentityLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading this device identity…'**
  String get mobileIdentityLoading;

  /// No description provided for @mobileIdentityFailed.
  ///
  /// In en, this message translates to:
  /// **'The protected device identity is unavailable.'**
  String get mobileIdentityFailed;

  /// No description provided for @mobileHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'My computers'**
  String get mobileHomeTitle;

  /// No description provided for @mobileHomeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No computers paired yet'**
  String get mobileHomeEmptyTitle;

  /// No description provided for @mobileHomeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code shown by your computer to pair it with this phone.'**
  String get mobileHomeEmptyBody;

  /// No description provided for @mobileScanQrAction.
  ///
  /// In en, this message translates to:
  /// **'Scan computer QR code'**
  String get mobileScanQrAction;

  /// No description provided for @mobileScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get mobileScannerTitle;

  /// No description provided for @mobileScannerInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code shown on your computer.'**
  String get mobileScannerInstructions;

  /// No description provided for @mobileScannerTorchAction.
  ///
  /// In en, this message translates to:
  /// **'Toggle flashlight'**
  String get mobileScannerTorchAction;

  /// No description provided for @mobileScannerSwitchCameraAction.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get mobileScannerSwitchCameraAction;

  /// No description provided for @mobileScannerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Allow camera access in system settings to scan a pairing QR code.'**
  String get mobileScannerPermissionDenied;

  /// No description provided for @mobileScannerRestricted.
  ///
  /// In en, this message translates to:
  /// **'Camera access is restricted on this device.'**
  String get mobileScannerRestricted;

  /// No description provided for @mobileScannerNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No usable camera is available.'**
  String get mobileScannerNoCamera;

  /// No description provided for @mobileScannerInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be started.'**
  String get mobileScannerInitializationFailed;

  /// No description provided for @mobileInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'This pairing QR code is invalid or expired. Scan a new code.'**
  String get mobileInvalidQr;

  /// No description provided for @mobilePairingJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining the private pairing invitation…'**
  String get mobilePairingJoining;

  /// No description provided for @mobilePairingVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying the computer identity…'**
  String get mobilePairingVerifying;

  /// No description provided for @mobilePairingWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval on the computer…'**
  String get mobilePairingWaitingApproval;

  /// No description provided for @mobilePairingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Computer paired'**
  String get mobilePairingSuccess;

  /// No description provided for @mobilePairingRejected.
  ///
  /// In en, this message translates to:
  /// **'The computer rejected pairing'**
  String get mobilePairingRejected;

  /// No description provided for @mobilePairingExpired.
  ///
  /// In en, this message translates to:
  /// **'Pairing expired'**
  String get mobilePairingExpired;

  /// No description provided for @mobilePairingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Pairing cancelled'**
  String get mobilePairingCancelled;

  /// No description provided for @mobilePairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get mobilePairingFailed;

  /// No description provided for @mobilePairingSignalingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not communicate with the signaling service. Check the signaling address and local network access.'**
  String get mobilePairingSignalingFailed;

  /// No description provided for @mobilePairingAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify the computer\'s pairing identity. Generate a new QR code and try again.'**
  String get mobilePairingAuthenticationFailed;

  /// No description provided for @mobilePairingPersistenceFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing was approved, but this computer could not be saved securely.'**
  String get mobilePairingPersistenceFailed;

  /// No description provided for @mobilePairingInternalFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing encountered an internal error. Please try again.'**
  String get mobilePairingInternalFailed;

  /// No description provided for @pairingSecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s remaining'**
  String pairingSecondsRemaining(int seconds);

  /// No description provided for @mobileControlLaterNotice.
  ///
  /// In en, this message translates to:
  /// **'Paired and ready for a private remote session.'**
  String get mobileControlLaterNotice;

  /// No description provided for @mobileGestureHint.
  ///
  /// In en, this message translates to:
  /// **'Tap, double-tap, drag, scroll, or pinch'**
  String get mobileGestureHint;

  /// No description provided for @mobileKeyboardAction.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get mobileKeyboardAction;

  /// No description provided for @mobileHideKeyboardAction.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get mobileHideKeyboardAction;

  /// No description provided for @mobileTextInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Text to computer'**
  String get mobileTextInputLabel;

  /// No description provided for @mobileSendTextAction.
  ///
  /// In en, this message translates to:
  /// **'Send text'**
  String get mobileSendTextAction;

  /// No description provided for @mobileModifierControl.
  ///
  /// In en, this message translates to:
  /// **'Ctrl'**
  String get mobileModifierControl;

  /// No description provided for @mobileModifierShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get mobileModifierShift;

  /// No description provided for @mobileModifierAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get mobileModifierAlt;

  /// No description provided for @mobileModifierCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get mobileModifierCommand;

  /// No description provided for @mobileKeyEscape.
  ///
  /// In en, this message translates to:
  /// **'Esc'**
  String get mobileKeyEscape;

  /// No description provided for @mobileKeyTab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get mobileKeyTab;

  /// No description provided for @mobileKeyArrowLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get mobileKeyArrowLeft;

  /// No description provided for @mobileKeyArrowUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get mobileKeyArrowUp;

  /// No description provided for @mobileKeyArrowRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get mobileKeyArrowRight;

  /// No description provided for @mobileKeyArrowDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get mobileKeyArrowDown;

  /// No description provided for @remoteControlTab.
  ///
  /// In en, this message translates to:
  /// **'Remote control'**
  String get remoteControlTab;

  /// No description provided for @thisComputerTab.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get thisComputerTab;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageMenuTooltip;

  /// No description provided for @languageSystemOption.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystemOption;

  /// No description provided for @languageEnglishOption.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishOption;

  /// No description provided for @languageSimplifiedChineseOption.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageSimplifiedChineseOption;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralSection;

  /// No description provided for @settingsConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnectionSection;

  /// No description provided for @settingsAdvancedSection.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvancedSection;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by Roammand.'**
  String get settingsLanguageBody;

  /// No description provided for @uninstallSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Roammand'**
  String get uninstallSettingsTitle;

  /// No description provided for @uninstallSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the app and installed background components from this Mac.'**
  String get uninstallSettingsBody;

  /// No description provided for @uninstallDevelopmentBuildBody.
  ///
  /// In en, this message translates to:
  /// **'Uninstall is available from the installed macOS app, not a development build.'**
  String get uninstallDevelopmentBuildBody;

  /// No description provided for @uninstallUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The protected uninstaller is missing. Reinstall Roammand before uninstalling.'**
  String get uninstallUnavailableBody;

  /// No description provided for @uninstallCheckingBody.
  ///
  /// In en, this message translates to:
  /// **'Checking the installed uninstaller…'**
  String get uninstallCheckingBody;

  /// No description provided for @uninstallConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Roammand?'**
  String get uninstallConfirmTitle;

  /// No description provided for @uninstallConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remote sessions will stop and the app, Host Agent, privileged bridge, and protected-session Agent will be removed.'**
  String get uninstallConfirmBody;

  /// No description provided for @uninstallPreserveDataNotice.
  ///
  /// In en, this message translates to:
  /// **'This keeps this Mac’s device identity, pairing records, and preferences so they can be restored after reinstalling.'**
  String get uninstallPreserveDataNotice;

  /// No description provided for @uninstallConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstallConfirmAction;

  /// No description provided for @uninstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Roammand could not be uninstalled. No personal data was removed.'**
  String get uninstallFailed;

  /// No description provided for @desktopControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Control a computer'**
  String get desktopControlTitle;

  /// No description provided for @desktopControlBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a connection descriptor from an authorized computer to start a private remote session.'**
  String get desktopControlBody;

  /// No description provided for @hostConnectionDescriptorLabel.
  ///
  /// In en, this message translates to:
  /// **'Host connection descriptor'**
  String get hostConnectionDescriptorLabel;

  /// No description provided for @hostConnectionDescriptorHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the public Host descriptor here'**
  String get hostConnectionDescriptorHint;

  /// No description provided for @hostConnectionDescriptorPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The descriptor contains only the Host public identity and signaling address. It never contains a private key.'**
  String get hostConnectionDescriptorPrivacy;

  /// No description provided for @invalidHostDescriptor.
  ///
  /// In en, this message translates to:
  /// **'Connection descriptor is invalid.'**
  String get invalidHostDescriptor;

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectAction;

  /// No description provided for @connectingAction.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingAction;

  /// No description provided for @remoteDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote desktop — {hostName}'**
  String remoteDesktopTitle(String hostName);

  /// No description provided for @closeSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Close connection'**
  String get closeSessionAction;

  /// No description provided for @remoteInputHint.
  ///
  /// In en, this message translates to:
  /// **'Click the desktop to send mouse and keyboard input.'**
  String get remoteInputHint;

  /// No description provided for @localExitShortcutHint.
  ///
  /// In en, this message translates to:
  /// **'Local exit: Ctrl+Alt+Shift+Esc'**
  String get localExitShortcutHint;

  /// No description provided for @remoteIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get remoteIdle;

  /// No description provided for @remoteConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to local identity and signaling…'**
  String get remoteConnecting;

  /// No description provided for @remoteReconnectingPending.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted. Preparing a secure retry…'**
  String get remoteReconnectingPending;

  /// No description provided for @remoteReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting… attempt {attempt} of {maximum}. {seconds} seconds remaining.'**
  String remoteReconnecting(int attempt, int maximum, int seconds);

  /// No description provided for @remoteAuthenticating.
  ///
  /// In en, this message translates to:
  /// **'Signing the session offer locally…'**
  String get remoteAuthenticating;

  /// No description provided for @remoteNegotiating.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the Host to verify and answer…'**
  String get remoteNegotiating;

  /// No description provided for @remoteConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get remoteConnected;

  /// No description provided for @remoteClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing and releasing input…'**
  String get remoteClosing;

  /// No description provided for @remoteAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Host authentication failed.'**
  String get remoteAuthenticationFailed;

  /// No description provided for @remoteHostAgentFailed.
  ///
  /// In en, this message translates to:
  /// **'The local Host Agent is unavailable.'**
  String get remoteHostAgentFailed;

  /// No description provided for @remoteLocalIdentityFailed.
  ///
  /// In en, this message translates to:
  /// **'This Controller identity is unavailable.'**
  String get remoteLocalIdentityFailed;

  /// No description provided for @remoteSignalingFailed.
  ///
  /// In en, this message translates to:
  /// **'The signaling connection failed.'**
  String get remoteSignalingFailed;

  /// No description provided for @remoteConfigurationFailed.
  ///
  /// In en, this message translates to:
  /// **'Remote connection settings are invalid.'**
  String get remoteConfigurationFailed;

  /// No description provided for @remoteConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'The remote session failed.'**
  String get remoteConnectionFailed;

  /// No description provided for @retryRemoteAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryRemoteAction;

  /// No description provided for @diagnosticsAction.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsAction;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy-safe diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'When a connection or reconnect fails, save this local report to troubleshoot session state, timing, and aggregate WebRTC health. Review exactly what it includes and excludes before saving. Nothing is uploaded or copied to the clipboard.'**
  String get diagnosticsPreviewBody;

  /// No description provided for @diagnosticsIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get diagnosticsIncludedTitle;

  /// No description provided for @diagnosticsExcludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Excluded'**
  String get diagnosticsExcludedTitle;

  /// No description provided for @diagnosticsIncludedVersions.
  ///
  /// In en, this message translates to:
  /// **'App, protocol, and OS versions'**
  String get diagnosticsIncludedVersions;

  /// No description provided for @diagnosticsIncludedSession.
  ///
  /// In en, this message translates to:
  /// **'Session states and stable error codes'**
  String get diagnosticsIncludedSession;

  /// No description provided for @diagnosticsIncludedReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect attempts and timing'**
  String get diagnosticsIncludedReconnect;

  /// No description provided for @diagnosticsIncludedWebRtc.
  ///
  /// In en, this message translates to:
  /// **'Aggregate WebRTC metrics'**
  String get diagnosticsIncludedWebRtc;

  /// No description provided for @diagnosticsExcludedDeviceIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Device identifiers'**
  String get diagnosticsExcludedDeviceIdentifiers;

  /// No description provided for @diagnosticsExcludedDeviceNames.
  ///
  /// In en, this message translates to:
  /// **'Device names'**
  String get diagnosticsExcludedDeviceNames;

  /// No description provided for @diagnosticsExcludedKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys and signatures'**
  String get diagnosticsExcludedKeys;

  /// No description provided for @diagnosticsExcludedTokens.
  ///
  /// In en, this message translates to:
  /// **'Nonces, tokens, and passwords'**
  String get diagnosticsExcludedTokens;

  /// No description provided for @diagnosticsExcludedSdpIce.
  ///
  /// In en, this message translates to:
  /// **'SDP and ICE candidates'**
  String get diagnosticsExcludedSdpIce;

  /// No description provided for @diagnosticsExcludedNetworkAddresses.
  ///
  /// In en, this message translates to:
  /// **'IP addresses and ports'**
  String get diagnosticsExcludedNetworkAddresses;

  /// No description provided for @diagnosticsExcludedInput.
  ///
  /// In en, this message translates to:
  /// **'Input content and coordinates'**
  String get diagnosticsExcludedInput;

  /// No description provided for @diagnosticsExcludedScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen content'**
  String get diagnosticsExcludedScreen;

  /// No description provided for @diagnosticsExcludedRawPayloads.
  ///
  /// In en, this message translates to:
  /// **'Raw signaling and data-channel payloads'**
  String get diagnosticsExcludedRawPayloads;

  /// No description provided for @diagnosticsExcludedRawStats.
  ///
  /// In en, this message translates to:
  /// **'Raw WebRTC statistics'**
  String get diagnosticsExcludedRawStats;

  /// No description provided for @diagnosticsEventSummary.
  ///
  /// In en, this message translates to:
  /// **'Captured events: {count}. Truncated: {truncated}.'**
  String diagnosticsEventSummary(int count, String truncated);

  /// No description provided for @diagnosticsTruncatedYes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get diagnosticsTruncatedYes;

  /// No description provided for @diagnosticsTruncatedNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get diagnosticsTruncatedNo;

  /// No description provided for @diagnosticsSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save report'**
  String get diagnosticsSaveAction;

  /// No description provided for @diagnosticsSavingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get diagnosticsSavingAction;

  /// No description provided for @diagnosticsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved locally to {path}'**
  String diagnosticsSaved(String path);

  /// No description provided for @diagnosticsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the diagnostics report.'**
  String get diagnosticsSaveFailed;

  /// No description provided for @networkSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Network service settings'**
  String get networkSettingsTooltip;

  /// No description provided for @networkSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Network services'**
  String get networkSettingsTitle;

  /// No description provided for @networkSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the signaling and STUN services used to find devices and establish direct connections.'**
  String get networkSettingsBody;

  /// No description provided for @networkProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Service profile'**
  String get networkProfileLabel;

  /// No description provided for @networkOfficialProfile.
  ///
  /// In en, this message translates to:
  /// **'Official service'**
  String get networkOfficialProfile;

  /// No description provided for @networkOfficialProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Use the built-in Roammand service defaults.'**
  String get networkOfficialProfileBody;

  /// No description provided for @networkCustomProfile.
  ///
  /// In en, this message translates to:
  /// **'Custom service'**
  String get networkCustomProfile;

  /// No description provided for @networkCustomProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Use a development or self-hosted signaling and STUN service.'**
  String get networkCustomProfileBody;

  /// No description provided for @networkSignalingEndpointLabel.
  ///
  /// In en, this message translates to:
  /// **'Signaling WebSocket address'**
  String get networkSignalingEndpointLabel;

  /// No description provided for @networkSignalingEndpointHint.
  ///
  /// In en, this message translates to:
  /// **'wss://signal.example.com/v1/connect'**
  String get networkSignalingEndpointHint;

  /// No description provided for @networkStunUrlsLabel.
  ///
  /// In en, this message translates to:
  /// **'STUN addresses'**
  String get networkStunUrlsLabel;

  /// No description provided for @networkStunUrlsHint.
  ///
  /// In en, this message translates to:
  /// **'One stun: or stuns: address per line'**
  String get networkStunUrlsHint;

  /// No description provided for @networkStunOptionalNotice.
  ///
  /// In en, this message translates to:
  /// **'STUN is optional for local testing. This release has no TURN fallback, so some restrictive networks cannot connect.'**
  String get networkStunOptionalNotice;

  /// No description provided for @networkMobileHostBindingNotice.
  ///
  /// In en, this message translates to:
  /// **'A paired computer keeps its signaling address from the QR code. This profile supplies the STUN service used for direct connections and the default for new manual pairing flows.'**
  String get networkMobileHostBindingNotice;

  /// No description provided for @networkSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save configuration'**
  String get networkSaveAction;

  /// No description provided for @networkSavingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get networkSavingAction;

  /// No description provided for @networkRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore official defaults'**
  String get networkRestoreAction;

  /// No description provided for @networkInvalidSignaling.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid secure signaling WebSocket address. Private ws:// addresses are allowed only in an explicitly enabled debug build.'**
  String get networkInvalidSignaling;

  /// No description provided for @networkInvalidStun.
  ///
  /// In en, this message translates to:
  /// **'Enter only valid stun: or stuns: addresses, one per line.'**
  String get networkInvalidStun;

  /// No description provided for @networkInvalidConfiguration.
  ///
  /// In en, this message translates to:
  /// **'The signaling or STUN configuration is invalid.'**
  String get networkInvalidConfiguration;

  /// No description provided for @networkSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The network configuration could not be saved.'**
  String get networkSaveFailed;

  /// No description provided for @networkChangeHostTitle.
  ///
  /// In en, this message translates to:
  /// **'Change this computer\'s network service?'**
  String get networkChangeHostTitle;

  /// No description provided for @networkChangeHostBody.
  ///
  /// In en, this message translates to:
  /// **'The managed Host Agent will restart and active remote sessions will end. If the signaling address changes, previously paired devices must scan a new QR code before they can find this computer again.'**
  String get networkChangeHostBody;

  /// No description provided for @networkConfirmChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Save and restart'**
  String get networkConfirmChangeAction;

  /// No description provided for @networkConfigurationSaved.
  ///
  /// In en, this message translates to:
  /// **'Network configuration saved.'**
  String get networkConfigurationSaved;

  /// No description provided for @networkHostMigrationSaved.
  ///
  /// In en, this message translates to:
  /// **'Server changed. Show a new QR code to previously paired phones.'**
  String get networkHostMigrationSaved;

  /// No description provided for @networkExternalHostRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved. The currently connected development Host Agent is independently managed; restart it with the same settings.'**
  String get networkExternalHostRestartRequired;

  /// No description provided for @networkHostRestartFailed.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved, but the managed Host Agent could not restart. Exit and reopen Roammand, then verify the service settings.'**
  String get networkHostRestartFailed;

  /// No description provided for @mobileUnfamiliarServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a different signaling service?'**
  String get mobileUnfamiliarServerTitle;

  /// No description provided for @mobileUnfamiliarServerBody.
  ///
  /// In en, this message translates to:
  /// **'This QR code will connect to {endpoint}. The service can observe connection metadata and disrupt availability. Continue only if you trust the computer and service operator.'**
  String mobileUnfamiliarServerBody(String endpoint);

  /// No description provided for @mobileTrustServerAction.
  ///
  /// In en, this message translates to:
  /// **'Trust and continue'**
  String get mobileTrustServerAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
