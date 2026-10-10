// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

void main() {
  // This is what happens on the web when the text needs a fallback font: the
  // first layout uses whatever fonts are loaded, and when the fallback font
  // arrives the engine reports a system font change.
  testWidgets('MongolText lays out again when a font it uses arrives', (
    tester,
  ) async {
    const style = TextStyle(fontFamily: 'ArrivesLater', fontSize: 20);
    const text = 'ᠮᠣᠩᠭᠣᠯ';
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: MongolText(text, style: style)),
      ),
    );
    // Until the font is loaded the test font draws each character as a
    // square, one font size tall.
    expect(tester.getSize(find.byType(MongolText)).height, 120);

    final bytes = await tester.runAsync(
      () => File('example/assets/fonts/MQG8F02.ttf').readAsBytes(),
    );
    final loader = FontLoader('ArrivesLater')
      ..addFont(Future.value(ByteData.sublistView(bytes!)));
    await tester.runAsync(loader.load);
    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byType(MongolText)).height, isNot(120));
  });
}
