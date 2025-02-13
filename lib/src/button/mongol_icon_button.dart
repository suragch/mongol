// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show Brightness, ButtonStyle, ButtonStyleButton, ColorScheme, Colors, IconButton, IconButtonTheme, InkResponse, InteractiveInkFeatureFactory, Material, WidgetState, WidgetStateProperty, WidgetStatePropertyAll, WidgetStatesController, MaterialTapTargetSize, Theme, ThemeData, VisualDensity, debugCheckHasMaterial, kDefaultIconDarkColor, kDefaultIconLightColor, kMinInteractiveDimension, kThemeChangeDuration;
import 'package:flutter/widgets.dart';

import '../menu/mongol_tooltip.dart';

// Minimum logical pixel size of the IconButton.
// See: <https://material.io/design/usability/accessibility.html#layout-typography>.
const double _kMinButtonSize = kMinInteractiveDimension;

enum _IconButtonVariant { standard, filled, filledTonal, outlined }

/// An IconButton that uses a MongolTooltip
///
/// Everything else about this widget except for the tooltip should behave
/// exactly like IconButton.
class MongolIconButton extends IconButton {
  const MongolIconButton({
    super.key,
    super.iconSize,
    super.visualDensity,
    super.padding,
    super.alignment,
    super.splashRadius,
    super.color,
    super.focusColor,
    super.hoverColor,
    super.highlightColor,
    super.splashColor,
    super.disabledColor,
    required super.onPressed,
    super.mouseCursor,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.enableFeedback,
    super.constraints,
    super.style,
    super.isSelected,
    super.selectedIcon,
    required super.icon,
  }) : _variant = _IconButtonVariant.standard;

  /// Create a filled variant of IconButton.
  ///
  /// Filled icon buttons have higher visual impact and should be used for
  /// high emphasis actions, such as turning off a microphone or camera.
  const MongolIconButton.filled({
    super.key,
    super.iconSize,
    super.visualDensity,
    super.padding,
    super.alignment,
    super.splashRadius,
    super.color,
    super.focusColor,
    super.hoverColor,
    super.highlightColor,
    super.splashColor,
    super.disabledColor,
    required super.onPressed,
    super.mouseCursor,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.enableFeedback,
    super.constraints,
    super.style,
    super.isSelected,
    super.selectedIcon,
    required super.icon,
  }) : _variant = _IconButtonVariant.filled;

  /// Create a filled tonal variant of IconButton.
  ///
  /// Filled tonal icon buttons are a middle ground between filled and outlined
  /// icon buttons. They’re useful in contexts where the button requires slightly
  /// more emphasis than an outline would give, such as a secondary action paired
  /// with a high emphasis action.
  const MongolIconButton.filledTonal({
    super.key,
    super.iconSize,
    super.visualDensity,
    super.padding,
    super.alignment,
    super.splashRadius,
    super.color,
    super.focusColor,
    super.hoverColor,
    super.highlightColor,
    super.splashColor,
    super.disabledColor,
    required super.onPressed,
    super.mouseCursor,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.enableFeedback,
    super.constraints,
    super.style,
    super.isSelected,
    super.selectedIcon,
    required super.icon,
  }) : _variant = _IconButtonVariant.filledTonal;

  /// Create a filled tonal variant of IconButton.
  ///
  /// Outlined icon buttons are medium-emphasis buttons. They’re useful when an
  /// icon button needs more emphasis than a standard icon button but less than
  /// a filled or filled tonal icon button.
  const MongolIconButton.outlined({
    super.key,
    super.iconSize,
    super.visualDensity,
    super.padding,
    super.alignment,
    super.splashRadius,
    super.color,
    super.focusColor,
    super.hoverColor,
    super.highlightColor,
    super.splashColor,
    super.disabledColor,
    required super.onPressed,
    super.mouseCursor,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.enableFeedback,
    super.constraints,
    super.style,
    super.isSelected,
    super.selectedIcon,
    required super.icon,
  }) : _variant = _IconButtonVariant.outlined;

  final _IconButtonVariant _variant;

