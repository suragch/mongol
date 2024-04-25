// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        Brightness,
        ColorScheme,
        IconButton,
        Icons,
        InkWell,
        ListTileTheme,
        Material,
        MaterialLocalizations,
        MaterialState,
        MaterialStateMouseCursor,
        MaterialStateProperty,
        MaterialType,
        PopupMenuTheme,
        PopupMenuThemeData,
        TextTheme,
        Theme,
        ThemeData,
        VerticalDivider,
        debugCheckHasMaterialLocalizations,
        kMinInteractiveDimension,
        kThemeChangeDuration;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/mongol.dart';

import 'mongol_intrinsic_height.dart';

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
///  * [MongolCheckedPopupMenuItem], a popup menu item with a checkmark.
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
    required this.onLayout,
    required super.child,
  });

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
/// To show a checkmark next to a popup menu item, consider using
/// [MongolCheckedPopupMenuItem].
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
/// used in a complete menu, and see the example at [MongolCheckedPopupMenuItem] for one way to
/// keep the text of [MongolPopupMenuItem]s that use [MongolText] widgets in their [child]
/// slot aligned with the text of [MongolCheckedPopupMenuItem]s or of [MongolPopupMenuItem]
/// that use a [MongolListTile] in their [child] slot.
///
/// See also:
///
///  * [MongolPopupMenuDivider], which can be used to divide items from each other.
///  * [MongolCheckedPopupMenuItem], a variant of [MongolPopupMenuItem] with a checkmark.
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
    super.key,
    this.value,
    this.onTap,
    this.enabled = true,
    this.width = kMinInteractiveDimension,
    this.padding,
    this.textStyle,
    this.labelTextStyle,
    this.mouseCursor,
    required this.child,
  });

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
  /// If this is null and [ThemeData.useMaterial3] is true, the vertical padding
  /// defaults to 12.0 on both sides.
  ///
  /// If this is null and [ThemeData.useMaterial3] is false, the vertical padding
  /// defaults to 16.0 on both sides.
  ///
  /// When null, the vertical padding defaults to 16.0 on both sides.
  final EdgeInsets? padding;

  /// The text style of the popup menu item.
  ///
  /// If this property is null, then [PopupMenuThemeData.textStyle] is used.
  /// If [PopupMenuThemeData.textStyle] is also null, then [TextTheme.titleMedium]
  /// of [ThemeData.textTheme] is used.
  final TextStyle? textStyle;

  /// The label style of the popup menu item.
  ///
  /// When [ThemeData.useMaterial3] is true, this styles the text of the popup menu item.
  ///
  /// If this property is null, then [PopupMenuThemeData.labelTextStyle] is used.
  /// If [PopupMenuThemeData.labelTextStyle] is also null, then [TextTheme.labelLarge]
  /// is used with the [ColorScheme.onSurface] color when popup menu item is enabled and
  /// the [ColorScheme.onSurface] color with 0.38 opacity when the popup menu item is disabled.
  final MaterialStateProperty<TextStyle?>? labelTextStyle;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the following [MaterialState]:
  ///
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  ///
  /// If null, then the value of [PopupMenuThemeData.mouseCursor] is used. If
  /// that is also null, then [MaterialStateMouseCursor.clickable] is used.
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
    // Need to pop the navigator first in case onTap may push new route onto navigator.
    Navigator.pop<T>(context, widget.value);

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final PopupMenuThemeData defaults = theme.useMaterial3
        ? _PopupMenuDefaultsM3(context)
        : _PopupMenuDefaultsM2(context);
    final Set<MaterialState> states = <MaterialState>{
      if (!widget.enabled) MaterialState.disabled,
    };

    TextStyle style = theme.useMaterial3
        ? (widget.labelTextStyle?.resolve(states) ??
            popupMenuTheme.labelTextStyle?.resolve(states)! ??
            defaults.labelTextStyle!.resolve(states)!)
        : (widget.textStyle ?? popupMenuTheme.textStyle ?? defaults.textStyle!);

    if (!widget.enabled && !theme.useMaterial3) {
      style = style.copyWith(color: theme.disabledColor);
    }

    Widget item = AnimatedDefaultTextStyle(
      style: style,
      duration: kThemeChangeDuration,
      child: Container(
        alignment: Alignment.topCenter,
        constraints: BoxConstraints(minWidth: widget.width),
        padding: widget.padding ??
            (theme.useMaterial3
                ? _PopupMenuDefaultsM3.menuVerticalPadding
                : _PopupMenuDefaultsM2.menuVerticalPadding),
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

    return MergeSemantics(
      child: Semantics(
        enabled: widget.enabled,
        button: true,
        child: InkWell(
          onTap: widget.enabled ? handleTap : null,
          canRequestFocus: widget.enabled,
          mouseCursor: _EffectiveMouseCursor(
              widget.mouseCursor, popupMenuTheme.mouseCursor),
          // todo material3: there should use ListTileTheme instead of MongolListTileTheme
          child: ListTileTheme.merge(
            contentPadding: EdgeInsets.zero,
            titleTextStyle: style,
            child: item,
          ),
        ),
      ),
    );
  }
}

