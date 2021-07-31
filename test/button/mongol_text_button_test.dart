// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';
import 'package:mongol/src/text/mongol_render_paragraph.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/finders.dart';
import '../widgets/mongol_widget_tester.dart';

void main() {
  testMongolWidgets('MongolTextButton, MongolTextButton.icon defaults',
      (MongolWidgetTester tester) async {
    const ColorScheme colorScheme = ColorScheme.light();

    // Enabled MongolTextButton
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: Center(
          child: MongolTextButton(
            onPressed: () {},
            child: const MongolText('button'),
          ),
        ),
      ),
    );

    final Finder buttonMaterial = find.descendant(
      of: find.byType(MongolTextButton),
      matching: find.byType(Material),
    );

    Material material = tester.widget<Material>(buttonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.primary);
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    final Align align = tester.firstWidget<Align>(find.ancestor(
        of: findMongol.text('button'), matching: find.byType(Align)));
    expect(align.alignment, Alignment.center);

    final Offset center = tester.getCenter(find.byType(MongolTextButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start the splash animation
    await tester.pump(const Duration(milliseconds: 100)); // splash is underway
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere(
        (RenderObject object) =>
            object.runtimeType.toString() == '_RenderInkFeatures');
    expect(
        inkFeatures,
        paints
          ..circle(
              color: colorScheme.primary
                  .withAlpha(0x1f))); // splash color is primary(0.12)

    await gesture.up();
    await tester.pumpAndSettle();
    material = tester.widget<Material>(buttonMaterial);
    // No change vs enabled and not pressed.
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.primary);
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Enabled MongolTextButton.icon
    final Key iconButtonKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: Center(
          child: MongolTextButton.icon(
            key: iconButtonKey,
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const MongolText('label'),
          ),
        ),
      ),
    );

    final Finder iconButtonMaterial = find.descendant(
      of: find.byKey(iconButtonKey),
      matching: find.byType(Material),
    );

    material = tester.widget<Material>(iconButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.primary);
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Disabled MongolTextButton
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme),
        home: const Center(
          child: MongolTextButton(
            onPressed: null,
            child: MongolText('button'),
          ),
        ),
      ),
    );

    material = tester.widget<Material>(buttonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)));
    expect(material.textStyle!.color, colorScheme.onSurface.withOpacity(0.38));
    expect(material.textStyle!.fontFamily, 'Roboto');
    expect(material.textStyle!.fontSize, 14);
    expect(material.textStyle!.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);
  });

  // testWidgets(
  //   'Default MongolTextButton meets a11y contrast guidelines',
  //   (WidgetTester tester) async {
  //     final FocusNode focusNode = FocusNode();

  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData.from(colorScheme: const ColorScheme.light()),
  //         home: Scaffold(
  //           body: Center(
  //             child: MongolTextButton(
  //               onPressed: () {},
  //               focusNode: focusNode,
  //               child: const MongolText('MongolTextButton'),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     // Default, not disabled.
  //     await expectLater(tester, meetsGuideline(textContrastGuideline));

  //     // Focused.
  //     focusNode.requestFocus();
  //     await tester.pumpAndSettle();
  //     await expectLater(tester, meetsGuideline(textContrastGuideline));

  //     // Hovered.
  //     final Offset center = tester.getCenter(find.byType(MongolTextButton));
  //     final TestGesture gesture = await tester.createGesture(
  //       kind: PointerDeviceKind.mouse,
  //     );
  //     await gesture.addPointer();
  //     await gesture.moveTo(center);
  //     await tester.pumpAndSettle();
  //     await expectLater(tester, meetsGuideline(textContrastGuideline));

  //     // Highlighted (pressed).
  //     await gesture.down(center);
  //     await tester.pump(); // Start the splash and highlight animations.
  //     await tester.pump(const Duration(
  //         milliseconds:
  //             800)); // Wait for splash and highlight to be well under way.
  //     await expectLater(tester, meetsGuideline(textContrastGuideline));

  //     await gesture.removePointer();
  //   },
  //   skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
  //   semanticsEnabled: true,
  // );

  // testMongolWidgets('MongolTextButton with colored theme meets a11y contrast guidelines', (MongolWidgetTester tester) async {
  //   final FocusNode focusNode = FocusNode();

  //   Color getTextColor(Set<MaterialState> states) {
  //     final Set<MaterialState> interactiveStates = <MaterialState>{
  //       MaterialState.pressed,
  //       MaterialState.hovered,
  //       MaterialState.focused,
  //     };
  //     if (states.any(interactiveStates.contains)) {
  //       return Colors.blue[900]!;
  //     }
  //     return Colors.blue[800]!;
  //   }

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: TextButtonTheme(
  //             data: TextButtonThemeData(
  //               style: ButtonStyle(
  //                 foregroundColor: MaterialStateProperty.resolveWith<Color>(getTextColor),
  //               ),
  //             ),
  //             child: Builder(
  //               builder: (BuildContext context) {
  //                 return MongolTextButton(
  //                   onPressed: () {},
  //                   focusNode: focusNode,
  //                   child: const MongolText('MongolTextButton'),
  //                 );
  //               },
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   // Default, not disabled.
  //   await expectLater(tester, meetsGuideline(textContrastGuideline));

  //   // Focused.
  //   focusNode.requestFocus();
  //   await tester.pumpAndSettle();
  //   await expectLater(tester, meetsGuideline(textContrastGuideline));

  //   // Hovered.
  //   final Offset center = tester.getCenter(find.byType(MongolTextButton));
  //   final TestGesture gesture = await tester.createGesture(
  //     kind: PointerDeviceKind.mouse,
  //   );
  //   await gesture.addPointer();
  //   addTearDown(gesture.removePointer);
  //   await gesture.moveTo(center);
  //   await tester.pumpAndSettle();
  //   await expectLater(tester, meetsGuideline(textContrastGuideline));

  //   // Highlighted (pressed).
  //   await gesture.down(center);
  //   await tester.pump(); // Start the splash and highlight animations.
  //   await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
  //   await expectLater(tester, meetsGuideline(textContrastGuideline));
  // },
  //   skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
  //   semanticsEnabled: true,
  // );

  testMongolWidgets(
      'MongolTextButton uses stateful color for text color in different states',
      (MongolWidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MongolTextButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.resolveWith<Color>(getTextColor),
              ),
              onPressed: () {},
              focusNode: focusNode,
              child: const MongolText('MongolTextButton'),
            ),
          ),
        ),
      ),
    );

    Color? textColor() {
      return tester
          .renderObject<MongolRenderParagraph>(
              findMongol.text('MongolTextButton'))
          .text
          .style
          ?.color;
    }

    // Default, not disabled.
    expect(textColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(MongolTextButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(textColor(), hoverColor);

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(
        milliseconds:
            800)); // Wait for splash and highlight to be well under way.
    expect(textColor(), pressedColor);
  });

  testMongolWidgets(
      'MongolTextButton uses stateful color for icon color in different states',
      (MongolWidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final Key buttonKey = UniqueKey();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MongolTextButton.icon(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.resolveWith<Color>(getTextColor),
              ),
              key: buttonKey,
              icon: const Icon(Icons.add),
              label: const MongolText('MongolTextButton'),
              onPressed: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    Color? iconColor() => _iconStyle(tester, Icons.add)?.color;
    // Default, not disabled.
    expect(iconColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(iconColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byKey(buttonKey));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(iconColor(), hoverColor);

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(
        milliseconds:
            800)); // Wait for splash and highlight to be well under way.
    expect(iconColor(), pressedColor);
  });

  testMongolWidgets('MongolTextButton has no clip by default',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MongolTextButton(
            child: Container(),
            onPressed: () {/* to make sure the button is enabled */},
          ),
        ),
      ),
    );

    expect(
      tester.renderObject(find.byType(MongolTextButton)),
      paintsExactlyCountTimes(#clipPath, 0),
    );
  });

  testMongolWidgets('Does MongolTextButton work with hover',
      (MongolWidgetTester tester) async {
    const Color hoverColor = Color(0xff001122);

    Color? getOverlayColor(Set<MaterialState> states) {
      return states.contains(MaterialState.hovered) ? hoverColor : null;
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MongolTextButton(
            style: ButtonStyle(
              overlayColor:
                  MaterialStateProperty.resolveWith<Color?>(getOverlayColor),
            ),
            child: Container(),
            onPressed: () {/* to make sure the button is enabled */},
          ),
        ),
      ),
    );

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(MongolTextButton)));
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere(
        (RenderObject object) =>
            object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: hoverColor));
  });

  testMongolWidgets('Does MongolTextButton work with focus',
      (MongolWidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    Color? getOverlayColor(Set<MaterialState> states) {
      return states.contains(MaterialState.focused) ? focusColor : null;
    }

    final FocusNode focusNode = FocusNode(debugLabel: 'MongolTextButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MongolTextButton(
          style: ButtonStyle(
            overlayColor:
                MaterialStateProperty.resolveWith<Color?>(getOverlayColor),
          ),
          focusNode: focusNode,
          onPressed: () {},
          child: const MongolText('button'),
        ),
      ),
    );

    WidgetsBinding.instance!.focusManager.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere(
        (RenderObject object) =>
            object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  // testMongolWidgets('Does MongolTextButton contribute semantics',
  //     (MongolWidgetTester tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   await tester.pumpWidget(
  //     Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: Material(
  //         child: Center(
  //           child: MongolTextButton(
  //             style: ButtonStyle(
  //               // Specifying minimumSize to mimic the original minimumSize for
  //               // RaisedButton so that the semantics tree's rect and transform
  //               // match the original version of this test.
  //               minimumSize:
  //                   MaterialStateProperty.all<Size>(const Size(88, 36)),
  //             ),
  //             onPressed: () {},
  //             child: const MongolText('ABC'),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics.rootChild(
  //               actions: <SemanticsAction>[
  //                 SemanticsAction.tap,
  //               ],
  //               label: 'ABC',
  //               rect: const Rect.fromLTRB(0.0, 0.0, 88.0, 48.0),
  //               transform: Matrix4.translationValues(356.0, 276.0, 0.0),
  //               flags: <SemanticsFlag>[
  //                 SemanticsFlag.hasEnabledState,
  //                 SemanticsFlag.isButton,
  //                 SemanticsFlag.isEnabled,
  //                 SemanticsFlag.isFocusable,
  //               ],
  //             ),
  //           ],
  //         ),
  //         ignoreId: true,
  //       ));

  //   semantics.dispose();
  // });

  testMongolWidgets('Does MongolTextButton scale with font scale changes',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.0),
            child: Center(
              child: MongolTextButton(
                onPressed: () {},
                child: const MongolText('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(MongolTextButton)),
        equals(const Size(48.0, 64.0)));
    expect(tester.getSize(find.byType(MongolText)),
        equals(const Size(14.0, 42.0)));

    // textScaleFactor expands text, but not button.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.3),
            child: Center(
              child: MongolTextButton(
                onPressed: () {},
                child: const MongolText('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    // Scaled text rendering is different on Linux and Mac by one pixel.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.byType(MongolTextButton)).width,
        isIn(<double>[47.0, 48.0]));
    expect(tester.getSize(find.byType(MongolTextButton)).height,
        isIn(<double>[70.0, 71.0]));
    expect(tester.getSize(find.byType(MongolText)).width,
        isIn(<double>[18.0, 19.0]));
    expect(tester.getSize(find.byType(MongolText)).height,
        isIn(<double>[54.0, 55.0]));

    // Set text scale large enough to expand text and button.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 3.0),
            child: Center(
              child: MongolTextButton(
                onPressed: () {},
                child: const MongolText('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    // Scaled text rendering is different on Linux and Mac by one pixel.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.byType(MongolTextButton)).height,
        isIn(<double>[133.0, 134.0]));
    expect(tester.getSize(find.byType(MongolTextButton)).width, equals(48.0));
    expect(tester.getSize(find.byType(MongolText)).height,
        isIn(<double>[126.0, 127.0]));
    expect(tester.getSize(find.byType(MongolText)).width, equals(42.0));
  });

  testMongolWidgets(
      'MongolTextButton size is configurable by ThemeData.materialTapTargetSize',
      (MongolWidgetTester tester) async {
    Widget buildFrame(MaterialTapTargetSize tapTargetSize, Key key) {
      return Theme(
        data: ThemeData(materialTapTargetSize: tapTargetSize),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MongolTextButton(
                key: key,
                child: const SizedBox(height: 50.0, width: 8.0),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
    }

    final Key key1 = UniqueKey();
    await tester.pumpWidget(buildFrame(MaterialTapTargetSize.padded, key1));
    expect(tester.getSize(find.byKey(key1)), const Size(48.0, 66.0));

    final Key key2 = UniqueKey();
    await tester.pumpWidget(buildFrame(MaterialTapTargetSize.shrinkWrap, key2));
    expect(tester.getSize(find.byKey(key2)), const Size(36.0, 66.0));
  });

  testMongolWidgets(
      'MongolTextButton onPressed and onLongPress callbacks are correctly called when non-null',
      (MongolWidgetTester tester) async {
    bool wasPressed;
    Finder textButton;

    Widget buildFrame({VoidCallback? onPressed, VoidCallback? onLongPress}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MongolTextButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          child: const MongolText('button'),
        ),
      );
    }

    // onPressed not null, onLongPress null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(
          onPressed: () {
            wasPressed = true;
          },
          onLongPress: null),
    );
    textButton = find.byType(MongolTextButton);
    expect(tester.widget<MongolTextButton>(textButton).enabled, true);
    await tester.tap(textButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress not null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(
          onPressed: null,
          onLongPress: () {
            wasPressed = true;
          }),
    );
    textButton = find.byType(MongolTextButton);
    expect(tester.widget<MongolTextButton>(textButton).enabled, true);
    await tester.longPress(textButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress null.
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: null),
    );
    textButton = find.byType(MongolTextButton);
    expect(tester.widget<MongolTextButton>(textButton).enabled, false);
  });

  testMongolWidgets(
      'MongolTextButton onPressed and onLongPress callbacks are distinctly recognized',
      (MongolWidgetTester tester) async {
    bool didPressButton = false;
    bool didLongPressButton = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MongolTextButton(
          onPressed: () {
            didPressButton = true;
          },
          onLongPress: () {
            didLongPressButton = true;
          },
          child: const MongolText('button'),
        ),
      ),
    );

    final Finder textButton = find.byType(MongolTextButton);
    expect(tester.widget<MongolTextButton>(textButton).enabled, true);

    expect(didPressButton, isFalse);
    await tester.tap(textButton);
    expect(didPressButton, isTrue);

    expect(didLongPressButton, isFalse);
    await tester.longPress(textButton);
    expect(didLongPressButton, isTrue);
  });

  // testMongolWidgets('MongolTextButton responds to density changes.',
  //     (MongolWidgetTester tester) async {
  //   const Key key = Key('test');
  //   const Key childKey = Key('test child');

  //   Future<void> buildTest(VisualDensity visualDensity,
  //       {bool useText = false}) async {
  //     return tester.pumpWidget(
  //       MaterialApp(
  //         home: Directionality(
  //           textDirection: TextDirection.rtl,
  //           child: Center(
  //             child: MongolTextButton(
  //               style: ButtonStyle(
  //                 visualDensity: visualDensity,
  //               ),
  //               key: key,
  //               onPressed: () {},
  //               child: useText
  //                   ? const MongolText('Text', key: childKey)
  //                   : Container(
  //                       key: childKey,
  //                       width: 100,
  //                       height: 100,
  //                       color: const Color(0xffff0000)),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   await buildTest(VisualDensity.standard);
  //   final RenderBox box = tester.renderObject(find.byKey(key));
  //   Rect childRect = tester.getRect(find.byKey(childKey));
  //   await tester.pumpAndSettle();
  //   expect(box.size, equals(const Size(116, 116)));
  //   expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

  //   await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
  //   await tester.pumpAndSettle();
  //   childRect = tester.getRect(find.byKey(childKey));
  //   expect(box.size, equals(const Size(140, 140)));
  //   expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

  //   // await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
  //   // await tester.pumpAndSettle();
  //   // childRect = tester.getRect(find.byKey(childKey));
  //   // expect(box.size, equals(const Size(116, 100)));
  //   // expect(childRect, equals(const Rect.fromLTRB(350, 250, 450, 350)));

  //   await buildTest(VisualDensity.standard, useText: true);
  //   await tester.pumpAndSettle();
  //   childRect = tester.getRect(find.byKey(childKey));
  //   expect(box.size, equals(const Size(48.0, 72.0)));
  //   //expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));

  //   await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0),
  //       useText: true);
  //   await tester.pumpAndSettle();
  //   childRect = tester.getRect(find.byKey(childKey));
  //   expect(box.size, equals(const Size(96, 60)));
  //   expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));

  //   await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0),
  //       useText: true);
  //   await tester.pumpAndSettle();
  //   childRect = tester.getRect(find.byKey(childKey));
  //   expect(box.size, equals(const Size(72, 36)));
  //   expect(childRect, equals(const Rect.fromLTRB(372.0, 293.0, 428.0, 307.0)));
  // });

  group('Default MongolTextButton padding for textScaleFactor, textDirection',
      () {
    const ValueKey<String> buttonKey = ValueKey<String>('button');
    const ValueKey<String> labelKey = ValueKey<String>('label');
    const ValueKey<String> iconKey = ValueKey<String>('icon');

    const List<double> textScaleFactorOptions = <double>[
      0.5,
      1.0,
      1.25,
      1.5,
      2.0,
      2.5,
      3.0,
      4.0
    ];
    const List<Widget?> iconOptions = <Widget?>[
      null,
      Icon(Icons.add, size: 18, key: iconKey)
    ];

    // Expected values for each textScaleFactor.
    final Map<double, double> paddingHorizontal = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 6,
      1.5: 4,
      2: 0,
      2.5: 0,
      3: 0,
      4: 0,
    };
    final Map<double, double> paddingWithIconGap = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 7,
      1.5: 6,
      2: 4,
      2.5: 4,
      3: 4,
      4: 4,
    };
    final Map<double, double> textPaddingWithoutIconVertical = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 8,
      1.5: 8,
      2: 8,
      2.5: 6,
      3: 4,
      4: 4,
    };
    final Map<double, double> textPaddingWithIconVertical = <double, double>{
      0.5: 8,
      1: 8,
      1.25: 7,
      1.5: 6,
      2: 4,
      2.5: 4,
      3: 4,
      4: 4,
    };

    Rect globalBounds(RenderBox renderBox) {
      final Offset topLeft = renderBox.localToGlobal(Offset.zero);
      return topLeft & renderBox.size;
    }

    /// Computes the padding between two [Rect]s, one inside the other.
    EdgeInsets paddingBetween({required Rect parent, required Rect child}) {
      assert(parent.intersect(child) == child);
      return EdgeInsets.fromLTRB(
        child.left - parent.left,
        child.top - parent.top,
        parent.right - child.right,
        parent.bottom - child.bottom,
      );
    }

    for (final double textScaleFactor in textScaleFactorOptions) {
      for (final Widget? icon in iconOptions) {
        final String testName = <String>[
          'MongolTextButton, text scale $textScaleFactor',
          if (icon != null) 'with icon',
        ].join(', ');

        testMongolWidgets(testName, (MongolWidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.from(colorScheme: const ColorScheme.light()),
              home: Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaleFactor: textScaleFactor,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Scaffold(
                        body: Center(
                          child: icon == null
                              ? MongolTextButton(
                                  key: buttonKey,
                                  onPressed: () {},
                                  child:
                                      const MongolText('button', key: labelKey),
                                )
                              : MongolTextButton.icon(
                                  key: buttonKey,
                                  onPressed: () {},
                                  icon: icon,
                                  label:
                                      const MongolText('button', key: labelKey),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          final Element paddingElement = tester.element(
            find.descendant(
              of: find.byKey(buttonKey),
              matching: find.byType(Padding),
            ),
          );
          final Padding paddingWidget = paddingElement.widget as Padding;

          // Compute expected padding, and check.

          final double expectedPaddingLeft =
              paddingHorizontal[textScaleFactor]!;
          final double expectedPaddingRight =
              paddingHorizontal[textScaleFactor]!;

          final double expectedPaddingTop = icon != null
              ? textPaddingWithIconVertical[textScaleFactor]!
              : textPaddingWithoutIconVertical[textScaleFactor]!;
          final double expectedPaddingBottom = expectedPaddingTop;

          final EdgeInsets expectedPadding = EdgeInsets.fromLTRB(
            expectedPaddingLeft,
            expectedPaddingTop,
            expectedPaddingRight,
            expectedPaddingBottom,
          );

          expect(paddingWidget.padding, expectedPadding);

          // Measure padding in terms of the difference between the button and its label child
          // and check that.

          final RenderBox labelRenderBox =
              tester.renderObject<RenderBox>(find.byKey(labelKey));
          final Rect labelBounds = globalBounds(labelRenderBox);
          final RenderBox? iconRenderBox = icon == null
              ? null
              : tester.renderObject<RenderBox>(find.byKey(iconKey));
          final Rect? iconBounds =
              icon == null ? null : globalBounds(iconRenderBox!);
          final Rect childBounds = icon == null
              ? labelBounds
              : labelBounds.expandToInclude(iconBounds!);

          // We measure the `InkResponse` descendant of the button
          // element, because the button has a larger `RenderBox`
          // which accommodates the minimum tap target with a width
          // of 48.
          final RenderBox buttonRenderBox = tester.renderObject<RenderBox>(
            find.descendant(
              of: find.byKey(buttonKey),
              matching: find.byWidgetPredicate(
                (Widget widget) => widget is InkResponse,
              ),
            ),
          );
          final Rect buttonBounds = globalBounds(buttonRenderBox);
          final EdgeInsets visuallyMeasuredPadding = paddingBetween(
            parent: buttonBounds,
            child: childBounds,
          );

          // Since there is a requirement of a minimum height of 64
          // and a minimum width of 36 on material buttons, the visual
          // padding of smaller buttons may not match their settings.
          // Therefore, we only test buttons that are large enough.
          if (buttonBounds.height > 64) {
            expect(
              visuallyMeasuredPadding.top,
              expectedPadding.top,
            );
            expect(
              visuallyMeasuredPadding.bottom,
              expectedPadding.bottom,
            );
          }

          if (buttonBounds.width > 36) {
            expect(
              visuallyMeasuredPadding.left,
              expectedPadding.left,
            );
            expect(
              visuallyMeasuredPadding.right,
              expectedPadding.right,
            );
          }

          // Check the gap between the icon and the label
          if (icon != null) {
            final double gapWidth = labelBounds.top - iconBounds!.bottom;
            expect(gapWidth, paddingWithIconGap[textScaleFactor]);
          }

          // Check the text's width - should be consistent with the textScaleFactor.
          final RenderBox textRenderObject = tester.renderObject<RenderBox>(
            find.descendant(
              of: find.byKey(labelKey),
              matching: find.byElementPredicate(
                (Element element) => element.widget is MongolRichText,
              ),
            ),
          );
          final double textWidth = textRenderObject.paintBounds.size.width;
          final double expectedTextWidth = 14 * textScaleFactor;
          expect(textWidth, moreOrLessEquals(expectedTextWidth, epsilon: 0.5));
        });
      }
    }
  });

  testMongolWidgets('Override MongolTextButton default padding',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light()),
        home: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: 2,
              ),
              child: Scaffold(
                body: Center(
                  child: MongolTextButton(
                    style: MongolTextButton.styleFrom(
                        padding: const EdgeInsets.all(22)),
                    onPressed: () {},
                    child: const MongolText('MongolTextButton'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final Padding paddingWidget = tester.widget<Padding>(
      find.descendant(
        of: find.byType(MongolTextButton),
        matching: find.byType(Padding),
      ),
    );
    expect(paddingWidget.padding, const EdgeInsets.all(22));
  });

  testMongolWidgets('Fixed size MongolTextButtons',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MongolTextButton(
                style:
                    MongolTextButton.styleFrom(fixedSize: const Size(100, 100)),
                onPressed: () {},
                child: const MongolText('100x100'),
              ),
              MongolTextButton(
                style: MongolTextButton.styleFrom(
                    fixedSize: const Size.fromHeight(200)),
                onPressed: () {},
                child: const MongolText('wx200'),
              ),
              MongolTextButton(
                style: MongolTextButton.styleFrom(
                    fixedSize: const Size.fromWidth(200)),
                onPressed: () {},
                child: const MongolText('200xh'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
        tester.getSize(findMongol.widgetWithText(MongolTextButton, '100x100')),
        const Size(100, 100));
    expect(
        tester
            .getSize(findMongol.widgetWithText(MongolTextButton, 'wx200'))
            .height,
        200);
    expect(
        tester
            .getSize(findMongol.widgetWithText(MongolTextButton, '200xh'))
            .width,
        200);
  });

  testMongolWidgets(
      'MongolTextButton with NoSplash splashFactory paints nothing',
      (MongolWidgetTester tester) async {
    Widget buildFrame({InteractiveInkFeatureFactory? splashFactory}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: MongolTextButton(
              style: MongolTextButton.styleFrom(
                splashFactory: splashFactory,
              ),
              onPressed: () {},
              child: const MongolText('test'),
            ),
          ),
        ),
      );
    }

    // NoSplash.splashFactory, no splash circles drawn
    await tester.pumpWidget(buildFrame(splashFactory: NoSplash.splashFactory));
    {
      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(findMongol.text('test')));
      final MaterialInkController material =
          Material.of(tester.element(findMongol.text('test')))!;
      await tester.pump(const Duration(milliseconds: 200));
      expect(material, paintsExactlyCountTimes(#drawCircle, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    // Default splashFactory (from Theme.of().splashFactory), one splash circle drawn.
    await tester.pumpWidget(buildFrame());
    {
      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(findMongol.text('test')));
      final MaterialInkController material =
          Material.of(tester.element(findMongol.text('test')))!;
      await tester.pump(const Duration(milliseconds: 200));
      expect(material, paintsExactlyCountTimes(#drawCircle, 1));
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testMongolWidgets('MongolTextButton.icon does not overflow',
      (MongolWidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/77815
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: MongolTextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const MongolText(
                // Much taller than 200
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut a euismod nibh. Morbi laoreet purus.',
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), null);
  });

  // testMongolWidgets('MongolTextButton.icon icon,label layout',
  //     (MongolWidgetTester tester) async {
  //   final Key buttonKey = UniqueKey();
  //   final Key iconKey = UniqueKey();
  //   final Key labelKey = UniqueKey();
  //   final ButtonStyle style = MongolTextButton.styleFrom(
  //     padding: EdgeInsets.zero,
  //     visualDensity: VisualDensity.standard, // dx=0, dy=0
  //   );

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: SizedBox(
  //           width: 200,
  //           child: MongolTextButton.icon(
  //             key: buttonKey,
  //             style: style,
  //             onPressed: () {},
  //             icon: SizedBox(key: iconKey, width: 100, height: 50),
  //             label: SizedBox(key: labelKey, width: 100, height: 50),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(tester.getRect(find.byKey(buttonKey)),
  //       const Rect.fromLTRB(0.0, 0.0, 200.0, 100.0));
  //   expect(tester.getRect(find.byKey(iconKey)),
  //       const Rect.fromLTRB(46.0, 0.0, 96.0, 100.0));
  //   expect(tester.getRect(find.byKey(labelKey)),
  //       const Rect.fromLTRB(104.0, 0.0, 154.0, 100.0));
  // });

  // testMongolWidgets('MongolTextButton maximumSize', (MongolWidgetTester tester) async {
  //   final Key key0 = UniqueKey();
  //   final Key key1 = UniqueKey();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: <Widget>[
  //               MongolTextButton(
  //                 key: key0,
  //                 style: MongolTextButton.styleFrom(
  //                   minimumSize: const Size(24, 36),
  //                   maximumSize: const Size.fromWidth(64),
  //                 ),
  //                 onPressed: () { },
  //                 child: const MongolText('A B C D E F G H I J K L M N O P'),
  //               ),
  //               MongolTextButton.icon(
  //                 key: key1,
  //                 style: MongolTextButton.styleFrom(
  //                   minimumSize: const Size(24, 36),
  //                   maximumSize: const Size.fromWidth(104),
  //                 ),
  //                 onPressed: () {},
  //                 icon: Container(color: Colors.red, width: 32, height: 32),
  //                 label: const MongolText('A B C D E F G H I J K L M N O P'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(tester.getSize(find.byKey(key0)), const Size(64.0, 128.0));
  //   expect(tester.getSize(find.byKey(key1)), const Size(104.0, 128.0));
  // });

  // testMongolWidgets('Fixed size MongolTextButton, same as minimumSize == maximumSize', (MongolWidgetTester tester) async {
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: <Widget>[
  //             MongolTextButton(
  //               style: MongolTextButton.styleFrom(fixedSize: const Size(200, 200)),
  //               onPressed: () { },
  //               child: const MongolText('200x200'),
  //             ),
  //             MongolTextButton(
  //               style: MongolTextButton.styleFrom(
  //                 minimumSize: const Size(200, 200),
  //                 maximumSize: const Size(200, 200),
  //               ),
  //               onPressed: () { },
  //               child: const MongolText('200,200'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(tester.getSize(find.widgetWithText(MongolTextButton, '200x200')), const Size(200, 200));
  //   expect(tester.getSize(find.widgetWithText(MongolTextButton, '200,200')), const Size(200, 200));
  // });
}

TextStyle? _iconStyle(MongolWidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}
