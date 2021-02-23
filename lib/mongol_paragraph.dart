// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:characters/characters.dart';

/// A paragraph of vertical Mongolian layout text.
///
/// This class is a replacement for the Paragraph class. Since Paragraph hands
/// all it's work down to the Flutter engine, this class also does the work
/// of line-wrapping and laying out the text.
///
/// The text is divided into a list of [_runs] where each run is a short
/// substring (usually a word or CJK/emoji character). Sometimes a run includes
/// multiple styles in which case [_rawStyledTextRuns] are used temorarily
/// before they can be combined into single [_runs] just based on words. The
/// [_runs] are then measured and layed out in [_lines] based on the given
/// constraints.
class MongolParagraph {
  /// This class is created by the library, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [MongolParagraph] object, use a [MongolParagraphBuilder].
  MongolParagraph._(
    this._runs,
    this._text,
    this._maxLines,
    this._ellipsis,
  );

  final String _text;
  final List<_TextRun> _runs;
  final int? _maxLines;
  final _TextRun? _ellipsis;

  double? _width;
  double? _height;
  double? _minIntrinsicHeight;
  double? _maxIntrinsicHeight;

  /// The amount of horizontal space this paragraph occupies.
  ///
  /// Valid only after [layout] has been called.
  double get width => _width ?? 0;

  /// The amount of vertical space this paragraph occupies.
  ///
  /// Valid only after [layout] has been called.
  double get height => _height ?? 0;

  /// The minimum height that this paragraph could be without failing to paint
  /// its contents within itself.
  ///
  /// Valid only after [layout] has been called.
  double get minIntrinsicHeight => _minIntrinsicHeight ?? 0;

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the width.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicHeight => _maxIntrinsicHeight ?? double.infinity;

  /// The distance to the alphabetic baseline the same as for horizontal text.
  double get alphabeticBaseline {
    if (_runs.isEmpty) {
      return 0.0;
    }
    return _runs.first.paragraph.alphabeticBaseline;
  }

  /// The distance to the ideographic baseline the same as for horizontal text.
  double get ideographicBaseline {
    if (_runs.isEmpty) {
      return 0.0;
    }
    return _runs.first.paragraph.ideographicBaseline;
  }

  /// True if there is more horizontal content, but the text was truncated, either
  /// because we reached `maxLines` lines of text or because the `maxLines` was
  /// null, `ellipsis` was not null, and one of the lines exceeded the height
  /// constraint.
  ///
  /// See the discussion of the `maxLines` and `ellipsis` arguments at
  /// [ParagraphStyle].
  bool get didExceedMaxLines {
    return _didExceedMaxLines;
  }

  bool _didExceedMaxLines = false;

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
    if (_runs.isEmpty) {
      return;
    }
    if (_lines.isNotEmpty) {
      _lines.clear();
      _didExceedMaxLines = false;
    }

    // add run lengths until exceeds length
    var start = 0;
    var end = 0;
    var lineWidth = 0.0;
    var lineHeight = 0.0;
    var runEndsWithNewLine = false;
    for (var i = 0; i < _runs.length; i++) {
      end = i;
      final run = _runs[i];
      final runWidth = run.width;
      final runHeight = run.height;

      if (lineWidth + runWidth > maxLineLength) {
        _addLine(start, end, lineWidth, lineHeight);
        lineWidth = runWidth;
        lineHeight = runHeight;
        start = end;
      } else {
        lineWidth += runWidth;
        lineHeight = math.max(lineHeight, run.height);
      }

      runEndsWithNewLine = _runEndsWithNewLine(run);
      if (runEndsWithNewLine) {
        end = i + 1;
        _addLine(start, end, lineWidth, lineHeight);
        lineWidth = 0;
        lineHeight = 0;
        start = end;
      }

      if (_didExceedMaxLines) {
        break;
      }
    }

    end = _runs.length;
    if (start < end) {
      _addLine(start, end, lineWidth, lineHeight);
    }

