// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

void main() {
  testWidgets('MongolRenderParagraph has correct instrinsic width',
      (WidgetTester tester) async {
    final paragraph = MongolRenderParagraph(TextSpan(text: 'A string'));

    final textHeight = paragraph.getMaxIntrinsicHeight(double.infinity);
    final oneLineTextWidth = paragraph.getMinIntrinsicWidth(double.infinity);
    final constrainedHeight = textHeight * 0.9;
    final wrappedTextHeight = paragraph.getMinIntrinsicHeight(double.infinity);
    final twoLinesTextWidth = paragraph.getMinIntrinsicWidth(constrainedHeight);

    expect(wrappedTextHeight, greaterThan(0.0));
    expect(wrappedTextHeight, lessThan(textHeight));
    expect(oneLineTextWidth, lessThan(twoLinesTextWidth));
    expect(twoLinesTextWidth, lessThan(oneLineTextWidth * 3.0));
    expect(paragraph.getMaxIntrinsicWidth(double.infinity),
        equals(oneLineTextWidth));
    expect(paragraph.getMaxIntrinsicWidth(constrainedHeight),
        equals(twoLinesTextWidth));
  });
}
