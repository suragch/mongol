// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, defaultTargetPlatform, listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show kMinInteractiveDimension;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart' show HapticFeedback;
export 'package:flutter/services.dart' show TextSelectionDelegate;
import 'package:flutter/widgets.dart';

import '../mongol_editable_text.dart';
import '../mongol_render_editable.dart';

/// The text position that a give selection handle manipulates. Dragging the
/// [start] handle always moves the [start]/[baseOffset] of the selection.
enum _TextSelectionHandlePosition { start, end }

/// An object that manages a pair of text selection handles.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class MongolTextSelectionOverlay {
  /// Creates an object that manages overlay entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  MongolTextSelectionOverlay({
    required TextEditingValue value,
    required this.context,
    Widget? debugRequiredFor,
    required LayerLink toolbarLayerLink,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    required this.renderObject,
    this.selectionControls,
    bool handlesVisible = false,
    required this.selectionDelegate,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    VoidCallback? onSelectionHandleTapped,
    ClipboardStatusNotifier? clipboardStatus,
    this.contextMenuBuilder,
    required TextMagnifierConfiguration magnifierConfiguration,
  })  : _handlesVisible = handlesVisible,
        _value = value {
    renderObject.selectionStartInViewport
        .addListener(_updateTextSelectionOverlayVisibilities);
    renderObject.selectionEndInViewport
        .addListener(_updateTextSelectionOverlayVisibilities);
    _updateTextSelectionOverlayVisibilities();
    _selectionOverlay = MongolSelectionOverlay(
      magnifierConfiguration: magnifierConfiguration,
      context: context,
      debugRequiredFor: debugRequiredFor,
      // The metrics will be set when show handles.
      startHandleType: TextSelectionHandleType.collapsed,
      startHandlesVisible: _effectiveStartHandleVisibility,
      lineWidthAtStart: 0.0,
      onStartHandleDragStart: _handleSelectionStartHandleDragStart,
      onStartHandleDragUpdate: _handleSelectionStartHandleDragUpdate,
      onEndHandleDragEnd: _handleAnyDragEnd,
      endHandleType: TextSelectionHandleType.collapsed,
      endHandlesVisible: _effectiveEndHandleVisibility,
      lineWidthAtEnd: 0.0,
      onEndHandleDragStart: _handleSelectionEndHandleDragStart,
      onEndHandleDragUpdate: _handleSelectionEndHandleDragUpdate,
      onStartHandleDragEnd: _handleAnyDragEnd,
      toolbarVisible: _effectiveToolbarVisibility,
      selectionEndpoints: const <TextSelectionPoint>[],
      selectionControls: selectionControls,
      selectionDelegate: selectionDelegate,
      clipboardStatus: clipboardStatus,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      toolbarLayerLink: toolbarLayerLink,
      onSelectionHandleTapped: onSelectionHandleTapped,
      dragStartBehavior: dragStartBehavior,
      toolbarLocation: renderObject.lastSecondaryTapDownPosition,
    );
  }

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;

  /// Controls the fade-in and fade-out animations for the toolbar and handles.
  @Deprecated('Use `SelectionOverlay.fadeDuration` instead. '
      'This feature was deprecated after v2.12.0-4.1.pre.')
  static const Duration fadeDuration = SelectionOverlay.fadeDuration;

  /// The editable line in which the selected text is being displayed.
  final MongolRenderEditable renderObject;

  /// Builds text selection handles and toolbar.
  final TextSelectionControls? selectionControls;

  /// The delegate for manipulating the current selection in the owning
  /// text field.
  final TextSelectionDelegate selectionDelegate;

  late final MongolSelectionOverlay _selectionOverlay;

  /// Builds the text selection toolbar when requested by the user.
  ///
  /// `primaryAnchor` is the desired anchor position for the context menu, while
  /// `secondaryAnchor` is the fallback location if the menu doesn't fit.
  ///
  /// `buttonItems` represents the buttons that would be built by default for
  /// this widget.
  ///
  /// If not provided, no context menu will be built.
  final WidgetBuilder? contextMenuBuilder;

  /// Retrieve current value.
  @visibleForTesting
  TextEditingValue get value => _value;

  TextEditingValue _value;

  TextSelection get _selection => _value.selection;

  final ValueNotifier<bool> _effectiveStartHandleVisibility =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _effectiveEndHandleVisibility =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _effectiveToolbarVisibility =
      ValueNotifier<bool>(false);

  void _updateTextSelectionOverlayVisibilities() {
    _effectiveStartHandleVisibility.value =
        _handlesVisible && renderObject.selectionStartInViewport.value;
    _effectiveEndHandleVisibility.value =
        _handlesVisible && renderObject.selectionEndInViewport.value;
    _effectiveToolbarVisibility.value =
        renderObject.selectionStartInViewport.value ||
            renderObject.selectionEndInViewport.value;
  }

  /// Whether selection handles are visible.
  ///
  /// Set to false if you want to hide the handles. Use this property to show or
  /// hide the handle without rebuilding them.
  ///
  /// Defaults to false.
  bool get handlesVisible => _handlesVisible;
  bool _handlesVisible = false;
  set handlesVisible(bool visible) {
    assert(visible != null);
    if (_handlesVisible == visible) {
      return;
    }
    _handlesVisible = visible;
    _updateTextSelectionOverlayVisibilities();
  }

  /// Builds the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    _updateSelectionOverlay();
    _selectionOverlay.showHandles();
  }

  /// Destroys the handles by removing them from overlay.
  void hideHandles() => _selectionOverlay.hideHandles();

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar() {
    _updateSelectionOverlay();

    if (selectionControls is! TextSelectionHandleControls) {
      _selectionOverlay.showToolbar();
      return;
    }

    if (contextMenuBuilder == null) {
      return;
    }

    assert(context.mounted);
    _selectionOverlay.showToolbar(
      context: context,
      contextMenuBuilder: contextMenuBuilder,
    );
    return;
  }

  /// Shows the magnifier, and hides the toolbar if it was showing when
  /// [showMagnifier] was called. This is safe to call on platforms not mobile,
  /// since a magnifierBuilder will not be provided, or the magnifierBuilder
  /// will return null on platforms not mobile.
  ///
  /// This is NOT the source of truth for if the magnifier is up or not,
  /// since magnifiers may hide themselves. If this info is needed, check
  /// [MagnifierController.shown].
  void showMagnifier(Offset positionToShow) {
    final TextPosition position =
        renderObject.getPositionForPoint(positionToShow);
    _updateSelectionOverlay();
    _selectionOverlay.showMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: positionToShow,
        renderEditable: renderObject,
      ),
    );
  }

  /// Update the current magnifier with new selection data, so the magnifier
  /// can respond accordingly.
  ///
  /// If the magnifier is not shown, this still updates the magnifier position
  /// because the magnifier may have hidden itself and is looking for a cue to
  /// reshow itself.
  ///
  /// If there is no magnifier in the overlay, this does nothing.
  void updateMagnifier(Offset positionToShow) {
    final TextPosition position =
        renderObject.getPositionForPoint(positionToShow);
    _updateSelectionOverlay();
    _selectionOverlay.updateMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: positionToShow,
        renderEditable: renderObject,
      ),
    );
  }

  /// Hide the current magnifier.
  ///
  /// This does nothing if there is no magnifier.
  void hideMagnifier() {
    _selectionOverlay.hideMagnifier();
  }

  /// Updates the overlay after the selection has changed.
  ///
  /// If this method is called while the [SchedulerBinding.schedulerPhase] is
  /// [SchedulerPhase.persistentCallbacks], i.e. during the build, layout, or
  /// paint phases (see [WidgetsBinding.drawFrame]), then the update is delayed
  /// until the post-frame callbacks phase. Otherwise the update is done
  /// synchronously. This means that it is safe to call during builds, but also
  /// that if you do call this during a build, the UI will not update until the
  /// next frame (i.e. many milliseconds later).
  void update(TextEditingValue newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    _updateSelectionOverlay();
    // _updateSelectionOverlay may not rebuild the selection overlay if the
    // text metrics and selection doesn't change even if the text has changed.
    // This rebuild is needed for the toolbar to update based on the latest text
    // value.
    _selectionOverlay.markNeedsBuild();
  }

  void _updateSelectionOverlay() {
    _selectionOverlay
      // Update selection handle metrics.
      ..startHandleType = TextSelectionHandleType.left
      ..lineWidthAtStart = _getStartGlyphWidth()
      ..endHandleType = TextSelectionHandleType.right
      ..lineWidthAtEnd = _getEndGlyphWidth()
      // Update selection toolbar metrics.
      ..selectionEndpoints = renderObject.getEndpointsForSelection(_selection)
      ..toolbarLocation = renderObject.lastSecondaryTapDownPosition;
  }

  /// Causes the overlay to update its rendering.
  ///
  /// This is intended to be called when the [renderObject] may have changed its
  /// text metrics (e.g. because the text was scrolled).
  void updateForScroll() {
    _updateSelectionOverlay();
    // This method may be called due to windows metrics changes. In that case,
    // non of the properties in _selectionOverlay will change, but a rebuild is
    // still needed.
    _selectionOverlay.markNeedsBuild();
  }

  /// Whether the handles are currently visible.
  bool get handlesAreVisible =>
      _selectionOverlay._handles != null && handlesVisible;

  /// Whether the toolbar is currently visible.
  bool get toolbarIsVisible {
    return selectionControls is TextSelectionHandleControls
        ? _selectionOverlay._contextMenuControllerIsShown
        : _selectionOverlay._toolbar != null;
  }

  /// Whether the magnifier is currently visible.
  bool get magnifierIsVisible => _selectionOverlay._magnifierController.shown;

  /// Hides the entire overlay including the toolbar and the handles.
  void hide() => _selectionOverlay.hide();

  /// Hides the toolbar part of the overlay.
  ///
  /// To hide the whole overlay, see [hide].
  void hideToolbar() => _selectionOverlay.hideToolbar();

  /// Final cleanup.
  void dispose() {
    _selectionOverlay.dispose();
    renderObject.selectionStartInViewport
        .removeListener(_updateTextSelectionOverlayVisibilities);
    renderObject.selectionEndInViewport
        .removeListener(_updateTextSelectionOverlayVisibilities);
    _effectiveToolbarVisibility.dispose();
    _effectiveStartHandleVisibility.dispose();
    _effectiveEndHandleVisibility.dispose();
    hideToolbar();
  }

  // "Width" here refers to the glyph width in a vertical line.
  // It would be the height of the glyph in a non-rotated orientation.
  double _getStartGlyphWidth() {
    final String currText = selectionDelegate.textEditingValue.text;
    final int firstSelectedGraphemeExtent;
    Rect? startHandleRect;
    // Only calculate handle rects if the text in the previous frame
    // is the same as the text in the current frame. This is done because
    // widget.renderObject contains the renderEditable from the previous frame.
    // If the text changed between the current and previous frames then
    // widget.renderObject.getRectForComposingRange might fail. In cases where
    // the current frame is different from the previous we fall back to
    // renderObject.preferredLineWidth.
    if (renderObject.plainText == currText &&
        _selection != null &&
        _selection.isValid &&
        !_selection.isCollapsed) {
      final String selectedGraphemes = _selection.textInside(currText);
      firstSelectedGraphemeExtent = selectedGraphemes.characters.first.length;
      startHandleRect = renderObject.getRectForComposingRange(TextRange(
          start: _selection.start,
          end: _selection.start + firstSelectedGraphemeExtent));
    }
    return startHandleRect?.width ?? renderObject.preferredLineWidth;
  }

  // "Width" here refers to the glyph width in a vertical line.
  // It would be the height of the glyph in a non-rotated orientation.
  double _getEndGlyphWidth() {
    final String currText = selectionDelegate.textEditingValue.text;
    final int lastSelectedGraphemeExtent;
    Rect? endHandleRect;
    // See the explanation in _getStartGlyphWidth.
    if (renderObject.plainText == currText &&
        _selection != null &&
        _selection.isValid &&
        !_selection.isCollapsed) {
      final String selectedGraphemes = _selection.textInside(currText);
      lastSelectedGraphemeExtent = selectedGraphemes.characters.last.length;
      endHandleRect = renderObject.getRectForComposingRange(TextRange(
          start: _selection.end - lastSelectedGraphemeExtent,
          end: _selection.end));
    }
    return endHandleRect?.width ?? renderObject.preferredLineWidth;
  }

  MagnifierInfo _buildMagnifier({
    required MongolRenderEditable renderEditable,
    required Offset globalGesturePosition,
    required TextPosition currentTextPosition,
  }) {
    final Offset globalRenderEditableTopLeft =
        renderEditable.localToGlobal(Offset.zero);
    final Rect localCaretRect =
        renderEditable.getLocalRectForCaret(currentTextPosition);

    final TextSelection lineAtOffset =
        renderEditable.getLineAtOffset(currentTextPosition);
    final TextPosition positionAtEndOfLine = TextPosition(
      offset: lineAtOffset.extentOffset,
      affinity: TextAffinity.upstream,
    );

    // Default affinity is downstream.
    final TextPosition positionAtBeginningOfLine = TextPosition(
      offset: lineAtOffset.baseOffset,
    );

    final Rect lineBoundaries = Rect.fromPoints(
      renderEditable.getLocalRectForCaret(positionAtBeginningOfLine).centerLeft,
      renderEditable.getLocalRectForCaret(positionAtEndOfLine).centerRight,
    );

    return MagnifierInfo(
      fieldBounds: globalRenderEditableTopLeft & renderEditable.size,
      globalGesturePosition: globalGesturePosition,
      caretRect: localCaretRect.shift(globalRenderEditableTopLeft),
      currentLineBoundaries: lineBoundaries.shift(globalRenderEditableTopLeft),
    );
  }

  // The contact position of the gesture at the current end handle location.
  // Updated when the handle moves.
  late double _endHandleDragPosition;

  // The distance from _endHandleDragPosition to the center of the line that it
  // corresponds to.
  late double _endHandleDragPositionToCenterOfLine;

  void _handleSelectionEndHandleDragStart(DragStartDetails details) {
    if (!renderObject.attached) {
      return;
    }

    // This adjusts for the fact that the selection handles may not
    // perfectly cover the TextPosition that they correspond to.
    _endHandleDragPosition = details.globalPosition.dx;
    final Offset endPoint = renderObject
        .localToGlobal(_selectionOverlay.selectionEndpoints.last.point);
    final double centerOfLine =
        endPoint.dx - renderObject.preferredLineWidth / 2;
    _endHandleDragPositionToCenterOfLine =
        centerOfLine - _endHandleDragPosition;
    final TextPosition position = renderObject.getPositionForPoint(
      Offset(
        centerOfLine,
        details.globalPosition.dy,
      ),
    );

    _selectionOverlay.showMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ),
    );
  }

  /// Given a handle position and drag position, returns the position of handle
  /// after the drag.
  ///
  /// The handle jumps instantly between lines when the drag reaches a full
  /// line's width away from the original handle position. In other words, the
  /// line jump happens when the contact point would be located at the same
  /// place on the handle at the new line as when the gesture started.
  double _getHandleDx(double dragDx, double handleDx) {
    final double distanceDragged = dragDx - handleDx;
    final int dragDirection = distanceDragged < 0.0 ? -1 : 1;
    final int linesDragged = dragDirection *
        (distanceDragged.abs() / renderObject.preferredLineWidth).floor();
    return handleDx + linesDragged * renderObject.preferredLineWidth;
  }

  void _handleSelectionEndHandleDragUpdate(DragUpdateDetails details) {
    if (!renderObject.attached) {
      return;
    }

    _endHandleDragPosition =
        _getHandleDx(details.globalPosition.dx, _endHandleDragPosition);
    final Offset adjustedOffset = Offset(
      _endHandleDragPosition + _endHandleDragPositionToCenterOfLine,
      details.globalPosition.dy,
    );

    final TextPosition position =
        renderObject.getPositionForPoint(adjustedOffset);

    if (_selection.isCollapsed) {
      _selectionOverlay.updateMagnifier(_buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ));

      final TextSelection currentSelection =
          TextSelection.fromPosition(position);
      _handleSelectionHandleChanged(currentSelection, isEnd: true);
      return;
    }

    final TextSelection newSelection;
    switch (defaultTargetPlatform) {
      // On Apple platforms, dragging the base handle makes it the extent.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        newSelection = TextSelection(
          extentOffset: position.offset,
          baseOffset: _selection.start,
        );
        if (position.offset <= _selection.start) {
          return; // Don't allow order swapping.
        }
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        newSelection = TextSelection(
          baseOffset: _selection.baseOffset,
          extentOffset: position.offset,
        );
        if (newSelection.baseOffset >= newSelection.extentOffset) {
          return; // Don't allow order swapping.
        }
        break;
    }

    _handleSelectionHandleChanged(newSelection, isEnd: true);

    _selectionOverlay.updateMagnifier(_buildMagnifier(
      currentTextPosition: newSelection.extent,
      globalGesturePosition: details.globalPosition,
      renderEditable: renderObject,
    ));
  }

  // The contact position of the gesture at the current start handle location.
  // Updated when the handle moves.
  late double _startHandleDragPosition;

  // The distance from _startHandleDragPosition to the center of the line that
  // it corresponds to.
  late double _startHandleDragPositionToCenterOfLine;

  void _handleSelectionStartHandleDragStart(DragStartDetails details) {
    if (!renderObject.attached) {
      return;
    }

    // This adjusts for the fact that the selection handles may not
    // perfectly cover the TextPosition that they correspond to.
    _startHandleDragPosition = details.globalPosition.dx;
    final Offset startPoint = renderObject
        .localToGlobal(_selectionOverlay.selectionEndpoints.first.point);
    final double centerOfLine =
        startPoint.dx - renderObject.preferredLineWidth / 2;
    _startHandleDragPositionToCenterOfLine =
        centerOfLine - _startHandleDragPosition;
    final TextPosition position = renderObject.getPositionForPoint(
      Offset(
        centerOfLine,
        details.globalPosition.dy,
      ),
    );

    _selectionOverlay.showMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ),
    );
  }

  void _handleSelectionStartHandleDragUpdate(DragUpdateDetails details) {
    if (!renderObject.attached) {
      return;
    }

    _startHandleDragPosition =
        _getHandleDx(details.globalPosition.dx, _startHandleDragPosition);
    final Offset adjustedOffset = Offset(
      _startHandleDragPosition + _startHandleDragPositionToCenterOfLine,
      details.globalPosition.dy,
    );
    final TextPosition position =
        renderObject.getPositionForPoint(adjustedOffset);

    if (_selection.isCollapsed) {
      _selectionOverlay.updateMagnifier(_buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ));

      final TextSelection currentSelection =
          TextSelection.fromPosition(position);
      _handleSelectionHandleChanged(currentSelection, isEnd: false);
      return;
    }

    final TextSelection newSelection;
    switch (defaultTargetPlatform) {
      // On Apple platforms, dragging the base handle makes it the extent.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        newSelection = TextSelection(
          extentOffset: position.offset,
          baseOffset: _selection.end,
        );
        if (newSelection.extentOffset >= _selection.end) {
          return; // Don't allow order swapping.
        }
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: _selection.extentOffset,
        );
        if (newSelection.baseOffset >= newSelection.extentOffset) {
          return; // Don't allow order swapping.
        }
        break;
    }

    _selectionOverlay.updateMagnifier(_buildMagnifier(
      currentTextPosition: newSelection.extent.offset < newSelection.base.offset
          ? newSelection.extent
          : newSelection.base,
      globalGesturePosition: details.globalPosition,
      renderEditable: renderObject,
    ));

    _handleSelectionHandleChanged(newSelection, isEnd: false);
  }

  void _handleAnyDragEnd(DragEndDetails details) {
    if (!context.mounted) {
      return;
    }
    if (selectionControls is! TextSelectionHandleControls) {
      _selectionOverlay.hideMagnifier();
      if (!_selection.isCollapsed) {
        _selectionOverlay.showToolbar();
      }
      return;
    }
    _selectionOverlay.hideMagnifier();
    if (!_selection.isCollapsed) {
      _selectionOverlay.showToolbar(
        context: context,
        contextMenuBuilder: contextMenuBuilder,
      );
    }
  }

  void _handleSelectionHandleChanged(TextSelection newSelection,
      {required bool isEnd}) {
    final TextPosition textPosition =
        isEnd ? newSelection.extent : newSelection.base;
    selectionDelegate.userUpdateTextEditingValue(
      _value.copyWith(selection: newSelection),
      SelectionChangedCause.drag,
    );
    selectionDelegate.bringIntoView(textPosition);
  }
}

