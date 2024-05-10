// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        ColorScheme,
        Colors,
        Divider,
        IconButton,
        IconButtonTheme,
        IconButtonThemeData,
        Ink,
        InkWell,
        ListTileStyle,
        MaterialState,
        MaterialStateColor,
        MaterialStateMouseCursor,
        MaterialStateProperty,
        TextTheme,
        Theme,
        ThemeData,
        VisualDensity,
        debugCheckHasMaterial,
        kThemeChangeDuration;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// Used with [MongolListTileTheme] to define default property values for
/// descendant [MongolListTile] widgets.
///
/// todo material3 as well as classes that build
/// todo material3 [MongolListTile]s, like [MongolCheckboxListTile], [MongolRadioListTile], and
/// todo material3 [MongolSwitchListTile].
///
/// Descendant widgets obtain the current [MongolListTileThemeData] object
/// using `MongolListTileTheme.of(context)`. Instances of
/// [MongolListTileThemeData] can be customized with
/// [MongolListTileThemeData.copyWith].
///
/// A [MongolListTileThemeData] is not specified as part of the
/// overall [Theme] with [ThemeData.listTileTheme] like Flutter's [ListTileThemeData].
/// Instead, [MongolListTileThemeData] is specified in the [MongolListTileTheme.data]
/// and MongolListTileTheme place to the top of the widget tree to specify the
/// theme for a subtree. See example code below.
/// ```dart
/// return MaterialApp(
///   title: 'mongol',
///   home: MongolListTileTheme(
///     data: MongolListTileThemeData(
///       minHorizontalPadding: 20,
///     ),
///     child: Scaffold(
///       appBar: AppBar(title: const Text(versionTitle)),
///       body: const HomeScreen(),
///     ),
///   )
/// );
///```
///
/// All [MongolListTileThemeData] properties are `null` by default.
/// When a theme property is null, the [MongolListTile] will provide its own
/// default based on the overall [Theme]'s textTheme and
/// colorScheme. See the individual [MongolListTile] properties for details.
///
/// The [Drawer] widget specifies a list tile theme for its children that
/// defines [style] to be [ListTileStyle.drawer].
@immutable
class MongolListTileThemeData with Diagnosticable {
  /// Creates a [MongolListTileThemeData].
  const MongolListTileThemeData({
    this.dense,
    this.shape,
    this.style,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.contentPadding,
    this.tileColor,
    this.selectedTileColor,
    this.verticalTitleGap,
    this.minHorizontalPadding,
    this.minLeadingHeight,
    this.enableFeedback,
    this.mouseCursor,
    this.visualDensity,
    this.titleAlignment,
  });

  /// Overrides the default value of [MongolListTile.dense].
  final bool? dense;

  /// Overrides the default value of [MongolListTile.shape].
  final ShapeBorder? shape;

  /// Overrides the default value of [MongolListTile.style].
  final ListTileStyle? style;

  /// Overrides the default value of [MongolListTile.selectedColor].
  final Color? selectedColor;

  /// Overrides the default value of [MongolListTile.iconColor].
  final Color? iconColor;

  /// Overrides the default value of [MongolListTile.textColor].
  final Color? textColor;

  /// Overrides the default value of [MongolListTile.titleTextStyle].
  final TextStyle? titleTextStyle;

  /// Overrides the default value of [MongolListTile.subtitleTextStyle].
  final TextStyle? subtitleTextStyle;

  /// Overrides the default value of [MongolListTile.leadingAndTrailingTextStyle].
  final TextStyle? leadingAndTrailingTextStyle;

  /// Overrides the default value of [MongolListTile.contentPadding].
  final EdgeInsetsGeometry? contentPadding;

  /// Overrides the default value of [MongolListTile.tileColor].
  final Color? tileColor;

  /// Overrides the default value of [MongolListTile.selectedTileColor].
  final Color? selectedTileColor;

  /// Overrides the default value of [MongolListTile.verticalTitleGap].
  final double? verticalTitleGap;

  /// Overrides the default value of [MongolListTile.minHorizontalPadding].
  final double? minHorizontalPadding;

  /// Overrides the default value of [MongolListTile.minLeadingHeight].
  final double? minLeadingHeight;

  /// Overrides the default value of [MongolListTile.enableFeedback].
  final bool? enableFeedback;

  /// If specified, overrides the default value of [MongolListTile.mouseCursor].
  final MaterialStateProperty<MouseCursor?>? mouseCursor;

  /// If specified, overrides the default value of [MongolListTile.visualDensity].
  final VisualDensity? visualDensity;

  /// If specified, overrides the default value of [MongolListTile.titleAlignment].
  final MongolListTileTitleAlignment? titleAlignment;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  MongolListTileThemeData copyWith({
    bool? dense,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? leadingAndTrailingTextStyle,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    double? verticalTitleGap,
    double? minHorizontalPadding,
    double? minLeadingHeight,
    bool? enableFeedback,
    MaterialStateProperty<MouseCursor?>? mouseCursor,
    bool? isThreeLine,
    VisualDensity? visualDensity,
    MongolListTileTitleAlignment? titleAlignment,
  }) {
    return MongolListTileThemeData(
      dense: dense ?? this.dense,
      shape: shape ?? this.shape,
      style: style ?? this.style,
      selectedColor: selectedColor ?? this.selectedColor,
      iconColor: iconColor ?? this.iconColor,
      textColor: textColor ?? this.textColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
      leadingAndTrailingTextStyle:
          leadingAndTrailingTextStyle ?? this.leadingAndTrailingTextStyle,
      contentPadding: contentPadding ?? this.contentPadding,
      tileColor: tileColor ?? this.tileColor,
      selectedTileColor: selectedTileColor ?? this.selectedTileColor,
      verticalTitleGap: verticalTitleGap ?? this.verticalTitleGap,
      minHorizontalPadding: minHorizontalPadding ?? this.minHorizontalPadding,
      minLeadingHeight: minLeadingHeight ?? this.minLeadingHeight,
      enableFeedback: enableFeedback ?? this.enableFeedback,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      visualDensity: visualDensity ?? this.visualDensity,
      titleAlignment: titleAlignment ?? this.titleAlignment,
    );
  }

