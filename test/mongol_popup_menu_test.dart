// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide PopupMenuButton, showMenu;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

import 'widgets/finders.dart';
import 'widgets/mongol_widget_tester.dart';

void main() {
  testMongolWidgets('Navigator.push works within a MongolPopupMenuButton',
      (MongolWidgetTester tester) async {
    final Key targetKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return const MongolText('Next');
          },
        },
        home: Material(
          child: Center(
            child: Builder(
              key: targetKey,
              builder: (BuildContext context) {
                return MongolPopupMenuButton<int>(
                  onSelected: (int value) {
                    Navigator.pushNamed(context, '/next');
                  },
                  itemBuilder: (BuildContext context) {
                    return <MongolPopupMenuItem<int>>[
                      const MongolPopupMenuItem<int>(
                        value: 1,
                        child: MongolText('One'),
                      ),
                    ];
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(targetKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(findMongol.text('One'), findsOneWidget);
    expect(findMongol.text('Next'), findsNothing);

    await tester.tap(findMongol.text('One'));
    await tester.pump(); // return the future
    await tester.pump(); // start the navigation
    await tester.pump(const Duration(seconds: 1)); // end the navigation

    expect(findMongol.text('One'), findsNothing);
    expect(findMongol.text('Next'), findsOneWidget);
  });

  testMongolWidgets(
      'MongolPopupMenuButton calls onCanceled callback when an item is not selected',
      (MongolWidgetTester tester) async {
    int cancels = 0;
    late BuildContext popupContext;
    final Key noCallbackKey = UniqueKey();
    final Key withCallbackKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              MongolPopupMenuButton<int>(
                key: noCallbackKey,
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
              ),
              MongolPopupMenuButton<int>(
                key: withCallbackKey,
                onCanceled: () => cancels++,
                itemBuilder: (BuildContext context) {
                  popupContext = context;
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me, too!'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Make sure everything works if no callback is provided
    await tester.tap(find.byKey(noCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(Offset.zero);
    await tester.pump();
    expect(cancels, equals(0));

    // Make sure callback is called when a non-selection tap occurs
    await tester.tap(find.byKey(withCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(Offset.zero);
    await tester.pump();
    expect(cancels, equals(1));

    // Make sure callback is called when back navigation occurs
    await tester.tap(find.byKey(withCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    Navigator.of(popupContext).pop();
    await tester.pump();
    expect(cancels, equals(2));
  });

  testMongolWidgets(
      'disabled MongolPopupMenuButton will not call itemBuilder, onSelected or onCanceled',
      (MongolWidgetTester tester) async {
    final GlobalKey popupButtonKey = GlobalKey();
    bool itemBuilderCalled = false;
    bool onSelectedCalled = false;
    bool onCanceledCalled = false;

    Widget buildApp({bool directional = false}) {
      return MaterialApp(
        home: Builder(builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              navigationMode: NavigationMode.directional,
            ),
            child: Material(
              child: Column(
                children: <Widget>[
                  MongolPopupMenuButton<int>(
                    enabled: false,
                    child: MongolText('Tap Me', key: popupButtonKey),
                    itemBuilder: (BuildContext context) {
                      itemBuilderCalled = true;
                      return <MongolPopupMenuEntry<int>>[
                        const MongolPopupMenuItem<int>(
                          value: 1,
                          child: MongolText('Tap me please!'),
                        ),
                      ];
                    },
                    onSelected: (int selected) => onSelectedCalled = true,
                    onCanceled: () => onCanceledCalled = true,
                  ),
                ],
              ),
            ),
          );
        }),
      );
    }

    await tester.pumpWidget(buildApp());

    // Try to bring up the popup menu and select the first item from it
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onSelectedCalled, isFalse);

    // Try to bring up the popup menu and tap outside it to cancel the menu
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onCanceledCalled, isFalse);

    // Test again, with directional navigation mode and after focusing the button.
    await tester.pumpWidget(buildApp(directional: true));

    // Try to bring up the popup menu and select the first item from it
    Focus.of(popupButtonKey.currentContext!).requestFocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onSelectedCalled, isFalse);

    // Try to bring up the popup menu and tap outside it to cancel the menu
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onCanceledCalled, isFalse);
  });

  testMongolWidgets('disabled MongolPopupMenuButton is not focusable',
      (MongolWidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final GlobalKey childKey = GlobalKey();
    bool itemBuilderCalled = false;
    bool onSelectedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              MongolPopupMenuButton<int>(
                key: popupButtonKey,
                enabled: false,
                child: Container(key: childKey),
                itemBuilder: (BuildContext context) {
                  itemBuilderCalled = true;
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
                onSelected: (int selected) => onSelectedCalled = true,
              ),
            ],
          ),
        ),
      ),
    );
    Focus.of(childKey.currentContext!).requestFocus();
    await tester.pump();

    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
    expect(itemBuilderCalled, isFalse);
    expect(onSelectedCalled, isFalse);
  });

  testMongolWidgets(
      'disabled MongolPopupMenuButton is focusable with directional navigation',
      (MongolWidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              navigationMode: NavigationMode.directional,
            ),
            child: Material(
              child: Column(
                children: <Widget>[
                  MongolPopupMenuButton<int>(
                    key: popupButtonKey,
                    enabled: false,
                    child: Container(key: childKey),
                    itemBuilder: (BuildContext context) {
                      return <MongolPopupMenuEntry<int>>[
                        const MongolPopupMenuItem<int>(
                          value: 1,
                          child: MongolText('Tap me please!'),
                        ),
                      ];
                    },
                    onSelected: (int selected) {},
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
    Focus.of(childKey.currentContext!).requestFocus();
    await tester.pump();

    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);
  });

  testMongolWidgets('MongolPopupMenuItem onTap callback is called when defined',
      (MongolWidgetTester tester) async {
    final List<int> menuItemTapCounters = <int>[0, 0];

    await tester.pumpWidget(
      TestApp(
        child: Material(
          child: RepaintBoundary(
            child: MongolPopupMenuButton<void>(
              child: const MongolText('Actions'),
              itemBuilder: (BuildContext context) =>
                  <MongolPopupMenuItem<void>>[
                MongolPopupMenuItem<void>(
                  child: const MongolText('First option'),
                  onTap: () {
                    menuItemTapCounters[0] += 1;
                  },
                ),
                MongolPopupMenuItem<void>(
                  child: const MongolText('Second option'),
                  onTap: () {
                    menuItemTapCounters[1] += 1;
                  },
                ),
                const MongolPopupMenuItem<void>(
                  child: MongolText('Option without onTap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap the first time
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[1, 0]);

    // Tap the item again
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 0]);

    // Tap a different item
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('Second option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);

    // Tap an item without onTap
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('Option without onTap'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);
  });

  testMongolWidgets('MongolPopupMenuItem can have both onTap and value',
      (MongolWidgetTester tester) async {
    final List<int> menuItemTapCounters = <int>[0, 0];
    String? selected;

    await tester.pumpWidget(
      TestApp(
        child: Material(
          child: RepaintBoundary(
            child: MongolPopupMenuButton<String>(
              child: const MongolText('Actions'),
              onSelected: (String value) {
                selected = value;
              },
              itemBuilder: (BuildContext context) =>
                  <MongolPopupMenuItem<String>>[
                MongolPopupMenuItem<String>(
                  value: 'first',
                  child: const MongolText('First option'),
                  onTap: () {
                    menuItemTapCounters[0] += 1;
                  },
                ),
                MongolPopupMenuItem<String>(
                  value: 'second',
                  child: const MongolText('Second option'),
                  onTap: () {
                    menuItemTapCounters[1] += 1;
                  },
                ),
                const MongolPopupMenuItem<String>(
                  value: 'third',
                  child: MongolText('Option without onTap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap the first item
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[1, 0]);
    expect(selected, 'first');

    // Tap the item again
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 0]);
    expect(selected, 'first');

    // Tap a different item
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('Second option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);
    expect(selected, 'second');

    // Tap an item without onTap
    await tester.tap(findMongol.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(findMongol.text('Option without onTap'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);
    expect(selected, 'third');
  });

  testMongolWidgets('MongolPopupMenuItem is only focusable when enabled',
      (MongolWidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final GlobalKey childKey = GlobalKey();
    bool itemBuilderCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              MongolPopupMenuButton<int>(
                key: popupButtonKey,
                itemBuilder: (BuildContext context) {
                  itemBuilderCalled = true;
                  return <MongolPopupMenuEntry<int>>[
                    MongolPopupMenuItem<int>(
                      enabled: true,
                      value: 1,
                      child: MongolText('Tap me please!', key: childKey),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Open the popup to build and show the menu contents.
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    final FocusNode childNode = Focus.of(childKey.currentContext!);
    // Now that the contents are shown, request focus on the child text.
    childNode.requestFocus();
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isTrue);

    // Make sure that the focus went where we expected it to.
    expect(childNode.hasPrimaryFocus, isTrue);
    itemBuilderCalled = false;

    // Close the popup.
    await tester.tap(find.byKey(popupButtonKey), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              MongolPopupMenuButton<int>(
                key: popupButtonKey,
                itemBuilder: (BuildContext context) {
                  itemBuilderCalled = true;
                  return <MongolPopupMenuEntry<int>>[
                    MongolPopupMenuItem<int>(
                      enabled: false,
                      value: 1,
                      child: MongolText('Tap me please!', key: childKey),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Open the popup again to rebuild the contents with enabled == false.
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    expect(itemBuilderCalled, isTrue);
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

  testMongolWidgets('MongolPopupMenuButton is horizontal on iOS',
      (MongolWidgetTester tester) async {
    Widget build(TargetPlatform platform) {
      debugDefaultTargetPlatformOverride = platform;
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              MongolPopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuItem<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('One'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(TargetPlatform.android));

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);

    await tester.pumpWidget(build(TargetPlatform.iOS));
    await tester.pumpAndSettle(); // Run theme change animation.

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    await tester.pumpWidget(build(TargetPlatform.macOS));
    await tester.pumpAndSettle(); // Run theme change animation.

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });

  group('MongolPopupMenuButton with Icon', () {
    // Helper function to create simple and valid popup menus.
    List<MongolPopupMenuItem<int>> simplePopupMenuItemBuilder(
        BuildContext context) {
      return <MongolPopupMenuItem<int>>[
        const MongolPopupMenuItem<int>(
          value: 1,
          child: MongolText('1'),
        ),
      ];
    }

    testMongolWidgets(
        'MongolPopupMenuButton fails when given both child and icon',
        (MongolWidgetTester tester) async {
      expect(() {
        MongolPopupMenuButton<int>(
          child: const MongolText('heyo'),
          icon: const Icon(Icons.view_carousel),
          itemBuilder: simplePopupMenuItemBuilder,
        );
      }, throwsAssertionError);
    });

    testMongolWidgets(
        'MongolPopupMenuButton creates IconButton when given an icon',
        (MongolWidgetTester tester) async {
      final MongolPopupMenuButton<int> button = MongolPopupMenuButton<int>(
        icon: const Icon(Icons.view_carousel),
        itemBuilder: simplePopupMenuItemBuilder,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: <Widget>[button],
            ),
          ),
        ),
      );

      expect(find.byType(MongolIconButton), findsOneWidget);
      expect(find.byIcon(Icons.view_carousel), findsOneWidget);
    });
  });

  // testMongolWidgets('PopupMenu positioning', (MongolWidgetTester tester) async {
  //   final Widget testButton = MongolPopupMenuButton<int>(
  //     itemBuilder: (BuildContext context) {
  //       return <MongolPopupMenuItem<int>>[
  //         const MongolPopupMenuItem<int>(value: 1, child: MongolText('AAA')),
  //         const MongolPopupMenuItem<int>(value: 2, child: MongolText('BBB')),
  //         const MongolPopupMenuItem<int>(value: 3, child: MongolText('CCC')),
  //       ];
  //     },
  //     child: const SizedBox(
  //       height: 100.0,
  //       width: 100.0,
  //       child: MongolText('XXX'),
  //     ),
  //   );
  //   bool popupMenu(Widget widget) {
  //     final String widgetType = widget.runtimeType.toString();
  //     // TODO(mraleph): Remove the old case below.
  //     return widgetType == '_PopupMenu<int?>' // normal case
  //         ||
  //         widgetType ==
  //             '_PopupMenu'; // for old versions of Dart that don't reify method type arguments
  //   }

  //   Future<void> openMenu(Alignment alignment) async {
  //     return TestAsyncUtils.guard<void>(() async {
  //       await tester
  //           .pumpWidget(Container()); // reset in case we had a menu up already
  //       await tester.pumpWidget(TestApp(
  //         child: Align(
  //           alignment: alignment,
  //           child: testButton,
  //         ),
  //       ));
  //       await tester.tap(findMongol.text('XXX'));
  //       await tester.pump();
  //     });
  //   }

  //   Future<void> testPositioningDown(
  //     MongolWidgetTester tester,
  //     Alignment alignment,
  //     Rect startRect,
  //   ) {
  //     return TestAsyncUtils.guard<void>(() async {
  //       await openMenu(alignment);
  //       Rect rect = tester.getRect(find.byWidgetPredicate(popupMenu));
  //       expect(rect, startRect);
  //       bool doneVertically = false;
  //       bool doneHorizontally = false;
  //       do {
  //         await tester.pump(const Duration(milliseconds: 20));
  //         final Rect newRect =
  //             tester.getRect(find.byWidgetPredicate(popupMenu));
  //         expect(newRect.left, rect.left);
  //         if (doneHorizontally) {
  //           expect(newRect.right, rect.right);
  //         } else {
  //           if (newRect.right == rect.right) {
  //             doneHorizontally = true;
  //           } else {
  //             expect(newRect.right, greaterThan(rect.right));
  //           }
  //         }

  //         expect(newRect.top, rect.top);
  //         if (doneVertically) {
  //           expect(newRect.bottom, rect.bottom);
  //         } else {
  //           if (newRect.bottom == rect.bottom) {
  //             doneVertically = true;
  //           } else {
  //             expect(newRect.bottom, greaterThan(rect.bottom));
  //           }
  //         }

  //         rect = newRect;
  //       } while (tester.binding.hasScheduledFrame);
  //     });
  //   }

  //   Future<void> testPositioningDownThenUp(
  //     MongolWidgetTester tester,
  //     Alignment alignment,
  //     Rect startRect,
  //   ) {
  //     return TestAsyncUtils.guard<void>(() async {
  //       await openMenu(alignment);
  //       Rect rect = tester.getRect(find.byWidgetPredicate(popupMenu));
  //       expect(rect, startRect);
  //       int horizontalStage = 0; // 0=down, 1=up, 2=done
  //       bool doneVertically = false;
  //       do {
  //         await tester.pump(const Duration(milliseconds: 20));
  //         final Rect newRect =
  //             tester.getRect(find.byWidgetPredicate(popupMenu));
  //         switch (horizontalStage) {
  //           case 0:
  //             if (newRect.left < rect.left) {
  //               horizontalStage = 1;
  //               expect(newRect.right, greaterThanOrEqualTo(rect.right));
  //               break;
  //             }
  //             expect(newRect.left, rect.left);
  //             expect(newRect.right, greaterThan(rect.right));
  //             break;
  //           case 1:
  //             if (newRect.left == rect.left) {
  //               horizontalStage = 2;
  //               expect(newRect.right, rect.right);
  //               break;
  //             }
  //             expect(newRect.left, lessThan(rect.left));
  //             expect(newRect.right, rect.right);
  //             break;
  //           case 2:
  //             expect(newRect.right, rect.right);
  //             expect(newRect.left, rect.left);
  //             break;
  //           default:
  //             assert(false);
  //         }

  //         expect(newRect.left, rect.left);
  //         if (doneVertically) {
  //           expect(newRect.bottom, rect.bottom);
  //         } else {
  //           if (newRect.bottom == rect.bottom) {
  //             doneVertically = true;
  //           } else {
  //             expect(newRect.bottom, greaterThan(rect.bottom));
  //           }
  //         }
  //         rect = newRect;
  //       } while (tester.binding.hasScheduledFrame);
  //     });
  //   }

  //   await testPositioningDown(
  //       tester, Alignment.topRight, const Rect.fromLTWH(792.0, 8.0, 0.0, 0.0));
  //   await testPositioningDown(
  //       tester, Alignment.topRight, const Rect.fromLTWH(792.0, 8.0, 0.0, 0.0));
  //   await testPositioningDown(
  //       tester, Alignment.topLeft, const Rect.fromLTWH(8.0, 8.0, 0.0, 0.0));
  //   await testPositioningDown(
  //       tester, Alignment.topLeft, const Rect.fromLTWH(8.0, 8.0, 0.0, 0.0));
  //   await testPositioningDown(
  //       tester, Alignment.topCenter, const Rect.fromLTWH(350.0, 8.0, 0.0, 0.0));
  //   await testPositioningDown(
  //       tester, Alignment.topCenter, const Rect.fromLTWH(450.0, 8.0, 0.0, 0.0));
  //   await testPositioningDown(tester, Alignment.centerRight,
  //       const Rect.fromLTWH(792.0, 250.0, 0.0, 0.0));
  //   await testPositioningDown(tester, Alignment.centerRight,
  //       const Rect.fromLTWH(792.0, 250.0, 0.0, 0.0));
  //   await testPositioningDown(tester, Alignment.centerLeft,
  //       const Rect.fromLTWH(8.0, 250.0, 0.0, 0.0));
  //   await testPositioningDown(tester, Alignment.centerLeft,
  //       const Rect.fromLTWH(8.0, 250.0, 0.0, 0.0));
  //   await testPositioningDown(
  //       tester, Alignment.center, const Rect.fromLTWH(350.0, 250.0, 0.0, 0.0));
  //   await testPositioningDown(
  //       tester, Alignment.center, const Rect.fromLTWH(450.0, 250.0, 0.0, 0.0));
  //   await testPositioningDownThenUp(tester, Alignment.bottomRight,
  //       const Rect.fromLTWH(792.0, 500.0, 0.0, 0.0));
  //   await testPositioningDownThenUp(tester, Alignment.bottomRight,
  //       const Rect.fromLTWH(792.0, 500.0, 0.0, 0.0));
  //   await testPositioningDownThenUp(tester, Alignment.bottomLeft,
  //       const Rect.fromLTWH(8.0, 500.0, 0.0, 0.0));
  //   await testPositioningDownThenUp(tester, Alignment.bottomLeft,
  //       const Rect.fromLTWH(8.0, 500.0, 0.0, 0.0));
  //   await testPositioningDownThenUp(tester, Alignment.bottomCenter,
  //       const Rect.fromLTWH(350.0, 500.0, 0.0, 0.0));
  //   await testPositioningDownThenUp(tester, Alignment.bottomCenter,
  //       const Rect.fromLTWH(450.0, 500.0, 0.0, 0.0));
  // });

  // testMongolWidgets('PopupMenu positioning inside nested Overlay',
  //     (MongolWidgetTester tester) async {
  //   final Key buttonKey = UniqueKey();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         appBar: AppBar(title: const MongolText('Example')),
  //         body: Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Overlay(
  //             initialEntries: <OverlayEntry>[
  //               OverlayEntry(
  //                 builder: (_) => Center(
  //                   child: MongolPopupMenuButton<int>(
  //                     key: buttonKey,
  //                     itemBuilder: (_) => <MongolPopupMenuItem<int>>[
  //                       const MongolPopupMenuItem<int>(
  //                           value: 1, child: MongolText('Item 1')),
  //                       const MongolPopupMenuItem<int>(
  //                           value: 2, child: MongolText('Item 2')),
  //                     ],
  //                     child: const MongolText('Show Menu'),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Finder buttonFinder = find.byKey(buttonKey);
  //   final Finder popupFinder = find.bySemanticsLabel('Popup menu');
  //   await tester.tap(buttonFinder);
  //   await tester.pumpAndSettle();

  //   final Offset buttonTopLeft = tester.getTopLeft(buttonFinder);
  //   expect(tester.getTopLeft(popupFinder), buttonTopLeft);
  // });

  testMongolWidgets('PopupMenu positioning inside nested Navigator',
      (MongolWidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const MongolText('Example')),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: MongolPopupMenuButton<int>(
                          key: buttonKey,
                          itemBuilder: (_) => <MongolPopupMenuItem<int>>[
                            const MongolPopupMenuItem<int>(
                                value: 1, child: MongolText('Item 1')),
                            const MongolPopupMenuItem<int>(
                                value: 2, child: MongolText('Item 2')),
                          ],
                          child: const MongolText('Show Menu'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    final Finder buttonFinder = find.byKey(buttonKey);
    final Finder popupFinder = find.bySemanticsLabel('Popup menu');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    final Offset buttonTopLeft = tester.getTopLeft(buttonFinder);
    expect(tester.getTopLeft(popupFinder), buttonTopLeft);
  });

  testMongolWidgets('PopupMenu removes MediaQuery padding',
      (MongolWidgetTester tester) async {
    late BuildContext popupContext;

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.all(50.0),
        ),
        child: Material(
          child: MongolPopupMenuButton<int>(
            itemBuilder: (BuildContext context) {
              popupContext = context;
              return <MongolPopupMenuItem<int>>[
                MongolPopupMenuItem<int>(
                  value: 1,
                  child: Builder(
                    builder: (BuildContext context) {
                      popupContext = context;
                      return const MongolText('AAA');
                    },
                  ),
                ),
              ];
            },
            child: const SizedBox(
              height: 100.0,
              width: 100.0,
              child: MongolText('XXX'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(findMongol.text('XXX'));

    await tester.pump();

    expect(MediaQuery.of(popupContext).padding, EdgeInsets.zero);
  });

  testMongolWidgets('Popup Menu Offset Test',
      (MongolWidgetTester tester) async {
    MongolPopupMenuButton<int> buildMenuButton({Offset offset = Offset.zero}) {
      return MongolPopupMenuButton<int>(
        offset: offset,
        itemBuilder: (BuildContext context) {
          return <MongolPopupMenuItem<int>>[
            MongolPopupMenuItem<int>(
              value: 1,
              child: Builder(
                builder: (BuildContext context) {
                  return const MongolText('AAA');
                },
              ),
            ),
          ];
        },
      );
    }

    // Popup a menu without any offset.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Material(
            child: buildMenuButton(),
          ),
        ),
      ),
    );

    // Popup the menu.
    await tester.tap(find.byType(MongolIconButton));
    await tester.pumpAndSettle();

    // Initial state, the menu start at Offset(8.0, 8.0), the 8 pixels is edge padding when offset.dx < 8.0.
    expect(
        tester.getTopLeft(find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_PopupMenu<int?>')),
        const Offset(8.0, 8.0));

    // Collapse the menu.
    await tester.tap(find.byType(MongolIconButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Popup a new menu with Offset(50.0, 50.0).
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Material(
            child: buildMenuButton(offset: const Offset(50.0, 50.0)),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MongolIconButton));
    await tester.pumpAndSettle();

    // This time the menu should start at Offset(50.0, 50.0), the padding only added when offset.dx < 8.0.
    expect(
        tester.getTopLeft(find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_PopupMenu<int?>')),
        const Offset(50.0, 50.0));
  });

  // testMongolWidgets('open PopupMenu has correct semantics',
  //     (MongolWidgetTester tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolPopupMenuButton<int>(
  //           itemBuilder: (BuildContext context) {
  //             return <MongolPopupMenuItem<int>>[
  //               const MongolPopupMenuItem<int>(
  //                   value: 1, child: MongolText('1')),
  //               const MongolPopupMenuItem<int>(
  //                   value: 2, child: MongolText('2')),
  //               const MongolPopupMenuItem<int>(
  //                   value: 3, child: MongolText('3')),
  //               const MongolPopupMenuItem<int>(
  //                   value: 4, child: MongolText('4')),
  //               const MongolPopupMenuItem<int>(
  //                   value: 5, child: MongolText('5')),
  //             ];
  //           },
  //           child: const SizedBox(
  //             height: 100.0,
  //             width: 100.0,
  //             child: MongolText('XXX'),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.tap(findMongol.text('XXX'));
  //   await tester.pumpAndSettle();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics(
  //               textDirection: TextDirection.ltr,
  //               children: <TestSemantics>[
  //                 TestSemantics(
  //                   children: <TestSemantics>[
  //                     TestSemantics(
  //                       flags: <SemanticsFlag>[
  //                         SemanticsFlag.scopesRoute,
  //                         SemanticsFlag.namesRoute,
  //                       ],
  //                       label: 'Popup menu',
  //                       textDirection: TextDirection.ltr,
  //                       children: <TestSemantics>[
  //                         TestSemantics(
  //                           flags: <SemanticsFlag>[
  //                             SemanticsFlag.hasImplicitScrolling,
  //                           ],
  //                           children: <TestSemantics>[
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '1',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '2',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '3',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '4',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '5',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //                 TestSemantics(),
  //               ],
  //             ),
  //           ],
  //         ),
  //         ignoreId: true,
  //         ignoreTransform: true,
  //         ignoreRect: true,
  //       ));

  //   semantics.dispose();
  // });

  // testMongolWidgets(
  //     'MongolPopupMenuItem merges the semantics of its descendants',
  //     (MongolWidgetTester tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolPopupMenuButton<int>(
  //           itemBuilder: (BuildContext context) {
  //             return <MongolPopupMenuItem<int>>[
  //               MongolPopupMenuItem<int>(
  //                 value: 1,
  //                 child: Row(
  //                   children: <Widget>[
  //                     Semantics(
  //                       child: const MongolText('test1'),
  //                     ),
  //                     Semantics(
  //                       child: const MongolText('test2'),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ];
  //           },
  //           child: const SizedBox(
  //             height: 100.0,
  //             width: 100.0,
  //             child: MongolText('XXX'),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.tap(findMongol.text('XXX'));
  //   await tester.pumpAndSettle();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics(
  //               textDirection: TextDirection.ltr,
  //               children: <TestSemantics>[
  //                 TestSemantics(
  //                   children: <TestSemantics>[
  //                     TestSemantics(
  //                       flags: <SemanticsFlag>[
  //                         SemanticsFlag.scopesRoute,
  //                         SemanticsFlag.namesRoute,
  //                       ],
  //                       label: 'Popup menu',
  //                       textDirection: TextDirection.ltr,
  //                       children: <TestSemantics>[
  //                         TestSemantics(
  //                           flags: <SemanticsFlag>[
  //                             SemanticsFlag.hasImplicitScrolling,
  //                           ],
  //                           children: <TestSemantics>[
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: 'test1\ntest2',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //                 TestSemantics(),
  //               ],
  //             ),
  //           ],
  //         ),
  //         ignoreId: true,
  //         ignoreTransform: true,
  //         ignoreRect: true,
  //       ));

  //   semantics.dispose();
  // });

  // testMongolWidgets('disabled MongolPopupMenuItem has correct semantics',
  //     (MongolWidgetTester tester) async {
  //   // Regression test for https://github.com/flutter/flutter/issues/45044.
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolPopupMenuButton<int>(
  //           itemBuilder: (BuildContext context) {
  //             return <MongolPopupMenuItem<int>>[
  //               const MongolPopupMenuItem<int>(value: 1, child: MongolText('1')),
  //               const MongolPopupMenuItem<int>(
  //                   value: 2, enabled: false, child: MongolText('2')),
  //               const MongolPopupMenuItem<int>(value: 3, child: MongolText('3')),
  //               const MongolPopupMenuItem<int>(value: 4, child: MongolText('4')),
  //               const MongolPopupMenuItem<int>(value: 5, child: MongolText('5')),
  //             ];
  //           },
  //           child: const SizedBox(
  //             height: 100.0,
  //             width: 100.0,
  //             child: MongolText('XXX'),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   await tester.tap(findMongol.text('XXX'));
  //   await tester.pumpAndSettle();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics(
  //               textDirection: TextDirection.ltr,
  //               children: <TestSemantics>[
  //                 TestSemantics(
  //                   children: <TestSemantics>[
  //                     TestSemantics(
  //                       flags: <SemanticsFlag>[
  //                         SemanticsFlag.scopesRoute,
  //                         SemanticsFlag.namesRoute,
  //                       ],
  //                       label: 'Popup menu',
  //                       textDirection: TextDirection.ltr,
  //                       children: <TestSemantics>[
  //                         TestSemantics(
  //                           flags: <SemanticsFlag>[
  //                             SemanticsFlag.hasImplicitScrolling,
  //                           ],
  //                           children: <TestSemantics>[
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '1',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                               ],
  //                               actions: <SemanticsAction>[],
  //                               label: '2',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '3',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '4',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                             TestSemantics(
  //                               flags: <SemanticsFlag>[
  //                                 SemanticsFlag.isButton,
  //                                 SemanticsFlag.hasEnabledState,
  //                                 SemanticsFlag.isEnabled,
  //                                 SemanticsFlag.isFocusable,
  //                               ],
  //                               actions: <SemanticsAction>[SemanticsAction.tap],
  //                               label: '5',
  //                               textDirection: TextDirection.ltr,
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //                 TestSemantics(),
  //               ],
  //             ),
  //           ],
  //         ),
  //         ignoreId: true,
  //         ignoreTransform: true,
  //         ignoreRect: true,
  //       ));

  //   semantics.dispose();
  // });

  // testMongolWidgets('MongolPopupMenuButton MongolPopupMenuDivider',
  //     (MongolWidgetTester tester) async {
  //   // Regression test for https://github.com/flutter/flutter/issues/27072

  //   late String selectedValue;
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: MongolPopupMenuButton<String>(
  //             onSelected: (String result) {
  //               selectedValue = result;
  //             },
  //             initialValue: '1',
  //             child: const MongolText('Menu Button'),
  //             itemBuilder: (BuildContext context) =>
  //                 <MongolPopupMenuEntry<String>>[
  //               const MongolPopupMenuItem<String>(
  //                 value: '1',
  //                 child: MongolText('1'),
  //               ),
  //               const MongolPopupMenuDivider(),
  //               const MongolPopupMenuItem<String>(
  //                 value: '2',
  //                 child: MongolText('2'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   await tester.tap(findMongol.text('Menu Button'));
  //   await tester.pumpAndSettle();
  //   expect(findMongol.text('1'), findsOneWidget);
  //   expect(find.byType(MongolPopupMenuDivider), findsOneWidget);
  //   expect(findMongol.text('2'), findsOneWidget);

  //   await tester.tap(findMongol.text('1'));
  //   await tester.pumpAndSettle();
  //   expect(selectedValue, '1');

  //   await tester.tap(findMongol.text('Menu Button'));
  //   await tester.pumpAndSettle();
  //   expect(findMongol.text('1'), findsOneWidget);
  //   expect(find.byType(MongolPopupMenuDivider), findsOneWidget);
  //   expect(findMongol.text('2'), findsOneWidget);

  //   await tester.tap(findMongol.text('2'));
  //   await tester.pumpAndSettle();
  //   expect(selectedValue, '2');
  // });

  testMongolWidgets(
      'MongolPopupMenuItem child height is a minimum, child is horizontally centered',
      (MongolWidgetTester tester) async {
    final Key mongolPopupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const MongolPopupMenuItem<String>(child: MongolText('item'))
            .runtimeType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MongolPopupMenuButton<String>(
              key: mongolPopupMenuButtonKey,
              child: const MongolText('button'),
              onSelected: (String result) {},
              itemBuilder: (BuildContext context) {
                return <MongolPopupMenuEntry<String>>[
                  // This menu item's height will be 48 because the default minimum height
                  // is 48 and the height of the text is less than 48.
                  const MongolPopupMenuItem<String>(
                    value: '0',
                    child: MongolText('Item 0'),
                  ),
                  // This menu item's height parameter specifies its minimum height. The
                  // overall height of the menu item will be 50 because the child's
                  // height 40, is less than 50.
                  const MongolPopupMenuItem<String>(
                    width: 50,
                    value: '1',
                    child: SizedBox(
                      width: 40,
                      child: MongolText('Item 1'),
                    ),
                  ),
                  // This menu item's height parameter specifies its minimum height, so the
                  // overall height of the menu item will be 75.
                  const MongolPopupMenuItem<String>(
                    width: 75,
                    value: '2',
                    child: SizedBox(
                      child: MongolText('Item 2'),
                    ),
                  ),
                  // This menu item's height will be 100.
                  const MongolPopupMenuItem<String>(
                    value: '3',
                    child: SizedBox(
                      width: 100,
                      child: MongolText('Item 3'),
                    ),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    // Show the menu
    await tester.tap(find.byKey(mongolPopupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items and their InkWells should have the expected vertical size
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 0')).width,
        48);
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 1')).width,
        50);
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 2')).width,
        75);
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 3')).width,
        100);
    expect(
        tester.getSize(findMongol.widgetWithText(InkWell, 'Item 0')).width, 48);
    expect(
        tester.getSize(findMongol.widgetWithText(InkWell, 'Item 1')).width, 50);
    expect(
        tester.getSize(findMongol.widgetWithText(InkWell, 'Item 2')).width, 75);
    expect(tester.getSize(findMongol.widgetWithText(InkWell, 'Item 3')).width,
        100);

    // Menu item children which whose height is less than the MongolPopupMenuItem
    // are horizontally centered.
    expect(
      tester
          .getRect(findMongol.widgetWithText(menuItemType, 'Item 0'))
          .center
          .dx,
      tester.getRect(findMongol.text('Item 0')).center.dx,
    );
    expect(
      tester
          .getRect(findMongol.widgetWithText(menuItemType, 'Item 2'))
          .center
          .dx,
      tester.getRect(findMongol.text('Item 2')).center.dx,
    );
  });

  testMongolWidgets('MongolPopupMenuItem custom padding',
      (MongolWidgetTester tester) async {
    final Key mongolPopupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const MongolPopupMenuItem<String>(child: MongolText('item'))
            .runtimeType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MongolPopupMenuButton<String>(
              key: mongolPopupMenuButtonKey,
              child: const MongolText('button'),
              onSelected: (String result) {},
              itemBuilder: (BuildContext context) {
                return <MongolPopupMenuEntry<String>>[
                  const MongolPopupMenuItem<String>(
                    padding: EdgeInsets.zero,
                    value: '0',
                    child: MongolText('Item 0'),
                  ),
                  const MongolPopupMenuItem<String>(
                    padding: EdgeInsets.zero,
                    width: 0,
                    value: '0',
                    child: MongolText('Item 1'),
                  ),
                  const MongolPopupMenuItem<String>(
                    padding: EdgeInsets.all(20),
                    value: '0',
                    child: MongolText('Item 2'),
                  ),
                  const MongolPopupMenuItem<String>(
                    padding: EdgeInsets.all(20),
                    width: 100,
                    value: '0',
                    child: MongolText('Item 3'),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    // Show the menu
    await tester.tap(find.byKey(mongolPopupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items and their InkWells should have the expected horizontal size
    // given the interactions between widths and padding.
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 0')).width,
        48); // Minimum interactive height (48)
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 1')).width,
        16); // Height of text (16)
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 2')).width,
        56); // Padding (20.0 + 20.0) + Height of text (16) = 56
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 3')).width,
        100); // Height value of 100, since child (16) + padding (40) < 100

    expect(
        tester
            .widget<Container>(findMongol.widgetWithText(Container, 'Item 0'))
            .padding,
        EdgeInsets.zero);
    expect(
        tester
            .widget<Container>(findMongol.widgetWithText(Container, 'Item 1'))
            .padding,
        EdgeInsets.zero);
    expect(
        tester
            .widget<Container>(findMongol.widgetWithText(Container, 'Item 2'))
            .padding,
        const EdgeInsets.all(20));
    expect(
        tester
            .widget<Container>(findMongol.widgetWithText(Container, 'Item 3'))
            .padding,
        const EdgeInsets.all(20));
  });

  // testMongolWidgets(
  //     'CheckedPopupMenuItem child height is a minimum, child is vertically centered',
  //     (MongolWidgetTester tester) async {
  //   final Key mongolPopupMenuButtonKey = UniqueKey();
  //   final Type menuItemType =
  //       const CheckedPopupMenuItem<String>(child: MongolText('item')).runtimeType;

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: MongolPopupMenuButton<String>(
  //             key: mongolPopupMenuButtonKey,
  //             child: const MongolText('button'),
  //             onSelected: (String result) {},
  //             itemBuilder: (BuildContext context) {
  //               return <MongolPopupMenuEntry<String>>[
  //                 // This menu item's height will be 56.0 because the default minimum height
  //                 // is 48, but the contents of MongolPopupMenuItem are 56.0 tall.
  //                 const CheckedPopupMenuItem<String>(
  //                   checked: true,
  //                   value: '0',
  //                   child: MongolText('Item 0'),
  //                 ),
  //                 // This menu item's height parameter specifies its minimum height. The
  //                 // overall height of the menu item will be 60 because the child's
  //                 // height 56, is less than 60.
  //                 const CheckedPopupMenuItem<String>(
  //                   checked: true,
  //                   height: 60,
  //                   value: '1',
  //                   child: SizedBox(
  //                     height: 40,
  //                     child: MongolText('Item 1'),
  //                   ),
  //                 ),
  //                 // This menu item's height parameter specifies its minimum height, so the
  //                 // overall height of the menu item will be 75.
  //                 const CheckedPopupMenuItem<String>(
  //                   checked: true,
  //                   height: 75,
  //                   value: '2',
  //                   child: SizedBox(
  //                     child: MongolText('Item 2'),
  //                   ),
  //                 ),
  //                 // This menu item's height will be 100.
  //                 const CheckedPopupMenuItem<String>(
  //                   checked: true,
  //                   height: 100,
  //                   value: '3',
  //                   child: SizedBox(
  //                     child: MongolText('Item 3'),
  //                   ),
  //                 ),
  //               ];
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   // Show the menu
  //   await tester.tap(find.byKey(mongolPopupMenuButtonKey));
  //   await tester.pumpAndSettle();

  //   // The menu items and their InkWells should have the expected vertical size
  //   expect(
  //       tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 0')).height, 56);
  //   expect(
  //       tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 1')).height, 60);
  //   expect(
  //       tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 2')).height, 75);
  //   expect(tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 3')).height,
  //       100);
  //   // We evaluate the InkWell at the first index because that is the ListTile's
  //   // InkWell, which wins in the gesture arena over the child's InkWell and
  //   // is the one of interest.
  //   expect(tester.getSize(findMongol.widgetWithText(InkWell, 'Item 0').at(1)).height,
  //       56);
  //   expect(tester.getSize(findMongol.widgetWithText(InkWell, 'Item 1').at(1)).height,
  //       60);
  //   expect(tester.getSize(findMongol.widgetWithText(InkWell, 'Item 2').at(1)).height,
  //       75);
  //   expect(tester.getSize(findMongol.widgetWithText(InkWell, 'Item 3').at(1)).height,
  //       100);

  //   // Menu item children which whose height is less than the MongolPopupMenuItem
  //   // are vertically centered.
  //   expect(
  //     tester.getRect(findMongol.widgetWithText(menuItemType, 'Item 0')).center.dy,
  //     tester.getRect(findMongol.text('Item 0')).center.dy,
  //   );
  //   expect(
  //     tester.getRect(findMongol.widgetWithText(menuItemType, 'Item 2')).center.dy,
  //     tester.getRect(findMongol.text('Item 2')).center.dy,
  //   );
  // });

  // testMongolWidgets('CheckedPopupMenuItem custom padding',
  //     (MongolWidgetTester tester) async {
  //   final Key MongolPopupMenuButtonKey = UniqueKey();
  //   final Type menuItemType =
  //       const CheckedPopupMenuItem<String>(child: MongolText('item')).runtimeType;

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: MongolPopupMenuButton<String>(
  //             key: MongolPopupMenuButtonKey,
  //             child: const MongolText('button'),
  //             onSelected: (String result) {},
  //             itemBuilder: (BuildContext context) {
  //               return <MongolPopupMenuEntry<String>>[
  //                 const CheckedPopupMenuItem<String>(
  //                   padding: EdgeInsets.zero,
  //                   value: '0',
  //                   child: MongolText('Item 0'),
  //                 ),
  //                 const CheckedPopupMenuItem<String>(
  //                   padding: EdgeInsets.zero,
  //                   height: 0,
  //                   value: '0',
  //                   child: MongolText('Item 1'),
  //                 ),
  //                 const CheckedPopupMenuItem<String>(
  //                   padding: EdgeInsets.all(20),
  //                   value: '0',
  //                   child: MongolText('Item 2'),
  //                 ),
  //                 const CheckedPopupMenuItem<String>(
  //                   padding: EdgeInsets.all(20),
  //                   height: 100,
  //                   value: '0',
  //                   child: MongolText('Item 3'),
  //                 ),
  //               ];
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   // Show the menu
  //   await tester.tap(find.byKey(popupMenuButtonKey));
  //   await tester.pumpAndSettle();

  //   // The menu items and their InkWells should have the expected vertical size
  //   // given the interactions between heights and padding.
  //   expect(tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 0')).height,
  //       56); // Minimum ListTile height (56)
  //   expect(tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 1')).height,
  //       56); // Minimum ListTile height (56)
  //   expect(tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 2')).height,
  //       96); // Padding (20.0 + 20.0) + Height of ListTile (56) = 96
  //   expect(tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 3')).height,
  //       100); // Height value of 100, since child (56) + padding (40) < 100

  //   expect(
  //       tester
  //           .widget<Container>(findMongol.widgetWithText(Container, 'Item 0'))
  //           .padding,
  //       EdgeInsets.zero);
  //   expect(
  //       tester
  //           .widget<Container>(findMongol.widgetWithText(Container, 'Item 1'))
  //           .padding,
  //       EdgeInsets.zero);
  //   expect(
  //       tester
  //           .widget<Container>(findMongol.widgetWithText(Container, 'Item 2'))
  //           .padding,
  //       const EdgeInsets.all(20));
  //   expect(
  //       tester
  //           .widget<Container>(findMongol.widgetWithText(Container, 'Item 3'))
  //           .padding,
  //       const EdgeInsets.all(20));
  // });

  testMongolWidgets(
      'Update MongolPopupMenuItem layout while the menu is visible',
      (MongolWidgetTester tester) async {
    final Key mongolPopupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const MongolPopupMenuItem<String>(child: MongolText('item'))
            .runtimeType;

    Widget buildFrame({
      TextDirection textDirection = TextDirection.ltr,
      double fontSize = 24,
    }) {
      return MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return Directionality(
            textDirection: textDirection,
            child: PopupMenuTheme(
              data: PopupMenuTheme.of(context).copyWith(
                textStyle: Theme.of(context)
                    .textTheme
                    .subtitle1!
                    .copyWith(fontSize: fontSize),
              ),
              child: child!,
            ),
          );
        },
        home: Scaffold(
          body: MongolPopupMenuButton<String>(
            key: mongolPopupMenuButtonKey,
            child: const MongolText('button'),
            onSelected: (String result) {},
            itemBuilder: (BuildContext context) {
              return <MongolPopupMenuEntry<String>>[
                const MongolPopupMenuItem<String>(
                  value: '0',
                  child: MongolText('Item 0'),
                ),
                const MongolPopupMenuItem<String>(
                  value: '1',
                  child: MongolText('Item 1'),
                ),
              ];
            },
          ),
        ),
      );
    }

    // Show the menu
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.byKey(mongolPopupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items should have their default heights and horizontal alignment.
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 0')).width,
        48);
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 1')).width,
        48);
    expect(tester.getTopLeft(findMongol.text('Item 0')).dy, 24);
    expect(tester.getTopLeft(findMongol.text('Item 1')).dy, 24);

    // While the menu is up, change its font size to 64 (default is 16).
    await tester.pumpWidget(buildFrame(fontSize: 64));
    await tester.pumpAndSettle(); // Theme changes are animated.
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 0')).width,
        128);
    expect(
        tester.getSize(findMongol.widgetWithText(menuItemType, 'Item 1')).width,
        128);
    expect(tester.getSize(findMongol.text('Item 0')).width, 128);
    expect(tester.getSize(findMongol.text('Item 1')).width, 128);
    expect(tester.getTopLeft(findMongol.text('Item 0')).dy, 24);
    expect(tester.getTopLeft(findMongol.text('Item 1')).dy, 24);
  });

  test(
      "MongolPopupMenuButton's child and icon properties cannot be simultaneously defined",
      () {
    expect(() {
      MongolPopupMenuButton<int>(
        itemBuilder: (BuildContext context) => <MongolPopupMenuItem<int>>[],
        child: Container(),
        icon: const Icon(Icons.error),
      );
    }, throwsAssertionError);
  });

  testMongolWidgets('MongolPopupMenuButton default tooltip',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              // Default Tooltip should be present when [MongolPopupMenuButton.icon]
              // and [MongolPopupMenuButton.child] are undefined.
              MongolPopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
              ),
              // Default Tooltip should be present when
              // [MongolPopupMenuButton.child] is defined.
              MongolPopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
                child: const MongolText('Test text'),
              ),
              // Default Tooltip should be present when
              // [MongolPopupMenuButton.icon] is defined.
              MongolPopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
                icon: const Icon(Icons.check),
              ),
            ],
          ),
        ),
      ),
    );

    // The default tooltip is defined as [MaterialLocalizations.showMenuTooltip]
    // and it is used when no tooltip is provided.
    expect(find.byType(MongolTooltip), findsNWidgets(3));
    expect(
        findMongol
            .byTooltip(const DefaultMaterialLocalizations().showMenuTooltip),
        findsNWidgets(3));
  });

  testMongolWidgets('MongolPopupMenuButton custom tooltip',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              // Tooltip should work when [MongolPopupMenuButton.icon]
              // and [MongolPopupMenuButton.child] are undefined.
              MongolPopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
                tooltip: 'Test tooltip',
              ),
              // Tooltip should work when
              // [MongolPopupMenuButton.child] is defined.
              MongolPopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
                tooltip: 'Test tooltip',
                child: const MongolText('Test text'),
              ),
              // Tooltip should work when
              // [MongolPopupMenuButton.icon] is defined.
              MongolPopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                      value: 1,
                      child: MongolText('Tap me please!'),
                    ),
                  ];
                },
                tooltip: 'Test tooltip',
                icon: const Icon(Icons.check),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(MongolTooltip), findsNWidgets(3));
    expect(findMongol.byTooltip('Test tooltip'), findsNWidgets(3));
  });

  testMongolWidgets('Allow Widget for MongolPopupMenuButton.icon',
      (MongolWidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolPopupMenuButton<int>(
            itemBuilder: (BuildContext context) {
              return <MongolPopupMenuEntry<int>>[
                const MongolPopupMenuItem<int>(
                  value: 1,
                  child: MongolText('Tap me please!'),
                ),
              ];
            },
            tooltip: 'Test tooltip',
            icon: const MongolText('MongolPopupMenuButton icon'),
          ),
        ),
      ),
    );

    expect(findMongol.text('MongolPopupMenuButton icon'), findsOneWidget);
  });

  testMongolWidgets('showMongolMenu uses nested navigator by default',
      (MongolWidgetTester tester) async {
    final MenuObserver rootObserver = MenuObserver();
    final MenuObserver nestedObserver = MenuObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showMongolMenu<int>(
                    context: context,
                    position: RelativeRect.fill,
                    items: <MongolPopupMenuItem<int>>[
                      const MongolPopupMenuItem<int>(
                        value: 1,
                        child: MongolText('1'),
                      ),
                    ],
                  );
                },
                child: const MongolText('Show Menu'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));

    expect(rootObserver.menuCount, 0);
    expect(nestedObserver.menuCount, 1);
  });

  testMongolWidgets(
      'showMongolMenu uses root navigator if useRootNavigator is true',
      (MongolWidgetTester tester) async {
    final MenuObserver rootObserver = MenuObserver();
    final MenuObserver nestedObserver = MenuObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showMongolMenu<int>(
                    context: context,
                    useRootNavigator: true,
                    position: RelativeRect.fill,
                    items: <MongolPopupMenuItem<int>>[
                      const MongolPopupMenuItem<int>(
                        value: 1,
                        child: MongolText('1'),
                      ),
                    ],
                  );
                },
                child: const MongolText('Show Menu'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));

    expect(rootObserver.menuCount, 1);
    expect(nestedObserver.menuCount, 0);
  });

  // testMongolWidgets('MongolPopupMenuButton calling showButtonMenu manually',
  //     (MongolWidgetTester tester) async {
  //   final GlobalKey<PopupMenuButtonState<int>> globalKey = GlobalKey();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Column(
  //           children: <Widget>[
  //             MongolPopupMenuButton<int>(
  //               key: globalKey,
  //               itemBuilder: (BuildContext context) {
  //                 return <MongolPopupMenuEntry<int>>[
  //                   const MongolPopupMenuItem<int>(
  //                     value: 1,
  //                     child: MongolText('Tap me please!'),
  //                   ),
  //                 ];
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(findMongol.text('Tap me please!'), findsNothing);

  //   globalKey.currentState!.showButtonMenu();
  //   // The MongolPopupMenuItem will appear after an animation, hence,
  //   // we have to first wait for the tester to settle.
  //   await tester.pumpAndSettle();

  //   expect(findMongol.text('Tap me please!'), findsOneWidget);
  // });

  testMongolWidgets('MongolPopupMenuItem changes mouse cursor when hovered',
      (MongolWidgetTester tester) async {
    const Key key = ValueKey<int>(1);
    // Test MongolPopupMenuItem() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: MongolPopupMenuItem<int>(
                  key: key,
                  mouseCursor: SystemMouseCursors.text,
                  value: 1,
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byKey(key)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: MongolPopupMenuItem<int>(
                  key: key,
                  value: 1,
                  child: Container(),
                ),
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
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: MongolPopupMenuItem<int>(
                  key: key,
                  value: 1,
                  enabled: false,
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic);
  });

  testMongolWidgets('PopupMenu in AppBar does not overlap with the status bar',
      (MongolWidgetTester tester) async {
    const List<MongolPopupMenuItem<int>> choices = <MongolPopupMenuItem<int>>[
      MongolPopupMenuItem<int>(value: 1, child: MongolText('Item 1')),
      MongolPopupMenuItem<int>(value: 2, child: MongolText('Item 2')),
      MongolPopupMenuItem<int>(value: 3, child: MongolText('Item 3')),
    ];

    const double statusBarHeight = 24.0;
    final MongolPopupMenuItem<int> firstItem = choices[0];
    int _selectedValue = choices[0].value!;

    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: const MediaQueryData(
                padding: EdgeInsets.only(top: statusBarHeight)), // status bar
            child: child!,
          );
        },
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              appBar: AppBar(
                title: const MongolText('PopupMenu Test'),
                actions: <Widget>[
                  MongolPopupMenuButton<int>(
                    onSelected: (int result) {
                      setState(() {
                        _selectedValue = result;
                      });
                    },
                    initialValue: _selectedValue,
                    itemBuilder: (BuildContext context) {
                      return choices;
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap third item.
    await tester.tap(findMongol.text('Item 3'));
    await tester.pumpAndSettle();

    // Open popupMenu again.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Check whether the first item is not overlapping with status bar.
    expect(tester.getTopLeft(find.byWidget(firstItem)).dy,
        greaterThan(statusBarHeight));
  });

  // testMongolWidgets(
  //     'Vertically long PopupMenu does not overlap with the status bar and bottom notch',
  //     (MongolWidgetTester tester) async {
  //   const double windowPaddingTop = 44;
  //   const double windowPaddingBottom = 34;

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       builder: (BuildContext context, Widget? child) {
  //         return MediaQuery(
  //           data: const MediaQueryData(
  //             padding: EdgeInsets.only(
  //               top: windowPaddingTop,
  //               bottom: windowPaddingBottom,
  //             ),
  //           ),
  //           child: child!,
  //         );
  //       },
  //       home: Scaffold(
  //         appBar: AppBar(
  //           title: const MongolText('PopupMenu Test'),
  //         ),
  //         body: MongolPopupMenuButton<int>(
  //           child: const MongolText('Show Menu'),
  //           itemBuilder: (BuildContext context) =>
  //               Iterable<MongolPopupMenuItem<int>>.generate(
  //             20,
  //             (int i) => MongolPopupMenuItem<int>(
  //               value: i,
  //               child: MongolText('Item $i'),
  //             ),
  //           ).toList(),
  //         ),
  //       ),
  //     ),
  //   );

  //   await tester.tap(findMongol.text('Show Menu'));
  //   await tester.pumpAndSettle();

  //   final Offset topRightOfMenu =
  //       tester.getTopRight(find.byType(SingleChildScrollView));
  //   final Offset bottomRightOfMenu =
  //       tester.getBottomRight(find.byType(SingleChildScrollView));

  //   expect(topRightOfMenu.dy, windowPaddingTop + 8.0);
  //   expect(bottomRightOfMenu.dy,
  //       600.0 - windowPaddingBottom - 8.0); // Screen height is 600.
  // });

  testMongolWidgets('PopupMenu position test when have unsafe area',
      (MongolWidgetTester tester) async {
    final GlobalKey buttonKey = GlobalKey();

    Widget buildFrame(double width, double height) {
      return MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(
                top: 32.0,
                bottom: 32.0,
              ),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          appBar: AppBar(
            title: const MongolText('PopupMenu Test'),
            actions: <Widget>[
              MongolPopupMenuButton<int>(
                child: SizedBox(
                  key: buttonKey,
                  height: height,
                  width: width,
                  child: const ColoredBox(
                    color: Colors.pink,
                  ),
                ),
                itemBuilder: (BuildContext context) =>
                    <MongolPopupMenuEntry<int>>[
                  const MongolPopupMenuItem<int>(
                      value: 1, child: MongolText('-1-')),
                  const MongolPopupMenuItem<int>(
                      value: 2, child: MongolText('-2-')),
                ],
              )
            ],
          ),
          body: Container(),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(20.0, 20.0));

    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    final Offset button = tester.getTopRight(find.byKey(buttonKey));
    expect(button, const Offset(800.0, 32.0)); // The topPadding is 32.0.

    final Offset popupMenu =
        tester.getTopRight(find.byType(SingleChildScrollView));

    // The menu should be positioned directly next to the top of the button.
    // The 8.0 pixels is [_kMenuScreenPadding].
    expect(popupMenu, Offset(button.dx - 8.0, button.dy + 8.0));
  });

  // // Regression test for https://github.com/flutter/flutter/issues/82874
  // testMongolWidgets(
  //     'PopupMenu position test when have unsafe area - left/right padding',
  //     (MongolWidgetTester tester) async {
  //   final GlobalKey buttonKey = GlobalKey();
  //   const EdgeInsets padding =
  //       EdgeInsets.only(left: 300.0, top: 32.0, right: 310.0, bottom: 64.0);
  //   EdgeInsets? mediaQueryPadding;

  //   Widget buildFrame(double width, double height) {
  //     return MaterialApp(
  //       builder: (BuildContext context, Widget? child) {
  //         return MediaQuery(
  //           data: const MediaQueryData(
  //             padding: padding,
  //           ),
  //           child: child!,
  //         );
  //       },
  //       home: Scaffold(
  //         appBar: AppBar(
  //           title: const MongolText('PopupMenu Test'),
  //           actions: <Widget>[
  //             MongolPopupMenuButton<int>(
  //               child: SizedBox(
  //                 key: buttonKey,
  //                 height: height,
  //                 width: width,
  //                 child: const ColoredBox(
  //                   color: Colors.pink,
  //                 ),
  //               ),
  //               itemBuilder: (BuildContext context) {
  //                 return <MongolPopupMenuEntry<int>>[
  //                   MongolPopupMenuItem<int>(
  //                     value: 1,
  //                     child: Builder(
  //                       builder: (BuildContext context) {
  //                         mediaQueryPadding = MediaQuery.of(context).padding;
  //                         return MongolText('-1-' * 500); // A long long text string.
  //                       },
  //                     ),
  //                   ),
  //                   const MongolPopupMenuItem<int>(value: 2, child: MongolText('-2-')),
  //                 ];
  //               },
  //             )
  //           ],
  //         ),
  //         body: const SizedBox.shrink(),
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(buildFrame(20.0, 20.0));

  //   await tester.tap(find.byKey(buttonKey));
  //   await tester.pumpAndSettle();

  //   final Offset button = tester.getTopRight(find.byKey(buttonKey));
  //   expect(button,
  //       Offset(800.0 - padding.right, padding.top)); // The topPadding is 32.0.

  //   final Offset popupMenuTopRight =
  //       tester.getTopRight(find.byType(SingleChildScrollView));

  //   // The menu should be positioned directly next to the top of the button.
  //   // The 8.0 pixels is [_kMenuScreenPadding].
  //   expect(popupMenuTopRight,
  //       Offset(800.0 - padding.right - 8.0, padding.top + 8.0));

  //   final Offset popupMenuTopLeft =
  //       tester.getTopLeft(find.byType(SingleChildScrollView));
  //   expect(popupMenuTopLeft, Offset(padding.left + 8.0, padding.top + 8.0));

  //   final Offset popupMenuBottomLeft =
  //       tester.getBottomLeft(find.byType(SingleChildScrollView));
  //   expect(popupMenuBottomLeft,
  //       Offset(padding.left + 8.0, 600.0 - padding.bottom - 8.0));

  //   // The `MediaQueryData.padding` should be removed.
  //   expect(mediaQueryPadding, EdgeInsets.zero);
  // });

  // group('feedback', () {
  //   late FeedbackTester feedback;

  //   setUp(() {
  //     feedback = FeedbackTester();
  //   });

  //   tearDown(() {
  //     feedback.dispose();
  //   });

  //   Widget buildFrame({bool? widgetEnableFeedback, bool? themeEnableFeedback}) {
  //     return MaterialApp(
  //       home: Scaffold(
  //         body: PopupMenuTheme(
  //           data: PopupMenuThemeData(
  //             enableFeedback: themeEnableFeedback,
  //           ),
  //           child: MongolPopupMenuButton<int>(
  //             enableFeedback: widgetEnableFeedback,
  //             child: const MongolText('Show Menu'),
  //             itemBuilder: (BuildContext context) {
  //               return <MongolPopupMenuItem<int>>[
  //                 const MongolPopupMenuItem<int>(
  //                   value: 1,
  //                   child: MongolText('One'),
  //                 ),
  //               ];
  //             },
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   testMongolWidgets('MongolPopupMenuButton enableFeedback works properly',
  //       (MongolWidgetTester tester) async {
  //     expect(feedback.clickSoundCount, 0);
  //     expect(feedback.hapticCount, 0);

  //     // MongolPopupMenuButton with enabled feedback.
  //     await tester.pumpWidget(buildFrame(widgetEnableFeedback: true));
  //     await tester.tap(findMongol.text('Show Menu'));
  //     await tester.pumpAndSettle();
  //     expect(feedback.clickSoundCount, 1);
  //     expect(feedback.hapticCount, 0);

  //     await tester.pumpWidget(Container());

  //     // MongolPopupMenuButton with disabled feedback.
  //     await tester.pumpWidget(buildFrame(widgetEnableFeedback: false));
  //     await tester.tap(findMongol.text('Show Menu'));
  //     await tester.pumpAndSettle();
  //     expect(feedback.clickSoundCount, 1);
  //     expect(feedback.hapticCount, 0);

  //     await tester.pumpWidget(Container());

  //     // MongolPopupMenuButton with enabled feedback by default.
  //     await tester.pumpWidget(buildFrame());
  //     await tester.tap(findMongol.text('Show Menu'));
  //     await tester.pumpAndSettle();
  //     expect(feedback.clickSoundCount, 2);
  //     expect(feedback.hapticCount, 0);

  //     await tester.pumpWidget(Container());

  //     // PopupMenu with disabled feedback using MongolPopupMenuButtonTheme.
  //     await tester.pumpWidget(buildFrame(themeEnableFeedback: false));
  //     await tester.tap(findMongol.text('Show Menu'));
  //     await tester.pumpAndSettle();
  //     expect(feedback.clickSoundCount, 2);
  //     expect(feedback.hapticCount, 0);

  //     await tester.pumpWidget(Container());

  //     // PopupMenu enableFeedback property overrides MongolPopupMenuButtonTheme.
  //     await tester.pumpWidget(
  //         buildFrame(widgetEnableFeedback: false, themeEnableFeedback: true));
  //     await tester.tap(findMongol.text('Show Menu'));
  //     await tester.pumpAndSettle();
  //     expect(feedback.clickSoundCount, 2);
  //     expect(feedback.hapticCount, 0);
  //   });
  // });

  testMongolWidgets('iconSize parameter tests',
      (MongolWidgetTester tester) async {
    Future<void> buildFrame({double? iconSize}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MongolPopupMenuButton<String>(
                iconSize: iconSize,
                itemBuilder: (_) => <MongolPopupMenuEntry<String>>[
                  const MongolPopupMenuItem<String>(
                    value: 'value',
                    child: MongolText('child'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await buildFrame();
    expect(
        tester.widget<MongolIconButton>(find.byType(MongolIconButton)).iconSize,
        24);

    await buildFrame(iconSize: 50);
    expect(
        tester.widget<MongolIconButton>(find.byType(MongolIconButton)).iconSize,
        50);
  });

  testMongolWidgets('does not crash in small overlay',
      (MongolWidgetTester tester) async {
    final GlobalKey navigator = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              OutlinedButton(
                onPressed: () {
                  showMongolMenu<void>(
                    context: navigator.currentContext!,
                    position: RelativeRect.fill,
                    items: const <MongolPopupMenuItem<void>>[
                      MongolPopupMenuItem<void>(child: MongolText('foo')),
                    ],
                  );
                },
                child: const MongolText('press'),
              ),
              SizedBox(
                height: 10,
                width: 10,
                child: Navigator(
                  key: navigator,
                  onGenerateRoute: (RouteSettings settings) =>
                      MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        Container(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(findMongol.text('press'));
    await tester.pumpAndSettle();
    expect(findMongol.text('foo'), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/80869
  testMongolWidgets('The menu position test in the scrollable widget',
      (MongolWidgetTester tester) async {
    final GlobalKey buttonKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 100),
                MongolPopupMenuButton<int>(
                  child: SizedBox(
                    key: buttonKey,
                    height: 10.0,
                    width: 10.0,
                    child: const ColoredBox(
                      color: Colors.pink,
                    ),
                  ),
                  itemBuilder: (BuildContext context) =>
                      <MongolPopupMenuEntry<int>>[
                    const MongolPopupMenuItem<int>(
                        value: 1, child: MongolText('-1-')),
                    const MongolPopupMenuItem<int>(
                        value: 2, child: MongolText('-2-')),
                  ],
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      ),
    );

    // Open the menu.
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    Offset button = tester.getTopLeft(find.byKey(buttonKey));
    expect(button, const Offset(0.0, 100.0));

    Offset popupMenu =
        tester.getTopLeft(find.byType(SingleChildScrollView).last);
    // The menu should be positioned directly next to the top of the button.
    // The 8.0 pixels is [_kMenuScreenPadding].
    expect(popupMenu, const Offset(8.0, 100.0));

    // Close the menu.
    await tester.tap(find.byKey(buttonKey), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Scroll a little bit.
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0.0, -50.0));

    button = tester.getTopLeft(find.byKey(buttonKey));
    expect(button, const Offset(0.0, 50.0));

    // Open the menu again.
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    popupMenu = tester.getTopLeft(find.byType(SingleChildScrollView).last);
    // The menu should be positioned directly next to the top of the button.
    // The 8.0 pixels is [_kMenuScreenPadding].
    expect(popupMenu, const Offset(8.0, 50.0));
  });
}

class TestApp extends StatefulWidget {
  const TestApp({
    Key? key,
    this.child,
  }) : super(key: key);

  final Widget? child;

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              assert(settings.name == '/');
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) => Material(
                  child: widget.child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MenuObserver extends NavigatorObserver {
  int menuCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.toString().contains('_PopupMenuRoute')) {
      menuCount++;
    }
    super.didPush(route, previousRoute);
  }
}