/// This widget represents a single draggable text selection handle.
class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay({
    Key? key,
    required this.selection,
    required this.position,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.renderObject,
    required this.onSelectionHandleChanged,
    required this.onSelectionHandleTapped,
    required this.selectionControls,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final MongolRenderEditable renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback? onSelectionHandleTapped;
  final TextSelectionControls? selectionControls;
  final DragStartBehavior dragStartBehavior;

  @override
  _TextSelectionHandleOverlayState createState() =>
      _TextSelectionHandleOverlayState();

  ValueListenable<bool> get _visibility {
    switch (position) {
      case _TextSelectionHandlePosition.start:
        return renderObject.selectionStartInViewport;
      case _TextSelectionHandlePosition.end:
        return renderObject.selectionEndInViewport;
    }
  }
}

class _TextSelectionHandleOverlayState
    extends State<_TextSelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  late Offset _dragPosition;

  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: SelectionOverlay.fadeDuration, vsync: this);

    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget._visibility.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_TextSelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget._visibility.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget._visibility.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    final handleSize = widget.selectionControls!.getHandleSize(
      widget.renderObject.preferredLineWidth,
    );
    _dragPosition = details.globalPosition + Offset(-handleSize.width, 0.0);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final position = widget.renderObject.getPositionForPoint(_dragPosition);

    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(TextSelection.fromPosition(position));
      return;
    }

    final TextSelection newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: widget.selection.extentOffset,
        );
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = TextSelection(
          baseOffset: widget.selection.baseOffset,
          extentOffset: position.offset,
        );
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset) {
      return; // don't allow order swapping.
    }

    widget.onSelectionHandleChanged(newSelection);
  }

  void _handleTap() {
    if (widget.onSelectionHandleTapped != null) {
      widget.onSelectionHandleTapped!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LayerLink layerLink;
    final TextSelectionHandleType type;

    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        layerLink = widget.startHandleLayerLink;
        type = _chooseType(TextSelectionHandleType.left);
        break;
      case _TextSelectionHandlePosition.end:
        // For collapsed selections, we shouldn't be building the [end] handle.
        assert(!widget.selection.isCollapsed);
        layerLink = widget.endHandleLayerLink;
        type = _chooseType(TextSelectionHandleType.right);
        break;
    }

    final handleAnchor = widget.selectionControls!.getHandleAnchor(
      type,
      widget.renderObject.preferredLineWidth,
    );
    final handleSize = widget.selectionControls!.getHandleSize(
      widget.renderObject.preferredLineWidth,
    );

    final handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    // Make sure the GestureDetector is big enough to be easily interactive.
    final interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(
          center: handleRect.center, radius: kMinInteractiveDimension / 2),
    );
    final padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: layerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: widget.dragStartBehavior,
            onPanStart: _handleDragStart,
            onPanUpdate: _handleDragUpdate,
            onTap: _handleTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls!.buildHandle(
                context,
                type,
                widget.renderObject.preferredLineWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextSelectionHandleType _chooseType(TextSelectionHandleType type) {
    if (widget.selection.isCollapsed) {
      return TextSelectionHandleType.collapsed;
    }
    return type;
  }
}

