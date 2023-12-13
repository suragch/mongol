// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui hide TextStyle;

import 'package:characters/characters.dart'
    show CharacterRange, StringCharacters;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart'
    show
        ContentInsertionConfiguration,
        kDefaultContentInsertionMimeTypes,
        DeleteToNextWordBoundaryIntent,
        ExpandSelectionToDocumentBoundaryIntent,
        ExtendSelectionVerticallyToAdjacentLineIntent,
        ReplaceTextIntent,
        ScrollToDocumentBoundaryIntent,
        Size,
        kMinInteractiveDimension;
import 'package:flutter/rendering.dart' show RevealedOffset, ViewportOffset;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'
    show
        Action,
        Actions,
        AnimationController,
        AppPrivateCommandCallback,
        AutofillGroup,
        AutofillGroupState,
        AutomaticKeepAliveClientMixin,
        AxisDirection,
        BuildContext,
        CallbackAction,
        CharacterRange,
        Clip,
        ClipboardStatus,
        ClipboardStatusNotifier,
        Color,
        CompositedTransformTarget,
        ContextAction,
        ContextMenuButtonItem,
        ContextMenuButtonType,
        CopySelectionTextIntent,
        Curve,
        Curves,
        DeleteCharacterIntent,
        DeleteToLineBreakIntent,
        DirectionalCaretMovementIntent,
        DirectionalFocusAction,
        DirectionalFocusIntent,
        DirectionalTextEditingIntent,
        DismissIntent,
        DoNothingAction,
        DoNothingAndStopPropagationTextIntent,
        EdgeInsets,
        ExpandSelectionToLineBreakIntent,
        ExtendSelectionByCharacterIntent,
        ExtendSelectionByPageIntent,
        ExtendSelectionToDocumentBoundaryIntent,
        ExtendSelectionToLineBreakIntent,
        ExtendSelectionToNextWordBoundaryIntent,
        ExtendSelectionToNextWordBoundaryOrCaretLocationIntent,
        Focus,
        FocusNode,
        FocusScope,
        GlobalKey,
        Intent,
        intentForMacOSSelector,
        LayerLink,
        LeafRenderObjectWidget,
        MediaQuery,
        MouseRegion,
        Offset,
        Orientation,
        PasteTextIntent,
        PointerDownEvent,
        primaryFocus,
        Radius,
        Rect,
        RedoTextIntent,
        ScrollBehavior,
        ScrollConfiguration,
        ScrollController,
        ScrollPhysics,
        Scrollable,
        ScrollableState,
        ScrollIntent,
        ScrollIncrementType,
        ScrollPosition,
        ScrollAction,
        SelectAllTextIntent,
        SelectionChangedCallback,
        Semantics,
        Simulation,
        State,
        StatefulWidget,
        TapRegionCallback,
        TextAlign,
        TextDirection,
        TextEditingController,
        TextFieldTapRegion,
        TextMagnifierConfiguration,
        TextSelectionControls,
        TextSelectionHandleType,
        TextSelectionHandleControls,
        TextSelectionToolbarAnchors,
        TextSelectionPoint,
        TextSpan,
        TextStyle,
        TickerMode,
        TickerProviderStateMixin,
        ToolbarOptions,
        TransposeCharactersIntent,
        UndoTextIntent,
        UpdateSelectionIntent,
        Widget,
        WidgetsBinding,
        WidgetsBindingObserver,
        debugCheckHasMediaQuery;
//import 'package:flutter/widgets.dart' hide EditableText, EditableTextState;

import 'package:mongol/src/base/mongol_text_align.dart';
import 'package:mongol/src/editing/mongol_render_editable.dart';
import 'package:mongol/src/editing/text_selection/mongol_text_selection.dart';

import 'mongol_text_editing_intents.dart';

export 'package:flutter/services.dart'
    show
        SelectionChangedCause,
        TextEditingValue,
        TextSelection,
        TextInputType,
        SmartQuotesType,
        SmartDashesType;

/// Signature for a widget builder that builds a context menu for the given
/// [MongolEditableTextState].
///
/// See also:
///
///  * [SelectableRegionContextMenuBuilder], which performs the same role for
///    [SelectableRegion].
typedef MongolEditableTextContextMenuBuilder = Widget Function(
  BuildContext context,
  MongolEditableTextState editableTextState,
);

// The time it takes for the cursor to fade from fully opaque to fully
// transparent and vice versa. A full cursor blink, from transparent to opaque
// to transparent, is twice this duration.
const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

// Number of cursor ticks during which the most recently entered character
// is shown in an obscured text field.
const int _kObscureShowLatestCharCursorTicks = 3;

// A time-value pair that represents a key frame in an animation.
class _KeyFrame {
  const _KeyFrame(this.time, this.value);
  // Values extracted from iOS 15.4 UIKit.
  static const List<_KeyFrame> iOSBlinkingCaretKeyFrames = <_KeyFrame>[
    _KeyFrame(0, 1), // 0
    _KeyFrame(0.5, 1), // 1
    _KeyFrame(0.5375, 0.75), // 2
    _KeyFrame(0.575, 0.5), // 3
    _KeyFrame(0.6125, 0.25), // 4
    _KeyFrame(0.65, 0), // 5
    _KeyFrame(0.85, 0), // 6
    _KeyFrame(0.8875, 0.25), // 7
    _KeyFrame(0.925, 0.5), // 8
    _KeyFrame(0.9625, 0.75), // 9
    _KeyFrame(1, 1), // 10
  ];

  // The timing, in seconds, of the specified animation `value`.
  final double time;
  final double value;
}

class _DiscreteKeyFrameSimulation extends Simulation {
  _DiscreteKeyFrameSimulation.iOSBlinkingCaret()
      : this._(_KeyFrame.iOSBlinkingCaretKeyFrames, 1);
  _DiscreteKeyFrameSimulation._(this._keyFrames, this.maxDuration)
      : assert(_keyFrames.isNotEmpty),
        assert(_keyFrames.last.time <= maxDuration),
        assert(() {
          for (int i = 0; i < _keyFrames.length - 1; i += 1) {
            if (_keyFrames[i].time > _keyFrames[i + 1].time) {
              return false;
            }
          }
          return true;
        }(), 'The key frame sequence must be sorted by time.');

  final double maxDuration;

  final List<_KeyFrame> _keyFrames;

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => time >= maxDuration;

  // The index of the KeyFrame corresponds to the most recent input `time`.
  int _lastKeyFrameIndex = 0;

  @override
  double x(double time) {
    final int length = _keyFrames.length;

    // Perform a linear search in the sorted key frame list, starting from the
    // last key frame found, since the input `time` usually monotonically
    // increases by a small amount.
    int searchIndex;
    final int endIndex;
    if (_keyFrames[_lastKeyFrameIndex].time > time) {
      // The simulation may have restarted. Search within the index range
      // [0, _lastKeyFrameIndex).
      searchIndex = 0;
      endIndex = _lastKeyFrameIndex;
    } else {
      searchIndex = _lastKeyFrameIndex;
      endIndex = length;
    }

    // Find the target key frame. Don't have to check (endIndex - 1): if
    // (endIndex - 2) doesn't work we'll have to pick (endIndex - 1) anyways.
    while (searchIndex < endIndex - 1) {
      assert(_keyFrames[searchIndex].time <= time);
      final _KeyFrame next = _keyFrames[searchIndex + 1];
      if (time < next.time) {
        break;
      }
      searchIndex += 1;
    }

    _lastKeyFrameIndex = searchIndex;
    return _keyFrames[_lastKeyFrameIndex].value;
  }
}

