// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mongol/src/base/mongol_text_align.dart';
import 'package:mongol/src/base/mongol_text_painter.dart';

import '../base/mongol_paragraph.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretWidthOffset = 2.0; // pixels

/// The consecutive sequence of [TextPosition]s that the caret should move to
/// when the user navigates the paragraph using the left arrow key or the
/// right arrow key.
///
/// When the user presses the left arrow key or the right arrow key, on
/// many platforms (macOS for instance), the caret will move to the previous
/// line or the next line, while maintaining its original horizontal location.
/// When it encounters a shorter line, the caret moves to the closest horizontal
/// location within that line, and restores the original horizontal location
/// when a long enough line is encountered.
///
/// Additionally, the caret will move to the beginning of the document if the
/// left arrow key is pressed and the caret is already on the first line. If
/// the right arrow key is pressed next, the caret will restore its original
/// horizontal location and move to the second line. Similarly the caret moves
/// to the end of the document if the right arrow key is pressed when it's
/// already on the last line.
///
/// Consider a top-aligned paragraph:
///   a  a  a
///   a     a
///  ——     a
/// where the caret was initially placed at the end of the first line. Pressing
/// the right arrow key once will move the caret to the end of the second
/// line, and twice the arrow key moves to the third line after the second "a"
/// on that line. Pressing the right arrow key again, the caret will move to
/// the end of the third line (the end of the document). Pressing the left
/// arrow key in this state will result in the caret moving to the end of the
/// second line.
///
/// Horizontal caret runs are typically interrupted when the layout of the text
/// changes (including when the text itself changes), or when the selection is
/// changed by other input events or programmatically (for example, when the
/// user pressed the up arrow key).
///
/// The [movePrevious] method moves the caret location (which is
/// [HorizontalCaretMovementRun.current]) to the previous line, and in case
/// the caret is already on the first line, the method does nothing and returns
/// false. Similarly the [moveNext] method moves the caret to the next line, and
/// returns false if the caret is already on the last line.
///
/// If the underlying paragraph's layout changes, [isValid] becomes false and
/// the [HorizontalCaretMovementRun] must not be used. The [isValid] property must
/// be checked before calling [movePrevious] and [moveNext], or accessing
/// [current].
class HorizontalCaretMovementRun implements Iterator<TextPosition> {
  HorizontalCaretMovementRun._(
    this._editable,
    this._lineMetrics,
    this._currentTextPosition,
    this._currentLine,
    this._currentOffset,
  );

  Offset _currentOffset;
  int _currentLine;
  TextPosition _currentTextPosition;

  final List<MongolLineMetrics> _lineMetrics;
  final MongolRenderEditable _editable;

  bool _isValid = true;

  /// Whether this [HorizontalCaretMovementRun] can still continue.
  ///
  /// A [HorizontalCaretMovementRun] run is valid if the underlying text layout
  /// hasn't changed.
  ///
  /// The [current] value and the [movePrevious] and [moveNext] methods must not
  /// be accessed when [isValid] is false.
  bool get isValid {
    if (!_isValid) {
      return false;
    }
    final List<MongolLineMetrics> newLineMetrics =
        _editable._textPainter.computeLineMetrics();
    // Use the implementation detail of the computeLineMetrics method to figure
    // out if the current text layout has been invalidated.
    if (!identical(newLineMetrics, _lineMetrics)) {
      _isValid = false;
    }
    return _isValid;
  }

  final Map<int, MapEntry<Offset, TextPosition>> _positionCache =
      <int, MapEntry<Offset, TextPosition>>{};

  MapEntry<Offset, TextPosition> _getTextPositionForLine(int lineNumber) {
    assert(isValid);
    assert(lineNumber >= 0);
    final MapEntry<Offset, TextPosition>? cachedPosition =
        _positionCache[lineNumber];
    if (cachedPosition != null) {
      return cachedPosition;
    }
    assert(lineNumber != _currentLine);

    final Offset newOffset =
        Offset(_lineMetrics[lineNumber].baseline, _currentOffset.dy);
    final TextPosition closestPosition =
        _editable._textPainter.getPositionForOffset(newOffset);
    final MapEntry<Offset, TextPosition> position =
        MapEntry<Offset, TextPosition>(newOffset, closestPosition);
    _positionCache[lineNumber] = position;
    return position;
  }

  @override
  TextPosition get current {
    assert(isValid);
    return _currentTextPosition;
  }

  @override
  bool moveNext() {
    assert(isValid);
    if (_currentLine + 1 >= _lineMetrics.length) {
      return false;
    }
    final MapEntry<Offset, TextPosition> position =
        _getTextPositionForLine(_currentLine + 1);
    _currentLine += 1;
    _currentOffset = position.key;
    _currentTextPosition = position.value;
    return true;
  }

  bool movePrevious() {
    assert(isValid);
    if (_currentLine <= 0) {
      return false;
    }
    final MapEntry<Offset, TextPosition> position =
        _getTextPositionForLine(_currentLine - 1);
    _currentLine -= 1;
    _currentOffset = position.key;
    _currentTextPosition = position.value;
    return true;
  }
}

