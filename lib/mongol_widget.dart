//import 'package:flutter/widgets.dart';
//import 'package:mongol/mongol_text_painter.dart';
//
//class MongolText extends LeafRenderObjectWidget {
//  /// Creates a single line of vertical text
//  ///
//  /// The [text] argument must not be null.
//  const MongolText({
//    Key key,
//    this.text,
//  })  : assert(text != null),
//        super(key: key);
//
//  /// The text to display in this widget.
//  final TextSpan text;
//
//  @override
//  RenderMongolText createRenderObject(BuildContext context) {
//    print('creating render object');
//    return RenderMongolText(text);
//  }
//
//  @override
//  void updateRenderObject(
//      BuildContext context, RenderMongolText renderObject) {
//    print('updating render object');
//    renderObject.text = text;
//  }
//}
//
//class RenderMongolText extends RenderBox {
//  /// Creates a vertical text render object.
//  ///
//  /// The [text] argument must not be null.
//  RenderMongolText(TextSpan text)
//      : assert(text != null),
//        _textPainter = MongolTextPainter(text: text);
//
//  final MongolTextPainter _textPainter;
//
//  /// The text to display
//  TextSpan get text => _textPainter.text;
//
//  set text(TextSpan value) {
//    switch (_textPainter.text.compareTo(value)) {
//      case RenderComparison.identical:
//      case RenderComparison.metadata:
//        return;
//      case RenderComparison.paint:
//        _textPainter.text = value;
//        markNeedsPaint();
//        break;
//      case RenderComparison.layout:
//        _textPainter.text = value;
//        markNeedsLayout();
//        break;
//    }
//  }
//
//  void _layoutText({
//    double minHeight = 0.0,
//    double maxHeight = double.infinity,
//  }) {
//    _textPainter.layout(
//      minHeight: minHeight,
//      maxHeight: maxHeight,
//    );
//  }
//
//  void _layoutTextWithConstraints(BoxConstraints constraints) {
//    _layoutText(
//      minHeight: constraints.minHeight,
//      maxHeight: constraints.maxHeight,
//    );
//  }
//
//  @override
//  double computeMinIntrinsicHeight(double width) {
//    _layoutText();
//    return _textPainter.minIntrinsicHeight;
//  }
//
//  @override
//  double computeMaxIntrinsicHeight(double width) {
//    _layoutText();
//    return _textPainter.maxIntrinsicHeight;
//  }
//
//  double _computeIntrinsicWidth(double height) {
//    _layoutText(minHeight: height, maxHeight: height);
//    return _textPainter.width;
//  }
//
//  @override
//  double computeMinIntrinsicWidth(double height) {
//    return _computeIntrinsicWidth(height);
//  }
//
//  @override
//  double computeMaxIntrinsicWidth(double height) {
//    return _computeIntrinsicWidth(height);
//  }
//
//  @override
//  double computeDistanceToActualBaseline(TextBaseline baseline) {
//    assert(!debugNeedsLayout);
//    assert(constraints != null);
//    assert(constraints.debugAssertIsValid());
//    _layoutTextWithConstraints(constraints);
//    // Since the text is rotated it doesn't make sense to use the rotated
//    // text baseline because this is used for aligning with other widgets.
//    // Instead we will return the base of the widget.
//    return _textPainter.height;
//  }
//
//  @override
//  void performLayout() {
//    _layoutTextWithConstraints(constraints);
//    final Size textSize = _textPainter.size;
//    size = constraints.constrain(textSize);
//  }
//
//  @override
//  void paint(PaintingContext context, Offset offset) {
//    _layoutTextWithConstraints(constraints);
//    _textPainter.paint(context.canvas, offset);
//  }
//}
