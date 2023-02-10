// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui' as ui show ParagraphStyle;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show
        TextAlign,
        TextSpan,
        Canvas,
        RenderComparison,
        Size,
        Rect,
        DiagnosticsNode,
        TextPosition,
        Offset,
        TextRange,
        TextOverflow,
        TextSelection,
        InlineSpan,
        FlutterError,
        ErrorSummary,
        TextDirection,
        TextBaseline,
        TextAffinity;
import 'package:mongol/src/base/mongol_paragraph.dart';

import 'mongol_text_align.dart';

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
/// 4. Call [dispose] when the object will no longer be accessed to release
///    native resources. For [MongolTextPainter] objects that are used repeatedly and
///    stored on a [State] or [RenderObject], call [dispose] from
///    [State.dispose] or [RenderObject.dispose] or similar. For [MongolTextPainter]
///    objects that are only used ephemerally, it is safe to immediately dispose
///    them after the last call to methods or properties on the object.
///
/// If the height of the area into which the text is being painted
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
  ///
  /// The [maxLines] property, if non-null, must be greater than zero.
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

  /// Computes the height of a configured [MongolTextPainter].
  ///
  /// This is a convenience method that creates a text painter with the supplied
  /// parameters, lays it out with the supplied [minHeight] and [maxHeight], and
  /// returns its [MongolTextPainter.height] making sure to dispose the underlying
  /// resources. Doing this operation is expensive and should be avoided
  /// whenever it is possible to preserve the [MongolTextPainter] to paint the
  /// text or get other information about it.
  static double computeWidth({
    required TextSpan text,
    MongolTextAlign textAlign = MongolTextAlign.top,
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
    double minHeight = 0.0,
    double maxHeight = double.infinity,
  }) {
    final MongolTextPainter painter = MongolTextPainter(
      text: text,
      textAlign: textAlign,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      ellipsis: ellipsis,
    )..layout(minHeight: minHeight, maxHeight: maxHeight);

    try {
      return painter.width;
    } finally {
      painter.dispose();
    }
  }

  /// Computes the max intrinsic height of a configured [MongolTextPainter].
  ///
  /// This is a convenience method that creates a text painter with the supplied
  /// parameters, lays it out with the supplied [minHeight] and [maxHeight], and
  /// returns its [MongolTextPainter.maxIntrinsicHeight] making sure to dispose the
  /// underlying resources. Doing this operation is expensive and should be avoided
  /// whenever it is possible to preserve the [MongolTextPainter] to paint the
  /// text or get other information about it.
  static double computeMaxIntrinsicHeight({
    required TextSpan text,
    MongolTextAlign textAlign = MongolTextAlign.top,
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
    double minHeight = 0.0,
    double maxHeight = double.infinity,
  }) {
    final MongolTextPainter painter = MongolTextPainter(
      text: text,
      textAlign: textAlign,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      ellipsis: ellipsis,
    )..layout(minHeight: minHeight, maxHeight: maxHeight);

    try {
      return painter.maxIntrinsicHeight;
    } finally {
      painter.dispose();
    }
  }

  // _paragraph being null means the text needs layout because of style changes.
  // Setting _paragraph to null invalidates all the layout cache.
  //
  // The MongolTextPainter class should not aggressively invalidate the layout as long
  // as `markNeedsLayout` is not called (i.e., the layout cache is still valid).
  // See: https://github.com/flutter/flutter/issues/85108
  MongolParagraph? _paragraph;
  // Whether _paragraph contains outdated paint information and needs to be
  // rebuilt before painting.
  bool _rebuildParagraphForPaint = true;

  bool get _debugAssertTextLayoutIsValid {
    assert(!debugDisposed);
    if (_paragraph == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Text layout not available'),
        if (_debugMarkNeedsLayoutCallStack != null)
          DiagnosticsStackTrace(
              'The calls that first invalidated the text layout were',
              _debugMarkNeedsLayoutCallStack)
        else
          ErrorDescription('The TextPainter has never been laid out.')
      ]);
    }
    return true;
  }

  StackTrace? _debugMarkNeedsLayoutCallStack;

  /// Marks this text painter's layout information as dirty and removes cached
  /// information.
  ///
  /// Uses this method to notify text painter to relayout in the case of
  /// layout changes in engine. In most cases, updating text painter properties
  /// in framework will automatically invoke this method.
  void markNeedsLayout() {
    assert(() {
      if (_paragraph != null) {
        _debugMarkNeedsLayoutCallStack ??= StackTrace.current;
      }
      return true;
    }());
    _paragraph?.dispose();
    _paragraph = null;
    _lineMetricsCache = null;
    _previousCaretPosition = null;
    _previousCaretPrototype = null;
  }

  /// The (potentially styled) text to paint.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  /// This must be non-null before you call [layout].
  ///
  /// The [TextSpan] this provides is in the form of a tree that may contain
  /// multiple instances of [TextSpan]s. To obtain a plain text representation
  /// of the contents of this [MongolTextPainter], use [plainText].
  TextSpan? get text => _text;
  TextSpan? _text;
  set text(TextSpan? value) {
    assert(value == null || value.debugAssertIsValid());
    if (_text == value) {
      return;
    }
    if (_text?.style != value?.style) {
      _layoutTemplate?.dispose();
      _layoutTemplate = null;
    }

    final RenderComparison comparison = value == null
        ? RenderComparison.layout
        : _text?.compareTo(value) ?? RenderComparison.layout;

    _text = value;
    _cachedPlainText = null;

    if (comparison.index >= RenderComparison.layout.index) {
      markNeedsLayout();
    } else if (comparison.index >= RenderComparison.paint.index) {
      // Don't clear the _paragraph instance variable just yet. It still
      // contains valid layout information.
      _rebuildParagraphForPaint = true;
    }
    // Neither relayout or repaint is needed.
  }

  /// Returns a plain text version of the text to paint.
  ///
  /// This uses [TextSpan.toPlainText] to get the full contents of all nodes
  /// in the tree.
  String get plainText {
    _cachedPlainText ??= _text?.toPlainText(includeSemanticsLabels: false);
    return _cachedPlainText ?? '';
  }

  String? _cachedPlainText;

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
    if (_textScaleFactor == value) {
      return;
    }
    _textScaleFactor = value;
    markNeedsLayout();
    _layoutTemplate?.dispose();
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

  ui.ParagraphStyle _createParagraphStyle() {
    // textAlign should always be `left` because this is the style for
    // a single text run. MongolTextAlign is handled elsewhere.
    return _text!.style?.getParagraphStyle(
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          ellipsis: ellipsis,
          locale: null,
          strutStyle: null,
        ) ??
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          // Use the default font size to multiply by as MongolRichText does not
          // perform inheriting [TextStyle]s and would otherwise
          // fail to apply textScaleFactor.
          fontSize: _kDefaultFontSize * textScaleFactor,
          maxLines: maxLines,
          ellipsis: ellipsis,
          locale: null,
        );
  }

  MongolParagraph? _layoutTemplate;
  MongolParagraph _createLayoutTemplate() {
    final builder = MongolParagraphBuilder(_createParagraphStyle());
    final textStyle = text?.style;
    if (textStyle != null) {
      builder.pushStyle(textStyle);
    }
    builder.addText(' ');
    return builder.build()
      ..layout(const MongolParagraphConstraints(height: double.infinity));
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
  double get preferredLineWidth =>
      (_layoutTemplate ??= _createLayoutTemplate()).width;

  // Unfortunately, using full precision floating point here causes bad layouts
  // because floating point math isn't associative. If we add and subtract
  // padding, for example, we'll get different values when we estimate sizes and
  // when we actually compute layout because the operations will end up associated
  // differently. To work around this problem for now, we round fractional pixel
  // values up to the nearest whole pixel value. The right long-term fix is to do
  // layout using fixed precision arithmetic.
  double _applyFloatingPointHack(double layoutValue) {
    return layoutValue.ceilToDouble();
  }

  /// The height at which decreasing the height of the text would prevent it from
  /// painting itself completely within its bounds.
  ///
  /// Valid only after [layout] has been called.
  double get minIntrinsicHeight {
    assert(_debugAssertTextLayoutIsValid);
    return _applyFloatingPointHack(_paragraph!.minIntrinsicHeight);
  }

  /// The height at which increasing the height of the text no longer decreases
  /// the width.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicHeight {
    assert(_debugAssertTextLayoutIsValid);
    return _applyFloatingPointHack(_paragraph!.maxIntrinsicHeight);
  }

  /// The horizontal space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get width {
    assert(_debugAssertTextLayoutIsValid);
    return _applyFloatingPointHack(_paragraph!.width);
  }

  /// The vertical space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get height {
    assert(_debugAssertTextLayoutIsValid);
    return _applyFloatingPointHack(_paragraph!.height);
  }

  /// The amount of space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  Size get size {
    assert(_debugAssertTextLayoutIsValid);
    return Size(width, height);
  }

  /// Even though the text is rotated, it is still useful to have a baseline
  /// along which to layout objects. (For example in the MongolInputDecorator.)
  ///
  /// Valid only after [layout] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugAssertTextLayoutIsValid);
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
    assert(_debugAssertTextLayoutIsValid);
    return _paragraph!.didExceedMaxLines;
  }

  double? _lastMinHeight;
  double? _lastMaxHeight;

  // Creates a MongolParagraph using the current configurations in this class and
  // assign it to _paragraph.
  void _createParagraph() {
    assert(_paragraph == null || _rebuildParagraphForPaint);
    final TextSpan? text = this.text;
    if (text == null) {
      throw StateError(
          'MongolTextPainter.text must be set to a non-null value before using the MongolTextPainter.');
    }
    final builder = MongolParagraphBuilder(
      _createParagraphStyle(),
      textAlign: _textAlign,
      textScaleFactor: _textScaleFactor,
      maxLines: _maxLines,
      ellipsis: _ellipsis,
    );
    _addStyleToText(builder, _text!);
    assert(() {
      _debugMarkNeedsLayoutCallStack = null;
      return true;
    }());
    _paragraph = builder.build();
    _rebuildParagraphForPaint = false;
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
    if (hasStyle) builder.pushStyle(style);
    if (text != null) builder.addText(text);
    if (children != null) {
      for (final child in children) {
        _addStyleToText(builder, child);
      }
    }
    if (hasStyle) builder.pop();
  }

  void _layoutParagraph(double minHeight, double maxHeight) {
    _paragraph!.layout(MongolParagraphConstraints(height: maxHeight));
    if (minHeight != maxHeight) {
      final newHeight = maxIntrinsicHeight.clamp(minHeight, maxHeight);
      if (newHeight != _applyFloatingPointHack(_paragraph!.height)) {
        _paragraph!.layout(MongolParagraphConstraints(height: newHeight));
      }
    }
  }

  /// Computes the visual position of the glyphs for painting the text.
  ///
  /// The text will layout with a height that's as close to its max intrinsic
  /// height as possible while still being greater than or equal to `minHeight`
  /// and less than or equal to `maxHeight`.
  ///
  /// The [text] property must be non-null before this is called.
  void layout({double minHeight = 0.0, double maxHeight = double.infinity}) {
    assert(text != null,
        'MongolTextPainter.text must be set to a non-null value before using the MongolTextPainter.');
    // Return early if the current layout information is not outdated, even if
    // _needsPaint is true (in which case _paragraph will be rebuilt in paint).
    if (_paragraph != null &&
        minHeight == _lastMinHeight &&
        maxHeight == _lastMaxHeight) {
      return;
    }

    if (_rebuildParagraphForPaint || _paragraph == null) {
      _createParagraph();
    }
    _lastMinHeight = minHeight;
    _lastMaxHeight = maxHeight;
    // A change in layout invalidates the cached caret and line metrics as well.
    _lineMetricsCache = null;
    _previousCaretPosition = null;
    _previousCaretPrototype = null;
    _layoutParagraph(minHeight, maxHeight);
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
    final double? minHeight = _lastMinHeight;
    final double? maxHeight = _lastMaxHeight;
    if (_paragraph == null || minHeight == null || maxHeight == null) {
      throw StateError(
        'MongolTextPainter.paint called when text geometry was not yet calculated.\n'
        'Please call layout() before paint() to position the text before painting it.',
      );
    }

    if (_rebuildParagraphForPaint) {
      Size? debugSize;
      assert(() {
        debugSize = size;
        return true;
      }());

      _createParagraph();
      // Unfortunately we have to redo the layout using the same constraints,
      // since we've created a new MongolParagraph. But there's no extra work being
      // done: if _needsPaint is true and _paragraph is not null, the previous
      // `layout` call didn't invoke _layoutParagraph.
      _layoutParagraph(minHeight, maxHeight);
      assert(debugSize == size);
    }
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
      const newlineCodeUnit = 10;
      if (prevCodeUnit == newlineCodeUnit) {
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
    assert(_debugAssertTextLayoutIsValid);
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
    assert(_debugAssertTextLayoutIsValid);
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
    assert(_debugAssertTextLayoutIsValid);
    return _paragraph!.getBoxesForRange(
      selection.start,
      selection.end,
    );
  }

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(_debugAssertTextLayoutIsValid);
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
    assert(_debugAssertTextLayoutIsValid);
    return _paragraph!.getWordBoundary(position);
  }

  /// Returns the text range of the line at the given offset.
  ///
  /// The newline, if any, is included in the range.
  TextRange getLineBoundary(TextPosition position) {
    assert(_debugAssertTextLayoutIsValid);
    return _paragraph!.getLineBoundary(position);
  }

  List<MongolLineMetrics>? _lineMetricsCache;

  /// Returns the full list of [MongolLineMetrics] that describe in detail the various
  /// metrics of each laid out line.
  ///
  /// The [MongolLineMetrics] list is presented in the order of the lines they represent.
  /// For example, the first line is in the zeroth index.
  ///
  /// [MongolLineMetrics] contains measurements such as ascent, descent, baseline, and
  /// width for the line as a whole, and may be useful for aligning additional
  /// widgets to a particular line.
  ///
  /// Valid only after [layout] has been called.
  List<MongolLineMetrics> computeLineMetrics() {
    assert(_debugAssertTextLayoutIsValid);
    return _lineMetricsCache ??= _paragraph!.computeLineMetrics();
  }

  bool _disposed = false;

  /// Whether this object has been disposed or not.
  ///
  /// Only for use when asserts are enabled.
  bool get debugDisposed {
    bool? disposed;
    assert(() {
      disposed = _disposed;
      return true;
    }());
    return disposed ??
        (throw StateError('debugDisposed only available when asserts are on.'));
  }

  /// Releases the resources associated with this painter.
  ///
  /// After disposal this painter is unusable.
  void dispose() {
    assert(() {
      _disposed = true;
      return true;
    }());
    _layoutTemplate?.dispose();
    _layoutTemplate = null;
    _paragraph?.dispose();
    _paragraph = null;
    _text = null;
  }
}
