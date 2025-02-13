// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart'
    show
        ButtonStyle,
        ButtonStyleButton,
        ColorScheme,
        ElevatedButtonTheme,
        InkRipple,
        InteractiveInkFeatureFactory,
        WidgetState,
        WidgetStateProperty,
        MaterialTapTargetSize,
        Theme,
        ThemeData,
        VisualDensity,
        WidgetStatesController,
        WidgetStatePropertyAll,
        kThemeChangeDuration;

import 'mongol_button_style_button.dart';

/// A vertical Material Design "elevated button".
///
/// Use elevated buttons to add dimension to otherwise mostly flat
/// layouts, e.g.  in long busy lists of content, or in wide
/// spaces. Avoid using elevated buttons on already-elevated content
/// such as dialogs or cards.
///
/// An elevated button is a label [child] displayed on a [Material]
/// widget whose [Material.elevation] increases when the button is
/// pressed. The label's [MongolText] and [Icon] widgets are displayed in
/// [style]'s [ButtonStyle.foregroundColor] and the button's filled
/// background is the [ButtonStyle.backgroundColor].
///
/// The elevated button's default style is defined by
/// [defaultStyleOf].  The style of this elevated button can be
/// overridden with its [style] parameter. The style of all elevated
/// buttons in a subtree can be overridden with the
/// [ElevatedButtonTheme], and the style of all of the elevated
/// buttons in an app can be overridden with the [Theme]'s
/// [ThemeData.elevatedButtonTheme] property.
///
/// The static [styleFrom] method is a convenient way to create a
/// elevated button [ButtonStyle] from simple values.
///
/// If [onPressed] and [onLongPress] callbacks are null, then the
/// button will be disabled.
///
/// {@tool dartpad --template=stateful_widget_scaffold}
///
/// This sample produces an enabled and a disabled MongolElevatedButton.
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final ButtonStyle style =
///     MongolElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
///
///   return Center(
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: <Widget>[
///         MongolElevatedButton(
///            style: style,
///            onPressed: null,
///            child: const Text('Disabled'),
///         ),
///         const SizedBox(height: 30),
///         MongolElevatedButton(
///           style: style,
///           onPressed: () {},
///           child: const Text('Enabled'),
///         ),
///       ],
///     ),
///   );
/// }
///
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [MongolFilledButton], a vertical filled button that doesn't elevate when pressed.
///  * [MongolFilledButton.tonal], a vertical filled button variant that uses a secondary fill color.
///  * [MongolTextButton], a simple flat button without a shadow.
///  * [MongolOutlinedButton], a [MongolTextButton] with a border outline.
///  * <https://material.io/design/components/buttons.html>
///  * <https://m3.material.io/components/buttons>
class MongolElevatedButton extends MongolButtonStyleButton {
  /// Create a MongolElevatedButton.
  ///
  /// The [autofocus] and [clipBehavior] arguments must not be null.
  const MongolElevatedButton({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.clipBehavior = Clip.none,
    super.statesController,
    required super.child,
  });

  /// Create an elevated button from a pair of widgets that serve as the button's
  /// [icon] and [label].
  ///
  /// The icon and label are arranged in a column and padded by 12 logical pixels
  /// at the start, and 16 at the end, with an 8 pixel gap in between.
  ///
  /// The [icon] and [label] arguments must not be null.
  factory MongolElevatedButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    ValueChanged<bool>? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    WidgetStatesController? statesController,
    required Widget icon,
    required Widget label,
  }) = _MongolElevatedButtonWithIcon;

  /// A static convenience method that constructs an elevated button
  /// [ButtonStyle] given simple values.
  ///
  /// The [foregroundColor] and [disabledForegroundColor] colors are used
  /// to create a [MaterialStateProperty] [ButtonStyle.foregroundColor], and
  /// a derived [ButtonStyle.overlayColor].
  /// 
  /// The [backgroundColor] and [disabledBackgroundColor] colors are
  /// used to create a [MaterialStateProperty] [ButtonStyle.backgroundColor].
  ///
  /// The button's elevations are defined relative to the [elevation]
  /// parameter. The disabled elevation is the same as the parameter
  /// value, [elevation] + 2 is used when the button is hovered
  /// or focused, and elevation + 6 is used when the button is pressed.
  ///
  /// Similarly, the [enabledMouseCursor] and [disabledMouseCursor]
  /// parameters are used to construct [ButtonStyle].mouseCursor.
  ///
  /// All of the other parameters are either used directly or used to
  /// create a [WidgetStateProperty] with a single value for all
  /// states.
  ///
  /// All parameters default to null, by default this method returns
  /// a [ButtonStyle] that doesn't override anything.
  ///
  /// For example, to override the default text and icon colors for a
  /// [MongolElevatedButton], as well as its overlay color, with all of the
  /// standard opacity adjustments for the pressed, focused, and
  /// hovered states, one could write:
  ///
  /// ```dart
  /// MongolElevatedButton(
  ///   style: MongolElevatedButton.styleFrom(foregroundColor: Colors.green),
  ///   onPressed: () {
  ///     // ...
  ///   },
  ///   child: const Text('Jump'),
  /// ),
  /// ```
  ///
  /// And to change the fill color:
  ///
  /// ```dart
  /// MongolElevatedButton(
  ///   style: MongolElevatedButton.styleFrom(backgroundColor: Colors.green),
  ///   onPressed: () {
  ///     // ...
  ///   },
  ///   child: const Text('Meow'),
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    final Color? background = backgroundColor;
    final Color? disabledBackground = disabledBackgroundColor;
    final WidgetStateProperty<Color?>? backgroundColorProp =
        (background == null && disabledBackground == null)
            ? null
            : _ElevatedButtonDefaultColor(background, disabledBackground);
    final Color? foreground = foregroundColor;
    final Color? disabledForeground = disabledForegroundColor;
    final WidgetStateProperty<Color?>? foregroundColorProp =
        (foreground == null && disabledForeground == null)
            ? null
            : _ElevatedButtonDefaultColor(foreground, disabledForeground);
    final WidgetStateProperty<Color?>? overlayColor =
        (foreground == null) ? null : _ElevatedButtonDefaultOverlay(foreground);
    final WidgetStateProperty<double>? elevationValue =
        (elevation == null) ? null : _ElevatedButtonDefaultElevation(elevation);
    final WidgetStateProperty<MouseCursor?> mouseCursor =
        _ElevatedButtonDefaultMouseCursor(
            enabledMouseCursor, disabledMouseCursor);

    return ButtonStyle(
      textStyle: WidgetStateProperty.all<TextStyle?>(textStyle),
      backgroundColor: backgroundColorProp,
      foregroundColor: foregroundColorProp,
      overlayColor: overlayColor,
      shadowColor: ButtonStyleButton.allOrNull<Color>(shadowColor),
      surfaceTintColor: ButtonStyleButton.allOrNull<Color>(surfaceTintColor),
      elevation: elevationValue,
      padding: ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(padding),
      minimumSize: ButtonStyleButton.allOrNull<Size>(minimumSize),
      maximumSize: ButtonStyleButton.allOrNull<Size>(maximumSize),
      fixedSize: ButtonStyleButton.allOrNull<Size>(fixedSize),
      side: ButtonStyleButton.allOrNull<BorderSide>(side),
      shape: ButtonStyleButton.allOrNull<OutlinedBorder>(shape),
      mouseCursor: mouseCursor,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  /// Defines the button's default appearance.
  ///
  /// The button [child]'s [MongolText] and [Icon] widgets are rendered with
  /// the [ButtonStyle]'s foreground color. The button's [InkWell] adds
  /// the style's overlay color when the button is focused, hovered
  /// or pressed. The button's background color becomes its [Material]
  /// color.
  ///
  /// All of the ButtonStyle's defaults appear below. In this list
  /// "Theme.foo" is shorthand for `Theme.of(context).foo`. Color
  /// scheme values like "onSurface(0.38)" are shorthand for
  /// `onSurface.withOpacity(0.38)`. [WidgetStateProperty] valued
  /// properties that are not followed by a sublist have the same
  /// value for all states, otherwise the values are as specified for
  /// each state, and "others" means all other states.
  ///
  /// The "default font size" below refers to the font size specified in the
  /// [defaultStyleOf] method (or 14.0 if unspecified), scaled by the
  /// `MediaQuery.textScalerOf(context).scale` method. The names of the
  /// EdgeInsets constructors and `EdgeInsetsGeometry.lerp` have been abbreviated
  /// for readability.
  ///
  /// The color of the [ButtonStyle.textStyle] is not used, the
  /// [ButtonStyle.foregroundColor] color is used instead.
  ///
  /// ## Material 2 defaults
  /// 
  /// * `textStyle` - Theme.textTheme.button
  /// * `backgroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.12)
  ///   * others - Theme.colorScheme.primary
  /// * `foregroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.38)
  ///   * others - Theme.colorScheme.onPrimary
  /// * `overlayColor`
  ///   * hovered - Theme.colorScheme.onPrimary(0.08)
  ///   * focused or pressed - Theme.colorScheme.onPrimary(0.24)
  /// * `shadowColor` - Theme.shadowColor
  /// * `elevation`
  ///   * disabled - 0
  ///   * default - 2
  ///   * hovered or focused - 4
  ///   * pressed - 8
  /// * `padding`
  ///   * `default font size <= 14` - vertical(16)
  ///   * `14 < default font size <= 28` - lerp(vertical(16), vertical(8))
  ///   * `28 < default font size <= 36` - lerp(vertical(8), vertical(4))
  ///   * `36 < default font size` - vertical(4)
  /// * `minimumSize` - Size(36, 64)
  /// * `fixedSize` - null
  /// * `maximumSize` - Size.infinite
  /// * `side` - null
  /// * `shape` - RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
  /// * `mouseCursor`
  ///   * disabled - SystemMouseCursors.forbidden
  ///   * others - SystemMouseCursors.click
  /// * `visualDensity` - theme.visualDensity
  /// * `tapTargetSize` - theme.materialTapTargetSize
  /// * `animationDuration` - kThemeChangeDuration
  /// * `enableFeedback` - true
  /// * `alignment` - Alignment.center
  /// * `splashFactory` - InkRipple.splashFactory
  ///
  /// The default padding values for the [MongolElevatedButton.icon] factory are slightly different:
  ///
  /// * `padding`
  ///   * `default font size <= 14` - start(12) end(16)
  ///   * `14 < default font size <= 28` - lerp(start(12) end(16), vertical(8))
  ///   * `28 < default font size <= 36` - lerp(vertical(8), vertical(4))
  ///   * `36 < default font size` - vertical(4)
  ///
  /// The default value for `side`, which defines the appearance of the button's
  /// outline, is null. That means that the outline is defined by the button
  /// shape's [OutlinedBorder.side]. Typically the default value of an
  /// [OutlinedBorder]'s side is [BorderSide.none], so an outline is not drawn.
  /// 
  /// ## Material 3 defaults
  ///
  /// If [ThemeData.useMaterial3] is set to true the following defaults will
  /// be used:
  ///
  /// * `textStyle` - Theme.textTheme.labelLarge
  /// * `backgroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.12)
  ///   * others - Theme.colorScheme.surface
  /// * `foregroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.38)
  ///   * others - Theme.colorScheme.primary
  /// * `overlayColor`
  ///   * hovered - Theme.colorScheme.primary(0.08)
  ///   * focused or pressed - Theme.colorScheme.primary(0.12)
  /// * `shadowColor` - Theme.colorScheme.shadow
  /// * `surfaceTintColor` - Theme.colorScheme.surfaceTint
  /// * `elevation`
  ///   * disabled - 0
  ///   * default - 1
  ///   * hovered - 3
  ///   * focused or pressed - 1
  /// * `padding`
  ///   * `default font size <= 14` - vertical(24)
  ///   * `14 < default font size <= 28` - lerp(vertical(24), vertical(12))
  ///   * `28 < default font size <= 36` - lerp(vertical(12), vertical(6))
  ///   * `36 < default font size` - vertical(6)
  /// * `minimumSize` - Size(40, 64)
  /// * `fixedSize` - null
  /// * `maximumSize` - Size.infinite
  /// * `side` - null
  /// * `shape` - StadiumBorder()
  /// * `mouseCursor`
  ///   * disabled - SystemMouseCursors.basic
  ///   * others - SystemMouseCursors.click
  /// * `visualDensity` - Theme.visualDensity
  /// * `tapTargetSize` - Theme.materialTapTargetSize
  /// * `animationDuration` - kThemeChangeDuration
  /// * `enableFeedback` - true
  /// * `alignment` - Alignment.center
  /// * `splashFactory` - Theme.splashFactory
  ///
  /// For the [MongolElevatedButton.icon] factory, the start (generally the top) value of
  /// [padding] is reduced from 24 to 16.
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Theme.of(context).useMaterial3
        ? _ElevatedButtonDefaultsM3(context)
        : styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
            disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
            shadowColor: theme.shadowColor,
            elevation: 2,
            textStyle: theme.textTheme.labelLarge,
            padding: _scaledPadding(context),
            minimumSize: const Size(36, 64),
            maximumSize: Size.infinite,
            side: null,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4))),
            enabledMouseCursor: SystemMouseCursors.click,
            disabledMouseCursor: SystemMouseCursors.basic,
            visualDensity: theme.visualDensity,
            tapTargetSize: theme.materialTapTargetSize,
            animationDuration: kThemeChangeDuration,
            enableFeedback: true,
            alignment: Alignment.center,
            splashFactory: InkRipple.splashFactory,
          );
  }

  /// Returns the [ElevatedButtonThemeData.style] of the closest
  /// [ElevatedButtonTheme] ancestor.
  @override
  ButtonStyle? themeStyleOf(BuildContext context) {
    return ElevatedButtonTheme.of(context).style;
  }
}