/// Displays some text in a scrollable container with a potentially blinking
/// cursor and with gesture recognizers.
///
/// This is the renderer for an editable vertical text field. It does not
/// directly provide a means of editing the text, but it does handle text
/// selection and manipulation of the text cursor.
///
/// The [text] is displayed, scrolled by the given [offset], aligned according
/// to [textAlign]. The [maxLines] property controls whether the text displays
/// on one line or many. The [selection], if it is not collapsed, is painted in
/// the [selectionColor]. If it _is_ collapsed, then it represents the cursor
/// position. The cursor is shown while [showCursor] is true. It is painted in
/// the [cursorColor].
///
/// If, when the render object paints, the caret is found to have changed
/// location, [onCaretChanged] is called.
///
/// Keyboard handling, IME handling, scrolling, toggling the [showCursor] value
/// to actually blink the cursor, and other features not mentioned above are the
/// responsibility of higher layers and not handled by this object.
class MongolRenderEditable extends RenderBox
    with RelayoutWhenSystemFontsChangeMixin
    implements TextLayoutMetrics {
  /// Creates a render object that implements the visual aspects of a text field.
  ///
  /// The [textAlign] argument must not be null. It defaults to
  /// [MongolTextAlign.top].
  ///
  /// If [showCursor] is not specified, then it defaults to hiding the cursor.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is 1, meaning this is a single-line
  /// text field. If it is not null, it must be greater than zero.
  ///
  /// The [offset] is required and must not be null. You can use
  /// [ViewportOffset.zero] if you have no need for scrolling.
  MongolRenderEditable({
    TextSpan? text,
    MongolTextAlign textAlign = MongolTextAlign.top,
    Color? cursorColor,
    ValueNotifier<bool>? showCursor,
    bool? hasFocus,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    Color? selectionColor,
    double textScaleFactor = 1.0,
    TextSelection? selection,
    required ViewportOffset offset,
    this.ignorePointer = false,
    bool readOnly = false,
    bool forceLine = true,
    String obscuringCharacter = '•',
    bool obscureText = false,
    double? cursorWidth,
    double cursorHeight = 1.0,
    Radius? cursorRadius,
    Offset cursorOffset = Offset.zero,
    double devicePixelRatio = 1.0,
    bool? enableInteractiveSelection,
    Clip clipBehavior = Clip.hardEdge,
    required this.textSelectionDelegate,
    MongolRenderEditablePainter? painter,
    MongolRenderEditablePainter? foregroundPainter,
  })  : assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        ),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(obscuringCharacter.characters.length == 1),
        assert(cursorWidth == null || cursorWidth >= 0.0),
        assert(cursorHeight >= 0.0),
        _textPainter = MongolTextPainter(
          text: text,
          textAlign: textAlign,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines == 1 ? 1 : null,
        ),
        _showCursor = showCursor ?? ValueNotifier<bool>(false),
        _maxLines = maxLines,
        _minLines = minLines,
        _expands = expands,
        _selection = selection,
        _offset = offset,
        _cursorWidth = cursorWidth,
        _cursorHeight = cursorHeight,
        _enableInteractiveSelection = enableInteractiveSelection,
        _devicePixelRatio = devicePixelRatio,
        _startHandleLayerLink = startHandleLayerLink,
        _endHandleLayerLink = endHandleLayerLink,
        _obscuringCharacter = obscuringCharacter,
        _obscureText = obscureText,
        _readOnly = readOnly,
        _forceLine = forceLine,
        _clipBehavior = clipBehavior {
    assert(!_showCursor.value || cursorColor != null);
    this.hasFocus = hasFocus ?? false;

    _selectionPainter.highlightColor = selectionColor;
    _selectionPainter.highlightedRange = selection;

    _caretPainter.caretColor = cursorColor;
    _caretPainter.cursorRadius = cursorRadius;
    _caretPainter.cursorOffset = cursorOffset;

    _updateForegroundPainter(foregroundPainter);
    _updatePainter(painter);
  }

  /// Child render objects
  _MongolRenderEditableCustomPaint? _foregroundRenderObject;
  _MongolRenderEditableCustomPaint? _backgroundRenderObject;

  @override
  void dispose() {
    _foregroundRenderObject?.dispose();
    _foregroundRenderObject = null;
    _backgroundRenderObject?.dispose();
    _backgroundRenderObject = null;
    _clipRectLayer.layer = null;
    _cachedBuiltInForegroundPainters?.dispose();
    _cachedBuiltInPainters?.dispose();
    _selectionStartInViewport.dispose();
    _selectionEndInViewport.dispose();
    _selectionPainter.dispose();
    _caretPainter.dispose();
    _textPainter.dispose();
    super.dispose();
  }

  void _updateForegroundPainter(MongolRenderEditablePainter? newPainter) {
    final effectivePainter = (newPainter == null)
        ? _builtInForegroundPainters
        : _CompositeRenderEditablePainter(
            painters: <MongolRenderEditablePainter>[
              _builtInForegroundPainters,
              newPainter,
            ],
          );

    if (_foregroundRenderObject == null) {
      final foregroundRenderObject =
          _MongolRenderEditableCustomPaint(painter: effectivePainter);
      adoptChild(foregroundRenderObject);
      _foregroundRenderObject = foregroundRenderObject;
    } else {
      _foregroundRenderObject?.painter = effectivePainter;
    }
    _foregroundPainter = newPainter;
  }

  /// The [MongolRenderEditablePainter] to use for painting above this
  /// [MongolRenderEditable]'s text content.
  ///
  /// The new [MongolRenderEditablePainter] will replace the previously specified
  /// foreground painter, and schedule a repaint if the new painter's
  /// `shouldRepaint` method returns true.
  MongolRenderEditablePainter? get foregroundPainter => _foregroundPainter;
  MongolRenderEditablePainter? _foregroundPainter;

  set foregroundPainter(MongolRenderEditablePainter? newPainter) {
    if (newPainter == _foregroundPainter) return;
    _updateForegroundPainter(newPainter);
  }

  void _updatePainter(MongolRenderEditablePainter? newPainter) {
    final effectivePainter = (newPainter == null)
        ? _builtInPainters
        : _CompositeRenderEditablePainter(
            painters: <MongolRenderEditablePainter>[
              _builtInPainters,
              newPainter,
            ],
          );

    if (_backgroundRenderObject == null) {
      final backgroundRenderObject =
          _MongolRenderEditableCustomPaint(painter: effectivePainter);
      adoptChild(backgroundRenderObject);
      _backgroundRenderObject = backgroundRenderObject;
    } else {
      _backgroundRenderObject?.painter = effectivePainter;
    }
    _painter = newPainter;
  }

  /// Sets the [MongolRenderEditablePainter] to use for painting beneath this
  /// [MongolRenderEditable]'s text content.
  ///
  /// The new [MongolRenderEditablePainter] will replace the previously specified
  /// painter, and schedule a repaint if the new painter's `shouldRepaint`
  /// method returns true.
  MongolRenderEditablePainter? get painter => _painter;
  MongolRenderEditablePainter? _painter;

  set painter(MongolRenderEditablePainter? newPainter) {
    if (newPainter == _painter) return;
    _updatePainter(newPainter);
  }

  // Caret painters:
  late final _CaretPainter _caretPainter = _CaretPainter();

  // Text Highlight painters:
  final _TextHighlightPainter _selectionPainter = _TextHighlightPainter();

  _CompositeRenderEditablePainter get _builtInForegroundPainters =>
      _cachedBuiltInForegroundPainters ??= _createBuiltInForegroundPainters();
  _CompositeRenderEditablePainter? _cachedBuiltInForegroundPainters;

  _CompositeRenderEditablePainter _createBuiltInForegroundPainters() {
    return _CompositeRenderEditablePainter(
      painters: <MongolRenderEditablePainter>[
        _caretPainter,
      ],
    );
  }

  _CompositeRenderEditablePainter get _builtInPainters =>
      _cachedBuiltInPainters ??= _createBuiltInPainters();
  _CompositeRenderEditablePainter? _cachedBuiltInPainters;

  _CompositeRenderEditablePainter _createBuiltInPainters() {
    return _CompositeRenderEditablePainter(
      painters: <MongolRenderEditablePainter>[
        _selectionPainter,
      ],
    );
  }

  double? _textLayoutLastMaxHeight;
  double? _textLayoutLastMinHeight;

  /// Assert that the last layout still matches the constraints.
  void debugAssertLayoutUpToDate() {
    assert(
      _textLayoutLastMaxHeight == constraints.maxHeight &&
          _textLayoutLastMinHeight == constraints.minHeight,
      'Last height ($_textLayoutLastMinHeight, $_textLayoutLastMaxHeight) not the same as max height constraint (${constraints.minHeight}, ${constraints.maxHeight}).',
    );
  }

  /// Whether the [handleEvent] will propagate pointer events to selection
  /// handlers.
  ///
  /// If this property is true, the [handleEvent] assumes that this renderer
  /// will be notified of input gestures via [handleTapDown], [handleTap],
  /// [handleDoubleTap], and [handleLongPress].
  ///
  /// If there are any gesture recognizers in the text span, the [handleEvent]
  /// will still propagate pointer events to those recognizers.
  ///
  /// The default value of this property is false.
  bool ignorePointer;

  /// The pixel ratio of the current device.
  ///
  /// Should be obtained by querying MediaQuery for the devicePixelRatio.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;

  set devicePixelRatio(double value) {
    if (devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsTextLayout();
  }

  /// Character used for obscuring text if [obscureText] is true.
  ///
  /// Must have a length of exactly one.
  String get obscuringCharacter => _obscuringCharacter;
  String _obscuringCharacter;

  set obscuringCharacter(String value) {
    if (_obscuringCharacter == value) {
      return;
    }
    assert(value.characters.length == 1);
    _obscuringCharacter = value;
    markNeedsLayout();
  }

  /// Whether to hide the text being edited (e.g., for passwords).
  bool get obscureText => _obscureText;
  bool _obscureText;
  set obscureText(bool value) {
    if (_obscureText == value) {
      return;
    }
    _obscureText = value;
    _cachedAttributedValue = null;
    markNeedsSemanticsUpdate();
  }

  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  TextSelectionDelegate textSelectionDelegate;

  /// Track whether position of the start of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "Hello", then scrolls so only "World" is visible, this will become false.
  /// If the user scrolls back so that the "H" is visible again, this will
  /// become true.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;
  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  /// Track whether position of the end of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "World", then scrolls so only "Hello" is visible, this will become
  /// 'false'. If the user scrolls back so that the "d" is visible again, this
  /// will become 'true'.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void _updateSelectionExtentsVisibility(Offset effectiveOffset) {
    assert(selection != null);
    final visibleRegion = Offset.zero & size;

    final startOffset = _textPainter.getOffsetForCaret(
      TextPosition(offset: selection!.start, affinity: selection!.affinity),
      _caretPrototype,
    );
    const visibleRegionSlop = 0.5;
    _selectionStartInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(startOffset + effectiveOffset);

    final endOffset = _textPainter.getOffsetForCaret(
      TextPosition(offset: selection!.end, affinity: selection!.affinity),
      _caretPrototype,
    );
    _selectionEndInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(endOffset + effectiveOffset);
  }

  void _setTextEditingValue(
      TextEditingValue newValue, SelectionChangedCause cause) {
    textSelectionDelegate.userUpdateTextEditingValue(newValue, cause);
  }

  void _setSelection(TextSelection nextSelection, SelectionChangedCause cause) {
    if (nextSelection.isValid) {
      // The nextSelection is calculated based on plainText, which can be out
      // of sync with the textSelectionDelegate.textEditingValue by one frame.
      // This is due to the render editable and editable text handle pointer
      // event separately. If the editable text changes the text during the
      // event handler, the render editable will use the outdated text stored in
      // the plainText when handling the pointer event.
      //
      // If this happens, we need to make sure the new selection is still valid.
      final int textLength = textSelectionDelegate.textEditingValue.text.length;
      nextSelection = nextSelection.copyWith(
        baseOffset: math.min(nextSelection.baseOffset, textLength),
        extentOffset: math.min(nextSelection.extentOffset, textLength),
      );
    }
    _setTextEditingValue(
      textSelectionDelegate.textEditingValue.copyWith(selection: nextSelection),
      cause,
    );
  }

  /// Returns the index into the string of the next character boundary after the
  /// given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If given
  /// string.length, string.length is returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int nextCharacter(int index, String string,
      [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == string.length) {
      return string.length;
    }

    var count = 0;
    final remaining = string.characters.skipWhile((String currentString) {
      if (count <= index) {
        count += currentString.length;
        return true;
      }
      if (includeWhitespace) {
        return false;
      }
      return TextLayoutMetrics.isWhitespace(currentString.codeUnitAt(0));
    });
    return string.length - remaining.toString().length;
  }

  /// Returns the index into the string of the previous character boundary
  /// before the given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If index is 0,
  /// 0 will be returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int previousCharacter(int index, String string,
      [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == 0) {
      return 0;
    }

    var count = 0;
    int? lastNonWhitespace;
    for (final currentString in string.characters) {
      if (!includeWhitespace &&
          !TextLayoutMetrics.isWhitespace(
              currentString.characters.first.toString().codeUnitAt(0))) {
        lastNonWhitespace = count;
      }
      if (count + currentString.length >= index) {
        return includeWhitespace ? count : lastNonWhitespace ?? 0;
      }
      count += currentString.length;
    }
    return 0;
  }

  // Returns the TextPosition to the left or right of the given offset.
  TextPosition _getTextPositionHorizontal(
      TextPosition position, double horizontalOffset) {
    final Offset caretOffset =
        _textPainter.getOffsetForCaret(position, _caretPrototype);
    final Offset caretOffsetTranslated =
        caretOffset.translate(horizontalOffset, 0.0);
    return _textPainter.getPositionForOffset(caretOffsetTranslated);
  }

  // Start TextLayoutMetrics.

  /// {@macro flutter.services.TextLayoutMetrics.getLineAtOffset}
  @override
  TextSelection getLineAtOffset(TextPosition position) {
    debugAssertLayoutUpToDate();
    final TextRange line = _textPainter.getLineBoundary(position);
    // If text is obscured, the entire string should be treated as one line.
    if (obscureText) {
      return TextSelection(baseOffset: 0, extentOffset: plainText.length);
    }
    return TextSelection(baseOffset: line.start, extentOffset: line.end);
  }

  /// {@macro flutter.painting.TextPainter.getWordBoundary}
  @override
  TextRange getWordBoundary(TextPosition position) {
    return _textPainter.getWordBoundary(position);
  }

  /// {@macro flutter.services.TextLayoutMetrics.getTextPositionAbove}
  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double preferredLineWidth = _textPainter.preferredLineWidth;
    final double horizontalOffset = -0.5 * preferredLineWidth;
    return _getTextPositionHorizontal(position, horizontalOffset);
  }

  /// {@macro flutter.services.TextLayoutMetrics.getTextPositionBelow}
  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double preferredLineWidth = _textPainter.preferredLineWidth;
    final double horizontalOffset = 1.5 * preferredLineWidth;
    return _getTextPositionHorizontal(position, horizontalOffset);
  }

  // End TextLayoutMetrics.

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    // Tell the painters to repaint since text layout may have changed.
    _foregroundRenderObject?.markNeedsPaint();
    _backgroundRenderObject?.markNeedsPaint();
  }

  /// Marks the render object as needing to be laid out again and have its text
  /// metrics recomputed.
  ///
  /// Implies [markNeedsLayout].
  @protected
  void markNeedsTextLayout() {
    _textLayoutLastMaxHeight = null;
    _textLayoutLastMinHeight = null;
    markNeedsLayout();
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _textPainter.markNeedsLayout();
    _textLayoutLastMaxHeight = null;
    _textLayoutLastMinHeight = null;
  }

  /// Returns a plain text version of the text in [TextPainter].
  ///
  /// If [obscureText] is true, returns the obscured text. See
  /// [obscureText] and [obscuringCharacter].
  /// In order to get the styled text as an [TextSpan] tree, use [text].
  String get plainText => _textPainter.plainText;

  /// The text to paint in the form of a tree of [TextSpan]s.
  ///
  /// In order to get the plain text representation, use [plainText].
  TextSpan? get text => _textPainter.text;
  final MongolTextPainter _textPainter;
  AttributedString? _cachedAttributedValue;
  List<InlineSpanSemanticsInformation>? _cachedCombinedSemanticsInfos;
  set text(TextSpan? value) {
    if (_textPainter.text == value) {
      return;
    }
    _cachedLineBreakCount = null;
    _textPainter.text = value;
    _cachedAttributedValue = null;
    _cachedCombinedSemanticsInfos = null;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// How the text should be aligned vertically.
  ///
  /// This must not be null.
  MongolTextAlign get textAlign => _textPainter.textAlign;

  set textAlign(MongolTextAlign value) {
    if (_textPainter.textAlign == value) return;
    _textPainter.textAlign = value;
    markNeedsTextLayout();
  }

  /// The color to use when painting the cursor.
  Color? get cursorColor => _caretPainter.caretColor;

  set cursorColor(Color? value) {
    _caretPainter.caretColor = value;
  }

  /// Whether to paint the cursor.
  ValueNotifier<bool> get showCursor => _showCursor;
  ValueNotifier<bool> _showCursor;

  set showCursor(ValueNotifier<bool> value) {
    if (_showCursor == value) return;
    if (attached) _showCursor.removeListener(_showHideCursor);
    _showCursor = value;
    if (attached) {
      _showHideCursor();
      _showCursor.addListener(_showHideCursor);
    }
  }

  void _showHideCursor() {
    _caretPainter.shouldPaint = showCursor.value;
  }

  /// Whether the editable is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;

  // bool _listenerAttached = false;
  set hasFocus(bool value) {
    if (_hasFocus == value) return;
    _hasFocus = value;
    markNeedsSemanticsUpdate();
  }

  /// Whether this rendering object will take a full line regardless the
  /// text height.
  bool get forceLine => _forceLine;
  bool _forceLine = false;

  set forceLine(bool value) {
    if (_forceLine == value) return;
    _forceLine = value;
    markNeedsLayout();
  }

  /// Whether this rendering object is read only.
  bool get readOnly => _readOnly;
  bool _readOnly = false;

  set readOnly(bool value) {
    if (_readOnly == value) return;
    _readOnly = value;
    markNeedsSemanticsUpdate();
  }

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will extend
  /// indefinitely instead.
  ///
  /// If this is null, there is no limit to the number of lines.
  ///
  /// When this is not null, the intrinsic width of the render object is the
  /// width of one line of text multiplied by this value. In other words, this
  /// also controls the width of the actual editing widget.
  int? get maxLines => _maxLines;
  int? _maxLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (maxLines == value) {
      return;
    }
    _maxLines = value;

    // Special case maxLines == 1 to keep only the first line so we can get the
    // width of the first line in case there are hard line breaks in the text.
    // See the `_preferredWidth` method.
    _textPainter.maxLines = value == 1 ? 1 : null;
    markNeedsTextLayout();
  }

  /// The minimum number of lines to occupy when the content spans fewer lines.
  ///
  /// If this is null (default), text container starts with enough horizontal space
  /// for one line and grows to accommodate additional lines as they are entered.
  ///
  /// This can be used in combination with [maxLines] for a varying set of behaviors.
  ///
  /// If the value is set, it must be greater than zero. If the value is greater
  /// than 1, [maxLines] should also be set to either null or greater than
  /// this value.
  ///
  /// When [maxLines] is set as well, the width will grow between the indicated
  /// range of lines. When [maxLines] is null, it will grow as wide as needed,
  /// starting from [minLines].
  ///
  /// A few examples of behaviors possible with [minLines] and [maxLines] are as follows.
  /// These apply equally to `MongolTextField`, `MongolTextFormField`,
  /// and `MongolEditableText`.
  ///
  /// Input that always occupies at least 2 lines and has an infinite max.
  /// Expands horizontally as needed.
  /// ```dart
  /// MongolTextField(minLines: 2)
  /// ```
  ///
  /// Input whose width starts from 2 lines and grows up to 4 lines at which
  /// point the width limit is reached. If additional lines are entered it will
  /// scroll horizontally.
  /// ```dart
  /// TextField(minLines:2, maxLines: 4)
  /// ```
  ///
  /// See the examples in [maxLines] for the complete picture of how [maxLines]
  /// and [minLines] interact to produce various behaviors.
  ///
  /// Defaults to null.
  int? get minLines => _minLines;
  int? _minLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set minLines(int? value) {
    assert(value == null || value > 0);
    if (minLines == value) return;
    _minLines = value;
    markNeedsTextLayout();
  }

  /// Whether this widget's width will be sized to fill its parent.
  ///
  /// If set to true and wrapped in a parent widget like [Expanded] or
  /// [SizedBox], the input will expand to fill the parent.
  ///
  /// [maxLines] and [minLines] must both be null when this is set to true,
  /// otherwise an error is thrown.
  ///
  /// Defaults to false.
  ///
  /// See the examples in [maxLines] for the complete picture of how [maxLines],
  /// [minLines], and [expands] interact to produce various behaviors.
  ///
  /// Input that matches the width of its parent:
  /// ```dart
  /// Expanded(
  ///   child: TextField(maxLines: null, expands: true),
  /// )
  /// ```
  bool get expands => _expands;
  bool _expands;
  set expands(bool value) {
    if (expands == value) {
      return;
    }
    _expands = value;
    markNeedsTextLayout();
  }

  /// The color to use when painting the selection.
  Color? get selectionColor => _selectionPainter.highlightColor;

  set selectionColor(Color? value) {
    _selectionPainter.highlightColor = value;
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;

  set textScaleFactor(double value) {
    if (_textPainter.textScaleFactor == value) return;
    _textPainter.textScaleFactor = value;
    markNeedsTextLayout();
  }

  /// The region of text that is selected, if any.
  ///
  /// The caret position is represented by a collapsed selection.
  ///
  /// If [selection] is null, there is no selection and attempts to
  /// manipulate the selection will throw.
  TextSelection? get selection => _selection;
  TextSelection? _selection;

  set selection(TextSelection? value) {
    if (_selection == value) return;
    _selection = value;
    _selectionPainter.highlightedRange = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The offset at which the text should be painted.
  ///
  /// If the text content is larger than the editable line itself, the editable
  /// line clips the text. This property controls which part of the text is
  /// visible by shifting the text by the given offset before clipping.
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;

  set offset(ViewportOffset value) {
    if (_offset == value) return;
    if (attached) _offset.removeListener(markNeedsPaint);
    _offset = value;
    if (attached) _offset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  /// How wide the cursor will be.
  ///
  /// This can be null, in which case the getter will actually return [preferredLineWidth].
  ///
  /// Setting this to itself fixes the value to the current [preferredLineWidth]. Setting
  /// this to null returns the behavior of deferring to [preferredLineWidth].
  double get cursorWidth => _cursorWidth ?? preferredLineWidth;
  double? _cursorWidth;

  set cursorWidth(double? value) {
    if (_cursorWidth == value) return;
    _cursorWidth = value;
    markNeedsLayout();
  }

  /// How thick the cursor will be.
  ///
  /// The cursor will draw over the text. The cursor height will extend
  /// down between the boundary of characters. This corresponds to extending
  /// downstream relative to the selected position. Negative values may be used
  /// to reverse this behavior.
  double get cursorHeight => _cursorHeight;
  double _cursorHeight = 1.0;

  set cursorHeight(double value) {
    if (_cursorHeight == value) {
      return;
    }
    _cursorHeight = value;
    markNeedsLayout();
  }

  /// The offset that is used, in pixels, when painting the cursor on screen.
  ///
  /// By default, the cursor position should be set to an offset of
  /// (0.0, -[cursorHeight] * 0.5) on iOS platforms and (0, 0) on Android
  /// platforms. The origin from where the offset is applied to is the arbitrary
  /// location where the cursor ends up being rendered from by default.
  Offset get cursorOffset => _caretPainter.cursorOffset;

  set cursorOffset(Offset value) {
    _caretPainter.cursorOffset = value;
  }

  /// How rounded the corners of the cursor should be.
  ///
  /// A null value is the same as [Radius.zero].
  Radius? get cursorRadius => _caretPainter.cursorRadius;

  set cursorRadius(Radius? value) {
    _caretPainter.cursorRadius = value;
  }

  /// The [LayerLink] of start selection handle.
  ///
  /// [MongolRenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of start handle.
  LayerLink get startHandleLayerLink => _startHandleLayerLink;
  LayerLink _startHandleLayerLink;

  set startHandleLayerLink(LayerLink value) {
    if (_startHandleLayerLink == value) return;
    _startHandleLayerLink = value;
    markNeedsPaint();
  }

  /// The [LayerLink] of end selection handle.
  ///
  /// [MongolRenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of end handle.
  LayerLink get endHandleLayerLink => _endHandleLayerLink;
  LayerLink _endHandleLayerLink;

  set endHandleLayerLink(LayerLink value) {
    if (_endHandleLayerLink == value) return;
    _endHandleLayerLink = value;
    markNeedsPaint();
  }

  /// Whether to allow the user to change the selection.
  ///
  /// Since [MongolRenderEditable] does not handle selection manipulation
  /// itself, this actually only affects whether the accessibility
  /// hints provided to the system (via
  /// [describeSemanticsConfiguration]) will enable selection
  /// manipulation. It's the responsibility of this object's owner
  /// to provide selection manipulation affordances.
  ///
  /// This field is used by [selectionEnabled] (which then controls
  /// the accessibility hints mentioned above). When null,
  /// [obscureText] is used to determine the value of
  /// [selectionEnabled] instead.
  bool? get enableInteractiveSelection => _enableInteractiveSelection;
  bool? _enableInteractiveSelection;

  set enableInteractiveSelection(bool? value) {
    if (_enableInteractiveSelection == value) return;
    _enableInteractiveSelection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// Whether interactive selection is enabled based on the values of
  /// [enableInteractiveSelection] and [obscureText].
  ///
  /// Since [MongolRenderEditable] does not handle selection manipulation
  /// itself, this actually only affects whether the accessibility
  /// hints provided to the system (via
  /// [describeSemanticsConfiguration]) will enable selection
  /// manipulation. It's the responsibility of this object's owner
  /// to provide selection manipulation affordances.
  ///
  /// By default, [enableInteractiveSelection] is null, [obscureText] is false,
  /// and this getter returns true.
  ///
  /// If [enableInteractiveSelection] is null and [obscureText] is true, then this
  /// getter returns false. This is the common case for password fields.
  ///
  /// If [enableInteractiveSelection] is non-null then its value is
  /// returned. An application might [enableInteractiveSelection] to
  /// true to enable interactive selection for a password field, or to
  /// false to unconditionally disable interactive selection.
  bool get selectionEnabled {
    return enableInteractiveSelection ?? !obscureText;
  }

  /// The maximum amount the text is allowed to scroll.
  ///
  /// This value is only valid after layout and can change as additional
  /// text is entered or removed in order to accommodate expanding when
  /// [expands] is set to true.
  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent = 0;

  double get _caretMargin => _kCaretGap + cursorHeight;

  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;

  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode] and [_combineSemanticsInfo].
  List<InlineSpanSemanticsInformation>? _semanticsInfo;

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  LinkedHashMap<Key, SemanticsNode>? _cachedChildNodes;

  /// Returns a list of rects that bound the given selection.
  ///
  /// See [MongolTextPainter.getBoxesForSelection] for more details.
  List<Rect> getBoxesForSelection(TextSelection selection) {
    _computeTextMetricsIfNeeded();
    return _textPainter
        .getBoxesForSelection(selection)
        .map((rect) => rect.shift(_paintOffset))
        .toList();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _semanticsInfo = _textPainter.text!.getSemanticsInformation();
    if (_semanticsInfo!.any(
            (InlineSpanSemanticsInformation info) => info.recognizer != null) &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      assert(readOnly && !obscureText);
      // For Selectable rich text with recognizer, we need to create a semantics
      // node for each text fragment.
      config
        ..isSemanticBoundary = true
        ..explicitChildNodes = true;
      return;
    }
    if (_cachedAttributedValue == null) {
      if (obscureText) {
        _cachedAttributedValue =
            AttributedString(obscuringCharacter * plainText.length);
      } else {
        final StringBuffer buffer = StringBuffer();
        int offset = 0;
        final List<StringAttribute> attributes = <StringAttribute>[];
        for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
          final String label = info.semanticsLabel ?? info.text;
          for (final StringAttribute infoAttribute in info.stringAttributes) {
            final TextRange originalRange = infoAttribute.range;
            attributes.add(
              infoAttribute.copy(
                range: TextRange(
                    start: offset + originalRange.start,
                    end: offset + originalRange.end),
              ),
            );
          }
          buffer.write(label);
          offset += label.length;
        }
        _cachedAttributedValue =
            AttributedString(buffer.toString(), attributes: attributes);
      }
    }
    config
      ..attributedValue = _cachedAttributedValue!
      ..isObscured = obscureText
      ..isMultiline = _isMultiline
      ..textDirection = TextDirection.ltr
      ..isFocused = hasFocus
      ..isTextField = true
      ..isReadOnly = readOnly;

    if (hasFocus && selectionEnabled) {
      config.onSetSelection = _handleSetSelection;
    }

    if (hasFocus && !readOnly) {
      config.onSetText = _handleSetText;
    }

    if (selectionEnabled && (selection?.isValid ?? false)) {
      config.textSelection = selection;
      if (_textPainter.getOffsetBefore(selection!.extentOffset) != null) {
        config
          ..onMoveCursorBackwardByWord = _handleMoveCursorBackwardByWord
          ..onMoveCursorBackwardByCharacter =
              _handleMoveCursorBackwardByCharacter;
      }
      if (_textPainter.getOffsetAfter(selection!.extentOffset) != null) {
        config
          ..onMoveCursorForwardByWord = _handleMoveCursorForwardByWord
          ..onMoveCursorForwardByCharacter =
              _handleMoveCursorForwardByCharacter;
      }
    }
  }

  void _handleSetText(String text) {
    textSelectionDelegate.userUpdateTextEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    assert(_semanticsInfo != null && _semanticsInfo!.isNotEmpty);
    final newChildren = <SemanticsNode>[];
    Rect currentRect;
    var ordinal = 0.0;
    var start = 0;
    final LinkedHashMap<Key, SemanticsNode> newChildCache =
        LinkedHashMap<Key, SemanticsNode>();
    _cachedCombinedSemanticsInfos ??= combineSemanticsInfo(_semanticsInfo!);
    for (final info in _cachedCombinedSemanticsInfos!) {
      final TextSelection selection = TextSelection(
        baseOffset: start,
        extentOffset: start + info.text.length,
      );
      start += info.text.length;

      final rects = _textPainter.getBoxesForSelection(selection);
      if (rects.isEmpty) {
        continue;
      }
      var rect = rects.first;
      for (final textBox in rects.skip(1)) {
        rect = rect.expandToInclude(textBox);
      }
      // Any of the text boxes may have had infinite dimensions.
      // We shouldn't pass infinite dimensions up to the bridges.
      rect = Rect.fromLTWH(
        math.max(0.0, rect.left),
        math.max(0.0, rect.top),
        math.min(rect.width, constraints.maxWidth),
        math.min(rect.height, constraints.maxHeight),
      );
      // Round the current rectangle to make this API testable and add some
      // padding so that the accessibility rects do not overlap with the text.
      currentRect = Rect.fromLTRB(
        rect.left.floorToDouble() - 4.0,
        rect.top.floorToDouble() - 4.0,
        rect.right.ceilToDouble() + 4.0,
        rect.bottom.ceilToDouble() + 4.0,
      );
      final configuration = SemanticsConfiguration()
        ..sortKey = OrdinalSortKey(ordinal++)
        ..textDirection = TextDirection.ltr
        ..attributedLabel = AttributedString(info.semanticsLabel ?? info.text,
            attributes: info.stringAttributes);
      final GestureRecognizer? recognizer = info.recognizer;
      if (recognizer != null) {
        if (recognizer is TapGestureRecognizer) {
          if (recognizer.onTap != null) {
            configuration.onTap = recognizer.onTap;
            configuration.isLink = true;
          }
        } else if (recognizer is DoubleTapGestureRecognizer) {
          if (recognizer.onDoubleTap != null) {
            configuration.onTap = recognizer.onDoubleTap;
            configuration.isLink = true;
          }
        } else if (recognizer is LongPressGestureRecognizer) {
          if (recognizer.onLongPress != null) {
            configuration.onLongPress = recognizer.onLongPress;
          }
        } else {
          assert(false, '${recognizer.runtimeType} is not supported.');
        }
      }
      if (node.parentPaintClipRect != null) {
        final Rect paintRect = node.parentPaintClipRect!.intersect(currentRect);
        configuration.isHidden = paintRect.isEmpty && !currentRect.isEmpty;
      }
      late final SemanticsNode newChild;
      if (_cachedChildNodes?.isNotEmpty ?? false) {
        newChild = _cachedChildNodes!.remove(_cachedChildNodes!.keys.first)!;
      } else {
        final UniqueKey key = UniqueKey();
        newChild = SemanticsNode(
          key: key,
          showOnScreen: _createShowOnScreenFor(key),
        );
      }
      newChild
        ..updateWith(config: configuration)
        ..rect = currentRect;
      newChildCache[newChild.key!] = newChild;
      newChildren.add(newChild);
    }
    _cachedChildNodes = newChildCache;
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  VoidCallback? _createShowOnScreenFor(Key key) {
    return () {
      final SemanticsNode node = _cachedChildNodes![key]!;
      showOnScreen(descendant: this, rect: node.rect);
    };
  }

  void _handleSetSelection(TextSelection selection) {
    _setSelection(selection, SelectionChangedCause.keyboard);
  }

  void _handleMoveCursorForwardByCharacter(bool extendSelection) {
    assert(selection != null);
    final extentOffset = _textPainter.getOffsetAfter(selection!.extentOffset);
    if (extentOffset == null) {
      return;
    }
    final baseOffset = !extendSelection ? extentOffset : selection!.baseOffset;
    _setSelection(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByCharacter(bool extendSelection) {
    assert(selection != null);
    final extentOffset = _textPainter.getOffsetBefore(selection!.extentOffset);
    if (extentOffset == null) {
      return;
    }
    final baseOffset = !extendSelection ? extentOffset : selection!.baseOffset;
    _setSelection(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorForwardByWord(bool extendSelection) {
    assert(selection != null);
    final currentWord = _textPainter.getWordBoundary(selection!.extent);
    final nextWord = _getNextWord(currentWord.end);
    if (nextWord == null) {
      return;
    }
    final baseOffset = extendSelection ? selection!.baseOffset : nextWord.start;
    _setSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: nextWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByWord(bool extendSelection) {
    assert(selection != null);
    final currentWord = _textPainter.getWordBoundary(selection!.extent);
    final previousWord = _getPreviousWord(currentWord.start - 1);
    if (previousWord == null) {
      return;
    }
    final baseOffset =
        extendSelection ? selection!.baseOffset : previousWord.start;
    _setSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: previousWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  TextRange? _getNextWord(int offset) {
    while (true) {
      final range = _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (!range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.end;
    }
  }

  TextRange? _getPreviousWord(int offset) {
    while (offset >= 0) {
      final range = _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (!range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.start - 1;
    }
    return null;
  }

  // Check if the given text range only contains white space or separator
  // characters.
  //
  // Includes newline characters from ASCII and separators from the
  // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  bool _onlyWhitespace(TextRange range) {
    for (var i = range.start; i < range.end; i++) {
      final codeUnit = text!.codeUnitAt(i)!;
      if (!TextLayoutMetrics.isWhitespace(codeUnit)) {
        return false;
      }
    }
    return true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _foregroundRenderObject?.attach(owner);
    _backgroundRenderObject?.attach(owner);

    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = _handleLongPress;
    _offset.addListener(markNeedsPaint);
    _showHideCursor();
    _showCursor.addListener(_showHideCursor);
    // assert(!_listenerAttached);
    // if (_hasFocus) {
    //   RawKeyboard.instance.addListener(_handleKeyEvent);
    //   _listenerAttached = true;
    // }
  }

  @override
  void detach() {
    _tap.dispose();
    _longPress.dispose();
    _offset.removeListener(markNeedsPaint);
    _showCursor.removeListener(_showHideCursor);
    super.detach();
    _foregroundRenderObject?.detach();
    _backgroundRenderObject?.detach();
  }

  @override
  void redepthChildren() {
    final RenderObject? foregroundChild = _foregroundRenderObject;
    final RenderObject? backgroundChild = _backgroundRenderObject;
    if (foregroundChild != null) redepthChild(foregroundChild);
    if (backgroundChild != null) redepthChild(backgroundChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    final RenderObject? foregroundChild = _foregroundRenderObject;
    final RenderObject? backgroundChild = _backgroundRenderObject;
    if (foregroundChild != null) visitor(foregroundChild);
    if (backgroundChild != null) visitor(backgroundChild);
  }

  bool get _isMultiline => maxLines != 1;

  Axis get _viewportAxis => _isMultiline ? Axis.horizontal : Axis.vertical;

  Offset get _paintOffset {
    switch (_viewportAxis) {
      case Axis.horizontal:
        return Offset(-offset.pixels, 0.0);
      case Axis.vertical:
        return Offset(0.0, -offset.pixels);
    }
  }

  double get _viewportExtent {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  double _getMaxScrollExtent(Size contentSize) {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return math.max(0.0, contentSize.width - size.width);
      case Axis.vertical:
        return math.max(0.0, contentSize.height - size.height);
    }
  }

  // We need to check the paint offset here because during animation, the start of
  // the text may position outside the visible region even when the text fits.
  bool get _hasVisualOverflow =>
      _maxScrollExtent > 0 || _paintOffset != Offset.zero;

  /// Returns the local coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two.
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the equivalent but for
  ///    a [TextPosition] rather than a [TextSelection].
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    _computeTextMetricsIfNeeded();

    final paintOffset = _paintOffset;

    final boxes = selection.isCollapsed
        ? <Rect>[]
        : _textPainter.getBoxesForSelection(selection);
    if (boxes.isEmpty) {
      final caretOffset =
          _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      final start = Offset(preferredLineWidth, 0.0) + caretOffset + paintOffset;
      return <TextSelectionPoint>[TextSelectionPoint(start, TextDirection.ltr)];
    } else {
      final start = Offset(boxes.first.left, boxes.first.top) + paintOffset;
      final end = Offset(boxes.last.right, boxes.last.bottom) + paintOffset;
      return <TextSelectionPoint>[
        TextSelectionPoint(start, TextDirection.ltr),
        TextSelectionPoint(end, TextDirection.ltr),
      ];
    }
  }

  /// Returns the smallest [Rect], in the local coordinate system, that covers
  /// the text within the [TextRange] specified.
  ///
  /// This method is used to calculate the approximate position of the IME bar
  /// on iOS.
  ///
  /// Returns null if [TextRange.isValid] is false for the given `range`, or the
  /// given `range` is collapsed.
  Rect? getRectForComposingRange(TextRange range) {
    if (!range.isValid || range.isCollapsed) {
      return null;
    }
    _computeTextMetricsIfNeeded();

    final boxes = _textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );

    return boxes
        .fold(
          null,
          (Rect? accum, Rect incoming) =>
              accum?.expandToInclude(incoming) ?? incoming,
        )
        ?.shift(_paintOffset);
  }

  /// Returns the position in the text for the given global coordinate.
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the reverse operation, taking
  ///    a [TextPosition] and returning a [Rect].
  ///  * [MongolTextPainter.getPositionForOffset], which is the equivalent method
  ///    for a [MongolTextPainter] object.
  TextPosition getPositionForPoint(Offset globalPosition) {
    _computeTextMetricsIfNeeded();
    globalPosition += -_paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition));
  }

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  ///
  /// See also:
  ///
  ///  * [getPositionForPoint], which is the reverse operation, taking
  ///    an [Offset] in global coordinates and returning a [TextPosition].
  ///  * [getEndpointsForSelection], which is the equivalent but for
  ///    a selection rather than a particular text position.
  ///  * [MongolTextPainter.getOffsetForCaret], the equivalent method for a
  ///    [MongolTextPainter] object.
  Rect getLocalRectForCaret(TextPosition caretPosition) {
    _computeTextMetricsIfNeeded();
    final caretOffset =
        _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);
    // This rect is the same as _caretPrototype but without the horizontal padding.
    final rect = Rect.fromLTWH(0.0, 0.0, cursorWidth, cursorHeight)
        .shift(caretOffset + _paintOffset + cursorOffset);
    // Add additional cursor offset (generally only if on iOS).
    return rect.shift(_snapToPhysicalPixel(rect.topLeft));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _layoutText(maxHeight: double.infinity);
    return _textPainter.minIntrinsicHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _layoutText(maxHeight: double.infinity);
    return _textPainter.maxIntrinsicHeight + cursorHeight;
  }

  /// An estimate of the width of a line in the text. See [TextPainter.preferredLineWidth].
  /// This does not require the layout to be updated.
  double get preferredLineWidth => _textPainter.preferredLineWidth;

  int? _cachedLineBreakCount;
  int _countHardLineBreaks(String text) {
    final int? cachedValue = _cachedLineBreakCount;
    if (cachedValue != null) {
      return cachedValue;
    }
    int count = 0;
    for (int index = 0; index < text.length; index += 1) {
      switch (text.codeUnitAt(index)) {
        case 0x000A: // LF
        case 0x0085: // NEL
        case 0x000B: // VT
        case 0x000C: // FF, treating it as a regular line separator
        case 0x2028: // LS
        case 0x2029: // PS
          count += 1;
      }
    }
    return _cachedLineBreakCount = count;
  }

  double _preferredWidth(double height) {
    final int? maxLines = this.maxLines;
    final int? minLines = this.minLines ?? maxLines;
    final double minWidth = preferredLineWidth * (minLines ?? 0);

    if (maxLines == null) {
      final double estimatedWidth;
      if (height == double.infinity) {
        estimatedWidth =
            preferredLineWidth * (_countHardLineBreaks(plainText) + 1);
      } else {
        _layoutText(maxHeight: height);
        estimatedWidth = _textPainter.width;
      }
      return math.max(estimatedWidth, minWidth);
    }

    final bool usePreferredLineHeightHack =
        maxLines == 1 && text?.codeUnitAt(0) == null;

    // Special case maxLines == 1 since it forces the scrollable direction
    // to be horizontal. Report the real height to prevent the text from being
    // clipped.
    if (maxLines == 1 && !usePreferredLineHeightHack) {
      // The _layoutText call lays out the paragraph using infinite height when
      // maxLines == 1. Also _textPainter.maxLines will be set to 1 so should
      // there be any line breaks only the first line is shown.
      assert(_textPainter.maxLines == 1);
      _layoutText(maxHeight: height);
      return _textPainter.width;
    }
    if (minLines == maxLines) {
      return minWidth;
    }
    _layoutText(maxHeight: height);
    final double maxWidth = preferredLineWidth * maxLines;
    return clampDouble(_textPainter.width, minWidth, maxWidth);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _preferredWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _preferredWidth(height);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _computeTextMetricsIfNeeded();
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  late TapGestureRecognizer _tap;
  late LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      assert(!debugNeedsLayout);

      if (!ignorePointer) {
        // Propagates the pointer event to selection handlers.
        _tap.addPointer(event);
        _longPress.addPointer(event);
      }
    }
  }

  Offset? _lastTapDownPosition;
  Offset? _lastSecondaryTapDownPosition;

  /// The position of the most recent secondary tap down event on this text
  /// input.
  Offset? get lastSecondaryTapDownPosition => _lastSecondaryTapDownPosition;

  /// Tracks the position of a secondary tap event.
  ///
  /// Should be called before attempting to change the selection based on the
  /// position of a secondary tap.
  void handleSecondaryTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
    _lastSecondaryTapDownPosition = details.globalPosition;
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTapDown]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// down events by calling this method.
  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }

  void _handleTapDown(TapDownDetails details) {
    assert(!ignorePointer);
    handleTapDown(details);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// events by calling this method.
  void handleTap() {
    selectPosition(cause: SelectionChangedCause.tap);
  }

  void _handleTap() {
    assert(!ignorePointer);
    handleTap();
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [DoubleTapGestureRecognizer.onDoubleTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to double
  /// tap events by calling this method.
  void handleDoubleTap() {
    selectWord(cause: SelectionChangedCause.doubleTap);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [LongPressGestureRecognizer.onLongPress]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to long
  /// press events by calling this method.
  void handleLongPress() {
    selectWord(cause: SelectionChangedCause.longPress);
  }

  void _handleLongPress() {
    assert(!ignorePointer);
    handleLongPress();
  }

  /// Move selection to the location of the last tap down.
  ///
  /// This method is mainly used to translate user inputs in global positions
  /// into a [TextSelection]. When used in conjunction with a [MongolEditableText],
  /// the selection change is fed back into [TextEditingController.selection].
  ///
  /// If you have a [TextEditingController], it's generally easier to
  /// programmatically manipulate its `value` or `selection` directly.
  void selectPosition({required SelectionChangedCause cause}) {
    selectPositionAt(from: _lastTapDownPosition!, cause: cause);
  }

  /// Select text between the global positions [from] and [to].
  ///
  /// [from] corresponds to the [TextSelection.baseOffset], and [to] corresponds
  /// to the [TextSelection.extentOffset].
  void selectPositionAt(
      {required Offset from,
      Offset? to,
      required SelectionChangedCause cause}) {
    _layoutText(
        minHeight: constraints.minHeight, maxHeight: constraints.maxHeight);
    final fromPosition =
        _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
    final toPosition = (to == null)
        ? null
        : _textPainter.getPositionForOffset(globalToLocal(to - _paintOffset));

    final baseOffset = fromPosition.offset;
    final extentOffset = toPosition?.offset ?? fromPosition.offset;

    final newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );
    _setSelection(newSelection, cause);
  }

  /// Select a word around the location of the last tap down.
  void selectWord({required SelectionChangedCause cause}) {
    selectWordsInRange(from: _lastTapDownPosition!, cause: cause);
  }

  /// Selects the set words of a paragraph in a given range of global positions.
  ///
  /// The first and last endpoints of the selection will always be at the
  /// beginning and end of a word respectively.
  void selectWordsInRange(
      {required Offset from,
      Offset? to,
      required SelectionChangedCause cause}) {
    _computeTextMetricsIfNeeded();
    final TextPosition fromPosition =
        _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
    final TextSelection fromWord = _getWordAtOffset(fromPosition);
    final TextPosition toPosition = to == null
        ? fromPosition
        : _textPainter.getPositionForOffset(globalToLocal(to - _paintOffset));
    final TextSelection toWord =
        toPosition == fromPosition ? fromWord : _getWordAtOffset(toPosition);
    final bool isFromWordBeforeToWord = fromWord.start < toWord.end;

    _setSelection(
      TextSelection(
        baseOffset: isFromWordBeforeToWord
            ? fromWord.base.offset
            : fromWord.extent.offset,
        extentOffset:
            isFromWordBeforeToWord ? toWord.extent.offset : toWord.base.offset,
        affinity: fromWord.affinity,
      ),
      cause,
    );
  }

  /// Move the selection to the beginning or end of a word.
  void selectWordEdge({required SelectionChangedCause cause}) {
    _computeTextMetricsIfNeeded();
    assert(_lastTapDownPosition != null);
    final TextPosition position = _textPainter.getPositionForOffset(
        globalToLocal(_lastTapDownPosition! - _paintOffset));
    final TextRange word = _textPainter.getWordBoundary(position);
    late TextSelection newSelection;
    if (position.offset <= word.start) {
      newSelection = TextSelection.collapsed(offset: word.start);
    } else {
      newSelection = TextSelection.collapsed(
          offset: word.end, affinity: TextAffinity.upstream);
    }
    _setSelection(newSelection, cause);
  }

  TextSelection _getWordAtOffset(TextPosition position) {
    debugAssertLayoutUpToDate();
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= plainText.length) {
      return TextSelection.fromPosition(TextPosition(
          offset: plainText.length, affinity: TextAffinity.upstream));
    }
    // If text is obscured, the entire sentence should be treated as one word.
    if (obscureText) {
      return TextSelection(baseOffset: 0, extentOffset: plainText.length);
    }
    final TextRange word = _textPainter.getWordBoundary(position);
    final int effectiveOffset;
    switch (position.affinity) {
      case TextAffinity.upstream:
        // upstream affinity is effectively -1 in text position.
        effectiveOffset = position.offset - 1;
        break;
      case TextAffinity.downstream:
        effectiveOffset = position.offset;
        break;
    }

    // On iOS, select the previous word if there is a previous word, or select
    // to the end of the next word if there is a next word. Select nothing if
    // there is neither a previous word nor a next word.
    //
    // If the platform is Android and the text is read only, try to select the
    // previous word if there is one; otherwise, select the single whitespace at
    // the position.
    if (TextLayoutMetrics.isWhitespace(plainText.codeUnitAt(effectiveOffset)) &&
        effectiveOffset > 0) {
      final TextRange? previousWord = _getPreviousWord(word.start);
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          if (previousWord == null) {
            final TextRange? nextWord = _getNextWord(word.start);
            if (nextWord == null) {
              return TextSelection.collapsed(offset: position.offset);
            }
            return TextSelection(
              baseOffset: position.offset,
              extentOffset: nextWord.end,
            );
          }
          return TextSelection(
            baseOffset: previousWord.start,
            extentOffset: position.offset,
          );
        case TargetPlatform.android:
          if (readOnly) {
            if (previousWord == null) {
              return TextSelection(
                baseOffset: position.offset,
                extentOffset: position.offset + 1,
              );
            }
            return TextSelection(
              baseOffset: previousWord.start,
              extentOffset: position.offset,
            );
          }
          break;
        case TargetPlatform.fuchsia:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    }

    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  void _layoutText(
      {double minHeight = 0.0, double maxHeight = double.infinity}) {
    if (_textLayoutLastMaxHeight == maxHeight &&
        _textLayoutLastMinHeight == minHeight) return;
    final availableMaxHeight = math.max(0.0, maxHeight - _caretMargin);
    final availableMinHeight = math.min(minHeight, availableMaxHeight);
    final textMaxHeight = _isMultiline ? availableMaxHeight : double.infinity;
    final textMinHeight = forceLine ? availableMaxHeight : availableMinHeight;
    _textPainter.layout(
      minHeight: textMinHeight,
      maxHeight: textMaxHeight,
    );
    _textLayoutLastMinHeight = minHeight;
    _textLayoutLastMaxHeight = maxHeight;
  }

  // Computes the text metrics if `_textPainter`'s layout information was marked
  // as dirty.
  //
  // This method must be called in `RenderEditable`'s public methods that expose
  // `_textPainter`'s metrics. For instance, `systemFontsDidChange` sets
  // _textPainter._paragraph to null, so accessing _textPainter's metrics
  // immediately after `systemFontsDidChange` without first calling this method
  // may crash.
  //
  // This method is also called in various paint methods (`RenderEditable.paint`
  // as well as its foreground/background painters' `paint`). It's needed
  // because invisible render objects kept in the tree by `KeepAlive` may not
  // get a chance to do layout but can still paint.
  // See https://github.com/flutter/flutter/issues/84896.
  //
  // This method only re-computes layout if the underlying `_textPainter`'s
  // layout cache is invalidated (by calling `TextPainter.markNeedsLayout`), or
  // the constraints used to layout the `_textPainter` is different. See
  // `TextPainter.layout`.
  void _computeTextMetricsIfNeeded() {
    _layoutText(
        minHeight: constraints.minHeight, maxHeight: constraints.maxHeight);
  }

  late Rect _caretPrototype;

  void _computeCaretPrototype() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _caretPrototype =
            Rect.fromLTWH(0.0, 0.0, cursorWidth + 2, cursorHeight);
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _caretPrototype = Rect.fromLTWH(_kCaretWidthOffset, 0.0,
            cursorWidth - 2.0 * _kCaretWidthOffset, cursorHeight);
        break;
    }
  }

  // Computes the offset to apply to the given [sourceOffset] so it perfectly
  // snaps to physical pixels.
  Offset _snapToPhysicalPixel(Offset sourceOffset) {
    final globalOffset = localToGlobal(sourceOffset);
    final pixelMultiple = 1.0 / _devicePixelRatio;
    return Offset(
      globalOffset.dx.isFinite
          ? (globalOffset.dx / pixelMultiple).round() * pixelMultiple -
              globalOffset.dx
          : 0,
      globalOffset.dy.isFinite
          ? (globalOffset.dy / pixelMultiple).round() * pixelMultiple -
              globalOffset.dy
          : 0,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _layoutText(
        minHeight: constraints.minHeight, maxHeight: constraints.maxHeight);
    final height = forceLine
        ? constraints.maxHeight
        : constraints.constrainHeight(_textPainter.size.height + _caretMargin);
    return Size(
        constraints.constrainWidth(_preferredWidth(constraints.maxHeight)),
        height);
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _computeTextMetricsIfNeeded();
    _computeCaretPrototype();
    // We grab _textPainter.size here because assigning to `size` on the next
    // line will trigger us to validate our intrinsic sizes, which will change
    // _textPainter's layout because the intrinsic size calculations are
    // destructive, which would mean we would get different results if we later
    // used properties on _textPainter in this method.
    // Other _textPainter state like didExceedMaxLines will also be affected,
    // though we currently don't use those here.
    // See also MongolRenderParagraph which has a similar issue.
    final Size textPainterSize = _textPainter.size;
    final double height = forceLine
        ? constraints.maxHeight
        : constraints.constrainWidth(_textPainter.size.height + _caretMargin);
    final double preferredWidth = _preferredWidth(constraints.maxHeight);
    size = Size(constraints.constrainWidth(preferredWidth), height);
    final Size contentSize = Size(
      textPainterSize.width,
      textPainterSize.height + _caretMargin,
    );

    final BoxConstraints painterConstraints = BoxConstraints.tight(contentSize);

    _foregroundRenderObject?.layout(painterConstraints);
    _backgroundRenderObject?.layout(painterConstraints);

    _maxScrollExtent = _getMaxScrollExtent(contentSize);
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(0.0, _maxScrollExtent);
  }

  MapEntry<int, Offset> _lineNumberFor(
    TextPosition startPosition,
    List<MongolLineMetrics> metrics,
  ) {
    final offset = _textPainter.getOffsetForCaret(startPosition, Rect.zero);
    for (final MongolLineMetrics lineMetrics in metrics) {
      if (lineMetrics.baseline > offset.dx) {
        return MapEntry<int, Offset>(
          lineMetrics.lineNumber,
          Offset(lineMetrics.baseline, offset.dy),
        );
      }
    }
    assert(
      startPosition.offset == 0,
      'unable to find the line for $startPosition',
    );
    return MapEntry<int, Offset>(
      math.max(0, metrics.length - 1),
      Offset(
          metrics.isNotEmpty
              ? metrics.last.baseline + metrics.last.ascent
              : 0.0,
          offset.dy),
    );
  }

  /// Starts a [HorizontalCaretMovementRun] at the given location in the text, for
  /// handling consecutive horizontal caret movements.
  ///
  /// This can be used to handle consecutive left/right arrow key movements
  /// in an input field.
  ///
  /// The [HorizontalCaretMovementRun.isValid] property indicates whether the text
  /// layout has changed and the horizontal caret run is invalidated.
  ///
  /// The caller should typically discard a [HorizontalCaretMovementRun] when
  /// its [HorizontalCaretMovementRun.isValid] becomes false, or on other
  /// occasions where the horizontal caret run should be interrupted.
  HorizontalCaretMovementRun startHorizontalCaretMovement(
      TextPosition startPosition) {
    final List<MongolLineMetrics> metrics = _textPainter.computeLineMetrics();
    final MapEntry<int, Offset> currentLine =
        _lineNumberFor(startPosition, metrics);
    return HorizontalCaretMovementRun._(
      this,
      metrics,
      startPosition,
      currentLine.key,
      currentLine.value,
    );
  }

  void _paintContents(PaintingContext context, Offset offset) {
    debugAssertLayoutUpToDate();
    final effectiveOffset = offset + _paintOffset;

    if (selection != null) {
      _updateSelectionExtentsVisibility(effectiveOffset);
    }

    final RenderBox? foregroundChild = _foregroundRenderObject;
    final RenderBox? backgroundChild = _backgroundRenderObject;

    // The painters paint in the viewport's coordinate space, since the
    // textPainter's coordinate space is not known to high level widgets.
    if (backgroundChild != null) context.paintChild(backgroundChild, offset);

    _textPainter.paint(context.canvas, effectiveOffset);

    if (foregroundChild != null) context.paintChild(foregroundChild, offset);
  }

  void _paintHandleLayers(
    PaintingContext context,
    List<TextSelectionPoint> endpoints,
    Offset offset,
  ) {
    var startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width),
      startPoint.dy.clamp(0.0, size.height),
    );
    context.pushLayer(
      LeaderLayer(link: startHandleLayerLink, offset: startPoint + offset),
      super.paint,
      Offset.zero,
    );
    if (endpoints.length == 2) {
      var endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width),
        endPoint.dy.clamp(0.0, size.height),
      );
      context.pushLayer(
        LeaderLayer(link: endHandleLayerLink, offset: endPoint + offset),
        super.paint,
        Offset.zero,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _computeTextMetricsIfNeeded();
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintContents,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      _paintContents(context, offset);
    }
    final TextSelection? selection = this.selection;
    if (selection != null && selection.isValid) {
      _paintHandleLayers(context, getEndpointsForSelection(selection), offset);
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _hasVisualOverflow ? Offset.zero & size : null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('cursorColor', cursorColor));
    properties.add(
        DiagnosticsProperty<ValueNotifier<bool>>('showCursor', showCursor));
    properties.add(IntProperty('maxLines', maxLines));
    properties.add(IntProperty('minLines', minLines));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(ColorProperty('selectionColor', selectionColor));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties.add(DiagnosticsProperty<TextSelection>('selection', selection));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      if (text != null)
        text!.toDiagnosticsNode(
          name: 'text',
          style: DiagnosticsTreeStyle.transition,
        ),
    ];
  }
}

