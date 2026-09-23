// Copyright 2014 The Flutter Authors.
// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';
import 'package:mongol/src/editing/mongol_input_decorator.dart';

const String inputText = 'text';

/// The decorator lays out along the vertical axis, so it is given a fixed
/// height and left free to take whatever width it needs.
Widget buildInputDecorator({
  InputDecoration decoration = const InputDecoration(),
  bool isEmpty = false,
  bool isFocused = false,
  double height = 300.0,
}) {
  return MaterialApp(
    home: Material(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: height,
          child: MongolInputDecorator(
            decoration: decoration,
            isEmpty: isEmpty,
            isFocused: isFocused,
            child: const MongolText(inputText),
          ),
        ),
      ),
    ),
  );
}

Finder findMongolText(String text) =>
    find.byWidgetPredicate((widget) => widget is MongolText && widget.data == text);

Size decoratorSize(WidgetTester tester) =>
    tester.getSize(find.byType(MongolInputDecorator));

void main() {
  testWidgets('MongolInputDecorator shows its child', (tester) async {
    await tester.pumpWidget(buildInputDecorator());
    expect(findMongolText(inputText), findsOneWidget);
  });

  testWidgets('MongolInputDecorator fills the height it is given',
      (tester) async {
    await tester.pumpWidget(buildInputDecorator(height: 300.0));
    expect(decoratorSize(tester).height, equals(300.0));
  });

  testWidgets('MongolInputDecorator shows hintText', (tester) async {
    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(hintText: 'hint'),
      isEmpty: true,
    ));
    await tester.pumpAndSettle();
    expect(findMongolText('hint'), findsOneWidget);
  });

  testWidgets('MongolInputDecorator shows labelText', (tester) async {
    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(labelText: 'label'),
      isEmpty: true,
    ));
    await tester.pumpAndSettle();
    expect(findMongolText('label'), findsOneWidget);
  });

  testWidgets('MongolInputDecorator shows prefixText and suffixText',
      (tester) async {
    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(prefixText: 'pre', suffixText: 'suf'),
    ));
    await tester.pumpAndSettle();
    expect(findMongolText('pre'), findsOneWidget);
    expect(findMongolText('suf'), findsOneWidget);
  });

  testWidgets('MongolInputDecorator shows errorText', (tester) async {
    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(errorText: 'error'),
    ));
    await tester.pumpAndSettle();
    expect(findMongolText('error'), findsOneWidget);
  });

  testWidgets('MongolInputDecorator shows counterText', (tester) async {
    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(counterText: 'counter'),
    ));
    await tester.pumpAndSettle();
    expect(findMongolText('counter'), findsOneWidget);
  });

  // The decorator is vertical, so the label, error and counter sit beside the
  // input and take width rather than height.

  testWidgets('labelText widens the decorator', (tester) async {
    await tester.pumpWidget(buildInputDecorator());
    final bare = decoratorSize(tester).width;

    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(labelText: 'label'),
      isEmpty: true,
    ));
    await tester.pumpAndSettle();
    expect(decoratorSize(tester).width, greaterThan(bare));
  });

  testWidgets('errorText widens the decorator', (tester) async {
    await tester.pumpWidget(buildInputDecorator());
    final bare = decoratorSize(tester).width;

    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(errorText: 'error'),
    ));
    await tester.pumpAndSettle();
    expect(decoratorSize(tester).width, greaterThan(bare));
  });

  testWidgets('counterText widens the decorator', (tester) async {
    await tester.pumpWidget(buildInputDecorator());
    final bare = decoratorSize(tester).width;

    await tester.pumpWidget(buildInputDecorator(
      decoration: const InputDecoration(counterText: 'counter'),
    ));
    await tester.pumpAndSettle();
    expect(decoratorSize(tester).width, greaterThan(bare));
  });

  group('icon', () {
    testWidgets('is shown at the default size', (tester) async {
      await tester.pumpWidget(buildInputDecorator(
        decoration: const InputDecoration(icon: Icon(Icons.pages)),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Icon), findsOneWidget);
      expect(tester.getSize(find.byType(Icon)), equals(const Size(24.0, 24.0)));
    });

    testWidgets('moves the input down the vertical axis', (tester) async {
      await tester.pumpWidget(buildInputDecorator());
      final withoutIcon = tester.getTopLeft(findMongolText(inputText));

      await tester.pumpWidget(buildInputDecorator(
        decoration: const InputDecoration(icon: Icon(Icons.pages)),
      ));
      await tester.pumpAndSettle();
      final withIcon = tester.getTopLeft(findMongolText(inputText));

      // The icon leads the input, so it takes space before it rather than
      // beside it.
      expect(withIcon.dy, greaterThan(withoutIcon.dy));
    });

    testWidgets('is placed before the input', (tester) async {
      await tester.pumpWidget(buildInputDecorator(
        decoration: const InputDecoration(icon: Icon(Icons.pages)),
      ));
      await tester.pumpAndSettle();
      final icon = tester.getTopLeft(find.byType(Icon));
      final input = tester.getTopLeft(findMongolText(inputText));
      expect(icon.dy, lessThan(input.dy));
    });
  });
}