/// An item with a checkmark in a Mongol Material Design popup menu.
///
/// To show a popup menu, use the [showMongolMenu] function. To create a button that
/// shows a popup menu, consider using [MongolPopupMenuButton].
///
/// A [MongolCheckedPopupMenuItem] is kMinInteractiveDimension pixels high, which
/// matches the default minimum height of a [MongolPopupMenuItem]. The horizontal
/// layout uses [MongolListTile]; the checkmark is an [Icons.done] icon, shown in the
/// [MongolListTile.leading] position.
///
/// {@tool snippet}
///
/// Suppose a `Commands` enum exists that lists the possible commands from a
/// particular popup menu, including `Commands.heroAndScholar` and
/// `Commands.hurricaneCame`, and further suppose that there is a
/// `_heroAndScholar` member field which is a boolean. The example below shows a
/// menu with one menu item with a checkmark that can toggle the boolean, and
/// one menu item without a checkmark for selecting the second option. (It also
/// shows a divider placed between the two menu items.)
///
/// ```dart
/// MongolPopupMenuButton<Commands>(
///   onSelected: (Commands result) {
///     switch (result) {
///       case Commands.heroAndScholar:
///         setState(() { _heroAndScholar = !_heroAndScholar; });
///       case Commands.hurricaneCame:
///         // ...handle hurricane option
///         break;
///       // ...other items handled here
///     }
///   },
///   itemBuilder: (BuildContext context) => <MongolPopupMenuEntry<Commands>>[
///     CheckedPopupMenuItem<Commands>(
///       checked: _heroAndScholar,
///       value: Commands.heroAndScholar,
///       child: const Text('Hero and scholar'),
///     ),
///     const MongolPopupMenuDivider(),
///     const MongolPopupMenuItem<Commands>(
///       value: Commands.hurricaneCame,
///       child: MongolListTile(leading: Icon(null), title: Text('Bring hurricane')),
///     ),
///     // ...other items listed here
///   ],
/// )
/// ```
/// {@end-tool}
///
/// In particular, observe how the second menu item uses a [MongolListTile] with a
/// blank [Icon] in the [MongolListTile.leading] position to get the same alignment as
/// the item with the checkmark.
///
/// See also:
///
///  * [MongolPopupMenuItem], a popup menu entry for picking a command (as opposed to
///    toggling a value).
///  * [MongolPopupMenuDivider], a popup menu entry that is just a horizontal line.
///  * [showMongolMenu], a method to dynamically show a popup menu at a given location.
///  * [MongolPopupMenuButton], an [MongolIconButton] that automatically shows a menu when
///    it is tapped.
class MongolCheckedPopupMenuItem<T> extends MongolPopupMenuItem<T> {
  /// Creates a popup menu item with a checkmark.
  ///
  /// By default, the menu item is [enabled] but unchecked. To mark the item as
  /// checked, set [checked] to true.
  const MongolCheckedPopupMenuItem({
    super.key,
    super.value,
    this.checked = false,
    super.enabled,
    super.padding,
    super.width,
    super.labelTextStyle,
    super.mouseCursor,
    super.child,
    super.onTap,
  });

  /// Whether to display a checkmark next to the menu item.
  ///
  /// Defaults to false.
  ///
  /// When true, an [Icons.done] checkmark is displayed.
  ///
  /// When this popup menu item is selected, the checkmark will fade in or out
  /// as appropriate to represent the implied new state.
  final bool checked;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text]. An appropriate [DefaultTextStyle] is put in scope for
  /// the child. The text should be short enough that it won't wrap.
  ///
  /// This widget is placed in the [ListTile.title] slot of a [ListTile] whose
  /// [ListTile.leading] slot is an [Icons.done] icon.
  @override
  Widget? get child => super.child;

  @override
  MongolPopupMenuItemState<T, MongolCheckedPopupMenuItem<T>> createState() => _MongolCheckedPopupMenuItemState<T>();
}

