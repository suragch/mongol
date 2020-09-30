// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

class MongolParagraph {
  /// To create a [MongolParagraph] object, use a [MongolParagraphBuilder].
  MongolParagraph._(this._runs, this._text);
  String _text;
  List<TextRun> _runs;

  double _width;
  double _height;
  double _minIntrinsicHeight;
  double _maxIntrinsicHeight;

  double get width => _width;

  double get height => _height;

  double get minIntrinsicHeight => _minIntrinsicHeight;

  double get maxIntrinsicHeight => _maxIntrinsicHeight;

  void layout(MongolParagraphConstraints constraints) =>
      _layout(constraints.height);

  void _layout(double height) {
    if (height == _height) return;
    _calculateLineBreaks(height);
    _calculateWidth();
    _height = height;
    _calculateIntrinsicHeight();
  }

  List<LineInfo> _lines = [];

  // Internally this method uses "width" and "height" naming with regard
  // to a horizontal line of text. Rotation doesn't happen until drawing.
  void _calculateLineBreaks(double maxLineLength) {
    assert(_runs != null);
    if (_runs.isEmpty) {
      return;
    }
    if (_lines.isNotEmpty) {
      _lines.clear();
    }

    // add run lengths until exceeds length
    int start = 0;
    int end = 0;
    double lineWidth = 0;
    double lineHeight = 0;
    for (int i = 0; i < _runs.length; i++) {
      end = i;
      final run = _runs[i];
      final runWidth = run.paragraph.maxIntrinsicWidth;
      final runHeight = run.paragraph.height;

      
      if (lineWidth + runWidth > maxLineLength) {
        _addLine(start, end, lineWidth, lineHeight);
        lineWidth = runWidth;
        lineHeight = runHeight;
        start = end;
      } else {
        lineWidth += runWidth;
        lineHeight = math.max(lineHeight, run.paragraph.height);
      }

      if (_runEndsWithNewLine(run)) {
        end = i + 1;
        _addLine(start, end, lineWidth, lineHeight);
        lineWidth = 0;
        lineHeight = 0;
        start = end;
      } 
    }

    end = _runs.length;
    if (start < end) {
      _addLine(start, end, lineWidth, lineHeight);
    }
  }

  bool _runEndsWithNewLine(TextRun run) {
    final index = run.end - 1;
    return _text[index] == '\n';
  }

  void _addLine(int start, int end, double width, double height) {
    final bounds = Rect.fromLTRB(0, 0, width, height);
    final LineInfo lineInfo = LineInfo(start, end, bounds);
    _lines.add(lineInfo);
  }

  void _calculateWidth() {
    assert(_lines != null);
    assert(_runs != null);
    double sum = 0;
    for (LineInfo line in _lines) {
      sum += line.bounds.height;
    }
    _width = sum;
  }

  // Internally this translates a horizontal run width to the vertical name
  // that it is known as externally.
  void _calculateIntrinsicHeight() {
    assert(_runs != null);

    double sum = 0;
    double maxRunWidth = 0;
    double maxLineLength = 0;
    for (LineInfo line in _lines) {
      for (int i = line.textRunStart; i < line.textRunEnd; i++) {
        final width = _runs[i].paragraph.maxIntrinsicWidth;
        maxRunWidth = math.max(width, maxRunWidth);
        sum += width;
      }
      maxLineLength = math.max(maxLineLength, sum);
      sum = 0;
    }
    _minIntrinsicHeight = maxRunWidth;
    _maxIntrinsicHeight = maxLineLength;
  }

  void draw(Canvas canvas, Offset offset) {
    assert(_lines != null);
    assert(_runs != null);

    // translate for the offset
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // rotate the canvas 90 degrees
    canvas.rotate(math.pi / 2);

    // loop through every line
    for (LineInfo line in _lines) {
      // translate for the line height
      canvas.translate(0, -line.bounds.height);

      // draw each run in the current line
      double dx = 0;
      for (int i = line.textRunStart; i < line.textRunEnd; i++) {
        canvas.drawParagraph(_runs[i].paragraph, Offset(dx, 0));
        dx += _runs[i].paragraph.longestLine;
      }
    }

    canvas.restore();
  }
}

class MongolParagraphConstraints {
  const MongolParagraphConstraints({
    this.height,
  }) : assert(height != null);

  final double height;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final MongolParagraphConstraints typedOther = other;
    return typedOther.height == height;
  }

  @override
  int get hashCode => height.hashCode;

  @override
  String toString() => '$runtimeType(height: $height)';
}

class MongolParagraphBuilder {
  MongolParagraphBuilder(ui.ParagraphStyle style) : _paragraphStyle = style;

