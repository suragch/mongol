// Copyright 2014 The Flutter Authors.
// Copyright 2020 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: todo

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/mongol.dart';

void main() {
  testWidgets('MongolText respects media query', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(textScaleFactor: 1.3),
      child: Center(
        child: MongolText('Hello'),
      ),
    ));

    var text =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);

    await tester.pumpWidget(const Center(
      child: MongolText('Hello'),
    ));

    text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
  });

  testWidgets('MongolText respects textScaleFactor with default font size',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: MongolText('Hello')));

    var text =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(14.0));
    expect(baseSize.height, equals(70.0));

    await tester.pumpWidget(const Center(
      child: MongolText(
        'Hello',
        textScaleFactor: 1.5,
      ),
    ));

    text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.5);
    final largeSize = tester.getSize(find.byType(MongolRichText));
    expect(largeSize.width, 21.0);
    expect(largeSize.height, equals(105.0));
  });

  testWidgets('MongolText respects textScaleFactor with explicit font size',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Center(
      child: MongolText('Hello', style: TextStyle(fontSize: 20.0)),
    ));

    var text =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
    final baseSize = tester.getSize(find.byType(MongolRichText));
    expect(baseSize.width, equals(20.0));
    expect(baseSize.height, equals(100.0));

    await tester.pumpWidget(const Center(
      child: MongolText('Hello',
          style: TextStyle(fontSize: 20.0), textScaleFactor: 1.3),
    ));

    text = tester.firstWidget(find.byType(MongolRichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);
    final largeSize = tester.getSize(find.byType(MongolRichText));
    expect(largeSize.width, equals(26.0));
    expect(largeSize.height, anyOf(131.0, 130.0));
  });

  testWidgets(
      'MongolText can be created from TextSpans and uses defaultTextStyle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const DefaultTextStyle(
        style: TextStyle(
          fontSize: 20.0,
        ),
        child: MongolText.rich(
          TextSpan(
            text: 'Hello',
            children: <TextSpan>[
              TextSpan(
                text: ' beautiful ',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(
                text: 'world',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    final text =
        tester.firstWidget(find.byType(MongolRichText)) as MongolRichText;
    expect(text, isNotNull);
    expect(text.text.style!.fontSize, 20.0);
  });

  // TODO the following features and tests need to be added:

  // testWidgets('inline widgets works with ellipsis', (WidgetTester tester) async {
  //   // Regression test for https://github.com/flutter/flutter/issues/35869
  //   const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
  //   await tester.pumpWidget(
  //     Text.rich(
  //       TextSpan(
  //         children: <InlineSpan>[
  //           const TextSpan(
  //             text: 'a very very very very very very very very very very long line',
  //           ),
  //           WidgetSpan(
  //             child: SizedBox(
  //               width: 20,
  //               height: 40,
  //               child: Card(
  //                 child: RichText(
  //                   text: const TextSpan(text: 'widget should be truncated'),
  //                   textDirection: TextDirection.rtl,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //         style: textStyle,
  //       ),
  //       textDirection: TextDirection.ltr,
  //       maxLines: 1,
  //       overflow: TextOverflow.ellipsis,
  //     ),
  //   );
  //   expect(tester.takeException(), null);
  // }, skip: isBrowser);

  // testWidgets('TapGesture recognizers contribute link semantics', (WidgetTester tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
  //   await tester.pumpWidget(
  //     Text.rich(
  //       TextSpan(
  //         children: <TextSpan>[
  //           TextSpan(
  //             text: 'click me',
  //             recognizer: TapGestureRecognizer()..onTap = () { },
  //           ),
  //         ],
  //         style: textStyle,
  //       ),
  //       textDirection: TextDirection.ltr,
  //     ),
  //   );
  //   final TestSemantics expectedSemantics = TestSemantics.root(
  //     children: <TestSemantics>[
  //       TestSemantics.rootChild(
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             label: 'click me',
  //             textDirection: TextDirection.ltr,
  //             actions: <SemanticsAction>[SemanticsAction.tap],
  //             flags: <SemanticsFlag>[SemanticsFlag.isLink]
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  //   expect(semantics, hasSemantics(
  //     expectedSemantics,
  //     ignoreTransform: true,
  //     ignoreId: true,
  //     ignoreRect: true,
  //   ));
  //   semantics.dispose();
  // });

  // testWidgets('Overflow is clipping correctly - short text with overflow: clip', (WidgetTester tester) async {
  //   await _pumpTextWidget(
  //     tester: tester,
  //     overflow: TextOverflow.clip,
  //     text: 'Hi',
  //   );

  //   expect(find.byType(Text), isNot(paints..clipRect()));
  // });

  // testWidgets('Overflow is clipping correctly - long text with overflow: ellipsis', (WidgetTester tester) async {
  //   await _pumpTextWidget(
  //     tester: tester,
  //     overflow: TextOverflow.ellipsis,
  //     text: 'a long long long long text, should be clip',
  //   );

  //   expect(
  //     find.byType(Text),
  //     paints..clipRect(rect: const Rect.fromLTWH(0, 0, 50, 50)),
  //   );
  // }, skip: isBrowser);

  // testWidgets('Overflow is clipping correctly - short text with overflow: ellipsis', (WidgetTester tester) async {
  //   await _pumpTextWidget(
  //     tester: tester,
  //     overflow: TextOverflow.ellipsis,
  //     text: 'Hi',
  //   );

  //   expect(find.byType(Text), isNot(paints..clipRect()));
  // });

  // testWidgets('Overflow is clipping correctly - long text with overflow: fade', (WidgetTester tester) async {
  //   await _pumpTextWidget(
  //     tester: tester,
  //     overflow: TextOverflow.fade,
  //     text: 'a long long long long text, should be clip',
  //   );

  //   expect(
  //     find.byType(Text),
  //     paints..clipRect(rect: const Rect.fromLTWH(0, 0, 50, 50)),
  //   );
  // });

  // testWidgets('Overflow is clipping correctly - short text with overflow: fade', (WidgetTester tester) async {
  //   await _pumpTextWidget(
  //     tester: tester,
  //     overflow: TextOverflow.fade,
  //     text: 'Hi',
  //   );

  //   expect(find.byType(Text), isNot(paints..clipRect()));
  // });

  // testWidgets('Overflow is clipping correctly - long text with overflow: visible', (WidgetTester tester) async {
  //   await _pumpTextWidget(
  //     tester: tester,
  //     overflow: TextOverflow.visible,
  //     text: 'a long long long long text, should be clip',
  //   );

  //   expect(find.byType(Text), isNot(paints..clipRect()));
  // });

  // testWidgets('Overflow is clipping correctly - short text with overflow: visible', (WidgetTester tester) async {
  //   await _pumpTextWidget(
  //     tester: tester,
  //     overflow: TextOverflow.visible,
  //     text: 'Hi',
  //   );

  //   expect(find.byType(Text), isNot(paints..clipRect()));
  // });

  // testWidgets('textWidthBasis affects the width of a Text widget', (WidgetTester tester) async {
  //   Future<void> createText(TextWidthBasis textWidthBasis) {
  //     return tester.pumpWidget(
  //       MaterialApp(
  //         home: Scaffold(
  //           body: Center(
  //             child: Container(
  //               // Each word takes up more than a half of a line. Together they
  //               // wrap onto two lines, but leave a lot of extra space.
  //               child: Text(
  //                 'twowordsthateachtakeupmorethanhalfof alineoftextsothattheywrapwithlotsofextraspace',
  //                 textDirection: TextDirection.ltr,
  //                 textWidthBasis: textWidthBasis,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   const double fontHeight = 14.0;
  //   const double screenWidth = 800.0;

  //   // When textWidthBasis is parent, takes up full screen width.
  //   await createText(TextWidthBasis.parent);
  //   final Size textSizeParent = tester.getSize(find.byType(Text));
  //   expect(textSizeParent.width, equals(screenWidth));
  //   expect(textSizeParent.height, equals(fontHeight * 2));

  //   // When textWidthBasis is longestLine, sets the width to as small as
  //   // possible for the two lines.
  //   await createText(TextWidthBasis.longestLine);
  //   final Size textSizeLongestLine = tester.getSize(find.byType(Text));
  //   expect(textSizeLongestLine.width, equals(630.0));
  //   expect(textSizeLongestLine.height, equals(fontHeight * 2));
  // }, skip: isBrowser);

  // testWidgets('textWidthBasis with textAlign still obeys parent alignment', (WidgetTester tester) async {
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: const <Widget>[
  //               Text(
  //                 'LEFT ALIGNED, PARENT',
  //                 textAlign: TextAlign.left,
  //                 textWidthBasis: TextWidthBasis.parent,
  //               ),
  //               Text(
  //                 'RIGHT ALIGNED, PARENT',
  //                 textAlign: TextAlign.right,
  //                 textWidthBasis: TextWidthBasis.parent,
  //               ),
  //               Text(
  //                 'LEFT ALIGNED, LONGEST LINE',
  //                 textAlign: TextAlign.left,
  //                 textWidthBasis: TextWidthBasis.longestLine,
  //               ),
  //               Text(
  //                 'RIGHT ALIGNED, LONGEST LINE',
  //                 textAlign: TextAlign.right,
  //                 textWidthBasis: TextWidthBasis.longestLine,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   // All Texts have the same horizontal alignment.
  //   final double offsetX = tester.getTopLeft(find.text('LEFT ALIGNED, PARENT')).dx;
  //   expect(tester.getTopLeft(find.text('RIGHT ALIGNED, PARENT')).dx, equals(offsetX));
  //   expect(tester.getTopLeft(find.text('LEFT ALIGNED, LONGEST LINE')).dx, equals(offsetX));
  //   expect(tester.getTopLeft(find.text('RIGHT ALIGNED, LONGEST LINE')).dx, equals(offsetX));

  //   // All Texts are less than or equal to the width of the Column.
  //   final double width = tester.getSize(find.byType(Column)).width;
  //   expect(tester.getSize(find.text('LEFT ALIGNED, PARENT')).width, lessThan(width));
  //   expect(tester.getSize(find.text('RIGHT ALIGNED, PARENT')).width, lessThan(width));
  //   expect(tester.getSize(find.text('LEFT ALIGNED, LONGEST LINE')).width, lessThan(width));
  //   expect(tester.getSize(find.text('RIGHT ALIGNED, LONGEST LINE')).width, equals(width));
  // }, skip: isBrowser);

  // testWidgets('Paragraph.getBoxesForRange returns nothing when selection range is zero length', (WidgetTester tester) async {
  //   final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle());
  //   builder.addText('hello');
  //   final ui.Paragraph paragraph = builder.build();
  //   paragraph.layout(const ui.ParagraphConstraints(width: 1000));
  //   expect(paragraph.getBoxesForRange(2, 2), isEmpty);
  // });
}

// Future<void> _pumpTextWidget({ WidgetTester tester, String text, TextOverflow overflow }) {
//   return tester.pumpWidget(
//     Directionality(
//       textDirection: TextDirection.ltr,
//       child: Center(
//         child: Container(
//           width: 50.0,
//           height: 50.0,
//           child: Text(
//             text,
//             overflow: overflow,
//           ),
//         ),
//       ),
//     ),
//   );
// }