class _MongolCheckedPopupMenuItemState<T> extends MongolPopupMenuItemState<T, MongolCheckedPopupMenuItem<T>> with SingleTickerProviderStateMixin {
  static const Duration _fadeDuration = Duration(milliseconds: 150);
  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _fadeDuration, vsync: this)
      ..value = widget.checked ? 1.0 : 0.0
      ..addListener(() => setState(() { /* animation changed */ }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void handleTap() {
    // This fades the checkmark in or out when tapped.
    if (widget.checked) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    super.handleTap();
  }

  @override
  Widget buildChild() {
    final ThemeData theme = Theme.of(context);
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final PopupMenuThemeData defaults = theme.useMaterial3 ? _PopupMenuDefaultsM3(context) : _PopupMenuDefaultsM2(context);
    final Set<MaterialState> states = <MaterialState>{
      if (widget.checked) MaterialState.selected,
    };
    final MaterialStateProperty<TextStyle?>? effectiveLabelTextStyle = widget.labelTextStyle
      ?? popupMenuTheme.labelTextStyle
      ?? defaults.labelTextStyle;
    return IgnorePointer(
      child: MongolListTileTheme.merge(
        contentPadding: EdgeInsets.zero,
        child: MongolListTile(
          enabled: widget.enabled,
          // todo material3
          // titleTextStyle: effectiveLabelTextStyle?.resolve(states),
          leading: FadeTransition(
            opacity: _opacity,
            child: Icon(_controller.isDismissed ? null : Icons.done),
          ),
          title: widget.child,
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
    this.constraints,
    required this.clipBehavior,
  }) : super(key: key);

  final _PopupMenuRoute<T> route;
  final String? semanticLabel;
  final BoxConstraints? constraints;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    // 1.0 for the height and 0.5 for the last item's fade.
    final double unit = 1.0 / (route.items.length + 1.5);
    final List<Widget> children = <Widget>[];
    final ThemeData theme = Theme.of(context);
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final PopupMenuThemeData defaults = theme.useMaterial3
        ? _PopupMenuDefaultsM3(context)
        : _PopupMenuDefaultsM2(context);

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
        return FadeTransition(
          opacity: opacity.animate(route.animation!),
          child: Material(
            shape: route.shape ?? popupMenuTheme.shape ?? defaults.shape,
            color: route.color ?? popupMenuTheme.color ?? defaults.color,
            clipBehavior: clipBehavior,
            type: MaterialType.card,
            elevation: route.elevation ??
                popupMenuTheme.elevation ??
                defaults.elevation!,
            shadowColor: route.shadowColor ??
                popupMenuTheme.shadowColor ??
                defaults.shadowColor,
            surfaceTintColor: route.surfaceTintColor ??
                popupMenuTheme.surfaceTintColor ??
                defaults.surfaceTintColor,
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
    this.avoidBounds,
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

  // List of rectangles that we should avoid overlapping. Unusable screen area.
  final Set<Rect> avoidBounds;

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

    final Offset wantedPosition = Offset(x, y);
    final Offset originCenter = position.toRect(Offset.zero & size).center;
    final Iterable<Rect> subScreens =
        DisplayFeatureSubScreen.subScreensInBounds(
            Offset.zero & size, avoidBounds);
    final Rect subScreen = _closestScreen(subScreens, originCenter);
    return _fitInsideScreen(subScreen, childSize, wantedPosition);

    // Avoid going outside an area defined as the rectangle 8.0 pixels from the
    // edge of the screen in every direction.
    // todo material3: this should be removed
    // if (y < _kMenuScreenPadding + padding.top) {
    //   y = _kMenuScreenPadding + padding.top;
    // } else if (y + childSize.height >
    //     size.height - _kMenuScreenPadding - padding.bottom) {
    //   y = size.height - childSize.height - _kMenuScreenPadding - padding.bottom;
    // }
    // if (x < _kMenuScreenPadding + padding.left) {
    //   x = _kMenuScreenPadding + padding.left;
    // } else if (x + childSize.width >
    //     size.width - _kMenuScreenPadding - padding.right) {
    //   x = size.width - padding.right - _kMenuScreenPadding - childSize.width;
    // }

    // return Offset(x, y);
  }

  Rect _closestScreen(Iterable<Rect> screens, Offset point) {
    Rect closest = screens.first;
    for (final Rect screen in screens) {
      if ((screen.center - point).distance <
          (closest.center - point).distance) {
        closest = screen;
      }
    }
    return closest;
  }

  Offset _fitInsideScreen(Rect screen, Size childSize, Offset wantedPosition) {
    double x = wantedPosition.dx;
    double y = wantedPosition.dy;
    // Avoid going outside an area defined as the rectangle 8.0 pixels from the
    // edge of the screen in every direction.
    if (y < screen.top + _kMenuScreenPadding + padding.top) {
      y = _kMenuScreenPadding + padding.top;
    } else if (y + childSize.height >
        screen.bottom - _kMenuScreenPadding - padding.bottom) {
      y = screen.bottom -
          childSize.height -
          _kMenuScreenPadding -
          padding.bottom;
    }
    if (x < screen.left + _kMenuScreenPadding + padding.left) {
      x = screen.left + _kMenuScreenPadding + padding.left;
    } else if (x + childSize.width >
        screen.right - _kMenuScreenPadding - padding.right) {
      x = screen.right - childSize.width - _kMenuScreenPadding - padding.right;
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
        padding != oldDelegate.padding ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    required this.position,
    required this.items,
    this.initialValue,
    this.elevation,
    this.surfaceTintColor,
    this.shadowColor,
    required this.barrierLabel,
    this.semanticLabel,
    this.shape,
    this.color,
    required this.capturedThemes,
    this.constraints,
    required this.clipBehavior,
    super.settings,
    this.popUpAnimationStyle,
  })  : itemSizes = List<Size?>.filled(items.length, null),
        // Menus always cycle focus through their items irrespective of the
        // focus traversal edge behavior set in the Navigator.
        super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  final RelativeRect position;
  final List<MongolPopupMenuEntry<T>> items;
  final List<Size?> itemSizes;
  final T? initialValue;
  final double? elevation;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final String? semanticLabel;
  final ShapeBorder? shape;
  final Color? color;
  final CapturedThemes capturedThemes;
  final BoxConstraints? constraints;
  final Clip clipBehavior;
  final AnimationStyle? popUpAnimationStyle;

  @override
  Animation<double> createAnimation() {
    if (popUpAnimationStyle != AnimationStyle.noAnimation) {
      return CurvedAnimation(
        parent: super.createAnimation(),
        curve: popUpAnimationStyle?.curve ?? Curves.linear,
        reverseCurve: popUpAnimationStyle?.reverseCurve ??
            const Interval(0.0, _kMenuCloseIntervalEnd),
      );
    }
    return super.createAnimation();
  }

  @override
  Duration get transitionDuration =>
      popUpAnimationStyle?.duration ?? _kMenuDuration;

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

    final Widget menu = _PopupMenu<T>(
      route: this,
      semanticLabel: semanticLabel,
      constraints: constraints,
      clipBehavior: clipBehavior,
    );
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
              _avoidBounds(mediaQuery),
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }

  Set<Rect> _avoidBounds(MediaQueryData mediaQuery) {
    return DisplayFeatureSubScreen.avoidBounds(mediaQuery).toSet();
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
/// The `clipBehavior` argument is used to clip the shape of the menu. Defaults to
/// [Clip.none].
///
/// See also:
///
///  * [MongolPopupMenuItem], a popup menu entry for a single value.
///  * [MongolPopupMenuDivider], a popup menu entry that is just a vertical line.
///  * [MongolCheckedPopupMenuItem], a popup menu item with a checkmark.
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
  Color? shadowColor,
  Color? surfaceTintColor,
  String? semanticLabel,
  ShapeBorder? shape,
  Color? color,
  bool useRootNavigator = false,
  BoxConstraints? constraints,
  Clip clipBehavior = Clip.none,
  RouteSettings? routeSettings,
  AnimationStyle? popUpAnimationStyle,
}) {
  assert(items.isNotEmpty);
  assert(debugCheckHasMaterialLocalizations(context));

  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      break;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      semanticLabel ??= MaterialLocalizations.of(context).popupMenuLabel;
  }

  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(_PopupMenuRoute<T>(
    position: position,
    items: items,
    initialValue: initialValue,
    elevation: elevation,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    semanticLabel: semanticLabel,
    barrierLabel: MaterialLocalizations.of(context).menuDismissLabel,
    shape: shape,
    color: color,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    constraints: constraints,
    clipBehavior: clipBehavior,
    settings: routeSettings,
    popUpAnimationStyle: popUpAnimationStyle,
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

/// todo material3 MenuAnchor
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
///  * [MongolCheckedPopupMenuItem], a popup menu item with a checkmark.
///  * [showMongolMenu], a method to dynamically show a popup menu at a given location.
class MongolPopupMenuButton<T> extends StatefulWidget {
  /// Creates a button that shows a popup menu.
  ///
  /// The [itemBuilder] argument must not be null.
  const MongolPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.initialValue,
    this.onOpened,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.padding = const EdgeInsets.all(8.0),
    this.child,
    this.splashRadius,
    this.icon,
    this.iconSize,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
    this.iconColor,
    this.enableFeedback,
    this.constraints,
    this.clipBehavior = Clip.none,
    this.useRootNavigator = false,
    this.popUpAnimationStyle,
  }) : assert(
          !(child != null && icon != null),
          'You can only pass [child] or [icon], not both.',
        );

  /// Called when the button is pressed to create the items to show in the menu.
  final MongolPopupMenuItemBuilder<T> itemBuilder;

  /// The value of the menu item, if any, that should be highlighted when the menu opens.
  final T? initialValue;

  /// Called when the popup menu is shown.
  final VoidCallback? onOpened;

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

  /// The color used to paint the shadow below the menu.
  ///
  /// If null then the ambient [PopupMenuThemeData.shadowColor] is used.
  /// If that is null too, then the overall theme's [ThemeData.shadowColor]
  /// (default black) is used.
  final Color? shadowColor;

  /// The color used as an overlay on [color] to indicate elevation.
  ///
  /// If null, [PopupMenuThemeData.surfaceTintColor] is used. If that
  /// is also null, the default value is [ColorScheme.surfaceTint].
  ///
  /// See [Material.surfaceTintColor] for more details on how this
  /// overlay is applied.
  final Color? surfaceTintColor;

  /// Matches IconButton's 8 dps padding by default. In some cases, notably where
  /// this button appears as the trailing element of a list item, it's useful to be able
  /// to set the padding to zero.
  final EdgeInsetsGeometry padding;

  /// The splash radius.
  ///
  /// If null, default splash radius of [InkWell] or [IconButton] is used.
  final double? splashRadius;

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

  /// If provided, this color is used for the button icon.
  ///
  /// If this property is null, then [PopupMenuThemeData.iconColor] is used.
  /// If [PopupMenuThemeData.iconColor] is also null then defaults to
  /// [IconThemeData.color].
  final Color? iconColor;

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

  /// Optional size constraints for the menu.
  ///
  /// When unspecified, defaults to:
  /// ```dart
  /// const BoxConstraints(
  ///   minWidth: 2.0 * 56.0,
  ///   maxWidth: 5.0 * 56.0,
  /// )
  /// ```
  ///
  /// The default constraints ensure that the menu width matches maximum width
  /// recommended by the Material Design guidelines.
  /// Specifying this parameter enables creation of menu wider than
  /// the default maximum width.
  final BoxConstraints? constraints;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// The [clipBehavior] argument is used the clip shape of the menu.
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// Used to determine whether to push the menu to the [Navigator] furthest
  /// from or nearest to the given `context`.
  ///
  /// Defaults to false.
  final bool useRootNavigator;

  /// Used to override the default animation curves and durations of the popup
  /// menu's open and close transitions.
  ///
  /// If [AnimationStyle.curve] is provided, it will be used to override
  /// the default popup animation curve. Otherwise, defaults to [Curves.linear].
  ///
  /// If [AnimationStyle.reverseCurve] is provided, it will be used to
  /// override the default popup animation reverse curve. Otherwise, defaults to
  /// `Interval(0.0, 2.0 / 3.0)`.
  ///
  /// If [AnimationStyle.duration] is provided, it will be used to override
  /// the default popup animation duration. Otherwise, defaults to 300ms.
  ///
  /// To disable the theme animation, use [AnimationStyle.noAnimation].
  ///
  /// If this is null, then the default animation will be used.
  final AnimationStyle? popUpAnimationStyle;

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
      widget.onOpened?.call();
      showMongolMenu<T?>(
        context: context,
        elevation: widget.elevation ?? popupMenuTheme.elevation,
        shadowColor: widget.shadowColor ?? popupMenuTheme.shadowColor,
        surfaceTintColor:
            widget.surfaceTintColor ?? popupMenuTheme.surfaceTintColor,
        items: items,
        initialValue: widget.initialValue,
        position: position,
        shape: widget.shape ?? popupMenuTheme.shape,
        color: widget.color ?? popupMenuTheme.color,
        constraints: widget.constraints,
        clipBehavior: widget.clipBehavior,
        useRootNavigator: widget.useRootNavigator,
        popUpAnimationStyle: widget.popUpAnimationStyle,
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
    final NavigationMode mode =
        MediaQuery.maybeNavigationModeOf(context) ?? NavigationMode.traditional;
    switch (mode) {
      case NavigationMode.traditional:
        return widget.enabled;
      case NavigationMode.directional:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final bool enableFeedback = widget.enableFeedback ??
        PopupMenuTheme.of(context).enableFeedback ??
        true;
    assert(debugCheckHasMaterialLocalizations(context));

    if (widget.child != null) {
      return MongolTooltip(
        message:
            widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
        child: InkWell(
          onTap: widget.enabled ? showButtonMenu : null,
          canRequestFocus: _canRequestFocus,
          radius: widget.splashRadius,
          enableFeedback: enableFeedback,
          child: widget.child,
        ),
      );
    }

    return MongolIconButton(
      icon: widget.icon ?? Icon(Icons.adaptive.more),
      padding: widget.padding,
      splashRadius: widget.splashRadius,
      iconSize: widget.iconSize ?? popupMenuTheme.iconSize ?? iconTheme.size,
      color: widget.iconColor ?? popupMenuTheme.iconColor ?? iconTheme.color,
      tooltip:
          widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
      onPressed: widget.enabled ? showButtonMenu : null,
      enableFeedback: enableFeedback,
    );
  }
}

// This MaterialStateProperty is passed along to the menu item's InkWell which
// resolves the property against MaterialState.disabled, MaterialState.hovered,
// MaterialState.focused.
class _EffectiveMouseCursor extends MaterialStateMouseCursor {
  const _EffectiveMouseCursor(this.widgetCursor, this.themeCursor);

  final MouseCursor? widgetCursor;
  final MaterialStateProperty<MouseCursor?>? themeCursor;

  @override
  MouseCursor resolve(Set<MaterialState> states) {
    return MaterialStateProperty.resolveAs<MouseCursor?>(
            widgetCursor, states) ??
        themeCursor?.resolve(states) ??
        MaterialStateMouseCursor.clickable.resolve(states);
  }

  @override
  String get debugDescription => 'MaterialStateMouseCursor(PopupMenuItemState)';
}

class _PopupMenuDefaultsM2 extends PopupMenuThemeData {
  _PopupMenuDefaultsM2(this.context) : super(elevation: 8.0);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  TextStyle? get textStyle => _textTheme.titleMedium;

  static EdgeInsets menuVerticalPadding =
      const EdgeInsets.symmetric(vertical: 16.0);
}

// BEGIN GENERATED TOKEN PROPERTIES - PopupMenu

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _PopupMenuDefaultsM3 extends PopupMenuThemeData {
  _PopupMenuDefaultsM3(this.context) : super(elevation: 3.0);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  MaterialStateProperty<TextStyle?>? get labelTextStyle {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      final TextStyle style = _textTheme.labelLarge!;
      if (states.contains(MaterialState.disabled)) {
        return style.apply(color: _colors.onSurface.withOpacity(0.38));
      }
      return style.apply(color: _colors.onSurface);
    });
  }

  @override
  Color? get color => _colors.surface;

  @override
  Color? get shadowColor => _colors.shadow;

  @override
  Color? get surfaceTintColor => _colors.surfaceTint;

  @override
  ShapeBorder? get shape => const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)));

  // TODO(tahatesser): This is taken from https://m3.material.io/components/menus/specs
  // Update this when the token is available.
  static EdgeInsets menuVerticalPadding =
      const EdgeInsets.symmetric(vertical: 12.0);
}
// END GENERATED TOKEN PROPERTIES - PopupMenu
