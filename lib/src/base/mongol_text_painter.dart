// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show max, min;
import 'dart:ui' as ui show ParagraphStyle;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show TextBoundary, UntilPredicate;
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
        TextScaler,
        TextAffinity;
import 'package:mongol/src/base/mongol_paragraph.dart';

import 'mongol_text_align.dart';

// The default font size if none is specified. This should be kept in
// sync with the default values in text_style.dart, as well as the
// defaults set in the engine (eg, LibTxt's text_style.h, paragraph_style.h).
const double _kDefaultFontSize = 14.0;

/// The different ways of measuring the height of one or more lines of text.
///
/// See [MongolText.textHeightBasis], for example.
enum TextHeightBasis {
  /// multiline text will take up the full height given by the parent. For single
  /// line text, only the minimum amount of height needed to contain the text
  /// will be used. A common use case for this is a standard series of
  /// paragraphs.
  parent,

  /// The height will be exactly enough to contain the longest line and no
  /// longer. A common use case for this is chat bubbles.
  longestLine,
}

/// A [TextBoundary] subclass for locating word breaks.
///
/// The underlying implementation uses [UAX #29](https://unicode.org/reports/tr29/)
/// defined default word boundaries.
///
/// The default word break rules can be tailored to meet the requirements of
/// different use cases. For instance, the default rule set keeps vertical
/// whitespaces together as a single word, which may not make sense in a
/// word-counting context -- "hello    world" counts as 3 words instead of 2.
/// An example is the [moveByWordBoundary] variant, which is a tailored
/// word-break locator that more closely matches the default behavior of most
/// platforms and editors when it comes to handling text editing keyboard
/// shortcuts that move or delete word by word.
class MongolWordBoundary extends TextBoundary {
  /// Creates a [MongolWordBoundary] with the text and layout information.
  MongolWordBoundary._(this._text, this._paragraph);

  final InlineSpan _text;
  final MongolParagraph _paragraph;

  @override
  TextRange getTextBoundaryAt(int position) =>
      _paragraph.getWordBoundary(TextPosition(offset: max(position, 0)));

  // Combines two UTF-16 code units (high surrogate + low surrogate) into a
  // single code point that represents a supplementary character.
  static int _codePointFromSurrogates(int highSurrogate, int lowSurrogate) {
    assert(
      MongolTextPainter.isHighSurrogate(highSurrogate),
      'U+${highSurrogate.toRadixString(16).toUpperCase().padLeft(4, "0")}) is not a high surrogate.',
    );
    assert(
      MongolTextPainter.isLowSurrogate(lowSurrogate),
      'U+${lowSurrogate.toRadixString(16).toUpperCase().padLeft(4, "0")}) is not a low surrogate.',
    );
    const int base = 0x010000 - (0xD800 << 10) - 0xDC00;
    return (highSurrogate << 10) + lowSurrogate + base;
  }

  // The Runes class does not provide random access with a code unit offset.
  int? _codePointAt(int index) {
    final int? codeUnitAtIndex = _text.codeUnitAt(index);
    if (codeUnitAtIndex == null) {
      return null;
    }
    return switch (codeUnitAtIndex & 0xFC00) {
      0xD800 =>
        _codePointFromSurrogates(codeUnitAtIndex, _text.codeUnitAt(index + 1)!),
      0xDC00 =>
        _codePointFromSurrogates(_text.codeUnitAt(index - 1)!, codeUnitAtIndex),
      _ => codeUnitAtIndex,
    };
  }

  static bool _isNewline(int codePoint) {
    return switch (codePoint) {
      0x000A || 0x0085 || 0x000B || 0x000C || 0x2028 || 0x2029 => true,
      _ => false,
    };
  }

  bool _skipSpacesAndPunctuations(int offset, bool forward) {
    // Use code point since some punctuations are supplementary characters.
    // "inner" here refers to the code unit that's before the break in the
    // search direction (`forward`).
    final int? innerCodePoint = _codePointAt(forward ? offset - 1 : offset);
    final int? outerCodeUnit = _text.codeUnitAt(forward ? offset : offset - 1);

    // Make sure the hard break rules in UAX#29 take precedence over the ones we
    // add below. Luckily there're only 4 hard break rules for word breaks, and
    // dictionary based breaking does not introduce new hard breaks:
    // https://unicode-org.github.io/icu/userguide/boundaryanalysis/break-rules.html#word-dictionaries
    //
    // WB1 & WB2: always break at the start or the end of the text.
    final bool hardBreakRulesApply = innerCodePoint == null ||
        outerCodeUnit == null
        // WB3a & WB3b: always break before and after newlines.
        ||
        _isNewline(innerCodePoint) ||
        _isNewline(outerCodeUnit);
    return hardBreakRulesApply ||
        !RegExp(r'[\p{Space_Separator}\p{Punctuation}]', unicode: true)
            .hasMatch(String.fromCharCode(innerCodePoint));
  }

