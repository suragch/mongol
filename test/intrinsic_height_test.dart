// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/src/base/mongol_text_painter.dart';

/// Twenty-three characters at fontSize 20 with the test font: 460 on one line.
const String text = 'aa bb cc dd ee ff gg hh';
const TextStyle style = TextStyle(fontSize: 20);

double intrinsicAt(double boxHeight, {int? maxLines}) {
  final painter = MongolTextPainter(
    text: const TextSpan(text: text, style: style),
    maxLines: maxLines,
  )..layout(maxHeight: boxHeight);
  return painter.maxIntrinsicHeight;
}

/// What the engine reports for the same text laid out horizontally. The
/// vertical value should agree with it, since both describe the text and not
/// the box it was put in.
double engineMaxIntrinsicWidth(String s, {int? maxLines}) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(fontSize: 20, maxLines: maxLines),
  )..addText(s);
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 100));
  return paragraph.maxIntrinsicWidth;
}

void main() {
  test('maxIntrinsicHeight does not move with the box it is laid out in', () {
    for (final double box in <double>[100, 200, 400, 600, 2000]) {
      expect(intrinsicAt(box), 460.0, reason: 'box $box');
    }
  });

  test('maxIntrinsicHeight does not move with maxLines', () {
    // The regression behind #53: this used to describe only the lines maxLines
    // kept, so it collapsed to the height of the box and the layout cache was
    // reused when a taller box would have fitted more text.
    for (final int? maxLines in <int?>[null, 1, 2, 3]) {
      expect(intrinsicAt(200, maxLines: maxLines), 460.0,
          reason: 'maxLines $maxLines');
    }
  });

  test('maxIntrinsicHeight agrees with the engine for the same text', () {
    expect(intrinsicAt(200), engineMaxIntrinsicWidth(text));
    expect(intrinsicAt(200, maxLines: 1),
        engineMaxIntrinsicWidth(text, maxLines: 1));
  });

  test('a hard newline bounds a segment rather than summing through it', () {
    const String twoSegments = 'aa bb\ncc dd ee';
    final painter = MongolTextPainter(
      text: const TextSpan(text: twoSegments, style: style),
    )..layout(maxHeight: 400);
    expect(painter.maxIntrinsicHeight, engineMaxIntrinsicWidth(twoSegments));
    expect(painter.maxIntrinsicHeight, 160.0);
  });
}
