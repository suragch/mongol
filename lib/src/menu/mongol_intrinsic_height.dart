// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that sizes its child to the child's maximum intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height.
///
/// The constraints that this widget passes to its child will adhere to the
/// parent's constraints, so if the constraints are not large enough to satisfy
/// the child's maximum intrinsic height, then the child will get less height
/// than it otherwise would. Likewise, if the minimum height constraint is
/// larger than the child's maximum intrinsic height, the child will be given
/// more width than it otherwise would.
///
/// If [stepHeight] is non-null, the child's height will be snapped to a multiple
/// of the [stepHeight]. Similarly, if [stepWidth] is non-null, the child's
/// width will be snapped to a multiple of the [stepWidth].
///
/// This class is relatively expensive, because it adds a speculative layout
/// pass before the final layout phase. Avoid using it where possible. In the
/// worst case, this widget can result in a layout that is O(N²) in the depth of
/// the tree.
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself. This can be used
///    to loosen the constraints passed to the [MongolRenderIntrinsicHeight],
///    allowing the [MongolRenderIntrinsicHeight]'s child to be smaller than that of
///    its parent.
///  * [Column], which when used with [CrossAxisAlignment.stretch] can be used
///    to loosen just the height constraints that are passed to the
///    [MongolRenderIntrinsicHeight], allowing the [MongolRenderIntrinsicHeight]'s child's
///    height to be smaller than that of its parent.
class MongolIntrinsicHeight extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to the child's intrinsic height.
  ///
  /// This class is relatively expensive. Avoid using it where possible.
  const MongolIntrinsicHeight(
      {Key? key, this.stepHeight, this.stepWidth, Widget? child})
      : assert(stepHeight == null || stepHeight >= 0.0),
        assert(stepWidth == null || stepWidth >= 0.0),
        super(key: key, child: child);

  /// If non-null, force the child's height to be a multiple of this value.
  ///
  /// If null or 0.0 the child's height will be the same as its maximum
  /// intrinsic height.
  ///
  /// This value must not be negative.
  ///
  /// See also:
  ///
  ///  * [RenderBox.getMaxIntrinsicHeight], which defines a widget's max
  ///    intrinsic height  in general.
  final double? stepHeight;

  /// If non-null, force the child's width to be a multiple of this value.
  ///
  /// If null or 0.0 the child's width will not be constrained.
  ///
  /// This value must not be negative.
  final double? stepWidth;

  double? get _stepHeight => stepHeight == 0.0 ? null : stepHeight;
  double? get _stepWidth => stepWidth == 0.0 ? null : stepWidth;

  @override
  MongolRenderIntrinsicHeight createRenderObject(BuildContext context) {
    return MongolRenderIntrinsicHeight(
        stepHeight: _stepHeight, stepWidth: _stepWidth);
  }

  @override
  void updateRenderObject(
      BuildContext context, MongolRenderIntrinsicHeight renderObject) {
    renderObject
      ..stepHeight = _stepHeight
      ..stepWidth = _stepWidth;
  }
}

/// Sizes its child to the child's maximum intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height.
///
/// The constraints that this widget passes to its child will adhere to the
/// parent's constraints, so if the constraints are not large enough to satisfy
/// the child's maximum intrinsic height, then the child will get less height
/// than it otherwise would. Likewise, if the minimum height constraint is
/// larger than the child's maximum intrinsic height, the child will be given
/// more width than it otherwise would.
///
/// If [stepHeight] is non-null, the child's height will be snapped to a multiple
/// of the [stepHeight]. Similarly, if [stepWidth] is non-null, the child's
/// width will be snapped to a multiple of the [stepWidth].
///
/// This class is relatively expensive, because it adds a speculative layout
/// pass before the final layout phase. Avoid using it where possible. In the
/// worst case, this widget can result in a layout that is O(N²) in the depth of
/// the tree.
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself. This can be used
///    to loosen the constraints passed to the [MongolRenderIntrinsicHeight],
///    allowing the [MongolRenderIntrinsicHeight]'s child to be smaller than that of
///    its parent.
///  * [Column], which when used with [CrossAxisAlignment.stretch] can be used
///    to loosen just the height constraints that are passed to the
///    [MongolRenderIntrinsicHeight], allowing the [MongolRenderIntrinsicHeight]'s child's
///    height to be smaller than that of its parent.
class MongolRenderIntrinsicHeight extends RenderProxyBox {
  /// Creates a render object that sizes itself to its child's intrinsic height.
  ///
  /// If [stepHeight] is non-null it must be > 0.0. Similarly If [stepWidth] is
  /// non-null it must be > 0.0.
  MongolRenderIntrinsicHeight({
    double? stepHeight,
    double? stepWidth,
    RenderBox? child,
  })  : assert(stepHeight == null || stepHeight > 0.0),
        assert(stepWidth == null || stepWidth > 0.0),
        _stepHeight = stepHeight,
        _stepWidth = stepWidth,
        super(child);

  /// If non-null, force the child's height to be a multiple of this value.
  ///
  /// This value must be null or > 0.0.
  double? get stepHeight => _stepHeight;
  double? _stepHeight;
  set stepHeight(double? value) {
    assert(value == null || value > 0.0);
    if (value == _stepHeight) return;
    _stepHeight = value;
    markNeedsLayout();
  }

  /// If non-null, force the child's width to be a multiple of this value.
  ///
  /// This value must be null or > 0.0.
  double? get stepWidth => _stepWidth;
  double? _stepWidth;
  set stepWidth(double? value) {
    assert(value == null || value > 0.0);
    if (value == _stepWidth) return;
    _stepWidth = value;
    markNeedsLayout();
  }

  static double _applyStep(double input, double? step) {
    assert(input.isFinite);
    if (step == null) return input;
    return (input / step).ceil() * step;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeMaxIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child == null) return 0.0;
    final double height = child!.getMaxIntrinsicHeight(width);
    return _applyStep(height, _stepHeight);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    if (!height.isFinite) height = computeMaxIntrinsicHeight(double.infinity);
    assert(height.isFinite);
    final double width = child!.getMinIntrinsicWidth(height);
    return _applyStep(width, _stepWidth);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    if (!height.isFinite) height = computeMaxIntrinsicHeight(double.infinity);
    assert(height.isFinite);
    final double width = child!.getMaxIntrinsicWidth(height);
    return _applyStep(width, _stepWidth);
  }

  Size _computeSize(
      {required ChildLayouter layoutChild,
      required BoxConstraints constraints}) {
    if (child != null) {
      if (!constraints.hasTightHeight) {
        final double height =
            child!.getMaxIntrinsicHeight(constraints.maxWidth);
        assert(height.isFinite);
        constraints =
            constraints.tighten(height: _applyStep(height, _stepHeight));
      }
      if (_stepWidth != null) {
        final double width = child!.getMaxIntrinsicWidth(constraints.maxHeight);
        assert(width.isFinite);
        constraints = constraints.tighten(width: _applyStep(width, _stepWidth));
      }
      return layoutChild(child!, constraints);
    } else {
      return constraints.smallest;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeSize(
      layoutChild: ChildLayoutHelper.dryLayoutChild,
      constraints: constraints,
    );
  }

  @override
  void performLayout() {
    size = _computeSize(
      layoutChild: ChildLayoutHelper.layoutChild,
      constraints: constraints,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('stepHeight', stepHeight));
    properties.add(DoubleProperty('stepWidth', stepWidth));
  }
}
