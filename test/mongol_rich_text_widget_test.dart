import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';

void main() {
  testWidgets('MongolRichText has text', (WidgetTester tester) async {
    await tester.pumpWidget(MongolRichText(text: TextSpan(text: 'T'),));

    final finder = find.byType(MongolRichText);
    expect(finder, findsOneWidget);

    final MongolRichText richText = finder.evaluate().single.widget;
    expect(richText.text.text, equals('T'));
  });
}
