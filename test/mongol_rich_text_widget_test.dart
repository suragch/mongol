import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';
import 'package:mongol/mongol_rich_text.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MongolRichText has text', (WidgetTester tester) async {
    await tester.pumpWidget(MongolRichText(
      text: TextSpan(text: 'T'),
    ));

    final finder = find.byType(MongolRichText);
    expect(finder, findsOneWidget);

    final MongolRichText richText = finder.evaluate().single.widget;
    expect(richText.text.text, equals('T'));
  });

  testWidgets('MongolRichText has correct size for single word',
      (WidgetTester tester) async {
    await tester.pumpWidget(Center(child: MongolText('Hello')));

    MongolRichText text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final Size baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(24.0));
    expect(baseSize.height, equals(120.0));
  });

  testWidgets('MongolRichText should not wrap when less than height constraint',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const String myString = 'A string that should not wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    MongolRichText text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final Size baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(24.0));
  });

  testWidgets('MongolRichText wraps text when taller than height constraint',
      (WidgetTester tester) async {
    // set the height of the surface so that the text will wrap
    await binding.setSurfaceSize(Size(1000, 500));
    addTearDown(() => binding.setSurfaceSize(null));

    const String myString = 'A string that should wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    MongolRichText text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final Size baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(48.0)); // two lines
    expect(baseSize.height, equals(336.0));
  });

  testWidgets('MongolRichText wraps text for new line character',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const String myString = 'A string that\nshould wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    MongolRichText text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final Size baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(48.0));
    expect(baseSize.height, equals(312.0));
  });

  testWidgets('MongolRichText wraps text for new line character before space',
      (WidgetTester tester) async {
    await binding.setSurfaceSize(Size(1000, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    const String myString = 'A string that\n should wrap';
    await tester.pumpWidget(
      Center(child: MongolText(myString)),
    );

    MongolRichText text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);

    final Size baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(48.0));
    expect(baseSize.height, equals(312.0));
  });

  testWidgets('MongolRichText has correct instrinsic width',
      (WidgetTester tester) async {
    MongolRenderParagraph paragraph =
        MongolRenderParagraph(TextSpan(text: 'A string'));

    final double textHeight = paragraph.getMaxIntrinsicHeight(double.infinity);
    final double oneLineTextWidth =
        paragraph.getMinIntrinsicWidth(double.infinity);
    final double constrainedHeight = textHeight * 0.9;
    final double wrappedTextHeight =
        paragraph.getMinIntrinsicHeight(double.infinity);
    final double twoLinesTextWidth =
        paragraph.getMinIntrinsicWidth(constrainedHeight);

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
