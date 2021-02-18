import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart'
    show
        InputBorder,
        BorderSide,
        BorderRadius,
        Radius,
        EdgeInsetsGeometry,
        EdgeInsets,
        ShapeBorder;

/// Draws a vertical line at the right side of a [MongolInputDecorator]'s
/// container and defines the container's shape.
///
/// The input decorator's "container" is the optionally filled area to the left
/// of the decorator's helper, error, and counter.
///
/// See also:
///
///  * [OutlineInputBorder], an [InputDecorator] border which draws a
///    rounded rectangle around the input decorator's container.
///  * [MongolInputDecoration], which is used to configure a
///    [MongolInputDecorator].
class SidelineInputBorder extends InputBorder {
  /// Creates a single line border on the right for a [MongolInputDecorator].
  ///
  /// The [borderSide] parameter defaults to [BorderSide.none] (it must not be
  /// null). Applications typically do not specify a [borderSide] parameter
  /// because the input decorator substitutes its own, using [copyWith], based
  /// on the current theme and [MongolInputDecorator.isFocused].
  ///
  /// The [borderRadius] parameter defaults to a value where the top and
  /// bottom left corners have a circular radius of 4.0. The [borderRadius]
  /// parameter must not be null.
  const SidelineInputBorder({
    BorderSide borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4.0),
      bottomLeft: Radius.circular(4.0),
    ),
  }) : super(borderSide: borderSide);

  /// The radii of the border's rounded rectangle corners.
  ///
  /// When this border is used with a filled input decorator, see
  /// [MongolInputDecoration.filled], the border radius defines the shape
  /// of the background fill as well as the top and bottom right
  /// edges of the sideline itself.
  ///
  /// By default the top and bottom left corners have a circular radius
  /// of 4.0.
  final BorderRadius borderRadius;

  @override
  bool get isOutline => false;

  @override
  SidelineInputBorder copyWith(
      {BorderSide? borderSide, BorderRadius? borderRadius}) {
    return SidelineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.only(right: borderSide.width);
  }

  @override
  SidelineInputBorder scale(double t) {
    return SidelineInputBorder(borderSide: borderSide.scale(t));
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(Rect.fromLTWH(rect.left, rect.top,
          math.max(0.0, rect.width - borderSide.width), rect.height));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.toRRect(rect));
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SidelineInputBorder) {
      return SidelineInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SidelineInputBorder) {
      return SidelineInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  /// Draw a vertical line at the right side of [rect].
  ///
  /// The [borderSide] defines the line's color and weight.
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderRadius.topRight != Radius.zero ||
        borderRadius.bottomRight != Radius.zero) {
      canvas.clipPath(getOuterPath(rect, textDirection: textDirection));
    }
    canvas.drawLine(rect.topRight, rect.bottomRight, borderSide.toPaint());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is InputBorder && other.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}
