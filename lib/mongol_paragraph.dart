// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:meta/meta.dart';
import 'package:flutter/painting.dart';
import 'package:characters/characters.dart';

/// A paragraph of vertical Mongolian layout text.
class MongolParagraph {
  /// This class is created by the library, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [MongolParagraph] object, use a [MongolParagraphBuilder].
  MongolParagraph._(this._runs, this._text);
  final String _text;
  final List<_TextRun> _runs;

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

  final List<_LineInfo> _lines = [];

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
    var start = 0;
    var end = 0;
    var lineWidth = 0.0;
    var lineHeight = 0.0;
    for (var i = 0; i < _runs.length; i++) {
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

  bool _runEndsWithNewLine(_TextRun run) {
    final index = run.end - 1;
    return _text[index] == '\n';
  }

  void _addLine(int start, int end, double width, double height) {
    final bounds = Rect.fromLTRB(0, 0, width, height);
    final lineInfo = _LineInfo(start, end, bounds);
    _lines.add(lineInfo);
  }

  void _calculateWidth() {
    assert(_lines != null);
    assert(_runs != null);
    var sum = 0.0;
    for (final line in _lines) {
      sum += line.bounds.height;
    }
    _width = sum;
  }

  // Internally this translates a horizontal run width to the vertical name
  // that it is known as externally.
  void _calculateIntrinsicHeight() {
    assert(_runs != null);

    var sum = 0.0;
    var maxRunWidth = 0.0;
    var maxLineLength = 0.0;
    for (final line in _lines) {
      for (var i = line.textRunStart; i < line.textRunEnd; i++) {
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

  /// Returns the text position closest to the given offset.
  TextPosition getPositionForOffset(Offset offset) {
    final encoded = _getPositionForOffset(offset.dx, offset.dy);
    return TextPosition(
        offset: encoded[0], affinity: TextAffinity.values[encoded[1]]);
  }

  // Both the line info and the text run are in horizontal orientation,
  // but the [dx] and [dy] offsets are in vertical orientation.
  List<int> _getPositionForOffset(double dx, double dy) {
    assert(_lines != null);
    assert(_runs != null);

    // find the line
    _LineInfo matchedLine;
    var rightEdgeAfterRotation = 0.0;
    var rotatedRunDx = 0.0;
    var rotatedRunDy = 0.0;
    for (var line in _lines) {
      rightEdgeAfterRotation += line.bounds.bottom;
      rotatedRunDx = line.bounds.top;
      if (dx <= rightEdgeAfterRotation) {
        matchedLine = line;
        break;
      }
    }
    matchedLine ??= _lines.last;

    // find the run in the line
    _TextRun matchedRun;
    var bottomEdgeAfterRotating = 0.0;
    for (var i = matchedLine.textRunStart; i < matchedLine.textRunEnd; i++) {
      final run = _runs[i];
      rotatedRunDy = bottomEdgeAfterRotating;
      bottomEdgeAfterRotating += run.paragraph.maxIntrinsicWidth;
      if (dy <= bottomEdgeAfterRotating) {
        matchedRun = run;
        break;
      }
    }
    matchedRun ??= _runs[matchedLine.textRunEnd - 1];

    // find the offset
    final paragraphDx = dy - rotatedRunDy;
    final paragrpahDy = dx - rotatedRunDx;
    final offset = Offset(paragraphDx, paragrpahDy);
    final runPosition = matchedRun.paragraph.getPositionForOffset(offset);
    final textOffset = matchedRun.start + runPosition.offset;

    // find the afinity
    const upstream = 0;
    const downstream = 1;
    final isFirstLine = matchedLine.textRunStart == 0;
    final isFirstRunInLine = matchedRun == _runs[matchedLine.textRunStart];
    final isFirstPositionInRun = runPosition.offset == 0;
    final textAfinity =
        (!isFirstLine && isFirstRunInLine && isFirstPositionInRun)
            ? downstream
            : upstream;
    return [textOffset, textAfinity];
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
    for (final line in _lines) {
      // translate for the line height
      canvas.translate(0, -line.bounds.height);

      // draw each run in the current line
      var dx = 0.0;
      for (var i = line.textRunStart; i < line.textRunEnd; i++) {
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
    @required this.height,
  }) : assert(height != null);

  /// The height the paragraph should use when computing the positions of glyphs.
  final double height;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is MongolParagraphConstraints && other.height == height;
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
    bool autoRotate = true,
  })  : _paragraphStyle = style,
        _textScaleFactor = textScaleFactor,
        _autoRotate = autoRotate;

  ui.ParagraphStyle _paragraphStyle;
  final double _textScaleFactor;
  final bool _autoRotate;
  final _styleStack = _Stack<TextStyle>();
  final _rawStyledTextRuns = <_RawStyledTextRun>[];

  static final _defaultParagraphStyle = ui.ParagraphStyle(
    textAlign: TextAlign.start,
    textDirection: TextDirection.ltr,
  );

  static final _defaultTextStyle = ui.TextStyle(
    color: Color(0xFFFFFFFF),
    textBaseline: TextBaseline.alphabetic,
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
    final runs = <_TextRun>[];

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
      final isRotated = false; // TODO: change this
      final run = _TextRun(startIndex, endIndex, isRotated, paragraph);
      runs.add(run);
      _builder = null;
      startIndex = endIndex;
    }

    return MongolParagraph._(runs, _plainText.toString());
  }

  bool _startsWithBreak(String run) {
    if (run.isEmpty) return false;
    return LineBreaker.isBreakChar(run[0]);
  }

  bool _endsWithBreak(String run) {
    if (run.isEmpty) return false;
    return LineBreaker.isBreakChar(run[run.length - 1]);
  }

  ui.TextStyle _uiStyleForRun(int index) {
    final style = _rawStyledTextRuns[index].style;
    return style?.getTextStyle(textScaleFactor: _textScaleFactor) ??
        _defaultTextStyle;
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
  LineBreaker(this.text) {
    _characterIterator = text.characters.iterator;
  }

  final String text;

  CharacterRange _characterIterator;

  String _currentTextRun;

  @override
  String get current => _currentTextRun;

  bool _atEndOfCharacterRange = false;
  String _rotatedCharacterBuffer;

  @override
  bool moveNext() {
    if (_atEndOfCharacterRange) {
      _currentTextRun = null;
      return false;
    }
    if (_rotatedCharacterBuffer != null) {
      _currentTextRun = _rotatedCharacterBuffer;
      _rotatedCharacterBuffer = null;
      return true;
    }

    final returnValue = StringBuffer();
    while (_characterIterator.moveNext()) {
      final current = _characterIterator.current;
      if (isBreakChar(current)) {
        returnValue.write(current);
        _currentTextRun = returnValue.toString();
        return true;
      } else if (_isRotatable(current)) {
        if (returnValue.isEmpty) {
          _currentTextRun = current;
          return true;
        } else {
          _currentTextRun = returnValue.toString();
          _rotatedCharacterBuffer = current;
          return true;
        }
      }
      returnValue.write(current);
    }
    _currentTextRun = returnValue.toString();
    if (_currentTextRun.isEmpty) {
      return false;
    }
    _atEndOfCharacterRange = true;
    return true;
  }

  static bool isBreakChar(String character) {
    return (character == ' ' || character == '\n');
  }

  static const MONGOL_QUICKCHECK_START = 0x1800;
  static const MONGOL_QUICKCHECK_END = 0x2060;
  static const KOREAN_JAMO_START = 0x1100;
  static const KOREAN_JAMO_END = 0x11FF;
  static const CJK_RADICAL_SUPPLEMENT_START = 0x2E80;
  static const CJK_SYMBOLS_AND_PUNCTUATION_START = 0x3000;
  static const CJK_SYMBOLS_AND_PUNCTUATION_MENKSOFT_END = 0x301C;
  static const CIRCLE_NUMBER_21 = 0x3251;
  static const CIRCLE_NUMBER_35 = 0x325F;
  static const CIRCLE_NUMBER_36 = 0x32B1;
  static const CIRCLE_NUMBER_50 = 0x32BF;
  static const CJK_UNIFIED_IDEOGRAPHS_END = 0x9FFF;
  static const HANGUL_SYLLABLES_START = 0xAC00;
  static const HANGUL_JAMO_EXTENDED_B_END = 0xD7FF;
  static const CJK_COMPATIBILITY_IDEOGRAPHS_START = 0xF900;
  static const CJK_COMPATIBILITY_IDEOGRAPHS_END = 0xFAFF;
  static const UNICODE_EMOJI_START = 0x1F000;

  bool _isRotatable(String character) {
    if (character.runes.length > 1) return true;

    final codePoint = character.runes.first;

    // Quick return: most Mongol chars should be in this range
    if (codePoint >= MONGOL_QUICKCHECK_START &&
        codePoint < MONGOL_QUICKCHECK_END) return false;

    // Korean Jamo
    if (codePoint < KOREAN_JAMO_START) return false; // latin, etc
    if (codePoint <= KOREAN_JAMO_END) return true;

    // Chinese and Japanese
    if (codePoint >= CJK_RADICAL_SUPPLEMENT_START &&
        codePoint <= CJK_UNIFIED_IDEOGRAPHS_END) {
      // exceptions for font handled punctuation
      if (codePoint >= CJK_SYMBOLS_AND_PUNCTUATION_START &&
          codePoint <= CJK_SYMBOLS_AND_PUNCTUATION_MENKSOFT_END) return false;
      if (codePoint >= CIRCLE_NUMBER_21 && codePoint <= CIRCLE_NUMBER_35) {
        return false;
      }

      if (codePoint >= CIRCLE_NUMBER_36 && codePoint <= CIRCLE_NUMBER_50) {
        return false;
      }
      return true;
    }

    // Korean Hangul
    if (codePoint >= HANGUL_SYLLABLES_START &&
        codePoint <= HANGUL_JAMO_EXTENDED_B_END) return true;

    // More Chinese
    if (codePoint >= CJK_COMPATIBILITY_IDEOGRAPHS_START &&
        codePoint <= CJK_COMPATIBILITY_IDEOGRAPHS_END) return true;

    // Emoji
    if (_isEmoji(codePoint)) return true;

    // all other code points
    return false;
  }

  bool _isEmoji(int codePoint) {
    return codePoint > UNICODE_EMOJI_START;
  }
}

// A data object to associate a text run with its style
class _RawStyledTextRun {
  _RawStyledTextRun(this.style, this.text);
  final TextStyle style;
  final String text;
}

/// A [_TextRun] describes the smallest unit of text that is printed on the
/// canvas. It may be a word, CJK character, emoji or particular style.
///
/// The [start] and [end] values are the indexes of the text range that
/// forms the run. The [paragraph] is the precomputed Paragraph object that
/// contains the text run.
class _TextRun {
  _TextRun(this.start, this.end, this.isRotated, this.paragraph);

  final int start;
  final int end;
  final bool isRotated;
  final ui.Paragraph paragraph;
}

/// LineInfo stores information about each line in the paragraph.
///
/// [textRunStart] is the index of the first text run in the line (out of all the
/// text runs in the paragraph). [textRunEnd] is the index of the last run.
///
/// The [bounds] is the size of the unrotated text line.
class _LineInfo {
  _LineInfo(this.textRunStart, this.textRunEnd, this.bounds);

  final int textRunStart;
  final int textRunEnd;
  final Rect bounds;
}

// This is for keeping track of the text style stack.
class _Stack<T> {
  final _stack = Queue<T>();

  void push(T element) {
    _stack.addLast(element);
  }

  void pop() {
    _stack.removeLast();
  }

  bool get isEmpty => _stack.isEmpty;

  T get top => _stack.last;
}
