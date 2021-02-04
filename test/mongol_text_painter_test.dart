// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol_text_painter.dart';

// TODO: add these tests:
// https://github.com/flutter/flutter/blob/e3c441e0fdc299737abf0d763cad8bab71892bf7/packages/flutter/test/painting/text_painter_test.dart

void main() {
  test('TextPainter returns correct offset for short one-line TextSpan', () {
    final painter = MongolTextPainter();

    var children = <TextSpan>[
      const TextSpan(text: 'B'),
      const TextSpan(text: 'C')
    ];
    painter.text = TextSpan(text: null, children: children);
    painter.layout();

    expect(painter.size, Size(14.0, 28.0));

    // before the first character
    var offset = Offset(-1.0, -1.0);
    var position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // offset zero
    offset = Offset.zero;
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on the first character, but closer to the start of the character
    offset = Offset(5.0, 5.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on the first character, but closer to the end of the character
    offset = Offset(5.0, 13.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // on the second character, but closer to the start of the character
    offset = Offset(5.0, 15.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // on the second character, but closer to the end of the character
    offset = Offset(5.0, 27.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 2);

    // to right of the line near vertical start
    offset = Offset(100.0, 5.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // to right of the line close to index second char start
    offset = Offset(100.0, 15.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // below the last character
    offset = Offset(5.0, 30.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 2);

    // below and to the right of the last character
    offset = Offset(100.0, 100.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 2);
  });

  test('TextPainter returns correct offset for hard-wrap multi-line TextSpan',
      () {
    final painter = MongolTextPainter();
    painter.text = TextSpan(
      text: 'ABCDE FGHIJ\nKLMNO PQRST',
      style: TextStyle(fontSize: 30),
    );
    painter.layout();

    expect(painter.size, Size(60.0, 330.0));

    // before the first character
    var offset = Offset(-1.0, -1.0);
    var position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // offset zero
    offset = Offset.zero;
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on A closer to beginning of char
    offset = Offset(10.0, 1.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on B closer to beginning of char
    offset = Offset(10.0, 40.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // on J closer to beginning of char
    offset = Offset(10.0, 310.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 10);

    // on J closer to end of char
    offset = Offset(10.0, 320.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 11);

    // on K closer to beginning of char
    offset = Offset(40.0, 10.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 12);

    // on T closer to end of char
    offset = Offset(40.0, 320.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 23);
  });

  test(
      'TextPainter returns correct offset and affinity for soft-wrap multi-line TextSpan',
      () {
    final painter = MongolTextPainter();
    painter.text = TextSpan(
      text: 'ABCDE FGHIJ KLMNO PQRST',
      style: TextStyle(fontSize: 30),
    );
    painter.layout(maxHeight: 400);

    expect(painter.size, Size(60.0, 360.0));

    // before the first character
    var offset = Offset(-1.0, -1.0);
    var position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);
    expect(position.affinity, TextAffinity.upstream);

    // offset zero
    offset = Offset.zero;
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);
    expect(position.affinity, TextAffinity.upstream);

    // on A closer to beginning of char
    offset = Offset(10.0, 1.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);
    expect(position.affinity, TextAffinity.upstream);

    // on B closer to beginning of char
    offset = Offset(10.0, 40.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);
    expect(position.affinity, TextAffinity.upstream);

    // left of B closer to beginning of char
    offset = Offset(-10.0, 40.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);
    expect(position.affinity, TextAffinity.upstream);

    // on J closer to beginning of char
    offset = Offset(10.0, 310.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 10);
    expect(position.affinity, TextAffinity.upstream);

    // on J closer to end of char
    offset = Offset(10.0, 320.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 11);
    expect(position.affinity, TextAffinity.upstream);

    // on final space of first line closer to end of char
    offset = Offset(10.0, 350.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 12);
    expect(position.affinity, TextAffinity.upstream);

    // below final space of first line
    offset = Offset(10.0, 450.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 12);
    expect(position.affinity, TextAffinity.upstream);

    // left of and below final space of first line
    offset = Offset(-10.0, 450.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 12);
    expect(position.affinity, TextAffinity.upstream);

    // on K closer to beginning of char
    offset = Offset(40.0, 10.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 12);
    expect(position.affinity, TextAffinity.downstream);

    // to right and above K closer to beginning of char
    offset = Offset(100.0, -10.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 12);
    expect(position.affinity, TextAffinity.downstream);

    // on T closer to end of char
    offset = Offset(40.0, 320.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 23);
    expect(position.affinity, TextAffinity.upstream);

    // below T
    offset = Offset(40.0, 500.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 23);
    expect(position.affinity, TextAffinity.upstream);

    // right of T closer to beginning of char
    offset = Offset(140.0, 310.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 22);
    expect(position.affinity, TextAffinity.upstream);

    // right of and below T
    offset = Offset(500.0, 500.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 23);
    expect(position.affinity, TextAffinity.upstream);
  });

  // Tests from
  // https://github.com/flutter/flutter/blob/e3c441e0fdc299737abf0d763cad8bab71892bf7/packages/flutter/test/painting/text_painter_test.dart

  test('MongolTextPainter caret test', () {
    final painter = MongolTextPainter();

    var text = 'A';
    painter.text = TextSpan(text: text);
    painter.layout();

    var caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 0),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 0.0);

    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: -1),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 0.0);

    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: 2),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 0.0);

    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, painter.height);

    // Check that getOffsetForCaret handles a character that is encoded as a
    // surrogate pair.
    text = 'A\u{1F600}';
    painter.text = TextSpan(text: text);
    painter.layout();

    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, painter.height);
  });

  test('MongolTextPainter multiple characters single word', () {
    final painter = MongolTextPainter();

    var children = <TextSpan>[
      const TextSpan(text: 'B'),
      const TextSpan(text: 'C'),
    ];
    painter.text = TextSpan(text: null, children: children);
    painter.layout();

    var caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 0),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 0);
    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 1),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, painter.height / 2);
    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 2),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, painter.height);
  });

  test('MongolTextPainter multiple words single line', () {
    final painter = MongolTextPainter();

    var children = <TextSpan>[
      const TextSpan(text: 'BBB'),
      const TextSpan(text: ' '),
      const TextSpan(text: 'CCC'),
    ];
    painter.text = TextSpan(text: null, children: children);
    painter.layout();

    // caret at start
    var caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 0),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 0);

    // caret in middle of first word
    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 1),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 14.0);

    // caret in middle of second word
    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 5),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 70);

    // caret at end
    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 7),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, painter.height);
  });

  test('MongolTextPainter null text test', () {
    final painter = MongolTextPainter();

    var children = <TextSpan>[
      const TextSpan(text: 'B'),
      const TextSpan(text: 'C'),
    ];
    painter.text = TextSpan(text: null, children: children);
    painter.layout();

    var caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 0),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 0);
    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 1),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, painter.height / 2);
    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 2),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, painter.height);

    children = <TextSpan>[];
    painter.text = TextSpan(text: null, children: children);
    painter.layout();

    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dy, 0);
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dy, 0);
  });

  test('MongolTextPainter caret emoji test', () {
    final painter = MongolTextPainter();

    // Format: '👨‍<zwj>👩‍<zwj>👦👨‍<zwj>👩‍<zwj>👧‍<zwj>👧👏<modifier>'
    // One three-person family, one four-person family, one clapping hands (medium skin tone).
    const text = '👨‍👩‍👦👨‍👩‍👧‍👧👏🏽';
    painter.text = const TextSpan(text: text);
    painter.layout(maxHeight: 10000);

    expect(text.length, 23);

    var caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dy, 0); // 👨
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dy, 42);
    expect(painter.height, 42);

    // Two UTF-16 codepoints per emoji, one codepoint per zwj
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👨
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 2), ui.Rect.zero);
    expect(caretOffset.dy, 14); // <zwj>
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 3), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👩‍
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 4), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👩‍
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 5), ui.Rect.zero);
    expect(caretOffset.dy, 14); // <zwj>
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 6), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👦
    // https://github.com/flutter/flutter/issues/75051
    //caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 7), ui.Rect.zero);
    //expect(caretOffset.dy, 14); // 👦
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 8), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👨
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 9), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👨
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 10), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <zwj>
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 11), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👩‍
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 12), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👩‍
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 13), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <zwj>
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 14), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👧‍
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 15), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👧‍
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 16), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <zwj>
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 17), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👧
    // https://github.com/flutter/flutter/issues/75051
    // caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 18), ui.Rect.zero);
    // expect(caretOffset.dy, 28); // 👧
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 19), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👏
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 20), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👏
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 21), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <medium skin tone modifier>
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 22), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <medium skin tone modifier>
    caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(offset: 23), ui.Rect.zero);
    expect(caretOffset.dy, 42); // end of string
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56308

  test('TextPainter error test', () {
    final painter = MongolTextPainter();
    expect(() {
      painter.paint(MockCanvas(), Offset.zero);
    }, anyOf(throwsFlutterError, throwsAssertionError));
  });

  test('MongolTextPainter size test', () {
    final painter = MongolTextPainter(
      text: const TextSpan(
        text: 'X',
        style: TextStyle(
          inherit: false,
          fontFamily: 'Ahem',
          fontSize: 123.0,
        ),
      ),
    );
    painter.layout();
    expect(painter.size, const Size(123.0, 123.0));
  });

  test('MongolTextPainter textScaleFactor test', () {
    final painter = MongolTextPainter(
      text: const TextSpan(
        text: 'X',
        style: TextStyle(
          inherit: false,
          fontFamily: 'Ahem',
          fontSize: 10.0,
        ),
      ),
      textScaleFactor: 2.0,
    );
    painter.layout();
    expect(painter.size, const Size(20.0, 20.0));
  });

  test('MongolTextPainter textScaleFactor null style test', () {
    final painter = MongolTextPainter(
      text: const TextSpan(
        text: 'X',
      ),
      textScaleFactor: 2.0,
    );
    painter.layout();
    expect(painter.size, const Size(28.0, 28.0));
  });

  test('MongolTextPainter default text width is 14 pixels', () {
    final painter = MongolTextPainter(
      text: const TextSpan(text: 'x'),
    );
    painter.layout();
    expect(painter.preferredLineWidth, 14.0);
    expect(painter.size, const Size(14.0, 14.0));
  });

  test('MongolTextPainter sets paragraph size from root', () {
    final painter = MongolTextPainter(
      text: const TextSpan(text: 'x', style: TextStyle(fontSize: 100.0)),
    );
    painter.layout();
    expect(painter.preferredLineWidth, 100.0);
    expect(painter.size, const Size(100.0, 100.0));
  });

  test('MongolTextPainter intrinsic dimensions', () {
    const style = TextStyle(
      inherit: false,
      fontFamily: 'Ahem',
      fontSize: 10.0,
    );
    MongolTextPainter painter;

    painter = MongolTextPainter(
      text: const TextSpan(
        text: 'X X X',
        style: style,
      ),
    );
    painter.layout();
    print(painter.size);
    expect(painter.size, const Size(10.0, 50.0));
    // skip: currently minIntrinsicHeight is counting the space so returns 20.0
    // expect(painter.minIntrinsicHeight, 10.0);
    expect(painter.maxIntrinsicHeight, 50.0);

    // painter = MongolTextPainter(
    //   text: const TextSpan(
    //     text: 'X X X',
    //     style: style,
    //   ),
    //   ellipsis: 'e',
    // );
    // painter.layout();
    // expect(painter.size, const Size(50.0, 10.0));
    // expect(painter.minIntrinsicHeight, 50.0);
    // expect(painter.maxIntrinsicHeight, 50.0);

    // painter = MongolTextPainter(
    //   text: const TextSpan(
    //     text: 'X X XXXX',
    //     style: style,
    //   ),
    //   maxLines: 2,
    // );
    // painter.layout();
    // expect(painter.size, const Size(80.0, 10.0));
    // expect(painter.minIntrinsicHeight, 40.0);
    // expect(painter.maxIntrinsicHeight, 80.0);

    // painter = MongolTextPainter(
    //   text: const TextSpan(
    //     text: 'X X XXXX XX',
    //     style: style,
    //   ),
    //   maxLines: 2,
    // );
    // painter.layout();
    // expect(painter.size, const Size(110.0, 10.0));
    // expect(painter.minIntrinsicHeight, 70.0);
    // expect(painter.maxIntrinsicHeight, 110.0);

    // painter = MongolTextPainter(
    //   text: const TextSpan(
    //     text: 'XXXXXXXX XXXX XX X',
    //     style: style,
    //   ),
    //   maxLines: 2,
    // );
    // painter.layout();
    // expect(painter.size, const Size(180.0, 10.0));
    // expect(painter.minIntrinsicHeight, 90.0);
    // expect(painter.maxIntrinsicHeight, 180.0);

    // painter = MongolTextPainter(
    //   text: const TextSpan(
    //     text: 'X XX XXXX XXXXXXXX',
    //     style: style,
    //   ),
    //   maxLines: 2,
    // );
    // painter.layout();
    // expect(painter.size, const Size(180.0, 10.0));
    // expect(painter.minIntrinsicHeight, 90.0);
    // expect(painter.maxIntrinsicHeight, 180.0);
  },); // https://github.com/flutter/flutter/issues/13512

  test('MongolTextPainter handles newlines properly', () {
    final painter = MongolTextPainter();

    const SIZE_OF_A = 14.0; // square size of "a" character
    var text = 'aaa';
    painter.text = TextSpan(text: text);
    painter.layout();

    // getOffsetForCaret in a plain one-line string is the same for either affinity.
    var offset = 0;
    painter.text = TextSpan(text: text);
    painter.layout();
    var caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 3;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));

    // For explicit newlines, getOffsetForCaret places the caret at the location
    // indicated by offset regardless of affinity.
    text = '\n\n';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));

    // getOffsetForCaret in an unwrapped string with explicit newlines is the
    // same for either affinity.
    text = '\naaa';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    // When text wraps on its own, getOffsetForCaret disambiguates between the
    // end of one line and start of next using affinity.
    text = 'aaaaaaa a'; // Just enough to wrap one character over to second line
    painter.text = TextSpan(text: text);
    painter.layout(maxHeight: 100); // SIZE_OF_A * text.length > 100, so it wraps
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length - 1),
      ui.Rect.zero,
    );
    // When affinity is downstream, cursor is at beginning of second line
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length - 1, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    // When affinity is upstream, cursor is at end of first line
    expect(caretOffset.dy, moreOrLessEquals(100.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));

    // The following test currently fails because MongolParagraph can't
    // find line break locations smaller than a normal text run. That is,
    // it can't unnatually break a long string without spaces.

    // // When text wraps on its own, getOffsetForCaret disambiguates between the
    // // end of one line and start of next using affinity.
    // text = 'aaaaaaaa'; // Just enough to wrap one character over to second line
    // painter.text = TextSpan(text: text);
    // painter.layout(maxHeight: 100); // SIZE_OF_A * text.length > 100, so it wraps
    // caretOffset = painter.getOffsetForCaret(
    //   ui.TextPosition(offset: text.length - 1),
    //   ui.Rect.zero,
    // );
    // // When affinity is downstream, cursor is at beginning of second line
    // expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    // expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    // caretOffset = painter.getOffsetForCaret(
    //   ui.TextPosition(offset: text.length - 1, affinity: ui.TextAffinity.upstream),
    //   ui.Rect.zero,
    // );
    // // When affinity is upstream, cursor is at end of first line
    // expect(caretOffset.dy, moreOrLessEquals(98.0, epsilon: 0.0001));
    // expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));

    // When given a string with a newline at the end, getOffsetForCaret puts
    // the cursor at the start of the next line regardless of affinity
    text = 'aaa\n';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    offset = text.length;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    // Given a one-line right aligned string, positioning the cursor at offset 0
    // means that it appears at the "end" of the string, after the character
    // that was typed first, at x=0.
    painter.textAlign = TextAlign.right;
    text = 'aaa';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    painter.textAlign = TextAlign.left;

    // When given an offset after a newline in the middle of a string,
    // getOffsetForCaret returns the start of the next line regardless of
    // affinity.
    text = 'aaa\naaa';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 4;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    // When given a string with multiple trailing newlines, places the caret
    // in the position given by offset regardless of affinity.
    text = 'aaa\n\n\n';
    offset = 3;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));

    offset = 4;
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    offset = 5;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));

    offset = 6;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));

    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));

    // When given a string with multiple leading newlines, places the caret in
    // the position given by offset regardless of affinity.
    text = '\n\n\naaa';
    offset = 3;
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));

    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));

    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx,moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
  });

  
}

class MockCanvas extends Fake implements Canvas {}
