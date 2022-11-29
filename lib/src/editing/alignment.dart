// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// The horizontal alignment of vertical Mongolian text within an input box.
///
/// A single [x] value that can range from -1.0 to 1.0. -1.0 aligns to the left side
/// of an input box so that the left side of the first line of text fits within the
/// box and its padding. 0.0 aligns to the center of the box. 1.0 aligns so that
/// the right side of the last line of text aligns with the right interior edge of
/// the input box.
///
/// See also:
///
///  * [TextAlignVertical], which is the [TextField] version for horizontal text
///  * [MongolTextField.textAlignHorizontal], which is passed on to the [MongolInputDecorator].
///  * [MongolInputDecorator.textAlignHorizontal], which defines the alignment of
///    prefix, input, and suffix within an [MongolInputDecorator].
class TextAlignHorizontal {
  /// Creates a TextAlignHorizontal from any x value between -1.0 and 1.0.
  const TextAlignHorizontal({
    required this.x,
  }) : assert(x >= -1.0 && x <= 1.0);

  /// A value ranging from -1.0 to 1.0 that defines the leftmost and rightmost
  /// locations of the left and right sides of the input box.
  final double x;

  /// Aligns a MongolTextField's input text with the leftmost location within a
  /// MongolTextField's input box.
  static const TextAlignHorizontal left = TextAlignHorizontal(x: -1.0);

  /// Aligns a MongolTextField's input text to the center of the MongolTextField.
  static const TextAlignHorizontal center = TextAlignHorizontal(x: 0.0);

  /// Aligns a MongolTextField's input text with the rightmost location within a
  /// MongolTextField.
  static const TextAlignHorizontal right = TextAlignHorizontal(x: 1.0);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'TextAlignHorizontal')}(x: $x)';
  }
}
