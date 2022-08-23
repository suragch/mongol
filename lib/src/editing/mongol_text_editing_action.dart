// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/widgets/text_editing_action.dart

import 'package:flutter/widgets.dart' show Intent, ContextAction, StatefulElement, protected, primaryFocus;

import 'mongol_render_editable.dart';

// import 'actions.dart';
// import 'editable_text.dart';
// import 'focus_manager.dart';
// import 'framework.dart';

/// The recipient of a [MongolTextEditingAction].
///
/// MongolTextEditingActions will only be enabled when an implementer of this 
/// class is focused.
///
/// See also:
///
///   * [MongolEditableTextState], which implements this and is the most typical
///     target of a MongolTextEditingAction.
abstract class MongolTextEditingActionTarget {
  /// The renderer that handles [MongolTextEditingAction]s.
  ///
  /// See also:
  ///
  /// * [MongolEditableTextState.renderEditable], which overrides this.
  MongolRenderEditable get renderEditable;
}

/// An [Action] related to editing text.
///
/// Enables itself only when a [MongolTextEditingActionTarget], e.g. 
/// [MongolEditableText], is currently focused. The result of this is that when a
/// MongolTextEditingActionTarget is not focused, it will fall through to any
/// non-MongolTextEditingAction that handles the same shortcut. For example,
/// overriding the tab key in [Shortcuts] with a MongolTextEditingAction will only
/// invoke your MongolTextEditingAction when a MongolTextEditingActionTarget is focused,
/// otherwise the default tab behavior will apply.
///
/// The currently focused MongolTextEditingActionTarget is available in the [invoke]
/// method via [textEditingActionTarget].
///
/// See also:
///
///  * [CallbackAction], which is a similar Action type but unrelated to text
///    editing.
abstract class MongolTextEditingAction<T extends Intent> extends ContextAction<T> {
  /// Returns the currently focused [MongolTextEditingAction], or null if none is
  /// focused.
  @protected
  MongolTextEditingActionTarget? get textEditingActionTarget {
    // If a MongolTextEditingActionTarget is not focused, then ignore this action.
    if (primaryFocus?.context == null
        || primaryFocus!.context! is! StatefulElement
        || ((primaryFocus!.context! as StatefulElement).state is! MongolTextEditingActionTarget)) {
      return null;
    }
    return (primaryFocus!.context! as StatefulElement).state as MongolTextEditingActionTarget;
  }

  @override
  bool isEnabled(T intent) {
    // The Action is disabled if there is no focused MongolTextEditingActionTarget.
    return textEditingActionTarget != null;
  }
}