/// Delegate interface for the [MongolTextSelectionGestureDetectorBuilder].
///
/// The interface is usually implemented by textfield implementations wrapping
/// [MongolEditableText], that use a [MongolTextSelectionGestureDetectorBuilder] to build a
/// [TextSelectionGestureDetector] for their [MongolEditableText]. The delegate provides
/// the builder with information about the current state of the textfield.
/// Based on this information, the builder adds the correct gesture handlers
/// to the gesture detector.
///
/// See also:
///
///  * [MongolTextField], which implements this delegate for the Material textfield.
abstract class MongolTextSelectionGestureDetectorBuilderDelegate {
  /// [GlobalKey] to the [MongolEditableText] for which the
  /// [MongolTextSelectionGestureDetectorBuilder] will build a [TextSelectionGestureDetector].
  GlobalKey<MongolEditableTextState> get editableTextKey;

  /// Whether the text field should respond to force presses.
  bool get forcePressEnabled;

  /// Whether the user may select text in the text field.
  bool get selectionEnabled;
}

/// Builds a [TextSelectionGestureDetector] to wrap an [MongolEditableText].
///
/// The class implements sensible defaults for many user interactions
/// with an [MongolEditableText] (see the documentation of the various gesture handler
/// methods, e.g. [onTapDown], [onForcePressStart], etc.). Subclasses of
/// [MongolTextSelectionGestureDetectorBuilder] can change the behavior performed in
/// responds to these gesture events by overriding the corresponding handler
/// methods of this class.
///
/// The resulting [TextSelectionGestureDetector] to wrap an [MongolEditableText] is
/// obtained by calling [buildGestureDetector].
///
/// See also:
///
///  * [MongolTextField], which uses a subclass to implement the Material-specific
///    gesture logic of an [MongolEditableText].
class MongolTextSelectionGestureDetectorBuilder {
  /// Creates a [MongolTextSelectionGestureDetectorBuilder].
  MongolTextSelectionGestureDetectorBuilder({
    required this.delegate,
  });

