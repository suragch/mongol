import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/src/base/mongol_paragraph.dart';
import 'package:mongol/src/base/mongol_text_align.dart';

// ignore_for_file: todo

void main() {
  MongolParagraph getParagraph(
    String text,
    double height, {
    MongolTextAlign? textAlign,
    int? maxLines,
    String? ellipsis,
  }) {
    final paragraphStyle = ui.ParagraphStyle(ellipsis: ellipsis);
    final paragraphBuilder = MongolParagraphBuilder(
      paragraphStyle,
      textAlign: textAlign ?? MongolTextAlign.top,
      maxLines: maxLines,
      ellipsis: ellipsis,
    );
    paragraphBuilder.addText(text);
    final constraints = MongolParagraphConstraints(height: height);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(constraints);
    return paragraph;
  }

  // This group is for testing [getBoxesForRange].
  //
  // You can compare the behavior to [Paragraph] with the following code:
  //
  // ```
  // const text = 'ABC DEF 123 456\n' //   0-16
  //     'ABC DEF 123 456\n' //  16-32
  //     'ABC DEF 123 456\n' //  32-48
  //     'ABC DEF 123 456\n' //  48-64
  //     'ABC DEF 123 456\n'; // 64-80
  // final paragraphStyle = ui.ParagraphStyle(
  //   textDirection: ui.TextDirection.ltr,
  // );
  // final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
  //   ..addText(text);
  // final constraints = ui.ParagraphConstraints(width: 300);
  // final paragraph = paragraphBuilder.build();
  // paragraph.layout(constraints);
  // final boxes = paragraph.getBoxesForRange(21, 58);
  // print(boxes);
  // ```
  group('getBoxesForRange', () {
    test('single character gives correct ranges', () {
      final paragraph = getParagraph('A', 300);

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

      // range that includes text but also goes beyond returns included text
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
      final paragraph = getParagraph('ABC', 300);

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
      final paragraph = getParagraph('ABC 123', 300);

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
      final paragraph = getParagraph(multipleLines, 300);

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
      final paragraph = getParagraph(graphemeClusters, 300);
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

    test('handles newlines well', () {
      const text = '\n';
      final paragraph = getParagraph(text, 300);

      var boxes = paragraph.getBoxesForRange(0, 1);
      expect(boxes.length, 1);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 0.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 0.0);

      boxes = paragraph.getBoxesForRange(1, 2);
      expect(boxes.length, 1);
      expect(boxes.first.left, 14.0);
      expect(boxes.first.top, 0.0);
      expect(boxes.first.right, 28.0);
      expect(boxes.first.bottom, 0.0);

      boxes = paragraph.getBoxesForRange(0, 8);
      expect(boxes.length, 2);
      expect(boxes.first.left, 0.0);
      expect(boxes.first.top, 0.0);
      expect(boxes.first.right, 14.0);
      expect(boxes.first.bottom, 0.0);
      expect(boxes.last.left, 14.0);
      expect(boxes.last.top, 0.0);
      expect(boxes.last.right, 28.0);
      expect(boxes.last.bottom, 0.0);
    });
  });

  group('getPositionForOffset -', () {
    test('control test', () {
      const text = 'I polished up that handle so carefullee\n'
          "That now I am the Ruler of the Queen's Navee!";

      final paragraph = getParagraph(text, 1000);

      final position20 =
          paragraph.getPositionForOffset(const Offset(5.0, 20.0));
      expect(position20.offset, greaterThan(0.0));

      final position40 =
          paragraph.getPositionForOffset(const Offset(5.0, 40.0));
      expect(position40.offset, greaterThan(position20.offset));

      final positionRight =
          paragraph.getPositionForOffset(const Offset(20.0, 5.0));
      expect(positionRight.offset, greaterThan(position40.offset));
    });

    test('empty content does not crash', () {
      const text = '';
      final paragraph = getParagraph(text, 1000);
      final position = paragraph.getPositionForOffset(const Offset(400, 300));
      expect(position,
          const TextPosition(offset: 0, affinity: ui.TextAffinity.downstream));
    });

    test('ending with new line does not crash', () {
      const text = 'hello\n';
      final paragraph = getParagraph(text, 1000);
      final position = paragraph.getPositionForOffset(const Offset(400, 300));
      expect(position,
          const TextPosition(offset: 5, affinity: ui.TextAffinity.downstream));
    });
  });

  group('miscellaneous methods -', () {
    test('getWordBoundary control test', () {
      const text = 'I polished up that handle so carefullee\n'
          "That now I am the Ruler of the Queen's Navee!";

      final paragraph = getParagraph(text, 1000);

      final range5 = paragraph.getWordBoundary(const TextPosition(offset: 5));
      expect(range5.textInside(text), equals('polished'));

      final range50 = paragraph.getWordBoundary(const TextPosition(offset: 50));
      expect(range50.textInside(text), equals(' '));

      final range75 = paragraph.getWordBoundary(const TextPosition(offset: 75));
      expect(range75.textInside(text), equals("Queen's"));

      // TODO: this maybe isn't good. It should be '!'.
      final range84 = paragraph.getWordBoundary(const TextPosition(offset: 84));
      expect(range84.textInside(text), equals('Navee!'));

      final range85 = paragraph.getWordBoundary(const TextPosition(offset: 85));
      expect(range85, const TextRange(start: 85, end: 85));

      // https://github.com/flutter/flutter/issues/75494
      final range1000 =
          paragraph.getWordBoundary(const TextPosition(offset: 1000));
      expect(range1000, const TextRange(start: 85, end: 1000));
    });

    test('getLineBoundary control test', () {
      const text = 'I polished up that handle so carefullee\n'
          "That now I am the Ruler of the Queen's Navee!";

      final paragraph = getParagraph(text, 1000);

      final range5 = paragraph.getLineBoundary(const TextPosition(offset: 5));
      expect(
        range5.textInside(text),
        equals('I polished up that handle so carefullee'),
      );

      final range40 = paragraph.getLineBoundary(const TextPosition(offset: 40));
      expect(
        range40.textInside(text),
        equals("That now I am the Ruler of the Queen's Navee!"),
      );

      final range85 = paragraph.getLineBoundary(const TextPosition(offset: 75));
      expect(
        range85.textInside(text),
        equals("That now I am the Ruler of the Queen's Navee!"),
      );

      final rangeLength =
          paragraph.getLineBoundary(const TextPosition(offset: text.length));
      expect(
        rangeLength.textInside(text),
        equals("That now I am the Ruler of the Queen's Navee!"),
      );

      final range1000 =
          paragraph.getLineBoundary(const TextPosition(offset: 1000));
      expect(range1000, TextRange.empty);
    });

    test('getLineBoundary does not include newline', () {
      // test for https://github.com/flutter/flutter/issues/83392
      const text = 'aaa\nbbb';

      final paragraph = getParagraph(text, 1000);

      var range = paragraph.getLineBoundary(const TextPosition(offset: 0));
      expect(
        range.textInside(text),
        equals('aaa'),
      );
      expect(range.start, 0);
      expect(range.end, 3);

      range = paragraph.getLineBoundary(const TextPosition(offset: 5));
      expect(
        range.textInside(text),
        equals('bbb'),
      );
      expect(range.start, 4);
      expect(range.end, 7);
    });

// https://github.com/flutter/flutter/issues/83392
// test('getLineBoundary includes newline characters', () {
//   const text = 'aaa\nbbb';

//   final paragraphStyle = ui.ParagraphStyle(
//     textDirection: ui.TextDirection.ltr,
//   );
//   final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
//     ..addText(text);
//   final constraints = ui.ParagraphConstraints(width: 1000);
//   final paragraph = paragraphBuilder.build();
//   paragraph.layout(constraints);

//   var range = paragraph.getLineBoundary(const TextPosition(offset: 0));
//   expect(
//     range.textInside(text),
//     equals('aaa\n'),
//   );
//   expect(range.start, 0);
//   expect(range.end, 4);

//   range = paragraph.getLineBoundary(const TextPosition(offset: 5));
//   expect(
//     range.textInside(text),
//     equals('bbb'),
//   );
//   expect(range.start, 4);
//   expect(range.end, 7);
// });
  });

  group('maxlines -', () {
    test('Paragraph handles maxlines', () {
      const text = 'this is some long text that should break over 3 lines';

      // multiline
      var paragraph = getParagraph(text, 300, maxLines: null);
      var exceededMaxLines = paragraph.didExceedMaxLines;
      expect(exceededMaxLines, false);
      var width = paragraph.width;
      expect(width, 42);

      // single line
      paragraph = getParagraph(text, 300, maxLines: 1);
      exceededMaxLines = paragraph.didExceedMaxLines;
      expect(exceededMaxLines, true);
      width = paragraph.width;
      expect(width, 14);

      // two lines
      paragraph = getParagraph(text, 300, maxLines: 2);
      exceededMaxLines = paragraph.didExceedMaxLines;
      expect(exceededMaxLines, true);
      width = paragraph.width;
      expect(width, 28);

      // three lines
      paragraph = getParagraph(text, 300, maxLines: 3);
      exceededMaxLines = paragraph.didExceedMaxLines;
      expect(exceededMaxLines, false);
      width = paragraph.width;
      expect(width, 42);
    });

    // // temporarily deleting this test. The ellipsis currently doesn't
    // // affect the intrinsic size.
    // test('last run has ellipsis when exceeding max lines', () {
    //   const text = 'this is some long text that should break over 3 lines';

    //   // line without ellipsis
    //   var paragraph = _getParagraph(text, 300, maxLines: 1);
    //   final lineHeightWithoutEllipsis = 252;
    //   expect(paragraph.maxIntrinsicHeight, lineHeightWithoutEllipsis);

    //   // size of ellipsis
    //   const ellipsis = '\u2026';
    //   final ellipsisParagraph = _getParagraph(ellipsis, 300);
    //   final ellipsisHeight = ellipsisParagraph.maxIntrinsicHeight;
    //   expect(ellipsisHeight, 14);

    //   // line that has room for ellipsis before overflowing
    //   paragraph = _getParagraph(text, 300, maxLines: 1, ellipsis: ellipsis);
    //   expect(
    //     paragraph.maxIntrinsicHeight,
    //     lineHeightWithoutEllipsis + ellipsisHeight,
    //   );
    // });
  });

  /// Keep this for testing Paragraph
  ///
  // test('Empty paragraph', () {
  //   const offset = 12;
  //   final paragraphStyle = ParagraphStyle(
  //     textDirection: TextDirection.ltr,
  //     maxLines: -1,
  //   );
  //   final text = 'asdf';
  //   final paragraphBuilder = ParagraphBuilder(paragraphStyle)..addText(text);
  //   final constraints = ParagraphConstraints(width: 300);
  //   final paragraph = paragraphBuilder.build();
  //   paragraph.layout(constraints);
  //   final asdf = paragraph.didExceedMaxLines;
  //   expect(asdf, true);
  //   // final range = paragraph.getLineBoundary(TextPosition(offset: offset));
  //   // final position = paragraph.getPositionForOffset(Offset(400, 300));
  //   // expect(position, TextPosition(offset: 0, affinity: ui.TextAffinity.downstream));
  // });
}
