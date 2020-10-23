// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mongol_rich_text.dart';

/// A run of vertical text with a single style.
///
/// The [MongolText] widget displays a string of vertical text with single
/// style. The string might break across multiple lines or might all be
/// displayed on the same line depending on the layout constraints.
///
/// The [style] argument is optional. When omitted, the text will use the style
/// from the closest enclosing [DefaultTextStyle]. If the given style's
/// [TextStyle.inherit] property is true (the default), the given style will
/// be merged with the closest enclosing [DefaultTextStyle]. This merging
/// behavior is useful, for example, to make the text bold while using the
/// default font family and size.
///
/// Using the [MongolText.rich] constructor, the [MongolText] widget can
/// display a paragraph with differently styled [TextSpan]s. The sample
/// that follows displays "Hello beautiful world" with different styles
/// for each word.
///
/// ```dart
/// const MongolText.rich(
///   TextSpan(
///     text: 'Hello', // default text style
///     children: <TextSpan>[
///       TextSpan(text: ' beautiful ', style: TextStyle(fontStyle: FontStyle.italic)),
///       TextSpan(text: 'world', style: TextStyle(fontWeight: FontWeight.bold)),
///     ],
///   ),
/// )
/// ```
///
/// See also:
///
///  * [MongolRichText], which gives you more control over the text styles.
///  * [DefaultTextStyle], which sets default styles for [MongolText] widgets.
class MongolText extends StatelessWidget {
  /// Creates a text widget for vertical Mongolian layout.
  ///
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  ///
  /// The [data] parameter must not be null.
  const MongolText(
    this.data, {
    Key key,
    this.style,
    this.textScaleFactor,
    this.semanticsLabel,
  })  : assert(
          data != null,
          'A non-null String must be provided to a MongolText widget.',
        ),
        textSpan = null,
        super(key: key);

  /// Creates a vertical Mongolian text widget with a [TextSpan].
  ///
  /// The [textSpan] parameter must not be null.
  ///
  /// See [MongolRichText] which provides a lower-level way to draw text.
  const MongolText.rich(
    this.textSpan, {
    Key key,
    this.style,
    this.textScaleFactor,
    this.semanticsLabel,
  })  : assert(
          textSpan != null,
          'A non-null TextSpan must be provided to a Text.rich widget.',
        ),
        data = null,
        super(key: key);

  /// This is the text that the MongolText widget will display.
  final String data;

  /// The text to display as a [TextSpan].
  ///
  /// This will be null if [data] is provided instead.
  final TextSpan textSpan;

  /// This is the style to use for the whole text string. If null a default
  /// style will be used.
  final TextStyle style;

  /// Font pixels per logical pixel
  final double textScaleFactor;

  /// An alternative semantics label for this text.
  ///
  /// If present, the semantics of this widget will contain this value instead
  /// of the actual text. This will overwrite any of the semantics labels applied
  /// directly to the [TextSpan]s.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// MongolText(r'$$', semanticsLabel: 'Double dollars')
  /// ```
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context);
    var effectiveTextStyle = style;
    if (style == null || style.inherit) {
      //effectiveTextStyle = _defaultMongolTextStyle.merge(style);
      effectiveTextStyle = defaultTextStyle.style.merge(effectiveTextStyle);
    }
    if (MediaQuery.boldTextOverride(context)) {
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    Widget result = MongolRichText(
      textScaleFactor: textScaleFactor ?? MediaQuery.textScaleFactorOf(context),
      text: TextSpan(
        style: effectiveTextStyle,
        text: data,
        children: textSpan != null ? <TextSpan>[textSpan] : null,
      ),
    );
    if (semanticsLabel != null) {
      result = Semantics(
        textDirection: TextDirection.ltr,
        label: semanticsLabel,
        child: ExcludeSemantics(
          child: result,
        ),
      );
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('data', data, showName: false));
    if (textSpan != null) {
      properties.add(textSpan.toDiagnosticsNode(
          name: 'textSpan', style: DiagnosticsTreeStyle.transition));
    }
    style?.debugFillProperties(properties);
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    if (semanticsLabel != null) {
      properties.add(StringProperty('semanticsLabel', semanticsLabel));
    }
  }
}
