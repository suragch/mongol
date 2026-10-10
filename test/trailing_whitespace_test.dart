// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/src/base/mongol_paragraph.dart';
import 'package:mongol/src/base/mongol_text_align.dart';

// The test font draws every glyph as a solid square one font size across and
// gives a space the same advance, so painted extents can be read off exactly.
const double fontSize = 10.0;

MongolParagraph layoutParagraph(
  String text,
  double height,
  MongolTextAlign textAlign,
) {
  final builder = MongolParagraphBuilder(
    ui.ParagraphStyle(),
    textAlign: textAlign,
  );
  builder.pushStyle(const TextStyle(fontSize: fontSize));
  builder.addText(text);
  return builder.build()..layout(MongolParagraphConstraints(height: height));
}

/// The first and last rows that the paragraph paints ink into.
Future<(int, int)> paintedRows(
  WidgetTester tester,
  MongolParagraph paragraph,
) async {
  final width = paragraph.width.ceil();
  final height = paragraph.height.ceil();
  final recorder = ui.PictureRecorder();
  paragraph.draw(ui.Canvas(recorder), Offset.zero);
  final picture = recorder.endRecording();
  final bytes = (await tester.runAsync(() async {
    final image = await picture.toImage(width, height);
    final data = await image.toByteData();
    image.dispose();
    return data;
  }))!;
  picture.dispose();

  var first = -1;
  var last = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = bytes.getUint8((y * width + x) * 4 + 3);
      if (alpha != 0) {
        if (first < 0) first = y;
        last = y;
        break;
      }
    }
  }
  return (first, last);
}

void main() {
  group('trailing spaces are not aligned -', () {
    testWidgets('bottom aligned text reaches the bottom edge', (tester) async {
      // 'aaa bb ' is 60 of ink and one trailing space.
      final paragraph = layoutParagraph('aaa bb ', 100, MongolTextAlign.bottom);

      final (first, last) = await paintedRows(tester, paragraph);
      expect(first, 40);
      expect(last, 99);
    });

    testWidgets('center aligned text is centered on its glyphs', (
      tester,
    ) async {
      // 'aaa bb ' is 60 of ink and one trailing space.
      final paragraph = layoutParagraph('aaa bb ', 100, MongolTextAlign.center);

      final (first, last) = await paintedRows(tester, paragraph);
      expect(first, 20);
      expect(last, 79);
    });

    testWidgets('justified lines run from edge to edge', (tester) async {
      final paragraph = layoutParagraph(
        'aaa bbb cc dd',
        100,
        MongolTextAlign.justify,
      );
      // The last line is never justified, so the first line, 'aaa bbb ', is
      // the one that reaches the bottom edge. The second only reaches 50.
      expect(paragraph.computeLineMetrics().length, 2);

      final (first, last) = await paintedRows(tester, paragraph);
      expect(first, 0);
      expect(last, 99);
    });

    test('line metrics report where the line is painted', () {
      final bottom = layoutParagraph('aaa bb ', 100, MongolTextAlign.bottom);
      expect(bottom.computeLineMetrics().single.top, 40);

      final center = layoutParagraph('aaa bb ', 100, MongolTextAlign.center);
      expect(center.computeLineMetrics().single.top, 20);
    });

    test('longestLine leaves out trailing spaces', () {
      final paragraph = layoutParagraph('aaa bb ', 100, MongolTextAlign.top);
      expect(paragraph.longestLine, 60);
    });
  });

  group('trailing spaces hang past the end of the line -', () {
    // 'aaa bbb ' is 80 with its trailing space and 70 without it, and
    // 'cccccc' is too long to join it.
    for (final height in [70.0, 75.0, 79.0]) {
      test(
        'a word that fits without its space stays on the line ($height)',
        () {
          final paragraph = layoutParagraph(
            'aaa bbb cccccc',
            height,
            MongolTextAlign.top,
          );
          expect(paragraph.computeLineMetrics().length, 2);
        },
      );
    }

    test('line breaks match ui.Paragraph', () {
      const text = 'aaa bbb ccc dd e ffff gg';
      for (var height = 40.0; height <= 240.0; height += 5) {
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle())
          ..pushStyle(ui.TextStyle(fontSize: fontSize))
          ..addText(text);
        final expected = builder.build()
          ..layout(ui.ParagraphConstraints(width: height));
        final paragraph = layoutParagraph(text, height, MongolTextAlign.top);
        expect(
          paragraph.computeLineMetrics().length,
          expected.computeLineMetrics().length,
          reason: 'at height $height',
        );
        expected.dispose();
      }
    });

    test('a line of only spaces does not wrap', () {
      final paragraph = layoutParagraph('aa      ', 30, MongolTextAlign.top);
      expect(paragraph.computeLineMetrics().length, 1);
    });
  });
}
