// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: omit_local_variable_types

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        InputBorder,
        Colors,
        VisualDensity,
        kMinInteractiveDimension,
        FloatingLabelBehavior,
        MaterialStateProperty,
        MaterialState,
        InputDecoration,
        FloatingLabelAlignment,
        Theme,
        ThemeData,
        Brightness;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../base/mongol_text_align.dart';
import '../text/mongol_text.dart';
import 'alignment.dart';
import 'input_border.dart';

const Duration _kTransitionDuration = Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;
const double _kFinalLabelScale = 0.75;

// Defines the gap in the MongolInputDecorator's outline border where the
// floating label will appear.
class _InputBorderGap extends ChangeNotifier {
  double? _start;
  double? get start => _start;
  set start(double? value) {
    if (value != _start) {
      _start = value;
      notifyListeners();
    }
  }

  double _extent = 0.0;
  double get extent => _extent;
  set extent(double value) {
    if (value != _extent) {
      _extent = value;
      notifyListeners();
    }
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, this class is not used in collection
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _InputBorderGap &&
        other.start == start &&
        other.extent == extent;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, this class is not used in collection
  int get hashCode => Object.hash(start, extent);
}

// Used to interpolate between two InputBorders.
class _InputBorderTween extends Tween<InputBorder> {
  _InputBorderTween({InputBorder? begin, InputBorder? end})
      : super(begin: begin, end: end);

  @override
  InputBorder lerp(double t) => ShapeBorder.lerp(begin, end, t)! as InputBorder;
}

// Passes the _InputBorderGap parameters along to an InputBorder's paint method.
class _InputBorderPainter extends CustomPainter {
  _InputBorderPainter({
    required Listenable repaint,
    required this.borderAnimation,
    required this.border,
    required this.gapAnimation,
    required this.gap,
    required this.fillColor,
    required this.hoverAnimation,
    required this.hoverColorTween,
  }) : super(repaint: repaint);

  final Animation<double> borderAnimation;
  final _InputBorderTween border;
  final Animation<double> gapAnimation;
  final _InputBorderGap gap;
  final Color fillColor;
  final ColorTween hoverColorTween;
  final Animation<double> hoverAnimation;

  Color get blendedColor =>
      Color.alphaBlend(hoverColorTween.evaluate(hoverAnimation)!, fillColor);

  @override
  void paint(Canvas canvas, Size size) {
    final borderValue = border.evaluate(borderAnimation);
    final canvasRect = Offset.zero & size;
    final blendedFillColor = blendedColor;
    if (blendedFillColor.alpha > 0) {
      canvas.drawPath(
        borderValue.getOuterPath(canvasRect, textDirection: TextDirection.ltr),
        Paint()
          ..color = blendedFillColor
          ..style = PaintingStyle.fill,
      );
    }

    borderValue.paint(
      canvas,
      canvasRect,
      gapStart: gap.start,
      gapExtent: gap.extent,
      gapPercentage: gapAnimation.value,
      textDirection: TextDirection.ltr,
    );
  }

  @override
  bool shouldRepaint(_InputBorderPainter oldPainter) {
    return borderAnimation != oldPainter.borderAnimation ||
        hoverAnimation != oldPainter.hoverAnimation ||
        gapAnimation != oldPainter.gapAnimation ||
        border != oldPainter.border ||
        gap != oldPainter.gap;
  }
}

// An analog of AnimatedContainer, which can animate its shaped border, for
// _InputBorder. This specialized animated container is needed because the
// _InputBorderGap, which is computed at layout time, is required by the
// _InputBorder's paint method.
class _BorderContainer extends StatefulWidget {
  const _BorderContainer({
    Key? key,
    required this.border,
    required this.gap,
    required this.gapAnimation,
    required this.fillColor,
    required this.hoverColor,
    required this.isHovering,
    // ignore: unused_element
    this.child,
  }) : super(key: key);

  final InputBorder border;
  final _InputBorderGap gap;
  final Animation<double> gapAnimation;
  final Color fillColor;
  final Color hoverColor;
  final bool isHovering;
  final Widget? child;

  @override
  _BorderContainerState createState() => _BorderContainerState();
}

class _BorderContainerState extends State<_BorderContainer>
    with TickerProviderStateMixin {
  static const Duration _kHoverDuration = Duration(milliseconds: 15);

  late AnimationController _controller;
  late AnimationController _hoverColorController;
  late Animation<double> _borderAnimation;
  late _InputBorderTween _border;
  late Animation<double> _hoverAnimation;
  late ColorTween _hoverColorTween;

  @override
  void initState() {
    super.initState();
    _hoverColorController = AnimationController(
      duration: _kHoverDuration,
      value: widget.isHovering ? 1.0 : 0.0,
      vsync: this,
    );
    _controller = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
    _borderAnimation = CurvedAnimation(
      parent: _controller,
      curve: _kTransitionCurve,
    );
    _border = _InputBorderTween(
      begin: widget.border,
      end: widget.border,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverColorController,
      curve: Curves.linear,
    );
    _hoverColorTween =
        ColorTween(begin: Colors.transparent, end: widget.hoverColor);
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverColorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_BorderContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.border != oldWidget.border) {
      _border = _InputBorderTween(
        begin: oldWidget.border,
        end: widget.border,
      );
      _controller
        ..value = 0.0
        ..forward();
    }
    if (widget.hoverColor != oldWidget.hoverColor) {
      _hoverColorTween =
          ColorTween(begin: Colors.transparent, end: widget.hoverColor);
    }
    if (widget.isHovering != oldWidget.isHovering) {
      if (widget.isHovering) {
        _hoverColorController.forward();
      } else {
        _hoverColorController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _InputBorderPainter(
        repaint: Listenable.merge(<Listenable>[
          _borderAnimation,
          widget.gap,
          _hoverColorController,
        ]),
        borderAnimation: _borderAnimation,
        border: _border,
        gapAnimation: widget.gapAnimation,
        gap: widget.gap,
        fillColor: widget.fillColor,
        hoverColorTween: _hoverColorTween,
        hoverAnimation: _hoverAnimation,
      ),
      child: widget.child,
    );
  }
}

// Used to "shake" the floating label to the up and down
// when the errorText first appears.
class _Shaker extends AnimatedWidget {
  const _Shaker({
    Key? key,
    required Animation<double> animation,
    this.child,
  }) : super(key: key, listenable: animation);

  final Widget? child;

  Animation<double> get animation => listenable as Animation<double>;

  double get translateY {
    const shakeDelta = 4.0;
    final t = animation.value;
    if (t <= 0.25) {
      return -t * shakeDelta;
    } else if (t < 0.75) {
      return (t - 0.5) * shakeDelta;
    } else {
      return (1.0 - t) * 4.0 * shakeDelta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.translationValues(0.0, translateY, 0.0),
      child: child,
    );
  }
}

// Display the helper and error text. When the error text appears
// it fades and the helper text fades out. The error text also
// slides leftwards a little when it first appears.
class _HelperError extends StatefulWidget {
  const _HelperError({
    Key? key,
    this.textAlign,
    this.helperText,
    this.helperStyle,
    this.helperMaxLines,
    this.errorText,
    this.errorStyle,
    this.errorMaxLines,
  }) : super(key: key);

  final MongolTextAlign? textAlign;
  final String? helperText;
  final TextStyle? helperStyle;
  final int? helperMaxLines;
  final String? errorText;
  final TextStyle? errorStyle;
  final int? errorMaxLines;

