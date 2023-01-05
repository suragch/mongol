// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mongol_text_editing_intents.dart';

/// Switch up/down arrow keys and left/right arrow keys
///
/// Insert this widget just below the MaterialApp (or WidgetsApp or
/// CupertinoApp) in order to cause the arrow keys to behave as expected
/// in a `MongolTextField`.
///
/// ```
/// MaterialApp(
///   builder: (context, child) => MongolTextEditingShortcuts(child: child),
/// ```
class MongolTextEditingShortcuts extends StatelessWidget {
  const MongolTextEditingShortcuts({Key? key, required this.child})
      : super(key: key);

  final Widget? child;

  // These shortcuts are shared between most platforms except macOS, which
  // uses different modifier keys for the line/word modifier.
  static final Map<ShortcutActivator, Intent> _commonShortcuts =
      <ShortcutActivator, Intent>{
    // Arrow: Move Selection.
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const MongolExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const MongolExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
        const MongolExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
        const MongolExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
            shift: true, alt: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
        const MongolExtendSelectionToNextWordBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
        const MongolExtendSelectionToNextWordBoundaryIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp,
            shift: true, control: true):
        const MongolExtendSelectionToNextWordBoundaryIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown,
            shift: true, control: true):
        const MongolExtendSelectionToNextWordBoundaryIntent(
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
        const MongolExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const MongolExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
        const MongolExtendSelectionByCharacterIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
        const MongolExtendSelectionByCharacterIntent(
            forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
        const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
            forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
        const MongolExtendSelectionToNextWordBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
        const MongolExtendSelectionToNextWordBoundaryIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true):
        const MongolExtendSelectionToNextWordBoundaryOrCaretLocationIntent(
            forward: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true):
        const MongolExtendSelectionToNextWordBoundaryOrCaretLocationIntent(
            forward: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: false, collapseAtReversal: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
            shift: true, alt: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: false, collapseAtReversal: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, meta: true):
        const MongolExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true):
        const MongolExpandSelectionToLineBreakIntent(forward: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown,
            shift: true, meta: true):
        const MongolExpandSelectionToLineBreakIntent(forward: true),
    const SingleActivator(LogicalKeyboardKey.arrowLeft,
            shift: true, meta: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight,
            shift: true, meta: true):
        const MongolExtendSelectionToDocumentBoundaryIntent(
            forward: true, collapseSelection: false),
  };

  // There is no complete documentation of iOS shortcuts. Use mac shortcuts for
  // now.
  static final Map<ShortcutActivator, Intent> _iOSShortcuts = _macShortcuts;

  static final Map<ShortcutActivator, Intent> _windowsShortcuts =
      _commonShortcuts;

  static Map<ShortcutActivator, Intent> get shortcuts {
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

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        debugLabel: '<Mongol Text Editing Shortcuts>',
        shortcuts: shortcuts,
        child: child ?? const SizedBox.shrink());
  }
}
