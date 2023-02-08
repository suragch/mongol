// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart'
    show
        Colors,
        Divider,
        Ink,
        InkWell,
        ListTileStyle,
        MaterialState,
        MaterialStateMouseCursor,
        MaterialStateProperty,
        Theme,
        ThemeData,
        VisualDensity,
        debugCheckHasMaterial,
        kThemeChangeDuration;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// An inherited widget that defines color and style parameters for [MongolListTile]s
/// in this widget's subtree.
///
/// Values specified here are used for [MongolListTile] properties that are not given
/// an explicit non-null value.
///
/// The [MongolDrawer] widget specifies a tile theme for its children which sets
/// [style] to [ListTileStyle.drawer].
class MongolListTileTheme extends InheritedTheme {
  /// Creates a list tile theme that controls the color and style parameters for
  /// [MongolListTile]s.
  const MongolListTileTheme({
    Key? key,
    this.dense = false,
    this.shape,
    this.style = ListTileStyle.list,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.contentPadding,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.verticalTitleGap,
    this.minHorizontalPadding,
    this.minLeadingHeight,
    required Widget child,
  }) : super(key: key, child: child);

  /// Creates a list tile theme that controls the color and style parameters for
  /// [MongolListTile]s, and merges in the current list tile theme, if any.
  ///
  /// The [child] argument must not be null.
  static Widget merge({
    Key? key,
    bool? dense,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    double? verticalTitleGap,
    double? minHorizontalPadding,
    double? minLeadingHeight,
    required Widget child,
  }) {
    return Builder(
      builder: (BuildContext context) {
        final MongolListTileTheme parent = MongolListTileTheme.of(context);
        return MongolListTileTheme(
          key: key,
          dense: dense ?? parent.dense,
          shape: shape ?? parent.shape,
          style: style ?? parent.style,
          selectedColor: selectedColor ?? parent.selectedColor,
          iconColor: iconColor ?? parent.iconColor,
          textColor: textColor ?? parent.textColor,
          contentPadding: contentPadding ?? parent.contentPadding,
          tileColor: tileColor ?? parent.tileColor,
          selectedTileColor: selectedTileColor ?? parent.selectedTileColor,
          enableFeedback: enableFeedback ?? parent.enableFeedback,
          verticalTitleGap: verticalTitleGap ?? parent.verticalTitleGap,
          minHorizontalPadding:
              minHorizontalPadding ?? parent.minHorizontalPadding,
          minLeadingHeight: minLeadingHeight ?? parent.minLeadingHeight,
          child: child,
        );
      },
    );
  }

  /// If true then [ListTile]s will have the vertically dense layout.
  final bool dense;

  /// If specified, [shape] defines the [MongolListTile]'s shape.
  final ShapeBorder? shape;

  /// If specified, [style] defines the font used for [MongolListTile] titles.
  final ListTileStyle style;

  /// If specified, the color used for icons and text when a [MongolListTile] is selected.
  final Color? selectedColor;

  /// If specified, the icon color used for enabled [MongolListTile]s that are not selected.
  final Color? iconColor;

  /// If specified, the text color used for enabled [MongolListTile]s that are not selected.
  final Color? textColor;

  /// The tile's internal padding.
  ///
  /// Insets a [MongolListTile]'s contents: its [MongolListTile.leading], [MongolListTile.title],
  /// [MongolListTile.subtitle], and [MongolListTile.trailing] widgets.
  final EdgeInsetsGeometry? contentPadding;

  /// If specified, defines the background color for `MongolListTile` when
  /// [MongolListTile.selected] is false.
  ///
  /// If [MongolListTile.tileColor] is provided, [tileColor] is ignored.
  final Color? tileColor;

  /// If specified, defines the background color for `MongolListTile` when
  /// [MongolListTile.selected] is true.
  ///
  /// If [MongolListTile.selectedTileColor] is provided, [selectedTileColor] is ignored.
  final Color? selectedTileColor;

  /// The vertical gap between the titles and the leading/trailing widgets.
  ///
  /// If specified, overrides the default value of [MongolListTile.verticalTitleGap].
  final double? verticalTitleGap;

  /// The minimum padding on the left and right of the title and subtitle widgets.
  ///
  /// If specified, overrides the default value of [MongolListTile.minHorizontalPadding].
  final double? minHorizontalPadding;

  /// The minimum height allocated for the [MongolListTile.leading] widget.
  ///
  /// If specified, overrides the default value of [MongolListTile.minLeadingHeight].
  final double? minLeadingHeight;

