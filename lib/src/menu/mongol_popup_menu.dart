// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        VerticalDivider,
        ThemeData,
        Theme,
        PopupMenuThemeData,
        PopupMenuTheme,
        Brightness,
        MaterialStateProperty,
        MaterialStateMouseCursor,
        MaterialState,
        Material,
        MaterialType,
        MaterialLocalizations,
        IconButton,
        Icons,
        InkWell,
        kMinInteractiveDimension,
        kThemeChangeDuration;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../button/mongol_icon_button.dart';
import 'mongol_intrinsic_height.dart';
import 'mongol_tooltip.dart';

// Examples can assume:
// enum Commands { heroAndScholar, hurricaneCame }
// late bool _heroAndScholar;
// late dynamic _selection;
// late BuildContext context;
// void setState(VoidCallback fn) { }

const Duration _kMenuDuration = Duration(milliseconds: 300);
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuHorizontalPadding = 8.0;
const double _kMenuDividerWidth = 16.0;
const double _kMenuMaxHeight = 5.0 * _kMenuHeightStep;
const double _kMenuMinHeight = 2.0 * _kMenuHeightStep;
const double _kMenuVerticalPadding = 16.0;
const double _kMenuHeightStep = 56.0;
const double _kMenuScreenPadding = 8.0;

/// A base class for entries in a material design popup menu.
///
/// The popup menu widget uses this interface to interact with the menu items.
/// To show a popup menu, use the [showMongolMenu] function. To create a button that
/// shows a popup menu, consider using [MongolPopupMenuButton].
///
/// The type `T` is the type of the value(s) the entry represents. All the
/// entries in a given menu must represent values with consistent types.
///
/// A [MongolPopupMenuEntry] may represent multiple values, for example a column
/// with several icons, or a single entry, for example a menu item with an icon
/// (see [MongolPopupMenuItem]), or no value at all (for example,
/// [MongolPopupMenuDivider]).
///
/// See also:
///
///  * [MongolPopupMenuItem], a popup menu entry for a single value.
///  * [MongolPopupMenuDivider], a popup menu entry that is just a vertical line.
///  * [showMongolMenu], a method to dynamically show a popup menu at a given location.
///  * [MongolPopupMenuButton], an [IconButton] that automatically shows a menu
///    when it is tapped.
abstract class MongolPopupMenuEntry<T> extends StatefulWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MongolPopupMenuEntry({Key? key}) : super(key: key);

  /// The amount of horizontal space occupied by this entry.
  ///
  /// This value is used at the time the [showMongolMenu] method is called, if the
  /// `initialValue` argument is provided, to determine the position of this
  /// entry when aligning the selected entry over the given `position`. It is
  /// otherwise ignored.
  double get width;

  /// Whether this entry represents a particular value.
  ///
  /// This method is used by [showMongolMenu], when it is called, to align the entry
  /// representing the `initialValue`, if any, to the given `position`, and then
  /// later is called on each entry to determine if it should be highlighted (if
  /// the method returns true, the entry will have its background color set to
  /// the ambient [ThemeData.highlightColor]). If `initialValue` is null, then
  /// this method is not called.
  ///
  /// If the [MongolPopupMenuEntry] represents a single value, this should
  /// return true if the argument matches that value. If it represents multiple
  /// values, it should return true if the argument matches any of them.
  bool represents(T? value);
}

/// A vertical divider in a material design popup menu.
///
/// This widget adapts the [Divider] for use in popup menus.
///
/// See also:
///
///  * [MongolPopupMenuItem], for the kinds of items that this widget divides.
///  * [showMongolMenu], a method to dynamically show a popup menu at a given location.
///  * [MongolPopupMenuButton], an [IconButton] that automatically shows a menu
///    when it is tapped.
class MongolPopupMenuDivider extends MongolPopupMenuEntry<Never> {
  /// Creates a vertical divider for a popup menu.
  ///
  /// By default, the divider has a width of 16 logical pixels.
  const MongolPopupMenuDivider({Key? key, this.width = _kMenuDividerWidth})
      : super(key: key);

  /// The width of the divider entry.
  ///
  /// Defaults to 16 pixels.
  @override
  final double width;

  @override
  bool represents(void value) => false;

  @override
  State<MongolPopupMenuDivider> createState() => _MongolPopupMenuDividerState();
}