  @override
  _HelperErrorState createState() => _HelperErrorState();
}

class _HelperErrorState extends State<_HelperError>
    with SingleTickerProviderStateMixin {
  // If the width of this widget and the counter are zero ("empty") at
  // layout time, no space is allocated for the subtext.
  static const Widget empty = SizedBox();

  late AnimationController _controller;
  Widget? _helper;
  Widget? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
    if (widget.errorText != null) {
      _error = _buildError();
      _controller.value = 1.0;
    } else if (widget.helperText != null) {
      _helper = _buildHelper();
    }
    _controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The _controller's value has changed.
    });
  }

  @override
  void didUpdateWidget(_HelperError old) {
    super.didUpdateWidget(old);

    final newErrorText = widget.errorText;
    final newHelperText = widget.helperText;
    final oldErrorText = old.errorText;
    final oldHelperText = old.helperText;

    final errorTextStateChanged =
        (newErrorText != null) != (oldErrorText != null);
    final helperTextStateChanged = newErrorText == null &&
        (newHelperText != null) != (oldHelperText != null);

    if (errorTextStateChanged || helperTextStateChanged) {
      if (newErrorText != null) {
        _error = _buildError();
        _controller.forward();
      } else if (newHelperText != null) {
        _helper = _buildHelper();
        _controller.reverse();
      } else {
        _controller.reverse();
      }
    }
  }

  Widget _buildHelper() {
    assert(widget.helperText != null);
    return Semantics(
      container: true,
      child: Opacity(
        opacity: 1.0 - _controller.value,
        child: MongolText(
          widget.helperText!,
          style: widget.helperStyle,
          textAlign: widget.textAlign,
          overflow: TextOverflow.ellipsis,
          maxLines: widget.helperMaxLines,
        ),
      ),
    );
  }

  Widget _buildError() {
    assert(widget.errorText != null);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Opacity(
        opacity: _controller.value,
        child: FractionalTranslation(
          translation: Tween<Offset>(
            begin: const Offset(-0.25, 0.0),
            end: const Offset(0.0, 0.0),
          ).evaluate(_controller.view),
          child: MongolText(
            widget.errorText!,
            style: widget.errorStyle,
            textAlign: widget.textAlign,
            overflow: TextOverflow.ellipsis,
            maxLines: widget.errorMaxLines,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed) {
      _error = null;
      if (widget.helperText != null) {
        return _helper = _buildHelper();
      } else {
        _helper = null;
        return empty;
      }
    }

    if (_controller.isCompleted) {
      _helper = null;
      if (widget.errorText != null) {
        return _error = _buildError();
      } else {
        _error = null;
        return empty;
      }
    }

    if (_helper == null && widget.errorText != null) return _buildError();

    if (_error == null && widget.helperText != null) return _buildHelper();

    if (widget.errorText != null) {
      return Stack(
        children: <Widget>[
          Opacity(
            opacity: 1.0 - _controller.value,
            child: _helper,
          ),
          _buildError(),
        ],
      );
    }

    if (widget.helperText != null) {
      return Stack(
        children: <Widget>[
          _buildHelper(),
          Opacity(
            opacity: _controller.value,
            child: _error,
          ),
        ],
      );
    }

    return empty;
  }
}

// private getter to mirror the _x in the FloatingLabelAlignment source code
extension MongolFloatingLabelAlignment on FloatingLabelAlignment {
  double get _y => (this == FloatingLabelAlignment.start) ? -1.0 : 0.0;
}

// Identifies the children of a _RenderDecorationElement.
enum _DecorationSlot {
  icon,
  input,
  label,
  hint,
  prefix,
  suffix,
  prefixIcon,
  suffixIcon,
  helperError,
  counter,
  container,
}

// An analog of InputDecoration for the _Decorator widget.
@immutable
class _Decoration {
  const _Decoration({
    required this.contentPadding,
    required this.isCollapsed,
    required this.floatingLabelWidth,
    required this.floatingLabelProgress,
    required this.floatingLabelAlignment,
    this.border,
    this.borderGap,
    required this.alignLabelWithHint,
    required this.isDense,
    this.visualDensity,
    this.icon,
    this.input,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.helperError,
    this.counter,
    this.container,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool isCollapsed;
  final double floatingLabelWidth;
  final double floatingLabelProgress;
  final FloatingLabelAlignment floatingLabelAlignment;
  final InputBorder? border;
  final _InputBorderGap? borderGap;
  final bool alignLabelWithHint;
  final bool? isDense;
  final VisualDensity? visualDensity;
  final Widget? icon;
  final Widget? input;
  final Widget? label;
  final Widget? hint;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? helperError;
  final Widget? counter;
  final Widget? container;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _Decoration &&
        other.contentPadding == contentPadding &&
        other.isCollapsed == isCollapsed &&
        other.floatingLabelWidth == floatingLabelWidth &&
        other.floatingLabelProgress == floatingLabelProgress &&
        other.floatingLabelAlignment == floatingLabelAlignment &&
        other.border == border &&
        other.borderGap == borderGap &&
        other.alignLabelWithHint == alignLabelWithHint &&
        other.isDense == isDense &&
        other.visualDensity == visualDensity &&
        other.icon == icon &&
        other.input == input &&
        other.label == label &&
        other.hint == hint &&
        other.prefix == prefix &&
        other.suffix == suffix &&
        other.prefixIcon == prefixIcon &&
        other.suffixIcon == suffixIcon &&
        other.helperError == helperError &&
        other.counter == counter &&
        other.container == container;
  }

  @override
  int get hashCode => Object.hash(
        contentPadding,
        floatingLabelWidth,
        floatingLabelProgress,
        floatingLabelAlignment,
        border,
        borderGap,
        alignLabelWithHint,
        isDense,
        visualDensity,
        icon,
        input,
        label,
        hint,
        prefix,
        suffix,
        prefixIcon,
        suffixIcon,
        helperError,
        counter,
        container,
      );
}

// A container for the layout values computed by _RenderDecoration._layout.
// These values are used by _RenderDecoration.performLayout to position
// all of the renderer children of a _RenderDecoration.
class _RenderDecorationLayout {
  const _RenderDecorationLayout({
    required this.boxToBaseline,
    required this.inputBaseline,
    required this.outlineBaseline,
    required this.subtextBaseline,
    required this.containerWidth,
    required this.subtextWidth,
  });

  final Map<RenderBox?, double> boxToBaseline;
  final double inputBaseline;
  final double outlineBaseline;
  final double subtextBaseline; // helper/error counter
  final double containerWidth;
  final double subtextWidth;
}

// The workhorse: layout and paint a _Decorator widget's _Decoration.
class _RenderDecoration extends RenderBox
    with SlottedContainerRenderObjectMixin<_DecorationSlot> {
  _RenderDecoration({
    required _Decoration decoration,
    //required TextDirection textDirection,
    required TextBaseline textBaseline,
    required bool isFocused,
    required bool expands,
    TextAlignHorizontal? textAlignHorizontal,
  })  : _decoration = decoration,
        _textBaseline = textBaseline,
        _textAlignHorizontal = textAlignHorizontal,
        _isFocused = isFocused,
        _expands = expands;

  static const double subtextGap = 8.0;

  RenderBox? get icon => childForSlot(_DecorationSlot.icon);
  RenderBox? get input => childForSlot(_DecorationSlot.input);
  RenderBox? get label => childForSlot(_DecorationSlot.label);
  RenderBox? get hint => childForSlot(_DecorationSlot.hint);
  RenderBox? get prefix => childForSlot(_DecorationSlot.prefix);
  RenderBox? get suffix => childForSlot(_DecorationSlot.suffix);
  RenderBox? get prefixIcon => childForSlot(_DecorationSlot.prefixIcon);
  RenderBox? get suffixIcon => childForSlot(_DecorationSlot.suffixIcon);
  RenderBox? get helperError => childForSlot(_DecorationSlot.helperError);
  RenderBox? get counter => childForSlot(_DecorationSlot.counter);
  RenderBox? get container => childForSlot(_DecorationSlot.container);

  // The returned list is ordered for hit testing.
  @override
  Iterable<RenderBox> get children {
    return <RenderBox>[
      if (icon != null) icon!,
      if (input != null) input!,
      if (prefixIcon != null) prefixIcon!,
      if (suffixIcon != null) suffixIcon!,
      if (prefix != null) prefix!,
      if (suffix != null) suffix!,
      if (label != null) label!,
      if (hint != null) hint!,
      if (helperError != null) helperError!,
      if (counter != null) counter!,
      if (container != null) container!,
    ];
  }

  _Decoration get decoration => _decoration;
  _Decoration _decoration;
  set decoration(_Decoration value) {
    if (_decoration == value) {
      return;
    }
    _decoration = value;
    markNeedsLayout();
  }

  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    if (_textBaseline == value) {
      return;
    }
    _textBaseline = value;
    markNeedsLayout();
  }

  TextAlignHorizontal get _defaultTextAlignHorizontal =>
      _isOutlineAligned ? TextAlignHorizontal.center : TextAlignHorizontal.left;
  TextAlignHorizontal? get textAlignHorizontal =>
      _textAlignHorizontal ?? _defaultTextAlignHorizontal;
  TextAlignHorizontal? _textAlignHorizontal;
  set textAlignHorizontal(TextAlignHorizontal? value) {
    if (_textAlignHorizontal == value) {
      return;
    }
    // No need to relayout if the effective value is still the same.
    if (textAlignHorizontal!.x == (value?.x ?? _defaultTextAlignHorizontal.x)) {
      _textAlignHorizontal = value;
      return;
    }
    _textAlignHorizontal = value;
    markNeedsLayout();
  }

  bool get isFocused => _isFocused;
  bool _isFocused;
  set isFocused(bool value) {
    if (_isFocused == value) {
      return;
    }
    _isFocused = value;
    markNeedsSemanticsUpdate();
  }

  bool get expands => _expands;
  bool _expands = false;
  set expands(bool value) {
    if (_expands == value) {
      return;
    }
    _expands = value;
    markNeedsLayout();
  }

  // Indicates that the decoration should be aligned to accommodate an outline
  // border.
  bool get _isOutlineAligned {
    return !decoration.isCollapsed && decoration.border!.isOutline;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (icon != null) {
      visitor(icon!);
    }
    if (prefix != null) {
      visitor(prefix!);
    }
    if (prefixIcon != null) {
      visitor(prefixIcon!);
    }

    if (label != null) {
      visitor(label!);
    }
    if (hint != null) {
      if (isFocused) {
        visitor(hint!);
      } else if (label == null) {
        visitor(hint!);
      }
    }

    if (input != null) {
      visitor(input!);
    }
    if (suffixIcon != null) {
      visitor(suffixIcon!);
    }
    if (suffix != null) {
      visitor(suffix!);
    }
    if (container != null) {
      visitor(container!);
    }
    if (helperError != null) {
      visitor(helperError!);
    }
    if (counter != null) {
      visitor(counter!);
    }
  }

  @override
  bool get sizedByParent => false;

  static double _minHeight(RenderBox? box, double width) {
    return box == null ? 0.0 : box.getMinIntrinsicHeight(width);
  }

  static double _maxHeight(RenderBox? box, double width) {
    return box == null ? 0.0 : box.getMaxIntrinsicHeight(width);
  }

  static double _minWidth(RenderBox? box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static Size _boxSize(RenderBox? box) => box == null ? Size.zero : box.size;

  static BoxParentData _boxParentData(RenderBox box) =>
      box.parentData! as BoxParentData;

  EdgeInsets get contentPadding => decoration.contentPadding as EdgeInsets;

  // Lay out the given box if needed, and return its baseline.
  double _layoutLineBox(RenderBox? box, BoxConstraints constraints) {
    if (box == null) {
      return 0.0;
    }
    box.layout(constraints, parentUsesSize: true);
    // Since internally, all layout is performed against the alphabetic baseline,
    // (eg, ascents/descents are all relative to alphabetic, even if the font is
    // an ideographic or hanging font), we should always obtain the reference
    // baseline from the alphabetic baseline. The ideographic baseline is for
    // use post-layout and is derived from the alphabetic baseline combined with
    // the font metrics.
    final double baseline = box.getDistanceToBaseline(TextBaseline.alphabetic)!;

    assert(() {
      if (baseline >= 0) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            "One of MongolInputDecorator's children reported a negative baseline offset."),
        ErrorDescription(
          '${box.runtimeType}, of size ${box.size}, reported a negative '
          'alphabetic baseline of $baseline.',
        ),
      ]);
    }());
    return baseline;
  }

  // Returns a value used by performLayout to position all of the renderers.
  // This method applies layout to all of the renderers except the container.
  // For convenience, the container is laid out in performLayout().
  _RenderDecorationLayout _layout(BoxConstraints layoutConstraints) {
    assert(
      layoutConstraints.maxHeight < double.infinity,
      'A MongolInputDecorator, which is typically created by a MongolTextField, cannot '
      'have an unbounded height.\n'
      'This happens when the parent widget does not provide a finite height '
      'constraint. For example, if the MongolInputDecorator is contained by a Column, '
      'then its height must be constrained. An Expanded widget or a SizedBox '
      'can be used to constrain the height of the MongolInputDecorator or the '
      'MongolTextField that contains it.',
    );

    // Margin on each side of subtext (counter and helperError)
    final Map<RenderBox?, double> boxToBaseline = <RenderBox?, double>{};
    final BoxConstraints boxConstraints = layoutConstraints.loosen();

    // Layout all the widgets used by MongolInputDecorator
    boxToBaseline[icon] = _layoutLineBox(icon, boxConstraints);
    final BoxConstraints containerConstraints = boxConstraints.copyWith(
      maxHeight: boxConstraints.maxHeight - _boxSize(icon).height,
    );
    boxToBaseline[prefixIcon] =
        _layoutLineBox(prefixIcon, containerConstraints);
    boxToBaseline[suffixIcon] =
        _layoutLineBox(suffixIcon, containerConstraints);
    final BoxConstraints contentConstraints = containerConstraints.copyWith(
      maxHeight: containerConstraints.maxHeight - contentPadding.vertical,
    );
    boxToBaseline[prefix] = _layoutLineBox(prefix, contentConstraints);
    boxToBaseline[suffix] = _layoutLineBox(suffix, contentConstraints);

    final double inputHeight = math.max(
      0.0,
      constraints.maxHeight -
          (_boxSize(icon).height +
              contentPadding.left +
              _boxSize(prefixIcon).height +
              _boxSize(prefix).height +
              _boxSize(suffix).height +
              _boxSize(suffixIcon).height +
              contentPadding.bottom),
    );
    // Increase the available height for the label when it is scaled down.
    final double invertedLabelScale = lerpDouble(
        1.00, 1 / _kFinalLabelScale, decoration.floatingLabelProgress)!;
    double suffixIconHeight = _boxSize(suffixIcon).height;
    if (decoration.border!.isOutline) {
      suffixIconHeight =
          lerpDouble(suffixIconHeight, 0.0, decoration.floatingLabelProgress)!;
    }
    final double labelHeight = math.max(
      0.0,
      constraints.maxHeight -
          (_boxSize(icon).height +
              contentPadding.top +
              _boxSize(prefixIcon).height +
              suffixIconHeight +
              contentPadding.bottom),
    );
    boxToBaseline[label] = _layoutLineBox(
      label,
      boxConstraints.copyWith(maxHeight: labelHeight * invertedLabelScale),
    );
    boxToBaseline[hint] = _layoutLineBox(
      hint,
      boxConstraints.copyWith(minHeight: inputHeight, maxHeight: inputHeight),
    );
    boxToBaseline[counter] = _layoutLineBox(counter, contentConstraints);

    // The helper or error text can occupy the full height less the space
    // occupied by the icon and counter.
    boxToBaseline[helperError] = _layoutLineBox(
      helperError,
      contentConstraints.copyWith(
        maxHeight: math.max(
            0.0, contentConstraints.maxHeight - _boxSize(counter).height),
      ),
    );

    // The width of the input needs to accommodate label to the left and counter and
    // helperError to the right, when they exist.
    final double labelWidth = label == null ? 0 : decoration.floatingLabelWidth;
    final double leftWidth = decoration.border!.isOutline
        ? math.max(labelWidth - boxToBaseline[label]!, 0)
        : labelWidth;
    final double counterWidth =
        counter == null ? 0 : boxToBaseline[counter]! + subtextGap;
    final bool helperErrorExists =
        helperError?.size != null && helperError!.size.width > 0;
    final double helperErrorWidth =
        !helperErrorExists ? 0 : helperError!.size.width + subtextGap;
    final double rightWidth = math.max(
      counterWidth,
      helperErrorWidth,
    );
    final Offset densityOffset = decoration.visualDensity!.baseSizeAdjustment;
    boxToBaseline[input] = _layoutLineBox(
      input,
      boxConstraints
          .deflate(EdgeInsets.only(
            left: contentPadding.left + leftWidth + densityOffset.dx / 2,
            right: contentPadding.right + rightWidth + densityOffset.dx / 2,
          ))
          .copyWith(
            minHeight: inputHeight,
            maxHeight: inputHeight,
          ),
    );

    // The field can be occupied by a hint or by the input itself
    final double hintWidth = hint == null ? 0 : hint!.size.width;
    final double inputDirectWidth = input == null ? 0 : input!.size.width;
    final double inputWidth = math.max(hintWidth, inputDirectWidth);
    final double inputInternalBaseline = math.max(
      boxToBaseline[input]!,
      boxToBaseline[hint]!,
    );

    // Calculate the amount that prefix/suffix affects height above and below
    // the input.
    final double prefixWidth = prefix?.size.width ?? 0;
    final double suffixWidth = suffix?.size.width ?? 0;
    final double fixWidth = math.max(
      boxToBaseline[prefix]!,
      boxToBaseline[suffix]!,
    );
    final double fixLeftOfInput = math.max(0, fixWidth - inputInternalBaseline);
    final double fixRightOfBaseline = math.max(
      prefixWidth - boxToBaseline[prefix]!,
      suffixWidth - boxToBaseline[suffix]!,
    );
    final double fixRightOfInput = math.max(
      0,
      fixRightOfBaseline - (inputWidth - inputInternalBaseline),
    );

    // Calculate the width of the input text container.
    final double prefixIconWidth =
        prefixIcon == null ? 0 : prefixIcon!.size.width;
    final double suffixIconWidth =
        suffixIcon == null ? 0 : suffixIcon!.size.width;
    final double fixIconWidth = math.max(prefixIconWidth, suffixIconWidth);
    final double contentWidth = math.max(
      fixIconWidth,
      leftWidth +
          contentPadding.left +
          fixLeftOfInput +
          inputWidth +
          fixRightOfInput +
          contentPadding.right +
          densityOffset.dx,
    );
    final double minContainerWidth =
        decoration.isDense! || decoration.isCollapsed || expands
            ? 0.0
            : kMinInteractiveDimension;
    final double maxContainerWidth = boxConstraints.maxWidth - rightWidth;
    final double containerWidth = expands
        ? maxContainerWidth
        : math.min(
            math.max(contentWidth, minContainerWidth), maxContainerWidth);

    // Ensure the text is horizontally centered in cases where the content is
    // shorter than kMinInteractiveDimension.
    final double interactiveAdjustment = minContainerWidth > contentWidth
        ? (minContainerWidth - contentWidth) / 2.0
        : 0.0;

    // Try to consider the prefix/suffix as part of the text when aligning it.
    // If the prefix/suffix overflows however, allow it to extend outside of the
    // input and align the remaining part of the text and prefix/suffix.
    final double overflow = math.max(0, contentWidth - maxContainerWidth);
    // Map textAlignHorizontal from -1:1 to 0:1 so that it can be used to scale
    // the baseline from its minimum to maximum values.
    final double textAlignHorizontalFactor =
        (textAlignHorizontal!.x + 1.0) / 2.0;
    // Adjust to try to fit left overflow inside the input on an inverse scale of
    // textAlignHorizontal, so that left aligned text adjusts the most and right
    // aligned text doesn't adjust at all.
    final double baselineAdjustment =
        fixLeftOfInput - overflow * (1 - textAlignHorizontalFactor);

    // The baselines that will be used to draw the actual input text content.
    final double leftInputBaseline = contentPadding.left +
        leftWidth +
        inputInternalBaseline +
        baselineAdjustment +
        interactiveAdjustment;
    final double maxContentWidth =
        containerWidth - contentPadding.left - leftWidth - contentPadding.right;
    final double alignableWidth = fixLeftOfInput + inputWidth + fixRightOfInput;
    final double maxHorizontalOffset = maxContentWidth - alignableWidth;
    final double textAlignHorizontalOffset =
        maxHorizontalOffset * textAlignHorizontalFactor;
    final double inputBaseline =
        leftInputBaseline + textAlignHorizontalOffset + densityOffset.dx / 2.0;

    // The three main alignments for the baseline when an outline is present are
    //
    //  * left (-1.0): leftmost point considering padding.
    //  * center (0.0): the absolute center of the input ignoring padding but
    //      accommodating the border and floating label.
    //  * right (1.0): rightmost point considering padding.
    //
    // That means that if the padding is uneven, center is not the exact
    // midpoint of left and right. To account for this, the left of center and
    // right of center alignments are interpolated independently.
    final double outlineCenterBaseline = inputInternalBaseline +
        baselineAdjustment / 2.0 +
        (containerWidth - (2.0 + inputWidth)) / 2.0;
    final double outlineLeftBaseline = leftInputBaseline;
    final double outlineRightBaseline = leftInputBaseline + maxHorizontalOffset;
    final double outlineBaseline = _interpolateThree(
      outlineLeftBaseline,
      outlineCenterBaseline,
      outlineRightBaseline,
      textAlignHorizontal!,
    );

    // Find the positions of the text below the input when it exists.
    double subtextCounterBaseline = 0;
    double subtextHelperBaseline = 0;
    double subtextCounterWidth = 0;
    double subtextHelperWidth = 0;
    if (counter != null) {
      subtextCounterBaseline =
          containerWidth + subtextGap + boxToBaseline[counter]!;
      subtextCounterWidth = counter!.size.width + subtextGap;
    }
    if (helperErrorExists) {
      subtextHelperBaseline =
          containerWidth + subtextGap + boxToBaseline[helperError]!;
      subtextHelperWidth = helperErrorWidth;
    }
    final double subtextBaseline = math.max(
      subtextCounterBaseline,
      subtextHelperBaseline,
    );
    final double subtextWidth = math.max(
      subtextCounterWidth,
      subtextHelperWidth,
    );

    return _RenderDecorationLayout(
      boxToBaseline: boxToBaseline,
      containerWidth: containerWidth,
      inputBaseline: inputBaseline,
      outlineBaseline: outlineBaseline,
      subtextBaseline: subtextBaseline,
      subtextWidth: subtextWidth,
    );
  }

  // Interpolate between three stops using textAlignHorizontal. This is used to
  // calculate the outline baseline, which ignores padding when the alignment is
  // middle. When the alignment is less than zero, it interpolates between the
  // centered text box's left and the left of the content padding. When the
  // alignment is greater than zero, it interpolates between the centered box's
  // left and the position that would align the right of the box with the right
  // padding.
  double _interpolateThree(double begin, double middle, double end,
      TextAlignHorizontal textAlignHorizontal) {
    if (textAlignHorizontal.x <= 0) {
      // It's possible for begin, middle, and end to not be in order because of
      // excessive padding. Those cases are handled by using middle.
      if (begin >= middle) {
        return middle;
      }
      // Do a standard linear interpolation on the first half, between begin and
      // middle.
      final double t = textAlignHorizontal.x + 1;
      return begin + (middle - begin) * t;
    }

    if (middle >= end) {
      return middle;
    }
    // Do a standard linear interpolation on the second half, between middle and
    // end.
    final double t = textAlignHorizontal.x;
    return middle + (end - middle) * t;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _minHeight(icon, width) +
        contentPadding.top +
        _minHeight(prefixIcon, width) +
        _minHeight(prefix, width) +
        math.max(_minHeight(input, width), _minHeight(hint, width)) +
        _minHeight(suffix, width) +
        _minHeight(suffixIcon, width) +
        contentPadding.bottom;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _maxHeight(icon, width) +
        contentPadding.top +
        _maxHeight(prefixIcon, width) +
        _maxHeight(prefix, width) +
        math.max(_maxHeight(input, width), _maxHeight(hint, width)) +
        _maxHeight(suffix, width) +
        _maxHeight(suffixIcon, width) +
        contentPadding.bottom;
  }

  double _lineWidth(double height, List<RenderBox?> boxes) {
    double width = 0.0;
    for (final RenderBox? box in boxes) {
      if (box == null) {
        continue;
      }
      width = math.max(_minWidth(box, height), width);
    }
    return width;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double iconWidth = _minWidth(icon, height);
    final double iconHeight = _minHeight(icon, iconWidth);

    height = math.max(height - iconHeight, 0.0);

    final double prefixIconWidth = _minWidth(prefixIcon, height);
    final double prefixIconHeight = _minHeight(prefixIcon, prefixIconWidth);

    final double suffixIconWidth = _minWidth(suffixIcon, height);
    final double suffixIconHeight = _minHeight(suffixIcon, suffixIconWidth);

    height = math.max(height - contentPadding.vertical, 0.0);

    final double counterWidth = _minWidth(counter, height);
    final double counterHeight = _minHeight(counter, counterWidth);

    final double helperErrorAvailableHeight =
        math.max(height - counterHeight, 0.0);
    final double helperErrorWidth =
        _minWidth(helperError, helperErrorAvailableHeight);
    double subtextWidth = math.max(counterWidth, helperErrorWidth);
    if (subtextWidth > 0.0) {
      subtextWidth += subtextGap;
    }

    final double prefixWidth = _minWidth(prefix, height);
    final double prefixHeight = _minHeight(prefix, prefixWidth);

    final double suffixWidth = _minWidth(suffix, height);
    final double suffixHeight = _minHeight(suffix, suffixWidth);

    final double availableInputHeight = math.max(
        height -
            prefixHeight -
            suffixHeight -
            prefixIconHeight -
            suffixIconHeight,
        0.0);
    final double inputWidth =
        _lineWidth(availableInputHeight, <RenderBox?>[input, hint]);
    final double inputMaxWidth =
        <double>[inputWidth, prefixWidth, suffixWidth].reduce(math.max);

    final Offset densityOffset = decoration.visualDensity!.baseSizeAdjustment;
    final double contentWidth = contentPadding.left +
        (label == null ? 0.0 : decoration.floatingLabelWidth) +
        inputMaxWidth +
        contentPadding.right +
        densityOffset.dx;
    final double containerWidth = <double>[
      iconWidth,
      contentWidth,
      prefixIconWidth,
      suffixIconWidth
    ].reduce(math.max);
    final double minContainerWidth =
        decoration.isDense! || expands ? 0.0 : kMinInteractiveDimension;
    return math.max(containerWidth, minContainerWidth) + subtextWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return computeMinIntrinsicWidth(height);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return _boxParentData(input!).offset.dx +
        input!.computeDistanceToActualBaseline(baseline)!;
  }

  // Records where the label was painted.
  Matrix4? _labelTransform;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
      reason:
          'Layout requires baseline metrics, which are only available after a full layout.',
    ));
    return Size.zero;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _labelTransform = null;
    final _RenderDecorationLayout layout = _layout(constraints);

    final double overallHeight = constraints.maxHeight;
    final double overallWidth = layout.containerWidth + layout.subtextWidth;

    if (container != null) {
      final BoxConstraints containerConstraints = BoxConstraints.tightFor(
        width: layout.containerWidth,
        height: overallHeight - _boxSize(icon).height,
      );
      container!.layout(containerConstraints, parentUsesSize: true);
      final double y = _boxSize(icon).height;
      _boxParentData(container!).offset = Offset(0.0, y);
    }

    double? width;
    double centerLayout(RenderBox box, double y) {
      _boxParentData(box).offset = Offset((width! - box.size.width) / 2.0, y);
      return box.size.height;
    }

    double? baseline;
    double baselineLayout(RenderBox box, double y) {
      _boxParentData(box).offset =
          Offset(baseline! - layout.boxToBaseline[box]!, y);
      return box.size.height;
    }

    final double top = contentPadding.top;
    final double bottom = overallHeight - contentPadding.bottom;

    width = layout.containerWidth;
    baseline =
        _isOutlineAligned ? layout.outlineBaseline : layout.inputBaseline;

    if (icon != null) {
      final double y = 0.0;
      centerLayout(icon!, y);
    }

    double start = top + _boxSize(icon).height;
    double end = bottom;
    if (prefixIcon != null) {
      start -= contentPadding.top;
      start += centerLayout(prefixIcon!, start);
    }
    if (label != null) {
      if (decoration.alignLabelWithHint) {
        baselineLayout(label!, start);
      } else {
        centerLayout(label!, start);
      }
    }
    if (prefix != null) {
      start += baselineLayout(prefix!, start);
    }
    if (input != null) {
      baselineLayout(input!, start);
    }
    if (hint != null) {
      baselineLayout(hint!, start);
    }
    if (suffixIcon != null) {
      end += contentPadding.bottom;
      end -= centerLayout(suffixIcon!, end - suffixIcon!.size.height);
    }
    if (suffix != null) {
      end -= baselineLayout(suffix!, end - suffix!.size.height);
    }

    if (helperError != null || counter != null) {
      width = layout.subtextWidth;
      baseline = layout.subtextBaseline;
      if (helperError != null) {
        baselineLayout(helperError!, top + _boxSize(icon).height);
      }
      if (counter != null) {
        baselineLayout(counter!, bottom - counter!.size.height);
      }
    }

    if (label != null) {
      final double labelY = _boxParentData(label!).offset.dy;
      // +1 shifts the range of y from (-1.0, 1.0) to (0.0, 2.0).
      final double floatAlign = decoration.floatingLabelAlignment._y + 1;
      final double floatHeight = _boxSize(label).height * _kFinalLabelScale;
      // When floating label is centered, its y is relative to
      // _BorderContainer's y and is independent of label's y.

      // The value of _InputBorderGap.start is relative to the origin of the
      // _BorderContainer which is inset by the icon's height. Although, when
      // floating label is centered, it's already relative to _BorderContainer.
      decoration.borderGap!.start = lerpDouble(labelY - _boxSize(icon).height,
          _boxSize(container).height / 2.0 - floatHeight / 2.0, floatAlign);

      decoration.borderGap!.extent = label!.size.height * _kFinalLabelScale;
    } else {
      decoration.borderGap!.start = null;
      decoration.borderGap!.extent = 0.0;
    }

    size = constraints.constrain(Size(overallWidth, overallHeight));
    assert(size.width == constraints.constrainWidth(overallWidth));
    assert(size.height == constraints.constrainHeight(overallHeight));
  }

  void _paintLabel(PaintingContext context, Offset offset) {
    context.paintChild(label!, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox? child) {
      if (child != null) {
        context.paintChild(child, _boxParentData(child).offset + offset);
      }
    }

    doPaint(container);

    if (label != null) {
      final Offset labelOffset = _boxParentData(label!).offset;
      final double labelWidth = _boxSize(label).width;
      final double labelHeight = _boxSize(label).height;
      // +1 shifts the range of y from (-1.0, 1.0) to (0.0, 2.0).
      final double floatAlign = decoration.floatingLabelAlignment._y + 1;
      final double floatHeight = labelHeight * _kFinalLabelScale;
      final double borderWeight = decoration.border!.borderSide.width;
      final double t = decoration.floatingLabelProgress;
      // The center of the outline border label ends up a little to the right of the
      // center of the left border line.
      final bool isOutlineBorder =
          decoration.border != null && decoration.border!.isOutline;
      // Center the scaled label relative to the border.
      final double floatingX = isOutlineBorder
          ? (-labelWidth * _kFinalLabelScale) / 2.0 + borderWeight / 2.0
          : contentPadding.left;
      final double scale = lerpDouble(1.0, _kFinalLabelScale, t)!;
      final double centeredFloatY = _boxParentData(container!).offset.dy +
          _boxSize(container).height / 2.0 -
          floatHeight / 2.0;
      final double floatStartY = labelOffset.dy;
      final double floatEndY =
          lerpDouble(floatStartY, centeredFloatY, floatAlign)!;
      final double dy = lerpDouble(floatStartY, floatEndY, t)!;
      final double dx = lerpDouble(0.0, floatingX - labelOffset.dx, t)!;
      _labelTransform = Matrix4.identity()
        ..translate(labelOffset.dx + dx, dy)
        ..scale(scale);
      layer = context.pushTransform(
        needsCompositing,
        offset,
        _labelTransform!,
        _paintLabel,
        oldLayer: layer as TransformLayer?,
      );
    } else {
      layer = null;
    }

    doPaint(icon);
    doPaint(prefix);
    doPaint(suffix);
    doPaint(prefixIcon);
    doPaint(suffixIcon);
    doPaint(hint);
    doPaint(input);
    doPaint(helperError);
    doPaint(counter);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox child in children) {
      // The label must be handled specially since we've transformed it.
      final Offset offset = _boxParentData(child).offset;
      final bool isHit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == label && _labelTransform != null) {
      final Offset labelOffset = _boxParentData(label!).offset;
      transform
        ..multiply(_labelTransform!)
        ..translate(-labelOffset.dx, -labelOffset.dy);
    }
    super.applyPaintTransform(child, transform);
  }
}

