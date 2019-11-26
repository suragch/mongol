import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';

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
    expect(baseSize.width, equals(30.0));
    expect(baseSize.height, equals(150.0));
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
    expect(baseSize.width, equals(30.0));
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
    expect(baseSize.width, equals(60.0)); // two lines
    expect(baseSize.height, equals(500.0));
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
    expect(baseSize.width, equals(60.0));
    expect(baseSize.height, equals(750.0));


  });
}
