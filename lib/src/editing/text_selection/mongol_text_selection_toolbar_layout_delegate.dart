// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Positions the toolbar to the left of [anchorLeft] if it fits, or otherwise 
/// to the right of [anchorRight].
///
/// See also:
///
///   * [MongolTextSelectionToolbar], which uses this to position itself.
class MongolTextSelectionToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates an instance of MongolTextSelectionToolbarLayoutDelegate.
  MongolTextSelectionToolbarLayoutDelegate({
    required this.anchorLeft,
    required this.anchorRight,
    this.fitsLeft,
  });

  /// The focal point to the left of which the toolbar attempts to position 
  /// itself.
  ///
  /// If there is not enough room to the left before reaching the left of the 
  /// screen, then the toolbar will position itself to the right of 
  /// [anchorRight].
  ///
  /// Should be provided in local coordinates.
  final Offset anchorLeft;

  /// The focal point to the right of which the toolbar attempts to position 
  /// itself, if it doesn't fit to the left of [anchorLeft].
  ///
  /// Should be provided in local coordinates.
  final Offset anchorRight;

  /// Whether or not the child should be considered to fit to the left of
  /// anchorLeft.
  ///
  /// Typically used to force the child to be drawn at anchorLeft even when it
  /// doesn't fit, such as when the [MongolTextSelectionToolbar] draws an
  /// open overflow menu.
  ///
  /// If not provided, it will be calculated.
  final bool? fitsLeft;

  // Return the value that centers height as closely as possible to position
  // while fitting inside of min and max.
  static double _centerOn(double position, double height, double max) {
    // If it overflows above, put it as far above as possible.
    if (position - height / 2.0 < 0.0) {
      return 0.0;
    }

    // If it overflows below, put it as far below as possible.
    if (position + height / 2.0 > max) {
      return max - height;
    }

    // Otherwise it fits while perfectly centered.
    return position - height / 2.0;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final fitsLeft = this.fitsLeft ?? anchorLeft.dx >= childSize.width;
    final anchor = fitsLeft ? anchorLeft : anchorRight;

    return Offset(
      fitsLeft
        ? math.max(0.0, anchor.dx - childSize.width)
        : anchor.dx,
      _centerOn(
        anchor.dy,
        childSize.height,
        size.height,
      ),
    );
  }

  @override
  bool shouldRelayout(MongolTextSelectionToolbarLayoutDelegate oldDelegate) {
    return anchorLeft != oldDelegate.anchorLeft
        || anchorRight != oldDelegate.anchorRight
        || fitsLeft != oldDelegate.fitsLeft;
  }
}
