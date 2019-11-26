import 'dart:ui' as ui show ParagraphStyle;

import 'package:flutter/painting.dart';
import 'package:mongol/mongol_paragraph.dart';


class MongolTextPainter {

  MongolTextPainter({
    TextSpan text,
  }) :  assert(text == null || text.debugAssertIsValid()),
        _text = text;

  MongolParagraph _paragraph;
  bool _needsLayout = true;

  TextSpan get text => _text;
  TextSpan _text;
  set text(TextSpan value) {
    assert(value == null || value.debugAssertIsValid());
    if (_text == value)
      return;
    _text = value;
    _paragraph = null;
    _needsLayout = true;
  }

  ui.ParagraphStyle _createParagraphStyle() {
    return ui.ParagraphStyle(
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

  double get minIntrinsicHeight {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.minIntrinsicHeight);
  }

  double get maxIntrinsicHeight {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.maxIntrinsicHeight);
  }

  double get width {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.width);
  }

  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.height);
  }

  Size get size {
    assert(!_needsLayout);
    return Size(width, height);
  }

  double _lastMinHeight;
  double _lastMaxHeight;

  void layout({ double minHeight = 0.0, double maxHeight = double.infinity }) {
    assert(text != null);
    if (!_needsLayout && minHeight == _lastMinHeight && maxHeight == _lastMaxHeight)
      return;
    _needsLayout = false;
    if (_paragraph == null) {
      final MongolParagraphBuilder builder = MongolParagraphBuilder(_createParagraphStyle());
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

  void _addStyleToText(MongolParagraphBuilder builder, TextSpan textSpan) {
    final style = textSpan.style;
    final text = textSpan.text;
    final children = textSpan.children;
    final bool hasStyle = style != null;
    if (hasStyle)
      builder.pushStyle(style);
    if (text != null)
      builder.addText(text);
    if (children != null) {
      for (TextSpan child in children) {
        assert(child != null);
        _addStyleToText(builder, child);
      }
    }
    if (hasStyle)
      builder.pop();
  }

  void paint(Canvas canvas, Offset offset) {
    _paragraph.draw(canvas, offset);
  }

}
