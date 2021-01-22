import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol_paragraph.dart';

void main() {
  MongolParagraph _getParagraph(String text, double height) {
    final paragraphStyle = ui.ParagraphStyle();
    final paragraphBuilder = MongolParagraphBuilder(paragraphStyle);
    paragraphBuilder.addText(text);
    final constraints = MongolParagraphConstraints(height: height);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(constraints);
    return paragraph;
  }

  group('getBoxesForRange', () {
    test('single character gives correct ranges', () {
      final paragraph = _getParagraph('A', 300);

      var boxes = paragraph.getBoxesForRange(0, 1);
      expect(boxes.length, 1);
      expect(boxes.first.bottom, 14.0);

      // any negative range returns empty list
      boxes = paragraph.getBoxesForRange(-1, 1);
      expect(boxes.length, 0);

      // range beyond the test returns empty list
      boxes = paragraph.getBoxesForRange(1, 2);
      expect(boxes.length, 0);

      // range that includes text but also goes beyond returns inluded text
      boxes = paragraph.getBoxesForRange(0, 2);
      expect(boxes.length, 1);
      expect(boxes.first.bottom, 14.0);
    });

    test('single line with single run gives correct ranges', () {
      final paragraph = _getParagraph('ABC', 300);

      var boxes = paragraph.getBoxesForRange(0, 1);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 0.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 14.0);

      boxes = paragraph.getBoxesForRange(1, 2);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 14.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 28.0);

      boxes = paragraph.getBoxesForRange(2, 3);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 28.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 42.0);
    });

    test('single line with multiple runs gives correct ranges', () {
      final paragraph = _getParagraph('ABC 123', 300);

      // first run (ABC )

      var boxes = paragraph.getBoxesForRange(0, 1);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 0.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 14.0);

      boxes = paragraph.getBoxesForRange(1, 2);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 14.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 28.0);

      boxes = paragraph.getBoxesForRange(2, 3);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 28.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 42.0);

      boxes = paragraph.getBoxesForRange(3, 4);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 42.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 56.0);

      // TODO: second run (123)

      boxes = paragraph.getBoxesForRange(4, 5);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 56.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 70.0);
    });
  });
}