  /// If specified, defines the feedback property for `MongolListTile`.
  ///
  /// If [MongolListTile.enableFeedback] is provided, [enableFeedback] is ignored.
  final bool? enableFeedback;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MongolListTileTheme theme = MongolListTileTheme.of(context);
  /// ```
  static MongolListTileTheme of(BuildContext context) {
    final MongolListTileTheme? result =
        context.dependOnInheritedWidgetOfExactType<MongolListTileTheme>();
    return result ?? const MongolListTileTheme(child: SizedBox());
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MongolListTileTheme(
      dense: dense,
      shape: shape,
      style: style,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      contentPadding: contentPadding,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      verticalTitleGap: verticalTitleGap,
      minHorizontalPadding: minHorizontalPadding,
      minLeadingHeight: minLeadingHeight,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(MongolListTileTheme oldWidget) {
    return dense != oldWidget.dense ||
        shape != oldWidget.shape ||
        style != oldWidget.style ||
        selectedColor != oldWidget.selectedColor ||
        iconColor != oldWidget.iconColor ||
        textColor != oldWidget.textColor ||
        contentPadding != oldWidget.contentPadding ||
        tileColor != oldWidget.tileColor ||
        selectedTileColor != oldWidget.selectedTileColor ||
        enableFeedback != oldWidget.enableFeedback ||
        verticalTitleGap != oldWidget.verticalTitleGap ||
        minHorizontalPadding != oldWidget.minHorizontalPadding ||
        minLeadingHeight != oldWidget.minLeadingHeight;
  }
}

/// A single fixed-width column that typically contains some text as well as
/// a leading or trailing icon.
///
/// This widget is the vertical text version of [ListTile].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=l8dj0yPBvgQ}
///
/// A list tile contains one to three lines of text optionally flanked by icons or
/// other widgets, such as check boxes. The icons (or other widgets) for the
/// tile are defined with the [leading] and [trailing] parameters. The first
/// line of text is not optional and is specified with [title]. The value of
/// [subtitle], which _is_ optional, will occupy the space allocated for an
/// additional line of text, or two lines if [isThreeLine] is true. If [dense]
/// is true then the overall width of this tile and the size of the
/// [DefaultTextStyle]s that wrap the [title] and [subtitle] widget are reduced.
///
/// It is the responsibility of the caller to ensure that [title] does not wrap,
/// and to ensure that [subtitle] doesn't wrap (if [isThreeLine] is false) or
/// wraps to two lines (if it is true).
///
/// The widths of the [leading] and [trailing] widgets are constrained
/// according to the
/// [Material spec](https://material.io/design/components/lists.html).
/// An exception is made for one-line MongolListTiles for accessibility. Please
/// see the example below to see how to adhere to both Material spec and
/// accessibility requirements.
///
/// Note that [leading] and [trailing] widgets can expand as far as they wish
/// vertically, so ensure that they are properly constrained.
///
/// List tiles are typically used in horizontal [ListView]s, or arranged in [Rows]s in
/// [MongolDrawer]s and [Card]s.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// {@tool snippet}
///
/// This example uses a [ListView] to demonstrate different configurations of
/// [MongolListTile]s in [Card]s.
///
/// ![Different variations of ListTile](https://flutter.github.io/assets-for-api-docs/assets/material/list_tile.png)
///
/// ```dart
/// ListView(
///   scrollDirection: Axis.horizontal,
///   children: const <Widget>[
///     Card(child: MongolListTile(title: Text('One-line MongolListTile'))),
///     Card(
///       child: MongolListTile(
///         leading: FlutterLogo(),
///         title: MongolText('One-line with leading widget'),
///       ),
///     ),
///     Card(
///       child: MongolListTile(
///         title: MongolText('One-line with trailing widget'),
///         trailing: Icon(Icons.more_vert),
///       ),
///     ),
///     Card(
///       child: MongolListTile(
///         leading: FlutterLogo(),
///         title: MongolText('One-line with both widgets'),
///         trailing: Icon(Icons.more_vert),
///       ),
///     ),
///     Card(
///       child: MongolListTile(
///         title: MongolText('One-line dense MongolListTile'),
///         dense: true,
///       ),
///     ),
///     Card(
///       child: MongolListTile(
///         leading: FlutterLogo(size: 56.0),
///         title: MongolText('Two-line MongolListTile'),
///         subtitle: MongolText('Here is a second line'),
///         trailing: Icon(Icons.more_vert),
///       ),
///     ),
///     Card(
///       child: MongolListTile(
///         leading: FlutterLogo(size: 72.0),
///         title: MongolText('Three-line MongolListTile'),
///         subtitle: MongolText(
///           'A sufficiently long subtitle warrants three lines.'
///         ),
///         trailing: Icon(Icons.more_vert),
///         isThreeLine: true,
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// To use a [MongolListTile] within a [Column], it needs to be wrapped in an
/// [Expanded] widget. [MongolListTile] requires fixed height constraints,
/// whereas a [Column] does not constrain its children.
///
/// ```dart
/// Column(
///   children: const <Widget>[
///     Expanded(
///       child: MongolListTile(
///         leading: FlutterLogo(),
///         title: MongolText('These MongolListTiles are expanded '),
///       ),
///     ),
///     Expanded(
///       child: MongolListTile(
///         trailing: FlutterLogo(),
///         title: MongolText('to fill the available space.'),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// Tiles can be much more elaborate. Here is a tile which can be tapped, but
/// which is disabled when the `_act` variable is not 2. When the tile is
/// tapped, the whole column has an ink splash effect (see [InkWell]).
///
/// ```dart
/// int _act = 1;
/// // ...
/// MongolListTile(
///   leading: const Icon(Icons.flight_land),
///   title: const MongolText("Trix's airplane"),
///   subtitle: _act != 2 ? const MongolText('The airplane is only in Act II.') : null,
///   enabled: _act == 2,
///   onTap: () { /* react to the tile being tapped */ }
/// )
/// ```
/// {@end-tool}
///
/// To be accessible, tappable [leading] and [trailing] widgets have to
/// be at least 48x48 in size. However, to adhere to the Material spec,
/// [trailing] and [leading] widgets in one-line MongolListTiles should visually be
/// at most 32 ([dense]: true) or 40 ([dense]: false) in width, which may
/// conflict with the accessibility requirement.
///
/// For this reason, a one-line MongolListTile allows the width of [leading]
/// and [trailing] widgets to be constrained by the width of the MongolListTile.
/// This allows for the creation of tappable [leading] and [trailing] widgets
/// that are large enough, but it is up to the developer to ensure that
/// their widgets follow the Material spec.
///
/// {@tool snippet}
///
/// Here is an example of a one-line, non-[dense] MongolListTile with a
/// tappable leading widget that adheres to accessibility requirements and
/// the Material spec. To adjust the use case below for a one-line, [dense]
/// MongolListTile, adjust the horizontal padding to 8.0.
///
/// ```dart
/// MongolListTile(
///   leading: GestureDetector(
///     behavior: HitTestBehavior.translucent,
///     onTap: () {},
///     child: Container(
///       width: 48,
///       height: 48,
///       padding: const EdgeInsets.symmetric(horizontal: 4.0),
///       alignment: Alignment.center,
///       child: const CircleAvatar(),
///     ),
///   ),
///   title: const MongolText('title'),
///   dense: false,
/// ),
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [MongolListTileTheme], which defines visual properties for [MongolListTile]s.
///  * [ListView], which can display an arbitrary number of [MongolListTile]s
///    in a scrolling list.
///  * [CircleAvatar], which shows an icon representing a person and is often
///    used as the [leading] element of a MongolListTile.
///  * [Card], which can be used with [Row] to show a few [MongolListTile]s.
///  * [VerticalDivider], which can be used to separate [MongolListTile]s.
///  * [MongolListTile.divideTiles], a utility for inserting [VerticalDivider]s
///    in between [MongolListTile]s.
///  * <https://material.io/design/components/lists.html>
///  * Cookbook: [Use lists](https://flutter.dev/docs/cookbook/lists/basic-list)
///  * Cookbook: [Implement swipe to dismiss](https://flutter.dev/docs/cookbook/gestures/dismissible)
class MongolListTile extends StatelessWidget {
  /// Creates a vertical list tile.
  ///
  /// If [isThreeLine] is true, then [subtitle] must not be null.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  const MongolListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.visualDensity,
    this.shape,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.mouseCursor,
    this.selected = false,
    this.focusColor,
    this.hoverColor,
    this.focusNode,
    this.autofocus = false,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.verticalTitleGap,
    this.minHorizontalPadding,
    this.minLeadingHeight,
  })  : assert(!isThreeLine || subtitle != null),
        super(key: key);

