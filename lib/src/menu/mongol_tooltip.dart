// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    show
        ThemeData,
        Theme,
        Feedback,
        TooltipThemeData,
        TooltipTheme,
        Brightness,
        Colors;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/src/text/mongol_text.dart';

/// A Mongol material design tooltip.
///
/// Tooltips provide text labels which help explain the function of a button or
/// other user interface action. Wrap the button in a [Tooltip] widget and provide
/// a message which will be shown when the widget is long pressed.
///
/// Many widgets, such as [IconButton], [FloatingActionButton], and
/// [MongolPopupMenuButton] have a `tooltip` property that, when non-null, causes the
/// widget to include a [Tooltip] in its build.
///
/// Tooltips improve the accessibility of visual widgets by proving a textual
/// representation of the widget, which, for example, can be vocalized by a
/// screen reader.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=EeEfD5fI-5Q}
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// This example show a basic [MongolTooltip] which has a [MongolText] as child.
/// [message] contains your label to be shown by the tooltip when
/// the child that MongolTooltip wraps is hovered over on web or desktop. On mobile,
/// the tooltip is shown when the widget is long pressed.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return const MongolTooltip(
///     message: 'I am a Tooltip',
///     child: MongolText('Hover over the text to show a tooltip.'),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// This example covers most of the attributes available in MongolTooltip.
/// `decoration` has been used to give a gradient and borderRadius to MongolTooltip.
/// `width` has been used to set a specific width of the MongolTooltip.
/// `preferRight` is false, the tooltip will prefer showing left of [MongolTooltip]'s child widget.
/// However, it may show the tooltip to the right if there's not enough space
/// to the left of the widget.
/// `textStyle` has been used to set the font size of the 'message'.
/// `showDuration` accepts a Duration to continue showing the message after the long
/// press has been released.
/// `waitDuration` accepts a Duration for which a mouse pointer has to hover over the child
/// widget before the tooltip is shown.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return MongolTooltip(
///     message: 'I am a Tooltip',
///     child: const Text('Tap this text and hold down to show a tooltip.'),
///     decoration: BoxDecoration(
///       borderRadius: BorderRadius.circular(25),
///       gradient: const LinearGradient(colors: <Color>[Colors.amber, Colors.red]),
///     ),
///     width: 50,
///     padding: const EdgeInsets.all(8.0),
///     preferRight: false,
///     textStyle: const TextStyle(
///       fontSize: 24,
///     ),
///     showDuration: const Duration(seconds: 2),
///     waitDuration: const Duration(seconds: 1),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * <https://material.io/design/components/tooltips.html>
///  * [TooltipTheme] or [ThemeData.tooltipTheme]
class MongolTooltip extends StatefulWidget {
  /// Creates a Mongol tooltip.
  ///
  /// By default, tooltips should adhere to the
  /// [Material specification](https://material.io/design/components/tooltips.html#spec).
  /// If the optional constructor parameters are not defined, the values
  /// provided by [TooltipTheme.of] will be used if a [TooltipTheme] is present
  /// or specified in [ThemeData].
  ///
  /// All parameters that are defined in the constructor will
  /// override the default values _and_ the values in [TooltipTheme.of].
  const MongolTooltip({
    Key? key,
    required this.message,
    this.width,
    this.padding,
    this.margin,
    this.horizontalOffset,
    this.preferRight,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.waitDuration,
    this.showDuration,
    this.child,
  }) : super(key: key);

  /// The text to display in the tooltip.
  final String message;

  /// The width of the tooltip's [child].
  ///
  /// If the [child] is null, then this is the tooltip's intrinsic width.
  final double? width;

  /// The amount of space by which to inset the tooltip's [child].
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry? padding;

  /// The empty space that surrounds the tooltip.
  ///
  /// Defines the tooltip's outer [Container.margin]. By default, a
  /// long tooltip will span the height of its window. If tall enough,
  /// a tooltip might also span the window's width. This property allows
  /// one to define how much space the tooltip must be inset from the edges
  /// of their display window.
  ///
  /// If this property is null, then [TooltipThemeData.margin] is used.
  /// If [TooltipThemeData.margin] is also null, the default margin is
  /// 0.0 logical pixels on all sides.
  final EdgeInsetsGeometry? margin;

  /// The horizontal gap between the widget and the displayed tooltip.
  ///
  /// When [preferRight] is set to true and tooltips have sufficient space to
  /// display themselves, this property defines how much horizontal space
  /// tooltips will position themselves to the right of their corresponding widgets.
  /// Otherwise, tooltips will position themselves to the left of their corresponding
  /// widgets with the given offset.
  final double? horizontalOffset;

