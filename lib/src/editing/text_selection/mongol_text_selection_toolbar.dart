// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart'
    show Icons, Material, MaterialType, IconButton;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'mongol_text_selection_toolbar_layout_delegate.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarWidth = 44.0;

/// A fully-functional Material-style text selection toolbar.
///
/// Tries to position itself to the left of [anchorLeft], but if it doesn't fit,
/// then it positions itself to the right of [anchorRight].
///
/// If any children don't fit in the menu, an overflow menu will automatically
/// be created.
///
/// See also:
///
///  * [MongolTextSelectionControls.buildToolbar], where this is used by default to
///    build an Android-style toolbar.
class MongolTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of MongolTextSelectionToolbar.
  const MongolTextSelectionToolbar({
    Key? key,
    required this.anchorLeft,
    required this.anchorRight,
    this.toolbarBuilder = _defaultToolbarBuilder,
    required this.children,
  })  : assert(children.length > 0),
        super(key: key);

  /// The focal point to the left of which the toolbar attempts to position
  /// itself.
  ///
  /// If there is not enough room to the left before reaching the left of the
  /// screen, then the toolbar will position itself to the right of
  /// [anchorRight].
  final Offset anchorLeft;

  /// The focal point to the right of which the toolbar attempts to position
  /// itself, if it doesn't fit to the left of [anchorLeft].
  final Offset anchorRight;

  /// The children that will be displayed in the text selection toolbar.
  ///
  /// Typically these are buttons.
  ///
  /// Must not be empty.
  ///
  /// See also:
  ///   * [MongolTextSelectionToolbarButton], which builds a toolbar button.
  final List<Widget> children;

  /// Builds the toolbar container.
  ///
  /// Useful for customizing the high-level background of the toolbar. The given
  /// child Widget will contain all of the [children].
  final ToolbarBuilder toolbarBuilder;

  // Build the default text selection menu toolbar.
  static Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
    return _TextSelectionToolbarContainer(
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paddingLeft =
        MediaQuery.of(context).padding.left + _kToolbarScreenPadding;
    final availableWidth = anchorLeft.dx - paddingLeft;
    final fitsLeft = _kToolbarWidth <= availableWidth;
    final localAdjustment = Offset(paddingLeft, _kToolbarScreenPadding);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        paddingLeft,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: Stack(
        children: <Widget>[
          CustomSingleChildLayout(
            delegate: MongolTextSelectionToolbarLayoutDelegate(
              anchorLeft: anchorLeft - localAdjustment,
              anchorRight: anchorRight - localAdjustment,
              fitsLeft: fitsLeft,
            ),
            child: _TextSelectionToolbarOverflowable(
              isLeft: fitsLeft,
              toolbarBuilder: toolbarBuilder,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// A toolbar containing the given children. If they overflow the height
// available, then the overflowing children will be displayed in an overflow
// menu.
class _TextSelectionToolbarOverflowable extends StatefulWidget {
  const _TextSelectionToolbarOverflowable({
    Key? key,
    required this.isLeft,
    required this.toolbarBuilder,
    required this.children,
  })  : assert(children.length > 0),
        super(key: key);

  final List<Widget> children;

  // When true, the toolbar fits to the left of its anchor and will be
  // positioned there.
  final bool isLeft;

  // Builds the toolbar that will be populated with the children and fit inside
  // of the layout that adjusts to overflow.
  final ToolbarBuilder toolbarBuilder;

  @override
  _TextSelectionToolbarOverflowableState createState() =>
      _TextSelectionToolbarOverflowableState();
}

class _TextSelectionToolbarOverflowableState
    extends State<_TextSelectionToolbarOverflowable>
    with TickerProviderStateMixin {
  // Whether or not the overflow menu is open. When it is closed, the menu
  // items that don't overflow are shown. When it is open, only the overflowing
  // menu items are shown.
  bool _overflowOpen = false;

  // The key for _TextSelectionToolbarTrailingEdgeAlign.
  UniqueKey _containerKey = UniqueKey();

  // Close the menu and reset layout calculations, as in when the menu has
  // changed and saved values are no longer relevant. This should be called in
  // setState or another context where a rebuild is happening.
  void _reset() {
    // Change _TextSelectionToolbarTrailingEdgeAlign's key when the menu changes in
    // order to cause it to rebuild. This lets it recalculate its
    // saved height for the new set of children, and it prevents AnimatedSize
    // from animating the size change.
    _containerKey = UniqueKey();
    // If the menu items change, make sure the overflow menu is closed. This
    // prevents getting into a broken state where _overflowOpen is true when
    // there are not enough children to cause overflow.
    _overflowOpen = false;
  }

  @override
  void didUpdateWidget(_TextSelectionToolbarOverflowable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the children are changing at all, the current page should be reset.
    if (!listEquals(widget.children, oldWidget.children)) {
      _reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TextSelectionToolbarTrailingEdgeAlign(
      key: _containerKey,
      overflowOpen: _overflowOpen,
      child: AnimatedSize(
        // This duration was eyeballed on a Pixel 2 emulator running Android
        // API 28.
        duration: const Duration(milliseconds: 140),
        child: widget.toolbarBuilder(
            context,
            _TextSelectionToolbarItemsLayout(
              isLeft: widget.isLeft,
              overflowOpen: _overflowOpen,
              children: <Widget>[
                _TextSelectionToolbarOverflowButton(
                  icon:
                      Icon(_overflowOpen ? Icons.arrow_back : Icons.more_horiz),
                  onPressed: () {
                    setState(() {
                      _overflowOpen = !_overflowOpen;
                    });
                  },
                ),
                ...widget.children,
              ],
            )),
      ),
    );
  }
}

// When the overflow menu is open, it tries to align its trailing edge to the
// trailing edge of the closed menu. This widget handles this effect by
// measuring and maintaining the height of the closed menu and aligning the child
// to that side.
class _TextSelectionToolbarTrailingEdgeAlign
    extends SingleChildRenderObjectWidget {
  const _TextSelectionToolbarTrailingEdgeAlign({
    Key? key,
    required Widget child,
    required this.overflowOpen,
  }) : super(key: key, child: child);

  final bool overflowOpen;

  @override
  _TextSelectionToolbarTrailingEdgeAlignRenderBox createRenderObject(
      BuildContext context) {
    return _TextSelectionToolbarTrailingEdgeAlignRenderBox(
      overflowOpen: overflowOpen,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      _TextSelectionToolbarTrailingEdgeAlignRenderBox renderObject) {
    renderObject.overflowOpen = overflowOpen;
  }
}

class _TextSelectionToolbarTrailingEdgeAlignRenderBox extends RenderProxyBox {
  _TextSelectionToolbarTrailingEdgeAlignRenderBox({
    required bool overflowOpen,
  })  : _overflowOpen = overflowOpen,
        super();

  // The height of the menu when it was closed. This is used to achieve the
  // behavior where the open menu aligns its trailing edge to the closed menu's
  // trailing edge.
  double? _closedHeight;

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child!.layout(constraints.loosen(), parentUsesSize: true);

    // Save the height when the menu is closed. If the menu changes, this height
    // is invalid, so it's important that this RenderBox be recreated in that
    // case. Currently, this is achieved by providing a new key to
    // _TextSelectionToolbarTrailingEdgeAlign.
    if (!overflowOpen && _closedHeight == null) {
      _closedHeight = child!.size.height;
    }

    size = constraints.constrain(Size(
      child!.size.width,
      // If the open menu is higher than the closed menu, just use its own height
      // and don't worry about aligning the trailing edges.
      // _closedHeight is used even when the menu is closed to allow it to
      // animate its size while keeping the same edge alignment.
      _closedHeight == null || child!.size.height > _closedHeight!
          ? child!.size.height
          : _closedHeight!,
    ));

    // Set the offset in the parent data such that the child will be aligned to
    // the trailing edge.
    final childParentData = child!.parentData! as ToolbarItemsParentData;
    childParentData.offset = Offset(
      0.0,
      size.height - child!.size.height,
    );
  }

  // Paint at the offset set in the parent data.
  @override
  void paint(PaintingContext context, Offset offset) {
    final childParentData = child!.parentData! as ToolbarItemsParentData;
    context.paintChild(child!, childParentData.offset + offset);
  }

  // Include the parent data offset in the hit test.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // The x, y parameters have the top left of the node's box as the origin.
    final childParentData = child!.parentData! as ToolbarItemsParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child!.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final childParentData = child.parentData! as ToolbarItemsParentData;
    transform.translate(childParentData.offset.dx, childParentData.offset.dy);
    super.applyPaintTransform(child, transform);
  }
}

// Renders the menu items in the correct positions in the menu and its overflow
// submenu based on calculating which item would first overflow.
class _TextSelectionToolbarItemsLayout extends MultiChildRenderObjectWidget {
  const _TextSelectionToolbarItemsLayout({
    Key? key,
    required this.isLeft,
    required this.overflowOpen,
    required List<Widget> children,
  }) : super(key: key, children: children);

  final bool isLeft;
  final bool overflowOpen;

  @override
  _RenderTextSelectionToolbarItemsLayout createRenderObject(
      BuildContext context) {
    return _RenderTextSelectionToolbarItemsLayout(
      isLeft: isLeft,
      overflowOpen: overflowOpen,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      _RenderTextSelectionToolbarItemsLayout renderObject) {
    renderObject
      ..isLeft = isLeft
      ..overflowOpen = overflowOpen;
  }

  @override
  _TextSelectionToolbarItemsLayoutElement createElement() =>
      _TextSelectionToolbarItemsLayoutElement(this);
}

class _TextSelectionToolbarItemsLayoutElement
    extends MultiChildRenderObjectElement {
  _TextSelectionToolbarItemsLayoutElement(
    MultiChildRenderObjectWidget widget,
  ) : super(widget);

  static bool _shouldPaint(Element child) {
    return (child.renderObject!.parentData! as ToolbarItemsParentData)
        .shouldPaint;
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where(_shouldPaint).forEach(visitor);
  }
}

class _RenderTextSelectionToolbarItemsLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ToolbarItemsParentData> {
  _RenderTextSelectionToolbarItemsLayout({
    required bool isLeft,
    required bool overflowOpen,
  })  : _isLeft = isLeft,
        _overflowOpen = overflowOpen,
        super();

  // The index of the last item that doesn't overflow.
  int _lastIndexThatFits = -1;

  bool _isLeft;
  bool get isLeft => _isLeft;
  set isLeft(bool value) {
    if (value == isLeft) {
      return;
    }
    _isLeft = value;
    markNeedsLayout();
  }

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  // Layout the necessary children, and figure out where the children first
  // overflow, if at all.
  void _layoutChildren() {
    // When overflow is not open, the toolbar is always a specific width.
    final sizedConstraints = _overflowOpen
        ? constraints
        : BoxConstraints.loose(Size(
            _kToolbarWidth,
            constraints.maxHeight,
          ));

    var i = -1;
    var height = 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      // No need to layout children inside the overflow menu when it's closed.
      // The opposite is not true. It is necessary to layout the children that
      // don't overflow when the overflow menu is open in order to calculate
      // _lastIndexThatFits.
      if (_lastIndexThatFits != -1 && !overflowOpen) {
        return;
      }

      final child = renderObjectChild as RenderBox;
      child.layout(sizedConstraints.loosen(), parentUsesSize: true);
      height += child.size.height;

      if (height > sizedConstraints.maxHeight && _lastIndexThatFits == -1) {
        _lastIndexThatFits = i - 1;
      }
    });

    // If the last child overflows, but only because of the height of the
    // overflow button, then just show it and hide the overflow button.
    final navButton = firstChild!;
    if (_lastIndexThatFits != -1 &&
        _lastIndexThatFits == childCount - 2 &&
        height - navButton.size.height <= sizedConstraints.maxHeight) {
      _lastIndexThatFits = -1;
    }
  }

  // Returns true when the child should be painted, false otherwise.
  bool _shouldPaintChild(RenderObject renderObjectChild, int index) {
    // Paint the navButton when there is overflow.
    if (renderObjectChild == firstChild) {
      return _lastIndexThatFits != -1;
    }

    // If there is no overflow, all children besides the navButton are painted.
    if (_lastIndexThatFits == -1) {
      return true;
    }

    // When there is overflow, paint if the child is in the part of the menu
    // that is currently open. Overflowing children are painted when the
    // overflow menu is open, and the children that fit are painted when the
    // overflow menu is closed.
    return (index > _lastIndexThatFits) == overflowOpen;
  }

  // Decide which children will be painted, set their shouldPaint, and set the
  // offset that painted children will be placed at.
  void _placeChildren() {
    var i = -1;
    var nextSize = const Size(0.0, 0.0);
    var fitHeight = 0.0;
    final navButton = firstChild!;
    var overflowWidth = overflowOpen && !isLeft ? navButton.size.width : 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      final child = renderObjectChild as RenderBox;
      final childParentData = child.parentData! as ToolbarItemsParentData;

      // Handle placing the navigation button after iterating all children.
      if (renderObjectChild == navButton) {
        return;
      }

      // There is no need to place children that won't be painted.
      if (!_shouldPaintChild(renderObjectChild, i)) {
        childParentData.shouldPaint = false;
        return;
      }
      childParentData.shouldPaint = true;

      if (!overflowOpen) {
        childParentData.offset = Offset(0.0, fitHeight);
        fitHeight += child.size.height;
        nextSize = Size(
          math.max(child.size.width, nextSize.width),
          fitHeight,
        );
      } else {
        childParentData.offset = Offset(overflowWidth, 0.0);
        overflowWidth += child.size.width;
        nextSize = Size(
          overflowWidth,
          math.max(child.size.height, nextSize.height),
        );
      }
    });

    // Place the navigation button if needed.
    final navButtonParentData = navButton.parentData! as ToolbarItemsParentData;
    if (_shouldPaintChild(firstChild!, 0)) {
      navButtonParentData.shouldPaint = true;
      if (overflowOpen) {
        navButtonParentData.offset =
            isLeft ? Offset(overflowWidth, 0.0) : Offset.zero;
        nextSize = Size(
          isLeft ? nextSize.width + navButton.size.width : nextSize.width,
          nextSize.height,
        );
      } else {
        navButtonParentData.offset = Offset(0.0, fitHeight);
        nextSize =
            Size(nextSize.width, nextSize.height + navButton.size.height);
      }
    } else {
      navButtonParentData.shouldPaint = false;
    }

    size = nextSize;
  }

  @override
  void performLayout() {
    _lastIndexThatFits = -1;
    if (firstChild == null) {
      size = constraints.smallest;
      return;
    }

    _layoutChildren();
    _placeChildren();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((RenderObject renderObjectChild) {
      final child = renderObjectChild as RenderBox;
      final childParentData = child.parentData! as ToolbarItemsParentData;
      if (!childParentData.shouldPaint) {
        return;
      }

      context.paintChild(child, childParentData.offset + offset);
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // The x, y parameters have the top left of the node's box as the origin.
    var child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as ToolbarItemsParentData;

      // Don't hit test children aren't shown.
      if (!childParentData.shouldPaint) {
        child = childParentData.previousSibling;
        continue;
      }

      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  // Visit only the children that should be painted.
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren((RenderObject renderObjectChild) {
      final child = renderObjectChild as RenderBox;
      final childParentData = child.parentData! as ToolbarItemsParentData;
      if (childParentData.shouldPaint) {
        visitor(renderObjectChild);
      }
    });
  }
}

// The Material-styled toolbar outline. Fill it with any widgets you want. No
// overflow ability.
class _TextSelectionToolbarContainer extends StatelessWidget {
  const _TextSelectionToolbarContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      // This value was eyeballed to match the native text selection menu on
      // a Pixel 2 running Android 10.
      borderRadius: const BorderRadius.all(Radius.circular(7.0)),
      clipBehavior: Clip.antiAlias,
      elevation: 1.0,
      type: MaterialType.card,
      child: child,
    );
  }
}

// A button styled like a Material native Android text selection overflow menu
// forward and back controls.
class _TextSelectionToolbarOverflowButton extends StatelessWidget {
  const _TextSelectionToolbarOverflowButton({
    Key? key,
    required this.icon,
    this.onPressed,
    // ignore: unused_element
    this.tooltip,
  }) : super(key: key);

  final Icon icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.card,
      color: const Color(0x00000000),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