class _Decorator extends RenderObjectWidget
    with SlottedMultiChildRenderObjectWidgetMixin<_DecorationSlot> {
  const _Decorator({
    required this.textAlignHorizontal,
    required this.decoration,
    required this.textBaseline,
    required this.isFocused,
    required this.expands,
  });

  final _Decoration decoration;
  final TextBaseline textBaseline;
  final TextAlignHorizontal? textAlignHorizontal;
  final bool isFocused;
  final bool expands;

  @override
  Iterable<_DecorationSlot> get slots => _DecorationSlot.values;

  @override
  Widget? childForSlot(_DecorationSlot slot) {
    switch (slot) {
      case _DecorationSlot.icon:
        return decoration.icon;
      case _DecorationSlot.input:
        return decoration.input;
      case _DecorationSlot.label:
        return decoration.label;
      case _DecorationSlot.hint:
        return decoration.hint;
      case _DecorationSlot.prefix:
        return decoration.prefix;
      case _DecorationSlot.suffix:
        return decoration.suffix;
      case _DecorationSlot.prefixIcon:
        return decoration.prefixIcon;
      case _DecorationSlot.suffixIcon:
        return decoration.suffixIcon;
      case _DecorationSlot.helperError:
        return decoration.helperError;
      case _DecorationSlot.counter:
        return decoration.counter;
      case _DecorationSlot.container:
        return decoration.container;
    }
  }

  @override
  _RenderDecoration createRenderObject(BuildContext context) {
    return _RenderDecoration(
      decoration: decoration,
      textBaseline: textBaseline,
      textAlignHorizontal: textAlignHorizontal,
      isFocused: isFocused,
      expands: expands,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderDecoration renderObject) {
    renderObject
      ..decoration = decoration
      ..expands = expands
      ..isFocused = isFocused
      ..textAlignHorizontal = textAlignHorizontal
      ..textBaseline = textBaseline;
  }
}

class _AffixText extends StatelessWidget {
  const _AffixText({
    required this.labelIsFloating,
    this.text,
    this.style,
    this.child,
  });

  final bool labelIsFloating;
  final String? text;
  final TextStyle? style;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: style,
      child: AnimatedOpacity(
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        opacity: labelIsFloating ? 1.0 : 0.0,
        child: child ??
            (text == null
                ? null
                : MongolText(
                    text!,
                    style: style,
                  )),
      ),
    );
  }
}

