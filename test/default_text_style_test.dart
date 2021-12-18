// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

void main() {
  testWidgets('DefaultTextStyle changes propagate to MongolRichText',
      (WidgetTester tester) async {
    const textWidget = MongolText('Hello');
    const s1 = TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.w900,
      height: 123.0,
    );

    await tester.pumpWidget(const DefaultTextStyle(
      style: s1,
      child: textWidget,
    ));

    final text =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text, isNotNull);
    expect(text.text.style, s1);
  });

  testWidgets('AnimatedDefaultTextStyle changes propagate to MongolText',
      (WidgetTester tester) async {
    const textWidget = MongolText('Hello');
    const s1 = TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.w800,
      height: 123.0,
    );
    const s2 = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w200,
      height: 1.0,
    );

    await tester.pumpWidget(const AnimatedDefaultTextStyle(
      style: s1,
      duration: Duration(milliseconds: 1000),
      child: textWidget,
    ));

    final text1 =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text1, isNotNull);
    expect(text1.text.style, s1);
    // expect(text1.textAlign, TextAlign.start);
    // expect(text1.softWrap, isTrue);
    // expect(text1.overflow, TextOverflow.clip);
    // expect(text1.maxLines, isNull);
    // expect(text1.textWidthBasis, TextWidthBasis.parent);
    // expect(text1.textHeightBehavior, isNull);

    await tester.pumpWidget(const AnimatedDefaultTextStyle(
      style: s2,
      textAlign: TextAlign.justify,
      softWrap: false,
      overflow: TextOverflow.fade,
      maxLines: 3,
      textWidthBasis: TextWidthBasis.longestLine,
      textHeightBehavior:
          ui.TextHeightBehavior(applyHeightToFirstAscent: false),
      duration: Duration(milliseconds: 1000),
      child: textWidget,
    ));

    final text2 =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text2, isNotNull);
    expect(text2.text.style, s1); // animation hasn't started yet
    // expect(text2.textAlign, TextAlign.justify);
    // expect(text2.softWrap, false);
    // expect(text2.overflow, TextOverflow.fade);
    // expect(text2.maxLines, 3);
    // expect(text2.textWidthBasis, TextWidthBasis.longestLine);
    // expect(text2.textHeightBehavior, const ui.TextHeightBehavior(applyHeightToFirstAscent: false));

    await tester.pump(const Duration(milliseconds: 1000));

    final text3 =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text3, isNotNull);
    expect(text3.text.style, s2); // animation has now finished
    // expect(text3.textAlign, TextAlign.justify);
    // expect(text3.softWrap, false);
    // expect(text3.overflow, TextOverflow.fade);
    // expect(text3.maxLines, 3);
    // expect(text2.textWidthBasis, TextWidthBasis.longestLine);
    // expect(text2.textHeightBehavior, const ui.TextHeightBehavior(applyHeightToFirstAscent: false));
  });
}
