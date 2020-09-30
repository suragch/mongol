// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'mongol_text_painter.dart';
import 'mongol_font.dart';

// Based on RichText of Flutter version 1.5. After that RichText became a
// MultiChildRenderObjectWidget in order to support InlineSpans.
class MongolRichText extends LeafRenderObjectWidget {
  /// Creates a paragraph of rich text in vertical orientation for traditional
  /// Mongolian.
  ///
  /// The [text] argument must not be null.
  const MongolRichText({
    Key key,
    @required this.text,
    this.textScaleFactor = 1.0,
  })  : assert(text != null),
        assert(textScaleFactor != null),
        super(key: key);

  /// The text to display in this widget.
  final TextSpan text;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  @override
  MongolRenderParagraph createRenderObject(BuildContext context) {
    
    return MongolRenderParagraph(
      _textWithMongolFont(),
      textScaleFactor: textScaleFactor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MongolRenderParagraph renderObject) {
    renderObject
      ..text = _textWithMongolFont()
      ..textScaleFactor = textScaleFactor;
  }

  TextSpan _textWithMongolFont() {
    if (text.style == null || text.style.fontFamily == null) {
      return TextSpan(
        style: TextStyle(fontFamily: MongolFont.defaultFont),
        children: [text],
      );
    }
    return text;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text.toPlainText()));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
  }
}

/// A render object that displays a paragraph of vertical Mongolian text.
class MongolRenderParagraph extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextParentData>,
        RelayoutWhenSystemFontsChangeMixin {
  /// Creates a vertical paragraph render object.
  ///
  /// The [text] argument must not be null.
  MongolRenderParagraph(
    TextSpan text, {
    double textScaleFactor = 1.0,
  })  : assert(text != null),
        assert(textScaleFactor != null),
        _textPainter = MongolTextPainter(
          text: text,
          textScaleFactor: textScaleFactor,
        );

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData)
      child.parentData = TextParentData();
  }

  final MongolTextPainter _textPainter;

  /// The text to display
  TextSpan get text => _textPainter.text;
  set text(TextSpan value) {
    switch (_textPainter.text.compareTo(value)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        return;
      case RenderComparison.paint:
        _textPainter.text = value;
        markNeedsPaint();
        break;
      case RenderComparison.layout:
        _textPainter.text = value;
        markNeedsLayout();
        break;
    }
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value) return;
    _textPainter.textScaleFactor = value;
    markNeedsLayout();
  }

  void _layoutText({
    double minHeight = 0.0,
    double maxHeight = double.infinity,
  }) {
    _textPainter.layout(
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  void _layoutTextWithConstraints(BoxConstraints constraints) {
    _layoutText(
      minHeight: constraints.minHeight,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _layoutText();
    return _textPainter.minIntrinsicHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _layoutText();
    return _textPainter.maxIntrinsicHeight;
  }

  double _computeIntrinsicWidth(double height) {
    _layoutText(minHeight: height, maxHeight: height);
    return _textPainter.width;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(height);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    _layoutTextWithConstraints(constraints);
    // Since the text is rotated it doesn't make sense to use the rotated
    // text baseline because this is used for aligning with other widgets.
    // Instead we will return the base of the widget.
    return _textPainter.height;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is! PointerDownEvent) return;
    _layoutTextWithConstraints(constraints);
    // final Offset offset = entry.localPosition;
    // final TextPosition position = _textPainter.getPositionForOffset(offset);
    // TODO: When supporting multiple spans, need to get span from painter.
    final TextPosition position = TextPosition(offset: 0);
    final TextSpan span = _textPainter.text.getSpanForPosition(position);
    span?.recognizer?.addPointer(event);
  }

  @override
  void performLayout() {
    _layoutTextWithConstraints(constraints);
    final Size textSize = _textPainter.size;
    size = constraints.constrain(textSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _layoutTextWithConstraints(constraints);
    final Canvas canvas = context.canvas;
    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final Paint paint = Paint()..color = debugCurrentRepaintColor.toColor();
        canvas.drawRect(offset & size, paint);
      }
      return true;
    }());

    _textPainter.paint(canvas, offset);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
          name: 'text', style: DiagnosticsTreeStyle.transition)
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
  }
}
