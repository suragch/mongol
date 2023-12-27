// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/src/base/mongol_text_align.dart';
import 'package:mongol/src/base/mongol_text_painter.dart';

void main() {
  test('TextPainter returns correct offset for short one-line TextSpan', () {
    final painter = MongolTextPainter();

    var children = <TextSpan>[
      const TextSpan(text: 'B'),
      const TextSpan(text: 'C')
    ];
    painter.text = TextSpan(text: null, children: children);
    painter.layout();

    expect(painter.size, const Size(14.0, 28.0));

    // before the first character
    var offset = const Offset(-1.0, -1.0);
    var position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // offset zero
    offset = Offset.zero;
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on the first character, but closer to the start of the character
    offset = const Offset(5.0, 5.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on the first character, but closer to the end of the character
    offset = const Offset(5.0, 13.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // on the second character, but closer to the start of the character
    offset = const Offset(5.0, 15.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // on the second character, but closer to the end of the character
    offset = const Offset(5.0, 27.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 2);

    // to right of the line near vertical start
    offset = const Offset(100.0, 5.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // to right of the line close to index second char start
    offset = const Offset(100.0, 15.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // below the last character
    offset = const Offset(5.0, 30.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 2);

    // below and to the right of the last character
    offset = const Offset(100.0, 100.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 2);
  });

  test('TextPainter returns correct offset for hard-wrap multi-line TextSpan',
      () {
    final painter = MongolTextPainter();
    painter.text = const TextSpan(
      text: 'ABCDE FGHIJ\nKLMNO PQRST',
      style: TextStyle(fontSize: 30),
    );
    painter.layout();

    expect(painter.size, const Size(60.0, 330.0));

    // before the first character
    var offset = const Offset(-1.0, -1.0);
    var position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // offset zero
    offset = Offset.zero;
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on A closer to beginning of char
    offset = const Offset(10.0, 1.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);

    // on B closer to beginning of char
    offset = const Offset(10.0, 40.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);

    // on J closer to beginning of char
    offset = const Offset(10.0, 310.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 10);

    // on J closer to end of char
    offset = const Offset(10.0, 320.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 11);

    // on K closer to beginning of char
    offset = const Offset(40.0, 10.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 12);

    // on T closer to end of char
    offset = const Offset(40.0, 320.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 23);
  });

  test(
      'MongolTextPainter returns correct offset and affinity for soft-wrap multi-line TextSpan',
      () {
    final painter = MongolTextPainter()
      ..text = const TextSpan(
          text: 'ABCDE FGHIJ',
          style: TextStyle(
            height: 1.0,
            fontSize: 10.0,
            fontFamily: 'Ahem',
          ))
      ..layout(maxHeight: 80);

    expect(painter.size, const Size(20.0, 80.0));

    // before the first character
    var offset = const Offset(-1.0, -1.0);
    var position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);
    expect(position.affinity, TextAffinity.downstream);

    // offset zero
    offset = Offset.zero;
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);
    expect(position.affinity, TextAffinity.downstream);

    // on A closer to beginning of char
    offset = const Offset(2.0, 2.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 0);
    expect(position.affinity, TextAffinity.downstream);

    // on B closer to beginning of char
    offset = const Offset(2.0, 12.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);
    expect(position.affinity, TextAffinity.downstream);

    // left of B closer to beginning of char
    offset = const Offset(-2.0, 12.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 1);
    expect(position.affinity, TextAffinity.downstream);

    // on J closer to beginning of char
    offset = const Offset(12.0, 42.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 10);
    expect(position.affinity, TextAffinity.downstream);

    // on J closer to end of char
    offset = const Offset(12.0, 48.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 11);
    expect(position.affinity, TextAffinity.upstream);

    // on final space of first line closer to end of char
    offset = const Offset(2.0, 58.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 6);
    expect(position.affinity, TextAffinity.upstream);

    // below final space of first line
    offset = const Offset(2.0, 70.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 6);
    expect(position.affinity, TextAffinity.upstream);

    // left of and below final space of first line
    offset = const Offset(-10.0, 4500.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 6);
    expect(position.affinity, TextAffinity.upstream);

    // below J
    offset = const Offset(12.0, 500.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 11);
    expect(position.affinity, TextAffinity.upstream);

    // right of and below J
    offset = const Offset(500.0, 500.0);
    position = painter.getPositionForOffset(offset);
    expect(position.offset, 11);
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
      const ui.TextPosition(offset: -1),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, 0.0);

    caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 2),
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

  test(
    'MongolTextPainter intrinsic dimensions',
    () {
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
      //print(painter.size);
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
    },
  ); // https://github.com/flutter/flutter/issues/13512

  test('MongolTextPainter handles newlines properly', () {
    final painter = MongolTextPainter();

    const sizeOfA = 14.0; // square size of "a" character
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
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 3;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * offset, epsilon: 0.0001));
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
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));
    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 2, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 2, epsilon: 0.0001));

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
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));

    // When text wraps on its own, getOffsetForCaret disambiguates between the
    // end of one line and start of next using affinity.
    text = 'aaaaaaa a'; // Just enough to wrap one character over to second line
    painter.text = TextSpan(text: text);
    painter.layout(
        maxHeight: 100); // SIZE_OF_A * text.length > 100, so it wraps
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length - 1),
      ui.Rect.zero,
    );
    // When affinity is downstream, cursor is at beginning of second line
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(
          offset: text.length - 1, affinity: ui.TextAffinity.upstream),
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
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));
    offset = text.length;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));

    // Given a one-line right aligned string, positioning the cursor at offset 0
    // means that it appears at the "end" of the string, after the character
    // that was typed first, at x=0.
    painter.textAlign = MongolTextAlign.bottom;
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
    painter.textAlign = MongolTextAlign.top;

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
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));

    // When given a string with multiple trailing newlines, places the caret
    // in the position given by offset regardless of affinity.
    text = 'aaa\n\n\n';
    offset = 3;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * 3, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(sizeOfA * 3, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));

    offset = 4;
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));

    offset = 5;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 2, epsilon: 0.001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 2, epsilon: 0.0001));

    offset = 6;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 3, epsilon: 0.0001));

    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 3, epsilon: 0.0001));

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
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 3, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 3, epsilon: 0.0001));

    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 2, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA * 2, epsilon: 0.0001));

    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dx, moreOrLessEquals(sizeOfA, epsilon: 0.0001));

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

  test('getWordBoundary returns range even if offset greater than length', () {
    final painter = MongolTextPainter();
    // final painter = TextPainter();
    // painter.textDirection = TextDirection.ltr;
    var text = 'test for words';
    painter.text = TextSpan(text: text);
    painter.layout();

    var wordRange = painter.getWordBoundary(
        const TextPosition(offset: 14, affinity: TextAffinity.upstream));
    expect(wordRange, const TextRange(start: 14, end: 14));
    wordRange = painter.getWordBoundary(
        const TextPosition(offset: 14, affinity: TextAffinity.downstream));
    expect(wordRange, const TextRange(start: 14, end: 14));
    wordRange = painter.getWordBoundary(
        const TextPosition(offset: 20, affinity: TextAffinity.downstream));
    expect(wordRange, const TextRange(start: 14, end: 20));
  });

  // test('MongolTextPainter widget span', () {
  //   final painter = MongolTextPainter();

  //   const text = 'test';
  //   painter.text = const TextSpan(
  //     text: text,
  //     children: <InlineSpan>[
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       TextSpan(text: text),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       TextSpan(text: text),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //       WidgetSpan(child: SizedBox(width: 50, height: 30)),
  //     ],
  //   );

  //   // We provide dimensions for the widgets
  //   painter.setPlaceholderDimensions(const <PlaceholderDimensions>[
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(51, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //     PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
  //   ]);

  //   painter.layout(maxHeight: 500);

  //   // Now, each of the WidgetSpans will have their own placeholder 'hole'.
  //   var caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
  //   expect(caretOffset.dx, 14);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4), ui.Rect.zero);
  //   expect(caretOffset.dx, 56);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 5), ui.Rect.zero);
  //   expect(caretOffset.dx, 106);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 6), ui.Rect.zero);
  //   expect(caretOffset.dx, 120);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 10), ui.Rect.zero);
  //   expect(caretOffset.dx, 212);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 11), ui.Rect.zero);
  //   expect(caretOffset.dx, 262);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 12), ui.Rect.zero);
  //   expect(caretOffset.dx, 276);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 13), ui.Rect.zero);
  //   expect(caretOffset.dx, 290);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 14), ui.Rect.zero);
  //   expect(caretOffset.dx, 304);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 15), ui.Rect.zero);
  //   expect(caretOffset.dx, 318);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 16), ui.Rect.zero);
  //   expect(caretOffset.dx, 368);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 17), ui.Rect.zero);
  //   expect(caretOffset.dx, 418);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 18), ui.Rect.zero);
  //   expect(caretOffset.dx, 0);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 19), ui.Rect.zero);
  //   expect(caretOffset.dx, 50);
  //   caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 23), ui.Rect.zero);
  //   expect(caretOffset.dx, 250);

  //   expect(painter.inlinePlaceholderBoxes!.length, 14);
  //   expect(painter.inlinePlaceholderBoxes![0], const TextBox.fromLTRBD(56, 0, 106, 30, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![2], const TextBox.fromLTRBD(212, 0, 262, 30, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![3], const TextBox.fromLTRBD(318, 0, 368, 30, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![4], const TextBox.fromLTRBD(368, 0, 418, 30, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![5], const TextBox.fromLTRBD(418, 0, 468, 30, TextDirection.ltr));
  //   // line should break here
  //   expect(painter.inlinePlaceholderBoxes![6], const TextBox.fromLTRBD(0, 30, 50, 60, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![7], const TextBox.fromLTRBD(50, 30, 100, 60, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![10], const TextBox.fromLTRBD(200, 30, 250, 60, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![11], const TextBox.fromLTRBD(250, 30, 300, 60, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![12], const TextBox.fromLTRBD(300, 30, 351, 60, TextDirection.ltr));
  //   expect(painter.inlinePlaceholderBoxes![13], const TextBox.fromLTRBD(351, 30, 401, 60, TextDirection.ltr));
  // }, skip: isBrowser); // https://github.com/flutter/flutter/issues/42086

  // // Null values are valid. See https://github.com/flutter/flutter/pull/48346#issuecomment-584839221
  // test('MongolTextPainter set TextHeightBehavior null test', () {
  //   final painter = MongolTextPainter(textHeightBehavior: null);

  //   painter.textHeightBehavior = const TextHeightBehavior();
  //   painter.textHeightBehavior = null;
  // });

  // test('MongolTextPainter line metrics', () {
  //   final painter = MongolTextPainter();

  //   const text = 'test1\nhello line two really long for soft break\nfinal line 4';
  //   painter.text = const TextSpan(
  //     text: text,
  //   );

  //   painter.layout(maxHeight: 300);

  //   expect(painter.text, const TextSpan(text: text));
  //   expect(painter.preferredLineWidth, 14);

  //   final List<ui.LineMetrics> lines = painter.computeLineMetrics();

  //   expect(lines.length, 4);

  //   expect(lines[0].hardBreak, true);
  //   expect(lines[1].hardBreak, false);
  //   expect(lines[2].hardBreak, true);
  //   expect(lines[3].hardBreak, true);

  //   expect(lines[0].ascent, 11.199999809265137);
  //   expect(lines[1].ascent, 11.199999809265137);
  //   expect(lines[2].ascent, 11.199999809265137);
  //   expect(lines[3].ascent, 11.199999809265137);

  //   expect(lines[0].descent, 2.799999952316284);
  //   expect(lines[1].descent, 2.799999952316284);
  //   expect(lines[2].descent, 2.799999952316284);
  //   expect(lines[3].descent, 2.799999952316284);

  //   expect(lines[0].unscaledAscent, 11.199999809265137);
  //   expect(lines[1].unscaledAscent, 11.199999809265137);
  //   expect(lines[2].unscaledAscent, 11.199999809265137);
  //   expect(lines[3].unscaledAscent, 11.199999809265137);

  //   expect(lines[0].baseline, 11.200000047683716);
  //   expect(lines[1].baseline, 25.200000047683716);
  //   expect(lines[2].baseline, 39.200000047683716);
  //   expect(lines[3].baseline, 53.200000047683716);

  //   expect(lines[0].height, 14);
  //   expect(lines[1].height, 14);
  //   expect(lines[2].height, 14);
  //   expect(lines[3].height, 14);

  //   expect(lines[0].width, 70);
  //   expect(lines[1].width, 294);
  //   expect(lines[2].width, 266);
  //   expect(lines[3].width, 168);

  //   expect(lines[0].left, 0);
  //   expect(lines[1].left, 0);
  //   expect(lines[2].left, 0);
  //   expect(lines[3].left, 0);

  //   expect(lines[0].lineNumber, 0);
  //   expect(lines[1].lineNumber, 1);
  //   expect(lines[2].lineNumber, 2);
  //   expect(lines[3].lineNumber, 3);
  // }, skip: true); // https://github.com/flutter/flutter/issues/62819

  // test('MongolTextPainter caret height and line height', () {
  //   final painter = MongolTextPainter()
  //     ..strutStyle = const StrutStyle(fontSize: 50.0);

  //   const String text = 'A';
  //   painter.text = const TextSpan(text: text, style: TextStyle(height: 1.0));
  //   painter.layout();

  //   final double caretHeight = painter.getFullHeightForCaret(
  //     const ui.TextPosition(offset: 0),
  //     ui.Rect.zero,
  //   )!;
  //   expect(caretHeight, 50.0);
  // }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56308
}

class MockCanvas extends Fake implements Canvas {}