EdgeInsetsGeometry _scaledPadding(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final double padding1x = theme.useMaterial3 ? 24.0 : 16.0;
  final double defaultFontSize = theme.textTheme.labelLarge?.fontSize ?? 14.0;
  final double effectiveTextScale =
      MediaQuery.textScalerOf(context).scale(defaultFontSize) / 14.0;

  return ButtonStyleButton.scaledPadding(
    EdgeInsets.symmetric(vertical: padding1x),
    EdgeInsets.symmetric(vertical: padding1x / 2),
    EdgeInsets.symmetric(vertical: padding1x / 2 / 2),
    effectiveTextScale,
  );
}

@immutable
class _ElevatedButtonDefaultColor extends WidgetStateProperty<Color?>
    with Diagnosticable {
  _ElevatedButtonDefaultColor(this.color, this.disabled);

  final Color? color;
  final Color? disabled;

  @override
  Color? resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return disabled;
    }
    return color;
  }
}

@immutable
class _ElevatedButtonDefaultOverlay extends WidgetStateProperty<Color?>
    with Diagnosticable {
  _ElevatedButtonDefaultOverlay(this.overlay);

  final Color overlay;

  @override
  Color? resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return overlay.withOpacity(0.24);
    }
    if (states.contains(WidgetState.hovered)) {
      return overlay.withOpacity(0.08);
    }
    if (states.contains(WidgetState.focused)) {
      return overlay.withOpacity(0.24);
    }
    return null;
  }
}