class _MongolPopupMenuDividerState extends State<MongolPopupMenuDivider> {
  @override
  Widget build(BuildContext context) => VerticalDivider(width: widget.width);
}

// This widget only exists to enable _PopupMenuRoute to save the sizes of
// each menu item. The sizes are used by _PopupMenuRouteLayout to compute the
// x coordinate of the menu's origin so that the center of selected menu
// item lines up with the center of its MongolPopupMenuButton.
class _MenuItem extends SingleChildRenderObjectWidget {
  const _MenuItem({
    Key? key,
    required this.onLayout,
    required Widget? child,
  }) : super(key: key, child: child);

  final ValueChanged<Size> onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMenuItem(onLayout);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderMenuItem extends RenderShiftedBox {
  _RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  ValueChanged<Size> onLayout;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child == null) {
      return Size.zero;
    }
    return child!.getDryLayout(constraints);
  }

  @override
  void performLayout() {
    if (child == null) {
      size = Size.zero;
    } else {
      child!.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child!.size);
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = Offset.zero;
    }
    onLayout(size);
  }
}

/// An item in a Mongol material design popup menu.
///
/// To show a popup menu, use the [showMongolMenu] function. To create a button that
/// shows a popup menu, consider using [MongolPopupMenuButton].
///
/// Typically the [child] of a [MongolPopupMenuItem] is a [MongolText] widget.
/// More elaborate menus with icons can use a [MongolListTile]. By default, a
/// [MongolPopupMenuItem] is [kMinInteractiveDimension] pixels
/// wide. If you use a widget with a different width, it must be specified in
/// the [width] property.
///
/// {@tool snippet}
///
/// Here, a [MongolText] widget is used with a popup menu item. The
/// `WhyFarther` type is an enum, not shown here.
///
/// ```dart
/// const MongolPopupMenuItem<WhyFarther>(
///   value: WhyFarther.harder,
///   child: MongolText('Working a lot harder'),
/// )
/// ```
/// {@end-tool}
///
/// See the example at [MongolPopupMenuButton] for how this example could be
/// used in a complete menu.
///
/// See also:
///
///  * [MongolPopupMenuDivider], which can be used to divide items from each other.
///  * [showMongolMenu], a method to dynamically show a popup menu at a given location.
///  * [MongolPopupMenuButton], an [IconButton] that automatically shows a menu when
///    it is tapped.
class MongolPopupMenuItem<T> extends MongolPopupMenuEntry<T> {
  /// Creates an item for a popup menu.
  ///
  /// By default, the item is [enabled].
  ///
  /// The `enabled` and `width` arguments must not be null.
  const MongolPopupMenuItem({
    Key? key,
    this.value,
    this.onTap,
    this.enabled = true,
    this.width = kMinInteractiveDimension,
    this.padding,
    this.textStyle,
    this.mouseCursor,
    required this.child,
  }) : super(key: key);

  /// The value that will be returned by [showMongolMenu] if this entry is selected.
  final T? value;

  /// Called when the menu item is tapped.
  final VoidCallback? onTap;

  /// Whether the user is permitted to select this item.
  ///
  /// Defaults to true. If this is false, then the item will not react to
  /// touches.
  final bool enabled;

  /// The minimum width of the menu item.
  ///
  /// Defaults to [kMinInteractiveDimension] pixels.
  @override
  final double width;

  /// The padding of the menu item.
  ///
  /// Note that [width] may interact with the applied padding. For example,
  /// If a [width] greater than the width of the sum of the padding and [child]
  /// is provided, then the padding's effect will not be visible.
  ///
  /// When null, the vertical padding defaults to 16.0 on both sides.
  final EdgeInsets? padding;

  /// The text style of the popup menu item.
  ///
  /// If this property is null, then [PopupMenuThemeData.textStyle] is used.
  /// If [PopupMenuThemeData.textStyle] is also null, then [TextTheme.subtitle1]
  /// of [ThemeData.textTheme] is used.
  final TextStyle? textStyle;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the following [MaterialState]:
  ///
  ///  * [MaterialState.disabled].
  ///
  /// If this property is null, [MaterialStateMouseCursor.clickable] will be used.
  final MouseCursor? mouseCursor;