class _MongolRenderEditableCustomPaint extends RenderBox {
  _MongolRenderEditableCustomPaint({
    MongolRenderEditablePainter? painter,
  })  : _painter = painter,
        super();

  @override
  MongolRenderEditable? get parent => super.parent as MongolRenderEditable?;

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  MongolRenderEditablePainter? get painter => _painter;
  MongolRenderEditablePainter? _painter;

  set painter(MongolRenderEditablePainter? newValue) {
    if (newValue == painter) return;

    final oldPainter = painter;
    _painter = newValue;

    if (newValue?.shouldRepaint(oldPainter) ?? true) markNeedsPaint();

    if (attached) {
      oldPainter?.removeListener(markNeedsPaint);
      newValue?.addListener(markNeedsPaint);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final parent = this.parent;
    assert(parent != null);
    final painter = this.painter;
    if (painter != null && parent != null) {
      parent._computeTextMetricsIfNeeded();
      painter.paint(context.canvas, size, parent);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _painter?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
}

/// An interface that paints within a [MongolRenderEditable]'s bounds, above or
/// beneath its text content.
///
/// This painter is typically used for painting auxiliary content that depends
/// on text layout metrics (for instance, for painting carets and text highlight
/// blocks). It can paint independently from its [MongolRenderEditable],
/// allowing it to repaint without triggering a repaint on the entire
/// [MongolRenderEditable] stack when only auxiliary content changes (e.g. a
/// blinking cursor) are present. It will be scheduled to repaint when:
///
///  * It's assigned to a new [MongolRenderEditable] and the [shouldRepaint]
///    method returns true.
///  * Any of the [MongolRenderEditable]s it is attached to repaints.
///  * The [notifyListeners] method is called, which typically happens when the
///    painter's attributes change.
///
/// See also:
///
///  * [MongolRenderEditable.foregroundPainter], which takes a
///    [MongolRenderEditablePainter] and sets it as the foreground painter of
///    the [MongolRenderEditable].
///  * [MongolRenderEditable.painter], which takes a [MongolRenderEditablePainter]
///    and sets it as the background painter of the [MongolRenderEditable].
///  * [CustomPainter] a similar class which paints within a [RenderCustomPaint].
abstract class MongolRenderEditablePainter extends ChangeNotifier {
  /// Determines whether repaint is needed when a new
  /// [MongolRenderEditablePainter] is provided to a [MongolRenderEditable].
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false. When [oldDelegate] is null, this method should always return true
  /// unless the new painter initially does not paint anything.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away. However, the [paint] method will get called whenever the
  /// [MongolRenderEditable]s it attaches to repaint, even if [shouldRepaint]
  /// returns false.
  bool shouldRepaint(MongolRenderEditablePainter? oldDelegate);

  /// Paints within the bounds of a [MongolRenderEditable].
  ///
  /// The given [Canvas] has the same coordinate space as the
  /// [MongolRenderEditable], which may be different from the coordinate space
  /// the [MongolRenderEditable]'s [MongolTextPainter] uses, when the text moves
  /// inside the [MongolRenderEditable].
  ///
  /// Paint operations performed outside of the region defined by the [canvas]'s
  /// origin and the [size] parameter may get clipped, when
  /// [MongolRenderEditable]'s [MongolRenderEditable.clipBehavior] is not
  /// [Clip.none].
  void paint(Canvas canvas, Size size, MongolRenderEditable renderEditable);
}

class _TextHighlightPainter extends MongolRenderEditablePainter {
  _TextHighlightPainter({TextRange? highlightedRange, Color? highlightColor})
      : _highlightedRange = highlightedRange,
        _highlightColor = highlightColor;

  final Paint highlightPaint = Paint();

  Color? get highlightColor => _highlightColor;
  Color? _highlightColor;

  set highlightColor(Color? newValue) {
    if (newValue == _highlightColor) return;
    _highlightColor = newValue;
    notifyListeners();
  }

  TextRange? get highlightedRange => _highlightedRange;
  TextRange? _highlightedRange;

  set highlightedRange(TextRange? newValue) {
    if (newValue == _highlightedRange) return;
    _highlightedRange = newValue;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size, MongolRenderEditable renderEditable) {
    final range = highlightedRange;
    final color = highlightColor;
    if (range == null || color == null || range.isCollapsed) {
      return;
    }

    highlightPaint.color = color;
    final boxes = renderEditable._textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );

    for (final box in boxes) {
      canvas.drawRect(box.shift(renderEditable._paintOffset), highlightPaint);
    }
  }

  @override
  bool shouldRepaint(MongolRenderEditablePainter? oldDelegate) {
    if (identical(oldDelegate, this)) {
      return false;
    }
    if (oldDelegate == null) {
      return highlightColor != null && highlightedRange != null;
    }
    return oldDelegate is! _TextHighlightPainter ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.highlightedRange != highlightedRange;
  }
}

class _CaretPainter extends MongolRenderEditablePainter {
  _CaretPainter();

  bool get shouldPaint => _shouldPaint;
  bool _shouldPaint = true;

  set shouldPaint(bool value) {
    if (shouldPaint == value) return;
    _shouldPaint = value;
    notifyListeners();
  }

  bool showRegularCaret = false;

  final Paint caretPaint = Paint();
  late final Paint floatingCursorPaint = Paint();

  Color? get caretColor => _caretColor;
  Color? _caretColor;

  set caretColor(Color? value) {
    if (caretColor?.value == value?.value) return;

    _caretColor = value;
    notifyListeners();
  }

  Radius? get cursorRadius => _cursorRadius;
  Radius? _cursorRadius;

  set cursorRadius(Radius? value) {
    if (_cursorRadius == value) return;
    _cursorRadius = value;
    notifyListeners();
  }

  Offset get cursorOffset => _cursorOffset;
  Offset _cursorOffset = Offset.zero;

  set cursorOffset(Offset value) {
    if (_cursorOffset == value) return;
    _cursorOffset = value;
    notifyListeners();
  }

  void paintRegularCursor(
    Canvas canvas,
    MongolRenderEditable renderEditable,
    Color caretColor,
    TextPosition textPosition,
  ) {
    final integralRect = renderEditable.getLocalRectForCaret(textPosition);
    if (shouldPaint) {
      final radius = cursorRadius;
      caretPaint.color = caretColor;
      if (radius == null) {
        canvas.drawRect(integralRect, caretPaint);
      } else {
        final caretRRect = RRect.fromRectAndRadius(integralRect, radius);
        canvas.drawRRect(caretRRect, caretPaint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size, MongolRenderEditable renderEditable) {
    // Compute the caret location even when `shouldPaint` is false.

    final selection = renderEditable.selection;

    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final caretColor = this.caretColor;
    final caretTextPosition = selection.extent;

    if (caretColor != null) {
      paintRegularCursor(canvas, renderEditable, caretColor, caretTextPosition);
    }
  }

  @override
  bool shouldRepaint(MongolRenderEditablePainter? oldDelegate) {
    if (identical(this, oldDelegate)) return false;

    if (oldDelegate == null) return shouldPaint;
    return oldDelegate is! _CaretPainter ||
        oldDelegate.shouldPaint != shouldPaint ||
        oldDelegate.caretColor != caretColor ||
        oldDelegate.cursorRadius != cursorRadius ||
        oldDelegate.cursorOffset != cursorOffset;
  }
}

class _CompositeRenderEditablePainter extends MongolRenderEditablePainter {
  _CompositeRenderEditablePainter({required this.painters});

  final List<MongolRenderEditablePainter> painters;

  @override
  void addListener(VoidCallback listener) {
    for (final painter in painters) {
      painter.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final painter in painters) {
      painter.removeListener(listener);
    }
  }

  @override
  void paint(Canvas canvas, Size size, MongolRenderEditable renderEditable) {
    for (final painter in painters) {
      painter.paint(canvas, size, renderEditable);
    }
  }

  @override
  bool shouldRepaint(MongolRenderEditablePainter? oldDelegate) {
    if (identical(oldDelegate, this)) return false;
    if (oldDelegate is! _CompositeRenderEditablePainter ||
        oldDelegate.painters.length != painters.length) return true;

    final oldPainters = oldDelegate.painters.iterator;
    final newPainters = painters.iterator;
    while (oldPainters.moveNext() && newPainters.moveNext()) {
      if (newPainters.current.shouldRepaint(oldPainters.current)) return true;
    }

    return false;
  }
}