  /// A static convenience method that constructs an icon button
  /// [ButtonStyle] given simple values. This method is only used for Material 3.
  ///
  /// The [foregroundColor] color is used to create a [WidgetStateProperty]
  /// [ButtonStyle.foregroundColor] value. Specify a value for [foregroundColor]
  /// to specify the color of the button's icons. The [hoverColor], [focusColor]
  /// and [highlightColor] colors are used to indicate the hover, focus,
  /// and pressed states. Use [backgroundColor] for the button's background
  /// fill color. Use [disabledForegroundColor] and [disabledBackgroundColor]
  /// to specify the button's disabled icon and fill color.
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
  /// For example, to override the default icon color for a
  /// [IconButton], as well as its overlay color, with all of the
  /// standard opacity adjustments for the pressed, focused, and
  /// hovered states, one could write:
  ///
  /// ```dart
  /// IconButton(
  ///   icon: const Icon(Icons.pets),
  ///   style: IconButton.styleFrom(foregroundColor: Colors.green),
  ///   onPressed: () {
  ///     // ...
  ///   },
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    double? iconSize,
    BorderSide? side,
    OutlinedBorder? shape,
    EdgeInsetsGeometry? padding,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    final WidgetStateProperty<Color?>? buttonBackgroundColor =
        (backgroundColor == null && disabledBackgroundColor == null)
            ? null
            : _IconButtonDefaultBackground(
                backgroundColor, disabledBackgroundColor);
    final WidgetStateProperty<Color?>? buttonForegroundColor =
        (foregroundColor == null && disabledForegroundColor == null)
            ? null
            : _IconButtonDefaultForeground(
                foregroundColor, disabledForegroundColor);
    final WidgetStateProperty<Color?>? overlayColor =
        (foregroundColor == null &&
                hoverColor == null &&
                focusColor == null &&
                highlightColor == null)
            ? null
            : _IconButtonDefaultOverlay(
                foregroundColor, focusColor, hoverColor, highlightColor);
    final WidgetStateProperty<MouseCursor?> mouseCursor =
        _IconButtonDefaultMouseCursor(enabledMouseCursor, disabledMouseCursor);

