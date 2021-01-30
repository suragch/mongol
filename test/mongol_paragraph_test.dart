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

  /// This group is for testing [getBoxesForRange].
  ///
  /// You can compare the behavior to [Paragraph] with the following code:
  ///
  /// ```
  /// const text = 'ABC DEF 123 456\n' //   0-16
  ///     'ABC DEF 123 456\n' //  16-32
  ///     'ABC DEF 123 456\n' //  32-48
  ///     'ABC DEF 123 456\n' //  48-64
  ///     'ABC DEF 123 456\n'; // 64-80
  /// final paragraphStyle = ui.ParagraphStyle(
  ///   textDirection: ui.TextDirection.ltr,
  /// );
  /// final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
  ///   ..addText(text);
  /// final constraints = ui.ParagraphConstraints(width: 300);
  /// final paragraph = paragraphBuilder.build();
  /// paragraph.layout(constraints);
  /// final boxes = paragraph.getBoxesForRange(21, 58);
  /// print(boxes);
  /// ```
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
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 0.0);
      expect(boxes.first.width, 14.0);
      expect(boxes.first.height, 98.0);
    });

    test('multiple lines with selection spanning multiple lines', () {
      const multipleLines =
          'ABC DEF 123 456\n' //   0-16                         .
          'ABC DEF 123 456\n' //  16-32
          'ABC DEF 123 456\n' //  32-48
          'ABC DEF 123 456\n' //  48-64
          'ABC DEF 123 456\n'; // 64-80
      final paragraph = _getParagraph(multipleLines, 300);

      var boxes = paragraph.getBoxesForRange(21, 58); // 2nd row E to 4th row 2
      expect(boxes.length, 3);

      expect(boxes[0].left, 14.0);
      expect(boxes[0].top, 70.0);
      expect(boxes[0].width, 14.0);
      expect(boxes[0].height, 140.0);

      expect(boxes[1].left, 28.0);
      expect(boxes[1].top, 0.0);
      expect(boxes[1].width, 14.0);
      expect(boxes[1].height, 210.0);

      expect(boxes[2].left, 42.0);
      expect(boxes[2].top, 0.0);
      expect(boxes[2].width, 14.0);
      expect(boxes[2].height, 140.0);

      boxes = paragraph.getBoxesForRange(21, 64); // 2nd row E to 4th row \n
      expect(boxes.length, 3);

      expect(boxes[0].left, 14.0);
      expect(boxes[0].top, 70.0);
      expect(boxes[0].width, 14.0);
      expect(boxes[0].height, 140.0);

      expect(boxes[1].left, 28.0);
      expect(boxes[1].top, 0.0);
      expect(boxes[1].width, 14.0);
      expect(boxes[1].height, 210.0);

      expect(boxes[2].left, 42.0);
      expect(boxes[2].top, 0.0);
      expect(boxes[2].width, 14.0);
      expect(boxes[2].height, 210.0);

      // test last char == line end
    });

    test('handles grapheme clusters well', () {
      const graphemeClusters =
          '👨‍👩‍👦' // man + zwj + woman + zwj + boy                       0-8
          '👨‍👩‍👧‍👧' // man + zwj + woman + zwj + girl + zwj + girl         8-19
          '👏🏽'; // clapping + medium_skin_tone                       19-23
      final paragraph = _getParagraph(graphemeClusters, 300);
      expect(graphemeClusters.length, 23);

      var boxes = paragraph.getBoxesForRange(0, 23);
      expect(boxes.length, 1);

      // incomplete grapheme clusters aren't counted
      boxes = paragraph.getBoxesForRange(0, 1);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(0, 2);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(0, 7);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(3, 5);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(8, 16);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(10, 12);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(17, 19);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(19, 21);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(20, 21);
      expect(boxes.length, 0);
      boxes = paragraph.getBoxesForRange(21, 23);
      expect(boxes.length, 0);
      // https://github.com/flutter/flutter/issues/75051
      // boxes = paragraph.getBoxesForRange(7, 9);
      // expect(boxes.length, 0);
      // boxes = paragraph.getBoxesForRange(18, 20);
      // expect(boxes.length, 0);

      // only complete ranges count
      boxes = paragraph.getBoxesForRange(0, 8);
      expect(boxes.length, 1);
      // the actual width should be 14 but testing measures every emoji
      expect(boxes.first.width, 42);
      expect(boxes.first.height, 14);
      boxes = paragraph.getBoxesForRange(8, 19);
      expect(boxes.length, 1);
      expect(boxes.first.width, 56);
      expect(boxes.first.height, 14);
      boxes = paragraph.getBoxesForRange(19, 23);
      expect(boxes.length, 1);
      expect(boxes.first.width, 28);
      expect(boxes.first.height, 14);
      boxes = paragraph.getBoxesForRange(0, 19);
      expect(boxes.length, 1);
      expect(boxes.first.width, 56);
      expect(boxes.first.height, 28);
      boxes = paragraph.getBoxesForRange(8, 23);
      expect(boxes.length, 1);
      expect(boxes.first.width, 56);
      expect(boxes.first.height, 28);
      boxes = paragraph.getBoxesForRange(0, 23);
      expect(boxes.length, 1);
      expect(boxes.first.width, 56);
      expect(boxes.first.height, 42);

      // partial ranges only return complete parts
      boxes = paragraph.getBoxesForRange(0, 10);
      expect(boxes.length, 1);
      expect(boxes.first.width, 42);
      expect(boxes.first.height, 14);
      boxes = paragraph.getBoxesForRange(4, 22);
      expect(boxes.length, 1);
      expect(boxes.first.width, 56);
      expect(boxes.first.height, 14);
      expect(boxes.first.left, 0);
      expect(boxes.first.top, 14);
      expect(boxes.first.right, 56);
      expect(boxes.first.bottom, 28);
      boxes = paragraph.getBoxesForRange(15, 23);
      expect(boxes.length, 1);
      expect(boxes.first.width, 28);
      expect(boxes.first.height, 14);
      boxes = paragraph.getBoxesForRange(1, 32);
      expect(boxes.length, 1);
      expect(boxes.first.width, 56);
      expect(boxes.first.height, 28);
      expect(boxes.first.left, 0);
      expect(boxes.first.top, 14);
      expect(boxes.first.right, 56);
      expect(boxes.first.bottom, 42);
    });

    // test('Partial ranges return empty boxes', () {
    //   final text = '👨‍👩‍👦';
    //   final paragraphStyle = ui.ParagraphStyle(
    //     textDirection: ui.TextDirection.ltr,
    //   );
    //   final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
    //     ..addText(text);
    //   final constraints = ui.ParagraphConstraints(width: 300);
    //   final paragraph = paragraphBuilder.build();
    //   paragraph.layout(constraints);

    //   var boxes = paragraph.getBoxesForRange(0, 8);
    //   expect(boxes.length, 1);
    //   boxes = paragraph.getBoxesForRange(1, 8);
    //   expect(boxes.length, 0);
    //   boxes = paragraph.getBoxesForRange(2, 8);
    //   expect(boxes.length, 0);
    //   boxes = paragraph.getBoxesForRange(3, 8);
    //   expect(boxes.length, 0);
    //   boxes = paragraph.getBoxesForRange(4, 8);
    //   expect(boxes.length, 0);
    //   boxes = paragraph.getBoxesForRange(5, 8);
    //   expect(boxes.length, 0);
    //   boxes = paragraph.getBoxesForRange(6, 8);
    //   expect(boxes.length, 0);
    //   boxes = paragraph.getBoxesForRange(7, 8);
    //   print(boxes); // [TextBox.fromLTRBD(0.0, 0.0, 42.0, 14.0, TextDirection.ltr)]
    //   expect(boxes.length, 0); // fails: Actual: <1>
    // });
  });
}
