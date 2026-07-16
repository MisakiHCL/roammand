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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'input.pbenum.dart';
import 'version.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'input.pbenum.dart';

class PointerButtonEvent extends $pb.GeneratedMessage {
  factory PointerButtonEvent({
    PointerButton? button,
    ButtonAction? action,
    $core.int? x,
    $core.int? y,
  }) {
    final result = create();
    if (button != null) result.button = button;
    if (action != null) result.action = action;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    return result;
  }

  PointerButtonEvent._();

  factory PointerButtonEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PointerButtonEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PointerButtonEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<PointerButton>(1, _omitFieldNames ? '' : 'button', $pb.PbFieldType.OE,
        defaultOrMaker: PointerButton.POINTER_BUTTON_UNSPECIFIED,
        valueOf: PointerButton.valueOf,
        enumValues: PointerButton.values)
    ..e<ButtonAction>(2, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE,
        defaultOrMaker: ButtonAction.BUTTON_ACTION_UNSPECIFIED,
        valueOf: ButtonAction.valueOf,
        enumValues: ButtonAction.values)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'x', $pb.PbFieldType.OS3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'y', $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerButtonEvent clone() => PointerButtonEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerButtonEvent copyWith(void Function(PointerButtonEvent) updates) =>
      super.copyWith((message) => updates(message as PointerButtonEvent))
          as PointerButtonEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PointerButtonEvent create() => PointerButtonEvent._();
  @$core.override
  PointerButtonEvent createEmptyInstance() => create();
  static $pb.PbList<PointerButtonEvent> createRepeated() =>
      $pb.PbList<PointerButtonEvent>();
  @$core.pragma('dart2js:noInline')
  static PointerButtonEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PointerButtonEvent>(create);
  static PointerButtonEvent? _defaultInstance;