  /// Whether the tooltip defaults to being displayed to the right of the widget.
  ///
  /// Defaults to true. If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  final bool? preferRight;

  /// Whether the tooltip's [message] should be excluded from the semantics
  /// tree.
  ///
  /// Defaults to false. A tooltip will add a [Semantics] label that is set to
  /// [MongolTooltip.message]. Set this property to true if the app is going to
  /// provide its own custom semantics label.
  final bool? excludeFromSemantics;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// Specifies the tooltip's shape and background color.
  ///
  /// The tooltip shape defaults to a rounded rectangle with a border radius of
  /// 4.0. Tooltips will also default to an opacity of 90% and with the color
  /// [Colors.grey[700]] if [ThemeData.brightness] is [Brightness.dark], and
  /// [Colors.white] if it is [Brightness.light].
  final Decoration? decoration;

  /// The style to use for the message of the tooltip.
  ///
  /// If null, the message's [TextStyle] will be determined based on
  /// [ThemeData]. If [ThemeData.brightness] is set to [Brightness.dark],
  /// [TextTheme.bodyText2] of [ThemeData.textTheme] will be used with
  /// [Colors.white]. Otherwise, if [ThemeData.brightness] is set to
  /// [Brightness.light], [TextTheme.bodyText2] of [ThemeData.textTheme] will be
  /// used with [Colors.black].
  final TextStyle? textStyle;

  /// The length of time that a pointer must hover over a tooltip's widget
  /// before the tooltip will be shown.
  ///
  /// Once the pointer leaves the widget, the tooltip will immediately
  /// disappear.
  ///
  /// Defaults to 0 milliseconds (tooltips are shown immediately upon hover).
  final Duration? waitDuration;

  /// The length of time that the tooltip will be shown after a long press
  /// is released.
  ///
  /// Defaults to 1.5 seconds.
  final Duration? showDuration;

  @override
  _MongolTooltipState createState() => _MongolTooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message, showName: false));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin,
        defaultValue: null));
    properties.add(DoubleProperty('horizontal offset', horizontalOffset,
        defaultValue: null));
    properties.add(FlagProperty('position',
        value: preferRight,
        ifTrue: 'right',
        ifFalse: 'left',
        showName: true,
        defaultValue: null));
    properties.add(FlagProperty('semantics',
        value: excludeFromSemantics,
        ifTrue: 'excluded',
        showName: true,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration,
        defaultValue: null));
  }
}

