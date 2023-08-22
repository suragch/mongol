// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Theme, TextSelectionTheme, Icons;
import 'package:flutter/widgets.dart';

import 'mongol_text_selection_toolbar.dart';
import 'mongol_text_selection_toolbar_button.dart';

// https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/material/text_selection.dart
// This file builds the Copy/Paste toolbar that pops up when you long click, etc.
// If you want a different style you can replace this class with another one.
// That's what Flutter does to give a different style for Material, Cupertino
// and others.

const double _kHandleSize = 22.0;

// Padding between the toolbar and the anchor.
const double _kToolbarContentDistanceRight = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;

/// Mongol styled text selection controls. (Adapted from Android Material version)
///
/// In order to avoid Mongolian Unicode and font issues, the text editing
/// controls use icons rather than text for the copy/cut/past/select buttons.
class MongolTextSelectionControls extends TextSelectionControls {
  /// Returns the size of the handle.
  @override
  Size getHandleSize(double textLineWidth) =>
      const Size(_kHandleSize, _kHandleSize);

  /// Builder for Mongol copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineWidth,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _TextSelectionControlsToolbar(
      globalEditableRegion: globalEditableRegion,
      textLineWidth: textLineWidth,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
    );
  }

  /// Builder for material-style text selection handles.
  ///
  /// Width and height terms are in vertical text layout context
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textLineWidth,
      [VoidCallback? onTap, double? startGlyphWidth, double? endGlyphWidth]) {
    final theme = Theme.of(context);
    final handleColor = TextSelectionTheme.of(context).selectionHandleColor ??
        theme.colorScheme.primary;
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          color: handleColor,
        ),
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // down-right, up-left, or left depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points down-right
        return Transform.rotate(
          angle: math.pi,
          child: handle,
        );
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points left
        return Transform.rotate(
          angle: -math.pi / 4.0,
          child: handle,
        );
    }
  }

  /// Gets anchor for material-style text selection handles.
  ///
  /// Width and height terms are in vertical text layout context.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineWidth,
      [double? startGlyphWidth, double? endGlyphWidth]) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, _kHandleSize);
      case TextSelectionHandleType.right:
        return Offset.zero;
      default:
        return const Offset(-4, _kHandleSize / 2);
    }
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // Android allows SelectAll when selection is not collapsed, unless
    // everything has already been selected.
    final value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
        value.text.isNotEmpty &&
        !(value.selection.start == 0 &&
            value.selection.end == value.text.length);
  }
}

// The label and callback for the available default text selection menu buttons.
class _TextSelectionToolbarItemData {
  const _TextSelectionToolbarItemData({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;
}

// The highest level toolbar widget, built directly by buildToolbar.
class _TextSelectionControlsToolbar extends StatefulWidget {
  const _TextSelectionControlsToolbar({
    Key? key,
    required this.clipboardStatus,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCut,
    required this.handleCopy,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineWidth,
  }) : super(key: key);

  final ValueListenable<ClipboardStatus>? clipboardStatus;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCut;
  final VoidCallback? handleCopy;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final Offset selectionMidpoint;
  final double textLineWidth;

  @override
  _TextSelectionControlsToolbarState createState() =>
      _TextSelectionControlsToolbarState();
}

class _TextSelectionControlsToolbarState
    extends State<_TextSelectionControlsToolbar> with TickerProviderStateMixin {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
  }

  @override
  void didUpdateWidget(_TextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  void dispose() {
    widget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If there are no buttons to be shown, don't render anything.
    if (widget.handleCut == null &&
        widget.handleCopy == null &&
        widget.handlePaste == null &&
        widget.handleSelectAll == null) {
      return const SizedBox.shrink();
    }
    // If the paste button is desired, don't render anything until the state of
    // the clipboard is known, since it's used to determine if paste is shown.
    if (widget.handlePaste != null &&
        widget.clipboardStatus?.value == ClipboardStatus.unknown) {
      return const SizedBox.shrink();
    }

    // Calculate the positioning of the menu. It is placed to the left of the
    // selection if there is enough room, or otherwise to the right.
    final startTextSelectionPoint = widget.endpoints[0];
    final endTextSelectionPoint =
        widget.endpoints.length > 1 ? widget.endpoints[1] : widget.endpoints[0];
    final anchorLeft = Offset(
        widget.globalEditableRegion.left +
            startTextSelectionPoint.point.dx -
            widget.textLineWidth -
            _kToolbarContentDistance,
        widget.globalEditableRegion.top + widget.selectionMidpoint.dy);
    final anchorRight = Offset(
        widget.globalEditableRegion.left +
            endTextSelectionPoint.point.dx +
            _kToolbarContentDistanceRight,
        widget.globalEditableRegion.top + widget.selectionMidpoint.dy);

    // Determine which buttons will appear so that the order and total number is
    // known.
    final itemData = <_TextSelectionToolbarItemData>[
      if (widget.handleCut != null)
        _TextSelectionToolbarItemData(
          icon: Icons.cut,
          onPressed: widget.handleCut!,
        ),
      if (widget.handleCopy != null)
        _TextSelectionToolbarItemData(
          icon: Icons.copy,
          onPressed: widget.handleCopy!,
        ),
      if (widget.handlePaste != null &&
          widget.clipboardStatus?.value == ClipboardStatus.pasteable)
        _TextSelectionToolbarItemData(
          icon: Icons.paste,
          onPressed: widget.handlePaste!,
        ),
      if (widget.handleSelectAll != null)
        _TextSelectionToolbarItemData(
          icon: Icons.select_all,
          onPressed: widget.handleSelectAll!,
        ),
    ];

    // If there is no option available, build an empty widget.
    if (itemData.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return MongolTextSelectionToolbar(
      anchorLeft: anchorLeft,
      anchorRight: anchorRight,
      children: itemData
          .asMap()
          .entries
          .map((MapEntry<int, _TextSelectionToolbarItemData> entry) {
        return MongolTextSelectionToolbarButton(
          padding: MongolTextSelectionToolbarButton.getPadding(
              entry.key, itemData.length),
          onPressed: entry.value.onPressed,
          child: Icon(entry.value.icon),
        );
      }).toList(),
    );
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
    final circle =
        Rect.fromCircle(center: Offset(radius, radius), radius: radius);
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

/// Text selection controls that follow the Material Design specification.
final TextSelectionControls mongolTextSelectionControls =
    MongolTextSelectionControls();