  /// Returns a [TextBoundary] suitable for handling keyboard navigation
  /// commands that change the current selection word by word.
  ///
  /// This [TextBoundary] is used by text widgets in the flutter framework to
  /// provide default implementation for text editing shortcuts, for example,
  /// "delete to the previous word".
  ///
  /// The implementation applies the same set of rules [MongolWordBoundary] uses,
  /// except that word breaks end on a space separator or a punctuation will be
  /// skipped, to match the behavior of most platforms. Additional rules may be
  /// added in the future to better match platform behaviors.
  late final TextBoundary moveByWordBoundary =
      _UntilTextBoundary(this, _skipSpacesAndPunctuations);
}

class _UntilTextBoundary extends TextBoundary {
  const _UntilTextBoundary(this._textBoundary, this._predicate);

  final UntilPredicate _predicate;
  final TextBoundary _textBoundary;

  @override
  int? getLeadingTextBoundaryAt(int position) {
    if (position < 0) {
      return null;
    }
    final int? offset = _textBoundary.getLeadingTextBoundaryAt(position);
    return offset == null || _predicate(offset, false)
        ? offset
        : getLeadingTextBoundaryAt(offset - 1);
  }

  @override
  int? getTrailingTextBoundaryAt(int position) {
    final int? offset =
        _textBoundary.getTrailingTextBoundaryAt(max(position, 0));
    return offset == null || _predicate(offset, true)
        ? offset
        : getTrailingTextBoundaryAt(offset);
  }
}

class _MongolTextLayout {
  _MongolTextLayout._(this._paragraph);

  // This field is not final because the owner MongolTextPainter could create a new
  // MongolParagraph with the exact same text layout (for example, when only the
  // color of the text is changed).
  //
  // The creator of this _MongolTextLayout is also responsible for disposing this
  // object when it's no longer needed.
  MongolParagraph _paragraph;

  /// Whether this layout has been invalidated and disposed.
  ///
  /// Only for use when asserts are enabled.
  bool get debugDisposed => _paragraph.debugDisposed;

  /// The vertical space required to paint this text.
  ///
  /// If a line ends with trailing spaces, the trailing spaces may extend
  /// outside of the horizontal paint bounds defined by [height].
  double get height => _paragraph.height;

  /// The horizontal space required to paint this text.
  double get width => _paragraph.width;

  /// The height at which decreasing the height of the text would prevent it from
  /// painting itself completely within its bounds.
  double get minIntrinsicLineExtent => _paragraph.minIntrinsicHeight;

  /// The height at which increasing the height of the text no longer decreases the width.
  ///
  /// Includes trailing spaces if any.
  double get maxIntrinsicLineExtent => _paragraph.maxIntrinsicHeight;

  /// The distance from the top edge of the topmost glyph to the bottom edge of
  /// the bottommost glyph in the paragraph.
  double get longestLine => _paragraph.longestLine;

  /// Returns the distance from the left of the text to the first baseline of the
  /// given type.
  double getDistanceToBaseline(TextBaseline baseline) {
    return switch (baseline) {
      TextBaseline.alphabetic => _paragraph.alphabeticBaseline,
      TextBaseline.ideographic => _paragraph.ideographicBaseline,
    };
  }
}

// This class stores the current text layout and the corresponding
// paintOffset/contentHeight, as well as some cached text metrics values that
// depends on the current text layout, which will be invalidated as soon as the
// text layout is invalidated.
class _TextPainterLayoutCacheWithOffset {
  _TextPainterLayoutCacheWithOffset(this.layout, this.textAlignment,
      double minHeight, double maxHeight, TextHeightBasis heightBasis)
      : contentHeight =
            _contentHeightFor(minHeight, maxHeight, heightBasis, layout),
        assert(textAlignment >= 0.0 && textAlignment <= 1.0);

  final _MongolTextLayout layout;

  // The content height the text painter should report in MongolTextPainter.height.
  // This is also used to compute `paintOffset`
  double contentHeight;

  // The effective text alignment in the MongolTextPainter's canvas. The value is
  // within the [0, 1] interval: 0 for top aligned and 1 for bottom aligned.
  final double textAlignment;

  // The paintOffset of the `paragraph` in the MongolTextPainter's canvas.
  //
  // It's coordinate values are guaranteed to not be NaN.
  Offset get paintOffset {
    if (textAlignment == 0) {
      return Offset.zero;
    }
    if (!paragraph.height.isFinite) {
      return const Offset(0.0, double.infinity);
    }
    final double dy = textAlignment * (contentHeight - paragraph.height);
    assert(!dy.isNaN);
    return Offset(0, dy);
  }

  MongolParagraph get paragraph => layout._paragraph;

