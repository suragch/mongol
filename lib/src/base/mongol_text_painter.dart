// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui' as ui show ParagraphStyle;

import 'package:flutter/widgets.dart';
import 'package:mongol/src/base/mongol_paragraph.dart';

// The default font size if none is specified. This should be kept in
// sync with the default values in text_style.dart, as well as the
// defaults set in the engine (eg, LibTxt's text_style.h, paragraph_style.h).
const double _kDefaultFontSize = 14.0;

/// This is used to cache and pass the computed metrics regarding the
/// caret's size and position. This is preferred due to the expensive
/// nature of the calculation.
class _CaretMetrics {
  const _CaretMetrics({required this.offset, this.fullWidth});

  /// The offset of the top left corner of the caret from the top left
  /// corner of the paragraph.
  final Offset offset;

  /// The full width of the glyph at the caret position.
  ///
  /// Orientation is a vertical paragraph with horizontal caret.
  final double? fullWidth;
}

/// Whether and how to align text vertically.
///
/// This is only used at the MongolTextPainter level and above. Below that the
/// more primitive [TextAlign] enum is used and top is mapped to left and
/// bottom is mapped to right.
enum MongolTextAlign {
  /// Align the text on the top edge of the container.
  top,

  /// Align the text on the bottom edge of the container.
  bottom,

  /// Align the text in the center of the container.
  center,

  /// Stretch lines of text that end with a soft line break to fill the height
  /// of the container.
  ///
  /// Lines that end with hard line breaks are aligned towards the [top] edge.
  justify,
}

/// A convenience method for converting MongolTextAlign to TextAlign
TextAlign mapMongolToHorizontalTextAlign(MongolTextAlign textAlign) {
  switch (textAlign) {
    case MongolTextAlign.top:
      return TextAlign.left;
    case MongolTextAlign.bottom:
      return TextAlign.right;
    case MongolTextAlign.center:
      return TextAlign.center;
    case MongolTextAlign.justify:
      return TextAlign.justify;
  }
}

/// A convenience method for converting MongolTextAlign to TextAlign
MongolTextAlign? mapHorizontalToMongolTextAlign(TextAlign? textAlign) {
  if (textAlign == null) return null;
  switch (textAlign) {
    case TextAlign.left:
    case TextAlign.start:
      return MongolTextAlign.top;
    case TextAlign.right:
    case TextAlign.end:
      return MongolTextAlign.bottom;
    case TextAlign.center:
      return MongolTextAlign.center;
    case TextAlign.justify:
      return MongolTextAlign.justify;
  }
}

/// An object that paints a Mongolian [TextSpan] tree into a [Canvas].
///
/// To use a [MongolTextPainter], follow these steps:
///
/// 1. Create a [TextSpan] tree and pass it to the [MongolTextPainter]
///    constructor.
///
/// 2. Call [layout] to prepare the paragraph.
///
/// 3. Call [paint] as often as desired to paint the paragraph.
///
/// If the width of the area into which the text is being painted
/// changes, return to step 2. If the text to be painted changes,
/// return to step 1.
///
/// The default text style is white. To change the color of the text,
/// pass a [TextStyle] object to the [TextSpan] in `text`.
class MongolTextPainter {
  /// Creates a text painter that paints the given text.
  ///
  /// The `text` argument is optional but [text] must be non-null before
  /// calling [layout].
  MongolTextPainter({
    TextSpan? text,
    MongolTextAlign textAlign = MongolTextAlign.top,
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
  })  : assert(text == null || text.debugAssertIsValid()),
        assert(maxLines == null || maxLines > 0),
        _text = text,
        _textAlign = textAlign,
        _textScaleFactor = textScaleFactor,
        _maxLines = maxLines,
        _ellipsis = ellipsis;

  MongolParagraph? _paragraph;
  bool _needsLayout = true;

  /// Marks this text painter's layout information as dirty and removes cached
  /// information.
  ///
  /// Uses this method to notify text painter to relayout in the case of
  /// layout changes in engine. In most cases, updating text painter properties
  /// in framework will automatically invoke this method.
  void markNeedsLayout() {
    _paragraph = null;
    _needsLayout = true;
    _previousCaretPosition = null;
    _previousCaretPrototype = null;
  }