@immutable
class _ElevatedButtonDefaultElevation extends WidgetStateProperty<double>
    with Diagnosticable {
  _ElevatedButtonDefaultElevation(this.elevation);

  final double elevation;

  @override
  double resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return 0;
    }
    if (states.contains(WidgetState.pressed)) {
      return elevation + 6;
    }
    if (states.contains(WidgetState.hovered)) {
      return elevation + 2;
    }
    if (states.contains(WidgetState.focused)) {
      return elevation + 2;
    }
    return elevation;
  }
}

@immutable
class _ElevatedButtonDefaultMouseCursor
    extends WidgetStateProperty<MouseCursor?> with Diagnosticable {
  _ElevatedButtonDefaultMouseCursor(this.enabledCursor, this.disabledCursor);

  final MouseCursor? enabledCursor;
  final MouseCursor? disabledCursor;

  @override
  MouseCursor? resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return disabledCursor;
    }
    return enabledCursor;
  }
}

class _MongolElevatedButtonWithIcon extends MongolElevatedButton {
  _MongolElevatedButtonWithIcon({
    super.key,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    super.statesController,
    required Widget icon,
    required Widget label,
  }) : super(
          autofocus: autofocus ?? false,
          clipBehavior: clipBehavior ?? Clip.none,
          child: _MongolElevatedButtonWithIconChild(icon: icon, label: label),
        );

  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final bool useMaterial3 = Theme.of(context).useMaterial3;
    final ButtonStyle buttonStyle = super.defaultStyleOf(context);
    final double defaultFontSize =
        buttonStyle.textStyle?.resolve(const <WidgetState>{})?.fontSize ??
            14.0;
    final double effectiveTextScale =
        MediaQuery.textScalerOf(context).scale(defaultFontSize) / 14.0;