  /// The widget below this widget in the tree.
  ///
  /// Typically a single-line [MongolListTile] (for menus with icons) or a
  /// [MongolText]. An appropriate [DefaultTextStyle] is put in scope for the
  /// child. In either case, the text should be short enough that it won't wrap.
  final Widget? child;

  @override
  bool represents(T? value) => value == this.value;

  @override
  MongolPopupMenuItemState<T, MongolPopupMenuItem<T>> createState() =>
      MongolPopupMenuItemState<T, MongolPopupMenuItem<T>>();
}

/// The [State] for [MongolPopupMenuItem] subclasses.
///
/// By default this implements the basic styling and layout of Material Design
/// popup menu items.
///
/// The [buildChild] method can be overridden to adjust exactly what gets placed
/// in the menu. By default it returns [MongolPopupMenuItem.child].
///
/// The [handleTap] method can be overridden to adjust exactly what happens when
/// the item is tapped. By default, it uses [Navigator.pop] to return the
/// [MongolPopupMenuItem.value] from the menu route.
///
/// This class takes two type arguments. The second, `W`, is the exact type of
/// the [Widget] that is using this [State]. It must be a subclass of
/// [MongolPopupMenuItem]. The first, `T`, must match the type argument of that widget
/// class, and is the type of values returned from this menu.
class MongolPopupMenuItemState<T, W extends MongolPopupMenuItem<T>>
    extends State<W> {
  /// The menu item contents.
  ///
  /// Used by the [build] method.
  ///
  /// By default, this returns [MongolPopupMenuItem.child]. Override this to put
  /// something else in the menu entry.
  @protected
  Widget? buildChild() => widget.child;

  /// The handler for when the user selects the menu item.
  ///
  /// Used by the [InkWell] inserted by the [build] method.
  ///
  /// By default, uses [Navigator.pop] to return the [MongolPopupMenuItem.value] from
  /// the menu route.
  @protected
  void handleTap() {
    widget.onTap?.call();

    Navigator.pop<T>(context, widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    TextStyle style = widget.textStyle ??
        popupMenuTheme.textStyle ??
        theme.textTheme.titleMedium!;

    if (!widget.enabled) style = style.copyWith(color: theme.disabledColor);

    Widget item = AnimatedDefaultTextStyle(
      style: style,
      duration: kThemeChangeDuration,
      child: Container(
        alignment: Alignment.topCenter,
        constraints: BoxConstraints(minWidth: widget.width),
        padding: widget.padding ??
            const EdgeInsets.symmetric(vertical: _kMenuVerticalPadding),
        child: buildChild(),
      ),
    );

    if (!widget.enabled) {
      final bool isDark = theme.brightness == Brightness.dark;
      item = IconTheme.merge(
        data: IconThemeData(opacity: isDark ? 0.5 : 0.38),
        child: item,
      );
    }
    final MouseCursor effectiveMouseCursor =
        MaterialStateProperty.resolveAs<MouseCursor>(
      widget.mouseCursor ?? MaterialStateMouseCursor.clickable,
      <MaterialState>{
        if (!widget.enabled) MaterialState.disabled,
      },
    );

    return MergeSemantics(
      child: Semantics(
        enabled: widget.enabled,
        button: true,
        child: InkWell(
          onTap: widget.enabled ? handleTap : null,
          canRequestFocus: widget.enabled,
          mouseCursor: effectiveMouseCursor,
          child: item,
        ),
      ),
    );
  }
}

class _PopupMenu<T> extends StatelessWidget {
  const _PopupMenu({
    Key? key,
    required this.route,
    required this.semanticLabel,
  }) : super(key: key);

  final _PopupMenuRoute<T> route;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final double unit = 1.0 /
        (route.items.length +
            1.5); // 1.0 for the height and 0.5 for the last item's fade.
    final List<Widget> children = <Widget>[];
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);

    for (int i = 0; i < route.items.length; i += 1) {
      final double start = (i + 1) * unit;
      final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      final CurvedAnimation opacity = CurvedAnimation(
        parent: route.animation!,
        curve: Interval(start, end),
      );
      Widget item = route.items[i];
      if (route.initialValue != null &&
          (route.items[i] as MongolPopupMenuItem)
              .represents(route.initialValue)) {
        item = Container(
          color: Theme.of(context).highlightColor,
          child: item,
        );
      }
      children.add(
        _MenuItem(
          onLayout: (Size size) {
            route.itemSizes[i] = size;
          },
          child: FadeTransition(
            opacity: opacity,
            child: item,
          ),
        ),
      );
    }

    final CurveTween opacity =
        CurveTween(curve: const Interval(0.0, 1.0 / 3.0));
    final CurveTween height = CurveTween(curve: Interval(0.0, unit));
    final CurveTween width =
        CurveTween(curve: Interval(0.0, unit * route.items.length));

    final Widget child = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: _kMenuMinHeight,
        maxHeight: _kMenuMaxHeight,
      ),
      child: MongolIntrinsicHeight(
        stepHeight: _kMenuHeightStep,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: semanticLabel,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: _kMenuHorizontalPadding,
            ),
            child: ListBody(
              mainAxis: Axis.horizontal,
              children: children,
            ),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: route.animation!,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: opacity.evaluate(route.animation!),
          child: Material(
            shape: route.shape ?? popupMenuTheme.shape,
            color: route.color ?? popupMenuTheme.color,
            type: MaterialType.card,
            elevation: route.elevation ?? popupMenuTheme.elevation ?? 8.0,
            child: Align(
              alignment: Alignment.topRight,
              widthFactor: width.evaluate(route.animation!),
              heightFactor: height.evaluate(route.animation!),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// Positioning of the menu on the screen.
class _PopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _PopupMenuRouteLayout(
    this.position,
    this.itemSizes,
    this.selectedItemIndex,
    this.padding,
  );

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final RelativeRect position;

  // The sizes of each item are computed when the menu is laid out, and before
  // the route is laid out.
  List<Size?> itemSizes;

  // The index of the selected item, or null if MongolPopupMenuButton.initialValue
  // was not specified.
  final int? selectedItemIndex;

  // The padding of unsafe area.
  EdgeInsets padding;

  // We put the child wherever position specifies, so long as it will fit within
  // the specified parent size padded (inset) by 8. If necessary, we adjust the
  // child's position so that it fits.

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus 8.0 pixels in each
    // direction.
    return BoxConstraints.loose(constraints.biggest).deflate(
      const EdgeInsets.all(_kMenuScreenPadding) + padding,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size: The size of the overlay.
    // childSize: The size of the menu, when fully open, as determined by
    // getConstraintsForChild.

    final double buttonWidth = size.width - position.left - position.right;
    // Find the ideal horizontal position.
    double x = position.left;
    if (selectedItemIndex != null) {
      double selectedItemOffset = _kMenuHorizontalPadding;
      for (int index = 0; index < selectedItemIndex!; index += 1) {
        selectedItemOffset += itemSizes[index]!.width;
      }
      selectedItemOffset += itemSizes[selectedItemIndex!]!.width / 2;
      x = x + buttonWidth / 2.0 - selectedItemOffset;
    }

    // Find the ideal vertical position.
    double y;
    if (position.top > position.bottom) {
      // Menu button is closer to the top edge, so grow to the bottom, aligned to the bottom edge.
      y = size.height - position.bottom - childSize.height;
    } else {
      // Menu button is closer to the top edge or is equidistant from both edges, so grow down.
      y = position.top;
    }

    // Avoid going outside an area defined as the rectangle 8.0 pixels from the
    // edge of the screen in every direction.
    if (y < _kMenuScreenPadding + padding.top) {
      y = _kMenuScreenPadding + padding.top;
    } else if (y + childSize.height >
        size.height - _kMenuScreenPadding - padding.bottom) {
      y = size.height - childSize.height - _kMenuScreenPadding - padding.bottom;
    }
    if (x < _kMenuScreenPadding + padding.left) {
      x = _kMenuScreenPadding + padding.left;
    } else if (x + childSize.width >
        size.width - _kMenuScreenPadding - padding.right) {
      x = size.width - padding.right - _kMenuScreenPadding - childSize.width;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    // If called when the old and new itemSizes have been initialized then
    // we expect them to have the same length because there's no practical
    // way to change length of the items list once the menu has been shown.
    assert(itemSizes.length == oldDelegate.itemSizes.length);

    return position != oldDelegate.position ||
        selectedItemIndex != oldDelegate.selectedItemIndex ||
        !listEquals(itemSizes, oldDelegate.itemSizes) ||
        padding != oldDelegate.padding;
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    required this.position,
    required this.items,
    this.initialValue,
    this.elevation,
    required this.barrierLabel,
    this.semanticLabel,
    this.shape,
    this.color,
    required this.capturedThemes,
  }) : itemSizes = List<Size?>.filled(items.length, null);

  final RelativeRect position;
  final List<MongolPopupMenuEntry<T>> items;
  final List<Size?> itemSizes;
  final T? initialValue;
  final double? elevation;
  final String? semanticLabel;
  final ShapeBorder? shape;
  final Color? color;
  final CapturedThemes capturedThemes;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linear,
      reverseCurve: const Interval(0.0, _kMenuCloseIntervalEnd),
    );
  }

  @override
  Duration get transitionDuration => _kMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    int? selectedItemIndex;
    if (initialValue != null) {
      for (int index = 0;
          selectedItemIndex == null && index < items.length;
          index += 1) {
        if (items[index].represents(initialValue)) selectedItemIndex = index;
      }
    }

    final Widget menu =
        _PopupMenu<T>(route: this, semanticLabel: semanticLabel);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _PopupMenuRouteLayout(
              position,
              itemSizes,
              selectedItemIndex,
              mediaQuery.padding,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}

