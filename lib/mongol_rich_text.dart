// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'mongol_text_painter.dart';

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
    this.autoRotate = true,
  })  : assert(text != null),
        assert(textScaleFactor != null),
        assert(autoRotate != null),
        super(key: key);
        
  /// The text to display in this widget.
  final TextSpan text;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// Whether to automatically rotate any emoji and CJK characters.
  /// 
  /// The default is `true`.
  /// 
  /// If `true` then any emoji and CJK characters that appear in the string
  /// will be rotated so that they are in the correct orientation in a vertical
  /// orientation. If `false` then the emoji and CJK characters will appear in
  /// the same orientation as Latin text.
  /// 
  /// One reason to set this to false is if you want to handle special rotation
  /// yourself using a [MongolTextSpan]. In this way you could rotate numbers
  /// like `2` or `22` but not `222`.
  final bool autoRotate;

  @override
  MongolRenderParagraph createRenderObject(BuildContext context) {
    
    return MongolRenderParagraph(
      text,
      textScaleFactor: textScaleFactor,
      autoRotate: autoRotate,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MongolRenderParagraph renderObject) {
    renderObject
      ..text = text
      ..textScaleFactor = textScaleFactor
      ..autoRotate = autoRotate;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text.toPlainText()));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties.add(FlagProperty('autoRotate', value: autoRotate, ifTrue: 'auto rotating emoji and CJK characters', ifFalse: 'not auto rotating emoji or CJK characters', showName: true));
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
    bool autoRotate = true,
  })  : assert(text != null),
        assert(textScaleFactor != null),
        assert(autoRotate != null),
        _textPainter = MongolTextPainter(
          text: text,
          textScaleFactor: textScaleFactor,
        );

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData) {
      child.parentData = TextParentData();
    }
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

  /// Whether to automatically rotate any emoji and CJK characters.
  /// 
  /// If `true` then any emoji and CJK characters that appear in the string
  /// will be rotated so that they are in the correct orientation in a vertical
  /// orientation. If `false` then the emoji and CJK characters will appear in
  /// the same orientation as Latin text.
  bool get autoRotate => _textPainter.autoRotate;
  set autoRotate(bool value) {
    assert(value != null);
    if (_textPainter.autoRotate == value) return;
    _textPainter.autoRotate = value;
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
    final offset = entry.localPosition;
    final position = _textPainter.getPositionForOffset(offset);
    final span = _textPainter.text.getSpanForPosition(position);
    if (span == null) {
      return;
    }
    if (span is TextSpan) {
      span.recognizer?.addPointer(event as PointerDownEvent);
    }
  }

  @override
  void performLayout() {
    _layoutTextWithConstraints(constraints);
    final textSize = _textPainter.size;
    size = constraints.constrain(textSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _layoutTextWithConstraints(constraints);
    final canvas = context.canvas;
    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final paint = Paint()..color = debugCurrentRepaintColor.toColor();
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