  /// Linearly interpolate between MongolListTileThemeData objects.
  static MongolListTileThemeData? lerp(
      MongolListTileThemeData? a, MongolListTileThemeData? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return MongolListTileThemeData(
      dense: t < 0.5 ? a?.dense : b?.dense,
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      style: t < 0.5 ? a?.style : b?.style,
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      textColor: Color.lerp(a?.textColor, b?.textColor, t),
      titleTextStyle: TextStyle.lerp(a?.titleTextStyle, b?.titleTextStyle, t),
      subtitleTextStyle:
          TextStyle.lerp(a?.subtitleTextStyle, b?.subtitleTextStyle, t),
      leadingAndTrailingTextStyle: TextStyle.lerp(
          a?.leadingAndTrailingTextStyle, b?.leadingAndTrailingTextStyle, t),
      contentPadding:
          EdgeInsetsGeometry.lerp(a?.contentPadding, b?.contentPadding, t),
      tileColor: Color.lerp(a?.tileColor, b?.tileColor, t),
      selectedTileColor:
          Color.lerp(a?.selectedTileColor, b?.selectedTileColor, t),
      verticalTitleGap: lerpDouble(a?.verticalTitleGap, b?.verticalTitleGap, t),
      minHorizontalPadding:
          lerpDouble(a?.minHorizontalPadding, b?.minHorizontalPadding, t),
      minLeadingHeight: lerpDouble(a?.minLeadingHeight, b?.minLeadingHeight, t),
      enableFeedback: t < 0.5 ? a?.enableFeedback : b?.enableFeedback,
      mouseCursor: t < 0.5 ? a?.mouseCursor : b?.mouseCursor,
      visualDensity: t < 0.5 ? a?.visualDensity : b?.visualDensity,
      titleAlignment: t < 0.5 ? a?.titleAlignment : b?.titleAlignment,
    );
  }