  /// A widget to display above the title.
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget? leading;

  /// The primary content of the list tile.
  ///
  /// Typically a [MongolText] widget.
  ///
  /// This should not wrap. To enforce the single line limit, use
  /// [MongolText.maxLines].
  final Widget? title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [MongolText] widget.
  ///
  /// If [isThreeLine] is false, this should not wrap.
  ///
  /// If [isThreeLine] is true, this should be configured to take a maximum of
  /// two lines. For example, you can use [MongolText.maxLines] to enforce the number
  /// of lines.
  ///
  /// The subtitle's default [TextStyle] depends on [TextTheme.bodyText2] except
  /// [TextStyle.color]. The [TextStyle.color] depends on the value of [enabled]
  /// and [selected].
  ///
  /// When [enabled] is false, the text color is set to [ThemeData.disabledColor].
  ///
  /// When [selected] is false, the text color is set to [MongolListTileTheme.textColor]
  /// if it's not null and to [TextTheme.caption]'s color if [MongolListTileTheme.textColor]
  /// is null.
  final Widget? subtitle;

  /// A widget to display under the title.
  ///
  /// Typically an [Icon] widget.
  final Widget? trailing;

  /// Whether this list tile is intended to display three lines of text.
  ///
  /// If true, then [subtitle] must be non-null (since it is expected to give
  /// the second and third lines of text).
  ///
  /// If false, the list tile is treated as having one line if the subtitle is
  /// null and treated as having two lines if the subtitle is non-null.
  ///
  /// When using a [MongolText] widget for [title] and [subtitle], you can enforce
  /// line limits using [MongolText.maxLines].
  final bool isThreeLine;

  /// Whether this list tile is part of a horizontally dense list.
  ///
  /// If this property is null then its value is based on [MongolListTileTheme.dense].
  ///
  /// Dense list tiles default to a smaller width.
  final bool? dense;

  /// Defines how compact the list tile's layout will be.
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [visualDensity] for all
  ///    widgets within a [Theme].
  final VisualDensity? visualDensity;

  /// The tile's shape.
  ///
  /// Defines the tile's [InkWell.customBorder] and [Ink.decoration] shape.
  ///
  /// If this property is null then [MongolListTileTheme.shape] is used.
  /// If that's null then a rectangular [Border] will be used.
  final ShapeBorder? shape;

  /// The tile's internal padding.
  ///
  /// Insets a [MongolListTile]'s contents: its [leading], [title], [subtitle],
  /// and [trailing] widgets.
  ///
  /// If null, `EdgeInsets.symmetric(vertical: 16.0)` is used.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether this list tile is interactive.
  ///
  /// If false, this list tile is styled with the disabled color from the
  /// current [Theme] and the [onTap] and [onLongPress] callbacks are
  /// inoperative.
  final bool enabled;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  /// Called when the user long-presses on this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback? onLongPress;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the following [MaterialState]s:
  ///
  ///  * [MaterialState.selected].
  ///  * [MaterialState.disabled].
  ///
  /// If this property is null, [MaterialStateMouseCursor.clickable] will be used.
  final MouseCursor? mouseCursor;

