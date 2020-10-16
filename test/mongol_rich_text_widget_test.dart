// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';
import 'package:mongol/mongol_rich_text.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized()
      as TestWidgetsFlutterBinding;

  testWidgets('MongolRichText has text', (WidgetTester tester) async {
    await tester.pumpWidget(MongolRichText(
      text: TextSpan(text: 'T'),
    ));

    final finder = find.byType(MongolRichText);
    expect(finder, findsOneWidget);

    final richText = finder.evaluate().single.widget as MongolRichText;
    expect(richText.text.text, equals('T'));
  });

  testWidgets('MongolRichText has correct size for single word',
      (WidgetTester tester) async {
    await tester.pumpWidget(Center(child: MongolText('Hello')));

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
    expect(baseSize.height, equals(70.0));
  });

  testWidgets('MongolRichText should not wrap when less than height constraint',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A string that should not wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
  });

  testWidgets('MongolRichText wraps text when taller than height constraint',
      (WidgetTester tester) async {
    // set the height of the surface so that the text will wrap
    await binding.setSurfaceSize(Size(1000, 500));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A long long long string that should wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(28.0)); // two lines
    expect(baseSize.height, equals(406.0));
  });

  testWidgets('MongolRichText wraps text for new line character',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A string that\nshould wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(28.0));
    expect(baseSize.height, equals(182.0));
  });

  testWidgets('MongolRichText wraps text for new line character before space',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A string that\n should wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(28.0));
    expect(baseSize.height, equals(182.0));
  });

  testWidgets('MongolRichText has correct instrinsic width',
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

  testWidgets('MongolText does not rotate emoji automatically upon request',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = '🇲🇳';
    await tester.pumpWidget(
      Center(
        child: MongolText(
          myString,
          autoRotate: false,
        ),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
    expect(baseSize.height, equals(28.0));
  });

  testWidgets('MongolText autoRotate defaults to true',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = '🇲🇳';
    await tester.pumpWidget(
      Center(
        child: MongolText(
          myString,
        ),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text, isNotNull);
    expect(text.autoRotate, true);
  });

  testWidgets('MongolText rotates emoji automatically',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = '🇲🇳';
    await tester.pumpWidget(
      Center(
        child: MongolText(
          myString,
        ),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(28.0));
    expect(baseSize.height, equals(14.0));
  });
}