  /// The (potentially styled) text to paint.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  /// This must be non-null before you call [layout].
  ///
  /// The [TextSpan] this provides is in the form of a tree that may contain
  /// multiple instances of [TextSpan]s. To obtain a plain text
  /// representation of the contents of this [TextPainter], use
  /// [TextSpan.toPlainText] to get the full contents of all nodes in the tree.
  /// [TextSpan.text] will only provide the contents of the first node in the
  /// tree.
  TextSpan? get text => _text;
  TextSpan? _text;
  set text(TextSpan? value) {
    assert(value == null || value.debugAssertIsValid());
    if (_text == value) return;
    if (_text?.style != value?.style) {
      _layoutTemplate = null;
    }
    _text = value;
    markNeedsLayout();
  }

  /// How the text should be aligned vertically.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  ///
  /// The [textAlign] property defaults to [MongolTextAlign.top].
  MongolTextAlign get textAlign => _textAlign;
  MongolTextAlign _textAlign;
  set textAlign(MongolTextAlign value) {
    if (_textAlign == value) {
      return;
    }
    _textAlign = value;
    markNeedsLayout();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  double get textScaleFactor => _textScaleFactor;
  double _textScaleFactor;
  set textScaleFactor(double value) {
    if (_textScaleFactor == value) return;
    _textScaleFactor = value;
    markNeedsLayout();
    _layoutTemplate = null;
  }

  /// The string used to ellipsize overflowing text. Setting this to a non-empty
  /// string will cause this string to be substituted for the remaining text
  /// if the text can not fit within the specified maximum height.
  ///
  /// Specifically, the ellipsis is applied to the last line before the line
  /// truncated by [maxLines], if [maxLines] is non-null and that line overflows
  /// the height constraint, or to the first line that is taller than the height
  /// constraint, if [maxLines] is null. The height constraint is the `maxHeight`
  /// passed to [layout].
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  ///
  /// The higher layers of the system, such as the [MongolText] widget, represent
  /// overflow effects using the [TextOverflow] enum. The
  /// [TextOverflow.ellipsis] value corresponds to setting this property to
  /// U+2026 HORIZONTAL ELLIPSIS (…).
  String? get ellipsis => _ellipsis;
  String? _ellipsis;
  set ellipsis(String? value) {
    assert(value == null || value.isNotEmpty);
    if (_ellipsis == value) {
      return;
    }
    _ellipsis = value;
    markNeedsLayout();
  }

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary.
  ///
  /// If the text exceeds the given number of lines, it is truncated such that
  /// subsequent lines are dropped.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  int? get maxLines => _maxLines;
  int? _maxLines;
  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (_maxLines == value) {
      return;
    }
    _maxLines = value;
    markNeedsLayout();
  }

  MongolParagraph? _layoutTemplate;

  ui.ParagraphStyle _createParagraphStyle() {
    return _text!.style?.getParagraphStyle(
          textAlign: mapMongolToHorizontalTextAlign(textAlign),
          textDirection: TextDirection.ltr,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          ellipsis: ellipsis,
          locale: null,
          strutStyle: null,
        ) ??
        ui.ParagraphStyle(
          textAlign: mapMongolToHorizontalTextAlign(textAlign),
          textDirection: TextDirection.ltr,
          // Use the default font size to multiply by as RichText does not
          // perform inheriting [TextStyle]s and would otherwise
          // fail to apply textScaleFactor.
          fontSize: _kDefaultFontSize * textScaleFactor,
          maxLines: maxLines,
          ellipsis: ellipsis,
          locale: null,
        );
  }

  /// The width of a space in [text] in logical pixels.
  ///
  /// (This is in vertical orientation. In other words, it is the height
  /// of a space in horizontal orientation.)
  ///
  /// Not every line of text in [text] will have this width, but this width
  /// is "typical" for text in [text] and useful for sizing other objects
  /// relative a typical line of text.
  ///
  /// Obtaining this value does not require calling [layout].
  ///
  /// The style of the [text] property is used to determine the font settings
  /// that contribute to the [preferredLineWidth]. If [text] is null or if it
  /// specifies no styles, the default [TextStyle] values are used (a 10 pixel
  /// sans-serif font).
  double get preferredLineWidth {
    if (_layoutTemplate == null) {
      final builder = MongolParagraphBuilder(_createParagraphStyle());
      if (text?.style != null) {
        builder.pushStyle(text!.style!);
      }
      builder.addText(' ');
      _layoutTemplate = builder.build()
        ..layout(const MongolParagraphConstraints(height: double.infinity));
    }
    return _layoutTemplate!.width;
  }

