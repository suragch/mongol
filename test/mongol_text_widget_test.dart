import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';
import 'package:mongol/mongol_font.dart';
import 'package:mongol/mongol_rich_text.dart';

void main() {
  testWidgets('MongolText has text', (WidgetTester tester) async {
    await tester.pumpWidget(MongolText('T'));

    final finder = find.byType(MongolText);
    expect(finder, findsOneWidget);

    final MongolText mongolText = finder.evaluate().single.widget;
    expect(mongolText.data, equals('T'));
  });

  testWidgets('MongolText able to set font', (WidgetTester tester) async {
    await tester.pumpWidget(
      MongolText(
        'T',
        style: TextStyle(fontFamily: 'Some Font'),
      ),
    );

    MongolText text = tester.firstWidget(find.byType(MongolText));
    expect(text, isNotNull);
    expect(text.style.fontFamily, equals('Some Font'));

    MongolRichText richText = tester.firstWidget(find.byType(MongolRichText));
    expect(richText, isNotNull);
    expect(richText.text.style.fontFamily, equals('Some Font'));
  });

  testWidgets('MongolText default to Mongol font', (WidgetTester tester) async {
    await tester.pumpWidget(
      MongolText(
        'T',
      ),
    );

    MongolRichText richText = tester.firstWidget(find.byType(MongolRichText));
    expect(richText, isNotNull);
    expect(richText.text.style.fontFamily, equals(MongolFont.qagan));
  });
}
