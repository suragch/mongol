// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        InputBorder, InputDecoration,
        Colors,
        VisualDensity,
        kMinInteractiveDimension,
        FloatingLabelBehavior, Theme, ThemeData, Brightness, InputDecorationTheme;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/alignment.dart';

import 'input_border.dart';
import 'mongol_text.dart';
import 'mongol_text_painter.dart';

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
  int get hashCode => hashValues(start, extent);
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

/// Defines the behavior of the floating label.
// enum FloatingLabelBehavior {
//   /// The label will always be positioned within the content, or hidden.
//   never,

//   /// The label will float when the input is focused, or has content.
//   auto,

//   /// The label will always float above the content.
//   always,
// }

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
    this.fixTextFieldOutlineLabel = false,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool isCollapsed;
  final double floatingLabelWidth;
  final double floatingLabelProgress;
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
  final bool fixTextFieldOutlineLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is _Decoration &&
        other.contentPadding == contentPadding &&
        other.isCollapsed == isCollapsed &&
        other.floatingLabelWidth == floatingLabelWidth &&
        other.floatingLabelProgress == floatingLabelProgress &&
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
        other.container == container &&
        other.fixTextFieldOutlineLabel == fixTextFieldOutlineLabel;
  }

  @override
  int get hashCode {
    return hashValues(
      contentPadding,
      floatingLabelWidth,
      floatingLabelProgress,
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
      fixTextFieldOutlineLabel,
    );
  }
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
class _RenderDecoration extends RenderBox {
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
  final Map<_DecorationSlot, RenderBox> children =
      <_DecorationSlot, RenderBox>{};

  RenderBox? _updateChild(
      RenderBox? oldChild, RenderBox? newChild, _DecorationSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      children.remove(slot);
    }
    if (newChild != null) {
      children[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  RenderBox? _icon;
  RenderBox? get icon => _icon;
  set icon(RenderBox? value) {
    _icon = _updateChild(_icon, value, _DecorationSlot.icon);
  }

  RenderBox? _input;
  RenderBox? get input => _input;
  set input(RenderBox? value) {
    _input = _updateChild(_input, value, _DecorationSlot.input);
  }

  RenderBox? _label;
  RenderBox? get label => _label;
  set label(RenderBox? value) {
    _label = _updateChild(_label, value, _DecorationSlot.label);
  }

  RenderBox? _hint;
  RenderBox? get hint => _hint;
  set hint(RenderBox? value) {
    _hint = _updateChild(_hint, value, _DecorationSlot.hint);
  }

  RenderBox? _prefix;
  RenderBox? get prefix => _prefix;
  set prefix(RenderBox? value) {
    _prefix = _updateChild(_prefix, value, _DecorationSlot.prefix);
  }

  RenderBox? _suffix;
  RenderBox? get suffix => _suffix;
  set suffix(RenderBox? value) {
    _suffix = _updateChild(_suffix, value, _DecorationSlot.suffix);
  }

  RenderBox? _prefixIcon;
  RenderBox? get prefixIcon => _prefixIcon;
  set prefixIcon(RenderBox? value) {
    _prefixIcon = _updateChild(_prefixIcon, value, _DecorationSlot.prefixIcon);
  }

  RenderBox? _suffixIcon;
  RenderBox? get suffixIcon => _suffixIcon;
  set suffixIcon(RenderBox? value) {
    _suffixIcon = _updateChild(_suffixIcon, value, _DecorationSlot.suffixIcon);
  }

  RenderBox? _helperError;
  RenderBox? get helperError => _helperError;
  set helperError(RenderBox? value) {
    _helperError =
        _updateChild(_helperError, value, _DecorationSlot.helperError);
  }

  RenderBox? _counter;
  RenderBox? get counter => _counter;
  set counter(RenderBox? value) {
    _counter = _updateChild(_counter, value, _DecorationSlot.counter);
  }

  RenderBox? _container;
  RenderBox? get container => _container;
  set container(RenderBox? value) {
    _container = _updateChild(_container, value, _DecorationSlot.container);
  }

  // The returned list is ordered for hit testing.
  Iterable<RenderBox> get _children sync* {
    if (icon != null) yield icon!;
    if (input != null) yield input!;
    if (prefixIcon != null) yield prefixIcon!;
    if (suffixIcon != null) yield suffixIcon!;
    if (prefix != null) yield prefix!;
    if (suffix != null) yield suffix!;
    if (label != null) yield label!;
    if (hint != null) yield hint!;
    if (helperError != null) yield helperError!;
    if (counter != null) yield counter!;
    if (container != null) yield container!;
  }

  _Decoration get decoration => _decoration;
  _Decoration _decoration;
  set decoration(_Decoration value) {
    if (_decoration == value) return;
    _decoration = value;
    markNeedsLayout();
  }

  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    assert(value != null);
    if (_textBaseline == value) return;
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
    if (_isFocused == value) return;
    _isFocused = value;
    markNeedsSemanticsUpdate();
  }

  bool get expands => _expands;
  bool _expands = false;
  set expands(bool value) {
    if (_expands == value) return;
    _expands = value;
    markNeedsLayout();
  }

  // Indicates that the decoration should be aligned to accommodate an outline
  // border.
  bool get _isOutlineAligned {
    return !decoration.isCollapsed && decoration.border!.isOutline;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final child in _children) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (icon != null) visitor(icon!);
    if (prefix != null) visitor(prefix!);
    if (prefixIcon != null) visitor(prefixIcon!);

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

    if (input != null) visitor(input!);
    if (suffixIcon != null) visitor(suffixIcon!);
    if (suffix != null) visitor(suffix!);
    if (container != null) visitor(container!);
    if (helperError != null) visitor(helperError!);
    if (counter != null) visitor(counter!);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final value = <DiagnosticsNode>[];
    void add(RenderBox? child, String name) {
      if (child != null) value.add(child.toDiagnosticsNode(name: name));
    }

    add(icon, 'icon');
    add(input, 'input');
    add(label, 'label');
    add(hint, 'hint');
    add(prefix, 'prefix');
    add(suffix, 'suffix');
    add(prefixIcon, 'prefixIcon');
    add(suffixIcon, 'suffixIcon');
    add(helperError, 'helperError');
    add(counter, 'counter');
    add(container, 'container');
    return value;
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
    final baseline = box.getDistanceToBaseline(TextBaseline.alphabetic);
    assert(baseline != null && baseline >= 0.0);
    return baseline!;
  }