  /// If this tile is also [enabled] then icons and text are rendered with the same color.
  ///
  /// By default the selected color is the theme's primary color. The selected color
  /// can be overridden with a [MongolListTileTheme].
  final bool selected;

  /// The color for the tile's [Material] when it has the input focus.
  final Color? focusColor;

  /// The color for the tile's [Material] when a pointer is hovering over it.
  final Color? hoverColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Defines the background color of `MongolListTile` when [selected] is false.
  ///
  /// When the value is null, the `tileColor` is set to [MongolListTileTheme.tileColor]
  /// if it's not null and to [Colors.transparent] if it's null.
  final Color? tileColor;

  /// Defines the background color of ` MongolListTile` when [selected] is true.
  ///
  /// When the value if null, the `selectedTileColor` is set to
  /// [MongolListTileTheme.selectedTileColor] if it's not null and to
  /// [Colors.transparent] if it's null.
  final Color? selectedTileColor;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// The vertical gap between the titles and the leading/trailing widgets.
  ///
  /// If null, then the value of [MongolListTileTheme.verticalTitleGap] is used. If
  /// that is also null, then a default value of 16 is used.
  final double? verticalTitleGap;

  /// The minimum padding on the left and right of the title and subtitle widgets.
  ///
  /// If null, then the value of [MongolListTileTheme.minHorizontalPadding] is used. If
  /// that is also null, then a default value of 4 is used.
  final double? minHorizontalPadding;

  /// The minimum height allocated for the [MongolListTile.leading] widget.
  ///
  /// If null, then the value of [MongolListTileTheme.minLeadingHeight] is used. If
  /// that is also null, then a default value of 40 is used.
  final double? minLeadingHeight;