class _MongolTooltipState extends State<MongolTooltip>
    with SingleTickerProviderStateMixin {
  static const double _defaultHorizontalOffset = 24.0;
  static const bool _defaultPreferRight = true;
  static const EdgeInsetsGeometry _defaultMargin = EdgeInsets.zero;
  static const Duration _fadeInDuration = Duration(milliseconds: 150);
  static const Duration _fadeOutDuration = Duration(milliseconds: 75);
  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultWaitDuration = Duration.zero;
  static const bool _defaultExcludeFromSemantics = false;

  late double width;
  late EdgeInsetsGeometry padding;
  late EdgeInsetsGeometry margin;
  late Decoration decoration;
  late TextStyle textStyle;
  late double horizontalOffset;
  late bool preferRight;
  late bool excludeFromSemantics;
  late AnimationController _controller;
  OverlayEntry? _entry;
  Timer? _hideTimer;
  Timer? _showTimer;
  late Duration showDuration;
  late Duration waitDuration;
  late bool _mouseIsConnected;
  bool _longPressActivated = false;

  @override
  void initState() {
    super.initState();
    _mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    _controller = AnimationController(
      duration: _fadeInDuration,
      reverseDuration: _fadeOutDuration,
      vsync: this,
    )..addStatusListener(_handleStatusChanged);
    // Listen to see when a mouse is added.
    RendererBinding.instance.mouseTracker
        .addListener(_handleMouseTrackerChange);
    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  // https://material.io/components/tooltips#specs
  double _getDefaultTooltipWidth() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 24.0;
      default:
        return 32.0;
    }
  }

  EdgeInsets _getDefaultPadding() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const EdgeInsets.symmetric(vertical: 8.0);
      default:
        return const EdgeInsets.symmetric(vertical: 16.0);
    }
  }

  double _getDefaultFontSize() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 10.0;
      default:
        return 14.0;
    }
  }

  // Forces a rebuild if a mouse has been added or removed.
  void _handleMouseTrackerChange() {
    if (!mounted) {
      return;
    }
    final bool mouseIsConnected =
        RendererBinding.instance.mouseTracker.mouseIsConnected;
    if (mouseIsConnected != _mouseIsConnected) {
      setState(() {
        _mouseIsConnected = mouseIsConnected;
      });
    }
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _hideTooltip(immediately: true);
    }
  }

  void _hideTooltip({bool immediately = false}) {
    _showTimer?.cancel();
    _showTimer = null;
    if (immediately) {
      _removeEntry();
      return;
    }
    if (_longPressActivated) {
      // Tool tips activated by long press should stay around for the showDuration.
      _hideTimer ??= Timer(showDuration, _controller.reverse);
    } else {
      // Tool tips activated by hover should disappear as soon as the mouse
      // leaves the control.
      _controller.reverse();
    }
    _longPressActivated = false;
  }

  void _showTooltip({bool immediately = false}) {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (immediately) {
      ensureTooltipVisible();
      return;
    }
    _showTimer ??= Timer(waitDuration, ensureTooltipVisible);
  }

  /// Shows the tooltip if it is not already visible.
  ///
  /// Returns `false` when the tooltip was already visible or if the context has
  /// become null.
  bool ensureTooltipVisible() {
    _showTimer?.cancel();
    _showTimer = null;
    if (_entry != null) {
      // Stop trying to hide, if we were.
      _hideTimer?.cancel();
      _hideTimer = null;
      _controller.forward();
      return false; // Already visible.
    }
    _createNewEntry();
    _controller.forward();
    return true;
  }

  void _createNewEntry() {
    final OverlayState overlayState = Overlay.of(
      context,
      debugRequiredFor: widget,
    )!;

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset target = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayState.context.findRenderObject(),
    );

    // We create this widget outside of the overlay entry's builder to prevent
    // updated values from happening to leak into the overlay when the overlay
    // rebuilds.
    final Widget overlay = Directionality(
      textDirection: TextDirection.ltr,
      child: _MongolTooltipOverlay(
        message: widget.message,
        width: width,
        padding: padding,
        margin: margin,
        decoration: decoration,
        textStyle: textStyle,
        animation: CurvedAnimation(
          parent: _controller,
          curve: Curves.fastOutSlowIn,
        ),
        target: target,
        horizontalOffset: horizontalOffset,
        preferRight: preferRight,
      ),
    );
    _entry = OverlayEntry(builder: (BuildContext context) => overlay);
    overlayState.insert(_entry!);
    SemanticsService.tooltip(widget.message);
  }

  void _removeEntry() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    _entry?.remove();
    _entry = null;
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_entry == null) {
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _hideTooltip();
    } else if (event is PointerDownEvent) {
      _hideTooltip(immediately: true);
    }
  }

  @override
  void deactivate() {
    if (_entry != null) {
      _hideTooltip(immediately: true);
    }
    _showTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
    RendererBinding.instance.mouseTracker
        .removeListener(_handleMouseTrackerChange);
    if (_entry != null) {
      _removeEntry();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    _longPressActivated = true;
    final bool tooltipCreated = ensureTooltipVisible();
    if (tooltipCreated) {
      Feedback.forLongPress(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    final ThemeData theme = Theme.of(context);
    final TooltipThemeData tooltipTheme = TooltipTheme.of(context);
    final TextStyle defaultTextStyle;
    final BoxDecoration defaultDecoration;
    if (theme.brightness == Brightness.dark) {
      defaultTextStyle = theme.textTheme.bodyText2!.copyWith(
        color: Colors.black,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    } else {
      defaultTextStyle = theme.textTheme.bodyText2!.copyWith(
        color: Colors.white,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.grey[700]!.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    }

    width = widget.width ?? tooltipTheme.height ?? _getDefaultTooltipWidth();
    padding = widget.padding ?? tooltipTheme.padding ?? _getDefaultPadding();
    margin = widget.margin ?? tooltipTheme.margin ?? _defaultMargin;
    horizontalOffset = widget.horizontalOffset ??
        tooltipTheme.verticalOffset ??
        _defaultHorizontalOffset;
    preferRight =
        widget.preferRight ?? tooltipTheme.preferBelow ?? _defaultPreferRight;
    excludeFromSemantics = widget.excludeFromSemantics ??
        tooltipTheme.excludeFromSemantics ??
        _defaultExcludeFromSemantics;
    decoration =
        widget.decoration ?? tooltipTheme.decoration ?? defaultDecoration;
    textStyle = widget.textStyle ?? tooltipTheme.textStyle ?? defaultTextStyle;
    waitDuration = widget.waitDuration ??
        tooltipTheme.waitDuration ??
        _defaultWaitDuration;
    showDuration = widget.showDuration ??
        tooltipTheme.showDuration ??
        _defaultShowDuration;

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _handleLongPress,
      excludeFromSemantics: true,
      child: Semantics(
        label: excludeFromSemantics ? null : widget.message,
        child: widget.child,
      ),
    );

    // Only check for hovering if there is a mouse connected.
    if (_mouseIsConnected) {
      result = MouseRegion(
        onEnter: (PointerEnterEvent event) => _showTooltip(),
        onExit: (PointerExitEvent event) => _hideTooltip(),
        child: result,
      );
    }

    return result;
  }
}

/// A delegate for computing the layout of a tooltip to be displayed left or
/// right of a target specified in the global coordinate system.
class _MongolTooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  ///
  /// The arguments must not be null.
  _MongolTooltipPositionDelegate({
    required this.target,
    required this.horizontalOffset,
    required this.preferRight,
  });

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of horizontal distance between the target and the displayed
  /// tooltip.
  final double horizontalOffset;

  /// Whether the tooltip is displayed to the right of its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferRight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionMongolDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      horizontalOffset: horizontalOffset,
      preferRight: preferRight,
    );
  }

  @override
  bool shouldRelayout(_MongolTooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target ||
        horizontalOffset != oldDelegate.horizontalOffset ||
        preferRight != oldDelegate.preferRight;
  }
}