  // Returns a value used by performLayout to position all of the renderers.
  // This method applies layout to all of the renderers except the container.
  // For convenience, the container is laid out in performLayout().
  _RenderDecorationLayout _layout(BoxConstraints layoutConstraints) {
    assert(
      layoutConstraints.maxHeight < double.infinity,
      'A MongolInputDecorator, which is typically created by a MongolTextField, '
      'cannot have an unbounded height.\n'
      'This happens when the parent widget does not provide a finite height '
      'constraint. For example, if the MongolInputDecorator is contained by a Column, '
      'then its height must be constrained. An Expanded widget or a SizedBox '
      'can be used to constrain the height of the MongolInputDecorator or the '
      'MongolTextField that contains it.',
    );

    // Margin on each side of subtext (counter and helperError)
    final boxToBaseline = <RenderBox?, double>{};
    final boxConstraints = layoutConstraints.loosen();

    // Layout all the widgets used by MongolInputDecorator
    boxToBaseline[prefix] = _layoutLineBox(prefix, boxConstraints);
    boxToBaseline[suffix] = _layoutLineBox(suffix, boxConstraints);
    boxToBaseline[icon] = _layoutLineBox(icon, boxConstraints);
    boxToBaseline[prefixIcon] = _layoutLineBox(prefixIcon, boxConstraints);
    boxToBaseline[suffixIcon] = _layoutLineBox(suffixIcon, boxConstraints);

    final inputHeight = math.max(
        0.0,
        constraints.maxHeight -
            (_boxSize(icon).height +
                contentPadding.top +
                _boxSize(prefixIcon).height +
                _boxSize(prefix).height +
                _boxSize(suffix).height +
                _boxSize(suffixIcon).height +
                contentPadding.bottom));
    // Increase the available height for the label when it is scaled down.
    final invertedLabelScale = lerpDouble(
        1.00, 1 / _kFinalLabelScale, decoration.floatingLabelProgress)!;
    var suffixIconHeight = _boxSize(suffixIcon).height;
    if (decoration.border!.isOutline) {
      suffixIconHeight =
          lerpDouble(suffixIconHeight, 0.0, decoration.floatingLabelProgress)!;
    }
    final labelHeight = math.max(
        0.0,
        constraints.maxHeight -
            (_boxSize(icon).height +
                contentPadding.top +
                _boxSize(prefixIcon).height +
                suffixIconHeight +
                contentPadding.bottom));
    boxToBaseline[label] = _layoutLineBox(
      label,
      boxConstraints.copyWith(maxHeight: labelHeight * invertedLabelScale),
    );
    boxToBaseline[hint] = _layoutLineBox(
      hint,
      boxConstraints.copyWith(minHeight: inputHeight, maxHeight: inputHeight),
    );
    boxToBaseline[counter] = _layoutLineBox(counter, boxConstraints);

    // The helper or error text can occupy the full height less the space
    // occupied by the icon and counter.
    boxToBaseline[helperError] = _layoutLineBox(
      helperError,
      boxConstraints.copyWith(
        maxWidth: math.max(
          0.0,
          boxConstraints.maxHeight -
              _boxSize(icon).height -
              _boxSize(counter).height -
              contentPadding.vertical,
        ),
      ),
    );

    // The width of the input needs to accommodate label to the left and counter and
    // helperError to the right, when they exist.
    final labelWidth = label == null ? 0 : decoration.floatingLabelWidth;
    final leftWidth = decoration.border!.isOutline
        ? math.max(labelWidth - boxToBaseline[label]!, 0)
        : labelWidth;
    final counterWidth =
        counter == null ? 0 : boxToBaseline[counter]! + subtextGap;
    final helperErrorExists =
        helperError?.size != null && helperError!.size.width > 0;
    final double helperErrorWidth =
        !helperErrorExists ? 0 : helperError!.size.width + subtextGap;
    final rightWidth = math.max(
      counterWidth,
      helperErrorWidth,
    );
    final densityOffset = decoration.visualDensity!.baseSizeAdjustment;
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
    final hintWidth = hint == null ? 0 : hint!.size.width;
    final inputDirectWidth = input == null ? 0 : input!.size.width;
    final inputWidth = math.max(hintWidth, inputDirectWidth);
    final inputInternalBaseline = math.max(
      boxToBaseline[input]!,
      boxToBaseline[hint]!,
    );

    // Calculate the amount that prefix/suffix affects width to the left and right of
    // the input.
    final prefixWidth = prefix?.size.width ?? 0;
    final suffixWidth = suffix?.size.width ?? 0;
    final fixWidth = math.max(
      boxToBaseline[prefix]!,
      boxToBaseline[suffix]!,
    );
    final fixLeftOfInput = math.max(0, fixWidth - inputInternalBaseline);
    final fixRightOfBaseline = math.max(
      prefixWidth - boxToBaseline[prefix]!,
      suffixWidth - boxToBaseline[suffix]!,
    );
    final fixRightOfInput = math.max(
      0,
      fixRightOfBaseline - (inputWidth - inputInternalBaseline),
    );

    // Calculate the width of the input text container.
    final double prefixIconWidth = prefixIcon == null ? 0 : prefixIcon!.size.width;
    final double suffixIconWidth = suffixIcon == null ? 0 : suffixIcon!.size.width;
    final double fixIconWidth = math.max(prefixIconWidth, suffixIconWidth);
    final double contentWidth = math.max(
      fixIconWidth,
      leftWidth +
          contentPadding.left +
          fixLeftOfInput +
          inputWidth +
          fixRightOfInput +
          contentPadding.right +
          densityOffset.dy,
    );
    final minContainerWidth =
        decoration.isDense! || decoration.isCollapsed || expands
            ? 0.0
            : kMinInteractiveDimension;
    final maxContainerWidth = boxConstraints.maxWidth - rightWidth;
    final double containerWidth = expands
        ? maxContainerWidth
        : math.min(
            math.max(contentWidth, minContainerWidth), maxContainerWidth);

    // Ensure the text is horizontally centered in cases where the content is
    // shorter than kMinInteractiveDimension.
    final interactiveAdjustment = minContainerWidth > contentWidth
        ? (minContainerWidth - contentWidth) / 2.0
        : 0.0;

    // Try to consider the prefix/suffix as part of the text when aligning it.
    // If the prefix/suffix overflows however, allow it to extend outside of the
    // input and align the remaining part of the text and prefix/suffix.
    final overflow = math.max(0, contentWidth - maxContainerWidth);
    // Map textAlignHorizontal from -1:1 to 0:1 so that it can be used to scale
    // the baseline from its minimum to maximum values.
    final textAlignHorizontalFactor = (textAlignHorizontal!.x + 1.0) / 2.0;
    // Adjust to try to fit left overflow inside the input on an inverse scale of
    // textAlignHorizontal, so that left aligned text adjusts the most and right
    // aligned text doesn't adjust at all.
    final baselineAdjustment =
        fixLeftOfInput - overflow * (1 - textAlignHorizontalFactor);

    // The baselines that will be used to draw the actual input text content.
    final leftInputBaseline = contentPadding.left +
        leftWidth +
        inputInternalBaseline +
        baselineAdjustment +
        interactiveAdjustment;
    final maxContentWidth =
        containerWidth - contentPadding.left - leftWidth - contentPadding.right;
    final alignableWidth = fixLeftOfInput + inputWidth + fixRightOfInput;
    final maxHorizontalOffset = maxContentWidth - alignableWidth;
    final textAlignHorizontalOffset =
        maxHorizontalOffset * textAlignHorizontalFactor;
    final inputBaseline =
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
    final outlineCenterBaseline = inputInternalBaseline +
        baselineAdjustment / 2.0 +
        (containerWidth - (2.0 + inputWidth)) / 2.0;
    final outlineLeftBaseline = leftInputBaseline;
    final outlineRightBaseline = leftInputBaseline + maxHorizontalOffset;
    final outlineBaseline = _interpolateThree(
      outlineLeftBaseline,
      outlineCenterBaseline,
      outlineRightBaseline,
      textAlignHorizontal!,
    );

    // Find the positions of the text to the left of the input when it exists.
    var subtextCounterBaseline = 0.0;
    var subtextHelperBaseline = 0.0;
    var subtextCounterWidth = 0.0;
    var subtextHelperWidth = 0.0;
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
    final subtextBaseline = math.max(
      subtextCounterBaseline,
      subtextHelperBaseline,
    );
    final subtextWidth = math.max(
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
  // centered text box's left side and the left of the content padding. When the
  // alignment is greater than zero, it interpolates between the centered box's
  // left and the position that would align the right side of the box with the right
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
      final t = textAlignHorizontal.x + 1;
      return begin + (middle - begin) * t;
    }

    if (middle >= end) {
      return middle;
    }
    // Do a standard linear interpolation on the second half, between middle and
    // end.
    final t = textAlignHorizontal.x;
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
    var width = 0.0;
    for (final box in boxes) {
      if (box == null) continue;
      width = math.max(_minWidth(box, height), width);
    }
    return width;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var subtextWidth = _lineWidth(height, <RenderBox?>[helperError, counter]);
    if (subtextWidth > 0.0) subtextWidth += subtextGap;
    final densityOffset = decoration.visualDensity!.baseSizeAdjustment;
    final containerWidth = contentPadding.left +
        (label == null ? 0.0 : decoration.floatingLabelWidth) +
        _lineWidth(height, <RenderBox?>[prefix, input, suffix]) +
        subtextWidth +
        contentPadding.right +
        densityOffset.dx;
    final minContainerWidth =
        decoration.isDense! || expands ? 0.0 : kMinInteractiveDimension;
    return math.max(containerWidth, minContainerWidth);
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
    return const Size(0, 0);
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _labelTransform = null;
    final layout = _layout(constraints);

    final overallHeight = constraints.maxHeight;
    final overallWidth = layout.containerWidth + layout.subtextWidth;

    if (container != null) {
      final containerConstraints = BoxConstraints.tightFor(
        width: layout.containerWidth,
        height: overallHeight - _boxSize(icon).height,
      );
      container!.layout(containerConstraints, parentUsesSize: true);
      final y = _boxSize(icon).height;
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

    final top = contentPadding.top;
    final bottom = overallHeight - contentPadding.bottom;

    width = layout.containerWidth;
    baseline =
        _isOutlineAligned ? layout.outlineBaseline : layout.inputBaseline;

    if (icon != null) {
      final y = 0.0;
      centerLayout(icon!, y);
    }

    var start = top + _boxSize(icon).height;
    var end = bottom;
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
    if (prefix != null) start += baselineLayout(prefix!, start);
    if (input != null) baselineLayout(input!, start);
    if (hint != null) baselineLayout(hint!, start);
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
      final labelY = _boxParentData(label!).offset.dy;
      // The value of _InputBorderGap.start is relative to the origin of the
      // _BorderContainer which is inset by the icon's height.
      decoration.borderGap!.start = labelY - _boxSize(icon).height;
      decoration.borderGap!.extent = label!.size.height * 0.75;
    } else {
      decoration.borderGap!.start = null;
      decoration.borderGap!.extent = 0.0;
    }

    size = constraints.constrain(Size(overallWidth, overallHeight));
    assert(size.height == constraints.constrainHeight(overallHeight));
    assert(size.width == constraints.constrainWidth(overallWidth));
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
      final labelOffset = _boxParentData(label!).offset;
      final labelWidth = label!.size.width;
      final borderWeight = decoration.border!.borderSide.width;
      final t = decoration.floatingLabelProgress;
      // The center of the outline border label ends up a little below the
      // center of the top border line.
      final isOutlineBorder =
          decoration.border != null && decoration.border!.isOutline;
      // Temporary opt-in fix for https://github.com/flutter/flutter/issues/54028
      // Center the scaled label relative to the border.
      final floatingX = decoration.fixTextFieldOutlineLabel
          ? isOutlineBorder
              ? (-labelWidth * _kFinalLabelScale) / 2.0 + borderWeight / 2.0
              : contentPadding.left
          : isOutlineBorder
              ? -labelWidth * 0.25
              : contentPadding.left;
      final scale = lerpDouble(1.0, _kFinalLabelScale, t)!;
      final dy = labelOffset.dy;
      final dx = lerpDouble(0.0, floatingX - labelOffset.dx, t)!;
      _labelTransform = Matrix4.identity()
        ..translate(labelOffset.dx + dx, dy)
        ..scale(scale);
      _transformLayer = context.pushTransform(
          needsCompositing, offset, _labelTransform!, _paintLabel,
          oldLayer: _transformLayer);
    } else {
      _transformLayer = null;
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

  TransformLayer? _transformLayer;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _children) {
      // The label must be handled specially since we've transformed it.
      final offset = _boxParentData(child).offset;
      final isHit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == label && _labelTransform != null) {
      final labelOffset = _boxParentData(label!).offset;
      transform
        ..multiply(_labelTransform!)
        ..translate(-labelOffset.dx, -labelOffset.dy);
    }
    super.applyPaintTransform(child, transform);
  }
}