    return ButtonStyle(
      backgroundColor: buttonBackgroundColor,
      foregroundColor: buttonForegroundColor,
      overlayColor: overlayColor,
      shadowColor: ButtonStyleButton.allOrNull<Color>(shadowColor),
      surfaceTintColor: ButtonStyleButton.allOrNull<Color>(surfaceTintColor),
      elevation: ButtonStyleButton.allOrNull<double>(elevation),
      padding: ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(padding),
      minimumSize: ButtonStyleButton.allOrNull<Size>(minimumSize),
      fixedSize: ButtonStyleButton.allOrNull<Size>(fixedSize),
      maximumSize: ButtonStyleButton.allOrNull<Size>(maximumSize),
      iconSize: ButtonStyleButton.allOrNull<double>(iconSize),
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (theme.useMaterial3) {
      final Size? minSize = constraints == null
          ? null
          : Size(constraints!.minWidth, constraints!.minHeight);
      final Size? maxSize = constraints == null
          ? null
          : Size(constraints!.maxWidth, constraints!.maxHeight);

      ButtonStyle adjustedStyle = styleFrom(
        visualDensity: visualDensity,
        foregroundColor: color,
        disabledForegroundColor: disabledColor,
        focusColor: focusColor,
        hoverColor: hoverColor,
        highlightColor: highlightColor,
        padding: padding,
        minimumSize: minSize,
        maximumSize: maxSize,
        iconSize: iconSize,
        alignment: alignment,
        enabledMouseCursor: mouseCursor,
        disabledMouseCursor: mouseCursor,
        enableFeedback: enableFeedback,
      );
      if (style != null) {
        adjustedStyle = style!.merge(adjustedStyle);
      }

      Widget effectiveIcon = icon;
      if ((isSelected ?? false) && selectedIcon != null) {
        effectiveIcon = selectedIcon!;
      }

      Widget iconButton = effectiveIcon;
      if (tooltip != null) {
        iconButton = MongolTooltip(
          message: tooltip!,
          child: effectiveIcon,
        );
      }

      return _SelectableIconButton(
        style: adjustedStyle,
        onPressed: onPressed,
        autofocus: autofocus,
        focusNode: focusNode,
        isSelected: isSelected,
        variant: _variant,
        child: iconButton,
      );
    }

    assert(debugCheckHasMaterial(context));

    Color? currentColor;
    if (onPressed != null) {
      currentColor = color;
    } else {
      currentColor = disabledColor ?? theme.disabledColor;
    }

    final VisualDensity effectiveVisualDensity =
        visualDensity ?? theme.visualDensity;

    final BoxConstraints unadjustedConstraints = constraints ??
        const BoxConstraints(
          minWidth: _kMinButtonSize,
          minHeight: _kMinButtonSize,
        );
    final BoxConstraints adjustedConstraints =
        effectiveVisualDensity.effectiveConstraints(unadjustedConstraints);
    final double effectiveIconSize =
        iconSize ?? IconTheme.of(context).size ?? 24.0;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.all(8.0);
    final AlignmentGeometry effectiveAlignment = alignment ?? Alignment.center;
    final bool effectiveEnableFeedback = enableFeedback ?? true;

    Widget result = ConstrainedBox(
      constraints: adjustedConstraints,
      child: Padding(
        padding: effectivePadding,
        child: SizedBox(
          height: effectiveIconSize,
          width: effectiveIconSize,
          child: Align(
            alignment: effectiveAlignment,
            child: IconTheme.merge(
              data: IconThemeData(
                size: effectiveIconSize,
                color: currentColor,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      result = MongolTooltip(
        message: tooltip!,
        child: result,
      );
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: InkResponse(
        focusNode: focusNode,
        autofocus: autofocus,
        canRequestFocus: onPressed != null,
        onTap: onPressed,
        mouseCursor: mouseCursor ??
            (onPressed == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click),
        enableFeedback: effectiveEnableFeedback,
        focusColor: focusColor ?? theme.focusColor,
        hoverColor: hoverColor ?? theme.hoverColor,
        highlightColor: highlightColor ?? theme.highlightColor,
        splashColor: splashColor ?? theme.splashColor,
        radius: splashRadius ??
            math.max(
              Material.defaultSplashRadius,
              (effectiveIconSize +
                      math.min(effectivePadding.horizontal,
                          effectivePadding.vertical)) *
                  0.7,
              // x 0.5 for diameter -> radius and + 40% overflow derived from other Material apps.
            ),
        child: result,
      ),
    );
  }
}

class _SelectableIconButton extends StatefulWidget {
  const _SelectableIconButton({
    this.isSelected,
    this.style,
    this.focusNode,
    required this.variant,
    required this.autofocus,
    required this.onPressed,
    required this.child,
  });

  final bool? isSelected;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final _IconButtonVariant variant;
  final bool autofocus;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<_SelectableIconButton> createState() => _SelectableIconButtonState();
}

class _SelectableIconButtonState extends State<_SelectableIconButton> {
  late final WidgetStatesController statesController;

  @override
  void initState() {
    super.initState();
    if (widget.isSelected == null) {
      statesController = WidgetStatesController();
    } else {
      statesController = WidgetStatesController(<WidgetState>{
        if (widget.isSelected!) WidgetState.selected
      });
    }
  }

  @override
  void didUpdateWidget(_SelectableIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected == null) {
      if (statesController.value.contains(WidgetState.selected)) {
        statesController.update(WidgetState.selected, false);
      }
      return;
    }
    if (widget.isSelected != oldWidget.isSelected) {
      statesController.update(WidgetState.selected, widget.isSelected!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool toggleable = widget.isSelected != null;

    return _IconButtonM3(
      statesController: statesController,
      style: widget.style,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onPressed: widget.onPressed,
      variant: widget.variant,
      toggleable: toggleable,
      child: Semantics(
        selected: widget.isSelected,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    statesController.dispose();
    super.dispose();
  }
}

class _IconButtonM3 extends ButtonStyleButton {
  const _IconButtonM3({
    required super.onPressed,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.statesController,
    required this.variant,
    required this.toggleable,
    required Widget super.child,
  }) : super(
      onLongPress: null,
      onHover: null,
      onFocusChange: null,
      clipBehavior: Clip.none);

  final _IconButtonVariant variant;
  final bool toggleable;

  /// ## Material 3 defaults
  ///
  /// If [ThemeData.useMaterial3] is set to true the following defaults will
  /// be used:
  ///
  /// * `textStyle` - null
  /// * `backgroundColor` - transparent
  /// * `foregroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.38)
  ///   * selected - Theme.colorScheme.primary
  ///   * others - Theme.colorScheme.onSurfaceVariant
  /// * `overlayColor`
  ///   * selected
  ///      * hovered - Theme.colorScheme.primary(0.08)
  ///      * focused or pressed - Theme.colorScheme.primary(0.12)
  ///   * hovered or focused - Theme.colorScheme.onSurfaceVariant(0.08)
  ///   * pressed - Theme.colorScheme.onSurfaceVariant(0.12)
  ///   * others - null
  /// * `shadowColor` - null
  /// * `surfaceTintColor` - null
  /// * `elevation` - 0
  /// * `padding` - all(8)
  /// * `minimumSize` - Size(40, 40)
  /// * `fixedSize` - null
  /// * `maximumSize` - Size.infinite
  /// * `iconSize` - 24
  /// * `side` - null
  /// * `shape` - StadiumBorder()
  /// * `mouseCursor`
  ///   * disabled - SystemMouseCursors.basic
  ///   * others - SystemMouseCursors.click
  /// * `visualDensity` - VisualDensity.standard
  /// * `tapTargetSize` - theme.materialTapTargetSize
  /// * `animationDuration` - kThemeChangeDuration
  /// * `enableFeedback` - true
  /// * `alignment` - Alignment.center
  /// * `splashFactory` - Theme.splashFactory
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    switch (variant) {
      case _IconButtonVariant.filled:
        return _FilledIconButtonDefaultsM3(context, toggleable);
      case _IconButtonVariant.filledTonal:
        return _FilledTonalIconButtonDefaultsM3(context, toggleable);
      case _IconButtonVariant.outlined:
        return _OutlinedIconButtonDefaultsM3(context, toggleable);
      case _IconButtonVariant.standard:
        return _IconButtonDefaultsM3(context, toggleable);
    }
  }

  /// Returns the [IconButtonThemeData.style] of the closest [IconButtonTheme] ancestor.
  /// The color and icon size can also be configured by the [IconTheme] if the same property
  /// has a null value in [IconButtonTheme]. However, if any of the properties exist
  /// in both [IconButtonTheme] and [IconTheme], [IconTheme] will be overridden.
  @override
  ButtonStyle? themeStyleOf(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    bool isIconThemeDefault(Color? color) {
      if (isDark) {
        return identical(color, kDefaultIconLightColor);
      }
      return identical(color, kDefaultIconDarkColor);
    }
    final bool isDefaultColor = isIconThemeDefault(iconTheme.color);
    final bool isDefaultSize = iconTheme.size == const IconThemeData.fallback().size;

    final ButtonStyle iconThemeStyle = IconButton.styleFrom(
      foregroundColor: isDefaultColor ? null : iconTheme.color,
      iconSize: isDefaultSize ? null : iconTheme.size
    );

    return IconButtonTheme.of(context).style?.merge(iconThemeStyle) ?? iconThemeStyle;
  }
}

@immutable
class _IconButtonDefaultBackground extends WidgetStateProperty<Color?> {
  _IconButtonDefaultBackground(this.background, this.disabledBackground);

  final Color? background;
  final Color? disabledBackground;

  @override
  Color? resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return disabledBackground;
    }
    return background;
  }

  @override
  String toString() {
    return '{disabled: $disabledBackground, otherwise: $background}';
  }
}

@immutable
class _IconButtonDefaultForeground extends WidgetStateProperty<Color?> {
  _IconButtonDefaultForeground(this.foregroundColor, this.disabledForegroundColor);

  final Color? foregroundColor;
  final Color? disabledForegroundColor;

  @override
  Color? resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return disabledForegroundColor;
    }
    return foregroundColor;
  }

  @override
  String toString() {
    return '{disabled: $disabledForegroundColor, otherwise: $foregroundColor}';
  }
}

@immutable
class _IconButtonDefaultOverlay extends WidgetStateProperty<Color?> {
  _IconButtonDefaultOverlay(this.foregroundColor, this.focusColor, this.hoverColor, this.highlightColor);

  final Color? foregroundColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;

  @override
  Color? resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      if (states.contains(WidgetState.pressed)) {
        return highlightColor ?? foregroundColor?.withOpacity(0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return hoverColor ?? foregroundColor?.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return focusColor ?? foregroundColor?.withOpacity(0.12);
      }
    }
    if (states.contains(WidgetState.pressed)) {
      return highlightColor ?? foregroundColor?.withOpacity(0.12);
    }
    if (states.contains(WidgetState.hovered)) {
      return hoverColor ?? foregroundColor?.withOpacity(0.08);
    }
    if (states.contains(WidgetState.focused)) {
      return focusColor ?? foregroundColor?.withOpacity(0.08);
    }
    return null;
  }

  @override
  String toString() {
    return '{hovered: $hoverColor, focused: $focusColor, pressed: $highlightColor, otherwise: null}';
  }
}

@immutable
class _IconButtonDefaultMouseCursor extends WidgetStateProperty<MouseCursor?> with Diagnosticable {
  _IconButtonDefaultMouseCursor(this.enabledCursor, this.disabledCursor);

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

// BEGIN GENERATED TOKEN PROPERTIES - IconButton

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _IconButtonDefaultsM3 extends ButtonStyle {
  _IconButtonDefaultsM3(this.context, this.toggleable)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    const WidgetStatePropertyAll<Color?>(Colors.transparent);

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.primary;
      }
      return _colors.onSurfaceVariant;
    });

