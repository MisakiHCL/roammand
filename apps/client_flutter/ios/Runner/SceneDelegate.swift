import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var privacyShield: UIView?

  override func sceneWillResignActive(_ scene: UIScene) {
    installPrivacyShield(in: scene)
    super.sceneWillResignActive(scene)
  }

  override func sceneDidEnterBackground(_ scene: UIScene) {
    installPrivacyShield(in: scene)
    super.sceneDidEnterBackground(scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    DispatchQueue.main.async { [weak self, weak scene] in
      guard scene?.activationState == .foregroundActive else { return }
      self?.removePrivacyShield()
    }
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    removePrivacyShield()
    super.sceneDidDisconnect(scene)
  }

  private func installPrivacyShield(in scene: UIScene) {
    guard privacyShield == nil else { return }
    guard let window = window ?? (scene as? UIWindowScene)?.windows.first else {
      return
    }

    // UIKit can capture the task-switcher snapshot before Flutter submits its
    // next frame, so this native opaque view is installed synchronously.
    let shield = UIView(frame: window.bounds)
    shield.backgroundColor = .black
    shield.isOpaque = true
    shield.isUserInteractionEnabled = true
    shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(shield)
    window.bringSubviewToFront(shield)
    window.layoutIfNeeded()
    shield.layer.displayIfNeeded()
    privacyShield = shield
  }

  private func removePrivacyShield() {
    privacyShield?.removeFromSuperview()
    privacyShield = nil
  }
}
