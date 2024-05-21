// Copyright 2014 The Flutter Authors.
// Copyright 2024 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

extension TextEditingControllerExtension on TextEditingController {
  /// Check that the [selection] is inside of the bounds of [text].
  bool isSelectionWithinTextBounds(TextSelection selection) {
    return selection.start <= text.length && selection.end <= text.length;
  }
}