/// Defines the appearance of a Material Design Mongol text field.
///
/// [MongolInputDecorator] displays the visual elements of a Material Design text
/// Mongol field around its input [child]. The visual elements themselves are defined
/// by an [InputDecoration] object and their layout and appearance depend
/// on the `baseStyle`, `textAlign`, `isFocused`, and `isEmpty` parameters.
///
/// [MongolTextField] uses this widget to decorate its [MongolEditableText] child.
///
/// [MongolInputDecorator] can be used to create widgets that look and behave like a
/// [MongolTextField] but support other kinds of input.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [MongolTextField], which uses a [MongolInputDecorator] to display a border,
///    labels, and icons, around its [MongolEditableText] child.
///  * [Decoration] and [DecoratedBox], for drawing arbitrary decorations
///    around other widgets.
class MongolInputDecorator extends StatefulWidget {
  /// Creates a widget that displays a border, labels, and icons,
  /// for a [MongolTextField].
  ///
  /// The [isFocused], [isHovering], [expands], and [isEmpty] arguments must not
  /// be null.
  const MongolInputDecorator({
    super.key,
    required this.decoration,
    this.baseStyle,
    this.textAlign,
    this.textAlignHorizontal,
    this.isFocused = false,
    this.isHovering = false,
    this.expands = false,
    this.isEmpty = false,
    this.child,
  });

  /// The text and styles to use when decorating the child.
  ///
  /// Null [InputDecoration] properties are initialized with the corresponding
  /// values from [ThemeData.inputDecorationTheme].
  ///
  /// Must not be null.
  final InputDecoration decoration;

  /// The style on which to base the label, hint, counter, and error styles
  /// if the [decoration] does not provide explicit styles.
  ///
  /// If null, `baseStyle` defaults to the `subtitle1` style from the
  /// current [Theme], see [ThemeData.textTheme].
  ///
  /// The [TextStyle.textBaseline] of the [baseStyle] is used to determine
  /// the baseline used for text alignment.
  final TextStyle? baseStyle;

  /// How the text in the decoration should be aligned vertically.
  final MongolTextAlign? textAlign;

  /// How the text should be aligned horizontally.
  ///
  /// Determines the alignment of the baseline within the available space of
  /// the input (typically a `MongolTextField`). For example,
  /// `TextAlignHorizontal.left` will place the baseline such that the text,
  /// and any attached decoration like prefix and suffix, is as close to the
  /// left side of the input as possible without overflowing. The widths of the
  /// prefix and suffix are similarly included for other alignment values. If
  /// the width is greater than the width available, then the prefix and suffix
  /// will be allowed to overflow first before the text scrolls.
  final TextAlignHorizontal? textAlignHorizontal;

  /// Whether the input field has focus.
  ///
  /// Determines the position of the label text and the color and weight of the
  /// border.
  ///
  /// Defaults to false.
  ///
  /// See also:
  ///
  ///  * [InputDecoration.hoverColor], which is also blended into the focus
  ///    color and fill color when the [isHovering] is true to produce the final
  ///    color.
  final bool isFocused;

  /// Whether the input field is being hovered over by a mouse pointer.
  ///
  /// Determines the container fill color, which is a blend of
  /// [InputDecoration.hoverColor] with [InputDecoration.fillColor] when
  /// true, and [InputDecoration.fillColor] when not.
  ///
  /// Defaults to false.
  final bool isHovering;

  /// If true, the width of the input field will be as large as possible.
  ///
  /// If wrapped in a widget that constrains its child's width, like Expanded
  /// or SizedBox, the input field will only be affected if [expands] is set to
  /// true.
  ///
  /// See [MongolTextField.minLines] and [MongolTextField.maxLines] for related
  /// ways to affect the width of an input. When [expands] is true, both must
  /// be null in order to avoid ambiguity in determining the width.
  ///
  /// Defaults to false.
  final bool expands;

  /// Whether the input field is empty.
  ///
  /// Determines the position of the label text and whether to display the hint
  /// text.
  ///
  /// Defaults to false.
  final bool isEmpty;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [MongolEditableText], [DropdownButton], or [InkWell].
  final Widget? child;

  /// Whether the label needs to get out of the way of the input, either by
  /// floating or disappearing.
  ///
  /// Will withdraw when not empty, or when focused while enabled.
  bool get _labelShouldWithdraw =>
      !isEmpty || (isFocused && decoration.enabled);

  @override
  State<MongolInputDecorator> createState() => _InputDecoratorState();

  /// The RenderBox that defines this decorator's "container". That's the
  /// area which is filled if [InputDecoration.filled] is true. It's the area
  /// adjacent to [InputDecoration.icon] and to the left of the widgets that contain
  /// [InputDecoration.helperText], [InputDecoration.errorText], and
  /// [InputDecoration.counterText].
  ///
  /// [MongolTextField] renders ink splashes within the container.
  static RenderBox? containerOf(BuildContext context) {
    final result = context.findAncestorRenderObjectOfType<_RenderDecoration>();
    return result?.container;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<InputDecoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<TextStyle>('baseStyle', baseStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('isFocused', isFocused));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('isEmpty', isEmpty));
  }
}