    // add empty line with invalid run indexes for final newline char
    if (runEndsWithNewLine) {
      final height = _lines.last.bounds.height;
      _addLine(-1, -1, 0, height);
    }
  }

  bool _runEndsWithNewLine(_TextRun run) {
    final index = run.end - 1;
    return _text[index] == '\n';
  }

  void _addLine(int start, int end, double width, double height) {
    if (_maxLines != null && _maxLines! <= _lines.length) {
      _didExceedMaxLines = true;
      return;
    }
    _didExceedMaxLines = false;
    final bounds = Rect.fromLTRB(0, 0, width, height);
    final lineInfo = _LineInfo(start, end, bounds);
    _lines.add(lineInfo);
  }

  void _calculateWidth() {
    var sum = 0.0;
    for (final line in _lines) {
      sum += line.bounds.height;
    }
    _width = sum;
  }

  // Internally this translates a horizontal run width to the vertical name
  // that it is known as externally.
  void _calculateIntrinsicHeight() {
    var sum = 0.0;
    var maxRunWidth = 0.0;
    var maxLineLength = 0.0;
    for (final line in _lines) {
      for (var i = line.textRunStart; i < line.textRunEnd; i++) {
        final width = _runs[i].width;
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
    const upstream = 0;
    const downstream = 1;

    if (_lines.isEmpty) {
      return [0, downstream];
    }

    // find the line
    _LineInfo? matchedLine;
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
    _TextRun? matchedRun;
    var bottomEdgeAfterRotating = 0.0;
    for (var i = matchedLine.textRunStart; i < matchedLine.textRunEnd; i++) {
      final run = _runs[i];
      rotatedRunDy = bottomEdgeAfterRotating;
      bottomEdgeAfterRotating += run.width;
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
    final lineEndCharOffset = _runs[matchedLine.textRunEnd - 1].end;
    final textAfinity =
        (textOffset == lineEndCharOffset) ? upstream : downstream;
    return [textOffset, textAfinity];
  }

  /// Draws the precomputed text on a [canvas] one line at a time in vertical
  /// lines that wrap from left to right.
  void draw(Canvas canvas, Offset offset) {
    final shouldDrawEllipsis = _didExceedMaxLines && _ellipsis != null;

    // translate for the offset
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // rotate the canvas 90 degrees
    canvas.rotate(math.pi / 2);

    // loop through every line
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];

      // translate for the line height
      final dy = -line.bounds.height;
      canvas.translate(0, dy);

      // draw each run in the current line
      canvas.save();
      final startIndex = line.textRunStart;
      final endIndex = line.textRunEnd - 1;
      final isLastLine = i == _lines.length - 1;
      for (var j = startIndex; j <= endIndex; j++) {
        if (shouldDrawEllipsis && isLastLine && j == endIndex) {
          if (maxIntrinsicHeight + _ellipsis!.height < height) {
            final run = _runs[j];
            run.draw(canvas, Offset(0, 0));
            canvas.translate(run.width, 0);
          }
          _ellipsis!.draw(canvas, Offset(0, 0));
        } else {
          final run = _runs[j];
          run.draw(canvas, Offset(0, 0));
          canvas.translate(run.width, 0);
        }
      }
      canvas.restore();
    }

    canvas.restore();
  }

  /// Returns a list of rects that enclose the given text range.
  ///
  /// Coordinates of the Rect are relative to the upper-left corner of the
  /// paragraph, where positive y values indicate down. Orientation is as
  /// vertical Mongolian text with left to right line wrapping.
  ///
  /// Note that this method behaves slightly differently than
  /// Paragraph.getBoxesForRange. The Paragraph version returns List<TextBox>,
  /// but TextBox doesn't accurately describe vertical text so Rect is used.
  List<Rect> getBoxesForRange(int start, int end) {
    final boxes = <Rect>[];

    // The [start] index must be within the text range
    final textLength = _text.length;
    if (start < 0 || start > _text.length) {
      return boxes;
    }

    // Allow the [end] index to be larger than the text length but don't use it
    final effectiveEnd = math.min(textLength, end);

    // Horizontal offset for the left side of the vertical rect
    var dx = 0.0;

    // loop through each line
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final lastRunIndex = line.textRunEnd - 1;

      // return empty line for invalid run indexes
      // (This happens when text ends with newline char.)
      if (lastRunIndex < 0) {
        if (end > textLength) {
          boxes.add(_lineBoundsAsBox(line, dx));
        }
        continue;
      }

      final lineLastCharIndex = _runs[lastRunIndex].end - 1;

      // skip empty lines before the selected range
      if (lineLastCharIndex < start) {
        // The line is horizontal but dx is for vertical orientation
        dx += line.bounds.height;
        continue;
      }

      final firstRunIndex = line.textRunStart;
      final lineFirstCharIndex = _runs[firstRunIndex].start;

      // If this is a full line then skip looping over the runs
      // because the line size has already been cached.
      if (lineFirstCharIndex >= start && lineLastCharIndex < effectiveEnd) {
        boxes.add(_lineBoundsAsBox(line, dx));
      } else {
        // check the runs one at a time
        final lineBox = _getBoxFromLine(line, start, effectiveEnd, dx);

        // partial selections of grapheme clusters should return no boxes
        if (lineBox != Rect.zero) {
          boxes.add(lineBox);
        }

        // If this is the last line there we're finished
        if (lineLastCharIndex >= effectiveEnd - 1) {
          return boxes;
        }
      }
      dx += line.bounds.height;
    }
    return boxes;
  }

  Rect _lineBoundsAsBox(_LineInfo line, double dx) {
    final lineBounds = line.bounds;
    return Rect.fromLTWH(dx, 0, lineBounds.height, lineBounds.width);
  }

  // Takes a single line and finds the box that includes the selected range
  Rect _getBoxFromLine(_LineInfo line, int start, int end, double dx) {
    var boxWidth = 0.0;
    var boxHeight = 0.0;

    // This is the vertical offset for the box in vertical line orientation
    // It will only be non-zero if this is the first box.
    var dy = 0.0;

    // loop though every run in the line
    for (var j = line.textRunStart; j < line.textRunEnd; j++) {
      final run = _runs[j];

      // skips runs that are after selected range
      if (run.start >= end) {
        break;
      }

      // skip runs that are before the selected range
      if (run.end <= start) {
        dy += run.width;
        continue;
      }

      // The size of full intermediate runs has already been cached
      if (run.start >= start && run.end <= end) {
        boxWidth = math.max(boxWidth, run.height);
        boxHeight += run.width;
        if (run.end == end) {
          break;
        }
        continue;
      }

      // The range selection is in middle of a run
      final localStart = math.max(start, run.start) - run.start;
      final localEnd = math.min(end, run.end) - run.start;
      final textBoxes = run.paragraph.getBoxesForRange(localStart, localEnd);

      // empty boxes occur for partial selections of a grapheme cluster
      if (textBoxes.isEmpty) {
        if (end <= run.end) {
          break;
        } else {
          dy += run.width;
          continue;
        }
      }

      // handle orientation differences for emoji and CJK characters
      final box = textBoxes.first;
      double verticalWidth;
      double verticalHeight;
      if (run.isRotated) {
        verticalWidth = box.right;
        verticalHeight = box.bottom;
      } else {
        dy += box.left;
        verticalWidth = box.bottom;
        verticalHeight = box.right - box.left;
      }

      // update the rect size
      boxWidth = math.max(boxWidth, verticalWidth);
      boxHeight += verticalHeight;

      // if this is the last run then we're finished
      if (end <= run.end) {
        break;
      }
    }

    if (boxWidth == 0.0 || boxHeight == 0.0) {
      return Rect.zero;
    }
    return Rect.fromLTWH(dx, dy, boxWidth, boxHeight);
  }

  /// Returns the [TextRange] of the word at the given [TextPosition].
  ///
  /// The current implementation just returns the currect text run, which is
  /// generally a word.
  TextRange getWordBoundary(TextPosition position) {
    final offset = position.offset;
    if (offset >= _text.length) {
      return TextRange(start: _text.length, end: offset);
    }
    final run = _getRunFromOffset(offset);
    if (run == null) {
      return TextRange.empty;
    }
    return _splitBreakCharactersFromRun(run, offset);
  }

  // runs can include break characters currently so split them from the returned
  // range
  TextRange _splitBreakCharactersFromRun(_TextRun run, int offset) {
    var start = run.start;
    var end = run.end;
    final finalChar = _text[end - 1];
    if (LineBreaker.isBreakChar(finalChar)) {
      if (offset == end - 1) {
        start = end - 1;
      } else {
        end = end - 1;
      }
    }
    return TextRange(start: start, end: end);
  }

  _TextRun? _getRunFromOffset(int offset) {
    if (offset >= _text.length) {
      return null;
    }
    var min = 0;
    var max = _runs.length - 1;
    // do a binary search
    while (min <= max) {
      final guess = (max + min) ~/ 2;
      if (offset >= _runs[guess].end) {
        min = guess + 1;
        continue;
      } else if (offset < _runs[guess].start) {
        max = guess - 1;
        continue;
      } else {
        return _runs[guess];
      }
    }
    return null;
  }

  TextRange getLineBoundary(TextPosition position) {
    final offset = position.offset;
    if (offset > _text.length) {
      return TextRange.empty;
    }
    var min = 0;
    var max = _lines.length - 1;
    var start = -1;
    var end = -1;
    // do a binary search
    while (min <= max) {
      final guess = (max + min) ~/ 2;
      final line = _lines[guess];
      start = _runs[line.textRunStart].start;
      end = _runs[line.textRunEnd - 1].end;
      if (offset >= end) {
        min = guess + 1;
        continue;
      } else if (offset < start) {
        max = guess - 1;
        continue;
      } else {
        break;
      }
    }
    return TextRange(start: start, end: end);
  }
}

