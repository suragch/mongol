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
      boxes = paragraph.getBoxesForRange(-2, -1);
      expect(boxes.length, 0);

      // range beyond the test returns empty list
      boxes = paragraph.getBoxesForRange(1, 2);
      expect(boxes.length, 0);

      // range that includes text but also goes beyond returns inluded text
      boxes = paragraph.getBoxesForRange(0, 2);
      expect(boxes.length, 1);
      expect(boxes.first.bottom, 14.0);

      // start greater than length returns empty list
      boxes = paragraph.getBoxesForRange(10, 11);
      expect(boxes.length, 0);

      // start greater than end returns empty list
      boxes = paragraph.getBoxesForRange(1, 0);
      expect(boxes.length, 0);
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
      
      boxes = paragraph.getBoxesForRange(0, 3);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 0.0);
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

      // second run (123)

      boxes = paragraph.getBoxesForRange(4, 5);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 56.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 70.0);

      boxes = paragraph.getBoxesForRange(4, 7);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 56.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 98.0);

      // spanning both ranges

      boxes = paragraph.getBoxesForRange(0, 7);
      expect(boxes.length, 2);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 0.0);
      expect(boxes.first.width, 14.0);
      expect(boxes.first.height, 56.0);
      expect(boxes.last.left, 0.0);
      expect(boxes.last.top, 56.0);
      expect(boxes.last.width, 14.0);
      expect(boxes.last.height, 42.0);
    });

    test('multiple lines with selection spanning multiple lines', () {
      const multipleLines = 
      'ABC DEF 123 456\n'   //  0-16
      'ABC DEF 123 456\n'   // 16-32
      'ABC DEF 123 456\n'   // 32-48
      'ABC DEF 123 456\n'   // 48-64
      'ABC DEF 123 456\n';  // 64-80
      final paragraph = _getParagraph(multipleLines, 300);

      var boxes = paragraph.getBoxesForRange(21, 58); // 2nd row E to 4th row 2
      expect(boxes.length, 10);

      expect(boxes[0].left, 14.0);
      expect(boxes[0].top, 70.0);
      expect(boxes[0].width, 14.0);
      expect(boxes[0].height, 42.0);

      expect(boxes[1].left, 14.0);
      expect(boxes[1].top, 112.0);
      expect(boxes[1].width, 14.0);
      expect(boxes[1].height, 56.0);

      expect(boxes[2].left, 14.0);
      expect(boxes[2].top, 168.0);
      expect(boxes[2].width, 14.0);
      expect(boxes[2].height, 42.0);

      expect(boxes[3].left, 28.0);
      expect(boxes[3].top, 0.0);
      expect(boxes[3].width, 14.0);
      expect(boxes[3].height, 56.0);

      expect(boxes[4].left, 28.0);
      expect(boxes[4].top, 56.0);
      expect(boxes[4].width, 14.0);
      expect(boxes[4].height, 56.0);

      expect(boxes[5].left, 28.0);
      expect(boxes[5].top, 112.0);
      expect(boxes[5].width, 14.0);
      expect(boxes[5].height, 56.0);

      expect(boxes[6].left, 28.0);
      expect(boxes[6].top, 168.0);
      expect(boxes[6].width, 14.0);
      expect(boxes[6].height, 42.0);

      expect(boxes[7].left, 42.0);
      expect(boxes[7].top, 0.0);
      expect(boxes[7].width, 14.0);
      expect(boxes[7].height, 56.0);

      expect(boxes[8].left, 42.0);
      expect(boxes[8].top, 56.0);
      expect(boxes[8].width, 14.0);
      expect(boxes[8].height, 56.0);

      expect(boxes[9].left, 42.0);
      expect(boxes[9].top, 112.0);
      expect(boxes[9].width, 14.0);
      expect(boxes[9].height, 28.0);
    });
  });
}
