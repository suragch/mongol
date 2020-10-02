// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// A paragraph of vertical Mongolian layout text.
class MongolParagraph {
  /// This class is created by the library, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [MongolParagraph] object, use a [MongolParagraphBuilder].
  MongolParagraph._(this._runs, this._text);
  String _text;
  List<TextRun> _runs;

  double _width;
  double _height;
  double _minIntrinsicHeight;
  double _maxIntrinsicHeight;

  /// The amount of horizontal space this paragraph occupies.
  ///
  /// Valid only after [layout] has been called.
  double get width => _width;

  /// The amount of vertical space this paragraph occupies.
  ///
  /// Valid only after [layout] has been called.
  double get height => _height;

  /// The minimum height that this paragraph could be without failing to paint
  /// its contents within itself.
  ///
  /// Valid only after [layout] has been called.
  double get minIntrinsicHeight => _minIntrinsicHeight;

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the width.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicHeight => _maxIntrinsicHeight;

  /// Computes the size and position of each glyph in the paragraph.
  ///
  /// The [MongolParagraphConstraints] control how tall the text is allowed 
  /// to be.
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

  /// Draws the precomputed text on a [canvas] one line at a time in vertical
  /// lines that wrap from left to right.
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

/// Layout constraints for [MongolParagraph] objects.
///
/// Instances of this class are typically used with [MongolParagraph.layout].
///
/// The only constraint that can be specified is the [height].
class MongolParagraphConstraints {
  const MongolParagraphConstraints({
    this.height,
  }) : assert(height != null);

  /// The height the paragraph should use when computing the positions of glyphs.
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

/// Builds a [MongolParagraph] containing text with the given styling 
/// information.
///
/// To set the paragraph's style, pass an appropriately-configured 
/// [ParagraphStyle] object to the [MongolParagraphBuilder] constructor.
///
/// Then, call combinations of [pushStyle], [addText], and [pop] to add styled
/// text to the object.
///
/// Finally, call [build] to obtain the constructed [MongolParagraph] object. 
/// After this point, the builder is no longer usable.
///
/// After constructing a [MongolParagraph], call [MongolParagraph.layout] on 
/// it and then paint it with [MongolParagraph.draw].
class MongolParagraphBuilder {
  MongolParagraphBuilder(
    ui.ParagraphStyle style, {
    double textScaleFactor = 1.0,
  })  : _paragraphStyle = style,
        _textScaleFactor = textScaleFactor;

  ui.ParagraphStyle _paragraphStyle;
  final double _textScaleFactor;
  final _styleStack = _Stack<TextStyle>();
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

  /// Applies the given style to the added text until [pop] is called.
  ///
  /// See [pop] for details.
  void pushStyle(TextStyle style) {
    if (_styleStack.isEmpty) {
      _styleStack.push(style);
      return;
    }
    final lastStyle = _styleStack.top;
    _styleStack.push(lastStyle.merge(style));
  }

  /// Ends the effect of the most recent call to [pushStyle].
  ///
  /// Internally, the paragraph builder maintains a stack of text styles. Text
  /// added to the paragraph is affected by all the styles in the stack. Calling
  /// [pop] removes the topmost style in the stack, leaving the remaining styles
  /// in effect.
  void pop() {
    _styleStack.pop();
  }

  final _plainText = StringBuffer();

  /// Adds the given text to the paragraph.
  ///
  /// The text will be styled according to the current stack of text styles.
  void addText(String text) {
    _plainText.write(text);
    final style = _styleStack.isEmpty ? null : _styleStack.top;
    final breakSegments = BreakSegments(text);
    for (final segment in breakSegments) {
      _rawStyledTextRuns.add(_RawStyledTextRun(style, segment));
    }
  }

  /// Applies the given paragraph style and returns a [MongolParagraph] 
  /// containing the added text and associated styling.
  ///
  /// After calling this function, the paragraph builder object is invalid and
  /// cannot be used further.
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

    return MongolParagraph._(runs, _plainText.toString());
  }

  bool _startsWithBreak(String run) {
    return run.startsWith(LineBreaker.breakChar);
  }

  bool _endsWithBreak(String run) {
    if (run.isEmpty) return false;
    return (run[run.length - 1].contains(LineBreaker.breakChar));
  }

  ui.TextStyle _uiStyleForRun(int index) {
    final style = _rawStyledTextRuns[index].style;
    return style?.getTextStyle(textScaleFactor: _textScaleFactor) ?? _defaultTextStyle;
  }

  String _stripNewLineChar(String text) {
    if (!text.endsWith('\n')) return text;
    return text.replaceAll('\n', '');
  }
}

/// An iterable that iterates over the substrings of [text] between locations
/// that line breaks are allowed.
class BreakSegments extends Iterable<String> {
  BreakSegments(this.text);
  final String text;

  @override
  Iterator<String> get iterator => LineBreaker(text);
}

/// Finds all the locations in a string of text where line breaks are allowed.
/// 
/// LineBreaker gives the strings between the breaks upon iteration.
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

// A data object to associate a text run with its style
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

/// LineInfo stores information about each line in the paragraph.
/// 
/// [textRunStart] is the index of the first text run in the line (out of all the
/// text runs in the paragraph). [textRunEnd] is the index of the last run.
/// 
/// The [bounds] is the location of the text line in the paragraph.
class LineInfo {
  LineInfo(this.textRunStart, this.textRunEnd, this.bounds);

  int textRunStart;
  int textRunEnd;
  Rect bounds;
}

// This is for keeping track of the text style stack.
class _Stack<T> {
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