class _DecorationElement extends RenderObjectElement {
  _DecorationElement(_Decorator widget) : super(widget);

  final Map<_DecorationSlot, Element> slotToChild =
      <_DecorationSlot, Element>{};

  @override
  _Decorator get widget => super.widget as _Decorator;

  @override
  _RenderDecoration get renderObject => super.renderObject as _RenderDecoration;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.containsValue(child));
    assert(child.slot is _DecorationSlot);
    assert(slotToChild.containsKey(child.slot));
    slotToChild.remove(child.slot);
    super.forgetChild(child);
  }

  void _mountChild(Widget? widget, _DecorationSlot slot) {
    final oldChild = slotToChild[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.decoration.icon, _DecorationSlot.icon);
    _mountChild(widget.decoration.input, _DecorationSlot.input);
    _mountChild(widget.decoration.label, _DecorationSlot.label);
    _mountChild(widget.decoration.hint, _DecorationSlot.hint);
    _mountChild(widget.decoration.prefix, _DecorationSlot.prefix);
    _mountChild(widget.decoration.suffix, _DecorationSlot.suffix);
    _mountChild(widget.decoration.prefixIcon, _DecorationSlot.prefixIcon);
    _mountChild(widget.decoration.suffixIcon, _DecorationSlot.suffixIcon);
    _mountChild(widget.decoration.helperError, _DecorationSlot.helperError);
    _mountChild(widget.decoration.counter, _DecorationSlot.counter);
    _mountChild(widget.decoration.container, _DecorationSlot.container);
  }

  void _updateChild(Widget? widget, _DecorationSlot slot) {
    final oldChild = slotToChild[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void update(_Decorator newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.decoration.icon, _DecorationSlot.icon);
    _updateChild(widget.decoration.input, _DecorationSlot.input);
    _updateChild(widget.decoration.label, _DecorationSlot.label);
    _updateChild(widget.decoration.hint, _DecorationSlot.hint);
    _updateChild(widget.decoration.prefix, _DecorationSlot.prefix);
    _updateChild(widget.decoration.suffix, _DecorationSlot.suffix);
    _updateChild(widget.decoration.prefixIcon, _DecorationSlot.prefixIcon);
    _updateChild(widget.decoration.suffixIcon, _DecorationSlot.suffixIcon);
    _updateChild(widget.decoration.helperError, _DecorationSlot.helperError);
    _updateChild(widget.decoration.counter, _DecorationSlot.counter);
    _updateChild(widget.decoration.container, _DecorationSlot.container);
  }

  void _updateRenderObject(RenderBox? child, _DecorationSlot slot) {
    switch (slot) {
      case _DecorationSlot.icon:
        renderObject.icon = child;
        break;
      case _DecorationSlot.input:
        renderObject.input = child;
        break;
      case _DecorationSlot.label:
        renderObject.label = child;
        break;
      case _DecorationSlot.hint:
        renderObject.hint = child;
        break;
      case _DecorationSlot.prefix:
        renderObject.prefix = child;
        break;
      case _DecorationSlot.suffix:
        renderObject.suffix = child;
        break;
      case _DecorationSlot.prefixIcon:
        renderObject.prefixIcon = child;
        break;
      case _DecorationSlot.suffixIcon:
        renderObject.suffixIcon = child;
        break;
      case _DecorationSlot.helperError:
        renderObject.helperError = child;
        break;
      case _DecorationSlot.counter:
        renderObject.counter = child;
        break;
      case _DecorationSlot.container:
        renderObject.container = child;
        break;
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, _DecorationSlot slot) {
    assert(child is RenderBox);
    _updateRenderObject(child as RenderBox, slot);
    assert(renderObject.children.keys.contains(slot));
  }

  @override
  void removeRenderObjectChild(RenderObject child, _DecorationSlot slot) {
    assert(child is RenderBox);
    assert(renderObject.children[slot] == child);
    _updateRenderObject(null, slot);
    assert(!renderObject.children.keys.contains(slot));
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, dynamic oldSlot, dynamic newSlot) {
    assert(false, 'not reachable');
  }
}

class _Decorator extends RenderObjectWidget {
  const _Decorator({
    Key? key,
    required this.textAlignHorizontal,
    required this.decoration,
    required this.textBaseline,
    required this.isFocused,
    required this.expands,
  }) : super(key: key);

  final _Decoration decoration;
  final TextBaseline textBaseline;
  final TextAlignHorizontal? textAlignHorizontal;
  final bool isFocused;
  final bool expands;

  @override
  _DecorationElement createElement() => _DecorationElement(this);

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
    Key? key,
    required this.decoration,
    this.baseStyle,
    this.textAlign,
    this.textAlignHorizontal,
    this.isFocused = false,
    this.isHovering = false,
    this.expands = false,
    this.isEmpty = false,
    this.child,
  }) : super(key: key);

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
  /// the input (typically a MongolTextField). For example, TextAlignHorizontal.left will
  /// place the baseline such that the text, and any attached decoration like
  /// prefix and suffix, is as close to the left side of the input as possible without
  /// overflowing. The widths of the prefix and suffix are similarly included
  /// for other alignment values. If the width is greater than the width
  /// available, then the prefix and suffix will be allowed to overflow first
  /// before the text scrolls.
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
  /// See [MongolTextField.minLines] and [MongolTextField.maxLines] for related ways to
  /// affect the width of an input. When [expands] is true, both must be null
  /// in order to avoid ambiguity in determining the width.
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
  _InputDecoratorState createState() => _InputDecoratorState();

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
    properties.add(
        DiagnosticsProperty<InputDecoration>('decoration', decoration));
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
    if (widget.decoration != old.decoration) _effectiveDecoration = null;

    final floatBehaviorChanged = widget.decoration.floatingLabelBehavior !=
            old.decoration.floatingLabelBehavior;

    if (widget._labelShouldWithdraw != old._labelShouldWithdraw ||
        floatBehaviorChanged) {
      if (_floatingLabelEnabled &&
          (widget._labelShouldWithdraw ||
              widget.decoration.floatingLabelBehavior ==
                  FloatingLabelBehavior.always))
        {_floatingLabelController.forward();}
      else
        {_floatingLabelController.reverse();}
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
      switch (themeData.brightness) {
        case Brightness.dark:
          return themeData.accentColor;
        case Brightness.light:
          return themeData.primaryColor;
      }
    }
    return themeData.hintColor;
  }

  Color _getDefaultBorderColor(ThemeData themeData) {
    if (isFocused) {
      switch (themeData.brightness) {
        case Brightness.dark:
          return themeData.accentColor;
        case Brightness.light:
          return themeData.primaryColor;
      }
    }
    if (decoration!.filled!) {
      return themeData.hintColor;
    }
    final enabledColor =
        themeData.colorScheme.onSurface.withOpacity(0.38);
    if (isHovering) {
      final hoverColor = decoration!.hoverColor ??
          themeData.inputDecorationTheme.hoverColor ??
          themeData.hoverColor;
      return Color.alphaBlend(hoverColor.withOpacity(0.12), enabledColor);
    }
    return enabledColor;
  }

  Color _getFillColor(ThemeData themeData) {
    if (decoration!.filled != true) // filled == null same as filled == false
      {return Colors.transparent;}
    if (decoration!.fillColor != null) return decoration!.fillColor!;

    // dark theme: 10% white (enabled), 5% white (disabled)
    // light theme: 4% black (enabled), 2% black (disabled)
    const darkEnabled = Color(0x1AFFFFFF);
    const darkDisabled = Color(0x0DFFFFFF);
    const lightEnabled = Color(0x0A000000);
    const lightDisabled = Color(0x05000000);

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
        !decoration!.enabled) return Colors.transparent;
    return decoration!.hoverColor ??
        themeData.inputDecorationTheme.hoverColor ??
        themeData.hoverColor;
  }

  Color _getDefaultIconColor(ThemeData themeData) {
    if (!decoration!.enabled && !isFocused) return themeData.disabledColor;

    switch (themeData.brightness) {
      case Brightness.dark:
        return Colors.white70;
      case Brightness.light:
        return Colors.black45;
    }
  }

  // True if the label will be shown and the hint will not.
  // If we're not focused, there's no value, labelText was provided, and
  // floatingLabelBehavior isn't set to always, then the label appears where the
  // hint would.
  bool get _hasInlineLabel {
    return !widget._labelShouldWithdraw &&
        decoration!.labelText != null &&
        decoration!.floatingLabelBehavior != FloatingLabelBehavior.always;
  }

  // If the label is a floating placeholder, it's always shown.
  bool get _shouldShowLabel => _hasInlineLabel || _floatingLabelEnabled;

  // The base style for the inline label or hint when they're displayed "inline",
  // i.e. when they appear in place of the empty text field.
  TextStyle _getInlineStyle(ThemeData themeData) {
    return themeData.textTheme.subtitle1!.merge(widget.baseStyle).copyWith(
        color: decoration!.enabled
            ? themeData.hintColor
            : themeData.disabledColor);
  }

  TextStyle _getFloatingLabelStyle(ThemeData themeData) {
    final Color color = decoration!.errorText != null
        ? decoration!.errorStyle?.color ?? themeData.errorColor
        : _getActiveColor(themeData);
    final style =
        themeData.textTheme.subtitle1!.merge(widget.baseStyle);
    // Temporary opt-in fix for https://github.com/flutter/flutter/issues/54028
    // Setting TextStyle.height to 1 ensures that the label's width (in 
    // vertical orientation) will equal its font size.
    return themeData.fixTextFieldOutlineLabel
        ? style
            .copyWith(
                height: 1,
                color: decoration!.enabled ? color : themeData.disabledColor)
            .merge(decoration!.labelStyle)
        : style
            .copyWith(
                color: decoration!.enabled ? color : themeData.disabledColor)
            .merge(decoration!.labelStyle);
  }

  TextStyle _getHelperStyle(ThemeData themeData) {
    final color =
        decoration!.enabled ? themeData.hintColor : Colors.transparent;
    return themeData.textTheme.caption!
        .copyWith(color: color)
        .merge(decoration!.helperStyle);
  }

  TextStyle _getErrorStyle(ThemeData themeData) {
    final color =
        decoration!.enabled ? themeData.errorColor : Colors.transparent;
    return themeData.textTheme.caption!
        .copyWith(color: color)
        .merge(decoration!.errorStyle);
  }

  InputBorder _getDefaultBorder(ThemeData themeData) {
    if (decoration!.border?.borderSide == BorderSide.none) {
      return decoration!.border!;
    }

    final Color borderColor;
    if (decoration!.enabled || isFocused) {
      borderColor = decoration!.errorText == null
          ? _getDefaultBorderColor(themeData)
          : themeData.errorColor;
    } else {
      borderColor =
          (decoration!.filled == true && decoration!.border?.isOutline != true)
              ? Colors.transparent
              : themeData.disabledColor;
    }

    final double borderWeight;
    if (decoration!.isCollapsed ||
        decoration?.border == InputBorder.none ||
        !decoration!.enabled)
      {borderWeight = 0.0;}
    else
      {borderWeight = isFocused ? 2.0 : 1.0;}

    final border =
        decoration!.border ?? const SidelineInputBorder();
    return border.copyWith(
        borderSide: BorderSide(color: borderColor, width: borderWeight));
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final inlineStyle = _getInlineStyle(themeData);
    final textBaseline = inlineStyle.textBaseline!;

    final hintStyle = inlineStyle.merge(decoration!.hintStyle);
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

    final isError = decoration!.errorText != null;
    InputBorder? border;
    if (!decoration!.enabled)
      {border = isError ? decoration!.errorBorder : decoration!.disabledBorder;}
    else if (isFocused)
      {border =
          isError ? decoration!.focusedErrorBorder : decoration!.focusedBorder;}
    else
      {border = isError ? decoration!.errorBorder : decoration!.enabledBorder;}
    border ??= _getDefaultBorder(themeData);

    final Widget container = _BorderContainer(
      border: border,
      gap: _borderGap,
      gapAnimation: _floatingLabelController.view,
      fillColor: _getFillColor(themeData),
      hoverColor: _getHoverColor(themeData),
      isHovering: isHovering,
    );

    // Temporary opt-in fix for https://github.com/flutter/flutter/issues/54028
    // Setting TextStyle.height to 1 ensures that the label's width (
    // in vertical orientation) will equal its font size.
    final inlineLabelStyle = themeData.fixTextFieldOutlineLabel
        ? inlineStyle.merge(decoration!.labelStyle).copyWith(height: 1)
        : inlineStyle.merge(decoration!.labelStyle);
    final Widget? label = decoration!.labelText == null
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
                    : inlineLabelStyle,
                child: MongolText(
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
                style: decoration!.prefixStyle ?? hintStyle,
                child: decoration!.prefix,
              );

    final Widget? suffix =
        decoration!.suffix == null && decoration!.suffixText == null
            ? null
            : _AffixText(
                labelIsFloating: widget._labelShouldWithdraw,
                text: decoration!.suffixText,
                style: decoration!.suffixStyle ?? hintStyle,
                child: decoration!.suffix,
              );

    final activeColor = _getActiveColor(themeData);
    final decorationIsDense =
        decoration!.isDense == true; // isDense == null, same as false
    final iconSize = decorationIsDense ? 18.0 : 24.0;
    final iconColor =
        isFocused ? activeColor : _getDefaultIconColor(themeData);

    final Widget? icon = decoration!.icon == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 16.0),
            child: IconTheme.merge(
              data: IconThemeData(
                color: iconColor,
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
                  color: iconColor,
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
                  color: iconColor,
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
        child: Text(
          decoration!.counterText!,
          style: _getHelperStyle(themeData).merge(decoration!.counterStyle),
          overflow: TextOverflow.ellipsis,
          semanticsLabel: decoration!.semanticCounterText,
        ),
      );
    }

    // The _Decoration widget and _RenderDecoration assume that contentPadding
    // has been resolved to EdgeInsets.
    final textDirection = TextDirection.ltr;
    final decorationContentPadding =
        decoration!.contentPadding?.resolve(textDirection);

    final EdgeInsets contentPadding;
    final double floatingLabelWidth;
    if (decoration!.isCollapsed) {
      floatingLabelWidth = 0.0;
      contentPadding = decorationContentPadding ?? EdgeInsets.zero;
    } else if (!border.isOutline) {
      // 4.0: the horizontal gap between the inline elements and the floating label.
      floatingLabelWidth = (4.0 + 0.75 * inlineLabelStyle.fontSize!) *
          MediaQuery.textScaleFactorOf(context);
      if (decoration!.filled == true) {
        // filled == null same as filled == false
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

    return _Decorator(
      decoration: _Decoration(
        contentPadding: contentPadding,
        isCollapsed: decoration!.isCollapsed,
        floatingLabelWidth: floatingLabelWidth,
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
        container: container,
        fixTextFieldOutlineLabel: themeData.fixTextFieldOutlineLabel,
      ),
      textBaseline: textBaseline,
      textAlignHorizontal: widget.textAlignHorizontal,
      isFocused: isFocused,
      expands: widget.expands,
    );
  }
}
