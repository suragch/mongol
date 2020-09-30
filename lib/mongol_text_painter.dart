// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphStyle;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/mongol_paragraph.dart';

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
    TextSpan text,
    double textScaleFactor = 1.0,
  })  : assert(text == null || text.debugAssertIsValid()),
        assert(textScaleFactor != null),
        _text = text,
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
  }

  MongolParagraph _paragraph;
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
  TextSpan get text => _text;
  TextSpan _text;
  set text(TextSpan value) {
    assert(value == null || value.debugAssertIsValid());
    if (_text == value) return;
    _text = value;
    _paragraph = null;
    _needsLayout = true;
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
    assert(value != null);
    if (_textScaleFactor == value) return;
    _textScaleFactor = value;
    markNeedsLayout();
  }

  ui.ParagraphStyle _createParagraphStyle() {
    return _text.style?.getParagraphStyle(
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr,
          textScaleFactor: textScaleFactor,
          maxLines: null,
          ellipsis: null,
          locale: null,
          strutStyle: null,
        ) ??
        ui.ParagraphStyle(
          textAlign: TextAlign.start,
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
    return _applyFloatingPointHack(_paragraph.minIntrinsicHeight);
  }

  /// The height at which increasing the height of the text no longer decreases 
  /// the width.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicHeight {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.maxIntrinsicHeight);
  }
  
  /// The horizontal space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get width {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.width);
  }

  /// The vertical space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.height);
  }

  /// The amount of space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  Size get size {
    assert(!_needsLayout);
    return Size(width, height);
  }

  double _lastMinHeight;
  double _lastMaxHeight;

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
      final MongolParagraphBuilder builder = MongolParagraphBuilder(
        _createParagraphStyle(),
        textScaleFactor: _textScaleFactor,
      );
      _addStyleToText(builder, _text);
      _paragraph = builder.build();
    }
    _lastMinHeight = minHeight;
    _lastMaxHeight = maxHeight;
    _paragraph.layout(MongolParagraphConstraints(height: maxHeight));
    if (minHeight != maxHeight) {
      final double newHeight = maxIntrinsicHeight.clamp(minHeight, maxHeight);
      if (newHeight != height)
        _paragraph.layout(MongolParagraphConstraints(height: newHeight));
    }
  }

  void _addStyleToText(
    MongolParagraphBuilder builder,
    TextSpan textSpan,
  ) {
    final style = textSpan.style;
    final text = textSpan.text;
    final children = textSpan.children;
    final bool hasStyle = style != null;
    if (hasStyle) builder.pushStyle(style);
    if (text != null) builder.addText(text);
    if (children != null) {
      for (TextSpan child in children) {
        assert(child != null);
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
    _paragraph.draw(canvas, offset);
  }
}