 @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.12);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurfaceVariant.withOpacity(0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurfaceVariant.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurfaceVariant.withOpacity(0.12);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const WidgetStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.all(8.0));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const WidgetStatePropertyAll<Size>(Size(40.0, 40.0));

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const WidgetStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    const WidgetStatePropertyAll<double>(24.0);

  @override
  WidgetStateProperty<BorderSide?>? get side => null;

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
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

// END GENERATED TOKEN PROPERTIES - IconButton

// BEGIN GENERATED TOKEN PROPERTIES - FilledIconButton

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _FilledIconButtonDefaultsM3 extends ButtonStyle {
  _FilledIconButtonDefaultsM3(this.context, this.toggleable)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.12);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.primary;
      }
      if (toggleable) { // toggleable but unselected case
        return _colors.surfaceContainerHighest;
      }
      return _colors.primary;
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.onPrimary;
      }
      if (toggleable) { // toggleable but unselected case
        return _colors.primary;
      }
      return _colors.onPrimary;
    });

 @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onPrimary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onPrimary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onPrimary.withOpacity(0.12);
        }
      }
      if (toggleable) { // toggleable but unselected case
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.12);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onPrimary.withOpacity(0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onPrimary.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onPrimary.withOpacity(0.12);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const WidgetStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.all(8.0));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const WidgetStatePropertyAll<Size>(Size(40.0, 40.0));

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const WidgetStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    const WidgetStatePropertyAll<double>(24.0);

  @override
  WidgetStateProperty<BorderSide?>? get side => null;

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
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

