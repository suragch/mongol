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

  test('TextPainter multiple characters single word', () {
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

  test('TextPainter multiple words single line', () {
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

  test('TextPainter null text test', () {
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

  test('TextPainter caret emoji test', () {
    final painter = MongolTextPainter();

    // Format: '👨‍<zwj>👩‍<zwj>👦👨‍<zwj>👩‍<zwj>👧‍<zwj>👧👏<modifier>'
    // One three-person family, one four-person family, one clapping hands (medium skin tone).
    const text = '👨‍👩‍👦👨‍👩‍👧‍👧👏🏽';
    painter.text = const TextSpan(text: text);
    painter.layout(maxHeight: 10000);

    expect(text.length, 23);

    var caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dy, 0); // 👨
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dy, 42);
    expect(painter.height, 42);

    // Two UTF-16 codepoints per emoji, one codepoint per zwj
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👨
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 2), ui.Rect.zero);
    expect(caretOffset.dy, 14); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 3), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 5), ui.Rect.zero);
    expect(caretOffset.dy, 14); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 6), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👦
    // https://github.com/flutter/flutter/issues/75051
    //caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 7), ui.Rect.zero);
    //expect(caretOffset.dy, 14); // 👦
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 8), ui.Rect.zero);
    expect(caretOffset.dy, 14); // 👨
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 9), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👨
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 10), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 11), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 12), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 13), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 14), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👧‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 15), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👧‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 16), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 17), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👧
    // https://github.com/flutter/flutter/issues/75051
    // caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 18), ui.Rect.zero);
    // expect(caretOffset.dy, 28); // 👧
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 19), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👏
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 20), ui.Rect.zero);
    expect(caretOffset.dy, 28); // 👏
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 21), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <medium skin tone modifier>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 22), ui.Rect.zero);
    expect(caretOffset.dy, 28); // <medium skin tone modifier>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 23), ui.Rect.zero);
    expect(caretOffset.dy, 42); // end of string
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56308
}
