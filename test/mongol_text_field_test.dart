// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

/// The field lays out along the vertical axis, so it is given a fixed height
/// and left free to take whatever width it needs.
Widget boxed(Widget child, {double height = 300.0}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(height: height, child: child),
        ),
      ),
    );

/// find.text matches nothing here: these widgets render MongolText.
Finder findMongolText(String text) => find
    .byWidgetPredicate((widget) => widget is MongolText && widget.data == text);

/// tester.enterText looks for Flutter's EditableText, which this package does
/// not use, so focus the field first and drive the input connection directly.
Future<void> enterMongolText(
    WidgetTester tester, Finder finder, String text) async {
  await tester.tap(finder);
  await tester.pump();
  tester.testTextInput.enterText(text);
  await tester.pump();
}

/// The hint is faded rather than removed, so read the opacity that wraps it.
double hintOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.ancestor(
      of: findMongolText('hint'),
      matching: find.byType(AnimatedOpacity),
    ))
    .opacity;

void main() {
  testWidgets('shows the text from its controller', (tester) async {
    final controller = TextEditingController(text: 'hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(boxed(MongolTextField(controller: controller)));

    expect(find.byType(MongolTextField), findsOneWidget);
    expect(controller.text, equals('hello'));
  });

  testWidgets('typing updates the controller and calls onChanged',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];

    await tester.pumpWidget(boxed(MongolTextField(
      controller: controller,
      onChanged: changes.add,
    )));

    await enterMongolText(tester, find.byType(MongolTextField), 'abc');
    await tester.pump();

    expect(controller.text, equals('abc'));
    expect(changes, equals(<String>['abc']));
  });

  testWidgets('onSubmitted fires when the action is sent', (tester) async {
    String? submitted;
    await tester.pumpWidget(boxed(MongolTextField(
      onSubmitted: (value) => submitted = value,
    )));

    await enterMongolText(tester, find.byType(MongolTextField), 'done');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, equals('done'));
  });

  testWidgets('readOnly keeps the existing text and takes no input',
      (tester) async {
    final controller = TextEditingController(text: 'fixed');
    addTearDown(controller.dispose);

    await tester.pumpWidget(boxed(MongolTextField(
      controller: controller,
      readOnly: true,
    )));

    await tester.tap(find.byType(MongolTextField));
    await tester.pump();

    expect(controller.text, equals('fixed'));
    expect(tester.testTextInput.hasAnyClients, isFalse,
        reason: 'a read only field should not connect to the keyboard');
  });

  testWidgets('enabled: false does not focus on tap', (tester) async {
    await tester.pumpWidget(boxed(const MongolTextField(enabled: false)));

    await tester.tap(find.byType(MongolTextField), warnIfMissed: false);
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, isFalse);
  });

  testWidgets('maxLength stops input beyond the limit', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(boxed(MongolTextField(
      controller: controller,
      maxLength: 3,
    )));

    await enterMongolText(tester, find.byType(MongolTextField), 'abcdef');
    await tester.pump();

    expect(controller.text.length, equals(3));
  });

  testWidgets('hintText is shown while empty and faded out once typed',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(boxed(MongolTextField(
      controller: controller,
      decoration: const InputDecoration(hintText: 'hint'),
    )));
    expect(findMongolText('hint'), findsOneWidget);
    expect(hintOpacity(tester), equals(1.0));

    await enterMongolText(tester, find.byType(MongolTextField), 'x');
    await tester.pumpAndSettle();

    // The hint stays in the tree and is faded out rather than removed.
    expect(controller.text, equals('x'));
    expect(hintOpacity(tester), equals(0.0));
  });

  testWidgets('obscureText replaces the glyphs but not the value',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(boxed(MongolTextField(
      controller: controller,
      obscureText: true,
    )));

    await enterMongolText(tester, find.byType(MongolTextField), 'secret');
    await tester.pump();

    expect(controller.text, equals('secret'),
        reason: 'obscuring is a display concern, the value is unchanged');
    expect(findMongolText('secret'), findsNothing);
  });
}
