// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

/// Eight short words, far more than fits in one column of the boxes below.
final String text = List.filled(8, '\u1828\u1822\u182D').join(' ');

Future<double> heightAt(WidgetTester tester, double boxHeight,
    {int? maxLines}) async {
  await tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: boxHeight),
        child: MongolText(text, maxLines: maxLines),
      ),
    ),
  ));
  return tester.getSize(find.byType(MongolText)).height;
}

void main() {
  testWidgets('maxLines text grows again after shrinking', (tester) async {
    final double big = await heightAt(tester, 400.0, maxLines: 1);
    final double small = await heightAt(tester, 200.0, maxLines: 1);
    final double bigAgain = await heightAt(tester, 400.0, maxLines: 1);

    expect(small, lessThan(big), reason: 'a smaller box holds less text');
    expect(bigAgain, equals(big),
        reason: 'returning to the original box must restore the layout');
  });

  testWidgets('maxLines text keeps growing past its original size',
      (tester) async {
    await heightAt(tester, 400.0, maxLines: 1);
    await heightAt(tester, 200.0, maxLines: 1);
    final double bigger = await heightAt(tester, 600.0, maxLines: 1);

    expect(bigger, greaterThan(await heightAt(tester, 400.0, maxLines: 1)));
  });

  testWidgets('text without maxLines was never affected', (tester) async {
    final double big = await heightAt(tester, 400.0);
    await heightAt(tester, 200.0);
    expect(await heightAt(tester, 400.0), equals(big));
  });
}