  /// The delegate for this [MongolTextSelectionGestureDetectorBuilder].
  ///
  /// The delegate provides the builder with information about what actions can
  /// currently be performed on the text field. Based on this, the builder adds
  /// the correct gesture handlers to the gesture detector.
  @protected
  final MongolTextSelectionGestureDetectorBuilderDelegate delegate;

  /// Whether to show the selection toolbar.
  ///
  /// It is based on the signal source when a [onTapDown] is called. This getter
  /// will return true if current [onTapDown] event is triggered by a touch or
  /// a stylus.
  bool get shouldShowSelectionToolbar => _shouldShowSelectionToolbar;
  bool _shouldShowSelectionToolbar = true;

  /// The [State] of the [EditableText] for which the builder will provide a
  /// [TextSelectionGestureDetector].
  @protected
  MongolEditableTextState get editableText =>
      delegate.editableTextKey.currentState!;

  /// The [RenderObject] of the [MongolEditableText] for which the builder will
  /// provide a [TextSelectionGestureDetector].
  @protected
  MongolRenderEditable get renderEditable => editableText.renderEditable;

  /// Handler for [TextSelectionGestureDetector.onTapDown].
  ///
  /// By default, it forwards the tap to [MongolRenderEditable.handleTapDown] and sets
  /// [shouldShowSelectionToolbar] to true if the tap was initiated by a finger or stylus.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onTapDown], which triggers this callback.
  @protected
  void onTapDown(TapDownDetails details) {
    renderEditable.handleTapDown(details);
    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus). A mouse shouldn't
    // trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    final kind = details.kind;
    _shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  /// Handler for [TextSelectionGestureDetector.onForcePressStart].
  ///
  /// By default, it selects the word at the position of the force press,
  /// if selection is enabled.
  ///
  /// This callback is only applicable when force press is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onForcePressStart], which triggers this
  ///    callback.
  @protected
  void onForcePressStart(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    _shouldShowSelectionToolbar = true;
    if (delegate.selectionEnabled) {
      renderEditable.selectWordsInRange(
        from: details.globalPosition,
        cause: SelectionChangedCause.forcePress,
      );
    }
  }

