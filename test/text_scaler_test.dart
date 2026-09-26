// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

Widget wrap(Widget child) => MaterialApp(
      home: Align(alignment: Alignment.topLeft, child: child),
    );

void main() {
  group('MongolText', () {
    testWidgets('textScaler scales the text', (tester) async {
      await tester.pumpWidget(
          wrap(const MongolText('ᠨᠢᠭᠡ', textScaler: TextScaler.noScaling)));
      final Size unscaled = tester.getSize(find.byType(MongolText));

      await tester.pumpWidget(
          wrap(const MongolText('ᠨᠢᠭᠡ', textScaler: TextScaler.linear(2.0))));
      final Size scaled = tester.getSize(find.byType(MongolText));

      expect(scaled.height, greaterThan(unscaled.height));
      expect(scaled.width, greaterThan(unscaled.width));
    });

    testWidgets('the deprecated textScaleFactor still scales the text',
        (tester) async {
      await tester.pumpWidget(
          wrap(const MongolText('ᠨᠢᠭᠡ', textScaler: TextScaler.linear(2.0))));
      final Size viaScaler = tester.getSize(find.byType(MongolText));

      await tester.pumpWidget(wrap(
        // ignore: deprecated_member_use_from_same_package
        const MongolText('ᠨᠢᠭᠡ', textScaleFactor: 2.0),
      ));
      final Size viaFactor = tester.getSize(find.byType(MongolText));

      expect(viaFactor, equals(viaScaler));
    });
  });

  group('MongolRichText', () {
    testWidgets('textScaler scales the text', (tester) async {
      await tester.pumpWidget(wrap(MongolRichText(
        text: const TextSpan(text: 'ᠨᠢᠭᠡ'),
        textScaler: TextScaler.noScaling,
      )));
      final Size unscaled = tester.getSize(find.byType(MongolRichText));

      await tester.pumpWidget(wrap(MongolRichText(
        text: const TextSpan(text: 'ᠨᠢᠭᠡ'),
        textScaler: const TextScaler.linear(2.0),
      )));
      final Size scaled = tester.getSize(find.byType(MongolRichText));

      expect(scaled.height, greaterThan(unscaled.height));
    });

    testWidgets('the deprecated textScaleFactor matches the equivalent scaler',
        (tester) async {
      await tester.pumpWidget(wrap(MongolRichText(
        text: const TextSpan(text: 'ᠨᠢᠭᠡ'),
        textScaler: const TextScaler.linear(2.0),
      )));
      final Size viaScaler = tester.getSize(find.byType(MongolRichText));

      await tester.pumpWidget(wrap(MongolRichText(
        text: const TextSpan(text: 'ᠨᠢᠭᠡ'),
        // ignore: deprecated_member_use_from_same_package
        textScaleFactor: 2.0,
      )));
      final Size viaFactor = tester.getSize(find.byType(MongolRichText));

      expect(viaFactor, equals(viaScaler));
    });

    testWidgets('passing both textScaler and textScaleFactor asserts',
        (tester) async {
      expect(
        () => MongolRichText(
          text: const TextSpan(text: 'ᠨᠢᠭᠡ'),
          textScaler: const TextScaler.linear(2.0),
          // ignore: deprecated_member_use_from_same_package
          textScaleFactor: 3.0,
        ),
        throwsAssertionError,
      );
    });
  });
}