/// A basic text input field.
///
/// This widget interacts with the [TextInput] service to let the user edit the
/// text it contains. It also provides scrolling, selection, and cursor
/// movement. This widget does not provide any focus management (e.g.,
/// tap-to-focus).
///
/// ## Handling User Input
///
/// Currently the user may change the text this widget contains via keyboard or
/// the text selection menu. When the user inserted or deleted text, you will be
/// notified of the change and get a chance to modify the new text value:
///
/// * The [inputFormatters] will be first applied to the user input.
///
/// * The [controller]'s [TextEditingController.value] will be updated with the
///   formatted result, and the [controller]'s listeners will be notified.
///
/// * The [onChanged] callback, if specified, will be called last.
///
/// ## Input Actions
///
/// A [TextInputAction] can be provided to customize the appearance of the
/// action button on the soft keyboard for Android and iOS. The default action
/// is [TextInputAction.done].
///
/// Many [TextInputAction]s are common between Android and iOS. However, if a
/// [textInputAction] is provided that is not supported by the current
/// platform in debug mode, an error will be thrown when the corresponding
/// MongolEditableText receives focus. For example, providing iOS's "emergencyCall"
/// action when running on an Android device will result in an error when in
/// debug mode. In release mode, incompatible [TextInputAction]s are replaced
/// either with "unspecified" on Android, or "default" on iOS. Appropriate
/// [textInputAction]s can be chosen by checking the current platform and then
/// selecting the appropriate action.
///
/// ## Lifecycle
///
/// Upon completion of editing, like pressing the "done" button on the keyboard,
/// two actions take place:
///
///   1st: Editing is finalized. The default behavior of this step includes
///   an invocation of [onChanged]. That default behavior can be overridden.
///   See [onEditingComplete] for details.
///
///   2nd: [onSubmitted] is invoked with the user's input value.
///
/// [onSubmitted] can be used to manually move focus to another input widget
/// when a user finishes with the currently focused input widget.
///
/// Rather than using this widget directly, consider using [MongolTextField], which
/// is a full-featured, material-design text input field with placeholder text,
/// labels, and [Form] integration.
///
/// ## Gesture Events Handling
///
/// This widget provides rudimentary, platform-agnostic gesture handling for
/// user actions such as tapping, long-pressing and scrolling when
/// [rendererIgnoresPointer] is false (false by default). For custom selection
/// behavior, call methods such as [MongolRenderEditable.selectPosition],
/// [MongolRenderEditable.selectWord], etc. programmatically.
///
/// See also:
///
///  * [MongolTextField], which is a full-featured, material-design text input
///    field with placeholder text, labels, and [Form] integration.
class MongolEditableText extends StatefulWidget {
  /// Creates a basic text input control.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is one, meaning this is a single-line
  /// text field. [maxLines] must be null or greater than zero.
  ///
  /// If [keyboardType] is not set or is null, its value will be inferred from
  /// [autofillHints], if [autofillHints] is not empty. Otherwise it defaults to
  /// [TextInputType.text] if [maxLines] is exactly one, and
  /// [TextInputType.multiline] if [maxLines] is null or greater than one.
  ///
  /// The text cursor is not shown if [showCursor] is false or if [showCursor]
  /// is null (the default) and [readOnly] is true.
  MongolEditableText({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.readOnly = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    required this.style,
    required this.cursorColor,
    this.textAlign = MongolTextAlign.top,
    this.textScaleFactor,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.forceLine = true,
    this.autofocus = false,
    bool? showCursor,
    this.showSelectionHandles = false,
    this.selectionColor,
    this.selectionControls,
    TextInputType? keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.onSelectionChanged,
    this.onSelectionHandleTapped,
    this.onTapOutside,
    List<TextInputFormatter>? inputFormatters,
    this.mouseCursor,
    this.rendererIgnoresPointer = false,
    this.cursorHeight = 2.0,
    this.cursorWidth,
    this.cursorRadius,
    this.cursorOpacityAnimates = false,
    this.cursorOffset,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.keyboardAppearance = Brightness.light,
    this.dragStartBehavior = DragStartBehavior.start,
    bool? enableInteractiveSelection,
    this.scrollController,
    this.scrollPhysics,
    @Deprecated(
      'Use `contextMenuBuilder` instead. '
      'This feature was deprecated after v3.3.0-0.5.pre.',
    )
    ToolbarOptions? toolbarOptions,
    this.autofillHints,
    this.autofillClient,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.scrollBehavior,
    this.contentInsertionConfiguration,
    this.contextMenuBuilder,
    this.magnifierConfiguration = TextMagnifierConfiguration.disabled,
  })  : assert(obscuringCharacter.length == 1),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        ),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(!obscureText || maxLines == 1,
            'Obscured fields cannot be multiline.'),
        assert(
          !readOnly || autofillHints == null,
          "Read-only fields can't have autofill hints.",
        ),
        enableInteractiveSelection =
            enableInteractiveSelection ?? (!readOnly || !obscureText),
        toolbarOptions = selectionControls is TextSelectionHandleControls &&
                toolbarOptions == null
            ? ToolbarOptions.empty
            : toolbarOptions ??
                (obscureText
                    ? (readOnly
                        // No point in even offering "Select All" in a read-only obscured
                        // field.
                        ? ToolbarOptions.empty
                        // Writable, but obscured.
                        : const ToolbarOptions(
                            selectAll: true,
                            paste: true,
                          ))
                    : (readOnly
                        // Read-only, not obscured.
                        ? const ToolbarOptions(
                            selectAll: true,
                            copy: true,
                          )
                        // Writable, not obscured.
                        : const ToolbarOptions(
                            copy: true,
                            cut: true,
                            selectAll: true,
                            paste: true,
                          ))),
        keyboardType = keyboardType ??
            _inferKeyboardType(
                autofillHints: autofillHints, maxLines: maxLines),
        inputFormatters = maxLines == 1
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.singleLineFormatter,
                ...inputFormatters ??
                    const Iterable<TextInputFormatter>.empty(),
              ]
            : inputFormatters,
        showCursor = showCursor ?? !readOnly,
        super(key: key);

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Controls whether this widget has keyboard focus.
  final FocusNode focusNode;

  /// Character used for obscuring text if [obscureText] is true.
  ///
  /// Must be only a single character.
  ///
  /// Defaults to the character U+2022 BULLET (•).
  final String obscuringCharacter;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the text field are
  /// replaced by [obscuringCharacter].
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Whether the text can be changed.
  ///
  /// When this is set to true, the text cannot be modified
  /// by any shortcut or keyboard operation. The text is still selectable.
  ///
  /// Defaults to false.
  final bool readOnly;

  /// Whether the text will take the full height regardless of the text height.
  ///
  /// When this is set to false, the height will be based on text height.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///  * [textWidthBasis], which controls the calculation of text width.
  final bool forceLine;

  /// Configuration of toolbar options.
  ///
  /// By default, all options are enabled. If [readOnly] is true,
  /// paste and cut will be disabled regardless.
  final ToolbarOptions toolbarOptions;

  /// Whether to show selection handles.
  ///
  /// When a selection is active, there will be two handles at each side of
  /// boundary, or one handle if the selection is collapsed. The handles can be
  /// dragged to adjust the selection.
  ///
  /// See also:
  ///
  ///  * [showCursor], which controls the visibility of the cursor.
  final bool showSelectionHandles;

  /// Whether to show cursor.
  ///
  /// The cursor refers to the blinking caret when the [MongolEditableText] is
  /// focused.
  ///
  /// See also:
  ///
  ///  * [showSelectionHandles], which controls the visibility of the selection
  ///    handles.
  final bool showCursor;

  /// Whether to enable autocorrection.
  ///
  /// Defaults to true. Cannot be null.
  final bool autocorrect;

  /// Whether to show input suggestions as the user types.
  ///
  /// This flag only affects Android. On iOS, suggestions are tied directly to
  /// [autocorrect], so that suggestions are only shown when [autocorrect] is
  /// true. On Android autocorrection and suggestion are controlled separately.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///  * <https://developer.android.com/reference/android/text/InputType.html#TYPE_TEXT_FLAG_NO_SUGGESTIONS>
  final bool enableSuggestions;

  /// The text style to use for the editable text.
  final TextStyle style;

  /// How the text should be aligned vertically.
  ///
  /// Defaults to [MongolTextAlign.top].
  final MongolTextAlign textAlign;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// Defaults to the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double? textScaleFactor;

  /// The color to use when painting the cursor.
  final Color cursorColor;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// vertically instead.
  ///
  /// If this is null, there is no limit to the number of lines, and the text
  /// container will start with enough horizontal space for one line and
  /// automatically grow to accommodate additional lines as they are entered.
  ///
  /// If this is not null, the value must be greater than zero, and it will lock
  /// the input to the given number of lines and take up enough vertical space
  /// to accommodate that number of lines. Setting [minLines] as well allows the
  /// input to grow between the indicated range.
  ///
  /// The full set of behaviors possible with [minLines] and [maxLines] are as
  /// follows. These examples apply equally to `MongolTextField`,
  /// `MongolTextFormField`, and `MongolEditableText`.
  ///
  /// Input that occupies a single line and scrolls vertically as needed.
  /// ```dart
  /// MongolTextField()
  /// ```
  ///
  /// Input whose width grows from one line up to as many lines as needed for
  /// the text that was entered. If a width limit is imposed by its parent, it
  /// will scroll horizontally when its width reaches that limit.
  /// ```dart
  /// MongolTextField(maxLines: null)
  /// ```
  ///
  /// The input's width is large enough for the given number of lines. If
  /// additional lines are entered the input scrolls horizontally.
  /// ```dart
  /// MongolTextField(maxLines: 2)
  /// ```
  ///
  /// Input whose width grows with content between a min and max. An infinite
  /// max is possible with `maxLines: null`.
  /// ```dart
  /// MongolTextField(minLines: 2, maxLines: 4)
  /// ```
  final int? maxLines;

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
  /// MongolTextField(minLines:2, maxLines: 4)
  /// ```
  ///
  /// See the examples in [maxLines] for the complete picture of how [maxLines]
  /// and [minLines] interact to produce various behaviors.
  ///
  /// Defaults to null.
  final int? minLines;

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
  ///   child: MongolTextField(maxLines: null, expands: true),
  /// )
  /// ```
  final bool expands;

  /// Whether this text field should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false. Cannot be null.
  // See https://github.com/flutter/flutter/issues/7035 for the rationale for this
  // keyboard behavior.
  final bool autofocus;

  /// The color to use when painting the selection.
  ///
  /// For [MongolTextField]s, the value is set to the ambient
  /// [ThemeData.textSelectionColor].
  final Color? selectionColor;

  /// Optional delegate for building the text selection handles and toolbar.
  ///
  /// The [MongolEditableText] widget used on its own will not trigger the display
  /// of the selection toolbar by itself. The toolbar is shown by calling
  /// [MongolEditableTextState.showToolbar] in response to an appropriate user event.
  ///
  /// See also:
  ///
  ///  * [MongolTextField], a Material Design themed wrapper of
  ///    [MongolEditableText], which shows the selection toolbar upon
  ///    appropriate user events based on the user's platform set in
  ///    [ThemeData.platform].
  final TextSelectionControls? selectionControls;

  /// The type of keyboard to use for editing the text.
  ///
  /// Defaults to [TextInputType.text] if [maxLines] is one and
  /// [TextInputType.multiline] otherwise.
  final TextInputType keyboardType;

  /// The type of action button to use with the soft keyboard.
  final TextInputAction? textInputAction;

  /// Called when the user initiates a change to the MongolTextField's
  /// value: when they have inserted or deleted text.
  ///
  /// This callback doesn't run when the MongolTextField's text is changed
  /// programmatically, via the MongolTextField's [controller]. Typically it
  /// isn't necessary to be notified of such changes, since they're
  /// initiated by the app itself.
  ///
  /// To be notified of all changes to the MongolTextField's text, cursor,
  /// and selection, one can add a listener to its [controller] with
  /// [TextEditingController.addListener].
  ///
  /// ## Handling emojis and other complex characters
  ///
  /// It's important to always use
  /// [characters](https://pub.dev/packages/characters) when dealing with user
  /// input text that may contain complex characters. This will ensure that
  /// extended grapheme clusters and surrogate pairs are treated as single
  /// characters, as they appear to the user.
  ///
  /// For example, when finding the length of some user input, use
  /// `string.characters.length`. Do NOT use `string.length` or even
  /// `string.runes.length`. For the complex character "👨‍👩‍👦", this
  /// appears to the user as a single character, and `string.characters.length`
  /// intuitively returns 1. On the other hand, `string.length` returns 8, and
  /// `string.runes.length` returns 5!
  ///
  /// See also:
  ///
  ///  * [inputFormatters], which are called before [onChanged]
  ///    runs and can validate and change ("format") the input value.
  ///  * [onEditingComplete], [onSubmitted], [onSelectionChanged]:
  ///    which are more specialized input change notifications.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits editable content (e.g., user presses the "done"
  /// button on the keyboard).
  ///
  /// The default implementation of [onEditingComplete] executes 2 different
  /// behaviors based on the situation:
  ///
  ///  - When a completion action is pressed, such as "done", "go", "send", or
  ///    "search", the user's content is submitted to the [controller] and then
  ///    focus is given up.
  ///
  ///  - When a non-completion action is pressed, such as "next" or "previous",
  ///    the user's content is submitted to the [controller], but focus is not
  ///    given up because developers may want to immediately move focus to
  ///    another input widget within [onSubmitted].
  ///
  /// Providing [onEditingComplete] prevents the aforementioned default behavior.
  final VoidCallback? onEditingComplete;

  /// Called when the user indicates that they are done editing the text in the
  /// field.
  final ValueChanged<String>? onSubmitted;

  /// This is used to receive a private command from the input method.
  ///
  /// Called when the result of [TextInputClient.performPrivateCommand] is
  /// received.
  ///
  /// This can be used to provide domain-specific features that are only known
  /// between certain input methods and their clients.
  ///
  /// See also:
  ///   * [https://developer.android.com/reference/android/view/inputmethod/InputConnection#performPrivateCommand(java.lang.String,%20android.os.Bundle)],
  ///     which is the Android documentation for performPrivateCommand, used to
  ///     send a command from the input method.
  ///   * [https://developer.android.com/reference/android/view/inputmethod/InputMethodManager#sendAppPrivateCommand],
  ///     which is the Android documentation for sendAppPrivateCommand, used to
  ///     send a command to the input method.
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// Called when the user changes the selection of text (including the cursor
  /// location).
  final SelectionChangedCallback? onSelectionChanged;

  /// A callback that's invoked when a selection handle is tapped.
  ///
  /// Both regular taps and long presses invoke this callback, but a drag
  /// gesture won't.
  final VoidCallback? onSelectionHandleTapped;

  /// Called for each tap that occurs outside of the [TextFieldTapRegion]
  /// group when the text field is focused.
  ///
  /// If this is null, [FocusNode.unfocus] will be called on the [focusNode] for
  /// this text field when a [PointerDownEvent] is received on another part of
  /// the UI. However, it will not unfocus as a result of mobile application
  /// touch events (which does not include mouse clicks), to conform with the
  /// platform conventions. To change this behavior, a callback may be set here
  /// that operates differently from the default.
  ///
  /// When adding additional controls to a text field (for example, a spinner, a
  /// button that copies the selected text, or modifies formatting), it is
  /// helpful if tapping on that control doesn't unfocus the text field. In
  /// order for an external widget to be considered as part of the text field
  /// for the purposes of tapping "outside" of the field, wrap the control in a
  /// [TextFieldTapRegion].
  ///
  /// The [PointerDownEvent] passed to the function is the event that caused the
  /// notification. It is possible that the event may occur outside of the
  /// immediate bounding box defined by the text field, although it will be
  /// within the bounding box of a [TextFieldTapRegion] member.
  ///
  /// See also:
  ///
  ///  * [TapRegion] for how the region group is determined.
  final TapRegionCallback? onTapOutside;

  /// Optional input validation and formatting overrides.
  ///
  /// Formatters are run in the provided order when the text input changes. When
  /// this parameter changes, the new formatters will not be applied until the
  /// next time the user inserts or deletes text.
  final List<TextInputFormatter>? inputFormatters;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If this property is null, [SystemMouseCursors.text] will be used.
  ///
  /// The [mouseCursor] is the only property of [MongolEditableText] that controls the
  /// appearance of the mouse pointer. All other properties related to "cursor"
  /// stands for the text cursor, which is usually a blinking vertical line at
  /// the editing position.
  final MouseCursor? mouseCursor;

  /// If true, the [MongolRenderEditable] created by this widget will not handle
  /// pointer events, see [MongolRenderEditable] and
  /// [MongolRenderEditable.ignorePointer].
  ///
  /// This property is false by default.
  final bool rendererIgnoresPointer;

  /// How wide the cursor will be.
  ///
  /// If this property is null, [MongolRenderEditable.preferredLineWidth] will
  /// be used.
  final double? cursorWidth;

  /// How thick the cursor will be.
  ///
  /// Defaults to 2.0.
  ///
  /// The cursor will draw above the text. The cursor height will extend
  /// down from the boundary between characters. This corresponds to extending
  /// downstream relative to the selected position. Negative values may be used
  /// to reverse this behavior.
  final double cursorHeight;

  /// How rounded the corners of the cursor should be.
  ///
  /// By default, the cursor has no radius.
  final Radius? cursorRadius;

  /// Whether the cursor will animate from fully transparent to fully opaque
  /// during each cursor blink.
  ///
  /// By default, the cursor opacity will animate on iOS platforms and will not
  /// animate on Android platforms.
  final bool cursorOpacityAnimates;

  /// The offset that is used, in pixels, when painting the cursor on screen.
  ///
  /// By default, the cursor position should be set to an offset of
  /// (0.0, -[cursorHeight] * 0.5) on iOS platforms and (0, 0) on Android
  /// platforms. The origin from where the offset is applied to is the arbitrary
  /// location where the cursor ends up being rendered from by default.
  final Offset? cursorOffset;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// Configures padding to edges surrounding a [Scrollable] when the
  /// MongolTextField scrolls into view.
  ///
  /// When this widget receives focus and is not completely visible (for
  /// example scrolled partially off the screen or overlapped by the keyboard)
  /// then it will attempt to make itself visible by scrolling a surrounding
  /// [Scrollable], if one is present. This value controls how far from the
  /// edges of a [Scrollable] the MongolTextField will be positioned after the
  /// scroll.
  ///
  /// Defaults to EdgeInsets.all(20.0).
  final EdgeInsets scrollPadding;

  /// Whether to enable user interface affordances for changing the
  /// text selection.
  ///
  /// For example, setting this to true will enable features such as
  /// long-pressing the MongolTextField to select text and show the
  /// cut/copy/paste menu, and tapping to move the text caret.
  ///
  /// When this is false, the text selection cannot be adjusted by
  /// the user, text cannot be copied, and the user cannot paste into
  /// the text field from the clipboard.
  final bool enableInteractiveSelection;

  /// Setting this property to true makes the cursor stop blinking or fading
  /// on and off once the cursor appears on focus. This property is useful for
  /// testing purposes.
  ///
  /// It does not affect the necessity to focus the EditableText for the cursor
  /// to appear in the first place.
  ///
  /// Defaults to false, resulting in a typical blinking cursor.
  static bool debugDeterministicCursor = false;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], scrolling drag behavior will
  /// begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first detected.
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

  /// The [ScrollController] to use when horizontally scrolling the input.
  ///
  /// If null, it will instantiate a new ScrollController.
  ///
  /// See [Scrollable.controller].
  final ScrollController? scrollController;

  /// The [ScrollPhysics] to use when horizontally scrolling the input.
  ///
  /// If not specified, it will behave according to the current platform.
  ///
  /// See [Scrollable.physics].
  ///
  /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [scrollPhysics].
  final ScrollPhysics? scrollPhysics;

  /// Same as [enableInteractiveSelection].
  ///
  /// This getter exists primarily for consistency with
  /// [MongolRenderEditable.selectionEnabled].
  bool get selectionEnabled => enableInteractiveSelection;

  /// A list of strings that helps the autofill service identify the type of this
  /// text input.
  ///
  /// When set to null or empty, this text input will not send its autofill
  /// information to the platform, preventing it from participating in
  /// autofills triggered by a different [AutofillClient], even if they're in the
  /// same [AutofillScope]. Additionally, on Android and web, setting this to
  /// null or empty will disable autofill for this text field.
  ///
  /// The minimum platform SDK version that supports Autofill is API level 26
  /// for Android, and iOS 10.0 for iOS.
  ///
  /// ### Setting up iOS autofill:
  ///
  /// To provide the best user experience and ensure your app fully supports
  /// password autofill on iOS, follow these steps:
  ///
  /// * Set up your iOS app's
  ///   [associated domains](https://developer.apple.com/documentation/safariservices/supporting_associated_domains_in_your_app).
  /// * Some autofill hints only work with specific [keyboardType]s. For example,
  ///   [AutofillHints.name] requires [TextInputType.name] and [AutofillHints.email]
  ///   works only with [TextInputType.emailAddress]. Make sure the input field has a
  ///   compatible [keyboardType]. Empirically, [TextInputType.name] works well
  ///   with many autofill hints that are predefined on iOS.
  ///
  /// ### Troubleshooting Autofill
  ///
  /// Autofill service providers rely heavily on [autofillHints]. Make sure the
  /// entries in [autofillHints] are supported by the autofill service currently
  /// in use (the name of the service can typically be found in your mobile
  /// device's system settings).
  ///
  /// #### Autofill UI refuses to show up when I tap on the text field
  ///
  /// Check the device's system settings and make sure autofill is turned on,
  /// and there're available credentials stored in the autofill service.
  ///
  /// * iOS password autofill: Go to Settings -> Password, turn on "Autofill
  ///   Passwords", and add new passwords for testing by pressing the top right
  ///   "+" button. Use an arbitrary "website" if you don't have associated
  ///   domains set up for your app. As long as there's at least one password
  ///   stored, you should be able to see a key-shaped icon in the quick type
  ///   bar on the software keyboard, when a password related field is focused.
  ///
  /// * iOS contact information autofill: iOS seems to pull contact info from
  ///   the Apple ID currently associated with the device. Go to Settings ->
  ///   Apple ID (usually the first entry, or "Sign in to your iPhone" if you
  ///   haven't set up one on the device), and fill out the relevant fields. If
  ///   you wish to test more contact info types, try adding them in Contacts ->
  ///   My Card.
  ///
  /// * Android autofill: Go to Settings -> System -> Languages & input ->
  ///   Autofill service. Enable the autofill service of your choice, and make
  ///   sure there're available credentials associated with your app.
  ///
  /// #### I called `TextInput.finishAutofillContext` but the autofill save
  /// prompt isn't showing
  ///
  /// * iOS: iOS may not show a prompt or any other visual indication when it
  ///   saves user password. Go to Settings -> Password and check if your new
  ///   password is saved. Neither saving password nor auto-generating strong
  ///   password works without properly setting up associated domains in your
  ///   app. To set up associated domains, follow the instructions in
  ///   <https://developer.apple.com/documentation/safariservices/supporting_associated_domains_in_your_app>.
  final Iterable<String>? autofillHints;

  /// The [AutofillClient] that controls this input field's autofill behavior.
  ///
  /// When null, this widget's [MongolEditableTextState] will be used as the
  /// [AutofillClient]. This property may override [autofillHints].
  final AutofillClient? autofillClient;

  /// The content will be clipped (or not) according to this option.
  ///
  /// See the enum [Clip] for details of all possible options and their common
  /// use cases.
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Restoration ID to save and restore the scroll offset of the
  /// [MongolEditableText].
  ///
  /// If a restoration id is provided, the [MongolEditableText] will persist its
  /// current scroll offset and restore it during state restoration.
  ///
  /// The scroll offset is persisted in a [RestorationBucket] claimed from
  /// the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// Persisting and restoring the content of the [MongolEditableText] is the
  /// responsibility of the owner of the [controller], who may use a
  /// [RestorableTextEditingController] for that purpose.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

  /// A [ScrollBehavior] that will be applied to this widget individually.
  ///
  /// Defaults to null, wherein the inherited [ScrollBehavior] is copied and
  /// modified to alter the viewport decoration, like [Scrollbar]s.
  ///
  /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
  /// [ScrollPhysics] is provided in [scrollPhysics], it will take precedence,
  /// followed by [scrollBehavior], and then the inherited ancestor
  /// [ScrollBehavior].
  ///
  /// The [ScrollBehavior] of the inherited [ScrollConfiguration] will be
  /// modified by default to only apply a [Scrollbar] if [maxLines] is greater
  /// than 1.
  final ScrollBehavior? scrollBehavior;

  /// {@template flutter.widgets.editableText.contentInsertionConfiguration}
  /// Configuration of handler for media content inserted via the system input
  /// method.
  ///
  /// Defaults to null in which case media content insertion will be disabled,
  /// and the system will display a message informing the user that the text field
  /// does not support inserting media content.
  ///
  /// Set [ContentInsertionConfiguration.onContentInserted] to provide a handler.
  /// Additionally, set [ContentInsertionConfiguration.allowedMimeTypes]
  /// to limit the allowable mime types for inserted content.
  ///
  /// {@tool dartpad}
  ///
  /// This example shows how to access the data for inserted content in your
  /// `TextField`.
  ///
  /// ** See code in examples/api/lib/widgets/editable_text/editable_text.on_content_inserted.0.dart **
  /// {@end-tool}
  ///
  /// If [contentInsertionConfiguration] is not provided, by default
  /// an empty list of mime types will be sent to the Flutter Engine.
  /// A handler function must be provided in order to customize the allowable
  /// mime types for inserted content.
  ///
  /// If rich content is inserted without a handler, the system will display
  /// a message informing the user that the current text input does not support
  /// inserting rich content.
  /// {@endtemplate}
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// Builds the text selection toolbar when requested by the user.
  ///
  /// `primaryAnchor` is the desired anchor position for the context menu, while
  /// `secondaryAnchor` is the fallback location if the menu doesn't fit.
  ///
  /// `buttonItems` represents the buttons that would be built by default for
  /// this widget.
  ///
  /// If not provided, no context menu will be shown.
  final MongolEditableTextContextMenuBuilder? contextMenuBuilder;

  final TextMagnifierConfiguration magnifierConfiguration;

  bool get _userSelectionEnabled =>
      enableInteractiveSelection && (!readOnly || !obscureText);

  /// Returns the [ContextMenuButtonItem]s representing the buttons in this
  /// platform's default selection menu for an editable field.
  ///
  /// For example, [MongolEditableText] uses this to generate the default
  /// buttons for its context menu.
  ///
  /// See also:
  ///
  /// * [MongolEditableTextState.contextMenuButtonItems], which gives the
  ///   [ContextMenuButtonItem]s for a specific MongolEditableText.
  /// * [SelectableRegion.getSelectableButtonItems], which performs a similar
  ///   role but for content that is selectable but not editable.
  static List<ContextMenuButtonItem> getEditableButtonItems({
    required final ClipboardStatus? clipboardStatus,
    required final VoidCallback? onCopy,
    required final VoidCallback? onCut,
    required final VoidCallback? onPaste,
    required final VoidCallback? onSelectAll,
  }) {
    // If the paste button is enabled, don't render anything until the state
    // of the clipboard is known, since it's used to determine if paste is
    // shown.
    if (onPaste != null && clipboardStatus == ClipboardStatus.unknown) {
      return <ContextMenuButtonItem>[];
    }

    return <ContextMenuButtonItem>[
      if (onCut != null)
        ContextMenuButtonItem(
          onPressed: onCut,
          type: ContextMenuButtonType.cut,
        ),
      if (onCopy != null)
        ContextMenuButtonItem(
          onPressed: onCopy,
          type: ContextMenuButtonType.copy,
        ),
      if (onPaste != null)
        ContextMenuButtonItem(
          onPressed: onPaste,
          type: ContextMenuButtonType.paste,
        ),
      if (onSelectAll != null)
        ContextMenuButtonItem(
          onPressed: onSelectAll,
          type: ContextMenuButtonType.selectAll,
        ),
    ];
  }

  // Infer the keyboard type of a `MongolEditableText` if it's not specified.
  static TextInputType _inferKeyboardType({
    required Iterable<String>? autofillHints,
    required int? maxLines,
  }) {
    if (autofillHints == null || autofillHints.isEmpty) {
      return maxLines == 1 ? TextInputType.text : TextInputType.multiline;
    }

    final String effectiveHint = autofillHints.first;

    // On iOS oftentimes specifying a text content type is not enough to qualify
    // the input field for autofill. The keyboard type also needs to be compatible
    // with the content type. To get autofill to work by default on MongolEditableText,
    // the keyboard type inference on iOS is done differently from other platforms.
    //
    // The entries with "autofill not working" comments are the iOS text content
    // types that should work with the specified keyboard type but won't trigger
    // (even within a native app). Tested on iOS 13.5.
    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          const Map<String, TextInputType> iOSKeyboardType =
              <String, TextInputType>{
            AutofillHints.addressCity: TextInputType.name,
            AutofillHints.addressCityAndState:
                TextInputType.name, // Autofill not working.
            AutofillHints.addressState: TextInputType.name,
            AutofillHints.countryName: TextInputType.name,
            AutofillHints.creditCardNumber:
                TextInputType.number, // Couldn't test.
            AutofillHints.email: TextInputType.emailAddress,
            AutofillHints.familyName: TextInputType.name,
            AutofillHints.fullStreetAddress: TextInputType.name,
            AutofillHints.givenName: TextInputType.name,
            AutofillHints.jobTitle: TextInputType.name, // Autofill not working.
            AutofillHints.location: TextInputType.name, // Autofill not working.
            AutofillHints.middleName:
                TextInputType.name, // Autofill not working.
            AutofillHints.name: TextInputType.name,
            AutofillHints.namePrefix:
                TextInputType.name, // Autofill not working.
            AutofillHints.nameSuffix:
                TextInputType.name, // Autofill not working.
            AutofillHints.newPassword: TextInputType.text,
            AutofillHints.newUsername: TextInputType.text,
            AutofillHints.nickname: TextInputType.name, // Autofill not working.
            AutofillHints.oneTimeCode: TextInputType.number,
            AutofillHints.organizationName:
                TextInputType.text, // Autofill not working.
            AutofillHints.password: TextInputType.text,
            AutofillHints.postalCode: TextInputType.name,
            AutofillHints.streetAddressLine1: TextInputType.name,
            AutofillHints.streetAddressLine2:
                TextInputType.name, // Autofill not working.
            AutofillHints.sublocality:
                TextInputType.name, // Autofill not working.
            AutofillHints.telephoneNumber: TextInputType.name,
            AutofillHints.url: TextInputType.url, // Autofill not working.
            AutofillHints.username: TextInputType.text,
          };

          final TextInputType? keyboardType = iOSKeyboardType[effectiveHint];
          if (keyboardType != null) {
            return keyboardType;
          }
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    }

    if (maxLines != 1) {
      return TextInputType.multiline;
    }

    const inferKeyboardType = <String, TextInputType>{
      AutofillHints.addressCity: TextInputType.streetAddress,
      AutofillHints.addressCityAndState: TextInputType.streetAddress,
      AutofillHints.addressState: TextInputType.streetAddress,
      AutofillHints.birthday: TextInputType.datetime,
      AutofillHints.birthdayDay: TextInputType.datetime,
      AutofillHints.birthdayMonth: TextInputType.datetime,
      AutofillHints.birthdayYear: TextInputType.datetime,
      AutofillHints.countryCode: TextInputType.number,
      AutofillHints.countryName: TextInputType.text,
      AutofillHints.creditCardExpirationDate: TextInputType.datetime,
      AutofillHints.creditCardExpirationDay: TextInputType.datetime,
      AutofillHints.creditCardExpirationMonth: TextInputType.datetime,
      AutofillHints.creditCardExpirationYear: TextInputType.datetime,
      AutofillHints.creditCardFamilyName: TextInputType.name,
      AutofillHints.creditCardGivenName: TextInputType.name,
      AutofillHints.creditCardMiddleName: TextInputType.name,
      AutofillHints.creditCardName: TextInputType.name,
      AutofillHints.creditCardNumber: TextInputType.number,
      AutofillHints.creditCardSecurityCode: TextInputType.number,
      AutofillHints.creditCardType: TextInputType.text,
      AutofillHints.email: TextInputType.emailAddress,
      AutofillHints.familyName: TextInputType.name,
      AutofillHints.fullStreetAddress: TextInputType.streetAddress,
      AutofillHints.gender: TextInputType.text,
      AutofillHints.givenName: TextInputType.name,
      AutofillHints.impp: TextInputType.url,
      AutofillHints.jobTitle: TextInputType.text,
      AutofillHints.language: TextInputType.text,
      AutofillHints.location: TextInputType.streetAddress,
      AutofillHints.middleInitial: TextInputType.name,
      AutofillHints.middleName: TextInputType.name,
      AutofillHints.name: TextInputType.name,
      AutofillHints.namePrefix: TextInputType.name,
      AutofillHints.nameSuffix: TextInputType.name,
      AutofillHints.newPassword: TextInputType.text,
      AutofillHints.newUsername: TextInputType.text,
      AutofillHints.nickname: TextInputType.text,
      AutofillHints.oneTimeCode: TextInputType.text,
      AutofillHints.organizationName: TextInputType.text,
      AutofillHints.password: TextInputType.text,
      AutofillHints.photo: TextInputType.text,
      AutofillHints.postalAddress: TextInputType.streetAddress,
      AutofillHints.postalAddressExtended: TextInputType.streetAddress,
      AutofillHints.postalAddressExtendedPostalCode: TextInputType.number,
      AutofillHints.postalCode: TextInputType.number,
      AutofillHints.streetAddressLevel1: TextInputType.streetAddress,
      AutofillHints.streetAddressLevel2: TextInputType.streetAddress,
      AutofillHints.streetAddressLevel3: TextInputType.streetAddress,
      AutofillHints.streetAddressLevel4: TextInputType.streetAddress,
      AutofillHints.streetAddressLine1: TextInputType.streetAddress,
      AutofillHints.streetAddressLine2: TextInputType.streetAddress,
      AutofillHints.streetAddressLine3: TextInputType.streetAddress,
      AutofillHints.sublocality: TextInputType.streetAddress,
      AutofillHints.telephoneNumber: TextInputType.phone,
      AutofillHints.telephoneNumberAreaCode: TextInputType.phone,
      AutofillHints.telephoneNumberCountryCode: TextInputType.phone,
      AutofillHints.telephoneNumberDevice: TextInputType.phone,
      AutofillHints.telephoneNumberExtension: TextInputType.phone,
      AutofillHints.telephoneNumberLocal: TextInputType.phone,
      AutofillHints.telephoneNumberLocalPrefix: TextInputType.phone,
      AutofillHints.telephoneNumberLocalSuffix: TextInputType.phone,
      AutofillHints.telephoneNumberNational: TextInputType.phone,
      AutofillHints.transactionAmount:
          TextInputType.numberWithOptions(decimal: true),
      AutofillHints.transactionCurrency: TextInputType.text,
      AutofillHints.url: TextInputType.url,
      AutofillHints.username: TextInputType.text,
    };

    return inferKeyboardType[effectiveHint] ?? TextInputType.text;
  }

  @override
  MongolEditableTextState createState() => MongolEditableTextState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<TextEditingController>('controller', controller));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText,
        defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect,
        defaultValue: true));
    properties.add(DiagnosticsProperty<bool>(
        'enableSuggestions', enableSuggestions,
        defaultValue: true));
    style.debugFillProperties(properties);
    properties.add(EnumProperty<MongolTextAlign>('textAlign', textAlign,
        defaultValue: null));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(IntProperty('minLines', minLines, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<TextInputType>(
        'keyboardType', keyboardType,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollController>(
        'scrollController', scrollController,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollPhysics>(
        'scrollPhysics', scrollPhysics,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Iterable<String>>(
        'autofillHints', autofillHints,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
        'enableInteractiveSelection', enableInteractiveSelection,
        defaultValue: true));
    properties.add(DiagnosticsProperty<List<String>>('contentCommitMimeTypes',
        contentInsertionConfiguration?.allowedMimeTypes ?? const <String>[],
        defaultValue: contentInsertionConfiguration == null
            ? const <String>[]
            : kDefaultContentInsertionMimeTypes));
  }
}

/// State for a [MongolEditableText].
class MongolEditableTextState extends State<MongolEditableText>
    with
        AutomaticKeepAliveClientMixin<MongolEditableText>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<MongolEditableText>,
        TextSelectionDelegate,
        TextInputClient
    implements AutofillClient {
  Timer? _cursorTimer;
  AnimationController get _cursorBlinkOpacityController {
    return _backingCursorBlinkOpacityController ??= AnimationController(
      vsync: this,
    )..addListener(_onCursorColorTick);
  }

  AnimationController? _backingCursorBlinkOpacityController;
  late final Simulation _iosBlinkCursorSimulation =
      _DiscreteKeyFrameSimulation.iOSBlinkingCaret();

  final ValueNotifier<bool> _cursorVisibilityNotifier =
      ValueNotifier<bool>(true);
  final GlobalKey _editableKey = GlobalKey();

  /// Detects whether the clipboard can paste.
  final ClipboardStatusNotifier? clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();

  TextInputConnection? _textInputConnection;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  MongolTextSelectionOverlay? _selectionOverlay;

  final GlobalKey _scrollableKey = GlobalKey();
  ScrollController? _internalScrollController;
  ScrollController get _scrollController =>
      widget.scrollController ??
      (_internalScrollController ??= ScrollController());

  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  bool _didAutoFocus = false;

  AutofillGroupState? _currentAutofillScope;

  @override
  AutofillScope? get currentAutofillScope => _currentAutofillScope;

  AutofillClient get _effectiveAutofillClient => widget.autofillClient ?? this;

  /// Whether to create an input connection with the platform for text editing
  /// or not.
  ///
  /// Read-only input fields do not need a connection with the platform since
  /// there's no need for text editing capabilities (e.g. virtual keyboard).
  ///
  /// On the web, we always need a connection because we want some browser
  /// functionalities to continue to work on read-only input fields like:
  ///
  /// - Relevant context menu.
  /// - cmd/ctrl+c shortcut to copy.
  /// - cmd/ctrl+a to select all.
  /// - Changing the selection using a physical keyboard.
  bool get _shouldCreateInputConnection => kIsWeb || !widget.readOnly;

  Orientation? _lastOrientation;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  Color get _cursorColor =>
      widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);

  @override
  bool get cutEnabled {
    if (widget.selectionControls is! TextSelectionHandleControls) {
      return widget.toolbarOptions.cut &&
          !widget.readOnly &&
          !widget.obscureText;
    }
    return !widget.readOnly &&
        !widget.obscureText &&
        !textEditingValue.selection.isCollapsed;
  }

  @override
  bool get copyEnabled {
    if (widget.selectionControls is! TextSelectionHandleControls) {
      return widget.toolbarOptions.copy && !widget.obscureText;
    }
    return !widget.obscureText && !textEditingValue.selection.isCollapsed;
  }

  @override
  bool get pasteEnabled {
    if (widget.selectionControls is! TextSelectionHandleControls) {
      return widget.toolbarOptions.paste && !widget.readOnly;
    }
    return !widget.readOnly &&
        (clipboardStatus == null ||
            clipboardStatus!.value == ClipboardStatus.pasteable);
  }

  @override
  bool get selectAllEnabled {
    if (widget.selectionControls is! TextSelectionHandleControls) {
      return widget.toolbarOptions.selectAll &&
          (!widget.readOnly || !widget.obscureText) &&
          widget.enableInteractiveSelection;
    }

    if (!widget.enableInteractiveSelection ||
        (widget.readOnly && widget.obscureText)) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return false;
      case TargetPlatform.iOS:
        return textEditingValue.text.isNotEmpty &&
            textEditingValue.selection.isCollapsed;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return textEditingValue.text.isNotEmpty &&
            !(textEditingValue.selection.start == 0 &&
                textEditingValue.selection.end == textEditingValue.text.length);
    }
  }

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  TextEditingValue get _textEditingValueForTextLayoutMetrics {
    final Widget? editableWidget = _editableKey.currentContext?.widget;
    if (editableWidget is! _MongolEditable) {
      throw StateError('_Editable must be mounted.');
    }
    return editableWidget.value;
  }

  /// Copy current selection to [Clipboard].
  @override
  void copySelection(SelectionChangedCause cause) {
    final TextSelection selection = textEditingValue.selection;
    if (selection.isCollapsed || widget.obscureText) {
      return;
    }
    final String text = textEditingValue.text;
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar(false);

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          // Collapse the selection and hide the toolbar and handles.
          userUpdateTextEditingValue(
            TextEditingValue(
              text: textEditingValue.text,
              selection: TextSelection.collapsed(
                  offset: textEditingValue.selection.end),
            ),
            SelectionChangedCause.toolbar,
          );
          break;
      }
    }
    clipboardStatus?.update();
  }

  /// Cut current selection to [Clipboard].
  @override
  void cutSelection(SelectionChangedCause cause) {
    if (widget.readOnly || widget.obscureText) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    _replaceText(ReplaceTextIntent(textEditingValue, '', selection, cause));
    if (cause == SelectionChangedCause.toolbar) {
      // Schedule a call to bringIntoView() after renderEditable updates.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bringIntoView(textEditingValue.selection.extent);
        }
      });
      hideToolbar();
    }
    clipboardStatus?.update();
  }

  /// Paste text from [Clipboard].
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (widget.readOnly) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    if (!selection.isValid) {
      return;
    }
    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      return;
    }

    // After the paste, the cursor should be collapsed and located after the
    // pasted content.
    final int lastSelectionIndex =
        math.max(selection.baseOffset, selection.extentOffset);
    final TextEditingValue collapsedTextEditingValue =
        textEditingValue.copyWith(
      selection: TextSelection.collapsed(offset: lastSelectionIndex),
    );

    userUpdateTextEditingValue(
      collapsedTextEditingValue.replaced(selection, data.text!),
      cause,
    );
    if (cause == SelectionChangedCause.toolbar) {
      // Schedule a call to bringIntoView() after renderEditable updates.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bringIntoView(textEditingValue.selection.extent);
        }
      });
      hideToolbar();
    }
  }

  /// Select the entire text value.
  @override
  void selectAll(SelectionChangedCause cause) {
    if (widget.readOnly && widget.obscureText) {
      // If we can't modify it, and we can't copy it, there's no point in
      // selecting it.
      return;
    }
    userUpdateTextEditingValue(
      textEditingValue.copyWith(
        selection: TextSelection(
            baseOffset: 0, extentOffset: textEditingValue.text.length),
      ),
      cause,
    );

    if (cause == SelectionChangedCause.toolbar) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.fuchsia:
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          hideToolbar();
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          bringIntoView(textEditingValue.selection.extent);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
      }
    }
  }

  /// This method is not yet implemented and always returns null.
  SuggestionSpan? findSuggestionSpanAtCursorIndex(int cursorIndex) {
    // Spellcheck is not implemented yet.
    return null;
  }

  /// This method is not yet implemented and always returns false.
  bool showSpellCheckSuggestionsToolbar() {
    // Spellcheck is not implemented yet.
    return false;
  }

  /// Returns the [ContextMenuButtonItem]s for the given [ToolbarOptions].
  @Deprecated(
    'Use `contextMenuBuilder` instead of `toolbarOptions`. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  List<ContextMenuButtonItem>? buttonItemsForToolbarOptions(
      [TargetPlatform? targetPlatform]) {
    final ToolbarOptions toolbarOptions = widget.toolbarOptions;
    if (toolbarOptions == ToolbarOptions.empty) {
      return null;
    }
    return <ContextMenuButtonItem>[
      if (toolbarOptions.cut && cutEnabled)
        ContextMenuButtonItem(
          onPressed: () {
            selectAll(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.selectAll,
        ),
      if (toolbarOptions.copy && copyEnabled)
        ContextMenuButtonItem(
          onPressed: () {
            copySelection(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.copy,
        ),
      if (toolbarOptions.paste && clipboardStatus != null && pasteEnabled)
        ContextMenuButtonItem(
          onPressed: () {
            pasteText(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.paste,
        ),
      if (toolbarOptions.selectAll && selectAllEnabled)
        ContextMenuButtonItem(
          onPressed: () {
            selectAll(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.selectAll,
        ),
    ];
  }

  /// Gets the line widths at the start and end of the selection for the given
  /// [MongolEditableTextState].
  _GlyphWidths _getGlyphWidths() {
    final TextSelection selection = textEditingValue.selection;

    // Only calculate handle rects if the text in the previous frame
    // is the same as the text in the current frame. This is done because
    // widget.renderObject contains the renderEditable from the previous frame.
    // If the text changed between the current and previous frames then
    // widget.renderObject.getRectForComposingRange might fail. In cases where
    // the current frame is different from the previous we fall back to
    // renderObject.preferredLineHeight.
    final TextSpan span = renderEditable.text!;
    final String prevText = span.toPlainText();
    final String currentText = textEditingValue.text;
    if (prevText != currentText ||
        !selection.isValid ||
        selection.isCollapsed) {
      return _GlyphWidths(
        start: renderEditable.preferredLineWidth,
        end: renderEditable.preferredLineWidth,
      );
    }

    final String selectedGraphemes = selection.textInside(currentText);
    final int firstSelectedGraphemeExtent =
        selectedGraphemes.characters.first.length;
    final Rect? startCharacterRect =
        renderEditable.getRectForComposingRange(TextRange(
      start: selection.start,
      end: selection.start + firstSelectedGraphemeExtent,
    ));
    final int lastSelectedGraphemeExtent =
        selectedGraphemes.characters.last.length;
    final Rect? endCharacterRect =
        renderEditable.getRectForComposingRange(TextRange(
      start: selection.end - lastSelectedGraphemeExtent,
      end: selection.end,
    ));
    return _GlyphWidths(
      start: startCharacterRect?.width ?? renderEditable.preferredLineWidth,
      end: endCharacterRect?.width ?? renderEditable.preferredLineWidth,
    );
  }

  /// Returns the anchor points for the default context menu.
  TextSelectionToolbarAnchors get contextMenuAnchors {
    if (renderEditable.lastSecondaryTapDownPosition != null) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: renderEditable.lastSecondaryTapDownPosition!,
      );
    }

    final _GlyphWidths glyphWidths = _getGlyphWidths();
    final TextSelection selection = textEditingValue.selection;
    final List<TextSelectionPoint> points =
        renderEditable.getEndpointsForSelection(selection);
    return TextSelectionToolbarAnchors.fromSelection(
      renderBox: renderEditable,
      startGlyphHeight: glyphWidths.start,
      endGlyphHeight: glyphWidths.end,
      selectionEndpoints: points,
    );
  }

  /// Returns the [ContextMenuButtonItem]s representing the buttons in this
  /// platform's default selection menu for [MongolEditableText].
  List<ContextMenuButtonItem> get contextMenuButtonItems {
    return buttonItemsForToolbarOptions() ??
        MongolEditableText.getEditableButtonItems(
          clipboardStatus: clipboardStatus?.value,
          onCopy: copyEnabled
              ? () => copySelection(SelectionChangedCause.toolbar)
              : null,
          onCut: cutEnabled
              ? () => cutSelection(SelectionChangedCause.toolbar)
              : null,
          onPaste: pasteEnabled
              ? () => pasteText(SelectionChangedCause.toolbar)
              : null,
          onSelectAll: selectAllEnabled
              ? () => selectAll(SelectionChangedCause.toolbar)
              : null,
        );
  }

  // todo editor-fixes copy from [EditableTextState]
  @override
  void autofill(TextEditingValue value) => updateEditingValue(value);

  @override
  void insertTextPlaceholder(Size size) {
    // todo editor-fixes should we implement it?
  }

  @override
  void removeTextPlaceholder() {
    // todo editor-fixes should we implement it?
  }

  // State lifecycle:

  @override
  void initState() {
    super.initState();
    clipboardStatus?.addListener(_onChangedClipboardStatus);
    widget.controller.addListener(_didChangeTextEditingValue);
    widget.focusNode.addListener(_handleFocusChanged);
    _scrollController.addListener(_onEditableScroll);
    _cursorVisibilityNotifier.value = widget.showCursor;
  }

  // Whether `TickerMode.of(context)` is true and animations (like blinking the
  // cursor) are supposed to run.
  bool _tickersEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final AutofillGroupState? newAutofillGroup = AutofillGroup.maybeOf(context);
    if (currentAutofillScope != newAutofillGroup) {
      _currentAutofillScope?.unregister(autofillId);
      _currentAutofillScope = newAutofillGroup;
      _currentAutofillScope?.register(_effectiveAutofillClient);
    }

    if (!_didAutoFocus && widget.autofocus) {
      _didAutoFocus = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && renderEditable.hasSize) {
          FocusScope.of(context).autofocus(widget.focusNode);
        }
      });
    }

    // Restart or stop the blinking cursor when TickerMode changes.
    final bool newTickerEnabled = TickerMode.of(context);
    if (_tickersEnabled != newTickerEnabled) {
      _tickersEnabled = newTickerEnabled;
      if (_tickersEnabled && _cursorActive) {
        _startCursorBlink();
      } else if (!_tickersEnabled && _cursorTimer != null) {
        _cursorTimer!.cancel();
        _cursorTimer = null;
      }
    }

    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    // Hide the text selection toolbar on mobile when orientation changes.
    final Orientation orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation == null) {
      _lastOrientation = orientation;
      return;
    }
    if (orientation != _lastOrientation) {
      _lastOrientation = orientation;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        hideToolbar(false);
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        hideToolbar();
      }
    }
  }

  @override
  void didUpdateWidget(MongolEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      _updateRemoteEditingValueIfNeeded();
    }
    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(_value);
    }
    _selectionOverlay?.handlesVisible = widget.showSelectionHandles;

    if (widget.autofillClient != oldWidget.autofillClient) {
      _currentAutofillScope
          ?.unregister(oldWidget.autofillClient?.autofillId ?? autofillId);
      _currentAutofillScope?.register(_effectiveAutofillClient);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (widget.scrollController != oldWidget.scrollController) {
      (oldWidget.scrollController ?? _internalScrollController)
          ?.removeListener(_onEditableScroll);
      _scrollController.addListener(_onEditableScroll);
    }

    if (!_shouldCreateInputConnection) {
      _closeInputConnectionIfNeeded();
    } else if (oldWidget.readOnly && _hasFocus) {
      _openInputConnection();
    }

    if (kIsWeb && _hasInputConnection) {
      if (oldWidget.readOnly != widget.readOnly) {
        _textInputConnection!
            .updateConfig(_effectiveAutofillClient.textInputConfiguration);
      }
    }

    if (widget.style != oldWidget.style) {
      final TextStyle style = widget.style;
      // The _textInputConnection will pick up the new style when it attaches in
      // _openInputConnection.
      if (_hasInputConnection) {
        _textInputConnection!.setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: TextDirection.ltr,
          textAlign: _rotatedTextAlign(widget.textAlign),
        );
      }
    }
    final bool canPaste =
        widget.selectionControls is TextSelectionHandleControls
            ? pasteEnabled
            : widget.selectionControls?.canPaste(this) ?? false;
    if (widget.selectionEnabled &&
        pasteEnabled &&
        clipboardStatus != null &&
        canPaste) {
      clipboardStatus!.update();
    }
  }

  TextAlign _rotatedTextAlign(MongolTextAlign mongolTextAlign) {
    switch (mongolTextAlign) {
      case MongolTextAlign.top:
        return TextAlign.left;
      case MongolTextAlign.center:
        return ui.TextAlign.center;
      case MongolTextAlign.bottom:
        return TextAlign.right;
      case MongolTextAlign.justify:
        return TextAlign.justify;
    }
  }

  @override
  void dispose() {
    _internalScrollController?.dispose();
    _currentAutofillScope?.unregister(autofillId);
    widget.controller.removeListener(_didChangeTextEditingValue);
    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _backingCursorBlinkOpacityController?.dispose();
    _backingCursorBlinkOpacityController = null;
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    widget.focusNode.removeListener(_handleFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    clipboardStatus?.removeListener(_onChangedClipboardStatus);
    clipboardStatus?.dispose();
    _cursorVisibilityNotifier.dispose();
    super.dispose();
    assert(_batchEditDepth <= 0, 'unfinished batch edits: $_batchEditDepth');
  }

  // TextInputClient implementation:

  /// The last known [TextEditingValue] of the platform text input plugin.
  ///
  /// This value is updated when the platform text input plugin sends a new
  /// update via [updateEditingValue], or when [MongolEditableText] calls
  /// [TextInputConnection.setEditingState] to overwrite the platform text input
  /// plugin's [TextEditingValue].
  ///
  /// Used in [_updateRemoteEditingValueIfNeeded] to determine whether the
  /// remote value is outdated and needs updating.
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    // This method handles text editing state updates from the platform text
    // input plugin. The [MongolEditableText] may not have the focus or an open
    // input connection, as autofill can update a disconnected
    // [MongolEditableText].

    // Since we still have to support keyboard select, this is the best place
    // to disable text updating.
    if (!_shouldCreateInputConnection) {
      return;
    }

    if (_checkNeedsAdjustAffinity(value)) {
      value = value.copyWith(
          selection:
              value.selection.copyWith(affinity: _value.selection.affinity));
    }

    if (widget.readOnly) {
      // In the read-only case, we only care about selection changes, and reject
      // everything else.
      value = _value.copyWith(selection: value.selection);
    }
    _lastKnownRemoteTextEditingValue = value;

    if (value == _value) {
      // This is possible, for example, when the numeric keyboard is input,
      // the engine will notify twice for the same value.
      // Track at https://github.com/flutter/flutter/issues/65811
      return;
    }

    if (value.text == _value.text && value.composing == _value.composing) {
      // `selection` is the only change.
      _handleSelectionChanged(
          value.selection,
          (_textInputConnection?.scribbleInProgress ?? false)
              ? SelectionChangedCause.scribble
              : SelectionChangedCause.keyboard);
    } else {
      // Only hide the toolbar overlay, the selection handle's visibility will be handled
      // by `_handleSelectionChanged`. https://github.com/flutter/flutter/issues/108673
      hideToolbar(false);

      final bool revealObscuredInput = _hasInputConnection &&
          widget.obscureText &&
          WidgetsBinding.instance.platformDispatcher.brieflyShowPassword &&
          value.text.length == _value.text.length + 1;

      _obscureShowCharTicksPending =
          revealObscuredInput ? _kObscureShowLatestCharCursorTicks : 0;
      _obscureLatestCharIndex =
          revealObscuredInput ? _value.selection.baseOffset : null;
      _formatAndSetValue(value, SelectionChangedCause.keyboard);
    }

    // Wherever the value is changed by the user, schedule a showCaretOnScreen
    // to make sure the user can see the changes they just made. Programmatical
    // changes to `textEditingValue` do not trigger the behavior even if the
    // text field is focused.
    _scheduleShowCaretOnScreen(withAnimation: true);
    if (_hasInputConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _stopCursorBlink(resetCharTicks: false);
      _startCursorBlink();
    }
  }

  bool _checkNeedsAdjustAffinity(TextEditingValue value) {
    // Trust the engine affinity if the text changes or selection changes.
    return value.text == _value.text &&
        value.selection.isCollapsed == _value.selection.isCollapsed &&
        value.selection.start == _value.selection.start &&
        value.selection.affinity != _value.selection.affinity;
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.newline:
        // If this is a multiline EditableText, do nothing for a "newline"
        // action; The newline is already inserted. Otherwise, finalize
        // editing.
        if (!_isMultiline) _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.next:
      case TextInputAction.previous:
      case TextInputAction.search:
      case TextInputAction.send:
        _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.continueAction:
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
        // Finalize editing, but don't give up focus because this keyboard
        // action does not imply the user is done inputting information.
        _finalizeEditing(action, shouldUnfocus: false);
        break;
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    widget.onAppPrivateCommand!(action, data);
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    assert(widget.contentInsertionConfiguration?.allowedMimeTypes
            .contains(content.mimeType) ??
        false);
    widget.contentInsertionConfiguration?.onContentInserted.call(content);
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // unimplemented
  }

  @pragma('vm:notify-debugger-on-exception')
  void _finalizeEditing(TextInputAction action, {required bool shouldUnfocus}) {
    // Take any actions necessary now that the user has completed editing.
    if (widget.onEditingComplete != null) {
      try {
        widget.onEditingComplete!();
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context:
              ErrorDescription('while calling onEditingComplete for $action'),
        ));
      }
    } else {
      // Default behavior if the developer did not provide an
      // onEditingComplete callback: Finalize editing and remove focus, or move
      // it to the next/previous field, depending on the action.
      widget.controller.clearComposing();
      if (shouldUnfocus) {
        switch (action) {
          case TextInputAction.none:
          case TextInputAction.unspecified:
          case TextInputAction.done:
          case TextInputAction.go:
          case TextInputAction.search:
          case TextInputAction.send:
          case TextInputAction.continueAction:
          case TextInputAction.join:
          case TextInputAction.route:
          case TextInputAction.emergencyCall:
          case TextInputAction.newline:
            widget.focusNode.unfocus();
            break;
          case TextInputAction.next:
            widget.focusNode.nextFocus();
            break;
          case TextInputAction.previous:
            widget.focusNode.previousFocus();
            break;
        }
      }
    }

    final ValueChanged<String>? onSubmitted = widget.onSubmitted;
    if (onSubmitted == null) {
      return;
    }

    // Invoke optional callback with the user's submitted content.
    try {
      onSubmitted(_value.text);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context: ErrorDescription('while calling onSubmitted for $action'),
      ));
    }

    // If `shouldUnfocus` is true, the text field should no longer be focused
    // after the microtask queue is drained. But in case the developer cancelled
    // the focus change in the `onSubmitted` callback by focusing this input
    // field again, reset the soft keyboard.
    // See https://github.com/flutter/flutter/issues/84240.
    //
    // `_restartConnectionIfNeeded` creates a new TextInputConnection to replace
    // the current one. This on iOS switches to a new input view and on Android
    // restarts the input method, and in both cases the soft keyboard will be
    // reset.
    if (shouldUnfocus) {
      _scheduleRestartConnection();
    }
  }

  int _batchEditDepth = 0;

  /// Begins a new batch edit, within which new updates made to the text editing
  /// value will not be sent to the platform text input plugin.
  ///
  /// Batch edits nest. When the outermost batch edit finishes, [endBatchEdit]
  /// will attempt to send [currentTextEditingValue] to the text input plugin if
  /// it detected a change.
  void beginBatchEdit() {
    _batchEditDepth += 1;
  }

  /// Ends the current batch edit started by the last call to [beginBatchEdit],
  /// and send [currentTextEditingValue] to the text input plugin if needed.
  ///
  /// Throws an error in debug mode if this [EditableText] is not in a batch
  /// edit.
  void endBatchEdit() {
    _batchEditDepth -= 1;
    assert(
      _batchEditDepth >= 0,
      'Unbalanced call to endBatchEdit: beginBatchEdit must be called first.',
    );
    _updateRemoteEditingValueIfNeeded();
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (_batchEditDepth > 0 || !_hasInputConnection) return;
    final localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue) return;
    _textInputConnection!.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  bool get _hasFocus => widget.focusNode.hasFocus;
  bool get _isMultiline => widget.maxLines != 1;

  // Finds the closest scroll offset to the current scroll offset that fully
  // reveals the given caret rect. If the given rect's main axis extent is too
  // large to be fully revealed in `renderEditable`, it will be centered along
  // the main axis.
  //
  // If this is a multiline MongolEditableText (which means the Editable can only
  // scroll horizontally), the given rect's width will first be extended to match
  // `renderEditable.preferredLineWidth`, before the target scroll offset is
  // calculated.
  RevealedOffset _getOffsetToRevealCaret(Rect rect) {
    if (!_scrollController.position.allowImplicitScrolling) {
      return RevealedOffset(offset: _scrollController.offset, rect: rect);
    }

    final editableSize = renderEditable.size;
    final double additionalOffset;
    final Offset unitOffset;

    if (!_isMultiline) {
      additionalOffset = rect.height >= editableSize.height
          // Center `rect` if it's oversized.
          ? editableSize.height / 2 - rect.center.dy
          // Valid additional offsets range from (rect.bottom - size.height)
          // to (rect.top). Pick the closest one if out of range.
          : clampDouble(0.0, rect.bottom - editableSize.height, rect.top);
      unitOffset = const Offset(0, 1);
    } else {
      // The caret is horizontally centered within the line. Expand the caret's
      // width so that it spans the line because we're going to ensure that the
      // entire expanded caret is scrolled into view.
      final expandedRect = Rect.fromCenter(
        center: rect.center,
        height: rect.height,
        width: math.max(rect.width, renderEditable.preferredLineWidth),
      );

      additionalOffset = expandedRect.width >= editableSize.width
          ? editableSize.width / 2 - expandedRect.center.dx
          : clampDouble(
              0.0, expandedRect.right - editableSize.width, expandedRect.left);
      unitOffset = const Offset(1, 0);
    }

    // No overscrolling when encountering tall fonts/scripts that extend past
    // the ascent.
    final double targetOffset = clampDouble(
      additionalOffset + _scrollController.offset,
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    final offsetDelta = _scrollController.offset - targetOffset;
    return RevealedOffset(
        rect: rect.shift(unitOffset * offsetDelta), offset: targetOffset);
  }

  /// Whether to send the autofill information to the autofill service.
  bool get _needsAutofill => widget.autofillHints?.isNotEmpty ?? false;

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) {
      return;
    }
    if (!_hasInputConnection) {
      final localValue = _value;

      // When _needsAutofill == true && currentAutofillScope == null, autofill
      // is allowed but saving the user input from the text field is
      // discouraged.
      //
      // In case the autofillScope changes from a non-null value to null, or
      // _needsAutofill changes to false from true, the platform needs to be
      // notified to exclude this field from the autofill context. So we need to
      // provide the autofillId.
      // todo editor-fixes replace with below code
      // _textInputConnection = _needsAutofill && currentAutofillScope != null
      //     ? currentAutofillScope!.attach(this, textInputConfiguration)
      //     : TextInput.attach(
      //         this,
      //         _createTextInputConfiguration(
      //             _isInAutofillContext || _needsAutofill));
      _textInputConnection = _needsAutofill && currentAutofillScope != null
          ? currentAutofillScope!
              .attach(this, _effectiveAutofillClient.textInputConfiguration)
          : TextInput.attach(
              this, _effectiveAutofillClient.textInputConfiguration);
      _textInputConnection!.show();
      _updateSizeAndTransform();
      _updateComposingRectIfNeeded();
      _updateCaretRectIfNeeded();
      if (_needsAutofill) {
        // Request autofill AFTER the size and the transform have been sent to
        // the platform text input plugin.
        _textInputConnection!.requestAutofill();
      }

      final style = widget.style;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: TextDirection.ltr,
          textAlign: _rotatedTextAlign(widget.textAlign),
        )
        ..setEditingState(localValue);
    } else {
      _textInputConnection!.show();
    }
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  bool _restartConnectionScheduled = false;
  void _scheduleRestartConnection() {
    if (_restartConnectionScheduled) {
      return;
    }
    _restartConnectionScheduled = true;
    scheduleMicrotask(_restartConnectionIfNeeded);
  }

  // Discards the current [TextInputConnection] and establishes a new one.
  //
  // This method is rarely needed. This is currently used to reset the input
  // type when the "submit" text input action is triggered and the developer
  // puts the focus back to this input field..
  void _restartConnectionIfNeeded() {
    _restartConnectionScheduled = false;
    if (!_hasInputConnection || !_shouldCreateInputConnection) {
      return;
    }
    _textInputConnection!.close();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;

    final AutofillScope? currentAutofillScope =
        _needsAutofill ? this.currentAutofillScope : null;
    final TextInputConnection newConnection = currentAutofillScope?.attach(
            this, textInputConfiguration) ??
        TextInput.attach(this, _effectiveAutofillClient.textInputConfiguration);
    _textInputConnection = newConnection;

    final TextStyle style = widget.style;
    newConnection
      ..show()
      ..setStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        textDirection: TextDirection.ltr,
        textAlign: _rotatedTextAlign(widget.textAlign),
      )
      ..setEditingState(_value);
    _lastKnownRemoteTextEditingValue = _value;
  }

  @override
  void didChangeInputControl(
      TextInputControl? oldControl, TextInputControl? newControl) {
    if (_hasFocus && _hasInputConnection) {
      oldControl?.hide();
      newControl?.show();
    }
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _finalizeEditing(TextInputAction.done, shouldUnfocus: true);
    }
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(_value);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    }
  }

  void _onEditableScroll() {
    _selectionOverlay?.updateForScroll();
  }

  MongolTextSelectionOverlay _createSelectionOverlay() {
    final selectionOverlay = MongolTextSelectionOverlay(
      clipboardStatus: clipboardStatus,
      context: context,
      value: _value,
      debugRequiredFor: widget,
      toolbarLayerLink: _toolbarLayerLink,
      startHandleLayerLink: _startHandleLayerLink,
      endHandleLayerLink: _endHandleLayerLink,
      renderObject: renderEditable,
      selectionControls: widget.selectionControls,
      selectionDelegate: this,
      dragStartBehavior: widget.dragStartBehavior,
      onSelectionHandleTapped: widget.onSelectionHandleTapped,
      contextMenuBuilder: widget.contextMenuBuilder == null
          ? null
          : (BuildContext context) {
              return widget.contextMenuBuilder!(
                context,
                this,
              );
            },
      magnifierConfiguration: widget.magnifierConfiguration,
    );

    return selectionOverlay;
  }

  @pragma('vm:notify-debugger-on-exception')
  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    // We return early if the selection is not valid. This can happen when the
    // text of [MongolEditableText] is updated at the same time as the selection is
    // changed by a gesture event.
    if (!widget.controller.isSelectionWithinTextBounds(selection)) return;

    widget.controller.selection = selection;

    // This will show the keyboard for all selection changes on the
    // MongolEditableText except for those triggered by a keyboard input.
    // Typically MongolEditableText shouldn't take user keyboard input if
    // it's not focused already. If the MongolEditableText is being
    // autofilled it shouldn't request focus.
    switch (cause) {
      case null:
      case SelectionChangedCause.doubleTap:
      case SelectionChangedCause.drag:
      case SelectionChangedCause.forcePress:
      case SelectionChangedCause.longPress:
      case SelectionChangedCause.scribble:
      case SelectionChangedCause.tap:
      case SelectionChangedCause.toolbar:
        requestKeyboard();
        break;
      case SelectionChangedCause.keyboard:
        if (_hasFocus) {
          requestKeyboard();
        }
        break;
    }
    if (widget.selectionControls == null && widget.contextMenuBuilder == null) {
      _selectionOverlay?.dispose();
      _selectionOverlay = null;
    } else {
      if (_selectionOverlay == null) {
        _selectionOverlay = _createSelectionOverlay();
      } else {
        _selectionOverlay!.update(_value);
      }
      _selectionOverlay!.handlesVisible = widget.showSelectionHandles;
      _selectionOverlay!.showHandles();
    }
    try {
      widget.onSelectionChanged?.call(selection, cause);
    } catch (exception, stack) {
      debugPrint('Error while calling onSelectionChanged for $cause');
      debugPrint(stack.toString());
    }

    // To keep the cursor from blinking while it moves, restart the timer here.
    if (_cursorTimer != null) {
      _stopCursorBlink(resetCharTicks: false);
      _startCursorBlink();
    }
  }

  // Animation configuration for scrolling the caret back on screen.
  static const Duration _caretAnimationDuration = Duration(milliseconds: 100);
  static const Curve _caretAnimationCurve = Curves.fastOutSlowIn;

  bool _showCaretOnScreenScheduled = false;

  void _scheduleShowCaretOnScreen({required bool withAnimation}) {
    if (_showCaretOnScreenScheduled) {
      return;
    }
    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _showCaretOnScreenScheduled = false;
      // Since we are in a post frame callback, check currentContext in case
      // RenderEditable has been disposed (in which case it will be null).
      final renderEditable = _editableKey.currentContext?.findRenderObject()
          as MongolRenderEditable?;
      if (renderEditable == null ||
          !(renderEditable.selection?.isValid ?? false) ||
          !_scrollController.hasClients) {
        return;
      }

      final lineWidth = renderEditable.preferredLineWidth;

      // Enlarge the target rect by scrollPadding to ensure that caret is not
      // positioned directly at the edge after scrolling.
      var rightSpacing = widget.scrollPadding.right;
      if (_selectionOverlay?.selectionControls != null) {
        final handleWidth = _selectionOverlay!.selectionControls!
            .getHandleSize(lineWidth)
            .width;
        final interactiveHandleWidth = math.max(
          handleWidth,
          kMinInteractiveDimension,
        );
        final anchor = _selectionOverlay!.selectionControls!.getHandleAnchor(
          TextSelectionHandleType.collapsed,
          lineWidth,
        );
        final handleCenter = handleWidth / 2 - anchor.dx;
        rightSpacing = math.max(
          handleCenter + interactiveHandleWidth / 2,
          rightSpacing,
        );
      }

      final caretPadding = widget.scrollPadding.copyWith(right: rightSpacing);

      final caretRect =
          renderEditable.getLocalRectForCaret(renderEditable.selection!.extent);
      final targetOffset = _getOffsetToRevealCaret(caretRect);

      final Rect rectToReveal;
      final TextSelection selection = textEditingValue.selection;
      if (selection.isCollapsed) {
        rectToReveal = targetOffset.rect;
      } else {
        final List<Rect> selectionBoxes =
            renderEditable.getBoxesForSelection(selection);
        rectToReveal = selection.baseOffset < selection.extentOffset
            ? selectionBoxes.last
            : selectionBoxes.first;
      }

      if (withAnimation) {
        _scrollController.animateTo(
          targetOffset.offset,
          duration: _caretAnimationDuration,
          curve: _caretAnimationCurve,
        );
        renderEditable.showOnScreen(
          rect: caretPadding.inflateRect(rectToReveal),
          duration: _caretAnimationDuration,
          curve: _caretAnimationCurve,
        );
      } else {
        _scrollController.jumpTo(targetOffset.offset);
        if (_value.selection.isCollapsed) {
          renderEditable.showOnScreen(
            rect: caretPadding.inflateRect(rectToReveal),
          );
        }
      }
    });
  }

  // keeping "bottom" rather than changing it to "right" because it likely refers
  // to the keyboard location. But this might be wrong.
  late double _lastBottomViewInset;

  @override
  void didChangeMetrics() {
    if (_lastBottomViewInset !=
        WidgetsBinding.instance.window.viewInsets.bottom) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _selectionOverlay?.updateForScroll();
      });
      if (_lastBottomViewInset <
          WidgetsBinding.instance.window.viewInsets.bottom) {
        // Because the metrics change signal from engine will come here every frame
        // (on both iOS and Android). So we don't need to show caret with animation.
        _scheduleShowCaretOnScreen(withAnimation: false);
      }
    }
    _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
  }

  @pragma('vm:notify-debugger-on-exception')
  void _formatAndSetValue(TextEditingValue value, SelectionChangedCause? cause,
      {bool userInteraction = false}) {
    // Only apply input formatters if the text has changed (including uncommited
    // text in the composing region), or when the user committed the composing
    // text.
    // Gboard is very persistent in restoring the composing region. Applying
    // input formatters on composing-region-only changes (except clearing the
    // current composing region) is very infinite-loop-prone: the formatters
    // will keep trying to modify the composing region while Gboard will keep
    // trying to restore the original composing region.
    final textChanged = _value.text != value.text ||
        (!_value.composing.isCollapsed && value.composing.isCollapsed);
    final selectionChanged = _value.selection != value.selection;

    if (textChanged) {
      value = widget.inputFormatters?.fold<TextEditingValue>(
            value,
            (TextEditingValue newValue, TextInputFormatter formatter) =>
                formatter.formatEditUpdate(_value, newValue),
          ) ??
          value;
    }

    // Put all optional user callback invocations in a batch edit to prevent
    // sending multiple `TextInput.updateEditingValue` messages.
    beginBatchEdit();
    _value = value;
    // Changes made by the keyboard can sometimes be "out of band" for listening
    // components, so always send those events, even if we didn't think it
    // changed. Also, the user long pressing should always send a selection change
    // as well.
    if (selectionChanged ||
        (userInteraction &&
            (cause == SelectionChangedCause.longPress ||
                cause == SelectionChangedCause.keyboard))) {
      _handleSelectionChanged(_value.selection, cause);
    }
    if (textChanged) {
      try {
        widget.onChanged?.call(_value.text);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context: ErrorDescription('while calling onChanged'),
        ));
      }
    }

    endBatchEdit();
  }

  void _onCursorColorTick() {
    renderEditable.cursorColor =
        widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);
    _cursorVisibilityNotifier.value =
        widget.showCursor && _cursorBlinkOpacityController.value > 0;
  }

  /// Whether the blinking cursor is actually visible at this precise moment
  /// (it's hidden half the time, since it blinks).
  @visibleForTesting
  bool get cursorCurrentlyVisible => _cursorBlinkOpacityController.value > 0;

  /// The cursor blink interval (the amount of time the cursor is in the "on"
  /// state or the "off" state). A complete cursor blink period is twice this
  /// value (half on, half off).
  @visibleForTesting
  Duration get cursorBlinkInterval => _kCursorBlinkHalfPeriod;

  /// The current status of the text selection handles.
  @visibleForTesting
  MongolTextSelectionOverlay? get selectionOverlay => _selectionOverlay;

  int _obscureShowCharTicksPending = 0;
  int? _obscureLatestCharIndex;

  // Indicates whether the cursor should be blinking right now (but it may
  // actually not blink because it's disabled via TickerMode.of(context)).
  bool _cursorActive = false;

  void _startCursorBlink() {
    assert(!(_cursorTimer?.isActive ?? false) ||
        !(_backingCursorBlinkOpacityController?.isAnimating ?? false));
    _cursorActive = true;
    if (!_tickersEnabled) {
      return;
    }
    _cursorTimer?.cancel();
    _cursorBlinkOpacityController.value = 1.0;
    if (MongolEditableText.debugDeterministicCursor) {
      return;
    }
    if (widget.cursorOpacityAnimates) {
      _cursorBlinkOpacityController
          .animateWith(_iosBlinkCursorSimulation)
          .whenComplete(_onCursorTick);
    } else {
      _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, (Timer timer) {
        _onCursorTick();
      });
    }
  }

  void _onCursorTick() {
    if (_obscureShowCharTicksPending > 0) {
      _obscureShowCharTicksPending =
          WidgetsBinding.instance.platformDispatcher.brieflyShowPassword
              ? _obscureShowCharTicksPending - 1
              : 0;
      if (_obscureShowCharTicksPending == 0) {
        setState(() {});
      }
    }

    if (widget.cursorOpacityAnimates) {
      _cursorTimer?.cancel();
      // Schedule this as an async task to avoid blocking tester.pumpAndSettle
      // indefinitely.
      _cursorTimer = Timer(
          Duration.zero,
          () => _cursorBlinkOpacityController
              .animateWith(_iosBlinkCursorSimulation)
              .whenComplete(_onCursorTick));
    } else {
      if (!(_cursorTimer?.isActive ?? false) && _tickersEnabled) {
        _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, (Timer timer) {
          _onCursorTick();
        });
      }
      _cursorBlinkOpacityController.value =
          _cursorBlinkOpacityController.value == 0 ? 1 : 0;
    }
  }

  void _stopCursorBlink({bool resetCharTicks = true}) {
    _cursorActive = false;
    _cursorBlinkOpacityController.value = 0.0;
    _cursorTimer?.cancel();
    _cursorTimer = null;
    if (resetCharTicks) {
      _obscureShowCharTicksPending = 0;
    }
  }

  void _startOrStopCursorTimerIfNeeded() {
    if (_cursorTimer == null && _hasFocus && _value.selection.isCollapsed) {
      _startCursorBlink();
    } else if (_cursorActive && (!_hasFocus || !_value.selection.isCollapsed)) {
      _stopCursorBlink();
    }
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    setState(() {
      /* We use widget.controller.value in build(). */
    });
    _adjacentLineAction.stopCurrentVerticalRunIfSelectionChanges();
  }

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      // Listen for changing viewInsets, which indicates keyboard showing up.
      WidgetsBinding.instance.addObserver(this);
      _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
      if (!widget.readOnly) {
        _scheduleShowCaretOnScreen(withAnimation: true);
      }
      if (!_value.selection.isValid) {
        // Place cursor at the end if the selection is invalid when we receive focus.
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _value.text.length), null);
      }
    } else {
      WidgetsBinding.instance.removeObserver(this);
      setState(() {});
    }
    updateKeepAlive();
  }

  void _updateSizeAndTransform() {
    if (_hasInputConnection) {
      final size = renderEditable.size;
      final transform = renderEditable.getTransformTo(null);
      _textInputConnection!.setEditableSizeAndTransform(size, transform);
      SchedulerBinding.instance
          .addPostFrameCallback((Duration _) => _updateSizeAndTransform());
    }
  }

  // Sends the current composing rect to the iOS text input plugin via the text
  // input channel. We need to keep sending the information even if no text is
  // currently marked, as the information usually lags behind. The text input
  // plugin needs to estimate the composing rect based on the latest caret rect,
  // when the composing rect info didn't arrive in time.
  void _updateComposingRectIfNeeded() {
    final composingRange = _value.composing;
    if (_hasInputConnection) {
      assert(mounted);
      var composingRect =
          renderEditable.getRectForComposingRange(composingRange);
      // Send the caret location instead if there's no marked text yet.
      if (composingRect == null) {
        assert(!composingRange.isValid || composingRange.isCollapsed);
        final offset = composingRange.isValid ? composingRange.start : 0;
        composingRect =
            renderEditable.getLocalRectForCaret(TextPosition(offset: offset));
      }
      _textInputConnection!.setComposingRect(composingRect);
      SchedulerBinding.instance
          .addPostFrameCallback((Duration _) => _updateComposingRectIfNeeded());
    }
  }

  void _updateCaretRectIfNeeded() {
    if (_hasInputConnection) {
      if (renderEditable.selection != null &&
          renderEditable.selection!.isValid &&
          renderEditable.selection!.isCollapsed) {
        final TextPosition currentTextPosition =
            TextPosition(offset: renderEditable.selection!.baseOffset);
        final Rect caretRect =
            renderEditable.getLocalRectForCaret(currentTextPosition);
        _textInputConnection!.setCaretRect(caretRect);
      }
      SchedulerBinding.instance
          .addPostFrameCallback((Duration _) => _updateCaretRectIfNeeded());
    }
  }

  /// The renderer for this widget's descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures
  /// when [MongolRenderEditable.ignorePointer] is true.
  late final MongolRenderEditable renderEditable =
      _editableKey.currentContext!.findRenderObject()! as MongolRenderEditable;

  @override
  TextEditingValue get textEditingValue => _value;

  double get _devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause? cause) {
    // Compare the current TextEditingValue with the pre-format new
    // TextEditingValue value, in case the formatter would reject the change.
    final bool shouldShowCaret =
        widget.readOnly ? _value.selection != value.selection : _value != value;
    if (shouldShowCaret) {
      _scheduleShowCaretOnScreen(withAnimation: true);
    }

    // Even if the value doesn't change, it may be necessary to focus and build
    // the selection overlay. For example, this happens when right clicking an
    // unfocused field that previously had a selection in the same spot.
    if (value == textEditingValue) {
      if (!widget.focusNode.hasFocus) {
        widget.focusNode.requestFocus();
        _selectionOverlay = _createSelectionOverlay();
      }
      return;
    }

    _formatAndSetValue(value, cause, userInteraction: true);
  }

  @override
  void bringIntoView(TextPosition position) {
    final localRect = renderEditable.getLocalRectForCaret(position);
    final targetOffset = _getOffsetToRevealCaret(localRect);

    _scrollController.jumpTo(targetOffset.offset);
    renderEditable.showOnScreen(rect: targetOffset.rect);
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
  /// is already shown, or when no text selection currently exists.
  @override
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb) {
      return false;
    }

    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }

    _selectionOverlay!.showToolbar();
    return true;
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (hideHandles) {
      // Hide the handles and the toolbar.
      _selectionOverlay?.hide();
    } else {
      // Hide only the toolbar but not the handles.
      _selectionOverlay?.hideToolbar();
    }
  }

  /// Toggles the visibility of the toolbar.
  void toggleToolbar([bool hideHandles = true]) {
    final MongolTextSelectionOverlay selectionOverlay =
        _selectionOverlay ??= _createSelectionOverlay();

    if (selectionOverlay.toolbarIsVisible) {
      hideToolbar(hideHandles);
    } else {
      showToolbar();
    }
  }

  /// Shows the magnifier at the position given by `positionToShow`,
  /// if there is no magnifier visible.
  ///
  /// Updates the magnifier to the position given by `positionToShow`,
  /// if there is a magnifier visible.
  ///
  /// Does nothing if a magnifier couldn't be shown, such as when the selection
  /// overlay does not currently exist.
  void showMagnifier(Offset positionToShow) {
    if (_selectionOverlay == null) {
      return;
    }

    if (_selectionOverlay!.magnifierIsVisible) {
      _selectionOverlay!.updateMagnifier(positionToShow);
    } else {
      _selectionOverlay!.showMagnifier(positionToShow);
    }
  }

  /// Hides the magnifier if it is visible.
  void hideMagnifier() {
    if (_selectionOverlay == null) {
      return;
    }

    if (_selectionOverlay!.magnifierIsVisible) {
      _selectionOverlay!.hideMagnifier();
    }
  }

  @override
  void performSelector(String selectorName) {
    final Intent? intent = intentForMacOSSelector(selectorName);

    if (intent != null) {
      final BuildContext? primaryContext = primaryFocus?.context;
      if (primaryContext != null) {
        Actions.invoke(primaryContext, intent);
      }
    }
  }

  @override
  String get autofillId => 'MongolEditableText-$hashCode';

  @override
  TextInputConfiguration get textInputConfiguration {
    final List<String>? autofillHints =
        widget.autofillHints?.toList(growable: false);
    final AutofillConfiguration autofillConfiguration = autofillHints != null
        ? AutofillConfiguration(
            uniqueIdentifier: autofillId,
            autofillHints: autofillHints,
            currentEditingValue: currentTextEditingValue,
          )
        : AutofillConfiguration.disabled;

    return TextInputConfiguration(
      inputType: widget.keyboardType,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      enableInteractiveSelection: widget._userSelectionEnabled,
      inputAction: widget.textInputAction ??
          (widget.keyboardType == TextInputType.multiline
              ? TextInputAction.newline
              : TextInputAction.done),
      keyboardAppearance: widget.keyboardAppearance,
      autofillConfiguration: autofillConfiguration,
    );
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // unimplemented
  }

  VoidCallback? _semanticsOnCopy(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            _hasFocus &&
            (widget.selectionControls is TextSelectionHandleControls
                ? copyEnabled
                : copyEnabled &&
                    (widget.selectionControls?.canCopy(this) ?? false))
        ? () {
            controls?.handleCopy(this);
            copySelection(SelectionChangedCause.toolbar);
          }
        : null;
  }

  VoidCallback? _semanticsOnCut(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            _hasFocus &&
            (widget.selectionControls is TextSelectionHandleControls
                ? cutEnabled
                : cutEnabled &&
                    (widget.selectionControls?.canCut(this) ?? false))
        ? () {
            controls?.handleCut(this);
            cutSelection(SelectionChangedCause.toolbar);
          }
        : null;
  }

  VoidCallback? _semanticsOnPaste(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            _hasFocus &&
            (widget.selectionControls is TextSelectionHandleControls
                ? pasteEnabled
                : pasteEnabled &&
                    (widget.selectionControls?.canPaste(this) ?? false)) &&
            (clipboardStatus == null ||
                clipboardStatus!.value == ClipboardStatus.pasteable)
        ? () {
            controls?.handlePaste(this);
            pasteText(SelectionChangedCause.toolbar);
          }
        : null;
  }

  // --------------------------- Text Editing Actions ---------------------------

  _TextBoundary _characterBoundary(DirectionalTextEditingIntent intent) {
    final _TextBoundary atomicTextBoundary = widget.obscureText
        ? _CodeUnitBoundary(_value)
        : _CharacterBoundary(_value);
    return _CollapsedSelectionBoundary(atomicTextBoundary, intent.forward);
  }

  _TextBoundary _nextWordBoundary(DirectionalTextEditingIntent intent) {
    final _TextBoundary atomicTextBoundary;
    final _TextBoundary boundary;

    if (widget.obscureText) {
      atomicTextBoundary = _CodeUnitBoundary(_value);
      boundary = _DocumentBoundary(_value);
    } else {
      final TextEditingValue textEditingValue =
          _textEditingValueForTextLayoutMetrics;
      atomicTextBoundary = _CharacterBoundary(textEditingValue);
      // This isn't enough. Newline characters.
      boundary = _ExpandedTextBoundary(_WhitespaceBoundary(textEditingValue),
          _WordBoundary(renderEditable, textEditingValue));
    }

    final _MixedBoundary mixedBoundary = intent.forward
        ? _MixedBoundary(atomicTextBoundary, boundary)
        : _MixedBoundary(boundary, atomicTextBoundary);
    // Use a _MixedBoundary to make sure we don't leave invalid codepoints in
    // the field after deletion.
    return _CollapsedSelectionBoundary(mixedBoundary, intent.forward);
  }

  _TextBoundary _linebreak(DirectionalTextEditingIntent intent) {
    final _TextBoundary atomicTextBoundary;
    final _TextBoundary boundary;

    if (widget.obscureText) {
      atomicTextBoundary = _CodeUnitBoundary(_value);
      boundary = _DocumentBoundary(_value);
    } else {
      final TextEditingValue textEditingValue =
          _textEditingValueForTextLayoutMetrics;
      atomicTextBoundary = _CharacterBoundary(textEditingValue);
      boundary = _LineBreak(renderEditable, textEditingValue);
    }

    // The _MixedBoundary is to make sure we don't leave invalid code units in
    // the field after deletion.
    // `boundary` doesn't need to be wrapped in a _CollapsedSelectionBoundary,
    // since the document boundary is unique and the linebreak boundary is
    // already caret-location based.
    return intent.forward
        ? _MixedBoundary(
            _CollapsedSelectionBoundary(atomicTextBoundary, true), boundary)
        : _MixedBoundary(
            boundary, _CollapsedSelectionBoundary(atomicTextBoundary, false));
  }

  void _updateSelection(UpdateSelectionIntent intent) {
    bringIntoView(intent.newSelection.extent);
    userUpdateTextEditingValue(
      intent.currentTextEditingValue.copyWith(selection: intent.newSelection),
      intent.cause,
    );
  }

  late final Action<UpdateSelectionIntent> _updateSelectionAction =
      CallbackAction<UpdateSelectionIntent>(onInvoke: _updateSelection);

  late final _UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent> _adjacentLineAction =
      _UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent>(this);

  _TextBoundary _documentBoundary(DirectionalTextEditingIntent intent) =>
      _DocumentBoundary(_value);

  Action<T> _makeOverridable<T extends Intent>(Action<T> defaultAction) {
    return Action<T>.overridable(
        context: context, defaultAction: defaultAction);
  }

  /// Transpose the characters immediately before and after the current
  /// collapsed selection.
  ///
  /// When the cursor is at the end of the text, transposes the last two
  /// characters, if they exist.
  ///
  /// When the cursor is at the start of the text, does nothing.
  void _transposeCharacters(TransposeCharactersIntent intent) {
    if (_value.text.characters.length <= 1 ||
        !_value.selection.isCollapsed ||
        _value.selection.baseOffset == 0) {
      return;
    }

    final String text = _value.text;
    final TextSelection selection = _value.selection;
    final bool atEnd = selection.baseOffset == text.length;
    final CharacterRange transposing =
        CharacterRange.at(text, selection.baseOffset);
    if (atEnd) {
      transposing.moveBack(2);
    } else {
      transposing
        ..moveBack()
        ..expandNext();
    }
    assert(transposing.currentCharacters.length == 2);

    userUpdateTextEditingValue(
      TextEditingValue(
        text: transposing.stringBefore +
            transposing.currentCharacters.last +
            transposing.currentCharacters.first +
            transposing.stringAfter,
        selection: TextSelection.collapsed(
          offset: transposing.stringBeforeLength + transposing.current.length,
        ),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  late final Action<TransposeCharactersIntent> _transposeCharactersAction =
      CallbackAction<TransposeCharactersIntent>(onInvoke: _transposeCharacters);

  void _replaceText(ReplaceTextIntent intent) {
    final TextEditingValue oldValue = _value;
    final TextEditingValue newValue = intent.currentTextEditingValue.replaced(
      intent.replacementRange,
      intent.replacementText,
    );
    userUpdateTextEditingValue(newValue, intent.cause);

    // If there's no change in text and selection (e.g. when selecting and
    // pasting identical text), the widget won't be rebuilt on value update.
    // Handle this by calling _didChangeTextEditingValue() so caret and scroll
    // updates can happen.
    if (newValue == oldValue) {
      _didChangeTextEditingValue();
    }
  }

  late final Action<ReplaceTextIntent> _replaceTextAction =
      CallbackAction<ReplaceTextIntent>(onInvoke: _replaceText);

  // Scrolls either to the beginning or end of the document depending on the
  // intent's `forward` parameter.
  void _scrollToDocumentBoundary(ScrollToDocumentBoundaryIntent intent) {
    if (intent.forward) {
      bringIntoView(TextPosition(offset: _value.text.length));
    } else {
      bringIntoView(const TextPosition(offset: 0));
    }
  }

  /// Handles [ScrollIntent] by scrolling the [Scrollable] inside of
  /// [MongolEditableText].
  void _scroll(ScrollIntent intent) {
    if (intent.type != ScrollIncrementType.page) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    if (widget.maxLines == 1) {
      _scrollController.jumpTo(position.maxScrollExtent);
      return;
    }

    // If the field isn't scrollable, do nothing. For example, when the lines of
    // text is less than maxLines, the field has nothing to scroll.
    if (position.maxScrollExtent == 0.0 && position.minScrollExtent == 0.0) {
      return;
    }

    final ScrollableState? state =
        _scrollableKey.currentState as ScrollableState?;
    final double increment =
        ScrollAction.getDirectionalIncrement(state!, intent);
    final double destination = clampDouble(
      position.pixels + increment,
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (destination == position.pixels) {
      return;
    }
    _scrollController.jumpTo(destination);
  }

  /// Extend the selection down by page if the `forward` parameter is true, or
  /// up by page otherwise.
  void _extendSelectionByPage(ExtendSelectionByPageIntent intent) {
    if (widget.maxLines == 1) {
      return;
    }

    final TextSelection nextSelection;
    final Rect extentRect = renderEditable.getLocalRectForCaret(
      _value.selection.extent,
    );
    final ScrollableState? state =
        _scrollableKey.currentState as ScrollableState?;
    final double increment = ScrollAction.getDirectionalIncrement(
      state!,
      ScrollIntent(
        direction: intent.forward ? AxisDirection.right : AxisDirection.left,
        type: ScrollIncrementType.page,
      ),
    );
    final ScrollPosition position = _scrollController.position;
    if (intent.forward) {
      if (_value.selection.extentOffset >= _value.text.length) {
        return;
      }
      final Offset nextExtentOffset =
          Offset(extentRect.left + increment, extentRect.top);
      final double width = position.maxScrollExtent + renderEditable.size.width;
      final TextPosition nextExtent =
          nextExtentOffset.dx + position.pixels >= width
              ? TextPosition(offset: _value.text.length)
              : renderEditable.getPositionForPoint(
                  renderEditable.localToGlobal(nextExtentOffset),
                );
      nextSelection = _value.selection.copyWith(
        extentOffset: nextExtent.offset,
      );
    } else {
      if (_value.selection.extentOffset <= 0) {
        return;
      }
      final Offset nextExtentOffset =
          Offset(extentRect.left + increment, extentRect.top);
      final TextPosition nextExtent = nextExtentOffset.dx + position.pixels <= 0
          ? const TextPosition(offset: 0)
          : renderEditable.getPositionForPoint(
              renderEditable.localToGlobal(nextExtentOffset),
            );
      nextSelection = _value.selection.copyWith(
        extentOffset: nextExtent.offset,
      );
    }

    bringIntoView(nextSelection.extent);
    userUpdateTextEditingValue(
      _value.copyWith(selection: nextSelection),
      SelectionChangedCause.keyboard,
    );
  }

  void _expandSelectionToDocumentBoundary(
      ExpandSelectionToDocumentBoundaryIntent intent) {
    final _TextBoundary textBoundary = _documentBoundary(intent);
    _expandSelection(intent.forward, textBoundary, true);
  }

  void _expandSelectionToLinebreak(ExpandSelectionToLineBreakIntent intent) {
    final _TextBoundary textBoundary = _linebreak(intent);
    _expandSelection(intent.forward, textBoundary);
  }

  void _expandSelection(bool forward, _TextBoundary textBoundary,
      [bool extentAtIndex = false]) {
    final TextSelection textBoundarySelection =
        textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return;
    }

    final bool inOrder =
        textBoundarySelection.baseOffset <= textBoundarySelection.extentOffset;
    final bool towardsExtent = forward == inOrder;
    final TextPosition position = towardsExtent
        ? textBoundarySelection.extent
        : textBoundarySelection.base;

    final TextPosition newExtent = forward
        ? textBoundary.getTrailingTextBoundaryAt(position)
        : textBoundary.getLeadingTextBoundaryAt(position);

    final TextSelection newSelection = textBoundarySelection.expandTo(
        newExtent, textBoundarySelection.isCollapsed || extentAtIndex);
    userUpdateTextEditingValue(
      _value.copyWith(selection: newSelection),
      SelectionChangedCause.keyboard,
    );
    bringIntoView(newSelection.extent);
  }

  Object? _hideToolbarIfVisible(DismissIntent intent) {
    if (_selectionOverlay?.toolbarIsVisible ?? false) {
      hideToolbar(false);
      return null;
    }
    return Actions.invoke(context, intent);
  }

  /// The default behavior used if [onTapOutside] is null.
  ///
  /// The `event` argument is the [PointerDownEvent] that caused the notification.
  void _defaultOnTapOutside(PointerDownEvent event) {
    /// The focus dropping behavior is only present on desktop platforms
    /// and mobile browsers.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        // On mobile platforms, we don't unfocus on touch events unless they're
        // in the web browser, but we do unfocus for all other kinds of events.
        switch (event.kind) {
          case ui.PointerDeviceKind.touch:
            if (kIsWeb) {
              widget.focusNode.unfocus();
            }
            break;
          case ui.PointerDeviceKind.mouse:
          case ui.PointerDeviceKind.stylus:
          case ui.PointerDeviceKind.invertedStylus:
          case ui.PointerDeviceKind.unknown:
            widget.focusNode.unfocus();
            break;
          case ui.PointerDeviceKind.trackpad:
            throw UnimplementedError(
                'Unexpected pointer down event for trackpad');
        }
        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        widget.focusNode.unfocus();
        break;
    }
  }

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    DoNothingAndStopPropagationTextIntent: DoNothingAction(consumesKey: false),
    ReplaceTextIntent: _replaceTextAction,
    UpdateSelectionIntent: _updateSelectionAction,
    DirectionalFocusIntent: DirectionalFocusAction.forTextField(),
    DismissIntent:
        CallbackAction<DismissIntent>(onInvoke: _hideToolbarIfVisible),

    // Delete
    DeleteCharacterIntent: _makeOverridable(
        _DeleteTextAction<DeleteCharacterIntent>(this, _characterBoundary)),
    DeleteToNextWordBoundaryIntent: _makeOverridable(
        _DeleteTextAction<DeleteToNextWordBoundaryIntent>(
            this, _nextWordBoundary)),
    DeleteToLineBreakIntent: _makeOverridable(
        _DeleteTextAction<DeleteToLineBreakIntent>(this, _linebreak)),

    // Extend/Move Selection
    ExtendSelectionByCharacterIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(
      this,
      false,
      _characterBoundary,
    )),
    ExtendSelectionByPageIntent: _makeOverridable(
        CallbackAction<ExtendSelectionByPageIntent>(
            onInvoke: _extendSelectionByPage)),
    MongolExtendSelectionByCharacterIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(
      this,
      false,
      _characterBoundary,
    )),
    ExtendSelectionToNextWordBoundaryIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryIntent>(
            this, true, _nextWordBoundary)),
    MongolExtendSelectionToNextWordBoundaryIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryIntent>(
            this, true, _nextWordBoundary)),
    ExtendSelectionToLineBreakIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToLineBreakIntent>(
            this, true, _linebreak)),
    MongolExtendSelectionToLineBreakIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToLineBreakIntent>(
            this, true, _linebreak)),
    ExpandSelectionToLineBreakIntent: _makeOverridable(
        CallbackAction<ExpandSelectionToLineBreakIntent>(
            onInvoke: _expandSelectionToLinebreak)),
    MongolExpandSelectionToLineBreakIntent: _makeOverridable(
        CallbackAction<ExpandSelectionToLineBreakIntent>(
            onInvoke: _expandSelectionToLinebreak)),
    ExpandSelectionToDocumentBoundaryIntent: _makeOverridable(
        CallbackAction<ExpandSelectionToDocumentBoundaryIntent>(
            onInvoke: _expandSelectionToDocumentBoundary)),
    ExtendSelectionVerticallyToAdjacentLineIntent:
        _makeOverridable(_adjacentLineAction),
    MongolExtendSelectionHorizontallyToAdjacentLineIntent:
        _makeOverridable(_adjacentLineAction),
    ExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(
            this, true, _documentBoundary)),
    MongolExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
        _UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(
            this, true, _documentBoundary)),
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent: _makeOverridable(
        _ExtendSelectionOrCaretPositionAction(this, _nextWordBoundary)),
    MongolExtendSelectionToNextWordBoundaryOrCaretLocationIntent:
        _makeOverridable(
            _ExtendSelectionOrCaretPositionAction(this, _nextWordBoundary)),
    ScrollToDocumentBoundaryIntent: _makeOverridable(
        CallbackAction<ScrollToDocumentBoundaryIntent>(
            onInvoke: _scrollToDocumentBoundary)),
    ScrollIntent: CallbackAction<ScrollIntent>(onInvoke: _scroll),

    // Copy Paste
    SelectAllTextIntent: _makeOverridable(_SelectAllAction(this)),
    CopySelectionTextIntent: _makeOverridable(_CopySelectionAction(this)),
    PasteTextIntent: _makeOverridable(CallbackAction<PasteTextIntent>(
        onInvoke: (PasteTextIntent intent) => pasteText(intent.cause))),

    TransposeCharactersIntent: _makeOverridable(_transposeCharactersAction),
  };

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final TextSelectionControls? controls = widget.selectionControls;
    return TextFieldTapRegion(
      onTapOutside: widget.onTapOutside ?? _defaultOnTapOutside,
      debugLabel: kReleaseMode ? null : 'MongolEditableText',
      child: MouseRegion(
        cursor: widget.mouseCursor ?? SystemMouseCursors.text,
        child: Actions(
          actions: _actions,
          child: _TextEditingHistory(
            controller: widget.controller,
            onTriggered: (TextEditingValue value) {
              userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);
            },
            child: Focus(
              focusNode: widget.focusNode,
              includeSemantics: false,
              debugLabel: kReleaseMode ? null : 'MongolEditableText',
              child: Scrollable(
                key: _scrollableKey,
                excludeFromSemantics: true,
                axisDirection:
                    _isMultiline ? AxisDirection.right : AxisDirection.down,
                controller: _scrollController,
                physics: widget.scrollPhysics,
                dragStartBehavior: widget.dragStartBehavior,
                restorationId: widget.restorationId,
                scrollBehavior: widget.scrollBehavior ??
                    ScrollConfiguration.of(context).copyWith(
                      scrollbars: _isMultiline,
                      overscroll: false,
                    ),
                viewportBuilder: (BuildContext context, ViewportOffset offset) {
                  return CompositedTransformTarget(
                    link: _toolbarLayerLink,
                    child: Semantics(
                      onCopy: _semanticsOnCopy(controls),
                      onCut: _semanticsOnCut(controls),
                      onPaste: _semanticsOnPaste(controls),
                      textDirection: TextDirection.ltr,
                      child: _MongolEditable(
                        key: _editableKey,
                        startHandleLayerLink: _startHandleLayerLink,
                        endHandleLayerLink: _endHandleLayerLink,
                        textSpan: buildTextSpan(),
                        value: _value,
                        cursorColor: _cursorColor,
                        showCursor: MongolEditableText.debugDeterministicCursor
                            ? ValueNotifier<bool>(widget.showCursor)
                            : _cursorVisibilityNotifier,
                        forceLine: widget.forceLine,
                        readOnly: widget.readOnly,
                        hasFocus: _hasFocus,
                        maxLines: widget.maxLines,
                        minLines: widget.minLines,
                        expands: widget.expands,
                        selectionColor: widget.selectionColor,
                        textScaleFactor: widget.textScaleFactor ??
                            MediaQuery.textScaleFactorOf(context),
                        textAlign: widget.textAlign,
                        obscuringCharacter: widget.obscuringCharacter,
                        obscureText: widget.obscureText,
                        autocorrect: widget.autocorrect,
                        enableSuggestions: widget.enableSuggestions,
                        offset: offset,
                        rendererIgnoresPointer: widget.rendererIgnoresPointer,
                        cursorWidth: widget.cursorWidth,
                        cursorHeight: widget.cursorHeight,
                        cursorRadius: widget.cursorRadius,
                        cursorOffset: widget.cursorOffset ?? Offset.zero,
                        enableInteractiveSelection:
                            widget._userSelectionEnabled,
                        textSelectionDelegate: this,
                        devicePixelRatio: _devicePixelRatio,
                        clipBehavior: widget.clipBehavior,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds [TextSpan] from current editing value.
  ///
  /// By default makes text in composing range appear as underlined.
  /// Descendants can override this method to customize appearance of text.
  TextSpan buildTextSpan() {
    if (widget.obscureText) {
      var text = _value.text;
      text = widget.obscuringCharacter * text.length;
      // Reveal the latest character in an obscured field only on mobile.
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.fuchsia) {
        final o =
            _obscureShowCharTicksPending > 0 ? _obscureLatestCharIndex : null;
        if (o != null && o >= 0 && o < text.length) {
          text = text.replaceRange(o, o + 1, _value.text.substring(o, o + 1));
        }
      }
      return TextSpan(style: widget.style, text: text);
    }
    // Read only mode should not paint text composing.
    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: !widget.readOnly,
    );
  }
}

class _MongolEditable extends LeafRenderObjectWidget {
  const _MongolEditable({
    Key? key,
    required this.textSpan,
    required this.value,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    this.cursorColor,
    required this.showCursor,
    required this.forceLine,
    required this.readOnly,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.selectionColor,
    required this.textScaleFactor,
    required this.textAlign,
    required this.obscuringCharacter,
    required this.obscureText,
    required this.autocorrect,
    required this.enableSuggestions,
    required this.offset,
    this.rendererIgnoresPointer = false,
    this.cursorWidth,
    required this.cursorHeight,
    this.cursorRadius,
    required this.cursorOffset,
    this.enableInteractiveSelection = true,
    required this.textSelectionDelegate,
    required this.devicePixelRatio,
    required this.clipBehavior,
  }) : super(key: key);

  final TextSpan textSpan;
  final TextEditingValue value;
  final Color? cursorColor;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final ValueNotifier<bool> showCursor;
  final bool forceLine;
  final bool readOnly;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final Color? selectionColor;
  final double textScaleFactor;
  final MongolTextAlign textAlign;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final ViewportOffset offset;
  final bool rendererIgnoresPointer;
  final double? cursorWidth;
  final double cursorHeight;
  final Radius? cursorRadius;
  final Offset cursorOffset;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;
  final double devicePixelRatio;
  final Clip clipBehavior;

  @override
  MongolRenderEditable createRenderObject(BuildContext context) {
    return MongolRenderEditable(
      text: textSpan,
      cursorColor: cursorColor,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      showCursor: showCursor,
      forceLine: forceLine,
      readOnly: readOnly,
      hasFocus: hasFocus,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      textAlign: textAlign,
      selection: value.selection,
      offset: offset,
      ignorePointer: rendererIgnoresPointer,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorOffset: cursorOffset,
      enableInteractiveSelection: enableInteractiveSelection,
      textSelectionDelegate: textSelectionDelegate,
      devicePixelRatio: devicePixelRatio,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MongolRenderEditable renderObject) {
    renderObject
      ..text = textSpan
      ..cursorColor = cursorColor
      ..startHandleLayerLink = startHandleLayerLink
      ..endHandleLayerLink = endHandleLayerLink
      ..showCursor = showCursor
      ..forceLine = forceLine
      ..readOnly = readOnly
      ..hasFocus = hasFocus
      ..maxLines = maxLines
      ..minLines = minLines
      ..expands = expands
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..textAlign = textAlign
      ..selection = value.selection
      ..offset = offset
      ..ignorePointer = rendererIgnoresPointer
      ..obscuringCharacter = obscuringCharacter
      ..obscureText = obscureText
      ..cursorWidth = cursorWidth
      ..cursorHeight = cursorHeight
      ..cursorRadius = cursorRadius
      ..cursorOffset = cursorOffset
      ..enableInteractiveSelection = enableInteractiveSelection
      ..textSelectionDelegate = textSelectionDelegate
      ..devicePixelRatio = devicePixelRatio
      ..clipBehavior = clipBehavior;
  }
}

/// An interface for retrieving the logical text boundary (left-closed-right-open)
/// at a given location in a document.
///
/// Depending on the implementation of the [_TextBoundary], the input
/// [TextPosition] can either point to a code unit, or a position between 2 code
/// units (which can be visually represented by the caret if the selection were
/// to collapse to that position).
///
/// For example, [_LineBreak] interprets the input [TextPosition] as a caret
/// location, since in Flutter the caret is generally painted between the
/// character the [TextPosition] points to and its previous character, and
/// [_LineBreak] cares about the affinity of the input [TextPosition]. Most
/// other text boundaries however, interpret the input [TextPosition] as the
/// location of a code unit in the document, since it's easier to reason about
/// the text boundary given a code unit in the text.
///
/// To convert a "code-unit-based" [_TextBoundary] to "caret-location-based",
/// use the [_CollapsedSelectionBoundary] combinator.
abstract class _TextBoundary {
  const _TextBoundary();

  TextEditingValue get textEditingValue;

  /// Returns the leading text boundary at the given location, inclusive.
  TextPosition getLeadingTextBoundaryAt(TextPosition position);

  /// Returns the trailing text boundary at the given location, exclusive.
  TextPosition getTrailingTextBoundaryAt(TextPosition position);

  TextRange getTextBoundaryAt(TextPosition position) {
    return TextRange(
      start: getLeadingTextBoundaryAt(position).offset,
      end: getTrailingTextBoundaryAt(position).offset,
    );
  }
}

// -----------------------------  Text Boundaries -----------------------------

class _CodeUnitBoundary extends _TextBoundary {
  const _CodeUnitBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      TextPosition(offset: position.offset);
  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) => TextPosition(
      offset: math.min(position.offset + 1, textEditingValue.text.length));
}

// The word modifier generally removes the word boundaries around white spaces
// (and newlines), IOW white spaces and some other punctuations are considered
// a part of the next word in the search direction.
class _WhitespaceBoundary extends _TextBoundary {
  const _WhitespaceBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    for (int index = position.offset; index >= 0; index -= 1) {
      if (!TextLayoutMetrics.isWhitespace(
          textEditingValue.text.codeUnitAt(index))) {
        return TextPosition(offset: index);
      }
    }
    return const TextPosition(offset: 0);
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    for (int index = position.offset;
        index < textEditingValue.text.length;
        index += 1) {
      if (!TextLayoutMetrics.isWhitespace(
          textEditingValue.text.codeUnitAt(index))) {
        return TextPosition(offset: index + 1);
      }
    }
    return TextPosition(offset: textEditingValue.text.length);
  }
}

// Most apps delete the entire grapheme when the backspace key is pressed.
// Also always put the new caret location to character boundaries to avoid
// sending malformed UTF-16 code units to the paragraph builder.
class _CharacterBoundary extends _TextBoundary {
  const _CharacterBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    final int endOffset =
        math.min(position.offset + 1, textEditingValue.text.length);
    return TextPosition(
      offset:
          CharacterRange.at(textEditingValue.text, position.offset, endOffset)
              .stringBeforeLength,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    final int endOffset =
        math.min(position.offset + 1, textEditingValue.text.length);
    final CharacterRange range =
        CharacterRange.at(textEditingValue.text, position.offset, endOffset);
    return TextPosition(
      offset: textEditingValue.text.length - range.stringAfterLength,
    );
  }

  @override
  TextRange getTextBoundaryAt(TextPosition position) {
    final int endOffset =
        math.min(position.offset + 1, textEditingValue.text.length);
    final CharacterRange range =
        CharacterRange.at(textEditingValue.text, position.offset, endOffset);
    return TextRange(
      start: range.stringBeforeLength,
      end: textEditingValue.text.length - range.stringAfterLength,
    );
  }
}

// [UAX #29](https://unicode.org/reports/tr29/) defined word boundaries.
class _WordBoundary extends _TextBoundary {
  const _WordBoundary(this.textLayout, this.textEditingValue);

  final TextLayoutMetrics textLayout;

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getWordBoundary(position).start,
      // Word boundary seems to always report downstream on many platforms.
      affinity:
          TextAffinity.downstream, // ignore: avoid_redundant_argument_values
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getWordBoundary(position).end,
      // Word boundary seems to always report downstream on many platforms.
      affinity:
          TextAffinity.downstream, // ignore: avoid_redundant_argument_values
    );
  }
}

// The linebreaks of the current text layout. The input [TextPosition]s are
// interpreted as caret locations because [TextPainter.getLineAtOffset] is
// text-affinity-aware.
class _LineBreak extends _TextBoundary {
  const _LineBreak(
    this.textLayout,
    this.textEditingValue,
  );

  final TextLayoutMetrics textLayout;

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getLineAtOffset(position).start,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getLineAtOffset(position).end,
      affinity: TextAffinity.upstream,
    );
  }
}

// The document boundary is unique and is a constant function of the input
// position.
class _DocumentBoundary extends _TextBoundary {
  const _DocumentBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      const TextPosition(offset: 0);
  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textEditingValue.text.length,
      affinity: TextAffinity.upstream,
    );
  }
}