class _InputDecoratorState extends State<MongolInputDecorator>
    with TickerProviderStateMixin {
  late AnimationController _floatingLabelController;
  late AnimationController _shakingLabelController;
  final _InputBorderGap _borderGap = _InputBorderGap();

  @override
  void initState() {
    super.initState();

    final labelIsInitiallyFloating = widget.decoration.floatingLabelBehavior ==
            FloatingLabelBehavior.always ||
        (widget.decoration.floatingLabelBehavior !=
                FloatingLabelBehavior.never &&
            widget._labelShouldWithdraw);

    _floatingLabelController = AnimationController(
        duration: _kTransitionDuration,
        vsync: this,
        value: labelIsInitiallyFloating ? 1.0 : 0.0);
    _floatingLabelController.addListener(_handleChange);

    _shakingLabelController = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _effectiveDecoration = null;
  }

  @override
  void dispose() {
    _floatingLabelController.dispose();
    _shakingLabelController.dispose();
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The _floatingLabelController's value has changed.
    });
  }

  InputDecoration? _effectiveDecoration;
  InputDecoration? get decoration {
    _effectiveDecoration ??= widget.decoration.applyDefaults(
      Theme.of(context).inputDecorationTheme,
    );
    return _effectiveDecoration;
  }

  MongolTextAlign? get textAlign => widget.textAlign;
  bool get isFocused => widget.isFocused;
  bool get isHovering => widget.isHovering && decoration!.enabled;
  bool get isEmpty => widget.isEmpty;
  bool get _floatingLabelEnabled {
    return decoration!.floatingLabelBehavior != FloatingLabelBehavior.never;
  }

  @override
  void didUpdateWidget(MongolInputDecorator old) {
    super.didUpdateWidget(old);
    if (widget.decoration != old.decoration) {
      _effectiveDecoration = null;
    }

    final floatBehaviorChanged = widget.decoration.floatingLabelBehavior !=
        old.decoration.floatingLabelBehavior;

    if (widget._labelShouldWithdraw != old._labelShouldWithdraw ||
        floatBehaviorChanged) {
      if (_floatingLabelEnabled &&
          (widget._labelShouldWithdraw ||
              widget.decoration.floatingLabelBehavior ==
                  FloatingLabelBehavior.always)) {
        _floatingLabelController.forward();
      } else {
        _floatingLabelController.reverse();
      }
    }

    final String? errorText = decoration!.errorText;
    final String? oldErrorText = old.decoration.errorText;

    if (_floatingLabelController.isCompleted &&
        errorText != null &&
        errorText != oldErrorText) {
      _shakingLabelController
        ..value = 0.0
        ..forward();
    }
  }

  Color _getActiveColor(ThemeData themeData) {
    if (isFocused) {
      return themeData.colorScheme.primary;
    }
    return themeData.hintColor;
  }

  Color _getDefaultBorderColor(ThemeData themeData) {
    if (isFocused) {
      return themeData.colorScheme.primary;
    }
    if (decoration!.filled!) {
      return themeData.hintColor;
    }
    final Color enabledColor =
        themeData.colorScheme.onSurface.withOpacity(0.38);
    if (isHovering) {
      final Color hoverColor = decoration!.hoverColor ??
          themeData.inputDecorationTheme.hoverColor ??
          themeData.hoverColor;
      return Color.alphaBlend(hoverColor.withOpacity(0.12), enabledColor);
    }
    return enabledColor;
  }

  Color _getFillColor(ThemeData themeData) {
    if (decoration!.filled != true) {
      // filled == null same as filled == false
      return Colors.transparent;
    }
    if (decoration!.fillColor != null) {
      return MaterialStateProperty.resolveAs(
          decoration!.fillColor!, materialState);
    }

    // dark theme: 10% white (enabled), 5% white (disabled)
    // light theme: 4% black (enabled), 2% black (disabled)
    const Color darkEnabled = Color(0x1AFFFFFF);
    const Color darkDisabled = Color(0x0DFFFFFF);
    const Color lightEnabled = Color(0x0A000000);
    const Color lightDisabled = Color(0x05000000);

    switch (themeData.brightness) {
      case Brightness.dark:
        return decoration!.enabled ? darkEnabled : darkDisabled;
      case Brightness.light:
        return decoration!.enabled ? lightEnabled : lightDisabled;
    }
  }

  Color _getHoverColor(ThemeData themeData) {
    if (decoration!.filled == null ||
        !decoration!.filled! ||
        isFocused ||
        !decoration!.enabled) {
      return Colors.transparent;
    }
    return decoration!.hoverColor ??
        themeData.inputDecorationTheme.hoverColor ??
        themeData.hoverColor;
  }

  Color _getIconColor(ThemeData themeData) {
    Color resolveIconColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled) &&
          !states.contains(MaterialState.focused)) {
        return themeData.disabledColor;
      }

      if (states.contains(MaterialState.focused)) {
        return themeData.colorScheme.primary;
      }

      switch (themeData.brightness) {
        case Brightness.dark:
          return Colors.white70;
        case Brightness.light:
          return Colors.black45;
      }
    }

    return MaterialStateProperty.resolveAs(
            themeData.inputDecorationTheme.iconColor, materialState) ??
        MaterialStateProperty.resolveWith(resolveIconColor)
            .resolve(materialState);
  }

  Color _getPrefixIconColor(ThemeData themeData) {
    return MaterialStateProperty.resolveAs(
            themeData.inputDecorationTheme.prefixIconColor, materialState) ??
        _getIconColor(themeData);
  }

  Color _getSuffixIconColor(ThemeData themeData) {
    return MaterialStateProperty.resolveAs(
            themeData.inputDecorationTheme.suffixIconColor, materialState) ??
        _getIconColor(themeData);
  }

  // True if the label will be shown and the hint will not.
  // If we're not focused, there's no value, labelText was provided, and
  // floatingLabelBehavior isn't set to always, then the label appears where the
  // hint would.
  bool get _hasInlineLabel {
    return !widget._labelShouldWithdraw &&
        (decoration!.labelText != null || decoration!.label != null) &&
        decoration!.floatingLabelBehavior != FloatingLabelBehavior.always;
  }

  // If the label is a floating placeholder, it's always shown.
  bool get _shouldShowLabel => _hasInlineLabel || _floatingLabelEnabled;

  // The base style for the inline label when they're displayed "inline",
  // i.e. when they appear in place of the empty text field.
  TextStyle _getInlineLabelStyle(ThemeData themeData) {
    final TextStyle defaultStyle = TextStyle(
      color:
          decoration!.enabled ? themeData.hintColor : themeData.disabledColor,
    );

    final TextStyle? style = MaterialStateProperty.resolveAs(
            decoration!.labelStyle, materialState) ??
        MaterialStateProperty.resolveAs(
            themeData.inputDecorationTheme.labelStyle, materialState);

    return themeData.textTheme.subtitle1!
        .merge(widget.baseStyle)
        .merge(defaultStyle)
        .merge(style)
        .copyWith(height: 1);
  }

  // The base style for the inline hint when they're displayed "inline",
  // i.e. when they appear in place of the empty text field.
  TextStyle _getInlineHintStyle(ThemeData themeData) {
    final TextStyle defaultStyle = TextStyle(
      color:
          decoration!.enabled ? themeData.hintColor : themeData.disabledColor,
    );

    final TextStyle? style =
        MaterialStateProperty.resolveAs(decoration!.hintStyle, materialState) ??
            MaterialStateProperty.resolveAs(
                themeData.inputDecorationTheme.hintStyle, materialState);

    return themeData.textTheme.subtitle1!
        .merge(widget.baseStyle)
        .merge(defaultStyle)
        .merge(style);
  }

  TextStyle _getFloatingLabelStyle(ThemeData themeData) {
    TextStyle getFallbackTextStyle() {
      final Color color = decoration!.errorText != null
          ? decoration!.errorStyle?.color ?? themeData.errorColor
          : _getActiveColor(themeData);

      return TextStyle(
              color: decoration!.enabled ? color : themeData.disabledColor)
          .merge(decoration!.floatingLabelStyle ?? decoration!.labelStyle);
    }

    final TextStyle? style = MaterialStateProperty.resolveAs(
            decoration!.floatingLabelStyle, materialState) ??
        MaterialStateProperty.resolveAs(
            themeData.inputDecorationTheme.floatingLabelStyle, materialState);

    return themeData.textTheme.subtitle1!
        .merge(widget.baseStyle)
        .copyWith(height: 1)
        .merge(getFallbackTextStyle())
        .merge(style);
  }

  TextStyle _getHelperStyle(ThemeData themeData) {
    final Color color =
        decoration!.enabled ? themeData.hintColor : Colors.transparent;
    return themeData.textTheme.caption!.copyWith(color: color).merge(
        MaterialStateProperty.resolveAs(
            decoration!.helperStyle, materialState));
  }

  TextStyle _getErrorStyle(ThemeData themeData) {
    final Color color =
        decoration!.enabled ? themeData.errorColor : Colors.transparent;
    return themeData.textTheme.caption!
        .copyWith(color: color)
        .merge(decoration!.errorStyle);
  }

  Set<MaterialState> get materialState {
    return <MaterialState>{
      if (!decoration!.enabled) MaterialState.disabled,
      if (isFocused) MaterialState.focused,
      if (isHovering) MaterialState.hovered,
      if (decoration!.errorText != null) MaterialState.error,
    };
  }

  InputBorder _getDefaultBorder(ThemeData themeData) {
    final InputBorder border =
        MaterialStateProperty.resolveAs(decoration!.border, materialState) ??
            const SidelineInputBorder();

    if (decoration!.border is MaterialStateProperty<InputBorder>) {
      return border;
    }

    if (border.borderSide == BorderSide.none) {
      return border;
    }

    final Color borderColor;
    if (decoration!.enabled || isFocused) {
      borderColor = decoration!.errorText == null
          ? _getDefaultBorderColor(themeData)
          : themeData.errorColor;
    } else {
      borderColor = ((decoration!.filled ?? false) &&
              !(decoration!.border?.isOutline ?? false))
          ? Colors.transparent
          : themeData.disabledColor;
    }

    final double borderWeight;
    if (decoration!.isCollapsed ||
        decoration?.border == InputBorder.none ||
        !decoration!.enabled) {
      borderWeight = 0.0;
    } else {
      borderWeight = isFocused ? 2.0 : 1.0;
    }

    return border.copyWith(
        borderSide: BorderSide(color: borderColor, width: borderWeight));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle labelStyle = _getInlineLabelStyle(themeData);
    final TextBaseline textBaseline = labelStyle.textBaseline!;

    final TextStyle hintStyle = _getInlineHintStyle(themeData);
    final Widget? hint = decoration!.hintText == null
        ? null
        : AnimatedOpacity(
            opacity: (isEmpty && !_hasInlineLabel) ? 1.0 : 0.0,
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            alwaysIncludeSemantics: true,
            child: MongolText(
              decoration!.hintText!,
              style: hintStyle,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              maxLines: decoration!.hintMaxLines,
            ),
          );

    final bool isError = decoration!.errorText != null;
    InputBorder? border;
    if (!decoration!.enabled) {
      border = isError ? decoration!.errorBorder : decoration!.disabledBorder;
    } else if (isFocused) {
      border =
          isError ? decoration!.focusedErrorBorder : decoration!.focusedBorder;
    } else {
      border = isError ? decoration!.errorBorder : decoration!.enabledBorder;
    }
    border ??= _getDefaultBorder(themeData);

    final Widget container = _BorderContainer(
      border: border,
      gap: _borderGap,
      gapAnimation: _floatingLabelController.view,
      fillColor: _getFillColor(themeData),
      hoverColor: _getHoverColor(themeData),
      isHovering: isHovering,
    );

    final Widget? label =
        decoration!.labelText == null && decoration!.label == null
            ? null
            : _Shaker(
                animation: _shakingLabelController.view,
                child: AnimatedOpacity(
                  duration: _kTransitionDuration,
                  curve: _kTransitionCurve,
                  opacity: _shouldShowLabel ? 1.0 : 0.0,
                  child: AnimatedDefaultTextStyle(
                    duration: _kTransitionDuration,
                    curve: _kTransitionCurve,
                    style: widget._labelShouldWithdraw
                        ? _getFloatingLabelStyle(themeData)
                        : labelStyle,
                    child: decoration!.label ??
                        MongolText(
                          decoration!.labelText!,
                          overflow: TextOverflow.ellipsis,
                          textAlign: textAlign,
                        ),
                  ),
                ),
              );

    final Widget? prefix =
        decoration!.prefix == null && decoration!.prefixText == null
            ? null
            : _AffixText(
                labelIsFloating: widget._labelShouldWithdraw,
                text: decoration!.prefixText,
                style: MaterialStateProperty.resolveAs(
                        decoration!.prefixStyle, materialState) ??
                    hintStyle,
                child: decoration!.prefix,
              );

    final Widget? suffix =
        decoration!.suffix == null && decoration!.suffixText == null
            ? null
            : _AffixText(
                labelIsFloating: widget._labelShouldWithdraw,
                text: decoration!.suffixText,
                style: MaterialStateProperty.resolveAs(
                        decoration!.suffixStyle, materialState) ??
                    hintStyle,
                child: decoration!.suffix,
              );

    final bool decorationIsDense = decoration!.isDense ?? false;
    final double iconSize = decorationIsDense ? 18.0 : 24.0;

    final Widget? icon = decoration!.icon == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 16.0),
            child: IconTheme.merge(
              data: IconThemeData(
                color: _getIconColor(themeData),
                size: iconSize,
              ),
              child: decoration!.icon!,
            ),
          );

    final Widget? prefixIcon = decoration!.prefixIcon == null
        ? null
        : Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: decoration!.prefixIconConstraints ??
                  themeData.visualDensity.effectiveConstraints(
                    const BoxConstraints(
                      minWidth: kMinInteractiveDimension,
                      minHeight: kMinInteractiveDimension,
                    ),
                  ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: _getPrefixIconColor(themeData),
                  size: iconSize,
                ),
                child: decoration!.prefixIcon!,
              ),
            ),
          );

    final Widget? suffixIcon = decoration!.suffixIcon == null
        ? null
        : Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: decoration!.suffixIconConstraints ??
                  themeData.visualDensity.effectiveConstraints(
                    const BoxConstraints(
                      minWidth: kMinInteractiveDimension,
                      minHeight: kMinInteractiveDimension,
                    ),
                  ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: _getSuffixIconColor(themeData),
                  size: iconSize,
                ),
                child: decoration!.suffixIcon!,
              ),
            ),
          );

    final Widget helperError = _HelperError(
      textAlign: textAlign,
      helperText: decoration!.helperText,
      helperStyle: _getHelperStyle(themeData),
      helperMaxLines: decoration!.helperMaxLines,
      errorText: decoration!.errorText,
      errorStyle: _getErrorStyle(themeData),
      errorMaxLines: decoration!.errorMaxLines,
    );

    Widget? counter;
    if (decoration!.counter != null) {
      counter = decoration!.counter;
    } else if (decoration!.counterText != null &&
        decoration!.counterText != '') {
      counter = Semantics(
        container: true,
        liveRegion: isFocused,
        child: MongolText(
          decoration!.counterText!,
          style: _getHelperStyle(themeData).merge(
              MaterialStateProperty.resolveAs(
                  decoration!.counterStyle, materialState)),
          overflow: TextOverflow.ellipsis,
          semanticsLabel: decoration!.semanticCounterText,
        ),
      );
    }

    // The _Decoration widget and _RenderDecoration assume that contentPadding
    // has been resolved to EdgeInsets.
    const textDirection = TextDirection.ltr;
    final EdgeInsets? decorationContentPadding =
        decoration!.contentPadding?.resolve(textDirection);

    final EdgeInsets contentPadding;
    final double floatingLabelWidth;
    if (decoration!.isCollapsed) {
      floatingLabelWidth = 0.0;
      contentPadding = decorationContentPadding ?? EdgeInsets.zero;
    } else if (!border.isOutline) {
      // 4.0: the horizontal gap between the inline elements and the floating label.
      floatingLabelWidth = (4.0 + 0.75 * labelStyle.fontSize!) *
          MediaQuery.textScaleFactorOf(context);
      if (decoration!.filled ?? false) {
        contentPadding = decorationContentPadding ??
            (decorationIsDense
                ? const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0)
                : const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0));
      } else {
        // Not top or bottom padding for sideline borders that aren't filled
        // is a small concession to backwards compatibility. This eliminates
        // the most noticeable layout change introduced by #13734.
        contentPadding = decorationContentPadding ??
            (decorationIsDense
                ? const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0)
                : const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0));
      }
    } else {
      floatingLabelWidth = 0.0;
      contentPadding = decorationContentPadding ??
          (decorationIsDense
              ? const EdgeInsets.fromLTRB(20.0, 12.0, 12.0, 12.0)
              : const EdgeInsets.fromLTRB(24.0, 12.0, 16.0, 12.0));
    }

    final _Decorator decorator = _Decorator(
      decoration: _Decoration(
          contentPadding: contentPadding,
          isCollapsed: decoration!.isCollapsed,
          floatingLabelWidth: floatingLabelWidth,
          floatingLabelAlignment: decoration!.floatingLabelAlignment!,
          floatingLabelProgress: _floatingLabelController.value,
          border: border,
          borderGap: _borderGap,
          alignLabelWithHint: decoration!.alignLabelWithHint ?? false,
          isDense: decoration!.isDense,
          visualDensity: themeData.visualDensity,
          icon: icon,
          input: widget.child,
          label: label,
          hint: hint,
          prefix: prefix,
          suffix: suffix,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          helperError: helperError,
          counter: counter,
          container: container),
      textBaseline: textBaseline,
      textAlignHorizontal: widget.textAlignHorizontal,
      isFocused: isFocused,
      expands: widget.expands,
    );

    final BoxConstraints? constraints =
        decoration!.constraints ?? themeData.inputDecorationTheme.constraints;
    if (constraints != null) {
      return ConstrainedBox(
        constraints: constraints,
        child: decorator,
      );
    }
    return decorator;
  }
}

// /// The border, labels, icons, and styles used to decorate a MongolTextField.
// ///
// /// The [MongolTextField] and [MongolInputDecorator] classes use
// /// [InputDecoration] objects to describe their decoration. (In fact,
// /// this class is merely the configuration of a [MongolInputDecorator], which
// /// does all the heavy lifting.)
// ///
// /// See also:
// ///
// ///  * [MongolTextField], which is a text input widget that uses a
// ///    [InputDecoration].
// ///  * [MongolInputDecorator], which is a widget that draws a [InputDecoration]
// ///    around an input child widget.
// ///  * [Decoration] and [DecoratedBox], for drawing borders and backgrounds
// ///    around a child widget.
// @immutable
// class MongolInputDecoration {
//   /// Creates a bundle of the border, labels, icons, and styles used to
//   /// decorate a Mongol text field.
//   ///
//   /// Unless specified by [ThemeData.inputDecorationTheme], [MongolInputDecorator]
//   /// defaults [isDense] to false and [filled] to false. The default border is
//   /// an instance of [SidelineInputBorder]. If [border] is [InputBorder.none]
//   /// then no border is drawn.
//   ///
//   /// The [enabled] argument must not be null.
//   ///
//   /// Only one of [prefix] and [prefixText] can be specified.
//   ///
//   /// Similarly, only one of [suffix] and [suffixText] can be specified.
//   const MongolInputDecoration({
//     this.icon,
//     this.iconColor,
//     this.label,
//     this.labelText,
//     this.labelStyle,
//     this.floatingLabelStyle,
//     this.helperText,
//     this.helperStyle,
//     this.helperMaxLines,
//     this.hintText,
//     this.hintStyle,
//     this.hintMaxLines,
//     this.errorText,
//     this.errorStyle,
//     this.errorMaxLines,
//     this.floatingLabelBehavior,
//     this.floatingLabelAlignment,
//     this.isCollapsed = false,
//     this.isDense,
//     this.contentPadding,
//     this.prefixIcon,
//     this.prefixIconConstraints,
//     this.prefix,
//     this.prefixText,
//     this.prefixStyle,
//     this.prefixIconColor,
//     this.suffixIcon,
//     this.suffix,
//     this.suffixText,
//     this.suffixStyle,
//     this.suffixIconColor,
//     this.suffixIconConstraints,
//     this.counter,
//     this.counterText,
//     this.counterStyle,
//     this.filled,
//     this.fillColor,
//     this.focusColor,
//     this.hoverColor,
//     this.errorBorder,
//     this.focusedBorder,
//     this.focusedErrorBorder,
//     this.disabledBorder,
//     this.enabledBorder,
//     this.border,
//     this.enabled = true,
//     this.semanticCounterText,
//     this.alignLabelWithHint,
//     this.constraints,
//   })  : assert(!(label != null && labelText != null),
//             'Declaring both label and labelText is not supported.'),
//         assert(!(prefix != null && prefixText != null),
//             'Declaring both prefix and prefixText is not supported.'),
//         assert(!(suffix != null && suffixText != null),
//             'Declaring both suffix and suffixText is not supported.');

