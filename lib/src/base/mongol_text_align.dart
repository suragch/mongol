// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Whether and how to align text vertically.
///
/// This is only used at the MongolTextPainter level and above. Below that the
/// more primitive [TextAlign] enum is used and top is mapped to left and
/// bottom is mapped to right.
enum MongolTextAlign {
  /// Align the text on the top edge of the container.
  top,

  /// Align the text on the bottom edge of the container.
  bottom,

  /// Align the text in the center of the container.
  center,

  /// Stretch lines of text that end with a soft line break to fill the height
  /// of the container.
  ///
  /// Lines that end with hard line breaks are aligned towards the [top] edge.
  justify,
}