// ------------------------  Text Boundary Combinators ------------------------

// Expands the innerTextBoundary with outerTextBoundary.
class _ExpandedTextBoundary extends _TextBoundary {
  _ExpandedTextBoundary(this.innerTextBoundary, this.outerTextBoundary);

  final _TextBoundary innerTextBoundary;
  final _TextBoundary outerTextBoundary;

  @override
  TextEditingValue get textEditingValue {
    assert(innerTextBoundary.textEditingValue ==
        outerTextBoundary.textEditingValue);
    return innerTextBoundary.textEditingValue;
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return outerTextBoundary.getLeadingTextBoundaryAt(
      innerTextBoundary.getLeadingTextBoundaryAt(position),
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return outerTextBoundary.getTrailingTextBoundaryAt(
      innerTextBoundary.getTrailingTextBoundaryAt(position),
    );
  }
}

// Force the innerTextBoundary to interpret the input [TextPosition]s as caret
// locations instead of code unit positions.
//
// The innerTextBoundary must be a [_TextBoundary] that interprets the input
// [TextPosition]s as code unit positions.
class _CollapsedSelectionBoundary extends _TextBoundary {
  _CollapsedSelectionBoundary(this.innerTextBoundary, this.isForward);

  final _TextBoundary innerTextBoundary;
  final bool isForward;