//   /// Defines a [MongolInputDecorator] that is the same size as the input field.
//   ///
//   /// This type of input decoration does not include a border by default.
//   ///
//   /// Sets the [isCollapsed] property to true.
//   const MongolInputDecoration.collapsed({
//     required this.hintText,
//     this.floatingLabelBehavior,
//     this.floatingLabelAlignment,
//     this.hintStyle,
//     this.filled = false,
//     this.fillColor,
//     this.focusColor,
//     this.hoverColor,
//     this.border = InputBorder.none,
//     this.enabled = true,
//   })  : icon = null,
//         iconColor = null,
//         label = null,
//         labelText = null,
//         labelStyle = null,
//         floatingLabelStyle = null,
//         helperText = null,
//         helperStyle = null,
//         helperMaxLines = null,
//         hintMaxLines = null,
//         errorText = null,
//         errorStyle = null,
//         errorMaxLines = null,
//         isDense = false,
//         contentPadding = EdgeInsets.zero,
//         isCollapsed = true,
//         prefixIcon = null,
//         prefix = null,
//         prefixText = null,
//         prefixStyle = null,
//         prefixIconColor = null,
//         prefixIconConstraints = null,
//         suffix = null,
//         suffixIcon = null,
//         suffixText = null,
//         suffixStyle = null,
//         suffixIconColor = null,
//         suffixIconConstraints = null,
//         counter = null,
//         counterText = null,
//         counterStyle = null,
//         errorBorder = null,
//         focusedBorder = null,
//         focusedErrorBorder = null,
//         disabledBorder = null,
//         enabledBorder = null,
//         semanticCounterText = null,
//         alignLabelWithHint = false,
//         constraints = null;

//   /// An icon to show before the input field and outside of the decoration's
//   /// container.
//   ///
//   /// The size and color of the icon is configured automatically using an
//   /// [IconTheme] and therefore does not need to be explicitly given in the
//   /// icon widget.
//   ///
//   /// The trailing edge of the icon is padded by 16dps.
//   ///
//   /// The decoration's container is the area which is filled if [filled] is
//   /// true and bordered per the [border]. It's the area adjacent to
//   /// [icon] and next to the widgets that contain [helperText],
//   /// [errorText], and [counterText].
//   ///
//   /// See [Icon], [ImageIcon].
//   final Widget? icon;

//   /// The color of the [icon].
//   ///
//   /// If [iconColor] is a [MaterialStateColor], then the effective
//   /// color can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   final Color? iconColor;

//   /// Optional widget that describes the input field.
//   ///
//   /// When the input field is empty and unfocused, the label is displayed at the
//   /// left of the input field (i.e., at the same location on the screen where
//   /// text may be entered in the input field). When the input field receives
//   /// focus (or if the field is non-empty), depending on [floatingLabelAlignment],
//   /// the label moves to the left, either horizontally adjacent to, or to the center of
//   /// the input field.
//   ///
//   /// This can be used, for example, to add multiple [TextStyle]'s to a label that would
//   /// otherwise be specified using [labelText], which only takes one [TextStyle].
//   ///
//   /// Only one of [label] and [labelText] can be specified.
//   final Widget? label;

//   /// Optional text that describes the input field.
//   ///
//   /// If a more elaborate label is required, consider using [label] instead.
//   /// Only one of [label] and [labelText] can be specified.
//   final String? labelText;

//   /// The style to use for [MongolInputDecoration.labelText] when the label is to the left
//   /// of the input field.
//   ///
//   /// If [labelStyle] is a [MaterialStateTextStyle], then the effective
//   /// text style can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   ///
//   /// When the [MongolInputDecoration.labelText] is left of (i.e., horizontally adjacent to)
//   /// the input field, the text uses the [floatingLabelStyle] instead.
//   ///
//   /// If null, defaults to a value derived from the base [TextStyle] for the
//   /// input field and the current [Theme].
//   ///
//   /// Note that if you specify this style it will override the default behavior
//   /// of [MongolInputDecoration] that changes the color of the label to the
//   /// [MongolInputDecoration.errorStyle] color or [ThemeData.errorColor].
//   final TextStyle? labelStyle;

//   /// The style to use for [MongolInputDecoration.labelText] when the label is
//   /// left of (i.e., horizontally adjacent to) the input field.
//   ///
//   /// When the [MongolInputDecoration.labelText] is left of the input field, the
//   /// text uses the [labelStyle] instead.
//   ///
//   /// If [floatingLabelStyle] is a [MaterialStateTextStyle], then the effective
//   /// text style can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   ///
//   /// If null, defaults to [labelStyle].
//   ///
//   /// Note that if you specify this style it will override the default behavior
//   /// of [MongolInputDecoration] that changes the color of the label to the
//   /// [MongolInputDecoration.errorStyle] color or [ThemeData.errorColor].
//   final TextStyle? floatingLabelStyle;

//   /// Text that provides context about the [MongolInputDecorator.child]'s value, such
//   /// as how the value will be used.
//   ///
//   /// If non-null, the text is displayed to the right of the [MongolInputDecorator.child], in
//   /// the same location as [errorText]. If a non-null [errorText] value is
//   /// specified then the helper text is not shown.
//   final String? helperText;

//   /// The style to use for the [helperText].
//   ///
//   /// If [helperStyle] is a [MaterialStateTextStyle], then the effective
//   /// text style can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   final TextStyle? helperStyle;

//   /// The maximum number of lines the [helperText] can occupy.
//   ///
//   /// Defaults to null, which means that the [helperText] will be limited
//   /// to a single line with [TextOverflow.ellipsis].
//   ///
//   /// This value is passed along to the [MongolText.maxLines] attribute
//   /// of the [MongolText] widget used to display the helper.
//   ///
//   /// See also:
//   ///
//   ///  * [errorMaxLines], the equivalent but for the [errorText].
//   final int? helperMaxLines;

//   /// Text that suggests what sort of input the field accepts.
//   ///
//   /// Displayed to the left of the [MongolInputDecorator.child] (i.e., at the same location
//   /// on the screen where text may be entered in the [MongolInputDecorator.child])
//   /// when the input [isEmpty] and either (a) [labelText] is null or (b) the
//   /// input has the focus.
//   final String? hintText;

//   /// The style to use for the [hintText].
//   ///
//   /// If [hintStyle] is a [MaterialStateTextStyle], then the effective
//   /// text style can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   ///
//   /// Also used for the [labelText] when the [labelText] is displayed to the
//   /// left of the input field (i.e., at the same location on the screen where
//   /// text may be entered in the [MongolInputDecorator.child]).
//   ///
//   /// If null, defaults to a value derived from the base [TextStyle] for the
//   /// input field and the current [Theme].
//   final TextStyle? hintStyle;

//   /// The maximum number of lines the [hintText] can occupy.
//   ///
//   /// Defaults to the value of [MongolTextField.maxLines] attribute.
//   ///
//   /// This value is passed along to the [MongolText.maxLines] attribute
//   /// of the [MongolText] widget used to display the hint text. [TextOverflow.ellipsis] is
//   /// used to handle the overflow when it is limited to single line.
//   final int? hintMaxLines;

//   /// Text that appears to the right of the [MongolInputDecorator.child] and
//   /// the border.
//   ///
//   /// If non-null, the border's color animates to red and the [helperText] is
//   /// not shown.
//   final String? errorText;

//   /// The style to use for the [MongolInputDecoration.errorText].
//   ///
//   /// If null, defaults of a value derived from the base [TextStyle] for the
//   /// input field and the current [Theme].
//   ///
//   /// By default the color of style will be used by the label of
//   /// [MongolInputDecoration] if [MongolInputDecoration.errorText] is not null. See
//   /// [MongolInputDecoration.labelStyle] or [MongolInputDecoration.floatingLabelStyle] for
//   /// an example of how to replicate this behavior if you have specified either
//   /// style.
//   final TextStyle? errorStyle;

//   /// The maximum number of lines the [errorText] can occupy.
//   ///
//   /// Defaults to null, which means that the [errorText] will be limited
//   /// to a single line with [TextOverflow.ellipsis].
//   ///
//   /// This value is passed along to the [Text.maxLines] attribute
//   /// of the [MongolText] widget used to display the error.
//   ///
//   /// See also:
//   ///
//   ///  * [helperMaxLines], the equivalent but for the [helperText].
//   final int? errorMaxLines;

//   /// Defines **how** the floating label should behave.
//   ///
//   /// When [FloatingLabelBehavior.auto] the label will float to the left only when
//   /// the field is focused or has some text content, otherwise it will appear
//   /// in the field in place of the content.
//   ///
//   /// When [FloatingLabelBehavior.always] the label will always float at the left
//   /// of the field to the left of the content.
//   ///
//   /// When [FloatingLabelBehavior.never] the label will always appear in an empty
//   /// field in place of the content.
//   ///
//   /// If null, [InputDecorationTheme.floatingLabelBehavior] will be used.
//   ///
//   /// See also:
//   ///
//   ///  * [floatingLabelAlignment] which defines **where** the floating label
//   ///    should be displayed.
//   final FloatingLabelBehavior? floatingLabelBehavior;

//   /// Defines **where** the floating label should be displayed.
//   ///
//   /// [MongolFloatingLabelAlignment.start] aligns the floating label to the topmost
//   /// possible position, which is horizontally adjacent to the label, to the left of
//   /// the field.
//   ///
//   /// [MongolFloatingLabelAlignment.center] aligns the floating label to the center at the
//   /// left of the field.
//   ///
//   /// If null, [InputDecorationTheme.floatingLabelAlignment] will be used.
//   ///
//   /// See also:
//   ///
//   ///  * [floatingLabelBehavior] which defines **how** the floating label should
//   ///    behave.
//   final MongolFloatingLabelAlignment? floatingLabelAlignment;

//   /// Whether the [InputDecorator.child] is part of a dense form (i.e., uses less horizontal
//   /// space).
//   ///
//   /// Defaults to false.
//   final bool? isDense;

//   /// The padding for the input decoration's container.
//   ///
//   /// The decoration's container is the area which is filled if [filled] is true
//   /// and bordered per the [border]. It's the area adjacent to [icon] and left of
//   /// the widgets that contain [helperText], [errorText], and [counterText].
//   ///
//   /// By default the `contentPadding` reflects [isDense] and the type of the
//   /// [border].
//   ///
//   /// If [isCollapsed] is true then `contentPadding` is [EdgeInsets.zero].
//   ///
//   /// If `isOutline` property of [border] is false and if [filled] is true then
//   /// `contentPadding` is `EdgeInsets.fromLTRB(8, 12, 8, 12)` when [isDense]
//   /// is true and `EdgeInsets.fromLTRB(12, 12, 12, 12)` when [isDense] is false.
//   /// If `isOutline` property of [border] is false and if [filled] is false then
//   /// `contentPadding` is `EdgeInsets.fromLTRB(8, 0, 8, 0)` when [isDense] is
//   /// true and `EdgeInsets.fromLTRB(12, 0, 12, 0)` when [isDense] is false.
//   ///
//   /// If `isOutline` property of [border] is true then `contentPadding` is
//   /// `EdgeInsets.fromLTRB(20, 12, 12, 12)` when [isDense] is true
//   /// and `EdgeInsets.fromLTRB(24, 12, 16, 12)` when [isDense] is false.
//   final EdgeInsetsGeometry? contentPadding;

//   /// Whether the decoration is the same size as the input field.
//   ///
//   /// A collapsed decoration cannot have [labelText], [errorText], an [icon].
//   ///
//   /// To create a collapsed input decoration, use [MongolInputDecoration.collapsed].
//   final bool isCollapsed;

//   /// An icon that appears before the [prefix] or [prefixText] and before
//   /// the editable part of the text field, within the decoration's container.
//   ///
//   /// The size and color of the prefix icon is configured automatically using an
//   /// [IconTheme] and therefore does not need to be explicitly given in the
//   /// icon widget.
//   ///
//   /// The prefix icon is constrained with a minimum size of 48px by 48px, but
//   /// can be expanded beyond that. Anything larger than 24px will require
//   /// additional padding to ensure it matches the Material Design spec of 12px
//   /// padding between the top edge of the input and leading edge of the prefix
//   /// icon. The following snippet shows how to pad the leading edge of the
//   /// prefix icon:
//   ///
//   /// ```dart
//   /// prefixIcon: Padding(
//   ///   padding: const EdgeInsetsDirectional.only(start: 12.0),
//   ///   child: myIcon, // myIcon is a 48px-wide widget.
//   /// )
//   /// ```
//   ///
//   /// The decoration's container is the area which is filled if [filled] is
//   /// true and bordered per the [border]. It's the area adjacent to
//   /// [icon] and left of the widgets that contain [helperText],
//   /// [errorText], and [counterText].
//   ///
//   /// The prefix icon alignment can be changed using [Align] with a fixed `widthFactor` and
//   /// `heightFactor`.
//   ///
//   /// See also:
//   ///
//   ///  * [Icon] and [ImageIcon], which are typically used to show icons.
//   ///  * [prefix] and [prefixText], which are other ways to show content
//   ///    before the text field (but after the icon).
//   ///  * [suffixIcon], which is the same but on the trailing edge.
//   ///  * [Align] A widget that aligns its child within itself and optionally
//   ///    sizes itself based on the child's size.
//   final Widget? prefixIcon;

//   /// The constraints for the prefix icon.
//   ///
//   /// This can be used to modify the [BoxConstraints] surrounding [prefixIcon].
//   ///
//   /// This property is particularly useful for getting the decoration's width
//   /// less than 48px. This can be achieved by setting [isDense] to true and
//   /// setting the constraints' minimum width and height to a value lower than
//   /// 48px.
//   final BoxConstraints? prefixIconConstraints;

//   /// Optional widget to place on the line before the input.
//   ///
//   /// This can be used, for example, to add some padding to text that would
//   /// otherwise be specified using [prefixText], or to add a custom widget in
//   /// front of the input. The widget's baseline is lined up with the input
//   /// baseline.
//   ///
//   /// Only one of [prefix] and [prefixText] can be specified.
//   ///
//   /// The [prefix] appears after the [prefixIcon], if both are specified.
//   ///
//   /// See also:
//   ///
//   ///  * [suffix], the equivalent but on the trailing edge.
//   final Widget? prefix;