/// Show a popup menu that contains the `items` at `position`.
///
/// `items` should be non-null and not empty.
///
/// If `initialValue` is specified then the first item with a matching value
/// will be highlighted and the value of `position` gives the rectangle whose
/// horizontal center will be aligned with the horizontal center of the highlighted
/// item (when possible).
///
/// If `initialValue` is not specified then the right side of the menu will be aligned
/// with the right side of the `position` rectangle.
///
/// In both cases, the menu position will be adjusted if necessary to fit on the
/// screen.
///
/// Vertically, the menu is positioned so that it grows in the direction that
/// has the most room. For example, if the `position` describes a rectangle on
/// the top edge of the screen, then the top edge of the menu is aligned with
/// the top edge of the `position`, and the menu grows to the bottom. If both
/// edges of the `position` are equidistant from the opposite edge of the
/// screen, then it grows down.
///
/// The positioning of the `initialValue` at the `position` is implemented by
/// iterating over the `items` to find the first whose
/// [MongolPopupMenuEntry.represents] method returns true for `initialValue`, and then
/// summing the values of [MongolPopupMenuEntry.width] for all the preceding widgets
/// in the list.
///
/// The `elevation` argument specifies the z-coordinate at which to place the
/// menu. The elevation defaults to 8, the appropriate elevation for popup
/// menus.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the menu. It is only used when the method is called. Its corresponding
/// widget can be safely removed from the tree before the popup menu is closed.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// menu to the [Navigator] furthest from or nearest to the given `context`. It
/// is `false` by default.
///
/// The `semanticLabel` argument is used by accessibility frameworks to
/// announce screen transitions when the menu is opened and closed. If this
/// label is not provided, it will default to
/// [MaterialLocalizations.popupMenuLabel].
///
/// See also:
///
///  * [MongolPopupMenuItem], a popup menu entry for a single value.
///  * [MongolPopupMenuDivider], a popup menu entry that is just a vertical line.
///  * [MongolPopupMenuButton], which provides an [IconButton] that shows a menu by
///    calling this method automatically.
///  * [SemanticsConfiguration.namesRoute], for a description of edge triggered
///    semantics.
Future<T?> showMongolMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<MongolPopupMenuEntry<T>> items,
  T? initialValue,
  double? elevation,
  String? semanticLabel,
  ShapeBorder? shape,
  Color? color,
  bool useRootNavigator = false,
}) {
  assert(items.isNotEmpty);

  semanticLabel ??= MaterialLocalizations.of(context).popupMenuLabel;

  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(_PopupMenuRoute<T>(
    position: position,
    items: items,
    initialValue: initialValue,
    elevation: elevation,
    semanticLabel: semanticLabel,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    shape: shape,
    color: color,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
  ));
}