// END GENERATED TOKEN PROPERTIES - FilledIconButton

// BEGIN GENERATED TOKEN PROPERTIES - FilledTonalIconButton

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _FilledTonalIconButtonDefaultsM3 extends ButtonStyle {
  _FilledTonalIconButtonDefaultsM3(this.context, this.toggleable)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.12);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.secondaryContainer;
      }
      if (toggleable) { // toggleable but unselected case
        return _colors.surfaceContainerHighest;
      }
      return _colors.secondaryContainer;
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.onSecondaryContainer;
      }
      if (toggleable) { // toggleable but unselected case
        return _colors.onSurfaceVariant;
      }
      return _colors.onSecondaryContainer;
    });

 @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSecondaryContainer.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSecondaryContainer.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSecondaryContainer.withOpacity(0.12);
        }
      }
      if (toggleable) { // toggleable but unselected case
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSurfaceVariant.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSurfaceVariant.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSurfaceVariant.withOpacity(0.12);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSecondaryContainer.withOpacity(0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSecondaryContainer.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSecondaryContainer.withOpacity(0.12);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const WidgetStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.all(8.0));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const WidgetStatePropertyAll<Size>(Size(40.0, 40.0));

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const WidgetStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    const WidgetStatePropertyAll<double>(24.0);

  @override
  WidgetStateProperty<BorderSide?>? get side => null;

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
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

// END GENERATED TOKEN PROPERTIES - FilledTonalIconButton

// BEGIN GENERATED TOKEN PROPERTIES - OutlinedIconButton

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _OutlinedIconButtonDefaultsM3 extends ButtonStyle {
  _OutlinedIconButtonDefaultsM3(this.context, this.toggleable)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        if (states.contains(WidgetState.selected)) {
          return _colors.onSurface.withOpacity(0.12);
        }
        return Colors.transparent;
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.inverseSurface;
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.onInverseSurface;
      }
      return _colors.onSurfaceVariant;
    });

 @override
  WidgetStateProperty<Color?>? get overlayColor =>    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onInverseSurface.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onInverseSurface.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onInverseSurface.withOpacity(0.08);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurface.withOpacity(0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurfaceVariant.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurfaceVariant.withOpacity(0.08);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const WidgetStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const WidgetStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.all(8.0));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const WidgetStatePropertyAll<Size>(Size(40.0, 40.0));

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const WidgetStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    const WidgetStatePropertyAll<double>(24.0);

  @override
  WidgetStateProperty<BorderSide?>? get side =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return null;
      } else {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: _colors.onSurface.withOpacity(0.12));
        }
        return BorderSide(color: _colors.outline);
      }
    });

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
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

// END GENERATED TOKEN PROPERTIES - OutlinedIconButton