  @override
  TextEditingValue get textEditingValue => innerTextBoundary.textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getLeadingTextBoundaryAt(position)
        : position.offset <= 0
            ? const TextPosition(offset: 0)
            : innerTextBoundary.getLeadingTextBoundaryAt(
                TextPosition(offset: position.offset - 1));
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getTrailingTextBoundaryAt(position)
        : position.offset <= 0
            ? const TextPosition(offset: 0)
            : innerTextBoundary.getTrailingTextBoundaryAt(
                TextPosition(offset: position.offset - 1));
  }
}

// A _TextBoundary that creates a [TextRange] where its start is from the
// specified leading text boundary and its end is from the specified trailing
// text boundary.
class _MixedBoundary extends _TextBoundary {
  _MixedBoundary(this.leadingTextBoundary, this.trailingTextBoundary);

  final _TextBoundary leadingTextBoundary;
  final _TextBoundary trailingTextBoundary;

  @override
  TextEditingValue get textEditingValue {
    assert(leadingTextBoundary.textEditingValue ==
        trailingTextBoundary.textEditingValue);
    return leadingTextBoundary.textEditingValue;
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      leadingTextBoundary.getLeadingTextBoundaryAt(position);

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) =>
      trailingTextBoundary.getTrailingTextBoundaryAt(position);
}

