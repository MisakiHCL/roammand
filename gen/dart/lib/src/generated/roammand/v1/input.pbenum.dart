// SPDX-License-Identifier: Apache-2.0

// This is a generated file - do not edit.
//
// Generated from roammand/v1/input.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PointerButton extends $pb.ProtobufEnum {
  static const PointerButton POINTER_BUTTON_UNSPECIFIED =
      PointerButton._(0, _omitEnumNames ? '' : 'POINTER_BUTTON_UNSPECIFIED');
  static const PointerButton POINTER_BUTTON_LEFT =
      PointerButton._(1, _omitEnumNames ? '' : 'POINTER_BUTTON_LEFT');
  static const PointerButton POINTER_BUTTON_RIGHT =
      PointerButton._(2, _omitEnumNames ? '' : 'POINTER_BUTTON_RIGHT');
  static const PointerButton POINTER_BUTTON_MIDDLE =
      PointerButton._(3, _omitEnumNames ? '' : 'POINTER_BUTTON_MIDDLE');

  static const $core.List<PointerButton> values = <PointerButton>[
    POINTER_BUTTON_UNSPECIFIED,
    POINTER_BUTTON_LEFT,
    POINTER_BUTTON_RIGHT,
    POINTER_BUTTON_MIDDLE,
  ];

  static final $core.List<PointerButton?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PointerButton? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PointerButton._(super.value, super.name);
}

class ButtonAction extends $pb.ProtobufEnum {
  static const ButtonAction BUTTON_ACTION_UNSPECIFIED =
      ButtonAction._(0, _omitEnumNames ? '' : 'BUTTON_ACTION_UNSPECIFIED');
  static const ButtonAction BUTTON_ACTION_DOWN =
      ButtonAction._(1, _omitEnumNames ? '' : 'BUTTON_ACTION_DOWN');
  static const ButtonAction BUTTON_ACTION_UP =
      ButtonAction._(2, _omitEnumNames ? '' : 'BUTTON_ACTION_UP');
  static const ButtonAction BUTTON_ACTION_CLICK =
      ButtonAction._(3, _omitEnumNames ? '' : 'BUTTON_ACTION_CLICK');
  static const ButtonAction BUTTON_ACTION_DOUBLE_CLICK =
      ButtonAction._(4, _omitEnumNames ? '' : 'BUTTON_ACTION_DOUBLE_CLICK');

  static const $core.List<ButtonAction> values = <ButtonAction>[
    BUTTON_ACTION_UNSPECIFIED,
    BUTTON_ACTION_DOWN,
    BUTTON_ACTION_UP,
    BUTTON_ACTION_CLICK,
    BUTTON_ACTION_DOUBLE_CLICK,
  ];

  static final $core.List<ButtonAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ButtonAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ButtonAction._(super.value, super.name);
}

class KeyboardAction extends $pb.ProtobufEnum {
  static const KeyboardAction KEYBOARD_ACTION_UNSPECIFIED =
      KeyboardAction._(0, _omitEnumNames ? '' : 'KEYBOARD_ACTION_UNSPECIFIED');
  static const KeyboardAction KEYBOARD_ACTION_DOWN =
      KeyboardAction._(1, _omitEnumNames ? '' : 'KEYBOARD_ACTION_DOWN');
  static const KeyboardAction KEYBOARD_ACTION_UP =
      KeyboardAction._(2, _omitEnumNames ? '' : 'KEYBOARD_ACTION_UP');

  static const $core.List<KeyboardAction> values = <KeyboardAction>[
    KEYBOARD_ACTION_UNSPECIFIED,
    KEYBOARD_ACTION_DOWN,
    KEYBOARD_ACTION_UP,
  ];

  static final $core.List<KeyboardAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static KeyboardAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const KeyboardAction._(super.value, super.name);
}

class SessionControlAction extends $pb.ProtobufEnum {
  static const SessionControlAction SESSION_CONTROL_ACTION_UNSPECIFIED =
      SessionControlAction._(
          0, _omitEnumNames ? '' : 'SESSION_CONTROL_ACTION_UNSPECIFIED');
  static const SessionControlAction SESSION_CONTROL_ACTION_CLOSE =
      SessionControlAction._(
          1, _omitEnumNames ? '' : 'SESSION_CONTROL_ACTION_CLOSE');
  static const SessionControlAction SESSION_CONTROL_ACTION_EMERGENCY_STOP =
      SessionControlAction._(
          2, _omitEnumNames ? '' : 'SESSION_CONTROL_ACTION_EMERGENCY_STOP');

  static const $core.List<SessionControlAction> values = <SessionControlAction>[
    SESSION_CONTROL_ACTION_UNSPECIFIED,
    SESSION_CONTROL_ACTION_CLOSE,
    SESSION_CONTROL_ACTION_EMERGENCY_STOP,
  ];

  static final $core.List<SessionControlAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SessionControlAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionControlAction._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
