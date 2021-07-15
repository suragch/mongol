// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';

void main() {
  testWidgets('MongolText has text', (WidgetTester tester) async {
    await tester.pumpWidget(const MongolText('T'));

    final finder = find.byType(MongolText);
    expect(finder, findsOneWidget);

    final mongolText = finder.evaluate().single.widget as MongolText;
    expect(mongolText.data, equals('T'));
  });

  testWidgets('MongolText able to set font', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MongolText(
        'T',
        style: TextStyle(fontFamily: 'Some Font'),
      ),
    );

    final text = tester.firstWidget(find.byType(MongolText)) as MongolText;
    expect(text, isNotNull);
    expect(text.style!.fontFamily, equals('Some Font'));

    final richText =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(richText, isNotNull);
    expect(richText.text.style!.fontFamily, equals('Some Font'));
  });
}