  /// Handler for [TextSelectionGestureDetector.onForcePressEnd].
  ///
  /// By default, it selects words in the range specified in [details] and shows
  /// toolbar if it is necessary.
  ///
  /// This callback is only applicable when force press is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onForcePressEnd], which triggers this
  ///    callback.
  @protected
  void onForcePressEnd(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    renderEditable.selectWordsInRange(
      from: details.globalPosition,
      cause: SelectionChangedCause.forcePress,
    );
    if (shouldShowSelectionToolbar) editableText.showToolbar();
  }

  /// Handler for [TextSelectionGestureDetector.onSingleTapUp].
  ///
  /// By default, it selects word edge if selection is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleTapUp], which triggers
  ///    this callback.
  @protected
  void onSingleTapUp(TapUpDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSingleTapCancel].
  ///
  /// By default, it services as place holder to enable subclass override.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleTapCancel], which triggers
  ///    this callback.
  @protected
  void onSingleTapCancel() {
    /* Subclass should override this method if needed. */
  }

  /// Handler for [TextSelectionGestureDetector.onSingleLongTapStart].
  ///
  /// By default, it selects text position specified in [details] if selection
  /// is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleLongTapStart], which triggers
  ///    this callback.
  @protected
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSingleLongTapMoveUpdate].
  ///
  /// By default, it updates the selection location specified in [details] if
  /// selection is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleLongTapMoveUpdate], which
  ///    triggers this callback.
  @protected
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSingleLongTapEnd].
  ///
  /// By default, it shows toolbar if necessary.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleLongTapEnd], which triggers this
  ///    callback.
  @protected
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (shouldShowSelectionToolbar) editableText.showToolbar();
  }

  /// Handler for [TextSelectionGestureDetector.onDoubleTapDown].
  ///
  /// By default, it selects a word through [MongolRenderEditable.selectWord] if
  /// selectionEnabled and shows toolbar if necessary.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDoubleTapDown], which triggers this
  ///    callback.
  @protected
  void onDoubleTapDown(TapDownDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectWord(cause: SelectionChangedCause.tap);
      if (shouldShowSelectionToolbar) editableText.showToolbar();
    }
  }

  /// Handler for [TextSelectionGestureDetector.onDragSelectionStart].
  ///
  /// By default, it selects a text position specified in [details].
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDragSelectionStart], which triggers
  ///    this callback.
  @protected
  void onDragSelectionStart(DragStartDetails details) {
    final kind = details.kind;
    _shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;

    renderEditable.selectPositionAt(
      from: details.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  /// Handler for [TextSelectionGestureDetector.onDragSelectionUpdate].
  ///
  /// By default, it updates the selection location specified in the provided
  /// details objects.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDragSelectionUpdate], which triggers
  ///    this callback./lib/src/material/text_field.dart
  @protected
  void onDragSelectionUpdate(
      DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    renderEditable.selectPositionAt(
      from: startDetails.globalPosition,
      to: updateDetails.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  /// Handler for [TextSelectionGestureDetector.onDragSelectionEnd].
  ///
  /// By default, it services as place holder to enable subclass override.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDragSelectionEnd], which triggers this
  ///    callback.
  @protected
  void onDragSelectionEnd(DragEndDetails details) {
    /* Subclass should override this method if needed. */
  }

  /// Returns a [TextSelectionGestureDetector] configured with the handlers
  /// provided by this builder.
  ///
  /// The [child] or its subtree should contain [EditableText].
  Widget buildGestureDetector({
    Key? key,
    HitTestBehavior? behavior,
    required Widget child,
  }) {
    return TextSelectionGestureDetector(
      key: key,
      onTapDown: onTapDown,
      onForcePressStart: delegate.forcePressEnabled ? onForcePressStart : null,
      onForcePressEnd: delegate.forcePressEnabled ? onForcePressEnd : null,
      onSingleTapUp: onSingleTapUp,
      onSingleTapCancel: onSingleTapCancel,
      onSingleLongTapStart: onSingleLongTapStart,
      onSingleLongTapMoveUpdate: onSingleLongTapMoveUpdate,
      onSingleLongTapEnd: onSingleLongTapEnd,
      onDoubleTapDown: onDoubleTapDown,
      onDragSelectionStart: onDragSelectionStart,
      onDragSelectionUpdate: onDragSelectionUpdate,
      onDragSelectionEnd: onDragSelectionEnd,
      behavior: behavior,
      child: child,
    );
  }
}

/// An object that manages a pair of selection handles and a toolbar.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class MongolSelectionOverlay {
  /// Creates an object that manages overlay entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  MongolSelectionOverlay({
    required this.context,
    this.debugRequiredFor,
    required TextSelectionHandleType startHandleType,
    required double lineWidthAtStart,
    this.startHandlesVisible,
    this.onStartHandleDragStart,
    this.onStartHandleDragUpdate,
    this.onStartHandleDragEnd,
    required TextSelectionHandleType endHandleType,
    required double lineWidthAtEnd,
    this.endHandlesVisible,
    this.onEndHandleDragStart,
    this.onEndHandleDragUpdate,
    this.onEndHandleDragEnd,
    this.toolbarVisible,
    required List<TextSelectionPoint> selectionEndpoints,
    required this.selectionControls,
    @Deprecated(
      'Use `contextMenuBuilder` in `showToolbar` instead. '
      'This feature was deprecated after v3.3.0-0.5.pre.',
    )
        required this.selectionDelegate,
    required this.clipboardStatus,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.toolbarLayerLink,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onSelectionHandleTapped,
    @Deprecated(
      'Use `contextMenuBuilder` in `showToolbar` instead. '
      'This feature was deprecated after v3.3.0-0.5.pre.',
    )
        Offset? toolbarLocation,
    this.magnifierConfiguration = TextMagnifierConfiguration.disabled,
  })  : _startHandleType = startHandleType,
        _lineWidthAtStart = lineWidthAtStart,
        _endHandleType = endHandleType,
        _lineWidthAtEnd = lineWidthAtEnd,
        _selectionEndpoints = selectionEndpoints,
        assert(debugCheckHasOverlay(context));

  /// Build context where the overlay will go
  final BuildContext context;

  final ValueNotifier<MagnifierInfo> _magnifierInfo =
      ValueNotifier<MagnifierInfo>(MagnifierInfo.empty);

  /// [MagnifierController.show] and [MagnifierController.hide] should not be
  /// called directly, except from inside [showMagnifier] and [hideMagnifier].
  /// If it is desired to show or hide the magnifier, call [showMagnifier] or
  /// [hideMagnifier]. This is because the magnifier needs to orchestrate
  /// with other properties in [MongolSelectionOverlay].
  final MagnifierController _magnifierController = MagnifierController();

  /// By default, [SelectionOverlay]'s [TextMagnifierConfiguration] is disabled.
  final TextMagnifierConfiguration magnifierConfiguration;

  /// Shows the magnifier, and hides the toolbar if it was showing when
  /// [showMagnifier] was called. This is safe to call on platforms not mobile,
  /// since a magnifierBuilder will not be provided, or the magnifierBuilder
  /// will return null on platforms not mobile.
  ///
  /// This is NOT the source of truth for if the magnifier is up or not,
  /// since magnifiers may hide themselves. If this info is needed, check
  /// [MagnifierController.shown].
  void showMagnifier(MagnifierInfo initialMagnifierInfo) {
    if (_toolbar != null || _contextMenuControllerIsShown) {
      hideToolbar();
    }

    // Start from empty, so we don't utilize any remnant values.
    _magnifierInfo.value = initialMagnifierInfo;

    // Pre-build the magnifiers so we can tell if we've built something
    // or not. If we don't build a magnifiers, then we should not
    // insert anything in the overlay.
    final Widget? builtMagnifier = magnifierConfiguration.magnifierBuilder(
      context,
      _magnifierController,
      _magnifierInfo,
    );

    if (builtMagnifier == null) {
      return;
    }

    _magnifierController.show(
        context: context,
        below: magnifierConfiguration.shouldDisplayHandlesInMagnifier
            ? null
            : _handles?.first,
        builder: (_) => builtMagnifier);
  }

  /// Hide the current magnifier.
  ///
  /// This does nothing if there is no magnifier.
  void hideMagnifier() {
    // This cannot be a check on `MagnifierController.shown`, since
    // it's possible that the magnifier is still in the overlay, but
    // not shown in cases where the magnifier hides itself.
    if (_magnifierController.overlayEntry == null) {
      return;
    }

    _magnifierController.hide();
  }

  /// The type of start selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  TextSelectionHandleType get startHandleType => _startHandleType;
  TextSelectionHandleType _startHandleType;
  set startHandleType(TextSelectionHandleType value) {
    if (_startHandleType == value) {
      return;
    }
    _startHandleType = value;
    markNeedsBuild();
  }

  /// The line width at the selection start.
  ///
  /// This value is used for calculating the size of the start selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  double get lineWidthAtStart => _lineWidthAtStart;
  double _lineWidthAtStart;
  set lineWidthAtStart(double value) {
    if (_lineWidthAtStart == value) {
      return;
    }
    _lineWidthAtStart = value;
    markNeedsBuild();
  }

  bool _isDraggingStartHandle = false;

  /// Whether the start handle is visible.
  ///
  /// If the value changes, the start handle uses [FadeTransition] to transition
  /// itself on and off the screen.
  ///
  /// If this is null, the start selection handle will always be visible.
  final ValueListenable<bool>? startHandlesVisible;

  /// Called when the users start dragging the start selection handles.
  final ValueChanged<DragStartDetails>? onStartHandleDragStart;

  void _handleStartHandleDragStart(DragStartDetails details) {
    assert(!_isDraggingStartHandle);
    _isDraggingStartHandle = details.kind == PointerDeviceKind.touch;
    onStartHandleDragStart?.call(details);
  }

  /// Called when the users drag the start selection handles to new locations.
  final ValueChanged<DragUpdateDetails>? onStartHandleDragUpdate;

  /// Called when the users lift their fingers after dragging the start selection
  /// handles.
  final ValueChanged<DragEndDetails>? onStartHandleDragEnd;

  void _handleStartHandleDragEnd(DragEndDetails details) {
    _isDraggingStartHandle = false;
    onStartHandleDragEnd?.call(details);
  }

  /// The type of end selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  TextSelectionHandleType get endHandleType => _endHandleType;
  TextSelectionHandleType _endHandleType;
  set endHandleType(TextSelectionHandleType value) {
    if (_endHandleType == value) {
      return;
    }
    _endHandleType = value;
    markNeedsBuild();
  }

  /// The line width at the selection end.
  ///
  /// This value is used for calculating the size of the end selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  double get lineWidthAtEnd => _lineWidthAtEnd;
  double _lineWidthAtEnd;
  set lineWidthAtEnd(double value) {
    if (_lineWidthAtEnd == value) {
      return;
    }
    _lineWidthAtEnd = value;
    markNeedsBuild();
  }

  bool _isDraggingEndHandle = false;

  /// Whether the end handle is visible.
  ///
  /// If the value changes, the end handle uses [FadeTransition] to transition
  /// itself on and off the screen.
  ///
  /// If this is null, the end selection handle will always be visible.
  final ValueListenable<bool>? endHandlesVisible;

  /// Called when the users start dragging the end selection handles.
  final ValueChanged<DragStartDetails>? onEndHandleDragStart;

  void _handleEndHandleDragStart(DragStartDetails details) {
    assert(!_isDraggingEndHandle);
    _isDraggingEndHandle = details.kind == PointerDeviceKind.touch;
    onEndHandleDragStart?.call(details);
  }

  /// Called when the users drag the end selection handles to new locations.
  final ValueChanged<DragUpdateDetails>? onEndHandleDragUpdate;

  /// Called when the users lift their fingers after dragging the end selection
  /// handles.
  final ValueChanged<DragEndDetails>? onEndHandleDragEnd;

  void _handleEndHandleDragEnd(DragEndDetails details) {
    _isDraggingEndHandle = false;
    onEndHandleDragEnd?.call(details);
  }

  /// Whether the toolbar is visible.
  ///
  /// If the value changes, the toolbar uses [FadeTransition] to transition
  /// itself on and off the screen.
  ///
  /// If this is null the toolbar will always be visible.
  final ValueListenable<bool>? toolbarVisible;

  /// The text selection positions of selection start and end.
  List<TextSelectionPoint> get selectionEndpoints => _selectionEndpoints;
  List<TextSelectionPoint> _selectionEndpoints;
  set selectionEndpoints(List<TextSelectionPoint> value) {
    if (!listEquals(_selectionEndpoints, value)) {
      markNeedsBuild();
      if (_isDraggingEndHandle || _isDraggingStartHandle) {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            HapticFeedback.selectionClick();
            break;
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            break;
        }
      }
    }
    _selectionEndpoints = value;
  }

  /// Debugging information for explaining why the [Overlay] is required.
  final Widget? debugRequiredFor;

  /// The object supplied to the [CompositedTransformTarget] that wraps the text
  /// field.
  final LayerLink toolbarLayerLink;

  /// The objects supplied to the [CompositedTransformTarget] that wraps the
  /// location of start selection handle.
  final LayerLink startHandleLayerLink;

  /// The objects supplied to the [CompositedTransformTarget] that wraps the
  /// location of end selection handle.
  final LayerLink endHandleLayerLink;

  /// Builds text selection handles and toolbar.
  final TextSelectionControls? selectionControls;

  /// The delegate for manipulating the current selection in the owning
  /// text field.
  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  final TextSelectionDelegate? selectionDelegate;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], handle drag behavior will
  /// begin at the position where the drag gesture won the arena. If set to
  /// [DragStartBehavior.down] it will begin at the position where a down
  /// event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for
  ///    the different behaviors.
  final DragStartBehavior dragStartBehavior;

  /// A callback that's optionally invoked when a selection handle is tapped.
  ///
  /// The [TextSelectionControls.buildHandle] implementation the text field
  /// uses decides where the handle's tap "hotspot" is, or whether the
  /// selection handle supports tap gestures at all. For instance,
  /// [MaterialTextSelectionControls] calls [onSelectionHandleTapped] when the
  /// selection handle's "knob" is tapped, while
  /// [CupertinoTextSelectionControls] builds a handle that's not sufficiently
  /// large for tapping (as it's not meant to be tapped) so it does not call
  /// [onSelectionHandleTapped] even when tapped.
  final VoidCallback? onSelectionHandleTapped;

  /// Maintains the status of the clipboard for determining if its contents can
  /// be pasted or not.
  ///
  /// Useful because the actual value of the clipboard can only be checked
  /// asynchronously (see [Clipboard.getData]).
  final ClipboardStatusNotifier? clipboardStatus;

  /// The location of where the toolbar should be drawn in relative to the
  /// location of [toolbarLayerLink].
  ///
  /// If this is null, the toolbar is drawn based on [selectionEndpoints] and
  /// the rect of render object of [context].
  ///
  /// This is useful for displaying toolbars at the mouse right-click locations
  /// in desktop devices.
  @Deprecated(
    'Use the `contextMenuBuilder` parameter in `showToolbar` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  Offset? get toolbarLocation => _toolbarLocation;
  Offset? _toolbarLocation;
  set toolbarLocation(Offset? value) {
    if (_toolbarLocation == value) {
      return;
    }
    _toolbarLocation = value;
    markNeedsBuild();
  }

  /// Controls the fade-in and fade-out animations for the toolbar and handles.
  static const Duration fadeDuration = Duration(milliseconds: 150);

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry>? _handles;

  /// A copy/paste toolbar.
  OverlayEntry? _toolbar;

  // Manages the context menu. Not necessarily visible when non-null.
  final ContextMenuController _contextMenuController = ContextMenuController();

  bool get _contextMenuControllerIsShown => _contextMenuController.isShown;

  /// Builds the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    if (_handles != null) {
      return;
    }

    _handles = <OverlayEntry>[
      OverlayEntry(builder: _buildStartHandle),
      OverlayEntry(builder: _buildEndHandle),
    ];
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)
        .insertAll(_handles!);
  }

  /// Destroys the handles by removing them from overlay.
  void hideHandles() {
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }
  }

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar({
    BuildContext? context,
    WidgetBuilder? contextMenuBuilder,
  }) {
    if (contextMenuBuilder == null) {
      if (_toolbar != null) {
        return;
      }
      _toolbar = OverlayEntry(builder: _buildToolbar);
      Overlay.of(this.context,
              rootOverlay: true, debugRequiredFor: debugRequiredFor)
          .insert(_toolbar!);
      return;
    }

    if (context == null) {
      return;
    }

    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return _SelectionToolbarWrapper(
          layerLink: toolbarLayerLink,
          offset: -renderBox.localToGlobal(Offset.zero),
          child: contextMenuBuilder(context),
        );
      },
    );
  }

  bool _buildScheduled = false;

  /// Rebuilds the selection toolbar or handles if they are present.
  void markNeedsBuild() {
    if (_handles == null && _toolbar == null) {
      return;
    }
    // If we are in build state, it will be too late to update visibility.
    // We will need to schedule the build in next frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_buildScheduled) {
        return;
      }
      _buildScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        _buildScheduled = false;
        if (_handles != null) {
          _handles![0].markNeedsBuild();
          _handles![1].markNeedsBuild();
        }
        _toolbar?.markNeedsBuild();
        if (_contextMenuController.isShown) {
          _contextMenuController.markNeedsBuild();
        }
      });
    } else {
      if (_handles != null) {
        _handles![0].markNeedsBuild();
        _handles![1].markNeedsBuild();
      }
      _toolbar?.markNeedsBuild();
      if (_contextMenuController.isShown) {
        _contextMenuController.markNeedsBuild();
      }
    }
  }

  /// Hides the entire overlay including the toolbar and the handles.
  void hide() {
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }
    if (_toolbar != null || _contextMenuControllerIsShown) {
      hideToolbar();
    }
  }

  /// Hides the toolbar part of the overlay.
  ///
  /// To hide the whole overlay, see [hide].
  void hideToolbar() {
    _contextMenuController.remove();
    if (_toolbar == null) {
      return;
    }
    _toolbar?.remove();
    _toolbar = null;
  }

  /// Disposes this object and release resources.
  void dispose() {
    hide();
  }

  Widget _buildStartHandle(BuildContext context) {
    final Widget handle;
    final TextSelectionControls? selectionControls = this.selectionControls;
    if (selectionControls == null) {
      handle = const SizedBox.shrink();
    } else {
      handle = _SelectionHandleOverlay(
        type: _startHandleType,
        handleLayerLink: startHandleLayerLink,
        onSelectionHandleTapped: onSelectionHandleTapped,
        onSelectionHandleDragStart: _handleStartHandleDragStart,
        onSelectionHandleDragUpdate: onStartHandleDragUpdate,
        onSelectionHandleDragEnd: _handleStartHandleDragEnd,
        selectionControls: selectionControls,
        visibility: startHandlesVisible,
        preferredLineWidth: _lineWidthAtStart,
        dragStartBehavior: dragStartBehavior,
      );
    }
    return TextFieldTapRegion(
      child: ExcludeSemantics(
        child: handle,
      ),
    );
  }

  Widget _buildEndHandle(BuildContext context) {
    final Widget handle;
    final TextSelectionControls? selectionControls = this.selectionControls;
    if (selectionControls == null ||
        _startHandleType == TextSelectionHandleType.collapsed) {
      // Hide the second handle when collapsed.
      handle = const SizedBox.shrink();
    } else {
      handle = _SelectionHandleOverlay(
        type: _endHandleType,
        handleLayerLink: endHandleLayerLink,
        onSelectionHandleTapped: onSelectionHandleTapped,
        onSelectionHandleDragStart: _handleEndHandleDragStart,
        onSelectionHandleDragUpdate: onEndHandleDragUpdate,
        onSelectionHandleDragEnd: _handleEndHandleDragEnd,
        selectionControls: selectionControls,
        visibility: endHandlesVisible,
        preferredLineWidth: _lineWidthAtEnd,
        dragStartBehavior: dragStartBehavior,
      );
    }
    return TextFieldTapRegion(
      child: ExcludeSemantics(
        child: handle,
      ),
    );
  }

  // Build the toolbar via TextSelectionControls.
  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null) {
      return const SizedBox.shrink();
    }
    assert(selectionDelegate != null,
        'If not using contextMenuBuilder, must pass selectionDelegate.');

    final RenderBox renderBox = this.context.findRenderObject()! as RenderBox;

    final Rect editingRegion = Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero),
      renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
    );

    final bool isMultiline =
        selectionEndpoints.last.point.dx - selectionEndpoints.first.point.dx >
            lineWidthAtEnd / 2;

    // If the selected text spans more than 1 line, vertically center the toolbar.
    // Derived from both iOS and Android.
    final double midY = isMultiline
        ? editingRegion.height / 2
        : (selectionEndpoints.first.point.dy +
                selectionEndpoints.last.point.dy) /
            2;

    final Offset midpoint = Offset(
      midY,
      // The x-coordinate won't be made use of most likely.
      selectionEndpoints.first.point.dx - lineWidthAtStart,
    );

    return _SelectionToolbarWrapper(
      visibility: toolbarVisible,
      layerLink: toolbarLayerLink,
      offset: -editingRegion.topLeft,
      child: Builder(
        builder: (BuildContext context) {
          return selectionControls!.buildToolbar(
            context,
            editingRegion,
            lineWidthAtStart,
            midpoint,
            selectionEndpoints,
            selectionDelegate!,
            clipboardStatus,
            toolbarLocation,
          );
        },
      ),
    );
  }

  /// Update the current magnifier with new selection data, so the magnifier
  /// can respond accordingly.
  ///
  /// If the magnifier is not shown, this still updates the magnifier position
  /// because the magnifier may have hidden itself and is looking for a cue to
  /// reshow itself.
  ///
  /// If there is no magnifier in the overlay, this does nothing.
  void updateMagnifier(MagnifierInfo magnifierInfo) {
    if (_magnifierController.overlayEntry == null) {
      return;
    }

    _magnifierInfo.value = magnifierInfo;
  }
}