    final EdgeInsetsGeometry scaledPadding = useMaterial3
        ? ButtonStyleButton.scaledPadding(
            const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 24),
            const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 12),
            const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 6),
            effectiveTextScale,
          )
        : ButtonStyleButton.scaledPadding(
            const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 16),
            const EdgeInsets.symmetric(vertical: 8),
            const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 4),
            effectiveTextScale,
          );
    return buttonStyle.copyWith(
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(scaledPadding),
    );
  }
}

class _MongolElevatedButtonWithIconChild extends StatelessWidget {
  const _MongolElevatedButtonWithIconChild(
      {Key? key, required this.label, required this.icon})
      : super(key: key);

  final Widget label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context).textScaleFactor;
    final double gap =
        scale <= 1 ? 8 : lerpDouble(8, 4, math.min(scale - 1, 1))!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[icon, SizedBox(height: gap), Flexible(child: label)],
    );
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - ElevatedButton

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _ElevatedButtonDefaultsM3 extends ButtonStyle {
  _ElevatedButtonDefaultsM3(this.context)
      : super(
          animationDuration: kThemeChangeDuration,
          enableFeedback: true,
          alignment: Alignment.center,
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<TextStyle?> get textStyle =>
      WidgetStatePropertyAll<TextStyle?>(
          Theme.of(context).textTheme.labelLarge);

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return _colors.onSurface.withOpacity(0.12);
        }
        return _colors.surface;
      });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        return _colors.primary;
      });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.12);
        }
        return null;
      });

  @override
  WidgetStateProperty<Color>? get shadowColor =>
      WidgetStatePropertyAll<Color>(_colors.shadow);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
      WidgetStatePropertyAll<Color>(_colors.surfaceTint);

  @override
  WidgetStateProperty<double>? get elevation =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return 0.0;
        }
        if (states.contains(WidgetState.pressed)) {
          return 1.0;
        }
        if (states.contains(WidgetState.hovered)) {
          return 3.0;
        }
        if (states.contains(WidgetState.focused)) {
          return 1.0;
        }
        return 1.0;
      });

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
      WidgetStatePropertyAll<EdgeInsetsGeometry>(_scaledPadding(context));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
      const WidgetStatePropertyAll<Size>(Size(40.0, 64.0));

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
      const WidgetStatePropertyAll<Size>(Size.infinite);

  // No default side

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
      const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder());

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      });

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  @override
  MaterialTapTargetSize? get tapTargetSize =>
      Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory =>
      Theme.of(context).splashFactory;
}

// END GENERATED TOKEN PROPERTIES - ElevatedButton

