// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/finders.dart';
import '../widgets/mongol_widget_tester.dart';
import '../widgets/semantics_tester.dart';

class MockOnPressedFunction {
  int called = 0;

  void handler() {
    called++;
  }
}

void main() {
  late MockOnPressedFunction mockOnPressedFunction;

  setUp(() {
    mockOnPressedFunction = MockOnPressedFunction();
  });

  testMongolWidgets('test default icon buttons are sized up to 48',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
        ),
      ),
    );

    final RenderBox iconButton =
        tester.renderObject(find.byType(MongolIconButton));
    expect(iconButton.size, const Size(48.0, 48.0));

    await tester.tap(find.byType(MongolIconButton));
    expect(mockOnPressedFunction.called, 1);
  });

  testMongolWidgets('test small icons are sized up to 48dp',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          iconSize: 10.0,
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
        ),
      ),
    );

    final RenderBox iconButton =
        tester.renderObject(find.byType(MongolIconButton));
    expect(iconButton.size, const Size(48.0, 48.0));
  });

  testMongolWidgets('test icons can be small when total size is >48dp',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          iconSize: 10.0,
          padding: const EdgeInsets.all(30.0),
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
        ),
      ),
    );

    final RenderBox iconButton =
        tester.renderObject(find.byType(MongolIconButton));
    expect(iconButton.size, const Size(70.0, 70.0));
  });

  testMongolWidgets('Small icons with non-null constraints can be <48dp',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          iconSize: 10.0,
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
          constraints: const BoxConstraints(),
        ),
      ),
    );

    final RenderBox iconButton =
        tester.renderObject(find.byType(MongolIconButton));

    // By default IconButton has a padding of 8.0 on all sides, so both
    // width and height are 10.0 + 2 * 8.0 = 26.0
    expect(iconButton.size, const Size(26.0, 26.0));
  });

  testMongolWidgets(
      'Small icons with non-null constraints and custom padding can be <48dp',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          iconSize: 10.0,
          padding: const EdgeInsets.all(3.0),
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
          constraints: const BoxConstraints(),
        ),
      ),
    );

    final RenderBox iconButton =
        tester.renderObject(find.byType(MongolIconButton));

    // This IconButton has a padding of 3.0 on all sides, so both
    // width and height are 10.0 + 2 * 3.0 = 16.0
    expect(iconButton.size, const Size(16.0, 16.0));
  });

  testMongolWidgets('Small icons comply with VisualDensity requirements',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: Theme(
          data: ThemeData(
              visualDensity: const VisualDensity(horizontal: 1, vertical: -1)),
          child: MongolIconButton(
            iconSize: 10.0,
            onPressed: mockOnPressedFunction.handler,
            icon: const Icon(Icons.link),
            constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
          ),
        ),
      ),
    );

    final RenderBox iconButton =
        tester.renderObject(find.byType(MongolIconButton));

    // VisualDensity(horizontal: 1, vertical: -1) increases the icon's
    // width by 4 pixels and decreases its height by 4 pixels, giving
    // final width 32.0 + 4.0 = 36.0 and
    // final height 32.0 - 4.0 = 28.0
    expect(iconButton.size, const Size(36.0, 28.0));
  });

  testMongolWidgets('test default icon buttons are constrained',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          padding: EdgeInsets.zero,
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.ac_unit),
          iconSize: 80.0,
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(MongolIconButton));
    expect(box.size, const Size(80.0, 80.0));
  });

  testMongolWidgets('test default icon buttons can be stretched if specified',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MongolIconButton(
                onPressed: mockOnPressedFunction.handler,
                icon: const Icon(Icons.ac_unit),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(MongolIconButton));
    expect(box.size, const Size(48.0, 600.0));
  });

  testMongolWidgets('test default padding', (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.ac_unit),
          iconSize: 80.0,
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(MongolIconButton));
    expect(box.size, const Size(96.0, 96.0));
  });

  testMongolWidgets('test tooltip', (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolIconButton(
              onPressed: mockOnPressedFunction.handler,
              icon: const Icon(Icons.ac_unit),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MongolTooltip), findsNothing);

    // Clear the widget tree.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolIconButton(
              onPressed: mockOnPressedFunction.handler,
              icon: const Icon(Icons.ac_unit),
              mongolTooltip: 'Test tooltip',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MongolTooltip), findsOneWidget);
    expect(findMongol.byTooltip('Test tooltip'), findsOneWidget);

    await tester.tap(findMongol.byTooltip('Test tooltip'));
    expect(mockOnPressedFunction.called, 1);
  });

  testMongolWidgets('IconButton AppBar size',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              MongolIconButton(
                padding: EdgeInsets.zero,
                onPressed: mockOnPressedFunction.handler,
                icon: const Icon(Icons.ac_unit),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox barBox = tester.renderObject(find.byType(AppBar));
    final RenderBox iconBox =
        tester.renderObject(find.byType(MongolIconButton));
    expect(iconBox.size.height, equals(barBox.size.height));
  });

  // This test is very similar to the '...explicit splashColor and highlightColor' test
  // in buttons_test.dart. If you change this one, you may want to also change that one.
  testMongolWidgets('IconButton with explicit splashColor and highlightColor',
      (MongolWidgetTester tester) async {
    const Color directSplashColor = Color(0xFF00000F);
    const Color directHighlightColor = Color(0xFF0000F0);

    Widget buttonWidget = wrap(
      child: MongolIconButton(
        icon: const Icon(Icons.android),
        splashColor: directSplashColor,
        highlightColor: directHighlightColor,
        onPressed: () {/* enable the button */},
      ),
    );

    await tester.pumpWidget(
      Theme(
        data: ThemeData(),
        child: buttonWidget,
      ),
    );

    final Offset center = tester.getCenter(find.byType(MongolIconButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(
        milliseconds: 200)); // wait for splash to be well under way

    expect(
      Material.of(tester.element(find.byType(MongolIconButton))),
      paints
        ..circle(color: directSplashColor)
        ..circle(color: directHighlightColor),
    );

    const Color themeSplashColor1 = Color(0xFF000F00);
    const Color themeHighlightColor1 = Color(0xFF00FF00);

    buttonWidget = wrap(
      child: MongolIconButton(
        icon: const Icon(Icons.android),
        onPressed: () {/* enable the button */},
      ),
    );

    await tester.pumpWidget(
      Theme(
        data: ThemeData(
          highlightColor: themeHighlightColor1,
          splashColor: themeSplashColor1,
        ),
        child: buttonWidget,
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MongolIconButton))),
      paints
        ..circle(color: themeSplashColor1)
        ..circle(color: themeHighlightColor1),
    );

    const Color themeSplashColor2 = Color(0xFF002200);
    const Color themeHighlightColor2 = Color(0xFF001100);

    await tester.pumpWidget(
      Theme(
        data: ThemeData(
          highlightColor: themeHighlightColor2,
          splashColor: themeSplashColor2,
        ),
        child:
            buttonWidget, // same widget, so does not get updated because of us
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MongolIconButton))),
      paints
        ..circle(color: themeSplashColor2)
        ..circle(color: themeHighlightColor2),
    );

    await gesture.up();
  });

  testMongolWidgets('IconButton with explicit splash radius',
      (MongolWidgetTester tester) async {
    const double splashRadius = 30.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolIconButton(
              icon: const Icon(Icons.android),
              splashRadius: splashRadius,
              onPressed: () {/* enable the button */},
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(MongolIconButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // Start gesture.
    await tester.pump(const Duration(
        milliseconds: 1000)); // Wait for splash to be well under way.

    expect(
      Material.of(tester.element(find.byType(MongolIconButton))),
      paints..circle(radius: splashRadius),
    );

    await gesture.up();
  });

  testMongolWidgets('IconButton Semantics (enabled)',
      (MongolWidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link, semanticLabel: 'link'),
        ),
      ),
    );

    expect(
        semantics,
        hasSemantics(
            TestSemantics.root(
              children: <TestSemantics>[
                TestSemantics.rootChild(
                  rect: const Rect.fromLTRB(0.0, 0.0, 48.0, 48.0),
                  actions: <SemanticsAction>[
                    SemanticsAction.tap,
                  ],
                  flags: <SemanticsFlag>[
                    SemanticsFlag.hasEnabledState,
                    SemanticsFlag.isButton,
                    SemanticsFlag.isEnabled,
                    SemanticsFlag.isFocusable,
                  ],
                  label: 'link',
                ),
              ],
            ),
            ignoreId: true,
            ignoreTransform: true));

    semantics.dispose();
  });

  testMongolWidgets('IconButton Semantics (disabled)',
      (MongolWidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      wrap(
        child: const MongolIconButton(
          onPressed: null,
          icon: Icon(Icons.link, semanticLabel: 'link'),
        ),
      ),
    );

    expect(
        semantics,
        hasSemantics(
            TestSemantics.root(
              children: <TestSemantics>[
                TestSemantics.rootChild(
                  rect: const Rect.fromLTRB(0.0, 0.0, 48.0, 48.0),
                  flags: <SemanticsFlag>[
                    SemanticsFlag.hasEnabledState,
                    SemanticsFlag.isButton,
                  ],
                  label: 'link',
                ),
              ],
            ),
            ignoreId: true,
            ignoreTransform: true));

    semantics.dispose();
  });

  testMongolWidgets('IconButton loses focus when disabled.',
      (MongolWidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'IconButton');
    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          focusNode: focusNode,
          autofocus: true,
          onPressed: () {},
          icon: const Icon(Icons.link),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrap(
        child: MongolIconButton(
          focusNode: focusNode,
          autofocus: true,
          onPressed: null,
          icon: const Icon(Icons.link),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testMongolWidgets(
      'IconButton keeps focus when disabled in directional navigation mode.',
      (MongolWidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'IconButton');
    await tester.pumpWidget(
      wrap(
        child: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: MongolIconButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () {},
            icon: const Icon(Icons.link),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrap(
        child: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: MongolIconButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: null,
            icon: const Icon(Icons.link),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);
  });

  testMongolWidgets("Disabled IconButton can't be traversed to when disabled.",
      (MongolWidgetTester tester) async {
    final FocusNode focusNode1 = FocusNode(debugLabel: 'IconButton 1');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'IconButton 2');

    await tester.pumpWidget(
      wrap(
        child: Column(
          children: <Widget>[
            MongolIconButton(
              focusNode: focusNode1,
              autofocus: true,
              onPressed: () {},
              icon: const Icon(Icons.link),
            ),
            MongolIconButton(
              focusNode: focusNode2,
              onPressed: null,
              icon: const Icon(Icons.link),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);

    expect(focusNode1.nextFocus(), isTrue);
    await tester.pump();

    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);
  });

  // group('feedback', () {
  //   late FeedbackTester feedback;

  //   setUp(() {
  //     feedback = FeedbackTester();
  //   });

  //   tearDown(() {
  //     feedback.dispose();
  //   });

  //   testMongolWidgets('IconButton with disabled feedback',
  //       (MongolWidgetTester tester) async {
  //     await tester.pumpWidget(Material(
  //       child: Directionality(
  //         textDirection: TextDirection.ltr,
  //         child: Center(
  //           child: MongolIconButton(
  //             onPressed: () {},
  //             enableFeedback: false,
  //             icon: const Icon(Icons.link),
  //           ),
  //         ),
  //       ),
  //     ));
  //     await tester.tap(find.byType(MongolIconButton), pointer: 1);
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 0);
  //     expect(feedback.hapticCount, 0);
  //   });

  //   testMongolWidgets('IconButton with enabled feedback',
  //       (MongolWidgetTester tester) async {
  //     await tester.pumpWidget(Material(
  //       child: Directionality(
  //         textDirection: TextDirection.ltr,
  //         child: Center(
  //           child: MongolIconButton(
  //             onPressed: () {},
  //             enableFeedback: true,
  //             icon: const Icon(Icons.link),
  //           ),
  //         ),
  //       ),
  //     ));
  //     await tester.tap(find.byType(MongolIconButton), pointer: 1);
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 1);
  //     expect(feedback.hapticCount, 0);
  //   });

  //   testMongolWidgets('IconButton with enabled feedback by default',
  //       (MongolWidgetTester tester) async {
  //     await tester.pumpWidget(Material(
  //       child: Directionality(
  //         textDirection: TextDirection.ltr,
  //         child: Center(
  //           child: MongolIconButton(
  //             onPressed: () {},
  //             icon: const Icon(Icons.link),
  //           ),
  //         ),
  //       ),
  //     ));
  //     await tester.tap(find.byType(MongolIconButton), pointer: 1);
  //     await tester.pump(const Duration(seconds: 1));
  //     expect(feedback.clickSoundCount, 1);
  //     expect(feedback.hapticCount, 0);
  //   });
  // });

  testMongolWidgets('IconButton responds to density changes.',
      (MongolWidgetTester tester) async {
    const Key key = Key('test');
    Future<void> buildTest(VisualDensity visualDensity) async {
      return tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: MongolIconButton(
                visualDensity: visualDensity,
                key: key,
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(VisualDensity.standard);
    final RenderBox box = tester.renderObject(find.byKey(key));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(48, 48)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(60, 60)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(40, 40)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(60, 40)));
  });

  testMongolWidgets('IconButton.mouseCursor changes cursor on hover',
      (MongolWidgetTester tester) async {
    // Test argument works
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: MongolIconButton(
              onPressed: () {},
              mouseCursor: SystemMouseCursors.forbidden,
              icon: const Icon(Icons.play_arrow),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(
        location: tester.getCenter(find.byType(MongolIconButton)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden);

    // Test default is click
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: MongolIconButton(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click);
  });
}

Widget wrap({required Widget child}) {
  return FocusTraversalGroup(
    policy: ReadingOrderTraversalPolicy(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(child: child),
      ),
    ),
  );
}
