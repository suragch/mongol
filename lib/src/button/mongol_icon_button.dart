// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart'
    show
        IconButton,
        VisualDensity,
        debugCheckHasMaterial,
        ThemeData,
        Theme,
        Material,
        kMinInteractiveDimension,
        InkResponse;
import 'package:flutter/widgets.dart';

import '../menu/mongol_tooltip.dart';

// Minimum logical pixel size of the IconButton.
// See: <https://material.io/design/usability/accessibility.html#layout-typography>.
const double _kMinButtonSize = kMinInteractiveDimension;

/// An IconButton that uses a MongolTooltip
///
/// Everything else about this widget except for the tooltip should behave
/// exactly like IconButton.
class MongolIconButton extends IconButton {
  const MongolIconButton({
    Key? key,
    double iconSize = 24.0,
    VisualDensity? visualDensity,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    AlignmentGeometry alignment = Alignment.center,
    double? splashRadius,
    Color? color,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    Color? disabledColor,
    required void Function()? onPressed,
    MouseCursor mouseCursor = SystemMouseCursors.click,
    FocusNode? focusNode,
    bool autofocus = false,
    this.mongolTooltip,
    bool enableFeedback = true,
    BoxConstraints? constraints,
    required Widget icon,
  })  : assert(splashRadius == null || splashRadius > 0),
        super(
          key: key,
          iconSize: iconSize,
          visualDensity: visualDensity,
          padding: padding,
          alignment: alignment,
          splashRadius: splashRadius,
          color: color,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          disabledColor: disabledColor,
          onPressed: onPressed,
          mouseCursor: mouseCursor,
          focusNode: focusNode,
          autofocus: autofocus,
          tooltip: mongolTooltip,
          enableFeedback: enableFeedback,
          constraints: constraints,
          icon: icon,
        );

  /// Mongolian text that describes the action that will occur when the button
  /// is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String? mongolTooltip;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
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

    Widget result = ConstrainedBox(
      constraints: adjustedConstraints,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: SizedBox(
          height: iconSize,
          width: iconSize,
          child: Align(
            alignment: alignment ?? Alignment.center,
            child: IconTheme.merge(
              data: IconThemeData(
                size: iconSize,
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
        mouseCursor: mouseCursor,
        enableFeedback: enableFeedback ?? true,
        focusColor: focusColor ?? theme.focusColor,
        hoverColor: hoverColor ?? theme.hoverColor,
        highlightColor: highlightColor ?? theme.highlightColor,
        splashColor: splashColor ?? theme.splashColor,
        radius: splashRadius ??
            math.max(
              Material.defaultSplashRadius,
              ((iconSize ?? 24) +
                      math.min(
                        padding?.horizontal ?? 0,
                        padding?.vertical ?? 0,
                      )) *
                  0.7,
              // x 0.5 for diameter -> radius and + 40% overflow derived from other Material apps.
            ),
        child: result,
      ),
    );
  }
}