  ui.ParagraphStyle _paragraphStyle;
  final _styleStack = Stack<TextStyle>();
  final _rawStyledTextRuns = <_RawStyledTextRun>[];

  static final _defaultParagraphStyle = ui.ParagraphStyle(
    textAlign: TextAlign.start,
    textDirection: TextDirection.ltr,
    fontSize: 30,
  );

  static final _defaultTextStyle = ui.TextStyle(
    color: Color(0xFF000000),
    textBaseline: TextBaseline.alphabetic,
    fontSize: 30,
  );

  void pushStyle(TextStyle style) {
    if (_styleStack.isEmpty) {
      _styleStack.push(style);
      return;
    }
    final lastStyle = _styleStack.top;
    _styleStack.push(lastStyle.merge(style));
  }

  void pop() {
    _styleStack.pop();
  }

  final _unstyledText = StringBuffer();

  void addText(String text) {
    _unstyledText.write(text);
    final style = _styleStack.top;
    final breakSegments = BreakSegments(text);
    for (final segment in breakSegments) {
      _rawStyledTextRuns.add(_RawStyledTextRun(style, segment));
    }
  }

  bool _startsWithBreak(String run) {
    return run.startsWith(LineBreaker.breakChar);
  }

  bool _endsWithBreak(String run) {
    if (run.isEmpty) return false;
    return (run[run.length - 1].contains(LineBreaker.breakChar));
  }

  MongolParagraph build() {
    _paragraphStyle ??= _defaultParagraphStyle;
    final runs = <TextRun>[];

    final length = _rawStyledTextRuns.length;
    var startIndex = 0;
    var endIndex = 0;
    ui.ParagraphBuilder _builder;
    for (var i = 0; i < length; i++) {
      
      final style = _uiStyleForRun(i);
      final text = _rawStyledTextRuns[i].text;
      endIndex += text.length;
      _builder ??= ui.ParagraphBuilder(_paragraphStyle);
      _builder.pushStyle(style);
      _builder.addText(_stripNewLineChar(text));
      _builder.pop();

      if (i < length - 1) {
        final nextText = _rawStyledTextRuns[i + 1].text;
        if (!_endsWithBreak(text) && !_startsWithBreak(nextText)) {
          continue;
        }
      }
      
      final paragraph = _builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: double.infinity));
      final run = TextRun(startIndex, endIndex, paragraph);
      runs.add(run);
      _builder = null;
      startIndex = endIndex;
    }

    return MongolParagraph._(runs, _unstyledText.toString());
  }

  ui.TextStyle _uiStyleForRun(int index) {
    final style = _rawStyledTextRuns[index].style;
    return style?.getTextStyle() ?? _defaultTextStyle;
  }

  String _stripNewLineChar(String text) {
    if (!text.endsWith('\n')) return text;
    return text.replaceAll('\n', '');

  }
}

class BreakSegments extends Iterable<String> {
  BreakSegments(this.text);
  final String text;

  @override
  Iterator<String> get iterator => LineBreaker(text);
}

class LineBreaker implements Iterator<String> {
  LineBreaker(this.text);
  final String text;

  String _currentTextRun;
  int _startIndex = 0;
  int _endIndex = 0;

  // space or new line
  static final breakChar = RegExp(' |\\n');

  @override
  String get current => _currentTextRun;

  @override
  bool moveNext() {
    _startIndex = _endIndex;
    if (_startIndex == text.length) {
      _currentTextRun = null;
      return false;
    }
    final next = text.indexOf(breakChar, _startIndex);
    _endIndex = (next != -1) ? next + 1 : text.length;
    _currentTextRun = text.substring(_startIndex, _endIndex);
    return true;
  }
}


class _RawStyledTextRun {
  _RawStyledTextRun(this.style, this.text);
  final TextStyle style;
  final String text;
}

/// A [TextRun] describes the smallest unit of text that is printed on the
/// canvas. It may be a word, CJK character, emoji or particular style.
///
/// The [start] and [end] values are the indexes of the text range that
/// forms the run. The [paragraph] is the precomputed Paragraph object that
/// contains the text run.
class TextRun {
  TextRun(this.start, this.end, this.paragraph);

  int start;
  int end;
  ui.Paragraph paragraph;
}

class LineInfo {
  LineInfo(this.textRunStart, this.textRunEnd, this.bounds);

  int textRunStart;
  int textRunEnd;
  Rect bounds;
}

class Stack<T> {
  final _stack = Queue();

  void push(T element) {
    _stack.addLast(element);
  }

  void pop() {
    _stack.removeLast();
  }

  bool get isEmpty => _stack.isEmpty;

  T get top => _stack.last;
}
