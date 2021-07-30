// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart' hide ListTile;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' hide WidgetTester;
import 'package:mongol/mongol.dart';

import 'rendering/mock_canvas.dart';
import 'widgets/finders.dart';
import 'widgets/mongol_widget_tester.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({Key? key}) : super(key: key);

  @override
  TestIconState createState() => TestIconState();
}

class TestIconState extends State<TestIcon> {
  late IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.add);
  }
}

class TestText extends StatefulWidget {
  const TestText(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  TestTextState createState() => TestTextState();
}

class TestTextState extends State<TestText> {
  late TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle = DefaultTextStyle.of(context).style;
    return MongolText(widget.text);
  }
}

void main() {
  // testMongolWidgets('MongolListTile geometry',
  //     (MongolWidgetTester tester) async {
  //   // See https://material.io/go/design-lists

  //   final Key leadingKey = GlobalKey();
  //   final Key trailingKey = GlobalKey();
  //   late bool hasSubtitle;

  //   const double topPadding = 10.0;
  //   const double bottomPadding = 20.0;
  //   Widget buildFrame(
  //       {bool dense = false,
  //       bool isTwoLine = false,
  //       bool isThreeLine = false,
  //       double textScaleFactor = 1.0,
  //       double? subtitleScaleFactor}) {
  //     hasSubtitle = isTwoLine || isThreeLine;
  //     subtitleScaleFactor ??= textScaleFactor;
  //     return MaterialApp(
  //       home: MediaQuery(
  //         data: MediaQueryData(
  //           padding:
  //               const EdgeInsets.only(top: topPadding, bottom: bottomPadding),
  //           textScaleFactor: textScaleFactor,
  //         ),
  //         child: Material(
  //           child: Center(
  //             child: MongolListTile(
  //               leading: SizedBox(key: leadingKey, width: 24.0, height: 24.0),
  //               title: const MongolText('title'),
  //               subtitle: hasSubtitle
  //                   ? MongolText('subtitle',
  //                       textScaleFactor: subtitleScaleFactor)
  //                   : null,
  //               trailing: SizedBox(key: trailingKey, width: 24.0, height: 24.0),
  //               dense: dense,
  //               isThreeLine: isThreeLine,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   void testChildren() {
  //     expect(find.byKey(leadingKey), findsOneWidget);
  //     expect(findMongol.text('title'), findsOneWidget);
  //     if (hasSubtitle) expect(findMongol.text('subtitle'), findsOneWidget);
  //     expect(find.byKey(trailingKey), findsOneWidget);
  //   }

  //   double left(String text) => tester.getTopLeft(findMongol.text(text)).dx;
  //   double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;
  //   double bottom(String text) =>
  //       tester.getBottomLeft(findMongol.text(text)).dy;
  //   double right(String text) =>
  //       tester.getBottomRight(findMongol.text(text)).dx;
  //   double height(String text) => tester.getRect(findMongol.text(text)).height;
  //   double width(String text) => tester.getRect(findMongol.text(text)).width;

  //   double leftKey(Key key) => tester.getTopLeft(find.byKey(key)).dx;
  //   double topKey(Key key) => tester.getTopLeft(find.byKey(key)).dy;
  //   double rightKey(Key key) => tester.getTopRight(find.byKey(key)).dx;
  //   double bottomKey(Key key) => tester.getBottomLeft(find.byKey(key)).dy;
  //   double widthKey(Key key) => tester.getSize(find.byKey(key)).width;
  //   double heightKey(Key key) => tester.getSize(find.byKey(key)).height;

  //   void testVerticalGeometry() {
  //     expect(topKey(leadingKey), math.max(16.0, topPadding));
  //     expect(top('title'), 56.0 + math.max(16.0, topPadding));
  //     if (hasSubtitle)
  //       expect(top('subtitle'), 56.0 + math.max(16.0, topPadding));
  //     expect(top('title'), bottomKey(leadingKey) + 32.0);
  //     expect(bottomKey(trailingKey), 800.0 - math.max(16.0, bottomPadding));
  //     expect(heightKey(trailingKey), 24.0);
  //   }

  //   void testHorizontalGeometry(double expectedWidth) {
  //     final Rect tileRect = tester.getRect(find.byType(MongolListTile));
  //     expect(tileRect.size, Size(800.0, expectedWidth));
  //     expect(left('title'), greaterThanOrEqualTo(tileRect.left));
  //     if (hasSubtitle) {
  //       expect(left('subtitle'), greaterThanOrEqualTo(right('title')));
  //       expect(right('subtitle'), lessThan(tileRect.right));
  //     } else {
  //       expect(left('title'),
  //           equals(tileRect.left + (tileRect.width - width('title')) / 2.0));
  //     }
  //     expect(widthKey(trailingKey), 24.0);
  //   }

  //   await tester.pumpWidget(buildFrame());
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(56.0);

  //   await tester.pumpWidget(buildFrame(dense: true));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(48.0);

  //   await tester.pumpWidget(buildFrame(isTwoLine: true));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(72.0);

  //   await tester.pumpWidget(buildFrame(isTwoLine: true, dense: true));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(64.0);

  //   await tester.pumpWidget(buildFrame(isThreeLine: true));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(88.0);

  //   await tester.pumpWidget(buildFrame(isThreeLine: true, dense: true));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(76.0);

  //   await tester.pumpWidget(buildFrame(textScaleFactor: 4.0));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(72.0);

  //   await tester.pumpWidget(buildFrame(dense: true, textScaleFactor: 4.0));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(72.0);

  //   await tester.pumpWidget(buildFrame(isTwoLine: true, textScaleFactor: 4.0));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(128.0);

  //   // Make sure that the height of a large subtitle is taken into account.
  //   await tester.pumpWidget(buildFrame(
  //       isTwoLine: true, textScaleFactor: 0.5, subtitleScaleFactor: 4.0));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(72.0);

  //   await tester.pumpWidget(
  //       buildFrame(isTwoLine: true, dense: true, textScaleFactor: 4.0));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(128.0);

  //   await tester
  //       .pumpWidget(buildFrame(isThreeLine: true, textScaleFactor: 4.0));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(128.0);

  //   await tester.pumpWidget(
  //       buildFrame(isThreeLine: true, dense: true, textScaleFactor: 4.0));
  //   testChildren();
  //   testVerticalGeometry();
  //   testHorizontalGeometry(128.0);
  // });

  testMongolWidgets('MongolListTile single-line geometry',
      (MongolWidgetTester tester) async {
    Widget buildFrame() {
      return const MaterialApp(
        home: Material(
          child: MongolListTile(
            title: MongolText('title'),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());

    // title
    expect(findMongol.text('title'), findsOneWidget);
    final offset = tester.getTopLeft(findMongol.text('title'));
    expect(offset, const Offset(20.0, 16.0));
  });

  testMongolWidgets('MongolListTile.divideTiles',
      (MongolWidgetTester tester) async {
    final List<String> titles = <String>['first', 'second', 'third'];

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return ListView(
              scrollDirection: Axis.horizontal,
              children: MongolListTile.divideTiles(
                context: context,
                tiles: titles.map<Widget>(
                    (String title) => MongolListTile(title: MongolText(title))),
              ).toList(),
            );
          },
        ),
      ),
    ));

    expect(findMongol.text('first'), findsOneWidget);
    expect(findMongol.text('second'), findsOneWidget);
    expect(findMongol.text('third'), findsOneWidget);
  });

  testMongolWidgets('MongolListTile.divideTiles with empty list',
      (MongolWidgetTester tester) async {
    final Iterable<Widget> output =
        MongolListTile.divideTiles(tiles: <Widget>[], color: Colors.grey);
    expect(output, isEmpty);
  });

  testMongolWidgets('MongolListTile.divideTiles only runs the generator once',
      (MongolWidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/78879
    int callCount = 0;
    Iterable<Widget> generator() sync* {
      callCount += 1;
      yield const MongolText('');
      yield const MongolText('');
    }

    final List<Widget> output =
        MongolListTile.divideTiles(tiles: generator(), color: Colors.grey)
            .toList();
    expect(output, hasLength(2));
    expect(callCount, 1);
  });

  testMongolWidgets('MongolListTileTheme', (MongolWidgetTester tester) async {
    final Key titleKey = UniqueKey();
    final Key subtitleKey = UniqueKey();
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();
    late ThemeData theme;

    Widget buildFrame({
      bool enabled = true,
      bool dense = false,
      bool selected = false,
      ShapeBorder? shape,
      Color? selectedColor,
      Color? iconColor,
      Color? textColor,
    }) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: MongolListTileTheme(
              dense: dense,
              shape: shape,
              selectedColor: selectedColor,
              iconColor: iconColor,
              textColor: textColor,
              child: Builder(
                builder: (BuildContext context) {
                  theme = Theme.of(context);
                  return MongolListTile(
                    enabled: enabled,
                    selected: selected,
                    leading: TestIcon(key: leadingKey),
                    trailing: TestIcon(key: trailingKey),
                    title: TestText('title', key: titleKey),
                    subtitle: TestText('subtitle', key: subtitleKey),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    const Color green = Color(0xFF00FF00);
    const Color red = Color(0xFFFF0000);
    const ShapeBorder roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );

    Color iconColor(Key key) =>
        tester.state<TestIconState>(find.byKey(key)).iconTheme.color!;
    Color textColor(Key key) =>
        tester.state<TestTextState>(find.byKey(key)).textStyle.color!;
    ShapeBorder inkWellBorder() => tester
        .widget<InkWell>(find.descendant(
            of: find.byType(MongolListTile), matching: find.byType(InkWell)))
        .customBorder!;

    // A selected MongolListTile's leading, trailing, and text get the primary color by default
    await tester.pumpWidget(buildFrame(selected: true));
    await tester.pump(
        const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.primaryColor);
    expect(iconColor(trailingKey), theme.primaryColor);
    expect(textColor(titleKey), theme.primaryColor);
    expect(textColor(subtitleKey), theme.primaryColor);

    // A selected MongolListTile's leading, trailing, and text get the MongolListTileTheme's selectedColor
    await tester.pumpWidget(buildFrame(selected: true, selectedColor: green));
    await tester.pump(
        const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), green);
    expect(iconColor(trailingKey), green);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // An unselected MongolListTile's leading and trailing get the MongolListTileTheme's iconColor
    // An unselected MongolListTile's title texts get the MongolListTileTheme's textColor
    await tester.pumpWidget(buildFrame(iconColor: red, textColor: green));
    await tester.pump(
        const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), red);
    expect(iconColor(trailingKey), red);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // If the item is disabled it's rendered with the theme's disabled color.
    await tester.pumpWidget(buildFrame(enabled: false));
    await tester.pump(
        const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // If the item is disabled it's rendered with the theme's disabled color.
    // Even if it's selected.
    await tester.pumpWidget(buildFrame(enabled: false, selected: true));
    await tester.pump(
        const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // A selected MongolListTile's InkWell gets the MongolListTileTheme's shape
    await tester.pumpWidget(buildFrame(selected: true, shape: roundedShape));
    expect(inkWellBorder(), roundedShape);
  });

  // testMongolWidgets('MongolListTile semantics',
  //     (MongolWidgetTester tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);

  //   await tester.pumpWidget(
  //     Material(
  //       child: Directionality(
  //         textDirection: TextDirection.ltr,
  //         child: MediaQuery(
  //           data: const MediaQueryData(),
  //           child: Row(
  //             children: <Widget>[
  //               const MongolListTile(
  //                 title: MongolText('one'),
  //               ),
  //               MongolListTile(
  //                 title: const MongolText('two'),
  //                 onTap: () {},
  //               ),
  //               const MongolListTile(
  //                 title: MongolText('three'),
  //                 selected: true,
  //               ),
  //               const MongolListTile(
  //                 title: MongolText('four'),
  //                 enabled: false,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(
  //     semantics,
  //     hasSemantics(
  //       TestSemantics.root(
  //         children: <TestSemantics>[
  //           TestSemantics.rootChild(
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.hasEnabledState,
  //               SemanticsFlag.isEnabled,
  //             ],
  //             label: 'one',
  //           ),
  //           TestSemantics.rootChild(
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.hasEnabledState,
  //               SemanticsFlag.isEnabled,
  //               SemanticsFlag.isFocusable,
  //             ],
  //             actions: <SemanticsAction>[SemanticsAction.tap],
  //             label: 'two',
  //           ),
  //           TestSemantics.rootChild(
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.isSelected,
  //               SemanticsFlag.hasEnabledState,
  //               SemanticsFlag.isEnabled,
  //             ],
  //             label: 'three',
  //           ),
  //           TestSemantics.rootChild(
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.hasEnabledState,
  //             ],
  //             label: 'four',
  //           ),
  //         ],
  //       ),
  //       ignoreTransform: true,
  //       ignoreId: true,
  //       ignoreRect: true,
  //     ),
  //   );

  //   semantics.dispose();
  // });

  testMongolWidgets('MongolListTile contentPadding 1',
      (MongolWidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: const MongolListTile(
                contentPadding: EdgeInsets.only(
                  top: 10.0,
                  bottom: 20.0,
                  left: 30.0,
                  right: 40.0,
                ),
                leading: MongolText('L'),
                title: MongolText('title'),
                trailing: MongolText('T'),
              ),
            ),
          ),
        ),
      );
    }

    double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;
    double bottom(String text) =>
        tester.getBottomRight(findMongol.text(text)).dy;

    await tester.pumpWidget(buildFrame(TextDirection.ltr));

    expect(tester.getSize(find.byType(MongolListTile)), const Size(126.0, 600));
    expect(top('L'), 10.0); // contentPadding.start = 10
    expect(bottom('T'), 580.0); // 800 - contentPadding.end
  });

  testMongolWidgets('MongolListTile contentPadding 2',
      (MongolWidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: const MongolListTile(
                contentPadding: EdgeInsetsDirectional.only(
                  start: 10.0,
                  end: 20.0,
                  top: 30.0,
                  bottom: 40.0,
                ),
                leading: MongolText('L'),
                title: MongolText('title'),
                trailing: MongolText('T'),
              ),
            ),
          ),
        ),
      );
    }

    double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;
    double bottom(String text) =>
        tester.getBottomLeft(findMongol.text(text)).dy;

    await tester.pumpWidget(buildFrame(TextDirection.ltr));

    expect(tester.getSize(find.byType(MongolListTile)), const Size(86.0, 600));
    expect(top('L'), 30.0);
    expect(bottom('T'), 560.0);
  });

  testMongolWidgets('MongolListTileTheme wide leading Widget',
      (MongolWidgetTester tester) async {
    const Key leadingKey = ValueKey<String>('L');

    Widget buildFrame(double leadingHeight, TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: MongolListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    SizedBox(key: leadingKey, width: 32, height: leadingHeight),
                title: const MongolText('title'),
                subtitle: const MongolText('subtitle'),
              ),
            ),
          ),
        ),
      );
    }

    double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;

    await tester.pumpWidget(buildFrame(24.0, TextDirection.ltr));
    expect(tester.getSize(find.byType(MongolListTile)), const Size(72.0, 600));
    expect(tester.getTopLeft(find.byKey(leadingKey)), const Offset(16.0, 0.0));
    expect(tester.getBottomRight(find.byKey(leadingKey)),
        const Offset(48.0, 24.0));

    expect(top('title'), 40.0);
    expect(top('subtitle'), 40.0);

    await tester.pumpWidget(buildFrame(56.0, TextDirection.ltr));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(72.0, 600.0));
    expect(tester.getTopLeft(find.byKey(leadingKey)), const Offset(16.0, 0.0));
    expect(tester.getBottomRight(find.byKey(leadingKey)),
        const Offset(48.0, 56.0));
    expect(top('title'), 72.0);
    expect(top('subtitle'), 72.0);
  });

  testMongolWidgets('MongolListTile leading and trailing positions',
      (MongolWidgetTester tester) async {
    // This test is based on the redlines at
    // https://material.io/design/components/lists.html#specs

    // DENSE "ONE"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              MongolListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                  TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(MongolListTile).at(0)),
        const Rect.fromLTWH(0.0, 0.0, 177.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)),
        const Rect.fromLTWH(16.0, 16.0, 40.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 40.0, 584.0));
    expect(tester.getRect(find.byType(MongolListTile).at(1)),
        const Rect.fromLTRB(177.0, 0.0, 225.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)),
        const Rect.fromLTRB(181.0, 16.0, 221.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(189.0, 560.0, 213.0, 584.0));

    // NON-DENSE "ONE"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              MongolListTile(
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(
        seconds: 2)); // the text styles are animated when we change dense
    //                                                                          LEFT                 TOP                   WIDTH  HEIGHT
    expect(tester.getRect(find.byType(MongolListTile).at(0)),
        const Rect.fromLTRB(0.0, 0.0, 216.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)),
        const Rect.fromLTWH(16.0, 16.0, 40.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 40.0, 584.0));
    expect(tester.getRect(find.byType(MongolListTile).at(1)),
        const Rect.fromLTRB(216.0, 0.0, 272.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)),
        const Rect.fromLTRB(224.0, 16.0, 264.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(232.0, 560.0, 256.0, 584.0));

    // DENSE "TWO"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              MongolListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(MongolListTile).at(0)),
        const Rect.fromLTRB(0.0, 0.0, 180.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)),
        const Rect.fromLTWH(16.0, 16.0, 40.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 40.0, 584.0));
    expect(tester.getRect(find.byType(MongolListTile).at(1)),
        const Rect.fromLTRB(180.0, 0.0, 244.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)),
        const Rect.fromLTRB(192.0, 16.0, 232.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(200.0, 560.0, 224.0, 584.0));

    // NON-DENSE "TWO"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              MongolListTile(
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(MongolListTile).at(0)),
        const Rect.fromLTRB(0.0, 0.0, 180.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)),
        const Rect.fromLTWH(16.0, 16.0, 40.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 40.0, 584.0));
    expect(tester.getRect(find.byType(MongolListTile).at(1)),
        const Rect.fromLTRB(180.0, 0.0, 252.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)),
        const Rect.fromLTRB(196.0, 16.0, 236.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(204.0, 560.0, 228.0, 584.0));

    // DENSE "THREE"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                dense: true,
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              MongolListTile(
                dense: true,
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(MongolListTile).at(0)),
        const Rect.fromLTRB(0.0, 0.0, 180.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)),
        const Rect.fromLTWH(16.0, 16.0, 40.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 40.0, 584.0));
    expect(tester.getRect(find.byType(MongolListTile).at(1)),
        const Rect.fromLTRB(180.0, 0.0, 256.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)),
        const Rect.fromLTRB(196.0, 16.0, 236.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(196.0, 560.0, 220.0, 584.0));

    // NON-DENSE THREE-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              MongolListTile(
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
                subtitle: MongolText('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(MongolListTile).at(0)),
        const Rect.fromLTRB(0.0, 0.0, 180.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)),
        const Rect.fromLTWH(16.0, 16.0, 40.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 40.0, 584.0));
    expect(tester.getRect(find.byType(MongolListTile).at(1)),
        const Rect.fromLTRB(180.0, 0.0, 268.0, 600.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)),
        const Rect.fromLTRB(196.0, 16.0, 236.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(196.0, 560.0, 220.0, 584.0));

    // "ONE-LINE" with Small Leading Widget
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading:
                    SizedBox(height: 12.0, width: 24.0, child: Placeholder()),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              MongolListTile(
                leading:
                    SizedBox(height: 12.0, width: 24.0, child: Placeholder()),
                trailing:
                    SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: MongolText('A'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(
        seconds: 2)); // the text styles are animated when we change dense
    //                                                                          LEFT                 TOP           WIDTH  HEIGHT
    expect(tester.getRect(find.byType(MongolListTile).at(0)),
        const Rect.fromLTRB(0.0, 0.0, 216.0, 600.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTWH(16.0, 16.0, 24.0, 12.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(16.0, 560.0, 40.0, 584.0));
    expect(tester.getRect(find.byType(MongolListTile).at(1)),
        const Rect.fromLTRB(216.0, 0.0, 272.0, 600.0));
    expect(tester.getRect(find.byType(Placeholder).at(2)),
        const Rect.fromLTRB(232.0, 16.0, 256.0, 28.0));
    expect(tester.getRect(find.byType(Placeholder).at(3)),
        const Rect.fromLTRB(232.0, 560.0, 256.0, 584.0));
  });

  testMongolWidgets(
      'MongolListTile leading icon height does not exceed MongolListTile height',
      (MongolWidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/28765
    const SizedBox oversizedWidget =
        SizedBox(height: 24.0, width: 80.0, child: Placeholder());

    // Dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('A'),
                dense: true,
              ),
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(0.0, 16.0, 48.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(48.0, 16.0, 96.0, 40.0));

    // Non-dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('A'),
                dense: false,
              ),
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(0.0, 16.0, 56.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(56.0, 16.0, 112.0, 40.0));

    // Dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                dense: true,
              ),
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(8.0, 16.0, 56.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(72.0, 16.0, 120.0, 40.0));

    // Non-dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                dense: false,
              ),
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(8.0, 16.0, 64.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(80.0, 16.0, 136.0, 40.0));

    // Dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                isThreeLine: true,
                dense: true,
              ),
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                isThreeLine: true,
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 16.0, 64.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(92.0, 16.0, 140.0, 40.0));

    // Non-dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                isThreeLine: true,
                dense: false,
              ),
              MongolListTile(
                leading: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                isThreeLine: true,
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 16.0, 72.0, 40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(104.0, 16.0, 160.0, 40.0));
  });

  testMongolWidgets(
      'MongolListTile trailing icon width does not exceed MongolListTile width',
      (MongolWidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/28765
    const SizedBox oversizedWidget =
        SizedBox(height: 24.0, width: 80.0, child: Placeholder());

    // Dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('A'),
                dense: true,
              ),
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(0.0, 560.0, 48.0, 584.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(48.0, 560.0, 96.0, 584.0));

    // Non-dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('A'),
                dense: false,
              ),
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(0.0, 560.0, 56.0, 584.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(56.0, 560.0, 112.0, 584.0));

    // Dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                dense: true,
              ),
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(8.0, 560.0, 56.0, 584.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(72.0, 560.0, 120.0, 584.0));

    // Non-dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                dense: false,
              ),
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(8.0, 560.0, 64.0, 584.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(80.0, 560.0, 136.0, 584.0));

    // Dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                isThreeLine: true,
                dense: true,
              ),
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                isThreeLine: true,
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 64.0, 584.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(92.0, 560.0, 140.0, 584.0));

    // Non-dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const <Widget>[
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('A'),
                subtitle: MongolText('A'),
                isThreeLine: true,
                dense: false,
              ),
              MongolListTile(
                trailing: oversizedWidget,
                title: MongolText('B'),
                subtitle: MongolText('B'),
                isThreeLine: true,
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)),
        const Rect.fromLTRB(16.0, 560.0, 72.0, 584.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),
        const Rect.fromLTRB(104.0, 560.0, 160.0, 584.0));
  });

  testMongolWidgets('MongolListTile only accepts focus when enabled',
      (MongolWidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              MongolListTile(
                title: MongolText('A', key: childKey),
                dense: true,
                enabled: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(); // Let the focus take effect.

    final FocusNode tileNode = Focus.of(childKey.currentContext!);
    tileNode.requestFocus();
    await tester.pump(); // Let the focus take effect.
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);

    expect(tileNode.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              MongolListTile(
                title: MongolText('A', key: childKey),
                dense: true,
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.binding.focusManager.primaryFocus, isNot(equals(tileNode)));
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

  testMongolWidgets('MongolListTile can autofocus unless disabled.',
      (MongolWidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              MongolListTile(
                title: MongolText('A', key: childKey),
                dense: true,
                enabled: true,
                autofocus: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              MongolListTile(
                title: MongolText('A', key: childKey),
                dense: true,
                enabled: false,
                autofocus: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

  testMongolWidgets('MongolListTile is focusable and has correct focus color',
      (MongolWidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'MongolListTile');
    tester.binding.focusManager.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: MongolListTile(
                  onTap: enabled ? () {} : null,
                  focusColor: Colors.orange[500],
                  autofocus: true,
                  focusNode: focusNode,
                ),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      find.byType(Material),
      paints
        ..rect(
          color: Colors.orange[500],
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        )
        ..rect(
          color: const Color(0xffffffff),
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        ),
    );

    // Check when the list tile is disabled.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(
      find.byType(Material),
      paints
        ..rect(
          color: const Color(0xffffffff),
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        ),
    );
  });

  testMongolWidgets('MongolListTile can be hovered and has correct hover color',
      (MongolWidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: MongolListTile(
                  onTap: enabled ? () {} : null,
                  hoverColor: Colors.orange[500],
                  autofocus: true,
                ),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.byType(Material),
      paints
        ..rect(
          color: const Color(0x1f000000),
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        )
        ..rect(
          color: const Color(0xffffffff),
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        ),
    );

    // Start hovering
    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(MongolListTile)));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.byType(Material),
      paints
        ..rect(
          color: const Color(0x1f000000),
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        )
        ..rect(
          color: Colors.orange[500],
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        )
        ..rect(
          color: const Color(0xffffffff),
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        ),
    );

    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.byType(Material),
      paints
        ..rect(
          color: Colors.orange[500],
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        )
        ..rect(
          color: const Color(0xffffffff),
          rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
        ),
    );
  });

  // // This test passes when tested individually but not in a group
  // testMongolWidgets('MongolListTile can be triggered by keyboard shortcuts',
  //     (MongolWidgetTester tester) async {
  //   tester.binding.focusManager.highlightStrategy =
  //       FocusHighlightStrategy.alwaysTraditional;
  //   const Key tileKey = Key('MongolListTile1');
  //   bool tapped = false;
  //   Widget buildApp({bool enabled = true}) {
  //     return MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: StatefulBuilder(
  //               builder: (BuildContext context, StateSetter setState) {
  //             return Container(
  //               width: 200,
  //               height: 100,
  //               color: Colors.white,
  //               child: MongolListTile(
  //                 key: tileKey,
  //                 onTap: enabled
  //                     ? () {
  //                         setState(() {
  //                           tapped = true;
  //                         });
  //                       }
  //                     : null,
  //                 hoverColor: Colors.orange[500],
  //                 autofocus: true,
  //               ),
  //             );
  //           }),
  //         ),
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(buildApp());
  //   await tester.pumpAndSettle();

  //   await tester.sendKeyEvent(LogicalKeyboardKey.space);
  //   await tester.pumpAndSettle();

  //   expect(tapped, isTrue);
  // });

  testMongolWidgets('MongolListTile responds to density changes.',
      (MongolWidgetTester tester) async {
    const Key key = Key('test');
    Future<void> buildTest(VisualDensity visualDensity) async {
      return tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: MongolListTile(
                key: key,
                onTap: () {},
                autofocus: true,
                visualDensity: visualDensity,
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(VisualDensity.standard);
    final RenderBox box = tester.renderObject(find.byKey(key));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(56.0, 600.0)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(68.0, 600.0)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(44.0, 600.0)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(68.0, 600.0)));
  });

  testMongolWidgets('MongolListTile shape is painted correctly',
      (MongolWidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/63877
    const ShapeBorder rectShape = RoundedRectangleBorder();
    const ShapeBorder stadiumShape = StadiumBorder();
    final Color tileColor = Colors.red.shade500;

    Widget buildMongolListTile(ShapeBorder shape) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: MongolListTile(shape: shape, tileColor: tileColor),
          ),
        ),
      );
    }

    // Test rectangle shape
    await tester.pumpWidget(buildMongolListTile(rectShape));
    Rect rect = tester.getRect(find.byType(MongolListTile));

    // Check if a path was painted with the correct color and shape
    expect(
      find.byType(Material),
      paints
        ..path(
          color: tileColor,
          // Corners should be included
          includes: <Offset>[
            Offset(rect.left, rect.top),
            Offset(rect.right, rect.top),
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
          ],
          // Points outside rect should be excluded
          excludes: <Offset>[
            Offset(rect.left - 1, rect.top - 1),
            Offset(rect.right + 1, rect.top - 1),
            Offset(rect.left - 1, rect.bottom + 1),
            Offset(rect.right + 1, rect.bottom + 1),
          ],
        ),
    );

    // Test stadium shape
    await tester.pumpWidget(buildMongolListTile(stadiumShape));
    rect = tester.getRect(find.byType(MongolListTile));

    // Check if a path was painted with the correct color and shape
    expect(
      find.byType(Material),
      paints
        ..path(
          color: tileColor,
          // Center points of sides should be included
          includes: <Offset>[
            Offset(rect.left + rect.width / 2, rect.top),
            Offset(rect.left, rect.top + rect.height / 2),
            Offset(rect.right, rect.top + rect.height / 2),
            Offset(rect.left + rect.width / 2, rect.bottom),
          ],
          // Corners should be excluded
          excludes: <Offset>[
            Offset(rect.left, rect.top),
            Offset(rect.right, rect.top),
            Offset(rect.left, rect.bottom),
            Offset(rect.right, rect.bottom),
          ],
        ),
    );
  });

  testMongolWidgets('MongolListTile changes mouse cursor when hovered',
      (MongolWidgetTester tester) async {
    // Test MongolListTile() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: MongolListTile(
                onTap: () {},
                mouseCursor: SystemMouseCursors.text,
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(
        location: tester.getCenter(find.byType(MongolListTile)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: MongolListTile(
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click);

    // Test default cursor when disabled
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: MongolListTile(
                enabled: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic);

    // Test default cursor when onTap or onLongPress is null
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: MongolListTile(),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic);
  });

  testMongolWidgets('MongolListTile respects tileColor & selectedTileColor',
      (MongolWidgetTester tester) async {
    bool isSelected = false;
    final Color tileColor = Colors.green.shade500;
    final Color selectedTileColor = Colors.red.shade500;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return MongolListTile(
                  selected: isSelected,
                  selectedTileColor: selectedTileColor,
                  tileColor: tileColor,
                  onTap: () {
                    setState(() => isSelected = !isSelected);
                  },
                  title: const MongolText('Title'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Initially, when isSelected is false, the MongolListTile should respect tileColor.
    expect(find.byType(Material), paints..path(color: tileColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(MongolListTile));
    await tester.pumpAndSettle();

    // When isSelected is true, the MongolListTile should respect selectedTileColor.
    expect(find.byType(Material), paints..path(color: selectedTileColor));
  });

  testMongolWidgets(
      'MongolListTile shows Material ripple effects on top of tileColor',
      (MongolWidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/73616
    final Color tileColor = Colors.red.shade500;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolListTile(
              tileColor: tileColor,
              onTap: () {},
              title: const MongolText('Title'),
            ),
          ),
        ),
      ),
    );

    // Before MongolListTile is tapped, it should be tileColor
    expect(find.byType(Material), paints..path(color: tileColor));

    // Tap on tile to trigger ink effect and wait for it to be underway.
    await tester.tap(find.byType(MongolListTile));
    await tester.pump(const Duration(milliseconds: 200));

    // After tap, the tile could be drawn in tileColor, with the ripple (circle) on top
    expect(
      find.byType(Material),
      paints
        ..path(color: tileColor)
        ..circle(),
    );
  });

  testMongolWidgets('MongolListTile default tile color',
      (MongolWidgetTester tester) async {
    bool isSelected = false;
    const Color defaultColor = Colors.transparent;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return MongolListTile(
                  selected: isSelected,
                  onTap: () {
                    setState(() => isSelected = !isSelected);
                  },
                  title: const MongolText('Title'),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: defaultColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(MongolListTile));
    await tester.pumpAndSettle();

    expect(find.byType(Material), paints..path(color: defaultColor));
  });

  testMongolWidgets(
      "MongolListTile respects MongolListTileTheme's tileColor & selectedTileColor",
      (MongolWidgetTester tester) async {
    late MongolListTileTheme theme;
    bool isSelected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolListTileTheme(
            tileColor: Colors.green.shade500,
            selectedTileColor: Colors.red.shade500,
            child: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  theme = MongolListTileTheme.of(context);
                  return MongolListTile(
                    selected: isSelected,
                    onTap: () {
                      setState(() => isSelected = !isSelected);
                    },
                    title: const MongolText('Title'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: theme.tileColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(MongolListTile));
    await tester.pumpAndSettle();

    expect(find.byType(Material), paints..path(color: theme.selectedTileColor));
  });

  testMongolWidgets(
      "MongolListTileTheme's tileColor & selectedTileColor are overridden by MongolListTile properties",
      (MongolWidgetTester tester) async {
    bool isSelected = false;
    final Color tileColor = Colors.green.shade500;
    final Color selectedTileColor = Colors.red.shade500;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolListTileTheme(
            selectedTileColor: Colors.green,
            tileColor: Colors.red,
            child: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return MongolListTile(
                    tileColor: tileColor,
                    selectedTileColor: selectedTileColor,
                    selected: isSelected,
                    onTap: () {
                      setState(() => isSelected = !isSelected);
                    },
                    title: const MongolText('Title'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: tileColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(MongolListTile));
    await tester.pumpAndSettle();

    expect(find.byType(Material), paints..path(color: selectedTileColor));
  });

  testMongolWidgets('MongolListTile layout at zero size',
      (MongolWidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/66636
    const Key key = Key('key');

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 0.0,
          height: 0.0,
          child: MongolListTile(
            key: key,
            tileColor: Colors.green,
          ),
        ),
      ),
    ));

    final RenderBox renderBox = tester.renderObject(find.byKey(key));
    expect(renderBox.size.width, equals(0.0));
    expect(renderBox.size.height, equals(0.0));
  });

  // group('feedback', () {
  //   late FeedbackTester feedback;

  //   setUp(() {
  //     feedback = FeedbackTester();
  //   });

  //   tearDown(() {
  //     feedback.dispose();
  //   });

  //   testMongolWidgets('MongolListTile with disabled feedback', (MongolWidgetTester tester) async {
  //     const bool enableFeedback = false;

  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: MongolListTile(
  //             title: const MongolText('Title'),
  //             onTap: () {},
  //             enableFeedback: enableFeedback,
  //           ),
  //         ),
  //       ),
  //     );

  //     await tester.tap(find.byType(MongolListTile));
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 0);
  //     expect(feedback.hapticCount, 0);
  //   });

  //   testMongolWidgets('MongolListTile with enabled feedback', (MongolWidgetTester tester) async {
  //     const bool enableFeedback = true;

  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: MongolListTile(
  //             title: const MongolText('Title'),
  //             onTap: () {},
  //             enableFeedback: enableFeedback,
  //           ),
  //         ),
  //       ),
  //     );

  //     await tester.tap(find.byType(MongolListTile));
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 1);
  //     expect(feedback.hapticCount, 0);
  //   });

  //   testMongolWidgets('MongolListTile with enabled feedback by default',
  //       (MongolWidgetTester tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: MongolListTile(
  //             title: const MongolText('Title'),
  //             onTap: () {},
  //           ),
  //         ),
  //       ),
  //     );

  //     await tester.tap(find.byType(MongolListTile));
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 1);
  //     expect(feedback.hapticCount, 0);
  //   });

  //   testMongolWidgets('MongolListTile with disabled feedback using MongolListTileTheme',
  //       (MongolWidgetTester tester) async {
  //     const bool enableFeedbackTheme = false;

  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: MongolListTileTheme(
  //             enableFeedback: enableFeedbackTheme,
  //             child: MongolListTile(
  //               title: const MongolText('Title'),
  //               onTap: () {},
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     await tester.tap(find.byType(MongolListTile));
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 0);
  //     expect(feedback.hapticCount, 0);
  //   });

  //   testMongolWidgets(
  //       'MongolListTile.enableFeedback overrides MongolListTileTheme.enableFeedback',
  //       (MongolWidgetTester tester) async {
  //     const bool enableFeedbackTheme = false;
  //     const bool enableFeedback = true;

  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: MongolListTileTheme(
  //             enableFeedback: enableFeedbackTheme,
  //             child: MongolListTile(
  //               enableFeedback: enableFeedback,
  //               title: const MongolText('Title'),
  //               onTap: () {},
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     await tester.tap(find.byType(MongolListTile));
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 1);
  //     expect(feedback.hapticCount, 0);
  //   });
  // });

  testMongolWidgets('MongolListTile verticalTitleGap = 0.0',
      (MongolWidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection,
        {double? themeVerticalTitleGap, double? widgetVerticalTitleGap}) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: MongolListTileTheme(
              verticalTitleGap: themeVerticalTitleGap,
              child: Container(
                alignment: Alignment.topLeft,
                child: MongolListTile(
                  verticalTitleGap: widgetVerticalTitleGap,
                  leading: const MongolText('L'),
                  title: const MongolText('title'),
                  trailing: const MongolText('T'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;

    await tester
        .pumpWidget(buildFrame(TextDirection.ltr, widgetVerticalTitleGap: 0));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);

    await tester
        .pumpWidget(buildFrame(TextDirection.ltr, themeVerticalTitleGap: 0));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);

    await tester.pumpWidget(buildFrame(TextDirection.ltr,
        themeVerticalTitleGap: 10, widgetVerticalTitleGap: 0));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);
  });

  testMongolWidgets(
      'MongolListTile verticalTitleGap = (default) && MongolListTile minLeadingHeight = (default)',
      (MongolWidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: const MongolListTile(
                leading: MongolText('L'),
                title: MongolText('title'),
                trailing: MongolText('T'),
              ),
            ),
          ),
        ),
      );
    }

    double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;

    await tester.pumpWidget(buildFrame(TextDirection.ltr));

    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);
  });

  testMongolWidgets('MongolListTile verticalTitleGap with visualDensity',
      (MongolWidgetTester tester) async {
    Widget buildFrame({
      double? verticalTitleGap,
      VisualDensity? visualDensity,
    }) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: MongolListTile(
                visualDensity: visualDensity,
                verticalTitleGap: verticalTitleGap,
                leading: const MongolText('L'),
                title: const MongolText('title'),
                trailing: const MongolText('T'),
              ),
            ),
          ),
        ),
      );
    }

    double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;

    await tester.pumpWidget(buildFrame(
      verticalTitleGap: 10.0,
      visualDensity:
          const VisualDensity(vertical: VisualDensity.minimumDensity),
    ));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);

    // Pump another frame of the same widget to ensure the underlying render
    // object did not cache the original verticalTitleGap calculation based on the
    // visualDensity
    await tester.pumpWidget(buildFrame(
      verticalTitleGap: 10.0,
      visualDensity:
          const VisualDensity(vertical: VisualDensity.minimumDensity),
    ));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);
  });

  testMongolWidgets('MongolListTile minVerticalPadding = 80.0',
      (MongolWidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection,
        {double? themeMinHorizontalPadding,
        double? widgetMinHorizontalPadding}) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: MongolListTileTheme(
              minHorizontalPadding: themeMinHorizontalPadding,
              child: Container(
                alignment: Alignment.topLeft,
                child: MongolListTile(
                  minHorizontalPadding: widgetMinHorizontalPadding,
                  leading: const MongolText('L'),
                  title: const MongolText('title'),
                  trailing: const MongolText('T'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
        buildFrame(TextDirection.ltr, widgetMinHorizontalPadding: 80));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(176.0, 600.0));

    await tester.pumpWidget(
        buildFrame(TextDirection.ltr, themeMinHorizontalPadding: 80));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(176.0, 600.0));

    await tester.pumpWidget(buildFrame(TextDirection.ltr,
        themeMinHorizontalPadding: 0, widgetMinHorizontalPadding: 80));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(176.0, 600.0));
  });

  testMongolWidgets('MongolListTile minLeadingHeight = 60.0',
      (MongolWidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection,
        {double? themeMinLeadingHeight, double? widgetMinLeadingHeight}) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: MongolListTileTheme(
              minLeadingHeight: themeMinLeadingHeight,
              child: Container(
                alignment: Alignment.topLeft,
                child: MongolListTile(
                  minLeadingHeight: widgetMinLeadingHeight,
                  leading: const MongolText('L'),
                  title: const MongolText('title'),
                  trailing: const MongolText('T'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    double top(String text) => tester.getTopLeft(findMongol.text(text)).dy;

    await tester
        .pumpWidget(buildFrame(TextDirection.ltr, widgetMinLeadingHeight: 60));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);

    await tester
        .pumpWidget(buildFrame(TextDirection.ltr, themeMinLeadingHeight: 60));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);

    await tester.pumpWidget(buildFrame(TextDirection.ltr,
        themeMinLeadingHeight: 0, widgetMinLeadingHeight: 60));
    expect(
        tester.getSize(find.byType(MongolListTile)), const Size(56.0, 600.0));
    expect(top('title'), 48.0);
  });

  testMongolWidgets('colors are applied to leading and trailing text widgets',
      (MongolWidgetTester tester) async {
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    late ThemeData theme;
    Widget buildFrame({
      bool enabled = true,
      bool selected = false,
    }) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                theme = Theme.of(context);
                return MongolListTile(
                  enabled: enabled,
                  selected: selected,
                  leading: TestText('leading', key: leadingKey),
                  title: const TestText('title'),
                  trailing: TestText('trailing', key: trailingKey),
                );
              },
            ),
          ),
        ),
      );
    }

    Color textColor(Key key) =>
        tester.state<TestTextState>(find.byKey(key)).textStyle.color!;

    await tester.pumpWidget(buildFrame());
    // Enabled color should be default bodyText2 color.
    expect(textColor(leadingKey), theme.textTheme.bodyText2!.color);
    expect(textColor(trailingKey), theme.textTheme.bodyText2!.color);

    await tester.pumpWidget(buildFrame(selected: true));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Selected color should be ThemeData.primaryColor by default.
    expect(textColor(leadingKey), theme.primaryColor);
    expect(textColor(trailingKey), theme.primaryColor);

    await tester.pumpWidget(buildFrame(enabled: false));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Disabled color should be ThemeData.disabledColor by default.
    expect(textColor(leadingKey), theme.disabledColor);
    expect(textColor(trailingKey), theme.disabledColor);
  });

  testMongolWidgets(
      'MongolListTileTheme colors are applied to leading and trailing text widgets',
      (MongolWidgetTester tester) async {
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    const Color selectedColor = Colors.orange;
    const Color defaultColor = Colors.black;

    late ThemeData theme;
    Widget buildFrame({
      bool enabled = true,
      bool selected = false,
    }) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: MongolListTileTheme(
              selectedColor: selectedColor,
              textColor: defaultColor,
              child: Builder(
                builder: (BuildContext context) {
                  theme = Theme.of(context);
                  return MongolListTile(
                    enabled: enabled,
                    selected: selected,
                    leading: TestText('leading', key: leadingKey),
                    title: const TestText('title'),
                    trailing: TestText('trailing', key: trailingKey),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    Color textColor(Key key) =>
        tester.state<TestTextState>(find.byKey(key)).textStyle.color!;

    await tester.pumpWidget(buildFrame());
    // Enabled color should use MongolListTileTheme.textColor.
    expect(textColor(leadingKey), defaultColor);
    expect(textColor(trailingKey), defaultColor);

    await tester.pumpWidget(buildFrame(selected: true));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Selected color should use MongolListTileTheme.selectedColor.
    expect(textColor(leadingKey), selectedColor);
    expect(textColor(trailingKey), selectedColor);

    await tester.pumpWidget(buildFrame(enabled: false));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Disabled color should be ThemeData.disabledColor.
    expect(textColor(leadingKey), theme.disabledColor);
    expect(textColor(trailingKey), theme.disabledColor);
  });

  testMongolWidgets(
      'selected, enabled MongolListTile default icon color, light and dark themes',
      (MongolWidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/77004

    const ColorScheme lightColorScheme = ColorScheme.light();
    const ColorScheme darkColorScheme = ColorScheme.dark();
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    Widget buildFrame(
        {required Brightness brightness, required bool selected}) {
      final ThemeData theme = brightness == Brightness.light
          ? ThemeData.from(colorScheme: const ColorScheme.light())
          : ThemeData.from(colorScheme: const ColorScheme.dark());
      return MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: MongolListTile(
              enabled: true,
              selected: selected,
              leading: TestIcon(key: leadingKey),
              trailing: TestIcon(key: trailingKey),
            ),
          ),
        ),
      );
    }

    Color iconColor(Key key) =>
        tester.state<TestIconState>(find.byKey(key)).iconTheme.color!;

    await tester
        .pumpWidget(buildFrame(brightness: Brightness.light, selected: true));
    expect(iconColor(leadingKey), lightColorScheme.primary);
    expect(iconColor(trailingKey), lightColorScheme.primary);

    await tester
        .pumpWidget(buildFrame(brightness: Brightness.light, selected: false));
    expect(iconColor(leadingKey), Colors.black45);
    expect(iconColor(trailingKey), Colors.black45);

    await tester
        .pumpWidget(buildFrame(brightness: Brightness.dark, selected: true));
    await tester.pumpAndSettle(); // Animated theme change
    expect(iconColor(leadingKey), darkColorScheme.primary);
    expect(iconColor(trailingKey), darkColorScheme.primary);

    // For this configuration, MongolListTile defers to the default IconTheme.
    // The default dark theme's IconTheme has color:white
    await tester
        .pumpWidget(buildFrame(brightness: Brightness.dark, selected: false));
    expect(iconColor(leadingKey), Colors.white);
    expect(iconColor(trailingKey), Colors.white);
  });
}