  @override
  int get hashCode => Object.hash(
        dense,
        shape,
        style,
        selectedColor,
        iconColor,
        textColor,
        titleTextStyle,
        subtitleTextStyle,
        leadingAndTrailingTextStyle,
        contentPadding,
        tileColor,
        selectedTileColor,
        verticalTitleGap,
        minHorizontalPadding,
        minLeadingHeight,
        enableFeedback,
        mouseCursor,
        visualDensity,
        titleAlignment,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MongolListTileThemeData &&
        other.dense == dense &&
        other.shape == shape &&
        other.style == style &&
        other.selectedColor == selectedColor &&
        other.iconColor == iconColor &&
        other.titleTextStyle == titleTextStyle &&
        other.subtitleTextStyle == subtitleTextStyle &&
        other.leadingAndTrailingTextStyle == leadingAndTrailingTextStyle &&
        other.textColor == textColor &&
        other.contentPadding == contentPadding &&
        other.tileColor == tileColor &&
        other.selectedTileColor == selectedTileColor &&
        other.verticalTitleGap == verticalTitleGap &&
        other.minHorizontalPadding == minHorizontalPadding &&
        other.minLeadingHeight == minLeadingHeight &&
        other.enableFeedback == enableFeedback &&
        other.mouseCursor == mouseCursor &&
        other.visualDensity == visualDensity &&
        other.titleAlignment == titleAlignment;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<bool>('dense', dense, defaultValue: null));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties
        .add(EnumProperty<ListTileStyle>('style', style, defaultValue: null));
    properties
        .add(ColorProperty('selectedColor', selectedColor, defaultValue: null));
    properties.add(ColorProperty('iconColor', iconColor, defaultValue: null));
    properties.add(ColorProperty('textColor', textColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'titleTextStyle', titleTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'subtitleTextStyle', subtitleTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'leadingAndTrailingTextStyle', leadingAndTrailingTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>(
        'contentPadding', contentPadding,
        defaultValue: null));
    properties.add(ColorProperty('tileColor', tileColor, defaultValue: null));
    properties.add(ColorProperty('selectedTileColor', selectedTileColor,
        defaultValue: null));
    properties.add(DoubleProperty('verticalTitleGap', verticalTitleGap,
        defaultValue: null));
    properties.add(DoubleProperty('minHorizontalPadding', minHorizontalPadding,
        defaultValue: null));
    properties.add(DoubleProperty('minLeadingHeight', minLeadingHeight,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('enableFeedback', enableFeedback,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<MouseCursor?>>(
        'mouseCursor', mouseCursor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<VisualDensity>(
        'visualDensity', visualDensity,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MongolListTileTitleAlignment>(
        'titleAlignment', titleAlignment,
        defaultValue: null));
  }
}

/// An inherited widget that defines color and style parameters for [MongolListTile]s
/// in this widget's subtree.
///
/// Values specified here are used for [MongolListTile] properties that are not given
/// an explicit non-null value.
///
/// The [MongolDrawer] widget specifies a tile theme for its children which sets
/// [style] to [ListTileStyle.drawer].
class MongolListTileTheme extends InheritedTheme {
  /// Creates a list tile theme that defines the color and style parameters for
  /// descendant [MongolListTile]s.
  ///
  /// Only the [data] parameter should be used. The other parameters are
  /// redundant (are now obsolete) and will be deprecated in a future update.
  const MongolListTileTheme({
    Key? key,
    MongolListTileThemeData? data,
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
    MaterialStateProperty<MouseCursor?>? mouseCursor,
    double? verticalTitleGap,
    double? minHorizontalPadding,
    double? minLeadingHeight,
    required super.child,
  })  : assert(data == null ||
            (shape ??
                    selectedColor ??
                    iconColor ??
                    textColor ??
                    contentPadding ??
                    tileColor ??
                    selectedTileColor ??
                    enableFeedback ??
                    mouseCursor ??
                    verticalTitleGap ??
                    minHorizontalPadding ??
                    minLeadingHeight) ==
                null),
        _data = data,
        _dense = dense,
        _shape = shape,
        _style = style,
        _selectedColor = selectedColor,
        _iconColor = iconColor,
        _textColor = textColor,
        _contentPadding = contentPadding,
        _tileColor = tileColor,
        _selectedTileColor = selectedTileColor,
        _enableFeedback = enableFeedback,
        _mouseCursor = mouseCursor,
        _verticalTitleGap = verticalTitleGap,
        _minHorizontalPadding = minHorizontalPadding,
        _minLeadingHeight = minLeadingHeight;

  final MongolListTileThemeData? _data;
  final bool? _dense;
  final ShapeBorder? _shape;
  final ListTileStyle? _style;
  final Color? _selectedColor;
  final Color? _iconColor;
  final Color? _textColor;
  final EdgeInsetsGeometry? _contentPadding;
  final Color? _tileColor;
  final Color? _selectedTileColor;
  final double? _verticalTitleGap;
  final double? _minHorizontalPadding;
  final double? _minLeadingHeight;
  final bool? _enableFeedback;
  final MaterialStateProperty<MouseCursor?>? _mouseCursor;

  /// The configuration of this theme.
  MongolListTileThemeData get data {
    return _data ??
        MongolListTileThemeData(
          dense: _dense,
          shape: _shape,
          style: _style,
          selectedColor: _selectedColor,
          iconColor: _iconColor,
          textColor: _textColor,
          contentPadding: _contentPadding,
          tileColor: _tileColor,
          selectedTileColor: _selectedTileColor,
          enableFeedback: _enableFeedback,
          mouseCursor: _mouseCursor,
          verticalTitleGap: _verticalTitleGap,
          minHorizontalPadding: _minHorizontalPadding,
          minLeadingHeight: _minLeadingHeight,
        );
  }

  /// Overrides the default value of [MongolListTile.dense].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.dense] property instead.
  bool? get dense => _data != null ? _data?.dense : _dense;

  /// Overrides the default value of [ListTile.shape].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.shape] property instead.
  ShapeBorder? get shape => _data != null ? _data?.shape : _shape;

  /// Overrides the default value of [ListTile.style].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.style] property instead.
  ListTileStyle? get style => _data != null ? _data?.style : _style;

  /// Overrides the default value of [MongolListTile.selectedColor].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.selectedColor] property instead.
  Color? get selectedColor =>
      _data != null ? _data?.selectedColor : _selectedColor;

  /// Overrides the default value of [MongolListTile.iconColor].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.iconColor] property instead.
  Color? get iconColor => _data != null ? _data?.iconColor : _iconColor;

  /// Overrides the default value of [MongolListTile.textColor].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.textColor] property instead.
  Color? get textColor => _data != null ? _data?.textColor : _textColor;

  /// Overrides the default value of [MongolListTile.contentPadding].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.contentPadding] property instead.
  EdgeInsetsGeometry? get contentPadding =>
      _data != null ? _data?.contentPadding : _contentPadding;

  /// Overrides the default value of [MongolListTile.tileColor].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.tileColor] property instead.
  Color? get tileColor => _data != null ? _data?.tileColor : _tileColor;

  /// Overrides the default value of [MongolListTile.selectedTileColor].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.selectedTileColor] property instead.
  Color? get selectedTileColor =>
      _data != null ? _data?.selectedTileColor : _selectedTileColor;

  /// Overrides the default value of [MongolListTile.verticalTitleGap].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.verticalTitleGap] property instead.
  double? get verticalTitleGap =>
      _data != null ? _data?.verticalTitleGap : _verticalTitleGap;

  /// Overrides the default value of [MongolListTile.minHorizontalPadding].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.minHorizontalPadding] property instead.
  double? get minHorizontalPadding =>
      _data != null ? _data?.minHorizontalPadding : _minHorizontalPadding;

  /// Overrides the default value of [MongolListTile.minLeadingHeight].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.minLeadingHeight] property instead.
  double? get minLeadingHeight =>
      _data != null ? _data?.minLeadingHeight : _minLeadingHeight;

  /// Overrides the default value of [MongolListTile.enableFeedback].
  ///
  /// This property is obsolete: please use the [data]
  /// [MongolListTileThemeData.enableFeedback] property instead.
  bool? get enableFeedback =>
      _data != null ? _data?.enableFeedback : _enableFeedback;

  /// The [data] property of the closest instance of this class that
  /// encloses the given context.
  ///
  /// If there is no enclosing [MongolListTileTheme] widget, then
  /// const MongolListTileThemeData().
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MongolListTileThemeData theme = MongolListTileTheme.of(context);
  /// ```
  static MongolListTileThemeData of(BuildContext context) {
    final MongolListTileTheme? result =
        context.dependOnInheritedWidgetOfExactType<MongolListTileTheme>();
    return result?.data ?? const MongolListTileThemeData();
  }

  /// Creates a list tile theme that controls the color and style parameters for
  /// [ListTile]s, and merges in the current list tile theme, if any.
  static Widget merge({
    Key? key,
    bool? dense,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? leadingAndTrailingTextStyle,
    EdgeInsetsGeometry? contentPadding,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    double? verticalTitleGap,
    double? minHorizontalPadding,
    double? minLeadingHeight,
    MongolListTileTitleAlignment? titleAlignment,
    MaterialStateProperty<MouseCursor?>? mouseCursor,
    VisualDensity? visualDensity,
    required Widget child,
  }) {
    return Builder(
      builder: (BuildContext context) {
        final MongolListTileThemeData parent = MongolListTileTheme.of(context);
        return MongolListTileTheme(
          key: key,
          data: MongolListTileThemeData(
            dense: dense ?? parent.dense,
            shape: shape ?? parent.shape,
            style: style ?? parent.style,
            selectedColor: selectedColor ?? parent.selectedColor,
            iconColor: iconColor ?? parent.iconColor,
            textColor: textColor ?? parent.textColor,
            titleTextStyle: titleTextStyle ?? parent.titleTextStyle,
            subtitleTextStyle: subtitleTextStyle ?? parent.subtitleTextStyle,
            leadingAndTrailingTextStyle: leadingAndTrailingTextStyle ??
                parent.leadingAndTrailingTextStyle,
            contentPadding: contentPadding ?? parent.contentPadding,
            tileColor: tileColor ?? parent.tileColor,
            selectedTileColor: selectedTileColor ?? parent.selectedTileColor,
            enableFeedback: enableFeedback ?? parent.enableFeedback,
            verticalTitleGap: verticalTitleGap ?? parent.verticalTitleGap,
            minHorizontalPadding:
                minHorizontalPadding ?? parent.minHorizontalPadding,
            minLeadingHeight: minLeadingHeight ?? parent.minLeadingHeight,
            titleAlignment: titleAlignment ?? parent.titleAlignment,
            mouseCursor: mouseCursor ?? parent.mouseCursor,
            visualDensity: visualDensity ?? parent.visualDensity,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MongolListTileTheme(
      data: MongolListTileThemeData(
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
      ),
      child: child,
    );
  }

  @override
  bool updateShouldNotify(MongolListTileTheme oldWidget) =>
      data != oldWidget.data;
}

/// Defines how [MongolListTile.leading] and [MongolListTile.trailing] are
/// horizontal aligned relative to the [MongolListTile]'s titles
/// ([MongolListTile.title] and [MongolListTile.subtitle]).
///
/// See also:
///
///  * [MongolListTile.titleAlignment], to configure the title alignment for an
///    individual [MongolListTile].
enum MongolListTileTitleAlignment {
  /// The left of the [MongolListTile.leading] and [MongolListTile.trailing] widgets are
  /// placed [MongolListTile.minHorizontalPadding] right the left of the [MongolListTile.title]
  /// if [MongolListTile.isThreeLine] is true, otherwise they're centered relative
  /// to the [MongolListTile.title] and [MongolListTile.subtitle] widgets.
  ///
  /// This is the default when [ThemeData.useMaterial3] is true.
  threeLine,

  /// The lefts of the [MongolListTile.leading] and [MongolListTile.trailing] widgets are
  /// placed 16 units right the left of the [MongolListTile.title]
  /// if the titles' overall width is greater than 72, otherwise they're
  /// centered relative to the [MongolListTile.title] and [MongolListTile.subtitle] widgets.
  ///
  /// This is the default when [ThemeData.useMaterial3] is false.
  titleWidth,

  /// The left of the [MongolListTile.leading] and [MongolListTile.trailing] widgets are
  /// placed [MongolListTile.minHorizontalPadding] right the left of the [MongolListTile.title].
  left,

  /// The [MongolListTile.leading] and [MongolListTile.trailing] widgets are
  /// centered relative to the [MongolListTile]'s titles.
  center,

  /// The right of the [MongolListTile.leading] and [MongolListTile.trailing] widgets are
  /// placed [MongolListTile.minHorizontalPadding] left the right of the [MongolListTile]'s
  /// titles.
  right,
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
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.visualDensity,
    this.shape,
    this.style,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.mouseCursor,
    this.selected = false,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.focusNode,
    this.autofocus = false,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.verticalTitleGap,
    this.minHorizontalPadding,
    this.minLeadingHeight,
    this.titleAlignment,
  }) : assert(!isThreeLine || subtitle != null);

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

  /// Defines the color used for icons and text when the list tile is selected.
  ///
  /// If this property is null then [ListTileThemeData.selectedColor]
  /// is used. If that is also null then [ColorScheme.primary] is used.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final Color? selectedColor;

  /// Defines the default color for [leading] and [trailing] icons.
  ///
  /// If this property is null and [selected] is false then [ListTileThemeData.iconColor]
  /// is used. If that is also null and [ThemeData.useMaterial3] is true, [ColorScheme.onSurfaceVariant]
  /// is used, otherwise if [ThemeData.brightness] is [Brightness.light], [Colors.black54] is used,
  /// and if [ThemeData.brightness] is [Brightness.dark], the value is null.
  ///
  /// If this property is null and [selected] is true then [ListTileThemeData.selectedColor]
  /// is used. If that is also null then [ColorScheme.primary] is used.
  ///
  /// If this color is a [MaterialStateColor] it will be resolved against
  /// [MaterialState.selected] and [MaterialState.disabled] states.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final Color? iconColor;

  /// Defines the text color for the [title], [subtitle], [leading], and [trailing].
  ///
  /// If this property is null and [selected] is false then [ListTileThemeData.textColor]
  /// is used. If that is also null then default text color is used for the [title], [subtitle]
  /// [leading], and [trailing]. Except for [subtitle], if [ThemeData.useMaterial3] is false,
  /// [TextTheme.bodySmall] is used.
  ///
  /// If this property is null and [selected] is true then [ListTileThemeData.selectedColor]
  /// is used. If that is also null then [ColorScheme.primary] is used.
  ///
  /// If this color is a [MaterialStateColor] it will be resolved against
  /// [MaterialState.selected] and [MaterialState.disabled] states.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final Color? textColor;

  /// The text style for ListTile's [title].
  ///
  /// If this property is null, then [ListTileThemeData.titleTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.bodyLarge]
  /// with [ColorScheme.onSurface] will be used. Otherwise, If ListTile style is
  /// [ListTileStyle.list], [TextTheme.titleMedium] will be used and if ListTile style
  /// is [ListTileStyle.drawer], [TextTheme.bodyLarge] will be used.
  final TextStyle? titleTextStyle;

  /// The text style for ListTile's [subtitle].
  ///
  /// If this property is null, then [ListTileThemeData.subtitleTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.bodyMedium]
  /// with [ColorScheme.onSurfaceVariant] will be used, otherwise [TextTheme.bodyMedium]
  /// with [TextTheme.bodySmall] color will be used.
  final TextStyle? subtitleTextStyle;

  /// The text style for ListTile's [leading] and [trailing].
  ///
  /// If this property is null, then [ListTileThemeData.leadingAndTrailingTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.labelSmall]
  /// with [ColorScheme.onSurfaceVariant] will be used, otherwise [TextTheme.bodyMedium]
  /// will be used.
  final TextStyle? leadingAndTrailingTextStyle;

  /// Defines the font used for the [title].
  ///
  /// If this property is null then [ListTileThemeData.style] is used. If that
  /// is also null then [ListTileStyle.list] is used.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final ListTileStyle? style;

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

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

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

  /// The color of splash for the tile's [Material].
  final Color? splashColor;

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

  /// Defines how [MongolListTile.leading] and [MongolListTile.trailing] are
  /// horizontal aligned relative to the [MongolListTile]'s titles
  /// ([MongolListTile.title] and [MongolListTile.subtitle]).
  ///
  /// If this property is null then [ListTileThemeData.titleAlignment]
  /// is used. If that is also null then [ListTileTitleAlignment.threeLine]
  /// is used.
  ///
  /// See also:
  ///
  /// * [ListTileTheme.of], which returns the nearest [ListTileTheme]'s
  ///   [ListTileThemeData].
  final MongolListTileTitleAlignment? titleAlignment;

  /// Add a one pixel border in between each tile. If color isn't specified the
  /// [ThemeData.dividerColor] of the context's [Theme] is used.
  ///
  /// See also:
  ///
  ///  * [VerticalDivider], which you can use to obtain this effect manually.
  /// todo material make it equal to ListTile.divideTiles
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

  bool _isDenseLayout(ThemeData theme, MongolListTileThemeData? tileTheme) {
    return dense ?? tileTheme?.dense ?? theme.listTileTheme.dense ?? false;
  }

  Color _tileBackgroundColor(ThemeData theme, MongolListTileThemeData tileTheme,
      MongolListTileThemeData defaults) {
    final Color? color = selected
        ? selectedTileColor ??
            tileTheme.selectedTileColor ??
            theme.listTileTheme.selectedTileColor
        : tileColor ?? tileTheme.tileColor ?? theme.listTileTheme.tileColor;
    return color ?? defaults.tileColor!;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    final MongolListTileThemeData tileTheme = MongolListTileTheme.of(context);
    final ListTileStyle listTileStyle = style ??
        tileTheme.style ??
        theme.listTileTheme.style ??
        ListTileStyle.list;
    final MongolListTileThemeData defaults = theme.useMaterial3
        ? _LisTileDefaultsM3(context)
        : _LisTileDefaultsM2(context, listTileStyle);
    final Set<MaterialState> states = <MaterialState>{
      if (!enabled) MaterialState.disabled,
      if (selected) MaterialState.selected,
    };

    Color? resolveColor(
        Color? explicitColor, Color? selectedColor, Color? enabledColor,
        [Color? disabledColor]) {
      return _IndividualOverrides(
        explicitColor: explicitColor,
        selectedColor: selectedColor,
        enabledColor: enabledColor,
        disabledColor: disabledColor,
      ).resolve(states);
    }

    final Color? effectiveIconColor =
        resolveColor(iconColor, selectedColor, iconColor) ??
            resolveColor(tileTheme.iconColor, tileTheme.selectedColor,
                tileTheme.iconColor) ??
            resolveColor(
                theme.listTileTheme.iconColor,
                theme.listTileTheme.selectedColor,
                theme.listTileTheme.iconColor) ??
            resolveColor(defaults.iconColor, defaults.selectedColor,
                defaults.iconColor, theme.disabledColor);
    final Color? effectiveColor =
        resolveColor(textColor, selectedColor, textColor) ??
            resolveColor(tileTheme.textColor, tileTheme.selectedColor,
                tileTheme.textColor) ??
            resolveColor(
                theme.listTileTheme.textColor,
                theme.listTileTheme.selectedColor,
                theme.listTileTheme.textColor) ??
            resolveColor(defaults.textColor, defaults.selectedColor,
                defaults.textColor, theme.disabledColor);
    final IconThemeData iconThemeData =
        IconThemeData(color: effectiveIconColor);
    final IconButtonThemeData iconButtonThemeData = IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: effectiveIconColor),
    );

    TextStyle? leadingAndTrailingStyle;
    if (leading != null || trailing != null) {
      leadingAndTrailingStyle = leadingAndTrailingTextStyle ??
          tileTheme.leadingAndTrailingTextStyle ??
          defaults.leadingAndTrailingTextStyle!;
      final Color? leadingAndTrailingTextColor = effectiveColor;
      leadingAndTrailingStyle =
          leadingAndTrailingStyle.copyWith(color: leadingAndTrailingTextColor);
    }

    Widget? leadingIcon;
    if (leading != null) {
      leadingIcon = AnimatedDefaultTextStyle(
        style: leadingAndTrailingStyle!,
        duration: kThemeChangeDuration,
        child: leading!,
      );
    }

    TextStyle titleStyle =
        titleTextStyle ?? tileTheme.titleTextStyle ?? defaults.titleTextStyle!;
    final Color? titleColor = effectiveColor;
    titleStyle = titleStyle.copyWith(
      color: titleColor,
      fontSize: _isDenseLayout(theme, tileTheme) ? 13.0 : null,
    );
    final Widget titleText = AnimatedDefaultTextStyle(
      style: titleStyle,
      duration: kThemeChangeDuration,
      child: title ?? const SizedBox(),
    );

    Widget? subtitleText;
    TextStyle? subtitleStyle;
    if (subtitle != null) {
      subtitleStyle = subtitleTextStyle ??
          tileTheme.subtitleTextStyle ??
          defaults.subtitleTextStyle!;
      final Color? subtitleColor = effectiveColor;
      subtitleStyle = subtitleStyle.copyWith(
        color: subtitleColor,
        fontSize: _isDenseLayout(theme, tileTheme) ? 12.0 : null,
      );
      subtitleText = AnimatedDefaultTextStyle(
        style: subtitleStyle,
        duration: kThemeChangeDuration,
        child: subtitle!,
      );
    }

    Widget? trailingIcon;
    if (trailing != null) {
      trailingIcon = AnimatedDefaultTextStyle(
        style: leadingAndTrailingStyle!,
        duration: kThemeChangeDuration,
        child: trailing!,
      );
    }

    const EdgeInsets defaultContentPadding =
        EdgeInsets.symmetric(vertical: 16.0);
    const TextDirection textDirection = TextDirection.ltr;
    final EdgeInsets resolvedContentPadding =
        contentPadding?.resolve(textDirection) ??
            tileTheme.contentPadding?.resolve(textDirection) ??
            defaultContentPadding;

    // Show basic cursor when MongolListTile isn't enabled or gesture callbacks are null.
    final Set<MaterialState> mouseStates = <MaterialState>{
      if (!enabled || (onTap == null && onLongPress == null))
        MaterialState.disabled,
    };
    final MouseCursor effectiveMouseCursor =
        MaterialStateProperty.resolveAs<MouseCursor?>(
                mouseCursor, mouseStates) ??
            tileTheme.mouseCursor?.resolve(mouseStates) ??
            MaterialStateMouseCursor.clickable.resolve(mouseStates);

    final MongolListTileTitleAlignment effectiveTitleAlignment =
        titleAlignment ??
            tileTheme.titleAlignment ??
            (theme.useMaterial3
                ? MongolListTileTitleAlignment.threeLine
                : MongolListTileTitleAlignment.titleWidth);

    return InkWell(
      customBorder: shape ?? tileTheme.shape,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      onFocusChange: onFocusChange,
      mouseCursor: effectiveMouseCursor,
      canRequestFocus: enabled,
      focusNode: focusNode,
      focusColor: focusColor,
      hoverColor: hoverColor,
      splashColor: splashColor,
      autofocus: autofocus,
      enableFeedback: enableFeedback ?? tileTheme.enableFeedback ?? true,
      child: Semantics(
        selected: selected,
        enabled: enabled,
        child: Ink(
          decoration: ShapeDecoration(
            shape: shape ?? tileTheme.shape ?? const Border(),
            color: _tileBackgroundColor(theme, tileTheme, defaults),
          ),
          child: SafeArea(
            left: false,
            right: false,
            minimum: resolvedContentPadding,
            child: IconTheme.merge(
              data: iconThemeData,
              child: IconButtonTheme(
                data: iconButtonThemeData,
                child: _MongolListTile(
                  leading: leadingIcon,
                  title: titleText,
                  subtitle: subtitleText,
                  trailing: trailingIcon,
                  isDense: _isDenseLayout(theme, tileTheme),
                  visualDensity: visualDensity ??
                      tileTheme.visualDensity ??
                      theme.visualDensity,
                  isThreeLine: isThreeLine,
                  titleBaselineType: titleStyle.textBaseline ??
                      defaults.titleTextStyle!.textBaseline!,
                  subtitleBaselineType: subtitleStyle?.textBaseline ??
                      defaults.subtitleTextStyle!.textBaseline!,
                  verticalTitleGap:
                      verticalTitleGap ?? tileTheme.verticalTitleGap ?? 16,
                  minHorizontalPadding: minHorizontalPadding ??
                      tileTheme.minHorizontalPadding ??
                      defaults.minHorizontalPadding!,
                  minLeadingHeight: minLeadingHeight ??
                      tileTheme.minLeadingHeight ??
                      defaults.minLeadingHeight!,
                  titleAlignment: effectiveTitleAlignment,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<Widget>('leading', leading, defaultValue: null));
    properties
        .add(DiagnosticsProperty<Widget>('title', title, defaultValue: null));
    properties.add(
        DiagnosticsProperty<Widget>('subtitle', subtitle, defaultValue: null));
    properties.add(
        DiagnosticsProperty<Widget>('trailing', trailing, defaultValue: null));
    properties.add(FlagProperty('isThreeLine',
        value: isThreeLine,
        ifTrue: 'THREE_LINE',
        ifFalse: 'TWO_LINE',
        showName: true,
        defaultValue: false));
    properties.add(FlagProperty('dense',
        value: dense, ifTrue: 'true', ifFalse: 'false', showName: true));
    properties.add(DiagnosticsProperty<VisualDensity>(
        'visualDensity', visualDensity,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(
        DiagnosticsProperty<ListTileStyle>('style', style, defaultValue: null));
    properties
        .add(ColorProperty('selectedColor', selectedColor, defaultValue: null));
    properties.add(ColorProperty('iconColor', iconColor, defaultValue: null));
    properties.add(ColorProperty('textColor', textColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'titleTextStyle', titleTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'subtitleTextStyle', subtitleTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'leadingAndTrailingTextStyle', leadingAndTrailingTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>(
        'contentPadding', contentPadding,
        defaultValue: null));
    properties.add(FlagProperty('enabled',
        value: enabled,
        ifTrue: 'true',
        ifFalse: 'false',
        showName: true,
        defaultValue: true));
    properties
        .add(DiagnosticsProperty<Function>('onTap', onTap, defaultValue: null));
    properties.add(DiagnosticsProperty<Function>('onLongPress', onLongPress,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MouseCursor>('mouseCursor', mouseCursor,
        defaultValue: null));
    properties.add(FlagProperty('selected',
        value: selected,
        ifTrue: 'true',
        ifFalse: 'false',
        showName: true,
        defaultValue: false));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: null));
    properties.add(ColorProperty('hoverColor', hoverColor, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode,
        defaultValue: null));
    properties.add(FlagProperty('autofocus',
        value: autofocus,
        ifTrue: 'true',
        ifFalse: 'false',
        showName: true,
        defaultValue: false));
    properties.add(ColorProperty('tileColor', tileColor, defaultValue: null));
    properties.add(ColorProperty('selectedTileColor', selectedTileColor,
        defaultValue: null));
    properties.add(FlagProperty('enableFeedback',
        value: enableFeedback,
        ifTrue: 'true',
        ifFalse: 'false',
        showName: true));
    properties.add(DoubleProperty('horizontalTitleGap', verticalTitleGap,
        defaultValue: null));
    properties.add(DoubleProperty('minVerticalPadding', minHorizontalPadding,
        defaultValue: null));
    properties.add(DoubleProperty('minLeadingWidth', minLeadingHeight,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MongolListTileTitleAlignment>(
        'titleAlignment', titleAlignment,
        defaultValue: null));
  }
}

class _IndividualOverrides extends MaterialStateProperty<Color?> {
  _IndividualOverrides({
    this.explicitColor,
    this.enabledColor,
    this.selectedColor,
    this.disabledColor,
  });

  final Color? explicitColor;
  final Color? enabledColor;
  final Color? selectedColor;
  final Color? disabledColor;

  @override
  Color? resolve(Set<MaterialState> states) {
    if (explicitColor is MaterialStateColor) {
      return MaterialStateProperty.resolveAs<Color?>(explicitColor, states);
    }
    if (states.contains(MaterialState.disabled)) {
      return disabledColor;
    }
    if (states.contains(MaterialState.selected)) {
      return selectedColor;
    }
    return enabledColor;
  }
}

// Identifies the children of a _MongolListTileElement.
enum _ListTileSlot {
  leading,
  title,
  subtitle,
  trailing,
}

class _MongolListTile
    extends SlottedMultiChildRenderObjectWidget<_ListTileSlot, RenderBox> {
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
    required this.titleAlignment,
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
  final MongolListTileTitleAlignment titleAlignment;

  @override
  Iterable<_ListTileSlot> get slots => _ListTileSlot.values;

  @override
  Widget? childForSlot(_ListTileSlot slot) {
    switch (slot) {
      case _ListTileSlot.leading:
        return leading;
      case _ListTileSlot.title:
        return title;
      case _ListTileSlot.subtitle:
        return subtitle;
      case _ListTileSlot.trailing:
        return trailing;
    }
  }

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
      titleAlignment: titleAlignment,
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
      ..minLeadingHeight = minLeadingHeight
      ..titleAlignment = titleAlignment;
  }
}

class _MongolRenderListTile extends RenderBox
    with SlottedContainerRenderObjectMixin<_ListTileSlot, RenderBox> {
  _MongolRenderListTile({
    required bool isDense,
    required VisualDensity visualDensity,
    required bool isThreeLine,
    required TextBaseline titleBaselineType,
    TextBaseline? subtitleBaselineType,
    required double verticalTitleGap,
    required double minHorizontalPadding,
    required double minLeadingHeight,
    required MongolListTileTitleAlignment titleAlignment,
  })  : _isDense = isDense,
        _visualDensity = visualDensity,
        _isThreeLine = isThreeLine,
        _titleBaselineType = titleBaselineType,
        _subtitleBaselineType = subtitleBaselineType,
        _verticalTitleGap = verticalTitleGap,
        _minHorizontalPadding = minHorizontalPadding,
        _minLeadingHeight = minLeadingHeight,
        _titleAlignment = titleAlignment;

  RenderBox? get leading => childForSlot(_ListTileSlot.leading);
  RenderBox? get title => childForSlot(_ListTileSlot.title);
  RenderBox? get subtitle => childForSlot(_ListTileSlot.subtitle);
  RenderBox? get trailing => childForSlot(_ListTileSlot.trailing);

  // The returned list is ordered for hit testing.
  @override
  Iterable<RenderBox> get children {
    return <RenderBox>[
      if (leading != null) leading!,
      if (title != null) title!,
      if (subtitle != null) subtitle!,
      if (trailing != null) trailing!,
    ];
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

  MongolListTileTitleAlignment get titleAlignment => _titleAlignment;
  MongolListTileTitleAlignment _titleAlignment;
  set titleAlignment(MongolListTileTitleAlignment value) {
    if (_titleAlignment == value) return;
    _titleAlignment = value;
    markNeedsLayout();
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
    assert(title != null);
    final BoxParentData parentData = title!.parentData! as BoxParentData;
    return parentData.offset.dx + title!.getDistanceToActualBaseline(baseline)!;
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

    final double leadingX;
    final double trailingX;

    switch (titleAlignment) {
      case MongolListTileTitleAlignment.threeLine:
        {
          if (isThreeLine) {
            leadingX = _minHorizontalPadding;
            trailingX = _minHorizontalPadding;
          } else {
            leadingX = (tileWidth - leadingSize.width) / 2.0;
            trailingX = (tileWidth - trailingSize.width) / 2.0;
          }
          break;
        }
      case MongolListTileTitleAlignment.titleWidth:
        {
          // This attempts to implement the redlines for the horizontal position of the
          // leading and trailing icons on the spec page:
          //   https://m2.material.io/components/lists#specs
          // The interpretation for these redlines is as follows:
          //  - For large tiles (> 72dp), both leading and trailing controls should be
          //    a fixed distance from left. As per guidelines this is set to 16dp.
          //  - For smaller tiles, trailing should always be centered. Leading can be
          //    centered or closer to the left. It should never be further than 16dp
          //    to the left.
          if (tileWidth > 72.0) {
            leadingX = 16.0;
            trailingX = 16.0;
          } else {
            leadingX = math.min((tileWidth - leadingSize.width) / 2.0, 16.0);
            trailingX = (tileWidth - trailingSize.width) / 2.0;
          }
          break;
        }
      case MongolListTileTitleAlignment.left:
        {
          leadingX = _minHorizontalPadding;
          trailingX = _minHorizontalPadding;
          break;
        }
      case MongolListTileTitleAlignment.center:
        {
          leadingX = (tileWidth - leadingSize.width) / 2.0;
          trailingX = (tileWidth - trailingSize.width) / 2.0;
          break;
        }
      case MongolListTileTitleAlignment.right:
        {
          leadingX = tileWidth - leadingSize.width - _minHorizontalPadding;
          trailingX = tileWidth - trailingSize.width - _minHorizontalPadding;
          break;
        }
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
    for (final RenderBox child in children) {
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

class _LisTileDefaultsM2 extends MongolListTileThemeData {
  _LisTileDefaultsM2(this.context, ListTileStyle style)
      : super(
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          minLeadingHeight: 40,
          minHorizontalPadding: 4,
          shape: const Border(),
          style: style,
        );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get tileColor => Colors.transparent;

  @override
  TextStyle? get titleTextStyle {
    switch (style!) {
      case ListTileStyle.drawer:
        return _textTheme.bodyLarge;
      case ListTileStyle.list:
        return _textTheme.titleMedium;
    }
  }

  @override
  TextStyle? get subtitleTextStyle =>
      _textTheme.bodyMedium!.copyWith(color: _textTheme.bodySmall!.color);

  @override
  TextStyle? get leadingAndTrailingTextStyle => _textTheme.bodyMedium;

  @override
  Color? get selectedColor => _theme.colorScheme.primary;

  @override
  Color? get iconColor {
    switch (_theme.brightness) {
      case Brightness.light:
        // For the sake of backwards compatibility, the default for unselected
        // tiles is Colors.black45 rather than colorScheme.onSurface.withAlpha(0x73).
        return Colors.black45;
      case Brightness.dark:
        return null; // null, Use current icon theme color
    }
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - LisTile

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _LisTileDefaultsM3 extends MongolListTileThemeData {
  _LisTileDefaultsM3(this.context)
      : super(
          contentPadding:
              const EdgeInsetsDirectional.only(top: 16.0, bottom: 24.0),
          minLeadingHeight: 24,
          minHorizontalPadding: 8,
          shape: const RoundedRectangleBorder(),
        );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get tileColor => Colors.transparent;

  @override
  TextStyle? get titleTextStyle =>
      _textTheme.bodyLarge!.copyWith(color: _colors.onSurface);

  @override
  TextStyle? get subtitleTextStyle =>
      _textTheme.bodyMedium!.copyWith(color: _colors.onSurfaceVariant);

  @override
  TextStyle? get leadingAndTrailingTextStyle =>
      _textTheme.labelSmall!.copyWith(color: _colors.onSurfaceVariant);

  @override
  Color? get selectedColor => _colors.primary;

  @override
  Color? get iconColor => _colors.onSurfaceVariant;
}

// END GENERATED TOKEN PROPERTIES - LisTile
