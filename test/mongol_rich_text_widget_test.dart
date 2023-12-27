// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';
import 'package:mongol/src/text/mongol_render_paragraph.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MongolRichText has text', (WidgetTester tester) async {
    await tester.pumpWidget(const MongolRichText(
      text: TextSpan(text: 'T'),
    ));

    final finder = find.byType(MongolRichText);
    expect(finder, findsOneWidget);

    final richText = finder.evaluate().single.widget as MongolRichText;
    expect(richText.text.text, equals('T'));
  });

  testWidgets('MongolRichText has correct size for single word',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: MongolText('Hello')));

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
    expect(baseSize.height, equals(70.0));
  });

  testWidgets('MongolRichText should not wrap when less than height constraint',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A string that should not wrap';
    await tester.pumpWidget(
      const Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
  });

  testWidgets('MongolRichText wraps text when taller than height constraint',
      (WidgetTester tester) async {
    // set the height of the surface so that the text will wrap
    await binding.setSurfaceSize(const Size(1000, 500));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A long long long string that should wrap';
    await tester.pumpWidget(
      const Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(28.0)); // two lines
    expect(baseSize.height, equals(500.0));
  });

  testWidgets('MongolRichText wraps text for new line character',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A string that\nshould wrap';
    await tester.pumpWidget(
      const Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(28.0));
    expect(baseSize.height, equals(182.0));
  });

  testWidgets('MongolRichText wraps text for new line character before space',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'A string that\n should wrap';
    await tester.pumpWidget(
      const Center(child: MongolText(myString)),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(28.0));
    expect(baseSize.height, equals(182.0));
  });

  testWidgets('MongolRichText has correct intrinsic width',
      (WidgetTester tester) async {
    final paragraph = MongolRenderParagraph(const TextSpan(text: 'A string'));

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

  testWidgets('MongolText rotates emoji automatically',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = '🇲🇳';
    await tester.pumpWidget(
      const Center(
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

  testWidgets('MongolText rotates and stacks two CJK character',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = '你好';
    await tester.pumpWidget(
      const Center(
        child: MongolText(
          myString,
        ),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
    expect(baseSize.height, equals(28.0));
  });

  testWidgets('MongolText handles mixed rotated and non-rotated text',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'ᠰᠠᠶᠢᠨ ᠪᠠᠶᠢᠨ᠎ᠠ ᠤᠤ︖ 👨‍👩‍👧🇭🇺22';
    await tester.pumpWidget(
      const Center(
        child: MongolText(
          myString,
        ),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(42.0));
    expect(baseSize.height,
        equals(282.7890625)); // should this be rounded to 283.0?
  });

  testWidgets('MongolText handles embedded formatting characters',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'ᠨᠠ\u200dᠢᠮᠠ';
    await tester.pumpWidget(
      const Center(
        child: MongolText(
          myString,
        ),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
    expect(baseSize.height, equals(70.0));
  });

  testWidgets('MongolText handles normal and rotated mix without spaces',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const myString = 'a你';
    await tester.pumpWidget(
      const Center(
        child: MongolText(
          myString,
        ),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
    expect(baseSize.height, equals(28.0));
  });
}