// -------------------------------  Text Actions -------------------------------
class _DeleteTextAction<T extends DirectionalTextEditingIntent>
    extends ContextAction<T> {
  _DeleteTextAction(this.state, this.getTextBoundariesForIntent);

  final MongolEditableTextState state;
  final _TextBoundary Function(T intent) getTextBoundariesForIntent;

  TextRange _expandNonCollapsedRange(TextEditingValue value) {
    final TextRange selection = value.selection;
    assert(selection.isValid);
    assert(!selection.isCollapsed);
    final _TextBoundary atomicBoundary = state.widget.obscureText
        ? _CodeUnitBoundary(value)
        : _CharacterBoundary(value);

    return TextRange(
      start: atomicBoundary
          .getLeadingTextBoundaryAt(TextPosition(offset: selection.start))
          .offset,
      end: atomicBoundary
          .getTrailingTextBoundaryAt(TextPosition(offset: selection.end - 1))
          .offset,
    );
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    if (kDebugMode) {
      print('mongol_editable_text -> _DeleteTextAction.invoke');
    }
    final TextSelection selection = state._value.selection;
    assert(selection.isValid);

    if (!selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
            state._value,
            '',
            _expandNonCollapsedRange(state._value),
            SelectionChangedCause.keyboard),
      );
    }

    final _TextBoundary textBoundary = getTextBoundariesForIntent(intent);
    if (!textBoundary.textEditingValue.selection.isValid) {
      return null;
    }
    if (!textBoundary.textEditingValue.selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
            state._value,
            '',
            _expandNonCollapsedRange(textBoundary.textEditingValue),
            SelectionChangedCause.keyboard),
      );
    }

    return Actions.invoke(
      context!,
      ReplaceTextIntent(
        textBoundary.textEditingValue,
        '',
        textBoundary
            .getTextBoundaryAt(textBoundary.textEditingValue.selection.base),
        SelectionChangedCause.keyboard,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      !state.widget.readOnly && state._value.selection.isValid;
}

class _UpdateTextSelectionAction<T extends DirectionalCaretMovementIntent>
    extends ContextAction<T> {
  _UpdateTextSelectionAction(
    this.state,
    this.ignoreNonCollapsedSelection,
    this.getTextBoundariesForIntent,
  );

  final MongolEditableTextState state;
  final bool ignoreNonCollapsedSelection;
  final _TextBoundary Function(T intent) getTextBoundariesForIntent;

  static const int newlineCodeUnit = 10;

  // Returns true iff the given position is at a wordwrap boundary in the
  // upstream position.
  bool _isAtWordwrapUpstream(TextPosition position) {
    final TextPosition end = TextPosition(
      offset: state.renderEditable.getLineAtOffset(position).end,
      affinity: TextAffinity.upstream,
    );
    return end == position &&
        end.offset != state.textEditingValue.text.length &&
        state.textEditingValue.text.codeUnitAt(position.offset) !=
            newlineCodeUnit;
  }

  // Returns true iff the given position at a wordwrap boundary in the
  // downstream position.
  bool _isAtWordwrapDownstream(TextPosition position) {
    final TextPosition start = TextPosition(
      offset: state.renderEditable.getLineAtOffset(position).start,
    );
    return start == position &&
        start.offset != 0 &&
        state.textEditingValue.text.codeUnitAt(position.offset - 1) !=
            newlineCodeUnit;
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final TextSelection selection = state._value.selection;
    assert(selection.isValid);

    final bool collapseSelection =
        intent.collapseSelection || !state.widget.selectionEnabled;
    // Collapse to the logical start/end.
    TextSelection collapse(TextSelection selection) {
      assert(selection.isValid);
      assert(!selection.isCollapsed);
      return selection.copyWith(
        baseOffset: intent.forward ? selection.end : selection.start,
        extentOffset: intent.forward ? selection.end : selection.start,
      );
    }

    if (!selection.isCollapsed &&
        !ignoreNonCollapsedSelection &&
        collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
            state._value, collapse(selection), SelectionChangedCause.keyboard),
      );
    }

    final _TextBoundary textBoundary = getTextBoundariesForIntent(intent);
    final TextSelection textBoundarySelection =
        textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return null;
    }
    if (!textBoundarySelection.isCollapsed &&
        !ignoreNonCollapsedSelection &&
        collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(state._value, collapse(textBoundarySelection),
            SelectionChangedCause.keyboard),
      );
    }

    TextPosition extent = textBoundarySelection.extent;

    // If continuesAtWrap is true extent and is at the relevant wordwrap, then
    // move it just to the other side of the wordwrap.
    if (intent.continuesAtWrap) {
      if (intent.forward && _isAtWordwrapUpstream(extent)) {
        extent = TextPosition(
          offset: extent.offset,
        );
      } else if (!intent.forward && _isAtWordwrapDownstream(extent)) {
        extent = TextPosition(
          offset: extent.offset,
          affinity: TextAffinity.upstream,
        );
      }
    }

    final TextPosition newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    final TextSelection newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : textBoundarySelection.extendTo(newExtent);

    // If collapseAtReversal is true and would have an effect, collapse it.
    if (!selection.isCollapsed &&
        intent.collapseAtReversal &&
        (selection.baseOffset < selection.extentOffset !=
            newSelection.baseOffset < newSelection.extentOffset)) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
          state._value,
          TextSelection.fromPosition(selection.base),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(textBoundary.textEditingValue, newSelection,
          SelectionChangedCause.keyboard),
    );
  }

  @override
  bool get isActionEnabled => state._value.selection.isValid;
}