  /// Add a one pixel border in between each tile. If color isn't specified the
  /// [ThemeData.dividerColor] of the context's [Theme] is used.
  ///
  /// See also:
  ///
  ///  * [VerticalDivider], which you can use to obtain this effect manually.
  static Iterable<Widget> divideTiles(
      {BuildContext? context,
      required Iterable<Widget> tiles,
      Color? color}) sync* {
    assert(color != null || context != null);

    final Iterator<Widget> iterator = tiles.iterator;
    final bool hasNext = iterator.moveNext();
    if (!hasNext) return;

    final Decoration decoration = BoxDecoration(
      border: Border(
        right: Divider.createBorderSide(context, color: color),
      ),
    );

    Widget tile = iterator.current;
    while (iterator.moveNext()) {
      yield DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: decoration,
        child: tile,
      );
      tile = iterator.current;
    }
    if (hasNext) yield tile;
  }

  Color? _iconColor(ThemeData theme, MongolListTileTheme? tileTheme) {
    if (!enabled) return theme.disabledColor;

    if (selected && tileTheme?.selectedColor != null) {
      return tileTheme!.selectedColor;
    }

    if (!selected && tileTheme?.iconColor != null) return tileTheme!.iconColor;

    switch (theme.brightness) {
      case Brightness.light:
        // For the sake of backwards compatibility, the default for unselected
        // tiles is Colors.black45 rather than colorScheme.onSurface.withAlpha(0x73).
        return selected ? theme.colorScheme.primary : Colors.black45;
      case Brightness.dark:
        return selected
            ? theme.colorScheme.primary
            : null; // null - use current icon theme color
    }
  }

  Color? _textColor(
      ThemeData theme, MongolListTileTheme? tileTheme, Color? defaultColor) {
    if (!enabled) return theme.disabledColor;

    if (selected && tileTheme?.selectedColor != null) {
      return tileTheme!.selectedColor;
    }

    if (!selected && tileTheme?.textColor != null) return tileTheme!.textColor;

    if (selected) return theme.colorScheme.primary;

    return defaultColor;
  }

  bool _isDenseLayout(MongolListTileTheme? tileTheme) {
    return dense ?? tileTheme?.dense ?? false;
  }

  TextStyle _titleTextStyle(ThemeData theme, MongolListTileTheme? tileTheme) {
    final TextStyle style;
    if (tileTheme != null) {
      switch (tileTheme.style) {
        case ListTileStyle.drawer:
          style = theme.textTheme.bodyLarge!;
          break;
        case ListTileStyle.list:
          style = theme.textTheme.titleMedium!;
          break;
      }
    } else {
      style = theme.textTheme.titleMedium!;
    }
    final Color? color = _textColor(theme, tileTheme, style.color);
    return _isDenseLayout(tileTheme)
        ? style.copyWith(fontSize: 13.0, color: color)
        : style.copyWith(color: color);
  }

  TextStyle _subtitleTextStyle(
      ThemeData theme, MongolListTileTheme? tileTheme) {
    final TextStyle style = theme.textTheme.bodyMedium!;
    final Color? color =
        _textColor(theme, tileTheme, theme.textTheme.bodySmall!.color);
    return _isDenseLayout(tileTheme)
        ? style.copyWith(color: color, fontSize: 12.0)
        : style.copyWith(color: color);
  }

  TextStyle _trailingAndLeadingTextStyle(
      ThemeData theme, MongolListTileTheme? tileTheme) {
    final TextStyle style = theme.textTheme.bodyMedium!;
    final Color? color = _textColor(theme, tileTheme, style.color);
    return style.copyWith(color: color);
  }

  Color _tileBackgroundColor(MongolListTileTheme? tileTheme) {
    if (!selected) {
      if (tileColor != null) return tileColor!;
      if (tileTheme?.tileColor != null) return tileTheme!.tileColor!;
    }

    if (selected) {
      if (selectedTileColor != null) return selectedTileColor!;
      if (tileTheme?.selectedTileColor != null) {
        return tileTheme!.selectedTileColor!;
      }
    }

    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    final MongolListTileTheme tileTheme = MongolListTileTheme.of(context);

    IconThemeData? iconThemeData;
    TextStyle? leadingAndTrailingTextStyle;
    if (leading != null || trailing != null) {
      iconThemeData = IconThemeData(color: _iconColor(theme, tileTheme));
      leadingAndTrailingTextStyle =
          _trailingAndLeadingTextStyle(theme, tileTheme);
    }

    Widget? leadingIcon;
    if (leading != null) {
      leadingIcon = AnimatedDefaultTextStyle(
        style: leadingAndTrailingTextStyle!,
        duration: kThemeChangeDuration,
        child: IconTheme.merge(
          data: iconThemeData!,
          child: leading!,
        ),
      );
    }

    final TextStyle titleStyle = _titleTextStyle(theme, tileTheme);
    final Widget titleText = AnimatedDefaultTextStyle(
      style: titleStyle,
      duration: kThemeChangeDuration,
      child: title ?? const SizedBox(),
    );

    Widget? subtitleText;
    TextStyle? subtitleStyle;
    if (subtitle != null) {
      subtitleStyle = _subtitleTextStyle(theme, tileTheme);
      subtitleText = AnimatedDefaultTextStyle(
        style: subtitleStyle,
        duration: kThemeChangeDuration,
        child: subtitle!,
      );
    }

    Widget? trailingIcon;
    if (trailing != null) {
      trailingIcon = AnimatedDefaultTextStyle(
        style: leadingAndTrailingTextStyle!,
        duration: kThemeChangeDuration,
        child: IconTheme.merge(
          data: iconThemeData!,
          child: trailing!,
        ),
      );
    }

    const EdgeInsets defaultContentPadding =
        EdgeInsets.symmetric(vertical: 16.0);
    const TextDirection textDirection = TextDirection.ltr;
    final EdgeInsets resolvedContentPadding =
        contentPadding?.resolve(textDirection) ??
            tileTheme.contentPadding?.resolve(textDirection) ??
            defaultContentPadding;

    final MouseCursor resolvedMouseCursor =
        MaterialStateProperty.resolveAs<MouseCursor>(
      mouseCursor ?? MaterialStateMouseCursor.clickable,
      <MaterialState>{
        if (!enabled || (onTap == null && onLongPress == null))
          MaterialState.disabled,
        if (selected) MaterialState.selected,
      },
    );

    return InkWell(
      customBorder: shape ?? tileTheme.shape,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      mouseCursor: resolvedMouseCursor,
      canRequestFocus: enabled,
      focusNode: focusNode,
      focusColor: focusColor,
      hoverColor: hoverColor,
      autofocus: autofocus,
      enableFeedback: enableFeedback ?? tileTheme.enableFeedback ?? true,
      child: Semantics(
        selected: selected,
        enabled: enabled,
        child: Ink(
          decoration: ShapeDecoration(
            shape: shape ?? tileTheme.shape ?? const Border(),
            color: _tileBackgroundColor(tileTheme),
          ),
          child: SafeArea(
            left: false,
            right: false,
            minimum: resolvedContentPadding,
            child: _MongolListTile(
              leading: leadingIcon,
              title: titleText,
              subtitle: subtitleText,
              trailing: trailingIcon,
              isDense: _isDenseLayout(tileTheme),
              visualDensity: visualDensity ?? theme.visualDensity,
              isThreeLine: isThreeLine,
              titleBaselineType: titleStyle.textBaseline!,
              subtitleBaselineType: subtitleStyle?.textBaseline,
              verticalTitleGap:
                  verticalTitleGap ?? tileTheme.verticalTitleGap ?? 16,
              minHorizontalPadding:
                  minHorizontalPadding ?? tileTheme.minHorizontalPadding ?? 4,
              minLeadingHeight:
                  minLeadingHeight ?? tileTheme.minLeadingHeight ?? 40,
            ),
          ),
        ),
      ),
    );
  }
}

// Identifies the children of a _MongolListTileElement.
enum _ListTileSlot {
  leading,
  title,
  subtitle,
  trailing,
}

class _MongolListTile extends RenderObjectWidget {
  const _MongolListTile({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.isThreeLine,
    required this.isDense,
    required this.visualDensity,
    required this.titleBaselineType,
    required this.verticalTitleGap,
    required this.minHorizontalPadding,
    required this.minLeadingHeight,
    this.subtitleBaselineType,
  }) : super(key: key);

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool isDense;
  final VisualDensity visualDensity;
  final TextBaseline titleBaselineType;
  final TextBaseline? subtitleBaselineType;
  final double verticalTitleGap;
  final double minHorizontalPadding;
  final double minLeadingHeight;

  @override
  _MongolListTileElement createElement() => _MongolListTileElement(this);