/// Layout constraints for [MongolParagraph] objects.
///
/// Instances of this class are typically used with [MongolParagraph.layout].
///
/// The only constraint that can be specified is the [height].
class MongolParagraphConstraints {
  const MongolParagraphConstraints({
    required this.height,
  });

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
    int? maxLines,
    String? ellipsis,
  })  : _paragraphStyle = style,
        _textScaleFactor = textScaleFactor,
        _maxLines = maxLines,
        _ellipsis = ellipsis;

  ui.ParagraphStyle? _paragraphStyle;
  final double _textScaleFactor;
  final int? _maxLines;
  final String? _ellipsis;
  //_TextRun? _ellipsisRun;
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
    ui.ParagraphBuilder? builder;
    ui.TextStyle? style;
    for (var i = 0; i < length; i++) {
      style = _uiStyleForRun(i);
      final segment = _rawStyledTextRuns[i].text;
      endIndex += segment.text.length;
      builder ??= ui.ParagraphBuilder(_paragraphStyle!);
      builder.pushStyle(style);
      final text = _stripNewLineChar(segment.text);
      builder.addText(text);
      builder.pop();

      if (_isNonBreakingSegment(i)) {
        continue;
      }

      final paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: double.infinity));
      final run =
          _TextRun(startIndex, endIndex, segment.isRotatable, paragraph);
      runs.add(run);
      builder = null;
      startIndex = endIndex;
    }

    return MongolParagraph._(
      runs,
      _plainText.toString(),
      _maxLines,
      _ellipsisRun(style),
    );
  }

  bool _isNonBreakingSegment(int i) {
    final segment = _rawStyledTextRuns[i].text;
    if (segment.isRotatable) return false;
    if (_endsWithBreak(segment.text)) return false;

    if (i >= _rawStyledTextRuns.length - 1) return false;
    final nextSegment = _rawStyledTextRuns[i + 1].text;
    if (nextSegment.isRotatable) return false;
    if (_startsWithBreak(nextSegment.text)) return false;
    return true;
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

  _TextRun? _ellipsisRun(ui.TextStyle? style) {
    if (_ellipsis == null) {
      return null;
    }
    final builder = ui.ParagraphBuilder(_paragraphStyle!);
    if (style != null) {
      builder.pushStyle(style);
    }
    builder.addText(_ellipsis!);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: double.infinity));
    return _TextRun(-1, -1, false, paragraph);
  }
}

