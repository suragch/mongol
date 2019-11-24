import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';

void main() {
  testWidgets('MongolText has text', (WidgetTester tester) async {
    await tester.pumpWidget(MongolText('T'));

    final finder = find.byType(MongolText);
    expect(finder, findsOneWidget);

    final MongolText mongolText = finder.evaluate().single.widget;
    expect(mongolText.data, equals('T'));
  });
}

