// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/src/base/mongol_paragraph.dart';

// The test font draws every glyph one font size across.
const double fontSize = 10.0;

MongolParagraph layoutParagraph(String text, double height) {
  final builder = MongolParagraphBuilder(ui.ParagraphStyle());
  builder.pushStyle(const TextStyle(fontSize: fontSize));
  builder.addText(text);
  return builder.build()..layout(MongolParagraphConstraints(height: height));
}

int engineLineCount(String text, double width) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle())
    ..pushStyle(ui.TextStyle(fontSize: fontSize))
    ..addText(text);
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: width));
  final count = paragraph.computeLineMetrics().length;
  paragraph.dispose();
  return count;
}

void main() {
  group('a word too long for a line -', () {
    test('is broken across lines', () {
      final paragraph = layoutParagraph('1234567890', 35);
      // 123 456 789 0
      expect(paragraph.computeLineMetrics().length, 4);
      expect(paragraph.width, 40);
      expect(paragraph.longestLine, 30);
    });

    test('breaks where ui.Paragraph breaks it', () {
      const texts = [
        '1234567890',
        'aa 1234567890123 bb',
        'see http://example.com/a-long/path-name ok',
        '12345\n1234567890\n',
      ];
      for (final text in texts) {
        for (var height = 10.0; height <= 200.0; height += 5) {
          expect(
            layoutParagraph(text, height).computeLineMetrics().length,
            engineLineCount(text, height),
            reason: '"$text" at height $height',
          );
        }
      }
    });

    test('keeps its text offsets', () {
      final paragraph = layoutParagraph('ab 1234567890 cd', 35);
      // ab_ 123 456 789 0_ cd
      expect(paragraph.computeLineMetrics().length, 6);

      expect(
        paragraph.getLineBoundary(const TextPosition(offset: 7)),
        const TextRange(start: 6, end: 9),
      );
      expect(
        paragraph.getLineBoundary(const TextPosition(offset: 12)),
        const TextRange(start: 12, end: 14),
      );

      // The middle of the third line, 456.
      final position = paragraph.getPositionForOffset(const Offset(25, 12));
      expect(position.offset, 7);

      final boxes = paragraph.getBoxesForRange(4, 11);
      expect(boxes.length, 3);
      expect(boxes.map((box) => box.height), [20, 30, 20]);
    });

    test('is still one word', () {
      final paragraph = layoutParagraph('ab 1234567890 cd', 35);
      expect(
        paragraph.getWordBoundary(const TextPosition(offset: 8)),
        const TextRange(start: 3, end: 13),
      );
    });

    test('does not change the intrinsic heights', () {
      final paragraph = layoutParagraph('ab 1234567890 cd', 35);
      expect(paragraph.minIntrinsicHeight, 110);
      expect(paragraph.maxIntrinsicHeight, 160);
    });

    test('is put back together when the line grows', () {
      final builder = MongolParagraphBuilder(ui.ParagraphStyle());
      builder.pushStyle(const TextStyle(fontSize: fontSize));
      builder.addText('ab 1234567890 cd');
      final paragraph = builder.build();

      paragraph.layout(const MongolParagraphConstraints(height: 35));
      expect(paragraph.computeLineMetrics().length, 6);
      paragraph.layout(const MongolParagraphConstraints(height: 200));
      expect(paragraph.computeLineMetrics().length, 1);
      paragraph.layout(const MongolParagraphConstraints(height: 55));
      // ab_ 12345 67890_ cd
      expect(paragraph.computeLineMetrics().length, 4);
      paragraph.dispose();
    });

    test('keeps each of its styles', () {
      final builder = MongolParagraphBuilder(ui.ParagraphStyle());
      builder.pushStyle(const TextStyle(fontSize: fontSize));
      builder.addText('12345');
      builder.pushStyle(const TextStyle(fontSize: 2 * fontSize));
      builder.addText('67890');
      final paragraph = builder.build()
        ..layout(const MongolParagraphConstraints(height: 60));

      // 12345 678 90, the last two lines twice as wide.
      final lines = paragraph.computeLineMetrics();
      expect(lines.map((line) => line.height), [50, 60, 40]);
      expect(paragraph.width, 10 + 2 * 20);
    });

    test('is not cut short by the maxLines of the paragraph style', () {
      // MongolTextPainter passes its maxLines and ellipsis in the style too.
      final builder = MongolParagraphBuilder(
        ui.ParagraphStyle(maxLines: 2, ellipsis: '…'),
      );
      builder.pushStyle(const TextStyle(fontSize: fontSize));
      builder.addText('ab 12345678901234567890 cd');
      final paragraph = builder.build()
        ..layout(const MongolParagraphConstraints(height: 35));

      // ab_ 123 456 789 012 345 678 90_ cd
      expect(paragraph.computeLineMetrics().length, 9);
      expect(paragraph.longestLine, 30);
    });

    test('that cannot be broken does not leave an empty line before it', () {
      final paragraph = layoutParagraph('W', 5);
      expect(paragraph.computeLineMetrics().length, 1);
      expect(paragraph.width, 10);
    });
  });
}