//   /// Optional text prefix to place on the line before the input.
//   ///
//   /// Uses the [prefixStyle]. Uses [hintStyle] if [prefixStyle] isn't specified.
//   /// The prefix text is not returned as part of the user's input.
//   ///
//   /// If a more elaborate prefix is required, consider using [prefix] instead.
//   /// Only one of [prefix] and [prefixText] can be specified.
//   ///
//   /// The [prefixText] appears after the [prefixIcon], if both are specified.
//   ///
//   /// See also:
//   ///
//   ///  * [suffixText], the equivalent but on the trailing edge.
//   final String? prefixText;

//   /// The style to use for the [prefixText].
//   ///
//   /// If [prefixStyle] is a [MaterialStateTextStyle], then the effective
//   /// text style can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   ///
//   /// If null, defaults to the [hintStyle].
//   ///
//   /// See also:
//   ///
//   ///  * [suffixStyle], the equivalent but on the trailing edge.
//   final TextStyle? prefixStyle;

//   /// Optional color of the prefixIcon
//   ///
//   /// Defaults to [iconColor]
//   ///
//   /// If [prefixIconColor] is a [MaterialStateColor], then the effective
//   /// color can depend on the [MaterialState.focused] state, i.e.
//   /// if the [TextField] is focused or not.
//   final Color? prefixIconColor;

//   /// An icon that appears after the editable part of the text field and
//   /// after the [suffix] or [suffixText], within the decoration's container.
//   ///
//   /// The size and color of the suffix icon is configured automatically using an
//   /// [IconTheme] and therefore does not need to be explicitly given in the
//   /// icon widget.
//   ///
//   /// The suffix icon is constrained with a minimum size of 48px by 48px, but
//   /// can be expanded beyond that. Anything larger than 24px will require
//   /// additional padding to ensure it matches the Material Design spec of 12px
//   /// padding between the bottom edge of the input and trailing edge of the
//   /// prefix icon. The following snippet shows how to pad the trailing edge of
//   /// the suffix icon:
//   ///
//   /// ```dart
//   /// suffixIcon: Padding(
//   ///   padding: const EdgeInsetsDirectional.only(end: 12.0),
//   ///   child: myIcon, // myIcon is a 48px-wide widget.
//   /// )
//   /// ```
//   ///
//   /// The decoration's container is the area which is filled if [filled] is
//   /// true and bordered per the [border]. It's the area adjacent to
//   /// [icon] and above the widgets that contain [helperText],
//   /// [errorText], and [counterText].
//   ///
//   /// The suffix icon alignment can be changed using [Align] with a fixed `widthFactor` and
//   /// `heightFactor`.
//   ///
//   /// See also:
//   ///
//   ///  * [Icon] and [ImageIcon], which are typically used to show icons.
//   ///  * [suffix] and [suffixText], which are other ways to show content
//   ///    after the text field (but before the icon).
//   ///  * [prefixIcon], which is the same but on the leading edge.
//   ///  * [Align] A widget that aligns its child within itself and optionally
//   ///    sizes itself based on the child's size.
//   final Widget? suffixIcon;

//   /// Optional widget to place on the line after the input.
//   ///
//   /// This can be used, for example, to add some padding to the text that would
//   /// otherwise be specified using [suffixText], or to add a custom widget after
//   /// the input. The widget's baseline is lined up with the input baseline.
//   ///
//   /// Only one of [suffix] and [suffixText] can be specified.
//   ///
//   /// The [suffix] appears before the [suffixIcon], if both are specified.
//   ///
//   /// See also:
//   ///
//   ///  * [prefix], the equivalent but on the leading edge.
//   final Widget? suffix;

//   /// Optional text suffix to place on the line after the input.
//   ///
//   /// Uses the [suffixStyle]. Uses [hintStyle] if [suffixStyle] isn't specified.
//   /// The suffix text is not returned as part of the user's input.
//   ///
//   /// If a more elaborate suffix is required, consider using [suffix] instead.
//   /// Only one of [suffix] and [suffixText] can be specified.
//   ///
//   /// The [suffixText] appears before the [suffixIcon], if both are specified.
//   ///
//   /// See also:
//   ///
//   ///  * [prefixText], the equivalent but on the leading edge.
//   final String? suffixText;

//   /// The style to use for the [suffixText].
//   ///
//   /// If [suffixStyle] is a [MaterialStateTextStyle], then the effective
//   /// text style can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   ///
//   /// If null, defaults to the [hintStyle].
//   ///
//   /// See also:
//   ///
//   ///  * [prefixStyle], the equivalent but on the leading edge.
//   final TextStyle? suffixStyle;

//   /// Optional color of the suffixIcon
//   ///
//   /// Defaults to [iconColor]
//   ///
//   /// If [suffixIconColor] is a [MaterialStateColor], then the effective
//   /// color can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   final Color? suffixIconColor;

//   /// The constraints for the suffix icon.
//   ///
//   /// This can be used to modify the [BoxConstraints] surrounding [suffixIcon].
//   ///
//   /// This property is particularly useful for getting the decoration's width
//   /// less than 48px. This can be achieved by setting [isDense] to true and
//   /// setting the constraints' minimum width and height to a value lower than
//   /// 48px.
//   ///
//   /// If null, a [BoxConstraints] with a minimum width and height of 48px is
//   /// used.
//   final BoxConstraints? suffixIconConstraints;

//   /// Optional text to place right of the line as a character count.
//   ///
//   /// Rendered using [counterStyle]. Uses [helperStyle] if [counterStyle] is
//   /// null.
//   ///
//   /// The semantic label can be replaced by providing a [semanticCounterText].
//   ///
//   /// If null or an empty string and [counter] isn't specified, then nothing
//   /// will appear in the counter's location.
//   final String? counterText;

//   /// Optional custom counter widget to go in the place otherwise occupied by
//   /// [counterText].  If this property is non null, then [counterText] is
//   /// ignored.
//   final Widget? counter;

//   /// The style to use for the [counterText].
//   ///
//   /// If [counterStyle] is a [MaterialStateTextStyle], then the effective
//   /// text style can depend on the [MaterialState.focused] state, i.e.
//   /// if the [MongolTextField] is focused or not.
//   ///
//   /// If null, defaults to the [helperStyle].
//   final TextStyle? counterStyle;

//   /// If true the decoration's container is filled with [fillColor].
//   ///
//   /// When [MongolInputDecorator.isHovering] is true, the [hoverColor] is also blended
//   /// into the final fill color.
//   ///
//   /// Typically this field set to true if [border] is an
//   /// [SidelineInputBorder].
//   ///
//   /// The decoration's container is the area which is filled if [filled] is
//   /// true and bordered per the [border]. It's the area adjacent to
//   /// [icon] and left of the widgets that contain [helperText],
//   /// [errorText], and [counterText].
//   ///
//   /// This property is false by default.
//   final bool? filled;

//   /// The base fill color of the decoration's container color.
//   ///
//   /// When [MongolInputDecorator.isHovering] is true, the
//   /// [hoverColor] is also blended into the final fill color.
//   ///
//   /// By default the fillColor is based on the current [Theme].
//   ///
//   /// The decoration's container is the area which is filled if [filled] is true
//   /// and bordered per the [border]. It's the area adjacent to [icon] and left of
//   /// the widgets that contain [helperText], [errorText], and [counterText].
//   final Color? fillColor;

//   /// By default the [focusColor] is based on the current [Theme].
//   ///
//   /// The decoration's container is the area which is filled if [filled] is
//   /// true and bordered per the [border]. It's the area adjacent to
//   /// [icon] and left of the widgets that contain [helperText],
//   /// [errorText], and [counterText].
//   final Color? focusColor;

//   /// The color of the focus highlight for the decoration shown if the container
//   /// is being hovered over by a mouse.
//   ///
//   /// If [filled] is true, the color is blended with [fillColor] and fills the
//   /// decoration's container.
//   ///
//   /// If [filled] is false, and [MongolInputDecorator.isFocused] is false, the color
//   /// is blended over the [enabledBorder]'s color.
//   ///
//   /// By default the [hoverColor] is based on the current [Theme].
//   ///
//   /// The decoration's container is the area which is filled if [filled] is
//   /// true and bordered per the [border]. It's the area adjacent to
//   /// [icon] and left of the widgets that contain [helperText],
//   /// [errorText], and [counterText].
//   final Color? hoverColor;

//   /// The border to display when the [MongolInputDecorator] does not have the focus and
//   /// is showing an error.
//   ///
//   /// See also:
//   ///
//   ///  * [MongolInputDecorator.isFocused], which is true if the [MongolInputDecorator]'s child
//   ///    has the focus.
//   ///  * [MongolInputDecoration.errorText], the error shown by the [MongolInputDecorator], if non-null.
//   ///  * [border], for a description of where the [MongolInputDecorator] border appears.
//   ///  * [SidelineInputBorder], a [MongolInputDecorator] border which draws a vertical
//   ///    line at the right of the input decorator's container.
//   ///  * [OutlineInputBorder], a [MongolInputDecorator] border which draws a
//   ///    rounded rectangle around the input decorator's container.
//   ///  * [InputBorder.none], which doesn't draw a border.
//   ///  * [focusedBorder], displayed when [MongolInputDecorator.isFocused] is true
//   ///    and [MongolInputDecoration.errorText] is null.
//   ///  * [focusedErrorBorder], displayed when [MongolInputDecorator.isFocused] is true
//   ///    and [MongolInputDecoration.errorText] is non-null.
//   ///  * [disabledBorder], displayed when [MongolInputDecoration.enabled] is false
//   ///    and [MongolInputDecoration.errorText] is null.
//   ///  * [enabledBorder], displayed when [MongolInputDecoration.enabled] is true
//   ///    and [MongolInputDecoration.errorText] is null.
//   final InputBorder? errorBorder;

//   /// The border to display when the [MongolInputDecorator] has the focus and is not
//   /// showing an error.
//   final InputBorder? focusedBorder;

//   /// The border to display when the [MongolInputDecorator] has the focus and is
//   /// showing an error.
//   final InputBorder? focusedErrorBorder;

//   /// The border to display when the [MongolInputDecorator] is disabled and is not
//   /// showing an error.
//   final InputBorder? disabledBorder;

//   /// The border to display when the [MongolInputDecorator] is enabled and is not
//   /// showing an error.
//   final InputBorder? enabledBorder;

//   /// The shape of the border to draw around the decoration's container.
//   ///
//   /// If [border] is a [MaterialStateUnderlineInputBorder]
//   /// or [MaterialStateOutlineInputBorder], then the effective border can depend on
//   /// the [MaterialState.focused] state, i.e. if the [MongolTextField] is focused or not.
//   ///
//   /// If [border] derives from [InputBorder] the border's [InputBorder.borderSide],
//   /// i.e. the border's color and width, will be overridden to reflect the input
//   /// decorator's state. Only the border's shape is used. If custom  [BorderSide]
//   /// values are desired for  a given state, all four borders – [errorBorder],
//   /// [focusedBorder], [enabledBorder], [disabledBorder] – must be set.
//   ///
//   /// The decoration's container is the area which is filled if [filled] is
//   /// true and bordered per the [border]. It's the area adjacent to
//   /// [MongolInputDecoration.icon] and above the widgets that contain
//   /// [MongolInputDecoration.helperText], [MongolInputDecoration.errorText], and
//   /// [MongolInputDecoration.counterText].
//   ///
//   /// The border's bounds, i.e. the value of `border.getOuterPath()`, define
//   /// the area to be filled.
//   ///
//   /// This property is only used when the appropriate one of [errorBorder],
//   /// [focusedBorder], [focusedErrorBorder], [disabledBorder], or [enabledBorder]
//   /// is not specified. This border's [InputBorder.borderSide] property is
//   /// configured by the MongolInputDecorator, depending on the values of
//   /// [MongolInputDecoration.errorText], [MongolInputDecoration.enabled],
//   /// [MongolInputDecorator.isFocused] and the current [Theme].
//   ///
//   /// Typically one of [SidelineInputBorder] or [OutlineInputBorder].
//   /// If null, MongolInputDecorator's default is `const SidelineInputBorder()`.
//   final InputBorder? border;

//   /// If false [helperText],[errorText], and [counterText] are not displayed,
//   /// and the opacity of the remaining visual elements is reduced.
//   ///
//   /// This property is true by default.
//   final bool enabled;

//   /// A semantic label for the [counterText].
//   ///
//   /// Defaults to null.
//   ///
//   /// If provided, this replaces the semantic label of the [counterText].
//   final String? semanticCounterText;

//   /// Typically set to true when the [MongolInputDecorator] contains a multiline
//   /// [MongolTextField] ([MongolTextField.maxLines] is null or > 1) to override the default
//   /// behavior of aligning the label with the center of the [MongolTextField].
//   ///
//   /// Defaults to false.
//   final bool? alignLabelWithHint;

//   /// Defines minimum and maximum sizes for the [MongolInputDecorator].
//   ///
//   /// Typically the decorator will fill the vertical space it is given. For
//   /// larger screens, it may be useful to have the maximum height clamped to
//   /// a given value so it doesn't fill the whole screen. This property
//   /// allows you to control how big the decorator will be in its available
//   /// space.
//   ///
//   /// If null, then the ambient [ThemeData.inputDecorationTheme]'s
//   /// [InputDecorationTheme.constraints] will be used. If that
//   /// is null then the decorator will fill the available height with
//   /// a default width based on text size.
//   final BoxConstraints? constraints;

