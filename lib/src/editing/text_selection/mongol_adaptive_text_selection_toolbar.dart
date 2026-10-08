// Copyright 2014 The Flutter Authors.
// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../text/mongol_text.dart';
import '../mongol_editable_text.dart';
import 'mongol_text_selection_toolbar.dart';
import 'mongol_text_selection_toolbar_button.dart';

/// The default context menu for text selection in vertical Mongolian text.
///
/// This is the Mongol counterpart of Flutter's `AdaptiveTextSelectionToolbar`.
/// It lays its buttons out vertically beside the selected line and uses icons
/// rather than text labels so that the menu does not depend on Mongolian font
/// support in the toolbar.
///
/// See also:
///
///  * [MongolEditableText.contextMenuBuilder], which builds this by default.
///  * [MongolTextSelectionToolbar], the toolbar widget used underneath.
class MongolAdaptiveTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [MongolAdaptiveTextSelectionToolbar] with the
  /// given [children].
  ///
  /// See also:
  ///
  ///  * [MongolAdaptiveTextSelectionToolbar.buttonItems], which takes a list
  ///    of [ContextMenuButtonItem]s instead of widgets.
  ///  * [MongolAdaptiveTextSelectionToolbar.editableText], which builds the
  ///    default buttons for a [MongolEditableText].
  const MongolAdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.anchors,
  }) : buttonItems = null;

  /// Create an instance of [MongolAdaptiveTextSelectionToolbar] whose
  /// children are built from the given [buttonItems].
  const MongolAdaptiveTextSelectionToolbar.buttonItems({
    super.key,
    required this.buttonItems,
    required this.anchors,
  }) : children = null;

  /// Create an instance of [MongolAdaptiveTextSelectionToolbar] with the
  /// default children for a [MongolEditableText].
  ///
  /// The buttons come from [MongolEditableTextState.contextMenuButtonItems]
  /// and the position from [MongolEditableTextState.contextMenuAnchors].
  MongolAdaptiveTextSelectionToolbar.editableText({
    super.key,
    required MongolEditableTextState editableTextState,
  }) : children = null,
       buttonItems = editableTextState.contextMenuButtonItems,
       anchors = editableTextState.contextMenuAnchors;

  /// The children of the toolbar, typically buttons.
  ///
  /// Exactly one of [children] or [buttonItems] is non-null.
  final List<Widget>? children;

  /// The [ContextMenuButtonItem]s that the toolbar's buttons are built from.
  ///
  /// Exactly one of [children] or [buttonItems] is non-null.
  final List<ContextMenuButtonItem>? buttonItems;

  /// The location on which to anchor the menu.
  ///
  /// The primary anchor is to the left of the selection and the secondary
  /// anchor, used when the menu does not fit on the left, is to its right.
  final TextSelectionToolbarAnchors anchors;

  /// Returns the icon shown for the given [ContextMenuButtonItem], or null
  /// for a [ContextMenuButtonType.custom] item, which shows its label instead.
  static IconData? getButtonIcon(ContextMenuButtonItem buttonItem) {
    return switch (buttonItem.type) {
      ContextMenuButtonType.cut => Icons.cut,
      ContextMenuButtonType.copy => Icons.copy,
      ContextMenuButtonType.paste => Icons.paste,
      ContextMenuButtonType.selectAll => Icons.select_all,
      ContextMenuButtonType.delete => Icons.delete,
      ContextMenuButtonType.lookUp => Icons.search,
      ContextMenuButtonType.searchWeb => Icons.travel_explore,
      ContextMenuButtonType.share => Icons.share,
      ContextMenuButtonType.liveTextInput => Icons.document_scanner,
      ContextMenuButtonType.custom => null,
    };
  }

  /// Returns the toolbar buttons for the given [buttonItems].
  static List<Widget> getButtons(List<ContextMenuButtonItem> buttonItems) {
    return <Widget>[
      for (var i = 0; i < buttonItems.length; i++)
        MongolTextSelectionToolbarButton(
          padding: MongolTextSelectionToolbarButton.getPadding(
            i,
            buttonItems.length,
          ),
          onPressed: buttonItems[i].onPressed,
          child: _buttonChild(buttonItems[i]),
        ),
    ];
  }

  static Widget _buttonChild(ContextMenuButtonItem buttonItem) {
    final IconData? icon = getButtonIcon(buttonItem);
    if (icon != null) {
      return Icon(icon);
    }
    return MongolText(buttonItem.label ?? '');
  }

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if ((children ?? buttonItems)?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return MongolTextSelectionToolbar(
      anchorLeft: anchors.primaryAnchor,
      anchorRight: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      children: children ?? getButtons(buttonItems!),
    );
  }
}
