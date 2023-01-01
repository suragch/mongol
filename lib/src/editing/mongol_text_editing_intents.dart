// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next character
/// boundary.
class MongolExtendSelectionByCharacterIntent
    extends ExtendSelectionByCharacterIntent {
  /// Creates an [MongolExtendSelectionByCharacterIntent].
  const MongolExtendSelectionByCharacterIntent(
      {required super.forward, required super.collapseSelection});
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the closest position on the adjacent
/// line.
class MongolExtendSelectionHorizontallyToAdjacentLineIntent
    extends ExtendSelectionVerticallyToAdjacentLineIntent {
  /// Creates an [MongolExtendSelectionHorizontallyToAdjacentLineIntent].
  const MongolExtendSelectionHorizontallyToAdjacentLineIntent(
      {required super.forward, required super.collapseSelection});
}

/// Expands the current selection to the closest line break in the direction
/// given by [forward].
///
/// Either the base or extent can move, whichever is closer to the line break.
/// The selection will never shrink.
///
/// This behavior is common on MacOS.
///
/// See also:
///
///   [MongolExtendSelectionToLineBreakIntent], which is similar but always moves the
///   extent.
class MongolExpandSelectionToLineBreakIntent
    extends ExpandSelectionToLineBreakIntent {
  /// Creates an [MongolExpandSelectionToLineBreakIntent].
  const MongolExpandSelectionToLineBreakIntent({required super.forward});
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the closest line break in the direction
/// given by [forward].
///
/// See also:
///
///   [ExpandSelectionToLineBreakIntent], which is similar but always increases
///   the size of the selection.
class MongolExtendSelectionToLineBreakIntent
    extends ExtendSelectionToLineBreakIntent {
  /// Creates an [MongolExtendSelectionToLineBreakIntent].
  const MongolExtendSelectionToLineBreakIntent(
      {required super.forward,
      required super.collapseSelection,
      super.collapseAtReversal,
      super.continuesAtWrap});
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the start or the end of the document.
///
/// See also:
///
///   [ExtendSelectionToDocumentBoundaryIntent], which is similar but always
///   increases the size of the selection.
class MongolExtendSelectionToDocumentBoundaryIntent
    extends ExtendSelectionToDocumentBoundaryIntent {
  /// Creates an [MongolExtendSelectionToDocumentBoundaryIntent].
  const MongolExtendSelectionToDocumentBoundaryIntent(
      {required super.forward, required super.collapseSelection});
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next word
/// boundary.
class MongolExtendSelectionToNextWordBoundaryIntent
    extends ExtendSelectionToNextWordBoundaryIntent {
  /// Creates an [MongolExtendSelectionToNextWordBoundaryIntent].
  const MongolExtendSelectionToNextWordBoundaryIntent(
      {required super.forward, required super.collapseSelection});
}

/// Extends, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next word
/// boundary, or the [TextSelection.base] position if it's closer in the move
/// direction.
///
/// This [Intent] typically has the same effect as an
/// [MongolExtendSelectionToNextWordBoundaryIntent], except it collapses the selection
/// when the order of [TextSelection.base] and [TextSelection.extent] would
/// reverse.
///
/// This is typically only used on MacOS.
class MongolExtendSelectionToNextWordBoundaryOrCaretLocationIntent
    extends ExtendSelectionToNextWordBoundaryOrCaretLocationIntent {
  /// Creates an [MongolExtendSelectionToNextWordBoundaryOrCaretLocationIntent].
  const MongolExtendSelectionToNextWordBoundaryOrCaretLocationIntent(
      {required super.forward});
}