  @override
  _MongolRenderListTile createRenderObject(BuildContext context) {
    return _MongolRenderListTile(
      isThreeLine: isThreeLine,
      isDense: isDense,
      visualDensity: visualDensity,
      titleBaselineType: titleBaselineType,
      subtitleBaselineType: subtitleBaselineType,
      verticalTitleGap: verticalTitleGap,
      minHorizontalPadding: minHorizontalPadding,
      minLeadingHeight: minLeadingHeight,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _MongolRenderListTile renderObject) {
    renderObject
      ..isThreeLine = isThreeLine
      ..isDense = isDense
      ..visualDensity = visualDensity
      ..titleBaselineType = titleBaselineType
      ..subtitleBaselineType = subtitleBaselineType
      ..verticalTitleGap = verticalTitleGap
      ..minHorizontalPadding = minHorizontalPadding
      ..minLeadingHeight = minLeadingHeight;
  }
}

class _MongolListTileElement extends RenderObjectElement {
  _MongolListTileElement(_MongolListTile widget) : super(widget);

  final Map<_ListTileSlot, Element> slotToChild = <_ListTileSlot, Element>{};

  @override
  _MongolListTile get widget => super.widget as _MongolListTile;

  @override
  _MongolRenderListTile get renderObject =>
      super.renderObject as _MongolRenderListTile;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.containsValue(child));
    assert(child.slot is _ListTileSlot);
    assert(slotToChild.containsKey(child.slot));
    slotToChild.remove(child.slot);
    super.forgetChild(child);
  }

  void _mountChild(Widget? widget, _ListTileSlot slot) {
    final Element? oldChild = slotToChild[slot];
    final Element? newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.leading, _ListTileSlot.leading);
    _mountChild(widget.title, _ListTileSlot.title);
    _mountChild(widget.subtitle, _ListTileSlot.subtitle);
    _mountChild(widget.trailing, _ListTileSlot.trailing);
  }

  void _updateChild(Widget? widget, _ListTileSlot slot) {
    final Element? oldChild = slotToChild[slot];
    final Element? newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void update(_MongolListTile newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.leading, _ListTileSlot.leading);
    _updateChild(widget.title, _ListTileSlot.title);
    _updateChild(widget.subtitle, _ListTileSlot.subtitle);
    _updateChild(widget.trailing, _ListTileSlot.trailing);
  }

  void _updateRenderObject(RenderBox? child, _ListTileSlot slot) {
    switch (slot) {
      case _ListTileSlot.leading:
        renderObject.leading = child;
        break;
      case _ListTileSlot.title:
        renderObject.title = child;
        break;
      case _ListTileSlot.subtitle:
        renderObject.subtitle = child;
        break;
      case _ListTileSlot.trailing:
        renderObject.trailing = child;
        break;
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, _ListTileSlot slot) {
    assert(child is RenderBox);
    _updateRenderObject(child as RenderBox, slot);
    assert(renderObject.children.keys.contains(slot));
  }

  @override
  void removeRenderObjectChild(RenderObject child, _ListTileSlot slot) {
    assert(child is RenderBox);
    assert(renderObject.children[slot] == child);
    _updateRenderObject(null, slot);
    assert(!renderObject.children.keys.contains(slot));
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false, 'not reachable');
  }
}

class _MongolRenderListTile extends RenderBox {
  _MongolRenderListTile({
    required bool isDense,
    required VisualDensity visualDensity,
    required bool isThreeLine,
    required TextBaseline titleBaselineType,
    TextBaseline? subtitleBaselineType,
    required double verticalTitleGap,
    required double minHorizontalPadding,
    required double minLeadingHeight,
  })  : _isDense = isDense,
        _visualDensity = visualDensity,
        _isThreeLine = isThreeLine,
        _titleBaselineType = titleBaselineType,
        _subtitleBaselineType = subtitleBaselineType,
        _verticalTitleGap = verticalTitleGap,
        _minHorizontalPadding = minHorizontalPadding,
        _minLeadingHeight = minLeadingHeight;

  final Map<_ListTileSlot, RenderBox> children = <_ListTileSlot, RenderBox>{};