  double _applyFloatingPointHack(double layoutValue) {
    return layoutValue.ceilToDouble();
  }

  /// The height at which decreasing the height of the text would prevent it from
  /// painting itself completely within its bounds.
  ///
  /// Valid only after [layout] has been called.
  double get minIntrinsicHeight {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph!.minIntrinsicHeight);
  }

  /// The height at which increasing the height of the text no longer decreases
  /// the width.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicHeight {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph!.maxIntrinsicHeight);
  }

  /// The horizontal space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get width {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph!.width);
  }

  /// The vertical space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph!.height);
  }

  /// The amount of space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  Size get size {
    assert(!_needsLayout);
    return Size(width, height);
  }

  /// Even though the text is rotated, it is still useful to have a baseline
  /// along which to layout objects. (For example in the MongolInputDecorator.)
  ///
  /// Valid only after [layout] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph!.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph!.ideographicBaseline;
    }
  }

  /// Whether any text was truncated or ellipsized.
  ///
  /// If [maxLines] is not null, this is true if there were more lines to be
  /// drawn than the given [maxLines], and thus at least one line was omitted in
  /// the output; otherwise it is false.
  ///
  /// If [maxLines] is null, this is true if [ellipsis] is not the empty string
  /// and there was a line that overflowed the `maxHeight` argument passed to
  /// [layout]; otherwise it is false.
  ///
  /// Valid only after [layout] has been called.
  bool get didExceedMaxLines {
    assert(!_needsLayout);
    return _paragraph!.didExceedMaxLines;
  }

  double? _lastMinHeight;
  double? _lastMaxHeight;

  /// Computes the visual position of the glyphs for painting the text.
  ///
  /// The text will layout with a height that's as close to its max intrinsic
  /// height as possible while still being greater than or equal to `minHeight`
  /// and less than or equal to `maxHeight`.
  ///
  /// The [text] property must be non-null before this is called.
  void layout({double minHeight = 0.0, double maxHeight = double.infinity}) {
    assert(text != null);
    if (!_needsLayout &&
        minHeight == _lastMinHeight &&
        maxHeight == _lastMaxHeight) return;
    _needsLayout = false;
    if (_paragraph == null) {
      final builder = MongolParagraphBuilder(
        _createParagraphStyle(),
        textScaleFactor: _textScaleFactor,
        maxLines: _maxLines,
        ellipsis: _ellipsis,
      );
      _addStyleToText(builder, _text!);
      _paragraph = builder.build();
    }
    _lastMinHeight = minHeight;
    _lastMaxHeight = maxHeight;
    // A change in layout invalidates the cached caret metrics as well.
    _previousCaretPosition = null;
    _previousCaretPrototype = null;
    _paragraph!.layout(MongolParagraphConstraints(height: maxHeight));
    if (minHeight != maxHeight) {
      final newHeight = maxIntrinsicHeight.clamp(minHeight, maxHeight);
      if (newHeight != height) {
        _paragraph!.layout(MongolParagraphConstraints(height: newHeight));
      }
    }
  }

  void _addStyleToText(
    MongolParagraphBuilder builder,
    InlineSpan inlineSpan,
  ) {
    if (inlineSpan is! TextSpan) {
      throw UnimplementedError(
          'Inline span support has not yet been implemented for MongolTextPainter');
    }
    final textSpan = inlineSpan;
    final style = textSpan.style;
    final text = textSpan.text;
    final children = textSpan.children;
    final hasStyle = style != null;
    if (hasStyle) builder.pushStyle(style!);
    if (text != null) builder.addText(text);
    if (children != null) {
      for (final child in children) {
        _addStyleToText(builder, child);
      }
    }
    if (hasStyle) builder.pop();
  }

  /// Paints the text onto the given canvas at the given offset.
  ///
  /// Valid only after [layout] has been called.
  ///
  /// If you cannot see the text being painted, check that your text color does
  /// not conflict with the background on which you are drawing. The default
  /// text color is white (to contrast with the default black background color),
  /// so if you are writing an application with a white background, the text
  /// will not be visible by default.
  ///
  /// To set the text style, specify a [TextStyle] when creating the [TextSpan]
  /// that you pass to the [MongolTextPainter] constructor or to the [text]
  /// property.
  void paint(Canvas canvas, Offset offset) {
    assert(() {
      if (_needsLayout) {
        throw FlutterError(
            'TextPainter.paint called when text geometry was not yet calculated.\n'
            'Please call layout() before paint() to position the text before painting it.');
      }
      return true;
    }());
    _paragraph!.draw(canvas, offset);
  }

  // Returns true iff the given value is a valid UTF-16 surrogate. The value
  // must be a UTF-16 code unit, meaning it must be in the range 0x0000-0xFFFF.
  //
  // See also:
  //   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
  static bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  // Checks if the glyph is either [Unicode.RLM] or [Unicode.LRM]. These values take
  // up zero space and do not have valid bounding boxes around them.
  //
  // We do not directly use the [Unicode] constants since they are strings.
  static bool _isUnicodeDirectionality(int value) {
    return value == 0x200F || value == 0x200E;
  }

  /// Returns the closest offset after `offset` at which the input cursor can be
  /// positioned.
  int? getOffsetAfter(int offset) {
    final nextCodeUnit = _text!.codeUnitAt(offset);
    if (nextCodeUnit == null) return null;
    return _isUtf16Surrogate(nextCodeUnit) ? offset + 2 : offset + 1;
  }

  /// Returns the closest offset before `offset` at which the input cursor can
  /// be positioned.
  int? getOffsetBefore(int offset) {
    final prevCodeUnit = _text!.codeUnitAt(offset - 1);
    if (prevCodeUnit == null) return null;
    return _isUtf16Surrogate(prevCodeUnit) ? offset - 2 : offset - 1;
  }

  // Unicode value for a zero width joiner character.
  static const int _zwjUtf16 = 0x200d;

  // Get the Rect of the cursor (in logical pixels) based off the near edge
  // of the character upstream from the given string offset.
  Rect? _getRectFromUpstream(int offset, Rect caretPrototype) {
    final flattenedText = _text!.toPlainText(includePlaceholders: false);
    final prevCodeUnit = _text!.codeUnitAt(max(0, offset - 1));
    if (prevCodeUnit == null) {
      return null;
    }

    // Check for multi-code-unit glyphs such as emojis or zero width joiner.
    final needsSearch = _isUtf16Surrogate(prevCodeUnit) ||
        _text!.codeUnitAt(offset) == _zwjUtf16 ||
        _isUnicodeDirectionality(prevCodeUnit);
    var graphemeClusterLength = needsSearch ? 2 : 1;
    var boxes = <Rect>[];
    while (boxes.isEmpty) {
      final prevRuneOffset = offset - graphemeClusterLength;
      boxes = _paragraph!.getBoxesForRange(prevRuneOffset, offset);
      // When the range does not include a full cluster, no boxes will be returned.
      if (boxes.isEmpty) {
        // When we are at the beginning of the line, a non-surrogate position will
        // return empty boxes. We break and try from downstream instead.
        if (!needsSearch) {
          break; // Only perform one iteration if no search is required.
        }
        if (prevRuneOffset < -flattenedText.length) {
          break; // Stop iterating when beyond the max length of the text.
        }
        // Multiply by two to log(n) time cover the entire text span. This allows
        // faster discovery of very long clusters and reduces the possibility
        // of certain large clusters taking much longer than others, which can
        // cause jank.
        graphemeClusterLength *= 2;
        continue;
      }
      final box = boxes.first;

      // If the upstream character is a newline, cursor is at start of next line
      const NEWLINE_CODE_UNIT = 10;
      if (prevCodeUnit == NEWLINE_CODE_UNIT) {
        return Rect.fromLTRB(box.right, _emptyOffset.dy,
            box.right + box.right - box.left, _emptyOffset.dy);
      }

      final dy = box.bottom;
      return Rect.fromLTRB(box.left, min(dy, _paragraph!.height), box.right,
          min(dy, _paragraph!.height));
    }
    return null;
  }

  // Get the Rect of the cursor (in logical pixels) based off the near edge
  // of the character downstream from the given string offset.
  Rect? _getRectFromDownstream(int offset, Rect caretPrototype) {
    final flattenedText = _text!.toPlainText(includePlaceholders: false);
    // We cap the offset at the final index of the _text.
    final nextCodeUnit =
        _text!.codeUnitAt(min(offset, flattenedText.length - 1));
    if (nextCodeUnit == null) return null;
    // Check for multi-code-unit glyphs such as emojis or zero width joiner
    final needsSearch = _isUtf16Surrogate(nextCodeUnit) ||
        nextCodeUnit == _zwjUtf16 ||
        _isUnicodeDirectionality(nextCodeUnit);
    var graphemeClusterLength = needsSearch ? 2 : 1;
    var boxes = <Rect>[];
    while (boxes.isEmpty) {
      final nextRuneOffset = offset + graphemeClusterLength;
      boxes = _paragraph!.getBoxesForRange(offset, nextRuneOffset);
      // When the range does not include a full grapheme cluster, no boxes will
      // be returned.
      if (boxes.isEmpty) {
        // When we are at the end of the line, a non-surrogate position will
        // return empty boxes. We break and try from upstream instead.
        if (!needsSearch) {
          break; // Only perform one iteration if no search is required.
        }
        if (nextRuneOffset >= flattenedText.length << 1) {
          break; // Stop iterating when beyond the max length of the text.
        }
        // Multiply by two to log(n) time cover the entire text span. This allows
        // faster discovery of very long clusters and reduces the possibility
        // of certain large clusters taking much longer than others, which can
        // cause jank.
        graphemeClusterLength *= 2;
        continue;
      }
      final box = boxes.last;
      final dy = box.top;
      return Rect.fromLTRB(box.left, min(dy, _paragraph!.height), box.right,
          min(dy, _paragraph!.height));
    }
    return null;
  }

  Offset get _emptyOffset {
    assert(!_needsLayout);
    switch (textAlign) {
      case MongolTextAlign.top:
      case MongolTextAlign.justify:
        return Offset.zero;
      case MongolTextAlign.bottom:
        return Offset(0.0, height);
      case MongolTextAlign.center:
        return Offset(0.0, height / 2.0);
    }
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout] has been called.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    _computeCaretMetrics(position, caretPrototype);
    return _caretMetrics.offset;
  }

  /// Returns the strut bounded width of the glyph at the given `position`.
  ///
  /// Valid only after [layout] has been called.
  double? getFullWidthForCaret(TextPosition position, Rect caretPrototype) {
    _computeCaretMetrics(position, caretPrototype);
    return _caretMetrics.fullWidth;
  }

  // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
  // [getFullWidthForCaret] in a row without performing redundant and expensive
  // get rect calls to the paragraph.
  late _CaretMetrics _caretMetrics;

  // Holds the TextPosition and caretPrototype the last caret metrics were
  // computed with. When new values are passed in, we recompute the caret metrics,
  // only as necessary.
  TextPosition? _previousCaretPosition;
  Rect? _previousCaretPrototype;

  // Checks if the [position] and [caretPrototype] have changed from the cached
  // version and recomputes the metrics required to position the caret.
  void _computeCaretMetrics(TextPosition position, Rect caretPrototype) {
    assert(!_needsLayout);
    if (position == _previousCaretPosition &&
        caretPrototype == _previousCaretPrototype) {
      return;
    }
    final offset = position.offset;
    Rect? rect;
    switch (position.affinity) {
      case TextAffinity.upstream:
        {
          rect = _getRectFromUpstream(offset, caretPrototype) ??
              _getRectFromDownstream(offset, caretPrototype);
          break;
        }
      case TextAffinity.downstream:
        {
          rect = _getRectFromDownstream(offset, caretPrototype) ??
              _getRectFromUpstream(offset, caretPrototype);
          break;
        }
    }
    _caretMetrics = _CaretMetrics(
      offset: rect != null ? Offset(rect.left, rect.top) : _emptyOffset,
      fullWidth: rect != null ? rect.right - rect.left : null,
    );

    // Cache the input parameters to prevent repeat work later.
    _previousCaretPosition = position;
    _previousCaretPrototype = caretPrototype;
  }

  /// Returns a list of rects that bound the given selection.
  List<Rect> getBoxesForSelection(TextSelection selection) {
    assert(!_needsLayout);
    return _paragraph!.getBoxesForRange(
      selection.start,
      selection.end,
    );
  }

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(!_needsLayout);
    return _paragraph!.getPositionForOffset(offset);
  }

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  TextRange getWordBoundary(TextPosition position) {
    assert(!_needsLayout);
    return _paragraph!.getWordBoundary(position);
  }

  /// Returns the text range of the line at the given offset.
  ///
  /// The newline, if any, is included in the range.
  TextRange getLineBoundary(TextPosition position) {
    assert(!_needsLayout);
    return _paragraph!.getLineBoundary(position);
  }
}
