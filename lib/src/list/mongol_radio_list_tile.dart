// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Examples can assume:
// void setState(VoidCallback fn) { }
// enum Meridiem { am, pm }
// enum SingingCharacter { lafayette }
// late SingingCharacter? _character;

import 'package:flutter/material.dart';

import 'mongol_list_tile.dart';
import 'mongol_checkbox_list_tile.dart';
import 'mongol_switch_list_tile.dart';
import '../text/mongol_text.dart';
import '../text/mongol_rich_text.dart';


enum _RadioType { material, adaptive }

/// A [MongolListTile] with a [Radio]. In other words, a radio button with a label.
///
/// The entire list tile is interactive: tapping anywhere in the tile selects
/// the radio button.
///
/// The [value], [groupValue], [onChanged], and [activeColor] properties of this
/// widget are identical to the similarly-named properties on the [Radio]
/// widget. The type parameter `T` serves the same purpose as that of the
/// [Radio] class' type parameter.
///
/// The [title], [subtitle], [isThreeLine], and [dense] properties are like
/// those of the same name on [MongolListTile].
///
/// The [selected] property on this widget is similar to the [MongolListTile.selected]
/// property. This tile's [activeColor] is used for the selected item's text color, or
/// the theme's [ThemeData.toggleableActiveColor] if [activeColor] is null.
///
/// This widget does not coordinate the [selected] state and the
/// [checked] state; to have the list tile appear selected when the
/// radio button is the selected radio button, set [selected] to true
/// when [value] matches [groupValue].
///
/// The radio button is shown on the left by default in left-to-right languages
/// (i.e. the leading edge). This can be changed using [controlAffinity]. The
/// [secondary] widget is placed on the opposite side. This maps to the
/// [MongolListTile.leading] and [MongolListTile.trailing] properties of [MongolListTile].
///
/// This widget requires a [Material] widget ancestor in the tree to paint
/// itself on, which is typically provided by the app's [Scaffold].
/// The [tileColor], and [selectedTileColor] are not painted by the
/// [MongolRadioListTile] itself but by the [Material] widget ancestor. In this
/// case, one can wrap a [Material] widget around the [MongolRadioListTile], e.g.:
///
/// {@tool snippet}
/// ```dart
/// ColoredBox(
///   color: Colors.green,
///   child: Material(
///     child: MongolRadioListTile<Meridiem>(
///       tileColor: Colors.red,
///       title: const MongolText('AM'),
///       groupValue: Meridiem.am,
///       value: Meridiem.am,
///       onChanged:(Meridiem? value) { },
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// ## Performance considerations when wrapping [MongolRadioListTile] with [Material]
///
/// Wrapping a large number of [MongolRadioListTile]s individually with [Material]s
/// is expensive. Consider only wrapping the [MongolRadioListTile]s that require it
/// or include a common [Material] ancestor where possible.
///
/// To show the [MongolRadioListTile] as disabled, pass null as the [onChanged]
/// callback.
///
/// {@tool dartpad}
/// ![MongolRadioListTile sample](https://flutter.github.io/assets-for-api-docs/assets/material/radio_list_tile.png)
///
/// This widget shows a pair of radio buttons that control the `_character`
/// field. The field is of the type `SingingCharacter`, an enum.
///
/// ```dart
/// import 'package:flutter/material.dart';
///
/// /// Flutter code sample for [MongolRadioListTile].
///
/// void main() => runApp(const RadioListTileApp());
///
/// class RadioListTileApp extends StatelessWidget {
///   const RadioListTileApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       theme: ThemeData(useMaterial3: true),
///       home: Scaffold(
///         appBar: AppBar(title: const Text('RadioListTile Sample')),
///         body: const RadioListTileExample(),
///       ),
///     );
///   }
/// }
///
/// enum SingingCharacter { lafayette, jefferson }
///
/// class RadioListTileExample extends StatefulWidget {
///   const RadioListTileExample({super.key});
///
///   @override
///   State<RadioListTileExample> createState() => _RadioListTileExampleState();
/// }
///
/// class _RadioListTileExampleState extends State<RadioListTileExample> {
///   SingingCharacter? _character = SingingCharacter.lafayette;
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: <Widget>[
///         MongolRadioListTile<SingingCharacter>(
///           title: const MongolText('Lafayette'),
///           value: SingingCharacter.lafayette,
///           groupValue: _character,
///           onChanged: (SingingCharacter? value) {
///             setState(() {
///               _character = value;
///             });
///           },
///         ),
///         MongolRadioListTile<SingingCharacter>(
///           title: const MongolText('Thomas Jefferson'),
///           value: SingingCharacter.jefferson,
///           groupValue: _character,
///           onChanged: (SingingCharacter? value) {
///             setState(() {
///               _character = value;
///             });
///           },
///         ),
///       ],
///     );
///   }
/// }
///```
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample demonstrates how [MongolRadioListTile] positions the radio widget
/// relative to the text in different configurations.
///
/// ```dart
/// import 'package:flutter/material.dart';
///
/// Flutter code sample for [MongolRadioListTile].
///
/// void main() => runApp(const RadioListTileApp());
///
/// class RadioListTileApp extends StatelessWidget {
///   const RadioListTileApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       theme: ThemeData(useMaterial3: true),
///       home: const RadioListTileExample(),
///     );
///   }
/// }
///
/// enum Groceries { pickles, tomato, lettuce }
///
/// class RadioListTileExample extends StatefulWidget {
///   const RadioListTileExample({super.key});
///
///   @override
///   State<RadioListTileExample> createState() => _RadioListTileExampleState();
/// }
///
/// class _RadioListTileExampleState extends State<RadioListTileExample> {
///   Groceries? _groceryItem = Groceries.pickles;
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: const Text('RadioListTile Sample')),
///       body: Column(
///         children: <Widget>[
///           MongolRadioListTile<Groceries>(
///             value: Groceries.pickles,
///             groupValue: _groceryItem,
///             onChanged: (Groceries? value) {
///               setState(() {
///                 _groceryItem = value;
///               });
///             },
///             title: const MongolText('Pickles'),
///             subtitle: const MongolText('Supporting text'),
///           ),
///           MongolRadioListTile<Groceries>(
///             value: Groceries.tomato,
///             groupValue: _groceryItem,
///             onChanged: (Groceries? value) {
///               setState(() {
///                 _groceryItem = value;
///               });
///             },
///             title: const MongolText('Tomato'),
///             subtitle: const MongolText(
///                 'Longer supporting text to demonstrate how the text wraps and the radio is centered vertically with the text.'),
///           ),
///           MongolRadioListTile<Groceries>(
///             value: Groceries.lettuce,
///             groupValue: _groceryItem,
///             onChanged: (Groceries? value) {
///               setState(() {
///                 _groceryItem = value;
///               });
///             },
///             title: const MongolText('Lettuce'),
///             subtitle: const MongolText(
///                 "Longer supporting text to demonstrate how the text wraps and how setting 'RadioListTile.isThreeLine = true' aligns the radio to the top vertically with the text."),
///             isThreeLine: true,
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Semantics in MongolRadioListTile
///
/// Since the entirety of the MongolRadioListTile is interactive, it should represent
/// itself as a single interactive entity.
///
/// To do so, a MongolRadioListTile widget wraps its children with a [MergeSemantics]
/// widget. [MergeSemantics] will attempt to merge its descendant [Semantics]
/// nodes into one node in the semantics tree. Therefore, MongolRadioListTile will
/// throw an error if any of its children requires its own [Semantics] node.
///
/// For example, you cannot nest a [MongolRichText] widget as a descendant of
/// MongolRadioListTile. [MongolRichText] has an embedded gesture recognizer that
/// requires its own [Semantics] node, which directly conflicts with
/// MongolRadioListTile's desire to merge all its descendants' semantic nodes
/// into one. Therefore, it may be necessary to create a custom radio tile
/// widget to accommodate similar use cases.
///
/// {@tool dartpad}
///
/// Here is an example of a custom labeled radio widget, called
/// LinkedLabelRadio, that includes an interactive [MongolRichText] widget that
/// handles tap gestures.
///
/// ```dart
/// import 'package:flutter/gestures.dart';
/// import 'package:flutter/material.dart';
///
/// Flutter code sample for custom labeled radio.
///
/// void main() => runApp(const LabeledRadioApp());
///
/// class LabeledRadioApp extends StatelessWidget {
///   const LabeledRadioApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       theme: ThemeData(useMaterial3: true),
///       home: Scaffold(
///         appBar: AppBar(title: const Text('Custom Labeled Radio Sample')),
///         body: const LabeledRadioExample(),
///       ),
///     );
///   }
/// }
///
/// class LinkedLabelRadio extends StatelessWidget {
///   const LinkedLabelRadio({
///     super.key,
///     required this.label,
///     required this.padding,
///     required this.groupValue,
///     required this.value,
///     required this.onChanged,
///   });
///
///   final String label;
///   final EdgeInsets padding;
///   final bool groupValue;
///   final bool value;
///   final ValueChanged<bool> onChanged;
///
///   @override
///   Widget build(BuildContext context) {
///     return Padding(
///       padding: padding,
///       child: Column(
///         children: <Widget>[
///           Radio<bool>(
///             groupValue: groupValue,
///             value: value,
///             onChanged: (bool? newValue) {
///               onChanged(newValue!);
///             },
///           ),
///           MongolRichText(
///             text: TextSpan(
///               text: label,
///               style: TextStyle(
///                 color: Theme.of(context).colorScheme.primary,
///                 decoration: TextDecoration.underline,
///               ),
///               recognizer: TapGestureRecognizer()
///                 ..onTap = () {
///                   debugPrint('Label has been tapped.');
///                 },
///             ),
///           ),
///         ],
///       ),
///     );
///   }
/// }
///
/// class LabeledRadioExample extends StatefulWidget {
///   const LabeledRadioExample({super.key});
///
///   @override
///   State<LabeledRadioExample> createState() => _LabeledRadioExampleState();
/// }
///
/// class _LabeledRadioExampleState extends State<LabeledRadioExample> {
///   bool _isRadioSelected = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Row(
///         mainAxisAlignment: MainAxisAlignment.center,
///         children: <Widget>[
///           LinkedLabelRadio(
///             label: 'First tappable label text',
///             padding: const EdgeInsets.symmetric(horizontal: 5.0),
///             value: true,
///             groupValue: _isRadioSelected,
///             onChanged: (bool newValue) {
///               setState(() {
///                 _isRadioSelected = newValue;
///               });
///             },
///           ),
///           LinkedLabelRadio(
///             label: 'Second tappable label text',
///             padding: const EdgeInsets.symmetric(horizontal: 5.0),
///             value: false,
///             groupValue: _isRadioSelected,
///             onChanged: (bool newValue) {
///               setState(() {
///                 _isRadioSelected = newValue;
///               });
///             },
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## MongolRadioListTile isn't exactly what I want
///
/// If the way MongolRadioListTile pads and positions its elements isn't quite what
/// you're looking for, you can create custom labeled radio widgets by
/// combining [Radio] with other widgets, such as [MongolText], [Padding] and
/// [InkWell].
///
/// {@tool dartpad}
///
/// Here is an example of a custom LabeledRadio widget, but you can easily
/// make your own configurable widget.
///
/// ```dart
/// import 'package:flutter/material.dart';
///
/// /// Flutter code sample for custom labeled radio.
///
/// void main() => runApp(const LabeledRadioApp());
///
/// class LabeledRadioApp extends StatelessWidget {
//   const LabeledRadioApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       theme: ThemeData(useMaterial3: true),
///       home: Scaffold(
///         appBar: AppBar(title: const Text('Custom Labeled Radio Sample')),
///         body: const LabeledRadioExample(),
///       ),
///     );
///   }
/// }
///
/// class LabeledRadio extends StatelessWidget {
///   const LabeledRadio({
///     super.key,
///     required this.label,
///     required this.padding,
///     required this.groupValue,
///     required this.value,
///     required this.onChanged,
///   });
///
///   final String label;
///   final EdgeInsets padding;
///   final bool groupValue;
///   final bool value;
///   final ValueChanged<bool> onChanged;
///
///   @override
///   Widget build(BuildContext context) {
///     return InkWell(
///       onTap: () {
///         if (value != groupValue) {
///           onChanged(value);
///         }
///       },
///       child: Padding(
///         padding: padding,
///         child: Column(
///           children: <Widget>[
///             Radio<bool>(
///               groupValue: groupValue,
///               value: value,
///               onChanged: (bool? newValue) {
///                 onChanged(newValue!);
///               },
///             ),
///             MongolText(label),
///           ],
///         ),
///       ),
///     );
///   }
/// }
///
/// class LabeledRadioExample extends StatefulWidget {
///   const LabeledRadioExample({super.key});
///
///   @override
///   State<LabeledRadioExample> createState() => _LabeledRadioExampleState();
/// }
///
/// class _LabeledRadioExampleState extends State<LabeledRadioExample> {
///   bool _isRadioSelected = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Row(
///         mainAxisAlignment: MainAxisAlignment.center,
///         children: <LabeledRadio>[
///           LabeledRadio(
///             label: 'This is the first label text',
///             padding: const EdgeInsets.symmetric(horizontal: 5.0),
///             value: true,
///             groupValue: _isRadioSelected,
///             onChanged: (bool newValue) {
///               setState(() {
///                 _isRadioSelected = newValue;
///               });
///             },
///           ),
///           LabeledRadio(
///             label: 'This is the second label text',
///             padding: const EdgeInsets.symmetric(horizontal: 5.0),
///             value: false,
///             groupValue: _isRadioSelected,
///             onChanged: (bool newValue) {
///               setState(() {
///                 _isRadioSelected = newValue;
///               });
///             },
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [MongolListTileTheme], which can be used to affect the style of list tiles,
///    including radio list tiles.
///  * [MongolCheckboxListTile], a similar widget for checkboxes.
///  * [MongolSwitchListTile], a similar widget for switches.
///  * [MongolListTile] and [Radio], the widgets from which this widget is made.
class MongolRadioListTile<T> extends StatelessWidget {
  /// Creates a combination of a list tile and a radio button.
  ///
  /// The radio tile itself does not maintain any state. Instead, when the radio
  /// button is selected, the widget calls the [onChanged] callback. Most
  /// widgets that use a radio button will listen for the [onChanged] callback
  /// and rebuild the radio tile with a new [groupValue] to update the visual
  /// appearance of the radio button.
  ///
  /// The following arguments are required:
  ///
  /// * [value] and [groupValue] together determine whether the radio button is
  ///   selected.
  /// * [onChanged] is called when the user selects this radio button.
  const MongolRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.contentPadding,
    this.shape,
    this.tileColor,
    this.selectedTileColor,
    this.visualDensity,
    this.focusNode,
    this.onFocusChange,
    this.enableFeedback,
  }) : _radioType = _RadioType.material,
       useCupertinoCheckmarkStyle = false,
       assert(!isThreeLine || subtitle != null);

  /// Creates a combination of a list tile and a platform adaptive radio.
  ///
  /// The checkbox uses [Radio.adaptive] to show a [CupertinoRadio] for
  /// iOS platforms, or [Radio] for all others.
  ///
  /// All other properties are the same as [RadioListTile].
  const MongolRadioListTile.adaptive({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.contentPadding,
    this.shape,
    this.tileColor,
    this.selectedTileColor,
    this.visualDensity,
    this.focusNode,
    this.onFocusChange,
    this.enableFeedback,
    this.useCupertinoCheckmarkStyle = false,
  }) : _radioType = _RadioType.adaptive,
       assert(!isThreeLine || subtitle != null);
  
  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for this group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  final T? groupValue;

  /// Called when the user selects this radio button.
  ///
  /// The radio button passes [value] as a parameter to this callback. The radio
  /// button does not actually change state until the parent widget rebuilds the
  /// radio tile with the new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The provided callback will not be invoked if this radio button is already
  /// selected.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// RadioListTile<SingingCharacter>(
  ///   title: const Text('Lafayette'),
  ///   value: SingingCharacter.lafayette,
  ///   groupValue: _character,
  ///   onChanged: (SingingCharacter? newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<T?>? onChanged;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [WidgetStateProperty.resolve] is used for the following [WidgetState]s:
  ///
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.disabled].
  ///
  /// If null, then the value of [RadioThemeData.mouseCursor] is used.
  /// If that is also null, then [WidgetStateMouseCursor.clickable] is used.
  final MouseCursor? mouseCursor;

  /// Set to true if this radio list tile is allowed to be returned to an
  /// indeterminate state by selecting it again when selected.
  ///
  /// To indicate returning to an indeterminate state, [onChanged] will be
  /// called with null.
  ///
  /// If true, [onChanged] can be called with [value] when selected while
  /// [groupValue] != [value], or with null when selected again while
  /// [groupValue] == [value].
  ///
  /// If false, [onChanged] will be called with [value] when it is selected
  /// while [groupValue] != [value], and only by selecting another radio button
  /// in the group (i.e. changing the value of [groupValue]) can this radio
  /// list tile be unselected.
  ///
  /// The default is false.
  ///
  /// {@tool dartpad}
  /// This example shows how to enable deselecting a radio button by setting the
  /// [toggleable] attribute.
  ///
  /// ** See code in examples/api/lib/material/radio_list_tile/radio_list_tile.toggleable.0.dart **
  /// {@end-tool}
  final bool toggleable;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to [ColorScheme.secondary] of the current [Theme].
  final Color? activeColor;

  /// The color that fills the radio button.
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.disabled].
  ///
  /// If null, then the value of [activeColor] is used in the selected state. If
  /// that is also null, then the value of [RadioThemeData.fillColor] is used.
  /// If that is also null, then the default value is used.
  final WidgetStateProperty<Color?>? fillColor;

  /// {@macro flutter.material.radio.materialTapTargetSize}
  ///
  /// Defaults to [MaterialTapTargetSize.shrinkWrap].
  final MaterialTapTargetSize? materialTapTargetSize;

  /// {@macro flutter.material.radio.hoverColor}
  final Color? hoverColor;

  /// The color for the radio's [Material].
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.pressed].
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///
  /// If null, then the value of [activeColor] with alpha [kRadialReactionAlpha]
  /// and [hoverColor] is used in the pressed and hovered state. If that is also
  /// null, the value of [SwitchThemeData.overlayColor] is used. If that is
  /// also null, then the default value is used in the pressed and hovered state.
  final WidgetStateProperty<Color?>? overlayColor;

  /// {@macro flutter.material.radio.splashRadius}
  ///
  /// If null, then the value of [RadioThemeData.splashRadius] is used. If that
  /// is also null, then [kRadialReactionRadius] is used.
  final double? splashRadius;

  /// The primary content of the list tile.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// A widget to display on the opposite side of the tile from the radio button.
  ///
  /// Typically an [Icon] widget.
  final Widget? secondary;

  /// Whether this list tile is intended to display three lines of text.
  ///
  /// If false, the list tile is treated as having one line if the subtitle is
  /// null and treated as having two lines if the subtitle is non-null.
  final bool isThreeLine;

  /// Whether this list tile is part of a vertically dense list.
  ///
  /// If this property is null then its value is based on [ListTileThemeData.dense].
  final bool? dense;

  /// Whether to render icons and text in the [activeColor].
  ///
  /// No effort is made to automatically coordinate the [selected] state and the
  /// [checked] state. To have the list tile appear selected when the radio
  /// button is the selected radio button, set [selected] to true when [value]
  /// matches [groupValue].
  ///
  /// Normally, this property is left to its default value, false.
  final bool selected;

  /// Where to place the control relative to the text.
  final ListTileControlAffinity controlAffinity;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Defines the insets surrounding the contents of the tile.
  ///
  /// Insets the [Radio], [title], [subtitle], and [secondary] widgets
  /// in [RadioListTile].
  ///
  /// When null, `EdgeInsets.symmetric(horizontal: 16.0)` is used.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether this radio button is checked.
  ///
  /// To control this value, set [value] and [groupValue] appropriately.
  bool get checked => value == groupValue;

  /// If specified, [shape] defines the shape of the [RadioListTile]'s [InkWell] border.
  final ShapeBorder? shape;

  /// If specified, defines the background color for `RadioListTile` when
  /// [RadioListTile.selected] is false.
  final Color? tileColor;

  /// If non-null, defines the background color when [RadioListTile.selected] is true.
  final Color? selectedTileColor;

  /// Defines how compact the list tile's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  final VisualDensity? visualDensity;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.material.ListTile.enableFeedback}
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  final _RadioType _radioType;

  /// Whether to use the checkbox style for the [CupertinoRadio] control.
  ///
  /// Only usable under the [RadioListTile.adaptive] constructor. If set to
  /// true, on Apple platforms the radio button will appear as an iOS styled
  /// checkmark. Controls the [CupertinoRadio] through
  /// [CupertinoRadio.useCheckmarkStyle].
  ///
  /// Defaults to false.
  final bool useCupertinoCheckmarkStyle;

  @override
  Widget build(BuildContext context) {
    final Widget control;
    switch (_radioType) {
      case _RadioType.material:
        control = Radio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          toggleable: toggleable,
          activeColor: activeColor,
          materialTapTargetSize: materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
          autofocus: autofocus,
          fillColor: fillColor,
          mouseCursor: mouseCursor,
          hoverColor: hoverColor,
          overlayColor: overlayColor,
          splashRadius: splashRadius,
        );
      case _RadioType.adaptive:
        control = Radio<T>.adaptive(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          toggleable: toggleable,
          activeColor: activeColor,
          materialTapTargetSize: materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
          autofocus: autofocus,
          fillColor: fillColor,
          mouseCursor: mouseCursor,
          hoverColor: hoverColor,
          overlayColor: overlayColor,
          splashRadius: splashRadius,
          useCupertinoCheckmarkStyle: useCupertinoCheckmarkStyle,
        );
    }

    Widget? leading, trailing;
    switch (controlAffinity) {
      case ListTileControlAffinity.leading:
      case ListTileControlAffinity.platform:
        leading = control;
        trailing = secondary;
      case ListTileControlAffinity.trailing:
        leading = secondary;
        trailing = control;
    }
    final ThemeData theme = Theme.of(context);
    final RadioThemeData radioThemeData = RadioTheme.of(context);
    final Set<WidgetState> states = <WidgetState>{
      if (selected) WidgetState.selected,
    };
    final Color effectiveActiveColor = activeColor
      ?? radioThemeData.fillColor?.resolve(states)
      ?? theme.colorScheme.secondary;
    return MergeSemantics(
      child: MongolListTile(
        selectedColor: effectiveActiveColor,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        isThreeLine: isThreeLine,
        dense: dense,
        enabled: onChanged != null,
        shape: shape,
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: onChanged != null ? () {
          if (toggleable && checked) {
            onChanged!(null);
            return;
          }
          if (!checked) {
            onChanged!(value);
          }
        } : null,
        selected: selected,
        autofocus: autofocus,
        contentPadding: contentPadding,
        visualDensity: visualDensity,
        focusNode: focusNode,
        onFocusChange: onFocusChange,
        enableFeedback: enableFeedback,
      ),
    );
  }
}