/// Signature for the callback invoked when a menu item is selected. The
/// argument is the value of the [MongolPopupMenuItem] that caused its menu to be
/// dismissed.
///
/// Used by [MongolPopupMenuButton.onSelected].
typedef MongolPopupMenuItemSelected<T> = void Function(T value);

/// Signature for the callback invoked when a [MongolPopupMenuButton] is dismissed
/// without selecting an item.
///
/// Used by [MongolPopupMenuButton.onCanceled].
typedef MongolPopupMenuCanceled = void Function();

/// Signature used by [MongolPopupMenuButton] to lazily construct the items shown when
/// the button is pressed.
///
/// Used by [MongolPopupMenuButton.itemBuilder].
typedef MongolPopupMenuItemBuilder<T> = List<MongolPopupMenuEntry<T>> Function(
    BuildContext context);

/// Displays a menu when pressed and calls [onSelected] when the menu is dismissed
/// because an item was selected. The value passed to [onSelected] is the value of
/// the selected menu item.
///
/// One of [child] or [icon] may be provided, but not both. If [icon] is provided,
/// then [MongolPopupMenuButton] behaves like an [IconButton].
///
/// If both are null, then a standard overflow icon is created (depending on the
/// platform).
///
/// {@tool snippet}
///
/// This example shows a menu with four items, selecting between an enum's
/// values and setting a `_selection` field based on the selection.
///
/// ```dart
/// // This is the type used by the popup menu below.
/// enum WhyFarther { harder, smarter, selfStarter, tradingCharter }
///
/// // This menu button widget updates a _selection field (of type WhyFarther,
/// // not shown here).
/// MongolPopupMenuButton<WhyFarther>(
///   onSelected: (WhyFarther result) { setState(() { _selection = result; }); },
///   itemBuilder: (BuildContext context) => <MongolPopupMenuEntry<WhyFarther>>[
///     const MongolPopupMenuItem<WhyFarther>(
///       value: WhyFarther.harder,
///       child: MongolText('Working a lot harder'),
///     ),
///     const MongolPopupMenuItem<WhyFarther>(
///       value: WhyFarther.smarter,
///       child: MongolText('Being a lot smarter'),
///     ),
///     const MongolPopupMenuItem<WhyFarther>(
///       value: WhyFarther.selfStarter,
///       child: MongolText('Being a self-starter'),
///     ),
///     const MongolPopupMenuItem<WhyFarther>(
///       value: WhyFarther.tradingCharter,
///       child: MongolText('Placed in charge of trading charter'),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [MongolPopupMenuItem], a popup menu entry for a single value.
///  * [MongolPopupMenuDivider], a popup menu entry that is just a vertical line.
///  * [showMongolMenu], a method to dynamically show a popup menu at a given location.
class MongolPopupMenuButton<T> extends StatefulWidget {
  /// Creates a button that shows a popup menu.
  ///
  /// The [itemBuilder] argument must not be null.
  const MongolPopupMenuButton({
    Key? key,
    required this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.elevation,
    this.padding = const EdgeInsets.all(8.0),
    this.child,
    this.icon,
    this.iconSize,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
    this.enableFeedback,
  })  : assert(
          !(child != null && icon != null),
          'You can only pass [child] or [icon], not both.',
        ),
        super(key: key);