class _ExtendSelectionOrCaretPositionAction extends ContextAction<
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent> {
  _ExtendSelectionOrCaretPositionAction(
      this.state, this.getTextBoundariesForIntent);

  final MongolEditableTextState state;
  final _TextBoundary Function(
          ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent)
      getTextBoundariesForIntent;

  @override
  Object? invoke(ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent,
      [BuildContext? context]) {
    final TextSelection selection = state._value.selection;
    assert(selection.isValid);

    final _TextBoundary textBoundary = getTextBoundariesForIntent(intent);
    final TextSelection textBoundarySelection =
        textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return null;
    }

    final TextPosition extent = textBoundarySelection.extent;
    final TextPosition newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    final TextSelection newSelection =
        (newExtent.offset - textBoundarySelection.baseOffset) *
                    (textBoundarySelection.extentOffset -
                        textBoundarySelection.baseOffset) <
                0
            ? textBoundarySelection.copyWith(
                extentOffset: textBoundarySelection.baseOffset,
                affinity: textBoundarySelection.extentOffset >
                        textBoundarySelection.baseOffset
                    ? TextAffinity.downstream
                    : TextAffinity.upstream,
              )
            : textBoundarySelection.extendTo(newExtent);

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(textBoundary.textEditingValue, newSelection,
          SelectionChangedCause.keyboard),
    );
  }

  @override
  bool get isActionEnabled =>
      state.widget.selectionEnabled && state._value.selection.isValid;
}

