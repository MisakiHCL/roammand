import Cocoa
import FlutterMacOS

private let minimumWindowSize = NSSize(width: 480, height: 480)
private let uninstallerChannelName = "dev.roammand/uninstaller"
private let uninstallMethodName = "uninstall"
private let installedUninstallerPath =
  "/Library/Application Support/Roammand/uninstall-macos.sh"
private let uninstallAuthorizationFailedCode = "UNINSTALL_AUTHORIZATION_FAILED"

private final class MacOsUninstallAuthorization {
  private let channel: FlutterMethodChannel

  init(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: uninstallerChannelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler(handle)
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == uninstallMethodName else {
      result(FlutterMethodNotImplemented)
      return
    }

    // Run Standard Additions inside the signed app process so macOS can
    // identify Roammand, rather than the external osascript executable, as
    // the requester in its administrator authentication dialog.
    let source = """
      do shell script (quoted form of "\(installedUninstallerPath)") \
        with administrator privileges
      """
    guard let script = NSAppleScript(source: source) else {
      result(authorizationError())
      return
    }

    var errorInfo: NSDictionary?
    guard script.executeAndReturnError(&errorInfo) != nil else {
      result(authorizationError())
      return
    }
    result(nil)
  }

  private func authorizationError() -> FlutterError {
    // AppleScript errors may include local account or filesystem details, so
    // never forward their descriptions across the Flutter channel.
    FlutterError(
      code: uninstallAuthorizationFailedCode,
      message: nil,
      details: nil
    )
  }
}

class MainFlutterWindow: NSWindow {
  private var uninstallAuthorization: MacOsUninstallAuthorization?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.minSize = minimumWindowSize

    RegisterGeneratedPlugins(registry: flutterViewController)
    uninstallAuthorization = MacOsUninstallAuthorization(
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    super.awakeFromNib()
  }
}
