// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui' as ui show ParagraphStyle;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/mongol_paragraph.dart';

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
    TextAlign textAlign = TextAlign.start,
    double textScaleFactor = 1.0,
  })  : assert(text == null || text.debugAssertIsValid()),
        _text = text,
        _textAlign = textAlign,
        _textScaleFactor = textScaleFactor;

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

  MongolParagraph? _paragraph;
  bool _needsLayout = true;

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
    _text = value;
    _paragraph = null;
    _needsLayout = true;
  }

  /// How the text should be aligned vertically.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  ///
  /// The [textAlign] property defaults to [TextAlign.start].
  TextAlign get textAlign => _textAlign;
  TextAlign _textAlign;
  set textAlign(TextAlign value) {
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
  }

  ui.ParagraphStyle _createParagraphStyle() {
    return _text!.style?.getParagraphStyle(
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
          textScaleFactor: textScaleFactor,
          maxLines: null,
          ellipsis: null,
          locale: null,
          strutStyle: null,
        ) ??
        ui.ParagraphStyle(
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
          maxLines: null,
          ellipsis: null,
          locale: null,
        );
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
    assert(!_needsLayout); // implies textDirection is non-null
    switch (textAlign) {
      case TextAlign.start:
      case TextAlign.justify:
      case TextAlign.left:
        return Offset.zero;
      case TextAlign.end:
      case TextAlign.right:
        return Offset(0.0, height);
      case TextAlign.center:
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

  // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
  // [getFullHeightForCaret] in a row without performing redundant and expensive
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

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(!_needsLayout);
    return _paragraph!.getPositionForOffset(offset);
  }
}