  RenderBox? _updateChild(
      RenderBox? oldChild, RenderBox? newChild, _ListTileSlot slot) {
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

  RenderBox? _leading;
  RenderBox? get leading => _leading;
  set leading(RenderBox? value) {
    _leading = _updateChild(_leading, value, _ListTileSlot.leading);
  }

  RenderBox? _title;
  RenderBox? get title => _title;
  set title(RenderBox? value) {
    _title = _updateChild(_title, value, _ListTileSlot.title);
  }

  RenderBox? _subtitle;
  RenderBox? get subtitle => _subtitle;
  set subtitle(RenderBox? value) {
    _subtitle = _updateChild(_subtitle, value, _ListTileSlot.subtitle);
  }

  RenderBox? _trailing;
  RenderBox? get trailing => _trailing;
  set trailing(RenderBox? value) {
    _trailing = _updateChild(_trailing, value, _ListTileSlot.trailing);
  }

  // The returned list is ordered for hit testing.
  Iterable<RenderBox> get _children sync* {
    if (leading != null) yield leading!;
    if (title != null) yield title!;
    if (subtitle != null) yield subtitle!;
    if (trailing != null) yield trailing!;
  }

  bool get isDense => _isDense;
  bool _isDense;
  set isDense(bool value) {
    if (_isDense == value) return;
    _isDense = value;
    markNeedsLayout();
  }

  VisualDensity get visualDensity => _visualDensity;
  VisualDensity _visualDensity;
  set visualDensity(VisualDensity value) {
    if (_visualDensity == value) return;
    _visualDensity = value;
    markNeedsLayout();
  }

  bool get isThreeLine => _isThreeLine;
  bool _isThreeLine;
  set isThreeLine(bool value) {
    if (_isThreeLine == value) return;
    _isThreeLine = value;
    markNeedsLayout();
  }

  TextBaseline get titleBaselineType => _titleBaselineType;
  TextBaseline _titleBaselineType;
  set titleBaselineType(TextBaseline value) {
    if (_titleBaselineType == value) return;
    _titleBaselineType = value;
    markNeedsLayout();
  }

  TextBaseline? get subtitleBaselineType => _subtitleBaselineType;
  TextBaseline? _subtitleBaselineType;
  set subtitleBaselineType(TextBaseline? value) {
    if (_subtitleBaselineType == value) return;
    _subtitleBaselineType = value;
    markNeedsLayout();
  }

  double get verticalTitleGap => _verticalTitleGap;
  double _verticalTitleGap;
  double get _effectiveVerticalTitleGap =>
      _verticalTitleGap + visualDensity.vertical * 2.0;

  set verticalTitleGap(double value) {
    if (_verticalTitleGap == value) return;
    _verticalTitleGap = value;
    markNeedsLayout();
  }

  double get minHorizontalPadding => _minHorizontalPadding;
  double _minHorizontalPadding;

  set minHorizontalPadding(double value) {
    if (_minHorizontalPadding == value) return;
    _minHorizontalPadding = value;
    markNeedsLayout();
  }

  double get minLeadingHeight => _minLeadingHeight;
  double _minLeadingHeight;

  set minLeadingHeight(double value) {
    if (_minLeadingHeight == value) return;
    _minLeadingHeight = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final RenderBox child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final RenderBox child in _children) {
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
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    void add(RenderBox? child, String name) {
      if (child != null) value.add(child.toDiagnosticsNode(name: name));
    }

    add(leading, 'leading');
    add(title, 'title');
    add(subtitle, 'subtitle');
    add(trailing, 'trailing');
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

  @override
  double computeMinIntrinsicHeight(double width) {
    final double leadingHeight = leading != null
        ? math.max(leading!.getMinIntrinsicHeight(width), _minLeadingHeight) +
            _effectiveVerticalTitleGap
        : 0.0;
    return leadingHeight +
        math.max(_minHeight(title, width), _minHeight(subtitle, width)) +
        _maxHeight(trailing, width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double leadingHeight = leading != null
        ? math.max(leading!.getMaxIntrinsicHeight(width), _minLeadingHeight) +
            _effectiveVerticalTitleGap
        : 0.0;
    return leadingHeight +
        math.max(_maxHeight(title, width), _maxHeight(subtitle, width)) +
        _maxHeight(trailing, width);
  }

  double get _defaultTileWidth {
    final bool hasSubtitle = subtitle != null;
    final bool isTwoLine = !isThreeLine && hasSubtitle;
    final bool isOneLine = !isThreeLine && !hasSubtitle;

    final Offset baseDensity = visualDensity.baseSizeAdjustment;
    if (isOneLine) return (isDense ? 48.0 : 56.0) + baseDensity.dx;
    if (isTwoLine) return (isDense ? 64.0 : 72.0) + baseDensity.dx;
    return (isDense ? 76.0 : 88.0) + baseDensity.dx;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return math.max(
      _defaultTileWidth,
      title!.getMinIntrinsicWidth(height) +
          (subtitle?.getMinIntrinsicWidth(height) ?? 0.0),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return computeMinIntrinsicWidth(height);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return 0.0;
  }

  static double? _boxBaseline(RenderBox box, TextBaseline baseline) {
    return box.getDistanceToBaseline(baseline);
  }

  static Size _layoutBox(RenderBox? box, BoxConstraints constraints) {
    if (box == null) return Size.zero;
    box.layout(constraints, parentUsesSize: true);
    return box.size;
  }

  static void _positionBox(RenderBox box, Offset offset) {
    final BoxParentData parentData = box.parentData! as BoxParentData;
    parentData.offset = offset;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
      reason:
          'Layout requires baseline metrics, which are only available after a full layout.',
    ));
    return Size.zero;
  }

  // All of the dimensions below were taken from the Material Design spec:
  // https://material.io/design/components/lists.html#specs
  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final bool hasLeading = leading != null;
    final bool hasSubtitle = subtitle != null;
    final bool hasTrailing = trailing != null;
    final bool isTwoLine = !isThreeLine && hasSubtitle;
    final bool isOneLine = !isThreeLine && !hasSubtitle;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;

    final BoxConstraints maxIconWidthConstraint = BoxConstraints(
      // One-line trailing and leading widget widths do not follow
      // Material specifications, but this sizing is required to adhere
      // to accessibility requirements for smallest tappable widget.
      // Two- and three-line trailing widget widths are constrained
      // properly according to the Material spec.
      maxWidth: (isDense ? 48.0 : 56.0) + densityAdjustment.dx,
    );
    final BoxConstraints looseConstraints = constraints.loosen();
    final BoxConstraints iconConstraints =
        looseConstraints.enforce(maxIconWidthConstraint);

    final double tileHeight = looseConstraints.maxHeight;
    final Size leadingSize = _layoutBox(leading, iconConstraints);
    final Size trailingSize = _layoutBox(trailing, iconConstraints);
    assert(
      tileHeight != leadingSize.height || tileHeight == 0.0,
      'Leading widget consumes entire tile height. Please use a sized widget, '
      'or consider replacing MongolListTile with a custom widget '
      '(see https://api.flutter.dev/flutter/material/ListTile-class.html#material.ListTile.4)',
    );
    assert(
      tileHeight != trailingSize.height || tileHeight == 0.0,
      'Trailing widget consumes entire tile height. Please use a sized widget, '
      'or consider replacing MongolListTile with a custom widget '
      '(see https://api.flutter.dev/flutter/material/ListTile-class.html#material.ListTile.4)',
    );

    final double titleStart = hasLeading
        ? math.max(_minLeadingHeight, leadingSize.height) +
            _effectiveVerticalTitleGap
        : 0.0;
    final double adjustedLeadingHeight = hasLeading
        ? math.max(leadingSize.height + _effectiveVerticalTitleGap, 32.0)
        : 0.0;
    final double adjustedTrailingHeight =
        hasTrailing ? math.max(trailingSize.height, 32.0) : 0.0;
    final BoxConstraints textConstraints = looseConstraints.tighten(
      height: tileHeight - titleStart - adjustedTrailingHeight,
    );
    final Size titleSize = _layoutBox(title, textConstraints);
    final Size subtitleSize = _layoutBox(subtitle, textConstraints);

    double? titleBaseline;
    double? subtitleBaseline;
    if (isTwoLine) {
      titleBaseline = isDense ? 28.0 : 32.0;
      subtitleBaseline = isDense ? 48.0 : 52.0;
    } else if (isThreeLine) {
      titleBaseline = isDense ? 22.0 : 28.0;
      subtitleBaseline = isDense ? 42.0 : 48.0;
    } else {
      assert(isOneLine);
    }

    final double defaultTileWidth = _defaultTileWidth;

    double tileWidth;
    double titleX;
    double? subtitleX;
    if (!hasSubtitle) {
      tileWidth = math.max(
          defaultTileWidth, titleSize.width + 2.0 * _minHorizontalPadding);
      titleX = (tileWidth - titleSize.width) / 2.0;
    } else {
      assert(subtitleBaselineType != null);
      titleX = titleBaseline! - _boxBaseline(title!, titleBaselineType)!;
      subtitleX = subtitleBaseline! -
          _boxBaseline(subtitle!, subtitleBaselineType!)! +
          visualDensity.horizontal * 2.0;
      tileWidth = defaultTileWidth;

      // If the title and subtitle overlap, move the title left by half
      // the overlap and the subtitle right by the same amount, and adjust
      // tileWidth so that both titles fit.
      final double titleOverlap = titleX + titleSize.width - subtitleX;
      if (titleOverlap > 0.0) {
        titleX -= titleOverlap / 2.0;
        subtitleX += titleOverlap / 2.0;
      }

      // If the title or subtitle overflow tileWidth then punt: title
      // and subtitle are arranged in a column, tileWidth = row width plus
      // _minHorizontalPadding on the left and right.
      if (titleX < _minHorizontalPadding ||
          (subtitleX + subtitleSize.width + _minHorizontalPadding) >
              tileWidth) {
        tileWidth =
            titleSize.width + subtitleSize.width + 2.0 * _minHorizontalPadding;
        titleX = _minHorizontalPadding;
        subtitleX = titleSize.width + _minHorizontalPadding;
      }
    }

    // This attempts to implement the redlines for the horizontal position of the
    // leading and trailing icons on the spec page:
    //   https://material.io/design/components/lists.html#specs
    // The interpretation for these redlines is as follows:
    //  - For large tiles (> 72dp), both leading and trailing controls should be
    //    a fixed distance from the left. As per guidelines this is set to 16dp.
    //  - For smaller tiles, trailing should always be centered. Leading can be
    //    centered or closer to the left. It should never be further than 16dp
    //    to the left.
    final double leadingX;
    final double trailingX;
    if (tileWidth > 72.0) {
      leadingX = 16.0;
      trailingX = 16.0;
    } else {
      leadingX = math.min((tileWidth - leadingSize.width) / 2.0, 16.0);
      trailingX = (tileWidth - trailingSize.width) / 2.0;
    }

    if (hasLeading) {
      _positionBox(leading!, Offset(leadingX, 0.0));
    }
    _positionBox(title!, Offset(titleX, adjustedLeadingHeight));
    if (hasSubtitle) {
      _positionBox(subtitle!, Offset(subtitleX!, adjustedLeadingHeight));
    }
    if (hasTrailing) {
      _positionBox(
          trailing!, Offset(trailingX, tileHeight - trailingSize.height));
    }

    size = constraints.constrain(Size(tileWidth, tileHeight));
    assert(size.width == constraints.constrainWidth(tileWidth));
    assert(size.height == constraints.constrainHeight(tileHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox? child) {
      if (child != null) {
        final BoxParentData parentData = child.parentData! as BoxParentData;
        context.paintChild(child, parentData.offset + offset);
      }
    }

    doPaint(leading);
    doPaint(title);
    doPaint(subtitle);
    doPaint(trailing);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox child in _children) {
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }
    return false;
  }
}
