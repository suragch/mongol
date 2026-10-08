// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Theme, TextSelectionTheme;
import 'package:flutter/widgets.dart';

// https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/material/text_selection.dart
// This file draws the selection handles. The copy/paste toolbar that pops up
// when you long press is built separately by MongolEditableText's
// contextMenuBuilder (MongolAdaptiveTextSelectionToolbar by default).

const double _kHandleSize = 22.0;

/// Mongol styled text selection handle controls. (Adapted from Android
/// Material version)
///
/// Specifically does not manage the toolbar, which is left to
/// [MongolEditableText.contextMenuBuilder].
class MongolTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  /// Returns the size of the handle.
  @override
  Size getHandleSize(double textLineWidth) =>
      const Size(_kHandleSize, _kHandleSize);

  /// Builder for material-style text selection handles.
  ///
  /// Width and height terms are in vertical text layout context
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineWidth, [
    VoidCallback? onTap,
    double? startGlyphWidth,
    double? endGlyphWidth,
  ]) {
    final theme = Theme.of(context);
    final handleColor =
        TextSelectionTheme.of(context).selectionHandleColor ??
        theme.colorScheme.primary;
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(color: handleColor),
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // down-right, up-left, or left depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points down-right
        return Transform.rotate(angle: math.pi, child: handle);
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points left
        return Transform.rotate(angle: -math.pi / 4.0, child: handle);
    }
  }

  /// Gets anchor for material-style text selection handles.
  ///
  /// Width and height terms are in vertical text layout context.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(
    TextSelectionHandleType type,
    double textLineWidth, [
    double? startGlyphWidth,
    double? endGlyphWidth,
  ]) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, _kHandleSize);
      case TextSelectionHandleType.right:
        return Offset.zero;
      default:
        return const Offset(-4, _kHandleSize / 2);
    }
  }
}

/// Draws a single text selection handle which points up and to the left.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.width / 2.0;
    final circle = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );
    final point = Rect.fromLTWH(0.0, 0.0, radius, radius);
    final path = Path()
      ..addOval(circle)
      ..addRect(point);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}

/// Text selection handle controls for vertical Mongolian text.
///
/// These leave the context menu to [MongolEditableText.contextMenuBuilder].
/// [MongolTextField] uses this by default.
final TextSelectionControls mongolTextSelectionControls =
    MongolTextSelectionControls();