  /// Called when the button is pressed to create the items to show in the menu.
  final MongolPopupMenuItemBuilder<T> itemBuilder;

  /// The value of the menu item, if any, that should be highlighted when the menu opens.
  final T? initialValue;

  /// Called when the user selects a value from the popup menu created by this button.
  ///
  /// If the popup menu is dismissed without selecting a value, [onCanceled] is
  /// called instead.
  final MongolPopupMenuItemSelected<T>? onSelected;

  /// Called when the user dismisses the popup menu without selecting an item.
  ///
  /// If the user selects a value, [onSelected] is called instead.
  final MongolPopupMenuCanceled? onCanceled;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String? tooltip;

  /// The z-coordinate at which to place the menu when open. This controls the
  /// size of the shadow below the menu.
  ///
  /// Defaults to 8, the appropriate elevation for popup menus.
  final double? elevation;

  /// Matches IconButton's 8 dps padding by default. In some cases, notably where
  /// this button appears as the trailing element of a list item, it's useful to be able
  /// to set the padding to zero.
  final EdgeInsetsGeometry padding;

  /// If provided, [child] is the widget used for this button
  /// and the button will utilize an [InkWell] for taps.
  final Widget? child;

  /// If provided, the [icon] is used for this button
  /// and the button will behave like an [IconButton].
  final Widget? icon;