class _MongolTooltipOverlay extends StatelessWidget {
  const _MongolTooltipOverlay({
    Key? key,
    required this.message,
    required this.width,
    this.padding,
    this.margin,
    this.decoration,
    this.textStyle,
    required this.animation,
    required this.target,
    required this.horizontalOffset,
    required this.preferRight,
  }) : super(key: key);

  final String message;
  final double width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final Animation<double> animation;
  final Offset target;
  final double horizontalOffset;
  final bool preferRight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _MongolTooltipPositionDelegate(
            target: target,
            horizontalOffset: horizontalOffset,
            preferRight: preferRight,
          ),
          child: FadeTransition(
            opacity: animation,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: width),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyText2!,
                child: Container(
                  decoration: decoration,
                  padding: padding,
                  margin: margin,
                  child: Center(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: MongolText(
                      message,
                      style: textStyle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Position a child box within a container box, either left or right of a target
/// point.
///
/// The container's size is described by `size`.
///
/// The target point is specified by `target`, as an offset from the top left of
/// the container.
///
/// The child box's size is given by `childSize`.
///
/// The return value is the suggested distance from the top left of the
/// container box to the top left of the child box.
///
/// The suggested position will be to the left of the target point if `preferRight` is
/// false, and to the right of the target point if it is true, unless it wouldn't fit on
/// the preferred side but would fit on the other side.
///
/// The suggested position will place the nearest side of the child to the
/// target point `horizontalOffset` from the target point (even if it cannot fit
/// given that constraint).
///
/// The suggested position will be at least `margin` away from the edge of the
/// container. If possible, the child will be positioned so that its center is
/// aligned with the target point. If the child cannot fit vertically within
/// the container given the margin, then the child will be centered in the
/// container.
///
/// Used by [MongolTooltip] to position a tooltip relative to its parent.
///
/// The arguments must not be null.
Offset positionMongolDependentBox({
  required Size size,
  required Size childSize,
  required Offset target,
  required bool preferRight,
  double horizontalOffset = 0.0,
  double margin = 10.0,
}) {
  // HORIZONTAL DIRECTION
  final bool fitsRight =
      target.dx + horizontalOffset + childSize.width <= size.width - margin;
  final bool fitsLeft =
      target.dx - horizontalOffset - childSize.width >= margin;
  final bool tooltipRight =
      preferRight ? fitsRight || !fitsLeft : !(fitsLeft || !fitsRight);
  double x;
  if (tooltipRight) {
    x = math.min(target.dx + horizontalOffset, size.width - margin);
  } else {
    x = math.max(target.dx - horizontalOffset - childSize.width, margin);
  }
  // VERTICAL DIRECTION
  double y;
  if (size.height - margin * 2.0 < childSize.height) {
    y = (size.height - childSize.height) / 2.0;
  } else {
    final double normalizedTargetY =
        target.dy.clamp(margin, size.height - margin);
    final double edge = margin + childSize.height / 2.0;
    if (normalizedTargetY < edge) {
      y = margin;
    } else if (normalizedTargetY > size.height - edge) {
      y = size.height - margin - childSize.height;
    } else {
      y = normalizedTargetY - childSize.height / 2.0;
    }
  }
  return Offset(x, y);
}
