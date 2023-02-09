// Copyright 2014 The Flutter Authors.
// Copyright 2022 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart'
    show
        InputBorder,
        OutlineInputBorder,
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
///  * [InputDecoration], which is used to configure a
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
  /// [InputDecoration.filled], the border radius defines the shape
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

/// Draws a rounded rectangle around a [MongolInputDecorator]'s container.
///
/// When the input decorator's label is floating, for example because its
/// input child has the focus, the label appears in a gap in the border outline.
///
/// See also:
///
///  * [SidelineInputBorder], the default [InputDecorator] border which
///    draws a vertical line at the right of the input decorator's container.
///  * [InputDecoration], which is used to configure an [MongolInputDecorator].
class MongolOutlineInputBorder extends InputBorder {
  /// Creates a rounded rectangle outline border for a [MongolInputDecorator].
  ///
  /// If the [borderSide] parameter is [BorderSide.none], it will not draw a
  /// border. However, it will still define a shape (which you can see if
  /// [InputDecoration.filled] is true).
  ///
  /// If an application does not specify a [borderSide] parameter of
  /// value [BorderSide.none], the input decorator substitutes its own, using
  /// [copyWith], based on the current theme and [InputDecorator.isFocused].
  ///
  /// The [borderRadius] parameter defaults to a value where all four
  /// corners have a circular radius of 4.0. The [borderRadius] parameter
  /// must not be null and the corner radii must be circular, i.e. their
  /// [Radius.x] and [Radius.y] values must be the same.
  ///
  /// See also:
  ///
  ///  * [InputDecoration.floatingLabelBehavior], which should be set to
  ///    [FloatingLabelBehavior.never] when the [borderSide] is
  ///    [BorderSide.none]. If let as [FloatingLabelBehavior.auto], the label
  ///    will extend beyond the container as if the border were still being
  ///    drawn.
  const MongolOutlineInputBorder({
    super.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.gapPadding = 4.0,
  }) : assert(gapPadding >= 0.0);

  // This can't be checked by the constructor because const constructor.
  static bool _cornersAreCircular(BorderRadius borderRadius) {
    return borderRadius.topLeft.x == borderRadius.topLeft.y &&
        borderRadius.bottomLeft.x == borderRadius.bottomLeft.y &&
        borderRadius.topRight.x == borderRadius.topRight.y &&
        borderRadius.bottomRight.x == borderRadius.bottomRight.y;
  }

  /// Vertical padding on either side of the border's
  /// [InputDecoration.labelText] height gap.
  ///
  /// This value is used by the [paint] method to compute the actual gap width.
  final double gapPadding;

  /// The radii of the border's rounded rectangle corners.
  ///
  /// The corner radii must be circular, i.e. their [Radius.x] and [Radius.y]
  /// values must be the same.
  final BorderRadius borderRadius;

  @override
  bool get isOutline => true;

