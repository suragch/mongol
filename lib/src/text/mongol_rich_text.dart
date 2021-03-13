// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mongol_render_paragraph.dart';
import '../base/mongol_text_align.dart';

/// A string of rich text in vertical Mongolian layout.
///
/// Based on RichText of Flutter version 1.5. After that RichText became a
/// MultiChildRenderObjectWidget in order to support InlineSpans.
///
/// The [MongolRichText] widget displays text that uses multiple different styles. The
/// text to display is described using a tree of [TextSpan] objects, each of
/// which has an associated style that is used for that subtree. The text might
/// break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// Text displayed in a [MongolRichText] widget must be explicitly styled. When
/// picking which style to use, consider using [DefaultTextStyle.of] the current
/// [BuildContext] to provide defaults. For more details on how to style text in
/// a [MongolRichText] widget, see the documentation for [TextStyle].
///
/// Consider using the [MongolText] widget to integrate with the [DefaultTextStyle]
/// automatically. When all the text uses the same style, the default constructor
/// is less verbose. The [MongolText.rich] constructor allows you to style multiple
/// spans with the default text style while still allowing specified styles per
/// span.
///
/// {@tool snippet}
///
/// This sample demonstrates how to mix and match text with different text
/// styles using the [MongolRichText] Widget. It displays the text "Hello bold world,"
/// emphasizing the word "bold" using a bold font weight.
///
/// ```dart
/// MongolRichText(
///   text: TextSpan(
///     text: 'Hello ',
///     style: DefaultTextStyle.of(context).style,
///     children: <TextSpan>[
///       TextSpan(text: 'bold', style: TextStyle(fontWeight: FontWeight.bold)),
///       TextSpan(text: ' world!'),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [TextStyle], which discusses how to style text.
///  * [TextSpan], which is used to describe the text in a paragraph.
///  * [MongolText], which automatically applies the ambient styles described by a
///    [DefaultTextStyle] to a single string.
///  * [MongolText.rich], a const text widget that provides similar functionality
///    as [MongolRichText]. [MongokText.rich] will inherit [TextStyle] from [DefaultTextStyle].
class MongolRichText extends LeafRenderObjectWidget {
  /// Creates a paragraph of rich text in vertical orientation for traditional
  /// Mongolian.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  ///
  /// The [text] argument must not be null.
  const MongolRichText({
    Key? key,
    required this.text,
    this.textAlign = MongolTextAlign.top,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
  })  : assert(maxLines == null || maxLines > 0),
        super(key: key);

  /// The text to display in this widget.
  final TextSpan text;

  /// How the text should be aligned vertically.
  final MongolTextAlign textAlign;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was 
  /// unlimited vertical space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary. If the text exceeds the given number of lines, it will be
  /// truncated according to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  @override
  MongolRenderParagraph createRenderObject(BuildContext context) {
    return MongolRenderParagraph(
      text,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MongolRenderParagraph renderObject) {
    renderObject
      ..text = text
      ..textAlign = textAlign
      ..softWrap = softWrap
      ..overflow = overflow
      ..textScaleFactor = textScaleFactor
      ..maxLines = maxLines;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text.toPlainText()));
    properties.add(EnumProperty<MongolTextAlign>('textAlign', textAlign,
        defaultValue: MongolTextAlign.top));
    properties.add(FlagProperty('softWrap', value: softWrap, ifTrue: 'wrapping at box height', ifFalse: 'no wrapping except at line break characters', showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow,
        defaultValue: TextOverflow.clip));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
  }
}


