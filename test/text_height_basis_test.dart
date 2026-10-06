// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

/// Six short words. Laid out in a 200 tall box the columns do not fill it
/// exactly, so the two height bases give different answers: [parent] takes the
/// whole 200, [longestLine] only what the longest column needs.
final String wrappingText = List.filled(6, '\u1828\u1822\u182D').join(' ');

const double boxHeight = 200.0;

Widget wrap(Widget child, {TextWidthBasis? defaultBasis}) {
  Widget content = ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: boxHeight),
    child: child,
  );
  if (defaultBasis != null) {
    content = DefaultTextStyle(
      style: const TextStyle(fontSize: 14.0),
      textWidthBasis: defaultBasis,
      child: content,
    );
  }
  return MaterialApp(
    home: Align(alignment: Alignment.topLeft, child: content),
  );
}

void main() {
  testWidgets('MongolText defaults to filling the parent', (tester) async {
    await tester.pumpWidget(wrap(MongolText(wrappingText)));
    expect(tester.getSize(find.byType(MongolText)).height, equals(boxHeight));
  });

  testWidgets('MongolText with longestLine takes only what it needs', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MongolText(wrappingText, textHeightBasis: TextHeightBasis.longestLine),
      ),
    );
    expect(tester.getSize(find.byType(MongolText)).height, lessThan(boxHeight));
  });

  testWidgets('MongolRichText honours textHeightBasis', (tester) async {
    await tester.pumpWidget(
      wrap(MongolRichText(text: TextSpan(text: wrappingText))),
    );
    final double parent = tester.getSize(find.byType(MongolRichText)).height;

    await tester.pumpWidget(
      wrap(
        MongolRichText(
          text: TextSpan(text: wrappingText),
          textHeightBasis: TextHeightBasis.longestLine,
        ),
      ),
    );
    final double longestLine = tester
        .getSize(find.byType(MongolRichText))
        .height;

    expect(parent, equals(boxHeight));
    expect(longestLine, lessThan(parent));
  });

  testWidgets('an ambient DefaultTextStyle supplies the basis', (tester) async {
    await tester.pumpWidget(
      wrap(MongolText(wrappingText), defaultBasis: TextWidthBasis.longestLine),
    );
    expect(tester.getSize(find.byType(MongolText)).height, lessThan(boxHeight));
  });

  testWidgets('an explicit basis beats the DefaultTextStyle', (tester) async {
    await tester.pumpWidget(
      wrap(
        MongolText(wrappingText, textHeightBasis: TextHeightBasis.parent),
        defaultBasis: TextWidthBasis.longestLine,
      ),
    );
    expect(tester.getSize(find.byType(MongolText)).height, equals(boxHeight));
  });
}
