// SPDX-License-Identifier: MPL-2.0

/// Shared text-input behavior for Roammand fields.
///
/// iOS animates cursor opacity by default. Disabling that animation avoids a
/// costly per-field focus path in Flutter Debug/Profile builds while retaining
/// the normal cursor blink. Personalized learning is disabled because device,
/// network, and remote-computer text should not train the system keyboard.
abstract final class RoammandTextInputPolicy {
  static const cursorOpacityAnimates = false;
  static const enableImePersonalizedLearning = false;
}
