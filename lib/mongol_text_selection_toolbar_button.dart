// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' show Theme, Brightness, Colors, IconButton;
import 'package:flutter/widgets.dart';

enum _TextSelectionToolbarItemPosition {
  /// The first item among multiple in the menu.
  first,

  /// One of several items, not the first or last.
  middle,

  /// The last item among multiple in the menu.
  last,

  /// The only item in the menu.
  only,
}

/// A button styled like a Material native Android text selection menu button.
class MongolTextSelectionToolbarButton extends StatelessWidget {
  /// Creates an instance of MongolTextSelectionToolbarButton.
  const MongolTextSelectionToolbarButton({
    Key? key,
    required this.child,
    required this.padding,
    this.onPressed,
  }) : super(key: key);

  // These values were eyeballed to match the native text selection menu on a
  // Pixel 2 running Android 10.
  static const double _kMiddlePadding = 9.5;
  static const double _kEndPadding = 14.5;

  /// The child of this button.
  ///
  /// Usually an [Icon].
  final Widget child;

  /// Called when this button is pressed.
  final VoidCallback? onPressed;

  /// The padding between the button's edge and its child.
  ///
  /// See also:
  ///
  ///  * [getPadding], which calculates the standard padding based on the
  ///    button's position.
  ///  * [ButtonStyle.padding], which is where this padding is applied.
  final EdgeInsets padding;

  /// Returns the standard padding for a button at index out of a total number
  /// of buttons.
  static EdgeInsets getPadding(int index, int total) {
    assert(total > 0 && index >= 0 && index < total);
    final position = _getPosition(index, total);
    return EdgeInsets.only(
      top: _getTopPadding(position),
      bottom: _getBottomPadding(position),
    );
  }

  static double _getTopPadding(_TextSelectionToolbarItemPosition position) {
    if (position == _TextSelectionToolbarItemPosition.first
        || position == _TextSelectionToolbarItemPosition.only) {
      return _kEndPadding;
    }
    return _kMiddlePadding;
  }

  static double _getBottomPadding(_TextSelectionToolbarItemPosition position) {
    if (position == _TextSelectionToolbarItemPosition.last
        || position == _TextSelectionToolbarItemPosition.only) {
      return _kEndPadding;
    }
    return _kMiddlePadding;
  }

  static _TextSelectionToolbarItemPosition _getPosition(int index, int total) {
    if (index == 0) {
      return total == 1
          ? _TextSelectionToolbarItemPosition.only
          : _TextSelectionToolbarItemPosition.first;
    }
    if (index == total - 1) {
      return _TextSelectionToolbarItemPosition.last;
    }
    return _TextSelectionToolbarItemPosition.middle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final primary = isDark ? Colors.white : Colors.black87;

    return IconButton(
      padding: padding,
      color: primary,
      onPressed: onPressed,
      icon: child,
    );
  }
}