/// An iterable that iterates over the substrings of [text] between locations
/// that line breaks are allowed.
class BreakSegments extends Iterable<RotatableString> {
  BreakSegments(this.text);
  final String text;

  @override
  Iterator<RotatableString> get iterator => LineBreaker(text);
}

class RotatableString {
  const RotatableString(this.text, this.isRotatable);
  final String text;
  final bool isRotatable;
}

/// Finds all the locations in a string of text where line breaks are allowed.
///
/// LineBreaker gives the strings between the breaks upon iteration.
class LineBreaker implements Iterator<RotatableString> {
  LineBreaker(this.text) {
    _characterIterator = text.characters.iterator;
  }

  final String text;

  late CharacterRange _characterIterator;

  RotatableString? _currentTextRun;

  @override
  RotatableString get current {
    if (_currentTextRun == null) {
      throw StateError(
          'Current is undefined before moveNext is called or after last element.');
    }
    return _currentTextRun!;
  }

  bool _atEndOfCharacterRange = false;
  RotatableString? _rotatedCharacterBuffer;

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
        _currentTextRun = RotatableString(returnValue.toString(), false);
        return true;
      } else if (_isRotatable(current)) {
        if (returnValue.isEmpty) {
          _currentTextRun = RotatableString(current, true);
          return true;
        } else {
          _currentTextRun = RotatableString(returnValue.toString(), false);
          _rotatedCharacterBuffer = RotatableString(current, true);
          return true;
        }
      }
      returnValue.write(current);
    }
    _currentTextRun = RotatableString(returnValue.toString(), false);
    if (_currentTextRun!.text.isEmpty) {
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
    //if (character.runes.length > 1) return true;

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
  final TextStyle? style;
  final RotatableString text;
}

