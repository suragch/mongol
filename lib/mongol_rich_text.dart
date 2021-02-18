// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'mongol_text_painter.dart';

/// A string of rich text in vertical Mongolian layout.
///
/// Based on RichText of Flutter version 1.5. After that RichText became a
/// MultiChildRenderObjectWidget in order to support InlineSpans.
///
/// The [MongolRichText] widget displays text that uses multiple different styles. The
/// text to display is described using a tree of [TextSpan] objects, each of
/// which has an associated style that is used for that subtree. The text might
/// break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// Text displayed in a [MongolRichText] widget must be explicitly styled. When
/// picking which style to use, consider using [DefaultTextStyle.of] the current
/// [BuildContext] to provide defaults. For more details on how to style text in
/// a [MongolRichText] widget, see the documentation for [TextStyle].
///
/// Consider using the [MongolText] widget to integrate with the [DefaultTextStyle]
/// automatically. When all the text uses the same style, the default constructor
/// is less verbose. The [MongolText.rich] constructor allows you to style multiple
/// spans with the default text style while still allowing specified styles per
/// span.
///
/// {@tool snippet}
///
/// This sample demonstrates how to mix and match text with different text
/// styles using the [MongolRichText] Widget. It displays the text "Hello bold world,"
/// emphasizing the word "bold" using a bold font weight.
///
/// ```dart
/// MongolRichText(
///   text: TextSpan(
///     text: 'Hello ',
///     style: DefaultTextStyle.of(context).style,
///     children: <TextSpan>[
///       TextSpan(text: 'bold', style: TextStyle(fontWeight: FontWeight.bold)),
///       TextSpan(text: ' world!'),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [TextStyle], which discusses how to style text.
///  * [TextSpan], which is used to describe the text in a paragraph.
///  * [MongolText], which automatically applies the ambient styles described by a
///    [DefaultTextStyle] to a single string.
///  * [MongolText.rich], a const text widget that provides similar functionality
///    as [MongolRichText]. [MongokText.rich] will inherit [TextStyle] from [DefaultTextStyle].
class MongolRichText extends LeafRenderObjectWidget {
  /// Creates a paragraph of rich text in vertical orientation for traditional
  /// Mongolian.
  ///
  /// The [text] argument must not be null.
  const MongolRichText({
    Key? key,
    required this.text,
    this.textAlign = MongolTextAlign.top,
    this.textScaleFactor = 1.0,
  }) : super(key: key);

  /// The text to display in this widget.
  final TextSpan text;

  /// How the text should be aligned vertically.
  final MongolTextAlign textAlign;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  @override
  MongolRenderParagraph createRenderObject(BuildContext context) {
    return MongolRenderParagraph(
      text,
      textAlign: textAlign,
      textScaleFactor: textScaleFactor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MongolRenderParagraph renderObject) {
    renderObject
      ..text = text
      ..textAlign = textAlign
      ..textScaleFactor = textScaleFactor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text.toPlainText()));
    properties.add(EnumProperty<MongolTextAlign>('textAlign', textAlign,
        defaultValue: MongolTextAlign.top));
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
    MongolTextAlign textAlign = MongolTextAlign.top,
    double textScaleFactor = 1.0,
  }) : _textPainter = MongolTextPainter(
          text: text,
          textAlign: textAlign,
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
  TextSpan get text => _textPainter.text!;
  set text(TextSpan value) {
    switch (_textPainter.text!.compareTo(value)) {
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

  /// How the text should be aligned vertically.
  MongolTextAlign get textAlign => _textPainter.textAlign;
  set textAlign(MongolTextAlign value) {
    if (_textPainter.textAlign == value) {
      return;
    }
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
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
    assert(constraints.debugAssertIsValid());
    _layoutTextWithConstraints(constraints);
    return _textPainter.computeDistanceToActualBaseline(baseline);
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
    final span = _textPainter.text!.getSpanForPosition(position);
    if (span == null) {
      return;
    }
    if (span is TextSpan) {
      span.recognizer?.addPointer(event);
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
    properties.add(EnumProperty<MongolTextAlign>('textAlign', textAlign));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
  }
}
