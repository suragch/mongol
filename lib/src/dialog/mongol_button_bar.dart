// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// These classes were adapted from Flutter [ButtonBar]

class MongolButtonBar extends StatelessWidget {
  const MongolButtonBar({
    Key? key,
    this.alignment,
    this.mainAxisSize,
    this.buttonTextTheme,
    this.buttonMinWidth,
    this.buttonHeight,
    this.buttonPadding,
    this.layoutBehavior,
    this.children = const <Widget>[],
  })  : assert(buttonMinWidth == null || buttonMinWidth >= 0.0),
        assert(buttonHeight == null || buttonHeight >= 0.0),
        super(key: key);

  /// How the children should be placed along the vertical axis.
  ///
  /// If null then it will use [ButtonBarTheme.alignment]. If that is null,
  /// it will default to [MainAxisAlignment.end].
  final MainAxisAlignment? alignment;

  /// How much horizontal space is available. See [Column.mainAxisSize].
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.mainAxisSize].
  /// If that is null, it will default to [MainAxisSize.max].
  final MainAxisSize? mainAxisSize;

  final ButtonTextTheme? buttonTextTheme;

  final double? buttonMinWidth;

  final double? buttonHeight;

  final EdgeInsetsGeometry? buttonPadding;

  final ButtonBarLayoutBehavior? layoutBehavior;

  /// The buttons to arrange horizontally.
  ///
  /// Typically [ElevatedButton] or [TextButton] widgets using [MongolText].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final parentButtonTheme = ButtonTheme.of(context);
    final barTheme = ButtonBarTheme.of(context);

    final buttonTheme = parentButtonTheme.copyWith(
      textTheme: buttonTextTheme ??
          barTheme.buttonTextTheme ??
          ButtonTextTheme.primary,
      minWidth: buttonMinWidth ?? barTheme.buttonMinWidth ?? 36.0,
      height: buttonHeight ?? barTheme.buttonHeight ?? 64.0,
      padding: buttonPadding ??
          barTheme.buttonPadding ??
          const EdgeInsets.symmetric(vertical: 8.0),
      alignedDropdown: false,
      layoutBehavior: layoutBehavior ??
          barTheme.layoutBehavior ??
          ButtonBarLayoutBehavior.padded,
    );

    final paddingUnit = buttonTheme.padding.vertical / 4.0;
    final Widget child = ButtonTheme.fromButtonThemeData(
      data: buttonTheme,
      child: _ButtonBarColumn(
        mainAxisAlignment:
            alignment ?? barTheme.alignment ?? MainAxisAlignment.end,
        mainAxisSize: mainAxisSize ?? barTheme.mainAxisSize ?? MainAxisSize.max,
        children: children.map<Widget>((Widget child) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: paddingUnit),
            child: child,
          );
        }).toList(),
      ),
    );
    switch (buttonTheme.layoutBehavior) {
      case ButtonBarLayoutBehavior.padded:
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 2.0 * paddingUnit,
            vertical: paddingUnit,
          ),
          child: child,
        );
      default: // ButtonBarLayoutBehavior.constrained:
        return Container(
          padding: EdgeInsets.symmetric(vertical: paddingUnit),
          constraints: const BoxConstraints(minWidth: 52.0),
          alignment: Alignment.center,
          child: child,
        );
    }
  }
}

class _ButtonBarColumn extends Flex {
  /// Creates a button bar that attempts to display in a column, but displays in
  /// a row if there is insufficient vertical space.
  const _ButtonBarColumn({
    required List<Widget> children,
    Axis direction = Axis.vertical,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(
          children: children,
          direction: direction,
          mainAxisSize: mainAxisSize,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
        );

  @override
  _RenderButtonBarColumn createRenderObject(BuildContext context) {
    return _RenderButtonBarColumn(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderButtonBarColumn renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment;
  }
}

class _RenderButtonBarColumn extends RenderFlex {
  _RenderButtonBarColumn({
    List<RenderBox>? children,
    Axis direction = Axis.vertical,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(
          children: children,
          direction: direction,
          mainAxisSize: mainAxisSize,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
        );

  bool _hasCheckedLayoutHeight = false;

  @override
  BoxConstraints get constraints {
    if (_hasCheckedLayoutHeight) return super.constraints;
    return super.constraints.copyWith(maxHeight: double.infinity);
  }

  @override
  void performLayout() {
    _hasCheckedLayoutHeight = false;

    super.performLayout();
    _hasCheckedLayoutHeight = true;

    if (size.height <= constraints.maxHeight) {
      super.performLayout();
    } else {
      final childConstraints = constraints.copyWith(minHeight: 0.0);
      RenderBox? child;
      var currentWidth = 0.0;
      child = firstChild;

      while (child != null) {
        final childParentData = child.parentData as FlexParentData;
        child.layout(childConstraints, parentUsesSize: true);
        switch (mainAxisAlignment) {
          case MainAxisAlignment.center:
            final midpoint = (constraints.maxHeight - child.size.height) / 2.0;
            childParentData.offset = Offset(midpoint, currentWidth);
            break;
          case MainAxisAlignment.end:
            childParentData.offset =
                Offset(constraints.maxHeight - child.size.height, currentWidth);
            break;
          default:
            childParentData.offset = Offset(0, currentWidth);
            break;
        }
        currentWidth += child.size.width;
        child = childParentData.nextSibling;
      }
      size = constraints.constrain(Size(constraints.maxHeight, currentWidth));
    }
  }
}