/// A [_TextRun] describes the smallest unit of text that is printed on the
/// canvas. It may be a word, CJK character, emoji or particular style.
///
/// The [start] and [end] values are the indexes of the text range that
/// forms the run. The [paragraph] is the precomputed Paragraph object that
/// contains the text run.
class _TextRun {
  _TextRun(this.start, this.end, this.isRotated, this.paragraph);

  /// The UTF-16 code unit index where this run starts within the entire text
  /// range. The value in inclusive (that is, this is the actual start index).
  final int start;

  /// The UTF-16 code unit index where this run ends within the entire text
  /// range. The value is exclusive (that is, one unit beyond the last code
  /// unit).
  final int end;

  /// Whether this text run should be rotated 90 degrees counterclockwise in
  /// relation to the rest of the text.
  ///
  /// This would normally be for emoji and  CJK characters so that they will
  /// appear in the correct orientation in a vertical line of text.
  final bool isRotated;

  /// The pre-computed text layout for this run.
  ///
  /// It includes the size but should never be more than one line.
  final ui.Paragraph paragraph;

  /// Returns the width of the run (in horizontal orientation) taking into account
  /// whether it [isRotated].
  double get width {
    if (isRotated) {
      return paragraph.height;
    }
    return paragraph.maxIntrinsicWidth;
  }

  /// Returns the height of the run (in horizontal orientation) taking into account
  /// whether it [isRotated].
  double get height {
    if (isRotated) {
      return paragraph.maxIntrinsicWidth;
    }
    return paragraph.height;
  }

  void draw(ui.Canvas canvas, ui.Offset offset) {
    if (isRotated) {
      canvas.save();
      canvas.rotate(-math.pi / 2);
      canvas.translate(-height, 0);
      canvas.drawParagraph(paragraph, offset);
      canvas.restore();
    } else {
      canvas.drawParagraph(paragraph, offset);
    }
  }
}

/// LineInfo stores information about each line in the paragraph.
///
/// [textRunStart] is the index of the first text run in the line (out of all the
/// text runs in the paragraph). [textRunEnd] is the index of the last run.
///
/// The [bounds] is the size of the unrotated text line.
class _LineInfo {
  _LineInfo(this.textRunStart, this.textRunEnd, this.bounds);

  /// The index of the run in [_runs] where this line starts
  final int textRunStart;

  /// The index (exclusive) of the run in [_runs] where this line end
  final int textRunEnd;

  /// The measured size of this unrotated line (horizontal orientation).
  ///
  /// There is no offset so [left] and [top] are `0`. Just use [width] and
  /// [height].
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