  static double _contentHeightFor(double minHeight, double maxHeight,
      TextHeightBasis heightBasis, _MongolTextLayout layout) {
    return switch (heightBasis) {
      TextHeightBasis.longestLine =>
        clampDouble(layout.longestLine, minHeight, maxHeight),
      TextHeightBasis.parent =>
        clampDouble(layout.maxIntrinsicLineExtent, minHeight, maxHeight),
    };
  }

  // Try to resize the contentHeight to fit the new input constraints, by just
  // adjusting the paint offset (so no line-breaking changes needed).
  //
  // Returns false if the new constraints require re-computing the line breaks,
  // in which case no side effects will occur.
  bool _resizeToFit(
      double minHeight, double maxHeight, TextHeightBasis heightBasis) {
    assert(layout.maxIntrinsicLineExtent.isFinite);
    // The assumption here is that if a MongolParagraph's height is already >= its
    // maxIntrinsicHeight, further increasing the input height does not change its
    // layout (but may change the paint offset if it's not top-aligned). This is
    // true even for MongolTextAlign.justify: when height >= maxIntrinsicHeight
    // MongolTextAlign.justify will behave exactly the same as MongolTextAlign.start.
    //
    // An exception to this is when the text is not top-aligned, and the input
    // height is double.infinity. Since the resulting MongolParagraph will have a height
    // of double.infinity, and to make the text visible the paintOffset.dy is
    // bound to be double.negativeInfinity, which invalidates all arithmetic
    // operations.
    final double newContentHeight =
        _contentHeightFor(minHeight, maxHeight, heightBasis, layout);
    if (newContentHeight == contentHeight) {
      return true;
    }
    assert(minHeight <= maxHeight);
    // Always needsLayout when the current paintOffset and the paragraph height are not finite.
    if (!paintOffset.dy.isFinite &&
        !paragraph.height.isFinite &&
        minHeight.isFinite) {
      assert(paintOffset.dy == double.infinity);
      assert(paragraph.height == double.infinity);
      return false;
    }
    final double maxIntrinsicHeight = paragraph.maxIntrinsicHeight;
    if ((paragraph.height - maxIntrinsicHeight) > -precisionErrorTolerance &&
        (maxHeight - maxIntrinsicHeight) > -precisionErrorTolerance) {
      // Adjust the paintOffset and contentWidth to the new input constraints.
      contentHeight = newContentHeight;
      return true;
    }
    return false;
  }

  // ---- Cached Values ----

  List<MongolLineMetrics> get lineMetrics =>
      _cachedLineMetrics ??= paragraph.computeLineMetrics();
  List<MongolLineMetrics>? _cachedLineMetrics;

  // Holds the TextPosition the last caret metrics were computed with. When new
  // values are passed in, we recompute the caret metrics only as necessary.
  TextPosition? _previousCaretPosition;
}

/// This is used to cache and pass the computed metrics regarding the
/// caret's size and position. This is preferred due to the expensive
/// nature of the calculation.
///
// A _CaretMetrics is either a _LineCaretMetrics or an _EmptyLineCaretMetrics.
@immutable
sealed class _CaretMetrics {}

/// The _CaretMetrics for carets located in a non-empty line. Carets located in a
/// non-empty line are associated with a glyph within the same line.
final class _LineCaretMetrics implements _CaretMetrics {
  const _LineCaretMetrics({required this.offset, required this.fullWidth});

  /// The offset of the top left corner of the caret from the top left
  /// corner of the paragraph.
  final Offset offset;

  /// The full width of the glyph at the caret position.
  final double fullWidth;
}

/// The _CaretMetrics for carets located in an empty line (when the text is
/// empty, or the caret is between two a newline characters).
final class _EmptyLineCaretMetrics implements _CaretMetrics {
  const _EmptyLineCaretMetrics({required this.lineHorizontalOffset});

