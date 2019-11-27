import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mongol/mongol.dart';

void main() {

  testWidgets('MongolRichText has correct instrinsic width',
      (WidgetTester tester) async {
    MongolRenderParagraph paragraph =
        MongolRenderParagraph(TextSpan(text: 'A string'));

    final double textHeight = paragraph.getMaxIntrinsicHeight(double.infinity);
    final double oneLineTextWidth =
        paragraph.getMinIntrinsicWidth(double.infinity);
    final double constrainedHeight = textHeight * 0.9;
    final double wrappedTextHeight =
        paragraph.getMinIntrinsicHeight(double.infinity);
    final double twoLinesTextWidth =
        paragraph.getMinIntrinsicWidth(constrainedHeight);

    expect(wrappedTextHeight, greaterThan(0.0));
    expect(wrappedTextHeight, lessThan(textHeight));
    expect(oneLineTextWidth, lessThan(twoLinesTextWidth));
    expect(twoLinesTextWidth, lessThan(oneLineTextWidth * 3.0));
    expect(paragraph.getMaxIntrinsicWidth(double.infinity),
        equals(oneLineTextWidth));
    expect(paragraph.getMaxIntrinsicWidth(constrainedHeight),
        equals(twoLinesTextWidth));
  });
}