  /// The offset applied to the Popup Menu Button.
  ///
  /// When not set, the Popup Menu Button will be positioned directly next to
  /// the button that was used to create it.
  final Offset offset;

  /// Whether this popup menu button is interactive.
  ///
  /// Must be non-null, defaults to `true`
  ///
  /// If `true` the button will respond to presses by displaying the menu.
  ///
  /// If `false`, the button is styled with the disabled color from the
  /// current [Theme] and will not respond to presses or show the popup
  /// menu and [onSelected], [onCanceled] and [itemBuilder] will not be called.
  ///
  /// This can be useful in situations where the app needs to show the button,
  /// but doesn't currently have anything to show in the menu.
  final bool enabled;

  /// If provided, the shape used for the menu.
  ///
  /// If this property is null, then [PopupMenuThemeData.shape] is used.
  /// If [PopupMenuThemeData.shape] is also null, then the default shape for
  /// [MaterialType.card] is used. This default shape is a rectangle with
  /// rounded edges of BorderRadius.circular(2.0).
  final ShapeBorder? shape;

  /// If provided, the background color used for the menu.
  ///
  /// If this property is null, then [PopupMenuThemeData.color] is used.
  /// If [PopupMenuThemeData.color] is also null, then
  /// Theme.of(context).cardColor is used.
  final Color? color;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// If provided, the size of the [Icon].
  ///
  /// If this property is null, the default size is 24.0 pixels.
  final double? iconSize;

  @override
  MongolPopupMenuButtonState<T> createState() =>
      MongolPopupMenuButtonState<T>();
}

/// The [State] for a [MongolPopupMenuButton].
///
/// See [showButtonMenu] for a way to programmatically open the popup menu
/// of your button state.
class MongolPopupMenuButtonState<T> extends State<MongolPopupMenuButton<T>> {
  /// A method to show a popup menu with the items supplied to
  /// [MongolPopupMenuButton.itemBuilder] at the position of your [MongolPopupMenuButton].
  ///
  /// By default, it is called when the user taps the button and [MongolPopupMenuButton.enabled]
  /// is set to `true`. Moreover, you can open the button by calling the method manually.
  ///
  /// You would access your [MongolPopupMenuButtonState] using a [GlobalKey] and
  /// show the menu of the button with `globalKey.currentState.showButtonMenu`.
  void showButtonMenu() {
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(widget.offset, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero) + widget.offset,
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final List<MongolPopupMenuEntry<T>> items = widget.itemBuilder(context);
    // Only show the menu if there is something to show
    if (items.isNotEmpty) {
      showMongolMenu<T?>(
        context: context,
        elevation: widget.elevation ?? popupMenuTheme.elevation,
        items: items,
        initialValue: widget.initialValue,
        position: position,
        shape: widget.shape ?? popupMenuTheme.shape,
        color: widget.color ?? popupMenuTheme.color,
      ).then<void>((T? newValue) {
        if (!mounted) return null;
        if (newValue == null) {
          widget.onCanceled?.call();
          return null;
        }
        widget.onSelected?.call(newValue);
      });
    }
  }

  bool get _canRequestFocus {
    final NavigationMode mode = MediaQuery.maybeOf(context)?.navigationMode ??
        NavigationMode.traditional;
    switch (mode) {
      case NavigationMode.traditional:
        return widget.enabled;
      case NavigationMode.directional:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enableFeedback = widget.enableFeedback ??
        PopupMenuTheme.of(context).enableFeedback ??
        true;

    if (widget.child != null) {
      return MongolTooltip(
        message:
            widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
        child: InkWell(
          onTap: widget.enabled ? showButtonMenu : null,
          canRequestFocus: _canRequestFocus,
          enableFeedback: enableFeedback,
          child: widget.child,
        ),
      );
    }

    return MongolIconButton(
      icon: widget.icon ?? Icon(Icons.adaptive.more),
      padding: widget.padding,
      iconSize: widget.iconSize ?? 24.0,
      mongolTooltip:
          widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
      onPressed: widget.enabled ? showButtonMenu : null,
      enableFeedback: enableFeedback,
    );
  }
}