class _UpdateTextSelectionToAdjacentLineAction<
    T extends DirectionalCaretMovementIntent> extends ContextAction<T> {
  _UpdateTextSelectionToAdjacentLineAction(this.state);

  final MongolEditableTextState state;

  HorizontalCaretMovementRun? _horizontalMovementRun;
  TextSelection? _runSelection;

  void stopCurrentVerticalRunIfSelectionChanges() {
    final TextSelection? runSelection = _runSelection;
    if (runSelection == null) {
      assert(_horizontalMovementRun == null);
      return;
    }
    _runSelection = state._value.selection;
    final TextSelection currentSelection = state.widget.controller.selection;
    final bool continueCurrentRun = currentSelection.isValid &&
        currentSelection.isCollapsed &&
        currentSelection.baseOffset == runSelection.baseOffset &&
        currentSelection.extentOffset == runSelection.extentOffset;
    if (!continueCurrentRun) {
      _horizontalMovementRun = null;
      _runSelection = null;
    }
  }

  @override
  void invoke(T intent, [BuildContext? context]) {
    assert(state._value.selection.isValid);

    final bool collapseSelection =
        intent.collapseSelection || !state.widget.selectionEnabled;
    final TextEditingValue value = state._textEditingValueForTextLayoutMetrics;
    if (!value.selection.isValid) {
      return;
    }

    if (_horizontalMovementRun?.isValid == false) {
      _horizontalMovementRun = null;
      _runSelection = null;
    }

    final HorizontalCaretMovementRun currentRun = _horizontalMovementRun ??
        state.renderEditable.startHorizontalCaretMovement(
            state.renderEditable.selection!.extent);

    final bool shouldMove =
        intent.forward ? currentRun.moveNext() : currentRun.movePrevious();
    final TextPosition newExtent = shouldMove
        ? currentRun.current
        : (intent.forward
            ? TextPosition(offset: state._value.text.length)
            : const TextPosition(offset: 0));
    final TextSelection newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : value.selection.extendTo(newExtent);

    Actions.invoke(
      context!,
      UpdateSelectionIntent(
          value, newSelection, SelectionChangedCause.keyboard),
    );
    if (state._value.selection == newSelection) {
      _horizontalMovementRun = currentRun;
      _runSelection = newSelection;
    }
  }

  @override
  bool get isActionEnabled => state._value.selection.isValid;
}