class _SelectionToolbarWrapper extends StatefulWidget {
  const _SelectionToolbarWrapper({
    this.visibility,
    required this.layerLink,
    required this.offset,
    required this.child,
  })  : assert(layerLink != null),
        assert(offset != null),
        assert(child != null);

  final Widget child;
  final Offset offset;
  final LayerLink layerLink;
  final ValueListenable<bool>? visibility;

  @override
  State<_SelectionToolbarWrapper> createState() =>
      _SelectionToolbarWrapperState();
}

class _SelectionToolbarWrapperState extends State<_SelectionToolbarWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: SelectionOverlay.fadeDuration, vsync: this);

    _toolbarVisibilityChanged();
    widget.visibility?.addListener(_toolbarVisibilityChanged);
  }

  @override
  void didUpdateWidget(_SelectionToolbarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibility == widget.visibility) {
      return;
    }
    oldWidget.visibility?.removeListener(_toolbarVisibilityChanged);
    _toolbarVisibilityChanged();
    widget.visibility?.addListener(_toolbarVisibilityChanged);
  }

  @override
  void dispose() {
    widget.visibility?.removeListener(_toolbarVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _toolbarVisibilityChanged() {
    if (widget.visibility?.value ?? true) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FadeTransition(
          opacity: _opacity,
          child: CompositedTransformFollower(
            link: widget.layerLink,
            showWhenUnlinked: false,
            offset: widget.offset,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// This widget represents a single draggable selection handle.
class _SelectionHandleOverlay extends StatefulWidget {
  /// Create selection overlay.
  const _SelectionHandleOverlay({
    required this.type,
    required this.handleLayerLink,
    this.onSelectionHandleTapped,
    this.onSelectionHandleDragStart,
    this.onSelectionHandleDragUpdate,
    this.onSelectionHandleDragEnd,
    required this.selectionControls,
    this.visibility,
    required this.preferredLineWidth,
    this.dragStartBehavior = DragStartBehavior.start,
  });

  final LayerLink handleLayerLink;
  final VoidCallback? onSelectionHandleTapped;
  final ValueChanged<DragStartDetails>? onSelectionHandleDragStart;
  final ValueChanged<DragUpdateDetails>? onSelectionHandleDragUpdate;
  final ValueChanged<DragEndDetails>? onSelectionHandleDragEnd;
  final TextSelectionControls selectionControls;
  final ValueListenable<bool>? visibility;
  final double preferredLineWidth;
  final TextSelectionHandleType type;
  final DragStartBehavior dragStartBehavior;

  @override
  State<_SelectionHandleOverlay> createState() =>
      _SelectionHandleOverlayState();
}

class _SelectionHandleOverlayState extends State<_SelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: SelectionOverlay.fadeDuration, vsync: this);

    _handleVisibilityChanged();
    widget.visibility?.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget.visibility?.value ?? true) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_SelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.visibility?.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget.visibility?.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget.visibility?.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Offset handleAnchor = widget.selectionControls.getHandleAnchor(
      widget.type,
      widget.preferredLineWidth,
    );
    final Size handleSize = widget.selectionControls.getHandleSize(
      widget.preferredLineWidth,
    );

    final Rect handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    // Make sure the GestureDetector is big enough to be easily interactive.
    final Rect interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(
          center: handleRect.center, radius: kMinInteractiveDimension / 2),
    );
    final RelativeRect padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: widget.handleLayerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              PanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                () => PanGestureRecognizer(
                  debugOwner: this,
                  // Mouse events select the text and do not drag the cursor.
                  supportedDevices: <PointerDeviceKind>{
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                ),
                (PanGestureRecognizer instance) {
                  instance
                    ..dragStartBehavior = widget.dragStartBehavior
                    ..onStart = widget.onSelectionHandleDragStart
                    ..onUpdate = widget.onSelectionHandleDragUpdate
                    ..onEnd = widget.onSelectionHandleDragEnd;
                },
              ),
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls.buildHandle(
                context,
                widget.type,
                widget.preferredLineWidth,
                widget.onSelectionHandleTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