//   /// Creates a copy of this input decoration with the given fields replaced
//   /// by the new values.
//   MongolInputDecoration copyWith({
//     Widget? icon,
//     Color? iconColor,
//     Widget? label,
//     String? labelText,
//     TextStyle? labelStyle,
//     TextStyle? floatingLabelStyle,
//     String? helperText,
//     TextStyle? helperStyle,
//     int? helperMaxLines,
//     String? hintText,
//     TextStyle? hintStyle,
//     int? hintMaxLines,
//     String? errorText,
//     TextStyle? errorStyle,
//     int? errorMaxLines,
//     FloatingLabelBehavior? floatingLabelBehavior,
//     MongolFloatingLabelAlignment? floatingLabelAlignment,
//     bool? isCollapsed,
//     bool? isDense,
//     EdgeInsetsGeometry? contentPadding,
//     Widget? prefixIcon,
//     Widget? prefix,
//     String? prefixText,
//     BoxConstraints? prefixIconConstraints,
//     TextStyle? prefixStyle,
//     Color? prefixIconColor,
//     Widget? suffixIcon,
//     Widget? suffix,
//     String? suffixText,
//     TextStyle? suffixStyle,
//     Color? suffixIconColor,
//     BoxConstraints? suffixIconConstraints,
//     Widget? counter,
//     String? counterText,
//     TextStyle? counterStyle,
//     bool? filled,
//     Color? fillColor,
//     Color? focusColor,
//     Color? hoverColor,
//     InputBorder? errorBorder,
//     InputBorder? focusedBorder,
//     InputBorder? focusedErrorBorder,
//     InputBorder? disabledBorder,
//     InputBorder? enabledBorder,
//     InputBorder? border,
//     bool? enabled,
//     String? semanticCounterText,
//     bool? alignLabelWithHint,
//     BoxConstraints? constraints,
//   }) {
//     return MongolInputDecoration(
//       icon: icon ?? this.icon,
//       iconColor: iconColor ?? this.iconColor,
//       label: label ?? this.label,
//       labelText: labelText ?? this.labelText,
//       labelStyle: labelStyle ?? this.labelStyle,
//       floatingLabelStyle: floatingLabelStyle ?? this.floatingLabelStyle,
//       helperText: helperText ?? this.helperText,
//       helperStyle: helperStyle ?? this.helperStyle,
//       helperMaxLines: helperMaxLines ?? this.helperMaxLines,
//       hintText: hintText ?? this.hintText,
//       hintStyle: hintStyle ?? this.hintStyle,
//       hintMaxLines: hintMaxLines ?? this.hintMaxLines,
//       errorText: errorText ?? this.errorText,
//       errorStyle: errorStyle ?? this.errorStyle,
//       errorMaxLines: errorMaxLines ?? this.errorMaxLines,
//       floatingLabelBehavior:
//           floatingLabelBehavior ?? this.floatingLabelBehavior,
//       floatingLabelAlignment:
//           floatingLabelAlignment ?? this.floatingLabelAlignment,
//       isCollapsed: isCollapsed ?? this.isCollapsed,
//       isDense: isDense ?? this.isDense,
//       contentPadding: contentPadding ?? this.contentPadding,
//       prefixIcon: prefixIcon ?? this.prefixIcon,
//       prefix: prefix ?? this.prefix,
//       prefixText: prefixText ?? this.prefixText,
//       prefixStyle: prefixStyle ?? this.prefixStyle,
//       prefixIconColor: prefixIconColor ?? this.prefixIconColor,
//       prefixIconConstraints:
//           prefixIconConstraints ?? this.prefixIconConstraints,
//       suffixIcon: suffixIcon ?? this.suffixIcon,
//       suffix: suffix ?? this.suffix,
//       suffixText: suffixText ?? this.suffixText,
//       suffixStyle: suffixStyle ?? this.suffixStyle,
//       suffixIconColor: suffixIconColor ?? this.suffixIconColor,
//       suffixIconConstraints:
//           suffixIconConstraints ?? this.suffixIconConstraints,
//       counter: counter ?? this.counter,
//       counterText: counterText ?? this.counterText,
//       counterStyle: counterStyle ?? this.counterStyle,
//       filled: filled ?? this.filled,
//       fillColor: fillColor ?? this.fillColor,
//       focusColor: focusColor ?? this.focusColor,
//       hoverColor: hoverColor ?? this.hoverColor,
//       errorBorder: errorBorder ?? this.errorBorder,
//       focusedBorder: focusedBorder ?? this.focusedBorder,
//       focusedErrorBorder: focusedErrorBorder ?? this.focusedErrorBorder,
//       disabledBorder: disabledBorder ?? this.disabledBorder,
//       enabledBorder: enabledBorder ?? this.enabledBorder,
//       border: border ?? this.border,
//       enabled: enabled ?? this.enabled,
//       semanticCounterText: semanticCounterText ?? this.semanticCounterText,
//       alignLabelWithHint: alignLabelWithHint ?? this.alignLabelWithHint,
//       constraints: constraints ?? this.constraints,
//     );
//   }

//   /// Used by widgets like [MongolTextField] and [MongolInputDecorator] to create a new
//   /// [MongolInputDecoration] with default values taken from the [theme].
//   ///
//   /// Only null valued properties from this [MongolInputDecoration] are replaced
//   /// by the corresponding values from [theme].
//   MongolInputDecoration applyDefaults(InputDecorationTheme theme) {
//     return copyWith(
//       labelStyle: labelStyle ?? theme.labelStyle,
//       floatingLabelStyle: floatingLabelStyle ?? theme.floatingLabelStyle,
//       helperStyle: helperStyle ?? theme.helperStyle,
//       helperMaxLines: helperMaxLines ?? theme.helperMaxLines,
//       hintStyle: hintStyle ?? theme.hintStyle,
//       errorStyle: errorStyle ?? theme.errorStyle,
//       errorMaxLines: errorMaxLines ?? theme.errorMaxLines,
//       floatingLabelBehavior:
//           floatingLabelBehavior ?? theme.floatingLabelBehavior,
//       floatingLabelAlignment:
//           floatingLabelAlignment ?? _mapFromThemeFloatingLabelAlignment(theme),
//       isCollapsed: isCollapsed,
//       isDense: isDense ?? theme.isDense,
//       contentPadding: contentPadding ?? theme.contentPadding,
//       prefixStyle: prefixStyle ?? theme.prefixStyle,
//       suffixStyle: suffixStyle ?? theme.suffixStyle,
//       counterStyle: counterStyle ?? theme.counterStyle,
//       filled: filled ?? theme.filled,
//       fillColor: fillColor ?? theme.fillColor,
//       focusColor: focusColor ?? theme.focusColor,
//       hoverColor: hoverColor ?? theme.hoverColor,
//       errorBorder: errorBorder ?? theme.errorBorder,
//       focusedBorder: focusedBorder ?? theme.focusedBorder,
//       focusedErrorBorder: focusedErrorBorder ?? theme.focusedErrorBorder,
//       disabledBorder: disabledBorder ?? theme.disabledBorder,
//       enabledBorder: enabledBorder ?? theme.enabledBorder,
//       border: border ?? theme.border,
//       alignLabelWithHint: alignLabelWithHint ?? theme.alignLabelWithHint,
//       constraints: constraints ?? theme.constraints,
//     );
//   }

//   MongolFloatingLabelAlignment _mapFromThemeFloatingLabelAlignment(
//       InputDecorationTheme theme) {
//     if (theme.floatingLabelAlignment == FloatingLabelAlignment.center) {
//       return MongolFloatingLabelAlignment.center;
//     }
//     return MongolFloatingLabelAlignment.start;
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) {
//       return true;
//     }
//     if (other.runtimeType != runtimeType) {
//       return false;
//     }
//     return other is MongolInputDecoration &&
//         other.icon == icon &&
//         other.iconColor == iconColor &&
//         other.label == label &&
//         other.labelText == labelText &&
//         other.labelStyle == labelStyle &&
//         other.floatingLabelStyle == floatingLabelStyle &&
//         other.helperText == helperText &&
//         other.helperStyle == helperStyle &&
//         other.helperMaxLines == helperMaxLines &&
//         other.hintText == hintText &&
//         other.hintStyle == hintStyle &&
//         other.hintMaxLines == hintMaxLines &&
//         other.errorText == errorText &&
//         other.errorStyle == errorStyle &&
//         other.errorMaxLines == errorMaxLines &&
//         other.floatingLabelBehavior == floatingLabelBehavior &&
//         other.floatingLabelAlignment == floatingLabelAlignment &&
//         other.isDense == isDense &&
//         other.contentPadding == contentPadding &&
//         other.isCollapsed == isCollapsed &&
//         other.prefixIcon == prefixIcon &&
//         other.prefixIconColor == prefixIconColor &&
//         other.prefix == prefix &&
//         other.prefixText == prefixText &&
//         other.prefixStyle == prefixStyle &&
//         other.prefixIconConstraints == prefixIconConstraints &&
//         other.suffixIcon == suffixIcon &&
//         other.suffixIconColor == suffixIconColor &&
//         other.suffix == suffix &&
//         other.suffixText == suffixText &&
//         other.suffixStyle == suffixStyle &&
//         other.suffixIconConstraints == suffixIconConstraints &&
//         other.counter == counter &&
//         other.counterText == counterText &&
//         other.counterStyle == counterStyle &&
//         other.filled == filled &&
//         other.fillColor == fillColor &&
//         other.focusColor == focusColor &&
//         other.hoverColor == hoverColor &&
//         other.errorBorder == errorBorder &&
//         other.focusedBorder == focusedBorder &&
//         other.focusedErrorBorder == focusedErrorBorder &&
//         other.disabledBorder == disabledBorder &&
//         other.enabledBorder == enabledBorder &&
//         other.border == border &&
//         other.enabled == enabled &&
//         other.semanticCounterText == semanticCounterText &&
//         other.alignLabelWithHint == alignLabelWithHint &&
//         other.constraints == constraints;
//   }

//   @override
//   int get hashCode {
//     final List<Object?> values = <Object?>[
//       icon,
//       iconColor,
//       label,
//       labelText,
//       floatingLabelStyle,
//       labelStyle,
//       helperText,
//       helperStyle,
//       helperMaxLines,
//       hintText,
//       hintStyle,
//       hintMaxLines,
//       errorText,
//       errorStyle,
//       errorMaxLines,
//       floatingLabelBehavior,
//       floatingLabelAlignment,
//       isDense,
//       contentPadding,
//       isCollapsed,
//       filled,
//       fillColor,
//       focusColor,
//       hoverColor,
//       prefixIcon,
//       prefixIconColor,
//       prefix,
//       prefixText,
//       prefixStyle,
//       prefixIconConstraints,
//       suffixIcon,
//       suffixIconColor,
//       suffix,
//       suffixText,
//       suffixStyle,
//       suffixIconConstraints,
//       counter,
//       counterText,
//       counterStyle,
//       errorBorder,
//       focusedBorder,
//       focusedErrorBorder,
//       disabledBorder,
//       enabledBorder,
//       border,
//       enabled,
//       semanticCounterText,
//       alignLabelWithHint,
//       constraints,
//     ];
//     return Object.hashAll(values);
//   }

//   @override
//   String toString() {
//     final List<String> description = <String>[
//       if (icon != null) 'icon: $icon',
//       if (iconColor != null) 'iconColor: $iconColor',
//       if (label != null) 'label: $label',
//       if (labelText != null) 'labelText: "$labelText"',
//       if (floatingLabelStyle != null)
//         'floatingLabelStyle: "$floatingLabelStyle"',
//       if (helperText != null) 'helperText: "$helperText"',
//       if (helperMaxLines != null) 'helperMaxLines: "$helperMaxLines"',
//       if (hintText != null) 'hintText: "$hintText"',
//       if (hintMaxLines != null) 'hintMaxLines: "$hintMaxLines"',
//       if (errorText != null) 'errorText: "$errorText"',
//       if (errorStyle != null) 'errorStyle: "$errorStyle"',
//       if (errorMaxLines != null) 'errorMaxLines: "$errorMaxLines"',
//       if (floatingLabelBehavior != null)
//         'floatingLabelBehavior: $floatingLabelBehavior',
//       if (floatingLabelAlignment != null)
//         'floatingLabelAlignment: $floatingLabelAlignment',
//       if (isDense ?? false) 'isDense: $isDense',
//       if (contentPadding != null) 'contentPadding: $contentPadding',
//       if (isCollapsed) 'isCollapsed: $isCollapsed',
//       if (prefixIcon != null) 'prefixIcon: $prefixIcon',
//       if (prefixIconColor != null) 'prefixIconColor: $prefixIconColor',
//       if (prefix != null) 'prefix: $prefix',
//       if (prefixText != null) 'prefixText: $prefixText',
//       if (prefixStyle != null) 'prefixStyle: $prefixStyle',
//       if (prefixIconConstraints != null)
//         'prefixIconConstraints: $prefixIconConstraints',
//       if (suffixIcon != null) 'suffixIcon: $suffixIcon',
//       if (suffixIconColor != null) 'suffixIconColor: $suffixIconColor',
//       if (suffix != null) 'suffix: $suffix',
//       if (suffixText != null) 'suffixText: $suffixText',
//       if (suffixStyle != null) 'suffixStyle: $suffixStyle',
//       if (suffixIconConstraints != null)
//         'suffixIconConstraints: $suffixIconConstraints',
//       if (counter != null) 'counter: $counter',
//       if (counterText != null) 'counterText: $counterText',
//       if (counterStyle != null) 'counterStyle: $counterStyle',
//       if (filled ?? false) 'filled: true',
//       if (fillColor != null) 'fillColor: $fillColor',
//       if (focusColor != null) 'focusColor: $focusColor',
//       if (hoverColor != null) 'hoverColor: $hoverColor',
//       if (errorBorder != null) 'errorBorder: $errorBorder',
//       if (focusedBorder != null) 'focusedBorder: $focusedBorder',
//       if (focusedErrorBorder != null) 'focusedErrorBorder: $focusedErrorBorder',
//       if (disabledBorder != null) 'disabledBorder: $disabledBorder',
//       if (enabledBorder != null) 'enabledBorder: $enabledBorder',
//       if (border != null) 'border: $border',
//       if (!enabled) 'enabled: false',
//       if (semanticCounterText != null)
//         'semanticCounterText: $semanticCounterText',
//       if (alignLabelWithHint != null) 'alignLabelWithHint: $alignLabelWithHint',
//       if (constraints != null) 'constraints: $constraints',
//     ];
//     return 'InputDecoration(${description.join(', ')})';
//   }
// }
