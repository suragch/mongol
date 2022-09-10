// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Swap up/down arrow keys and left/right arrow keys on platforms other than the web.
/// [DefaultTextEditingShortcuts._webDisablingTextShortcuts] said, "Web handles
/// its text selection natively and doesn't use any of these shortcuts in Flutter".
/// so maybe there is no way to swap these keys, but I'm not sure.
class DefaultMongolTextEditingShortcuts extends StatelessWidget {
  const DefaultMongolTextEditingShortcuts({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  // These are shortcuts are shared between most platforms except macOS for it
  // uses different modifier keys as the line/word modifier.
  static final Map<ShortcutActivator, Intent> _commonShortcuts =
      <ShortcutActivator, Intent>{
    // Arrow: Move Selection.
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const ExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const ExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
        const ExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
        const ExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
            shift: true, alt: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
        const ExtendSelectionToNextWordBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
        const ExtendSelectionToNextWordBoundaryIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp,
            shift: true, control: true):
        const ExtendSelectionToNextWordBoundaryIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown,
            shift: true, control: true):
        const ExtendSelectionToNextWordBoundaryIntent(
            forward: true, collapseSelection: false),
  };

  // The following key combinations have no effect on text editing on this
  // platform:
  //   * End
  //   * Home
  //   * Meta + X
  //   * Meta + C
  //   * Meta + V
  //   * Meta + A
  //   * Meta + shift? + Z
  //   * Meta + shift? + arrow down
  //   * Meta + shift? + arrow left
  //   * Meta + shift? + arrow right
  //   * Meta + shift? + arrow up
  //   * Shift + end
  //   * Shift + home
  //   * Meta + shift? + delete
  //   * Meta + shift? + backspace
  static final Map<ShortcutActivator, Intent> _androidShortcuts =
      _commonShortcuts;

  static final Map<ShortcutActivator, Intent> _fuchsiaShortcuts =
      _androidShortcuts;

  static final Map<ShortcutActivator, Intent> _linuxShortcuts =
      _commonShortcuts;

  // macOS document shortcuts: https://support.apple.com/en-us/HT201236.
  // The macOS shortcuts uses different word/line modifiers than most other
  // platforms.
  static final Map<ShortcutActivator, Intent> _macShortcuts =
      <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const ExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const ExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
        const ExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
        const ExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
        const ExtendSelectionVerticallyToAdjacentLineIntent(
            forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
        const ExtendSelectionToNextWordBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
        const ExtendSelectionToNextWordBoundaryIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true):
        const ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(
            forward: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true):
        const ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(
            forward: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: false, collapseAtReversal: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
            shift: true, alt: true):
        const ExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: false, collapseAtReversal: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true):
        const ExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, meta: true):
        const ExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true):
        const ExpandSelectionToLineBreakIntent(forward: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown,
        shift: true,
        meta: true): const ExpandSelectionToLineBreakIntent(forward: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft,
            shift: true, meta: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
            shift: true, meta: true):
        const ExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: false),
  };

  // There is no complete documentation of iOS shortcuts. Use mac shortcuts for
  // now.
  static final Map<ShortcutActivator, Intent> _iOSShortcuts = _macShortcuts;

  static final Map<ShortcutActivator, Intent> _windowsShortcuts =
      _commonShortcuts;

  static Map<ShortcutActivator, Intent> get _shortcuts {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidShortcuts;
      case TargetPlatform.fuchsia:
        return _fuchsiaShortcuts;
      case TargetPlatform.iOS:
        return _iOSShortcuts;
      case TargetPlatform.linux:
        return _linuxShortcuts;
      case TargetPlatform.macOS:
        return _macShortcuts;
      case TargetPlatform.windows:
        return _windowsShortcuts;
    }
  }

  // Web handles its text selection natively and doesn't use any of these
  // shortcuts in Flutter.
  static final Map<ShortcutActivator, Intent> _webDisablingTextShortcuts =
      <ShortcutActivator, Intent>{
    for (final bool pressShift in const <bool>[
      true,
      false
    ]) ...<SingleActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift):
          const DoNothingAndStopPropagationTextIntent(),
      SingleActivator(LogicalKeyboardKey.delete, shift: pressShift):
          const DoNothingAndStopPropagationTextIntent(),
      SingleActivator(LogicalKeyboardKey.backspace,
          alt: true,
          shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
      SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift):
          const DoNothingAndStopPropagationTextIntent(),
      SingleActivator(LogicalKeyboardKey.backspace,
          control: true,
          shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
      SingleActivator(LogicalKeyboardKey.delete,
          control: true,
          shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
      SingleActivator(LogicalKeyboardKey.backspace,
          meta: true,
          shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
      SingleActivator(LogicalKeyboardKey.delete, meta: true, shift: pressShift):
          const DoNothingAndStopPropagationTextIntent(),
    },
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
        shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft,
        shift: true,
        control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
        shift: true,
        control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.end):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.home):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown,
        shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft,
        shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
        shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.end, shift: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.home, shift: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.end, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.home, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.space):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.enter):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyX, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyC, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyV, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyA, control: true):
        const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
        const DoNothingAndStopPropagationTextIntent(),
  };

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    if (kIsWeb) {
      // On the web, these shortcuts make sure of the following:
      //
      // 1. Shortcuts fired when an EditableText is focused are ignored and
      //    forwarded to the browser by the EditableText's Actions, because it
      //    maps DoNothingAndStopPropagationTextIntent to DoNothingAction.
      // 2. Shortcuts fired when no EditableText is focused will still trigger
      //    _shortcuts assuming DoNothingAndStopPropagationTextIntent is
      //    unhandled elsewhere.
      result = Shortcuts(
          debugLabel: '<Web Disabling Text Editing Shortcuts>',
          shortcuts: _webDisablingTextShortcuts,
          child: result);
    }
    return Shortcuts(
        debugLabel: '<Default Text Editing Shortcuts>',
        shortcuts: _shortcuts,
        child: result);
  }
}