  @$pb.TagNumber(1)
  PointerButton get button => $_getN(0);
  @$pb.TagNumber(1)
  set button(PointerButton value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasButton() => $_has(0);
  @$pb.TagNumber(1)
  void clearButton() => $_clearField(1);

  @$pb.TagNumber(2)
  ButtonAction get action => $_getN(1);
  @$pb.TagNumber(2)
  set action(ButtonAction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearAction() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get x => $_getIZ(2);
  @$pb.TagNumber(3)
  set x($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasX() => $_has(2);
  @$pb.TagNumber(3)
  void clearX() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get y => $_getIZ(3);
  @$pb.TagNumber(4)
  set y($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasY() => $_has(3);
  @$pb.TagNumber(4)
  void clearY() => $_clearField(4);
}

class KeyboardEvent extends $pb.GeneratedMessage {
  factory KeyboardEvent({
    KeyboardAction? action,
    $core.int? usbHidUsage,
    $core.int? modifierBits,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (usbHidUsage != null) result.usbHidUsage = usbHidUsage;
    if (modifierBits != null) result.modifierBits = modifierBits;
    return result;
  }

  KeyboardEvent._();

  factory KeyboardEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KeyboardEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyboardEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<KeyboardAction>(1, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE,
        defaultOrMaker: KeyboardAction.KEYBOARD_ACTION_UNSPECIFIED,
        valueOf: KeyboardAction.valueOf,
        enumValues: KeyboardAction.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'usbHidUsage', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'modifierBits', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyboardEvent clone() => KeyboardEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyboardEvent copyWith(void Function(KeyboardEvent) updates) =>
      super.copyWith((message) => updates(message as KeyboardEvent))
          as KeyboardEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KeyboardEvent create() => KeyboardEvent._();
  @$core.override
  KeyboardEvent createEmptyInstance() => create();
  static $pb.PbList<KeyboardEvent> createRepeated() =>
      $pb.PbList<KeyboardEvent>();
  @$core.pragma('dart2js:noInline')
  static KeyboardEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeyboardEvent>(create);
  static KeyboardEvent? _defaultInstance;

  @$pb.TagNumber(1)
  KeyboardAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(KeyboardAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get usbHidUsage => $_getIZ(1);
  @$pb.TagNumber(2)
  set usbHidUsage($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsbHidUsage() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsbHidUsage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get modifierBits => $_getIZ(2);
  @$pb.TagNumber(3)
  set modifierBits($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModifierBits() => $_has(2);
  @$pb.TagNumber(3)
  void clearModifierBits() => $_clearField(3);
}

class TextInputEvent extends $pb.GeneratedMessage {
  factory TextInputEvent({
    $core.String? text,
  }) {
    final result = create();
    if (text != null) result.text = text;
    return result;
  }

  TextInputEvent._();

  factory TextInputEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextInputEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextInputEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextInputEvent clone() => TextInputEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextInputEvent copyWith(void Function(TextInputEvent) updates) =>
      super.copyWith((message) => updates(message as TextInputEvent))
          as TextInputEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextInputEvent create() => TextInputEvent._();
  @$core.override
  TextInputEvent createEmptyInstance() => create();
  static $pb.PbList<TextInputEvent> createRepeated() =>
      $pb.PbList<TextInputEvent>();
  @$core.pragma('dart2js:noInline')
  static TextInputEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextInputEvent>(create);
  static TextInputEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

class SessionControlEvent extends $pb.GeneratedMessage {
  factory SessionControlEvent({
    SessionControlAction? action,
  }) {
    final result = create();
    if (action != null) result.action = action;
    return result;
  }

  SessionControlEvent._();

  factory SessionControlEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionControlEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionControlEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..e<SessionControlAction>(
        1, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE,
        defaultOrMaker: SessionControlAction.SESSION_CONTROL_ACTION_UNSPECIFIED,
        valueOf: SessionControlAction.valueOf,
        enumValues: SessionControlAction.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionControlEvent clone() => SessionControlEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionControlEvent copyWith(void Function(SessionControlEvent) updates) =>
      super.copyWith((message) => updates(message as SessionControlEvent))
          as SessionControlEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionControlEvent create() => SessionControlEvent._();
  @$core.override
  SessionControlEvent createEmptyInstance() => create();
  static $pb.PbList<SessionControlEvent> createRepeated() =>
      $pb.PbList<SessionControlEvent>();
  @$core.pragma('dart2js:noInline')
  static SessionControlEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionControlEvent>(create);
  static SessionControlEvent? _defaultInstance;

  @$pb.TagNumber(1)
  SessionControlAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(SessionControlAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);
}

class ReleaseAllInput extends $pb.GeneratedMessage {
  factory ReleaseAllInput() => create();

  ReleaseAllInput._();

  factory ReleaseAllInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReleaseAllInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReleaseAllInput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReleaseAllInput clone() => ReleaseAllInput()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReleaseAllInput copyWith(void Function(ReleaseAllInput) updates) =>
      super.copyWith((message) => updates(message as ReleaseAllInput))
          as ReleaseAllInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReleaseAllInput create() => ReleaseAllInput._();
  @$core.override
  ReleaseAllInput createEmptyInstance() => create();
  static $pb.PbList<ReleaseAllInput> createRepeated() =>
      $pb.PbList<ReleaseAllInput>();
  @$core.pragma('dart2js:noInline')
  static ReleaseAllInput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReleaseAllInput>(create);
  static ReleaseAllInput? _defaultInstance;
}

class PointerMoveEvent extends $pb.GeneratedMessage {
  factory PointerMoveEvent({
    $core.int? x,
    $core.int? y,
    $core.int? pressedButtonBits,
  }) {
    final result = create();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (pressedButtonBits != null) result.pressedButtonBits = pressedButtonBits;
    return result;
  }

  PointerMoveEvent._();

  factory PointerMoveEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PointerMoveEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PointerMoveEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'x', $pb.PbFieldType.OS3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'y', $pb.PbFieldType.OS3)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'pressedButtonBits', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerMoveEvent clone() => PointerMoveEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerMoveEvent copyWith(void Function(PointerMoveEvent) updates) =>
      super.copyWith((message) => updates(message as PointerMoveEvent))
          as PointerMoveEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PointerMoveEvent create() => PointerMoveEvent._();
  @$core.override
  PointerMoveEvent createEmptyInstance() => create();
  static $pb.PbList<PointerMoveEvent> createRepeated() =>
      $pb.PbList<PointerMoveEvent>();
  @$core.pragma('dart2js:noInline')
  static PointerMoveEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PointerMoveEvent>(create);
  static PointerMoveEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get x => $_getIZ(0);
  @$pb.TagNumber(1)
  set x($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get y => $_getIZ(1);
  @$pb.TagNumber(2)
  set y($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get pressedButtonBits => $_getIZ(2);
  @$pb.TagNumber(3)
  set pressedButtonBits($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPressedButtonBits() => $_has(2);
  @$pb.TagNumber(3)
  void clearPressedButtonBits() => $_clearField(3);
}

class PointerScrollEvent extends $pb.GeneratedMessage {
  factory PointerScrollEvent({
    $core.int? deltaX,
    $core.int? deltaY,
  }) {
    final result = create();
    if (deltaX != null) result.deltaX = deltaX;
    if (deltaY != null) result.deltaY = deltaY;
    return result;
  }

  PointerScrollEvent._();

  factory PointerScrollEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PointerScrollEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PointerScrollEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'deltaX', $pb.PbFieldType.OS3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'deltaY', $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerScrollEvent clone() => PointerScrollEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerScrollEvent copyWith(void Function(PointerScrollEvent) updates) =>
      super.copyWith((message) => updates(message as PointerScrollEvent))
          as PointerScrollEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PointerScrollEvent create() => PointerScrollEvent._();
  @$core.override
  PointerScrollEvent createEmptyInstance() => create();
  static $pb.PbList<PointerScrollEvent> createRepeated() =>
      $pb.PbList<PointerScrollEvent>();
  @$core.pragma('dart2js:noInline')
  static PointerScrollEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PointerScrollEvent>(create);
  static PointerScrollEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get deltaX => $_getIZ(0);
  @$pb.TagNumber(1)
  set deltaX($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeltaX() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeltaX() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get deltaY => $_getIZ(1);
  @$pb.TagNumber(2)
  set deltaY($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeltaY() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeltaY() => $_clearField(2);
}

enum ReliableInputEnvelope_Event {
  pointerButton,
  keyboard,
  text,
  sessionControl,
  releaseAllInput,
  notSet
}

class ReliableInputEnvelope extends $pb.GeneratedMessage {
  factory ReliableInputEnvelope({
    $0.ProtocolVersion? protocolVersion,
    $core.List<$core.int>? sessionId,
    $fixnum.Int64? sequence,
    PointerButtonEvent? pointerButton,
    KeyboardEvent? keyboard,
    TextInputEvent? text,
    SessionControlEvent? sessionControl,
    ReleaseAllInput? releaseAllInput,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (sessionId != null) result.sessionId = sessionId;
    if (sequence != null) result.sequence = sequence;
    if (pointerButton != null) result.pointerButton = pointerButton;
    if (keyboard != null) result.keyboard = keyboard;
    if (text != null) result.text = text;
    if (sessionControl != null) result.sessionControl = sessionControl;
    if (releaseAllInput != null) result.releaseAllInput = releaseAllInput;
    return result;
  }

  ReliableInputEnvelope._();

  factory ReliableInputEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReliableInputEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ReliableInputEnvelope_Event>
      _ReliableInputEnvelope_EventByTag = {
    10: ReliableInputEnvelope_Event.pointerButton,
    11: ReliableInputEnvelope_Event.keyboard,
    12: ReliableInputEnvelope_Event.text,
    13: ReliableInputEnvelope_Event.sessionControl,
    14: ReliableInputEnvelope_Event.releaseAllInput,
    0: ReliableInputEnvelope_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReliableInputEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14])
    ..aOM<$0.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $0.ProtocolVersion.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<PointerButtonEvent>(10, _omitFieldNames ? '' : 'pointerButton',
        subBuilder: PointerButtonEvent.create)
    ..aOM<KeyboardEvent>(11, _omitFieldNames ? '' : 'keyboard',
        subBuilder: KeyboardEvent.create)
    ..aOM<TextInputEvent>(12, _omitFieldNames ? '' : 'text',
        subBuilder: TextInputEvent.create)
    ..aOM<SessionControlEvent>(13, _omitFieldNames ? '' : 'sessionControl',
        subBuilder: SessionControlEvent.create)
    ..aOM<ReleaseAllInput>(14, _omitFieldNames ? '' : 'releaseAllInput',
        subBuilder: ReleaseAllInput.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReliableInputEnvelope clone() =>
      ReliableInputEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReliableInputEnvelope copyWith(
          void Function(ReliableInputEnvelope) updates) =>
      super.copyWith((message) => updates(message as ReliableInputEnvelope))
          as ReliableInputEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReliableInputEnvelope create() => ReliableInputEnvelope._();
  @$core.override
  ReliableInputEnvelope createEmptyInstance() => create();
  static $pb.PbList<ReliableInputEnvelope> createRepeated() =>
      $pb.PbList<ReliableInputEnvelope>();
  @$core.pragma('dart2js:noInline')
  static ReliableInputEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReliableInputEnvelope>(create);
  static ReliableInputEnvelope? _defaultInstance;

  ReliableInputEnvelope_Event whichEvent() =>
      _ReliableInputEnvelope_EventByTag[$_whichOneof(0)]!;
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($0.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get sessionId => $_getN(1);
  @$pb.TagNumber(2)
  set sessionId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sequence => $_getI64(2);
  @$pb.TagNumber(3)
  set sequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);

  @$pb.TagNumber(10)
  PointerButtonEvent get pointerButton => $_getN(3);
  @$pb.TagNumber(10)
  set pointerButton(PointerButtonEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPointerButton() => $_has(3);
  @$pb.TagNumber(10)
  void clearPointerButton() => $_clearField(10);
  @$pb.TagNumber(10)
  PointerButtonEvent ensurePointerButton() => $_ensure(3);

  @$pb.TagNumber(11)
  KeyboardEvent get keyboard => $_getN(4);
  @$pb.TagNumber(11)
  set keyboard(KeyboardEvent value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasKeyboard() => $_has(4);
  @$pb.TagNumber(11)
  void clearKeyboard() => $_clearField(11);
  @$pb.TagNumber(11)
  KeyboardEvent ensureKeyboard() => $_ensure(4);

  @$pb.TagNumber(12)
  TextInputEvent get text => $_getN(5);
  @$pb.TagNumber(12)
  set text(TextInputEvent value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasText() => $_has(5);
  @$pb.TagNumber(12)
  void clearText() => $_clearField(12);
  @$pb.TagNumber(12)
  TextInputEvent ensureText() => $_ensure(5);

  @$pb.TagNumber(13)
  SessionControlEvent get sessionControl => $_getN(6);
  @$pb.TagNumber(13)
  set sessionControl(SessionControlEvent value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasSessionControl() => $_has(6);
  @$pb.TagNumber(13)
  void clearSessionControl() => $_clearField(13);
  @$pb.TagNumber(13)
  SessionControlEvent ensureSessionControl() => $_ensure(6);

  @$pb.TagNumber(14)
  ReleaseAllInput get releaseAllInput => $_getN(7);
  @$pb.TagNumber(14)
  set releaseAllInput(ReleaseAllInput value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasReleaseAllInput() => $_has(7);
  @$pb.TagNumber(14)
  void clearReleaseAllInput() => $_clearField(14);
  @$pb.TagNumber(14)
  ReleaseAllInput ensureReleaseAllInput() => $_ensure(7);
}

enum PointerFastEnvelope_Event { move, scroll, notSet }

class PointerFastEnvelope extends $pb.GeneratedMessage {
  factory PointerFastEnvelope({
    $0.ProtocolVersion? protocolVersion,
    $core.List<$core.int>? sessionId,
    $fixnum.Int64? sequence,
    PointerMoveEvent? move,
    PointerScrollEvent? scroll,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (sessionId != null) result.sessionId = sessionId;
    if (sequence != null) result.sequence = sequence;
    if (move != null) result.move = move;
    if (scroll != null) result.scroll = scroll;
    return result;
  }

  PointerFastEnvelope._();

  factory PointerFastEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PointerFastEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PointerFastEnvelope_Event>
      _PointerFastEnvelope_EventByTag = {
    10: PointerFastEnvelope_Event.move,
    11: PointerFastEnvelope_Event.scroll,
    0: PointerFastEnvelope_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PointerFastEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'roammand.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11])
    ..aOM<$0.ProtocolVersion>(1, _omitFieldNames ? '' : 'protocolVersion',
        subBuilder: $0.ProtocolVersion.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<PointerMoveEvent>(10, _omitFieldNames ? '' : 'move',
        subBuilder: PointerMoveEvent.create)
    ..aOM<PointerScrollEvent>(11, _omitFieldNames ? '' : 'scroll',
        subBuilder: PointerScrollEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerFastEnvelope clone() => PointerFastEnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerFastEnvelope copyWith(void Function(PointerFastEnvelope) updates) =>
      super.copyWith((message) => updates(message as PointerFastEnvelope))
          as PointerFastEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PointerFastEnvelope create() => PointerFastEnvelope._();
  @$core.override
  PointerFastEnvelope createEmptyInstance() => create();
  static $pb.PbList<PointerFastEnvelope> createRepeated() =>
      $pb.PbList<PointerFastEnvelope>();
  @$core.pragma('dart2js:noInline')
  static PointerFastEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PointerFastEnvelope>(create);
  static PointerFastEnvelope? _defaultInstance;

  PointerFastEnvelope_Event whichEvent() =>
      _PointerFastEnvelope_EventByTag[$_whichOneof(0)]!;
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.ProtocolVersion get protocolVersion => $_getN(0);
  @$pb.TagNumber(1)
  set protocolVersion($0.ProtocolVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ProtocolVersion ensureProtocolVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get sessionId => $_getN(1);
  @$pb.TagNumber(2)
  set sessionId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sequence => $_getI64(2);
  @$pb.TagNumber(3)
  set sequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);

  @$pb.TagNumber(10)
  PointerMoveEvent get move => $_getN(3);
  @$pb.TagNumber(10)
  set move(PointerMoveEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMove() => $_has(3);
  @$pb.TagNumber(10)
  void clearMove() => $_clearField(10);
  @$pb.TagNumber(10)
  PointerMoveEvent ensureMove() => $_ensure(3);

  @$pb.TagNumber(11)
  PointerScrollEvent get scroll => $_getN(4);
  @$pb.TagNumber(11)
  set scroll(PointerScrollEvent value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasScroll() => $_has(4);
  @$pb.TagNumber(11)
  void clearScroll() => $_clearField(11);
  @$pb.TagNumber(11)
  PointerScrollEvent ensureScroll() => $_ensure(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