  /// The x offset of the unoccupied line.
  final double lineHorizontalOffset;
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
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    double textScaleFactor = 1.0,
    TextScaler textScaler = TextScaler.noScaling,
    int? maxLines,
    String? ellipsis,
    TextHeightBasis textHeightBasis = TextHeightBasis.parent,
  })  : assert(text == null || text.debugAssertIsValid()),
        assert(maxLines == null || maxLines > 0),
        assert(
            textScaleFactor == 1.0 ||
                identical(textScaler, TextScaler.noScaling),
            'Use textScaler instead.'),
        _text = text,
        _textAlign = textAlign,
        _textScaler = textScaler == TextScaler.noScaling
            ? TextScaler.linear(textScaleFactor)
            : textScaler,
        _maxLines = maxLines,
        _ellipsis = ellipsis,
        _textHeightBasis = textHeightBasis;

  /// Computes the height of a configured [MongolTextPainter].
  ///
  /// This is a convenience method that creates a text painter with the supplied
  /// parameters, lays it out with the supplied [minHeight] and [maxHeight], and
  /// returns its [MongolTextPainter.height] making sure to dispose the underlying
  /// resources. Doing this operation is expensive and should be avoided
  /// whenever it is possible to preserve the [MongolTextPainter] to paint the
  /// text or get other information about it.
  static double computeHeight({
    required TextSpan text,
    MongolTextAlign textAlign = MongolTextAlign.top,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    double textScaleFactor = 1.0,
    TextScaler textScaler = TextScaler.noScaling,
    int? maxLines,
    String? ellipsis,
    TextHeightBasis textHeightBasis = TextHeightBasis.parent,
    double minHeight = 0.0,
    double maxHeight = double.infinity,
  }) {
    assert(
      textScaleFactor == 1.0 || identical(textScaler, TextScaler.noScaling),
      'Use textScaler instead.',
    );
    final MongolTextPainter painter = MongolTextPainter(
      text: text,
      textAlign: textAlign,
      textScaler: textScaler == TextScaler.noScaling
          ? TextScaler.linear(textScaleFactor)
          : textScaler,
      maxLines: maxLines,
      ellipsis: ellipsis,
      textHeightBasis: textHeightBasis,
    )..layout(minHeight: minHeight, maxHeight: maxHeight);

    try {
      return painter.height;
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
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    double textScaleFactor = 1.0,
    TextScaler textScaler = TextScaler.noScaling,
    int? maxLines,
    String? ellipsis,
    TextHeightBasis textHeightBasis = TextHeightBasis.parent,
    double minHeight = 0.0,
    double maxHeight = double.infinity,
  }) {
    assert(
      textScaleFactor == 1.0 || identical(textScaler, TextScaler.noScaling),
      'Use textScaler instead.',
    );
    final MongolTextPainter painter = MongolTextPainter(
      text: text,
      textAlign: textAlign,
      textScaler: textScaler == TextScaler.noScaling
          ? TextScaler.linear(textScaleFactor)
          : textScaler,
      maxLines: maxLines,
      ellipsis: ellipsis,
      textHeightBasis: textHeightBasis,
    )..layout(minHeight: minHeight, maxHeight: maxHeight);

    try {
      return painter.maxIntrinsicHeight;
    } finally {
      painter.dispose();
    }
  }

  // Whether textHeightBasis has changed after the most recent `layout` call.
  bool _debugNeedsRelayout = true;
  // The result of the most recent `layout` call.
  _TextPainterLayoutCacheWithOffset? _layoutCache;

  // Whether _layoutCache contains outdated paint information and needs to be
  // updated before painting.
  //
  // MongolParagraph is entirely immutable, thus text style changes that can affect
  // layout and those who can't both require the MongolParagraph object being
  // recreated. The caller may not call `layout` again after text color is
  // updated. See: https://github.com/flutter/flutter/issues/85108
  bool _rebuildParagraphForPaint = true;
  // `_layoutCache`'s input height. This is only needed because there's no API to
  // create paint only updates that don't affect the text layout (e.g., changing
  // the color of the text), on ui.Paragraph or ui.ParagraphBuilder.
  double _inputHeight = double.nan;

  bool get _debugAssertTextLayoutIsValid {
    assert(!debugDisposed);
    if (_layoutCache == null) {
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
      if (_layoutCache != null) {
        _debugMarkNeedsLayoutCallStack ??= StackTrace.current;
      }
      return true;
    }());
    _layoutCache?.paragraph.dispose();
    _layoutCache = null;
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

  /// Deprecated. Will be removed in a future version of Flutter. Use
  /// [textScaler] instead.
  ///
  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  double get textScaleFactor => textScaler.textScaleFactor;
  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  set textScaleFactor(double value) {
    textScaler = TextScaler.linear(value);
  }

  /// The font scaling strategy to use when laying out and rendering the text.
  ///
  /// The value usually comes from [MediaQuery.textScalerOf], which typically
  /// reflects the user-specified text scaling value in the platform's
  /// accessibility settings. The [TextStyle.fontSize] of the text will be
  /// adjusted by the [TextScaler] before the text is laid out and rendered.
  ///
  /// The [layout] method must be called after [textScaler] changes as it
  /// affects the text layout.
  TextScaler get textScaler => _textScaler;
  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (value == _textScaler) {
      return;
    }
    _textScaler = value;
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

  /// Defines how to measure the height of the rendered text.
  TextHeightBasis get textHeightBasis => _textHeightBasis;
  TextHeightBasis _textHeightBasis;
  set textHeightBasis(TextHeightBasis value) {
    if (_textHeightBasis == value) {
      return;
    }
    assert(() {
      return _debugNeedsRelayout = true;
    }());
    _textHeightBasis = value;
  }

  ui.ParagraphStyle _createParagraphStyle() {
    // textAlign should always be `left` because this is the style for
    // a single text run. MongolTextAlign is handled elsewhere.
    return _text!.style?.getParagraphStyle(
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
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
          fontSize: textScaler.scale(_kDefaultFontSize),
          maxLines: maxLines,
          ellipsis: ellipsis,
          locale: null,
        );
  }

  MongolParagraph? _layoutTemplate;
  MongolParagraph _createLayoutTemplate() {
    final builder = MongolParagraphBuilder(_createParagraphStyle());
    // MongolParagraphBuilder will handle converting the painter TextStyle to
    // the ui.TextStyle as well as applying the text scaler.
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

  /// The height at which decreasing the height of the text would prevent it from
  /// painting itself completely within its bounds.
  ///
  /// Valid only after [layout] has been called.
  double get minIntrinsicHeight {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.minIntrinsicLineExtent;
  }

  /// The height at which increasing the height of the text no longer decreases
  /// the width.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicHeight {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.maxIntrinsicLineExtent;
  }

  /// The vertical space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get height {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    return _layoutCache!.contentHeight;
  }

  /// The horizontal space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get width {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.width;
  }

  /// The amount of space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  Size get size {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    return Size(width, height);
  }

  /// Even though the text is rotated, it is still useful to have a baseline
  /// along which to layout objects. (For example in the MongolInputDecorator.)
  ///
  /// Valid only after [layout] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.getDistanceToBaseline(baseline);
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
    return _layoutCache!.paragraph.didExceedMaxLines;
  }

  // Creates a MongolParagraph using the current configurations in this class and
  // assign it to _paragraph.
  MongolParagraph _createParagraph(InlineSpan text) {
    final builder = MongolParagraphBuilder(
      _createParagraphStyle(),
      textAlign: _textAlign,
      textScaler: _textScaler,
      maxLines: _maxLines,
      ellipsis: _ellipsis,
    );
    _addStyleToText(builder, text);
    assert(() {
      _debugMarkNeedsLayoutCallStack = null;
      return true;
    }());
    _rebuildParagraphForPaint = false;
    return builder.build();
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

  /// Computes the visual position of the glyphs for painting the text.
  ///
  /// The text will layout with a height that's as close to its max intrinsic
  /// height (or its longest line, if [textHeightBasis] is set to
  /// [TextHeightBasis.parent]) as possible while still being greater than or
  /// equal to `minHeight` and less than or equal to `maxHeight`.
  ///
  /// The [text] property must be non-null before this is called.
  void layout({double minHeight = 0.0, double maxHeight = double.infinity}) {
    assert(!maxHeight.isNaN);
    assert(!minHeight.isNaN);
    assert(() {
      _debugNeedsRelayout = false;
      return true;
    }());

    final _TextPainterLayoutCacheWithOffset? cachedLayout = _layoutCache;
    if (cachedLayout != null &&
        cachedLayout._resizeToFit(minHeight, maxHeight, textHeightBasis)) {
      return;
    }

    final TextSpan? text = this.text;
    if (text == null) {
      throw StateError(
          'MongolTextPainter.text must be set to a non-null value before using the MongolTextPainter.');
    }

    final double paintOffsetAlignment = _computePaintOffsetFraction(textAlign);
    // Try to avoid laying out the paragraph with maxHeight=double.infinity
    // when the text is not top-aligned, so we don't have to deal with an
    // infinite paint offset.
    final bool adjustMaxHeight =
        !maxHeight.isFinite && paintOffsetAlignment != 0;
    final double? adjustedMaxHeight = !adjustMaxHeight
        ? maxHeight
        : cachedLayout?.layout.maxIntrinsicLineExtent;
    _inputHeight = adjustedMaxHeight ?? maxHeight;

    // Only rebuild the paragraph when there're layout changes, even when
    // `_rebuildParagraphForPaint` is true. It's best to not eagerly rebuild
    // the paragraph to avoid the extra work, because:
    // 1. the text color could change again before `paint` is called (so one of
    //    the paragraph rebuilds is unnecessary)
    // 2. the user could be measuring the text layout so `paint` will never be
    //    called.
    final paragraph = (cachedLayout?.paragraph ?? _createParagraph(text))
      ..layout(MongolParagraphConstraints(height: _inputHeight));
    final newLayoutCache = _TextPainterLayoutCacheWithOffset(
      _MongolTextLayout._(paragraph),
      paintOffsetAlignment,
      minHeight,
      maxHeight,
      textHeightBasis,
    );
    // Call layout again if newLayoutCache had an infinite paint offset.
    // This is not as expensive as it seems, line breaking is relatively cheap
    // as compared to shaping.
    if (adjustedMaxHeight == null && minHeight.isFinite) {
      assert(maxHeight.isInfinite);
      final double newInputHeight =
          newLayoutCache.layout.maxIntrinsicLineExtent;
      paragraph.layout(MongolParagraphConstraints(height: newInputHeight));
      _inputHeight = newInputHeight;
    }
    _layoutCache = newLayoutCache;
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
    final _TextPainterLayoutCacheWithOffset? layoutCache = _layoutCache;
    if (layoutCache == null) {
      throw StateError(
        'MongolTextPainter.paint called when text geometry was not yet calculated.\n'
        'Please call layout() before paint() to position the text before painting it.',
      );
    }

    if (!layoutCache.paintOffset.dy.isFinite ||
        !layoutCache.paintOffset.dx.isFinite) {
      return;
    }

    if (_rebuildParagraphForPaint) {
      Size? debugSize;
      assert(() {
        debugSize = size;
        return true;
      }());

      final paragraph = layoutCache.paragraph;
      // Unfortunately even if we know that there is only paint changes, there's
      // no API to only make those updates so the paragraph has to be recreated
      // and re-laid out.
      assert(!_inputHeight.isNaN);
      layoutCache.layout._paragraph = _createParagraph(text!)
        ..layout(MongolParagraphConstraints(height: _inputHeight));
      assert(paragraph.height == layoutCache.layout._paragraph.height);
      paragraph.dispose();
      assert(debugSize == size);
    }
    assert(!_rebuildParagraphForPaint);
    layoutCache.paragraph.draw(canvas, offset + layoutCache.paintOffset);
  }

  // Returns true if value falls in the valid range of the UTF16 encoding.
  static bool _isUTF16(int value) {
    return value >= 0x0 && value <= 0xFFFFF;
  }

  /// Returns true iff the given value is a valid UTF-16 high (first) surrogate.
  /// The value must be a UTF-16 code unit, meaning it must be in the range
  /// 0x0000-0xFFFF.
  ///
  /// See also:
  ///   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
  ///   * [isLowSurrogate], which checks the same thing for low (second)
  /// surrogates.
  static bool isHighSurrogate(int value) {
    assert(_isUTF16(value));
    return value & 0xFC00 == 0xD800;
  }

  /// Returns true iff the given value is a valid UTF-16 low (second) surrogate.
  /// The value must be a UTF-16 code unit, meaning it must be in the range
  /// 0x0000-0xFFFF.
  ///
  /// See also:
  ///   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
  ///   * [isHighSurrogate], which checks the same thing for high (first)
  /// surrogates.
  static bool isLowSurrogate(int value) {
    assert(_isUTF16(value));
    return value & 0xFC00 == 0xDC00;
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
    final int? nextCodeUnit = _text!.codeUnitAt(offset);
    if (nextCodeUnit == null) {
      return null;
    }
    return isHighSurrogate(nextCodeUnit) ? offset + 2 : offset + 1;
  }

  /// Returns the closest offset before `offset` at which the input cursor can
  /// be positioned.
  int? getOffsetBefore(int offset) {
    final int? prevCodeUnit = _text!.codeUnitAt(offset - 1);
    if (prevCodeUnit == null) {
      return null;
    }
    return isLowSurrogate(prevCodeUnit) ? offset - 2 : offset - 1;
  }

  // Unicode value for a zero width joiner character.
  static const int _zwjUtf16 = 0x200d;

  // Get the caret metrics (in logical pixels) based off the near edge of the
  // character upstream from the given string offset.
  _CaretMetrics? _getMetricsFromUpstream(int offset) {
    assert(offset >= 0);
    final int plainTextLength = plainText.length;
    if (plainTextLength == 0 || offset > plainTextLength) {
      return null;
    }
    final int prevCodeUnit = plainText.codeUnitAt(max(0, offset - 1));

    // If the upstream character is a newline, cursor is at start of next line
    const int newlineCodeUnit = 10;

    // Check for multi-code-unit glyphs such as emojis or zero width joiner.
    final bool needsSearch = isHighSurrogate(prevCodeUnit) ||
        isLowSurrogate(prevCodeUnit) ||
        _text!.codeUnitAt(offset) == _zwjUtf16 ||
        _isUnicodeDirectionality(prevCodeUnit);
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<Rect> boxes = <Rect>[];
    while (boxes.isEmpty) {
      final int prevRuneOffset = offset - graphemeClusterLength;
      boxes = _layoutCache!.paragraph
          .getBoxesForRange(max(0, prevRuneOffset), offset);
      // When the range does not include a full cluster, no boxes will be returned.
      if (boxes.isEmpty) {
        // When we are at the beginning of the line, a non-surrogate position will
        // return empty boxes. We break and try from downstream instead.
        if (!needsSearch && prevCodeUnit == newlineCodeUnit) {
          break; // Only perform one iteration if no search is required.
        }
        if (prevRuneOffset < -plainTextLength) {
          break; // Stop iterating when beyond the max length of the text.
        }
        // Multiply by two to log(n) time cover the entire text span. This allows
        // faster discovery of very long clusters and reduces the possibility
        // of certain large clusters taking much longer than others, which can
        // cause jank.
        graphemeClusterLength *= 2;
        continue;
      }

      // Try to identify the box nearest the offset.  This logic works when
      // there's just one box, and when all boxes have the same direction.
      final box = boxes.last;
      return prevCodeUnit == newlineCodeUnit
          ? _EmptyLineCaretMetrics(lineHorizontalOffset: box.right)
          : _LineCaretMetrics(
              offset: Offset(box.left, box.bottom),
              fullWidth: box.right - box.left,
            );
    }
    return null;
  }

  // Get the caret metrics (in logical pixels) based off the near edge of the
  // character downstream from the given string offset.
  _CaretMetrics? _getMetricsFromDownstream(int offset) {
    assert(offset >= 0);
    final int plainTextLength = plainText.length;
    if (plainTextLength == 0) {
      return null;
    }
    // We cap the offset at the final index of plain text.
    final int nextCodeUnit =
        plainText.codeUnitAt(min(offset, plainTextLength - 1));

    // Check for multi-code-unit glyphs such as emojis or zero width joiner
    final bool needsSearch = isHighSurrogate(nextCodeUnit) ||
        isLowSurrogate(nextCodeUnit) ||
        nextCodeUnit == _zwjUtf16 ||
        _isUnicodeDirectionality(nextCodeUnit);
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<Rect> boxes = <Rect>[];
    while (boxes.isEmpty) {
      final int nextRuneOffset = offset + graphemeClusterLength;
      boxes = _layoutCache!.paragraph.getBoxesForRange(offset, nextRuneOffset);
      // When the range does not include a full cluster, no boxes will be returned.
      if (boxes.isEmpty) {
        // When we are at the end of the line, a non-surrogate position will
        // return empty boxes. We break and try from upstream instead.
        if (!needsSearch) {
          break; // Only perform one iteration if no search is required.
        }
        if (nextRuneOffset >= plainTextLength << 1) {
          break; // Stop iterating when beyond the max length of the text.
        }
        // Multiply by two to log(n) time cover the entire text span. This allows
        // faster discovery of very long clusters and reduces the possibility
        // of certain large clusters taking much longer than others, which can
        // cause jank.
        graphemeClusterLength *= 2;
        continue;
      }

      // Try to identify the box nearest the offset.  This logic works when
      // there's just one box, and when all boxes have the same direction.
      final box = boxes.first;
      return _LineCaretMetrics(
        offset: Offset(box.left, box.top),
        fullWidth: box.right - box.left,
      );
    }
    return null;
  }

  static double _computePaintOffsetFraction(MongolTextAlign textAlign) {
    return switch (textAlign) {
      MongolTextAlign.top => 0.0,
      MongolTextAlign.bottom => 1.0,
      MongolTextAlign.center => 0.5,
      MongolTextAlign.justify => 0.0,
    };
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout] has been called.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    final _CaretMetrics caretMetrics;
    final _TextPainterLayoutCacheWithOffset layoutCache = _layoutCache!;
    if (position.offset < 0) {
      caretMetrics = const _EmptyLineCaretMetrics(lineHorizontalOffset: 0);
    } else {
      caretMetrics = _computeCaretMetrics(position);
    }

    final Offset rawOffset;
    switch (caretMetrics) {
      case _EmptyLineCaretMetrics(:final double lineHorizontalOffset):
        final double paintOffsetAlignment =
            _computePaintOffsetFraction(textAlign);
        // The full height is not (height - caretPrototype.height)
        // because MongolRenderEditable reserves cursor height on the bottom. Ideally this
        // should be handled by MongolRenderEditable instead.
        final double dy = paintOffsetAlignment == 0
            ? 0
            : paintOffsetAlignment * layoutCache.contentHeight;
        return Offset(lineHorizontalOffset, dy);
      case _LineCaretMetrics(:final Offset offset):
        rawOffset = offset;
    }
    // If offset.dy is outside of the advertised content area, then the associated
    // glyph cluster belongs to a trailing newline character. Ideally the behavior
    // should be handled by higher-level implementations (for instance,
    // MongolRenderEditable reserves height for showing the caret, it's best to handle
    // the clamping there).
    final double adjustedDy = clampDouble(
        rawOffset.dy + layoutCache.paintOffset.dy,
        0,
        layoutCache.contentHeight);
    return Offset(rawOffset.dx + layoutCache.paintOffset.dx, adjustedDy);
  }

  /// Returns the strut bounded width of the glyph at the given `position`.
  ///
  /// Valid only after [layout] has been called.
  double? getFullWidthForCaret(TextPosition position, Rect caretPrototype) {
    if (position.offset < 0) {
      return null;
    }
    return switch (_computeCaretMetrics(position)) {
      _LineCaretMetrics(:final double fullWidth) => fullWidth,
      _EmptyLineCaretMetrics() => null,
    };
  }

  // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
  // [getFullWidthForCaret] in a row without performing redundant and expensive
  // get rect calls to the paragraph.
  late _CaretMetrics _caretMetrics;

  // Checks if the [position] and [caretPrototype] have changed from the cached
  // version and recomputes the metrics required to position the caret.
  _CaretMetrics _computeCaretMetrics(TextPosition position) {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset cachedLayout = _layoutCache!;
    if (position == cachedLayout._previousCaretPosition) {
      return _caretMetrics;
    }
    final int offset = position.offset;
    final _CaretMetrics? metrics = switch (position.affinity) {
      TextAffinity.upstream =>
        _getMetricsFromUpstream(offset) ?? _getMetricsFromDownstream(offset),
      TextAffinity.downstream =>
        _getMetricsFromDownstream(offset) ?? _getMetricsFromUpstream(offset),
    };
    // Cache the input parameters to prevent repeat work later.
    cachedLayout._previousCaretPosition = position;
    return _caretMetrics =
        metrics ?? const _EmptyLineCaretMetrics(lineHorizontalOffset: 0);
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// The [selection] must be a valid range (with [TextSelection.isValid] true).
  ///
  /// Leading or trailing newline characters will be represented by zero-height
  /// `Rect`s.
  ///
  /// The method only returns `Rect`s of glyphs that are entirely enclosed by
  /// the given `selection`: a multi-code-unit glyph will be excluded if only
  /// part of its code units are in `selection`.
  List<Rect> getBoxesForSelection(TextSelection selection) {
    assert(_debugAssertTextLayoutIsValid);
    assert(selection.isValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset cachedLayout = _layoutCache!;
    final Offset offset = cachedLayout.paintOffset;
    if (!offset.dy.isFinite || !offset.dx.isFinite) {
      return <Rect>[];
    }
    final boxes = cachedLayout.paragraph.getBoxesForRange(
      selection.start,
      selection.end,
    );
    return offset == Offset.zero
        ? boxes
        : boxes
            .map((Rect box) => _shiftTextBox(box, offset))
            .toList(growable: false);
  }

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset cachedLayout = _layoutCache!;
    return cachedLayout.paragraph
        .getPositionForOffset(offset - cachedLayout.paintOffset);
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
    return _layoutCache!.paragraph.getWordBoundary(position);
  }

  /// Returns a [TextBoundary] that can be used to perform word boundary analysis
  /// on the current [text].
  ///
  /// This [TextBoundary] uses word boundary rules defined in [Unicode Standard
  /// Annex #29](http://www.unicode.org/reports/tr29/#Word_Boundaries).
  ///
  /// Currently word boundary analysis can only be performed after [layout]
  /// has been called.
  MongolWordBoundary get wordBoundaries =>
      MongolWordBoundary._(text!, _layoutCache!.paragraph);

  /// Returns the text range of the line at the given offset.
  ///
  /// The newline (if any) is not returned as part of the range.
  TextRange getLineBoundary(TextPosition position) {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.paragraph.getLineBoundary(position);
  }

  static MongolLineMetrics _shiftLineMetrics(
      MongolLineMetrics metrics, Offset offset) {
    assert(offset.dx.isFinite);
    assert(offset.dy.isFinite);
    return MongolLineMetrics(
      hardBreak: metrics.hardBreak,
      ascent: metrics.ascent,
      descent: metrics.descent,
      unscaledAscent: metrics.unscaledAscent,
      height: metrics.height,
      width: metrics.width,
      top: metrics.top + offset.dy,
      baseline: metrics.baseline + offset.dx,
      lineNumber: metrics.lineNumber,
    );
  }

  static Rect _shiftTextBox(Rect box, Offset offset) {
    assert(offset.dx.isFinite);
    assert(offset.dy.isFinite);
    return Rect.fromLTRB(
      box.left + offset.dx,
      box.top + offset.dy,
      box.right + offset.dx,
      box.bottom + offset.dy,
    );
  }

  /// Returns the full list of [MongolLineMetrics] that describe in detail the various
  /// metrics of each laid out line.
  ///
  /// The [MongolLineMetrics] list is presented in the order of the lines they represent.
  /// For example, the first line is in the zeroth index.
  ///
  /// [MongolLineMetrics] contains measurements such as ascent, descent, baseline, and
  /// height for the line as a whole, and may be useful for aligning additional
  /// widgets to a particular line.
  ///
  /// Valid only after [layout] has been called.
  List<MongolLineMetrics> computeLineMetrics() {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset layout = _layoutCache!;
    final Offset offset = layout.paintOffset;
    if (!offset.dy.isFinite || !offset.dx.isFinite) {
      return const <MongolLineMetrics>[];
    }
    final List<MongolLineMetrics> rawMetrics = layout.lineMetrics;
    return offset == Offset.zero
        ? rawMetrics
        : rawMetrics
            .map((MongolLineMetrics metrics) =>
                _shiftLineMetrics(metrics, offset))
            .toList(growable: false);
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
    _layoutCache?.paragraph.dispose();
    _layoutCache = null;
    _text = null;
  }
}
