// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/mongol_font.dart';

import 'mongol_rich_text.dart';

class MongolText extends StatelessWidget {
  const MongolText(
    this.data, {
    Key key,
    this.style,
    this.textScaleFactor,
  })  : assert(data != null, 'The data cannot be null.'),
        super(key: key);

  /// This is the text that the MongolText widget will display.
  final String data;

  /// This is the style to use for the whole text string. If null a default
  /// style will be used.
  final TextStyle style;

  /// Font pixels per logical pixel
  final double textScaleFactor;

  static const TextStyle _defaultMongolTextStyle =
      TextStyle(fontFamily: MongolFont.qagan, fontSize: 24.0);

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = style;
    if (style == null || style.inherit) {
      effectiveTextStyle = _defaultMongolTextStyle.merge(style);
      effectiveTextStyle = defaultTextStyle.style.merge(effectiveTextStyle);
    }

    Widget result = MongolRichText(
      text: TextSpan(
        text: data,
        style: effectiveTextStyle,
      ),
      textScaleFactor: textScaleFactor ?? MediaQuery.textScaleFactorOf(context),
    );
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('data', data, showName: false));
    style?.debugFillProperties(properties);
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
  }
}