  @override
  MongolOutlineInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return MongolOutlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(borderSide.width);
  }

  @override
  MongolOutlineInputBorder scale(double t) {
    return MongolOutlineInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is MongolOutlineInputBorder) {
      final MongolOutlineInputBorder outline = a;
      return MongolOutlineInputBorder(
        borderRadius: BorderRadius.lerp(outline.borderRadius, borderRadius, t)!,
        borderSide: BorderSide.lerp(outline.borderSide, borderSide, t),
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is MongolOutlineInputBorder) {
      final MongolOutlineInputBorder outline = b;
      return MongolOutlineInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, outline.borderRadius, t)!,
        borderSide: BorderSide.lerp(borderSide, outline.borderSide, t),
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(borderRadius
          .resolve(textDirection)
          .toRRect(rect)
          .deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  Path _gapBorderPath(
      Canvas canvas, RRect center, double start, double extent) {
    // When the corner radii on any side add up to be greater than the
    // given width, each radius has to be scaled to not exceed the
    // size of the width/height of the RRect.
    final RRect scaledRRect = center.scaleRadii();

    final Rect tlCorner = Rect.fromLTWH(
      scaledRRect.left,
      scaledRRect.top,
      scaledRRect.tlRadiusX * 2.0,
      scaledRRect.tlRadiusY * 2.0,
    );
    final Rect trCorner = Rect.fromLTWH(
      scaledRRect.right - scaledRRect.trRadiusX * 2.0,
      scaledRRect.top,
      scaledRRect.trRadiusX * 2.0,
      scaledRRect.trRadiusY * 2.0,
    );
    final Rect brCorner = Rect.fromLTWH(
      scaledRRect.right - scaledRRect.brRadiusX * 2.0,
      scaledRRect.bottom - scaledRRect.brRadiusY * 2.0,
      scaledRRect.brRadiusX * 2.0,
      scaledRRect.brRadiusY * 2.0,
    );
    final Rect blCorner = Rect.fromLTWH(
      scaledRRect.left,
      scaledRRect.bottom - scaledRRect.blRadiusY * 2.0,
      scaledRRect.blRadiusX * 2.0,
      scaledRRect.blRadiusX * 2.0,
    );

    // Unlike OutlineInputBorder, MongolOutlineInputBorder ignores partial
    // sweeps around the corners. It's just a plain 90 degrees at all four
    // corners.
    const double cornerArcSweep = math.pi / 2.0; // 90 degrees
    final Path path = Path()
      ..addArc(tlCorner, math.pi, cornerArcSweep)
      ..lineTo(scaledRRect.right - scaledRRect.trRadiusX, scaledRRect.top)
      ..addArc(trCorner, (3 * math.pi) / 2.0, cornerArcSweep)
      ..lineTo(scaledRRect.right, scaledRRect.bottom - scaledRRect.brRadiusY)
      ..addArc(brCorner, 0.0, cornerArcSweep)
      ..lineTo(scaledRRect.left + scaledRRect.blRadiusX, scaledRRect.bottom);

    // Don't draw the bottom left corner if the text is too long.
    if (start + extent < scaledRRect.height - scaledRRect.blRadiusY) {
      path.addArc(blCorner, math.pi / 2, cornerArcSweep);
      path.lineTo(scaledRRect.left, scaledRRect.top + start + extent);
    }

    // Don't draw a line for the extent gap.
    path.moveTo(scaledRRect.left, start);

    // Finish off a little line segment from the top of the gap to the corner.
    if (start > scaledRRect.tlRadiusY) {
      path.lineTo(scaledRRect.left, scaledRRect.tlRadiusY);
    }

    return path;
  }

  /// Draw a rounded rectangle around [rect] using [borderRadius].
  ///
  /// The [borderSide] defines the line's color and weight.
  ///
  /// The top side of the rounded rectangle may be interrupted by a single gap
  /// if [gapExtent] is non-null. In that case the gap begins at
  /// `gapStart - gapPadding`. The gap's height is
  /// `(gapPadding + gapExtent + gapPadding) * gapPercentage`.
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    assert(gapPercentage >= 0.0 && gapPercentage <= 1.0);
    assert(_cornersAreCircular(borderRadius));

    final Paint paint = borderSide.toPaint();
    final RRect outer = borderRadius.toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);
    if (gapStart == null || gapExtent <= 0.0 || gapPercentage == 0.0) {
      canvas.drawRRect(center, paint);
    } else {
      final double extent = lerpDouble(
        0.0,
        gapExtent + gapPadding * 2.0,
        gapPercentage,
      )!;
      final Path path = _gapBorderPath(
        canvas,
        center,
        math.max(0.0, gapStart - gapPadding),
        extent,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is OutlineInputBorder &&
        other.borderSide == borderSide &&
        other.borderRadius == borderRadius &&
        other.gapPadding == gapPadding;
  }

  @override
  int get hashCode => Object.hash(borderSide, borderRadius, gapPadding);
}
