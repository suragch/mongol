// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
}