class _SelectAllAction extends ContextAction<SelectAllTextIntent> {
  _SelectAllAction(this.state);

  final MongolEditableTextState state;

  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        state._value,
        TextSelection(baseOffset: 0, extentOffset: state._value.text.length),
        intent.cause,
      ),
    );
  }

  @override
  bool get isActionEnabled => state.widget.selectionEnabled;
}

class _CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  _CopySelectionAction(this.state);

  final MongolEditableTextState state;

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      state.cutSelection(intent.cause);
    } else {
      state.copySelection(intent.cause);
    }
  }

  @override
  bool get isActionEnabled =>
      state._value.selection.isValid && !state._value.selection.isCollapsed;
}

/// A void function that takes a [TextEditingValue].
@visibleForTesting
typedef TextEditingValueCallback = void Function(TextEditingValue value);

/// Provides undo/redo capabilities for text editing.
///
/// Listens to [controller] as a [ValueNotifier] and saves relevant values for
/// undoing/redoing. The cadence at which values are saved is a best
/// approximation of the native behaviors of a hardware keyboard on Flutter's
/// desktop platforms, as there are subtle differences between each of these
/// platforms.
///
/// Listens to keyboard undo/redo shortcuts and calls [onTriggered] when a
/// shortcut is triggered that would affect the state of the [controller].
class _TextEditingHistory extends StatefulWidget {
  /// Creates an instance of [_TextEditingHistory].
  const _TextEditingHistory({
    required this.child,
    required this.controller,
    required this.onTriggered,
  });

  /// The child widget of [_TextEditingHistory].
  final Widget child;

  /// The [TextEditingController] to save the state of over time.
  final TextEditingController controller;

  /// Called when an undo or redo causes a state change.
  ///
  /// If the state would still be the same before and after the undo/redo, this
  /// will not be called. For example, receiving a redo when there is nothing
  /// to redo will not call this method.
  ///
  /// It is also not called when the controller is changed for reasons other
  /// than undo/redo.
  final TextEditingValueCallback onTriggered;

  @override
  State<_TextEditingHistory> createState() => _TextEditingHistoryState();
}

class _TextEditingHistoryState extends State<_TextEditingHistory> {
  final _UndoStack<TextEditingValue> _stack = _UndoStack<TextEditingValue>();
  late final _Throttled<TextEditingValue> _throttledPush;
  Timer? _throttleTimer;

  // This duration was chosen as a best fit for the behavior of Mac, Linux,
  // and Windows undo/redo state save durations, but it is not perfect for any
  // of them.
  static const Duration _kThrottleDuration = Duration(milliseconds: 500);

  void _undo(UndoTextIntent intent) {
    _update(_stack.undo());
  }

  void _redo(RedoTextIntent intent) {
    _update(_stack.redo());
  }

  void _update(TextEditingValue? nextValue) {
    if (nextValue == null) {
      return;
    }
    if (nextValue.text == widget.controller.text) {
      return;
    }
    widget.onTriggered(widget.controller.value.copyWith(
      text: nextValue.text,
      selection: nextValue.selection,
    ));
  }

  void _push() {
    if (widget.controller.value == TextEditingValue.empty) {
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // Composing text is not counted in history coalescing.
        if (!widget.controller.value.composing.isCollapsed) {
          return;
        }
        break;
      case TargetPlatform.android:
        // Gboard on Android puts non-CJK words in composing regions. Coalesce
        // composing text in order to allow the saving of partial words in that
        // case.
        break;
    }

    _throttleTimer = _throttledPush(widget.controller.value);
  }

  @override
  void initState() {
    super.initState();
    _throttledPush = _throttle<TextEditingValue>(
      duration: _kThrottleDuration,
      function: _stack.push,
    );
    _push();
    widget.controller.addListener(_push);
  }

  @override
  void didUpdateWidget(_TextEditingHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _stack.clear();
      oldWidget.controller.removeListener(_push);
      widget.controller.addListener(_push);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_push);
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        UndoTextIntent: Action<UndoTextIntent>.overridable(
            context: context,
            defaultAction: CallbackAction<UndoTextIntent>(onInvoke: _undo)),
        RedoTextIntent: Action<RedoTextIntent>.overridable(
            context: context,
            defaultAction: CallbackAction<RedoTextIntent>(onInvoke: _redo)),
      },
      child: widget.child,
    );
  }
}

/// A data structure representing a chronological list of states that can be
/// undone and redone.
class _UndoStack<T> {
  /// Creates an instance of [_UndoStack].
  _UndoStack();

  final List<T> _list = <T>[];

  // The index of the current value, or null if the list is empty.
  late int _index;

  /// Returns the current value of the stack.
  T? get currentValue => _list.isEmpty ? null : _list[_index];

  /// Add a new state change to the stack.
  ///
  /// Pushing identical objects will not create multiple entries.
  void push(T value) {
    if (_list.isEmpty) {
      _index = 0;
      _list.add(value);
      return;
    }

    assert(_index < _list.length && _index >= 0);

    if (value == currentValue) {
      return;
    }

    // If anything has been undone in this stack, remove those irrelevant states
    // before adding the new one.
    if (_index != _list.length - 1) {
      _list.removeRange(_index + 1, _list.length);
    }
    _list.add(value);
    _index = _list.length - 1;
  }

  /// Returns the current value after an undo operation.
  ///
  /// An undo operation moves the current value to the previously pushed value,
  /// if any.
  ///
  /// Iff the stack is completely empty, then returns null.
  T? undo() {
    if (_list.isEmpty) {
      return null;
    }

    assert(_index < _list.length && _index >= 0);

    if (_index != 0) {
      _index = _index - 1;
    }

    return currentValue;
  }

  /// Returns the current value after a redo operation.
  ///
  /// A redo operation moves the current value to the value that was last
  /// undone, if any.
  ///
  /// Iff the stack is completely empty, then returns null.
  T? redo() {
    if (_list.isEmpty) {
      return null;
    }

    assert(_index < _list.length && _index >= 0);

    if (_index < _list.length - 1) {
      _index = _index + 1;
    }

    return currentValue;
  }

  /// Remove everything from the stack.
  void clear() {
    _list.clear();
    _index = -1;
  }

  @override
  String toString() {
    return '_UndoStack $_list';
  }
}

/// A function that can be throttled with the throttle function.
typedef _Throttleable<T> = void Function(T currentArg);

/// A function that has been throttled by [_throttle].
typedef _Throttled<T> = Timer Function(T currentArg);

/// Returns a _Throttled that will call through to the given function only a
/// maximum of once per duration.
///
/// Only works for functions that take exactly one argument and return void.
_Throttled<T> _throttle<T>({
  required Duration duration,
  required _Throttleable<T> function,
  // If true, calls at the start of the timer.
  bool leadingEdge = false,
}) {
  Timer? timer;
  bool calledDuringTimer = false;
  late T arg;

  return (T currentArg) {
    arg = currentArg;
    if (timer != null) {
      calledDuringTimer = true;
      return timer!;
    }
    if (leadingEdge) {
      function(arg);
    }
    calledDuringTimer = false;
    timer = Timer(duration, () {
      if (!leadingEdge || calledDuringTimer) {
        function(arg);
      }
      timer = null;
    });
    return timer!;
  };
}

/// The start and end glyph widths (when in vertical orientation) of some
/// range of text.
@immutable
class _GlyphWidths {
  const _GlyphWidths({
    required this.start,
    required this.end,
  });

  /// The glyph width of the first line.
  final double start;

  /// The glyph width of the last line.
  final double end;
}
