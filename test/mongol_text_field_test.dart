// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: omit_local_variable_types
// ignore_for_file: todo

@TestOn('!chrome')
import 'dart:ui' as ui show window;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mongol/src/base/mongol_text_align.dart';
import 'package:mongol/src/editing/mongol_editable_text.dart';
import 'package:mongol/src/editing/mongol_render_editable.dart';
import 'package:mongol/src/text/mongol_text.dart';
import 'package:mongol/src/editing/mongol_text_field.dart';

import 'widgets/binding.dart';
import 'widgets/editable_text_utils.dart';
import 'widgets/mongol_widget_tester.dart';
import 'widgets/finders.dart';
import 'widgets/semantics_tester.dart';

// import '../widgets/editable_text_utils.dart' show findRenderEditable, globalize, textOffsetToPosition;
// import '../widgets/semantics_tester.dart';
// import 'feedback_tester.dart';

typedef FormatEditUpdateCallback = void Function(
    TextEditingValue, TextEditingValue);

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments as Object;
        break;
    }
  }
}

class MaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(MaterialLocalizationsDelegate old) => false;
}

class WidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(WidgetsLocalizationsDelegate old) => false;
}

Widget overlay({required Widget child}) {
  final entry = OverlayEntry(
    builder: (BuildContext context) {
      return Center(
        child: Material(
          child: child,
        ),
      );
    },
  );
  return overlayWithEntry(entry);
}

Widget overlayWithEntry(OverlayEntry entry) {
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: <LocalizationsDelegate<dynamic>>[
      WidgetsLocalizationsDelegate(),
      MaterialLocalizationsDelegate(),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(600.0, 800.0)),
        child: Overlay(
          initialEntries: <OverlayEntry>[
            entry,
          ],
        ),
      ),
    ),
  );
}

Widget boilerplate({required Widget child}) {
  return MaterialApp(
    home: Localizations(
      locale: const Locale('en', 'US'),
      delegates: <LocalizationsDelegate<dynamic>>[
        WidgetsLocalizationsDelegate(),
        MaterialLocalizationsDelegate(),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(600.0, 800.0)),
          child: Center(
            child: Material(
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> skipPastScrollingAnimation(MongolWidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

double getOpacity(MongolWidgetTester tester, Finder finder) {
  return tester
      .widget<FadeTransition>(
        find.ancestor(
          of: finder,
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;
}

class TestFormatter extends TextInputFormatter {
  TestFormatter(this.onFormatEditUpdate);
  FormatEditUpdateCallback onFormatEditUpdate;
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    onFormatEditUpdate(oldValue, newValue);
    return newValue;
  }
}

void main() {
  MongolTestWidgetsFlutterBinding.ensureInitialized();
  final mockClipboard = MockClipboard();
  SystemChannels.platform
      .setMockMethodCallHandler(mockClipboard.handleMethodCall);

  setUp(() async {
    debugResetSemanticsIdCounter();
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  // final Key textFieldKey = UniqueKey();
  // Widget textFieldBuilder({
  //   int? maxLines = 1,
  //   int? minLines,
  // }) {
  //   return boilerplate(
  //     child: MongolTextField(
  //       key: textFieldKey,
  //       style: const TextStyle(color: Colors.black, fontSize: 34.0),
  //       maxLines: maxLines,
  //       minLines: minLines,
  //       decoration: const InputDecoration(
  //         hintText: 'Placeholder',
  //       ),
  //     ),
  //   );
  // }

  // testMongolWidgets('can use the desktop cut/copy/paste buttons on Mac', (MongolWidgetTester tester) async {
  //   final controller = TextEditingController(
  //     text: 'blah1 blah2',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   // Initially, the menu is not shown and there is no selection.
  //   expect(find.byType(CupertinoButton), findsNothing);
  //   expect(controller.selection, const TextSelection(baseOffset: -1, extentOffset: -1));

  //   final midBlah1 = textOffsetToPosition(tester, 2);

  //   // Right clicking shows the menu.
  //   final gesture = await tester.startGesture(
  //     midBlah1,
  //     kind: PointerDeviceKind.mouse,
  //     buttons: kSecondaryMouseButton,
  //   );
  //   addTearDown(gesture.removePointer);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();
  //   expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
  //   expect(findMongol.text('Cut'), findsOneWidget);
  //   expect(findMongol.text('Copy'), findsOneWidget);
  //   expect(findMongol.text('Paste'), findsOneWidget);

  //   // Copy the first word.
  //   await tester.tap(findMongol.text('Copy'));
  //   await tester.pumpAndSettle();
  //   expect(controller.text, 'blah1 blah2');
  //   expect(controller.selection, const TextSelection(baseOffset: 5, extentOffset: 5));
  //   expect(find.byType(CupertinoButton), findsNothing);

  //   // Paste it at the end.
  //   await gesture.down(textOffsetToPosition(tester, controller.text.length));
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();
  //   expect(controller.selection, const TextSelection(baseOffset: 11, extentOffset: 11, affinity: TextAffinity.upstream));
  //   expect(findMongol.text('Cut'), findsNothing);
  //   expect(findMongol.text('Copy'), findsNothing);
  //   expect(findMongol.text('Paste'), findsOneWidget);
  //   await tester.tap(findMongol.text('Paste'));
  //   await tester.pumpAndSettle();
  //   expect(controller.text, 'blah1 blah2blah1');
  //   expect(controller.selection, const TextSelection(baseOffset: 16, extentOffset: 16));

  //   // Cut the first word.
  //   await gesture.down(midBlah1);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();
  //   expect(findMongol.text('Cut'), findsOneWidget);
  //   expect(findMongol.text('Copy'), findsOneWidget);
  //   expect(findMongol.text('Paste'), findsOneWidget);
  //   expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
  //   await tester.tap(findMongol.text('Cut'));
  //   await tester.pumpAndSettle();
  //   expect(controller.text, ' blah2blah1');
  //   expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 0));
  //   expect(find.byType(CupertinoButton), findsNothing);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux }), skip: kIsWeb);

  testMongolWidgets(
      'MongolTextField passes onEditingComplete to MongolEditableText',
      (tester) async {
    final VoidCallback onEditingComplete = () {};

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolTextField(
            onEditingComplete: onEditingComplete,
          ),
        ),
      ),
    );

    final Finder editableTextFinder = find.byType(MongolEditableText);
    expect(editableTextFinder, findsOneWidget);

    final MongolEditableText editableTextWidget =
        tester.widget(editableTextFinder);
    expect(editableTextWidget.onEditingComplete, onEditingComplete);
  });

  testMongolWidgets('MongolTextField has consistent size', (tester) async {
    final Key textFieldKey = UniqueKey();
    late String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          key: textFieldKey,
          decoration: const InputDecoration(
            hintText: 'Placeholder',
          ),
          onChanged: (String value) {
            textFieldValue = value;
          },
        ),
      ),
    );

    RenderBox findTextFieldBox() =>
        tester.renderObject(find.byKey(textFieldKey));

    final RenderBox inputBox = findTextFieldBox();
    final Size emptyInputSize = inputBox.size;

    Future<void> checkText(String testValue) async {
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(MongolTextField), testValue);
        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));
        await skipPastScrollingAnimation(tester);
      });
    }

    await checkText(' ');

    expect(findTextFieldBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    await checkText('Test');
    expect(findTextFieldBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));
  });

  testMongolWidgets('Cursor blinks', (tester) async {
    await tester.pumpWidget(
      overlay(
        child: const MongolTextField(
          decoration: InputDecoration(
            hintText: 'Placeholder',
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(MongolTextField));

    final MongolEditableTextState editableText =
        tester.state(find.byType(MongolEditableText));

    // Check that the cursor visibility toggles after each blink interval.
    Future<void> checkCursorToggle() async {
      final bool initialShowCursor = editableText.cursorCurrentlyVisible;
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval ~/ 10);
      expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
    }

    await checkCursorToggle();
    await tester.showKeyboard(find.byType(MongolTextField));

    // Try the test again with a nonempty EditableText.
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'X',
      selection: TextSelection.collapsed(offset: 1),
    ));
    await checkCursorToggle();
  });

  testMongolWidgets('Cursor animates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MongolTextField(),
        ),
      ),
    );

    final Finder textFinder = find.byType(MongolTextField);
    await tester.tap(textFinder);
    await tester.pump();

    final MongolEditableTextState editableTextState =
        tester.firstState(find.byType(MongolEditableText));
    final MongolRenderEditable renderEditable =
        editableTextState.renderEditable;

    expect(renderEditable.cursorColor!.alpha, 255);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(renderEditable.cursorColor!.alpha, 255);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 100));

    expect(renderEditable.cursorColor!.alpha, 110);

    await tester.pump(const Duration(milliseconds: 100));

    expect(renderEditable.cursorColor!.alpha, 16);
    await tester.pump(const Duration(milliseconds: 50));

    expect(renderEditable.cursorColor!.alpha, 0);
  },
      variant: const TargetPlatformVariant(
          <TargetPlatform>{TargetPlatform.iOS, TargetPlatform.macOS}));

  testMongolWidgets('Cursor radius is 2.0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MongolTextField(),
        ),
      ),
    );

    final MongolEditableTextState editableTextState =
        tester.firstState(find.byType(MongolEditableText));
    final MongolRenderEditable renderEditable =
        editableTextState.renderEditable;

    expect(renderEditable.cursorRadius, const Radius.circular(2.0));
  },
      variant: const TargetPlatformVariant(
          <TargetPlatform>{TargetPlatform.iOS, TargetPlatform.macOS}));

  testMongolWidgets('cursor has expected defaults', (tester) async {
    await tester.pumpWidget(
      overlay(
        child: const MongolTextField(),
      ),
    );

    final MongolTextField textField =
        tester.firstWidget(find.byType(MongolTextField));
    expect(textField.cursorHeight, 2.0);
    expect(textField.cursorWidth, null);
    expect(textField.cursorRadius, null);
  });

  testMongolWidgets('cursor has expected radius value', (tester) async {
    await tester.pumpWidget(
      overlay(
        child: const MongolTextField(
          cursorRadius: Radius.circular(3.0),
        ),
      ),
    );

    final MongolTextField textField =
        tester.firstWidget(find.byType(MongolTextField));
    expect(textField.cursorHeight, 2.0);
    expect(textField.cursorRadius, const Radius.circular(3.0));
  });

  // testMongolWidgets('Material cursor android golden', (tester) async {
  //   final Widget widget = overlay(
  //     child: const RepaintBoundary(
  //       key: ValueKey<int>(1),
  //       child: MongolTextField(
  //         cursorColor: Colors.blue,
  //         cursorHeight: 15,
  //         cursorRadius: Radius.circular(3.0),
  //       ),
  //     ),
  //   );
  //   await tester.pumpWidget(widget);

  //   const String testValue = 'A short phrase';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   await tester.tapAt(textOffsetToPosition(tester, testValue.length));
  //   await tester.pump();

  //   await expectLater(
  //     find.byKey(const ValueKey<int>(1)),
  //     matchesGoldenFile('text_field_cursor_test.material.0.png'),
  //   );
  // });

  // testMongolWidgets('Material cursor golden', (tester) async {
  //   final Widget widget = overlay(
  //     child: const RepaintBoundary(
  //       key: ValueKey<int>(1),
  //       child: MongolTextField(
  //         cursorColor: Colors.blue,
  //         cursorHeight: 15,
  //         cursorRadius: Radius.circular(3.0),
  //       ),
  //     ),
  //   );
  //   await tester.pumpWidget(widget);

  //   const String testValue = 'A short phrase';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   await tester.tapAt(textOffsetToPosition(tester, testValue.length));
  //   await tester.pump();

  //   await expectLater(
  //     find.byKey(const ValueKey<int>(1)),
  //     matchesGoldenFile(
  //       'text_field_cursor_test_${describeEnum(debugDefaultTargetPlatformOverride!).toLowerCase()}.material.1.png',
  //     ),
  //   );
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets('TextInputFormatter gets correct selection value', (tester) async {
  //   late TextEditingValue actualOldValue;
  //   late TextEditingValue actualNewValue;
  //   final FormatEditUpdateCallback callBack = (TextEditingValue oldValue, TextEditingValue newValue) {
  //     actualOldValue = oldValue;
  //     actualNewValue = newValue;
  //   };
  //   final FocusNode focusNode = FocusNode();
  //   final TextEditingController controller = TextEditingController(text: '123');
  //   await tester.pumpWidget(
  //     boilerplate(
  //       child: MongolTextField(
  //         controller: controller,
  //         focusNode: focusNode,
  //         inputFormatters: <TextInputFormatter>[TestFormatter(callBack)],
  //       ),
  //     ),
  //   );

  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pumpAndSettle();

  //   await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
  //   await tester.pumpAndSettle();

  //   expect(
  //     actualOldValue,
  //     const TextEditingValue(
  //       text: '123',
  //       selection: TextSelection.collapsed(offset: 3, affinity: TextAffinity.upstream),
  //     ),
  //   );
  //   expect(
  //     actualNewValue,
  //     const TextEditingValue(
  //       text: '12',
  //       selection: TextSelection.collapsed(offset: 2),
  //     ),
  //   );
  // });

  // testMongolWidgets('text field selection toolbar renders correctly inside opacity', (tester) async {
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: Container(
  //             width: 100,
  //             height: 100,
  //             child: const Opacity(
  //               opacity: 0.5,
  //               child: MongolTextField(
  //                 decoration: InputDecoration(hintText: 'Placeholder'),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   await tester.showKeyboard(find.byType(MongolTextField));

  //   const String testValue = 'A B C';
  //   tester.testTextInput.updateEditingValue(
  //       const TextEditingValue(
  //         text: testValue
  //       )
  //   );
  //   await tester.pump();

  //   // The selectWordsInRange with SelectionChangedCause.tap seems to be needed to show the toolbar.
  //   // (This is true even if we provide selection parameter to the TextEditingValue above.)
  //   final MongolEditableTextState state = tester.state<EditableTextState>(find.byType(MongolEditableText));
  //   state.renderEditable.selectWordsInRange(from: Offset.zero, cause: SelectionChangedCause.tap);

  //   expect(state.showToolbar(), true);

  //   // This is needed for the AnimatedOpacity to turn from 0 to 1 so the toolbar is visible.
  //   await tester.pumpAndSettle();
  //   await tester.pump(const Duration(seconds: 1));

  //   // Sanity check that the toolbar widget exists.
  //   expect(findMongol.text('Paste'), findsOneWidget);

  //   await expectLater(
  //     // The toolbar exists in the Overlay above the MaterialApp.
  //     find.byType(Overlay),
  //     matchesGoldenFile('text_field_opacity_test.0.png'),
  //   );
  // });

  // testMongolWidgets('text field toolbar options correctly changes options',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //             toolbarOptions: const ToolbarOptions(copy: true),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //   // This tap just puts the cursor somewhere different than where the double
  //   // tap will occur to test that the double tap moves the existing cursor first.
  //   await tester.tapAt(textfieldStart + const Offset(50.0, 9.0));
  //   await tester.pump(const Duration(milliseconds: 500));

  //   await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   // First tap moved the cursor.
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(
  //         offset: 8, affinity: TextAffinity.downstream),
  //   );
  //   await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //   await tester.pump();

  //   // Second tap selects the word around the cursor.
  //   expect(
  //     controller.selection,
  //     const TextSelection(baseOffset: 8, extentOffset: 12),
  //   );

  //   // Selected text shows 'Copy', and not 'Paste', 'Cut', 'Select All'.
  //   expect(findMongol.text('Paste'), findsNothing);
  //   expect(findMongol.text('Copy'), findsOneWidget);
  //   expect(findMongol.text('Cut'), findsNothing);
  //   expect(findMongol.text('Select All'), findsNothing);
  // },
  //   variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
  // );

  // testMongolWidgets('text selection style 1', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure\nhi\nwasssup!',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: RepaintBoundary(
  //             child: Container(
  //               width: 650.0,
  //               height: 600.0,
  //               decoration: const BoxDecoration(
  //                 color: Color(0xff00ff00),
  //               ),
  //               child: Column(
  //                 children: <Widget>[
  //                   MongolTextField(
  //                     key: const Key('field0'),
  //                     controller: controller,
  //                     style: const TextStyle(height: 4, color: Colors.black45),
  //                     toolbarOptions: const ToolbarOptions(copy: true, selectAll: true),
  //                     selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingTop,
  //                     selectionWidthStyle: ui.BoxWidthStyle.max,
  //                     maxLines: 3,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart = tester.getTopLeft(find.byKey(const Key('field0')));

  //   await tester.longPressAt(textfieldStart + const Offset(50.0, 2.0));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await tester.tapAt(textfieldStart + const Offset(100.0, 107.0));
  //   await tester.pump(const Duration(milliseconds: 300));

  //   await expectLater(
  //     find.byType(MaterialApp),
  //     matchesGoldenFile('text_field_golden.TextSelectionStyle.1.png'),
  //   );
  // });

  // testMongolWidgets('text selection style 2', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure\nhi\nwasssup!',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: RepaintBoundary(
  //             child: Container(
  //               width: 650.0,
  //               height: 600.0,
  //               decoration: const BoxDecoration(
  //                 color: Color(0xff00ff00),
  //               ),
  //               child: Column(
  //                 children: <Widget>[
  //                   MongolTextField(
  //                     key: const Key('field0'),
  //                     controller: controller,
  //                     style: const TextStyle(height: 4, color: Colors.black45),
  //                     toolbarOptions: const ToolbarOptions(copy: true, selectAll: true),
  //                     selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingBottom,
  //                     selectionWidthStyle: ui.BoxWidthStyle.tight,
  //                     maxLines: 3,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart = tester.getTopLeft(find.byKey(const Key('field0')));

  //   await tester.longPressAt(textfieldStart + const Offset(50.0, 2.0));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await tester.tapAt(textfieldStart + const Offset(100.0, 107.0));
  //   await tester.pump(const Duration(milliseconds: 300));

  //   await expectLater(
  //     find.byType(MaterialApp),
  //     matchesGoldenFile('text_field_golden.TextSelectionStyle.2.png'),
  //   );
  // });

  // testMongolWidgets('text field toolbar options correctly changes options',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //             toolbarOptions: const ToolbarOptions(copy: true),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //   await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //   await tester.pump(const Duration(milliseconds: 50));

  //   await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //   await tester.pump();

  //   // Selected text shows 'Copy', and not 'Paste', 'Cut', 'Select all'.
  //   expect(findMongol.text('Paste'), findsNothing);
  //   expect(findMongol.text('Copy'), findsOneWidget);
  //   expect(findMongol.text('Cut'), findsNothing);
  //   expect(findMongol.text('Select all'), findsNothing);
  // },
  //   variant: const TargetPlatformVariant(<TargetPlatform>{
  //     TargetPlatform.android,
  //     TargetPlatform.fuchsia,
  //     TargetPlatform.linux,
  //     TargetPlatform.windows,
  //   }),
  // );

  // testMongolWidgets('cursor layout has correct width', (tester) async {
  //   EditableText.debugDeterministicCursor = true;
  //   await tester.pumpWidget(
  //       overlay(
  //         child: const RepaintBoundary(
  //           child: MongolTextField(
  //             cursorWidth: 15.0,
  //           ),
  //         ),
  //       )
  //   );
  //   await tester.enterText(find.byType(MongolTextField), ' ');
  //   await skipPastScrollingAnimation(tester);

  //   await expectLater(
  //     find.byType(MongolTextField),
  //     matchesGoldenFile('text_field_cursor_width_test.0.png'),
  //   );
  //   EditableText.debugDeterministicCursor = false;
  // });

  // testMongolWidgets('cursor layout has correct radius', (tester) async {
  //   EditableText.debugDeterministicCursor = true;
  //   await tester.pumpWidget(
  //       overlay(
  //         child: const RepaintBoundary(
  //           child: MongolTextField(
  //             cursorWidth: 15.0,
  //             cursorRadius: Radius.circular(3.0),
  //           ),
  //         ),
  //       )
  //   );
  //   await tester.enterText(find.byType(MongolTextField), ' ');
  //   await skipPastScrollingAnimation(tester);

  //   await expectLater(
  //     find.byType(MongolTextField),
  //     matchesGoldenFile('text_field_cursor_width_test.1.png'),
  //   );
  //   EditableText.debugDeterministicCursor = false;
  // });

  // testMongolWidgets('cursor layout has correct height', (tester) async {
  //   EditableText.debugDeterministicCursor = true;
  //   await tester.pumpWidget(
  //       overlay(
  //         child: const RepaintBoundary(
  //           child: MongolTextField(
  //             cursorWidth: 15.0,
  //             cursorHeight: 30.0,
  //           ),
  //         ),
  //       )
  //   );
  //   await tester.enterText(find.byType(MongolTextField), ' ');
  //   await skipPastScrollingAnimation(tester);

  //   await expectLater(
  //     find.byType(MongolTextField),
  //     matchesGoldenFile('text_field_cursor_width_test.2.png'),
  //   );
  //   EditableText.debugDeterministicCursor = false;
  // });

  // testMongolWidgets('Overflowing a line with spaces stops the cursor at the end', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: textFieldKey,
  //         controller: controller,
  //         maxLines: null,
  //       ),
  //     ),
  //   );
  //   expect(controller.selection.baseOffset, -1);
  //   expect(controller.selection.extentOffset, -1);

  //   const String testValueOneLine = 'enough text to be exactly at the end of the line.';
  //   await tester.enterText(find.byType(MongolTextField), testValueOneLine);
  //   await skipPastScrollingAnimation(tester);

  //   RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

  //   RenderBox inputBox = findInputBox();
  //   final Size oneLineInputSize = inputBox.size;

  //   await tester.tapAt(textOffsetToPosition(tester, testValueOneLine.length));
  //   await tester.pump();

  //   const String testValueTwoLines = 'enough text to overflow the first line and go to the second';
  //   await tester.enterText(find.byType(MongolTextField), testValueTwoLines);
  //   await skipPastScrollingAnimation(tester);

  //   expect(inputBox, findInputBox());
  //   inputBox = findInputBox();
  //   expect(inputBox.size.width, greaterThan(oneLineInputSize.width));
  //   final Size twoLineInputSize = inputBox.size;

  //   // Enter a string with the same number of characters as testValueTwoLines,
  //   // but where the overflowing part is all spaces. Assert that it only renders
  //   // on one line.
  //   const String testValueSpaces = testValueOneLine + '          ';
  //   expect(testValueSpaces.length, testValueTwoLines.length);
  //   await tester.enterText(find.byType(MongolTextField), testValueSpaces);
  //   await skipPastScrollingAnimation(tester);

  //   expect(inputBox, findInputBox());
  //   inputBox = findInputBox();
  //   expect(inputBox.size.width, oneLineInputSize.width);

  //   // Swapping the final space for a letter causes it to wrap to 2 lines.
  //   const String testValueSpacesOverflow = testValueOneLine + '         a';
  //   expect(testValueSpacesOverflow.length, testValueTwoLines.length);
  //   await tester.enterText(find.byType(MongolTextField), testValueSpacesOverflow);
  //   await skipPastScrollingAnimation(tester);

  //   expect(inputBox, findInputBox());
  //   inputBox = findInputBox();
  //   expect(inputBox.size.width, twoLineInputSize.width);

  //   // Positioning the cursor at the end of a line overflowing with spaces puts
  //   // it inside the input still.
  //   await tester.enterText(find.byType(MongolTextField), testValueSpaces);
  //   await skipPastScrollingAnimation(tester);
  //   await tester.tapAt(textOffsetToPosition(tester, testValueSpaces.length));
  //   await tester.pump();

  //   final double inputHeight = findRenderEditable(tester).size.height;
  //   final Offset cursorOffsetSpaces = findRenderEditable(tester).getLocalRectForCaret(
  //     const TextPosition(offset: testValueSpaces.length),
  //   ).bottomRight;

  //   expect(cursorOffsetSpaces.dy, inputHeight - kCaretGap);
  // });

  testMongolWidgets('mobile obscureText control test', (tester) async {
    await tester.pumpWidget(
      overlay(
        child: const MongolTextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Placeholder',
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(MongolTextField));

    const String testValue = 'ABC';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue,
      selection: TextSelection.collapsed(offset: testValue.length),
    ));

    await tester.pump();

    // Enter a character into the obscured field and verify that the character
    // is temporarily shown to the user and then changed to a bullet.
    const String newChar = 'X';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue + newChar,
      selection: TextSelection.collapsed(offset: testValue.length + 1),
    ));

    await tester.pump();

    String editText = findRenderEditable(tester).text!.text!;
    expect(editText.substring(editText.length - 1), newChar);

    await tester.pump(const Duration(seconds: 2));

    editText = findRenderEditable(tester).text!.text!;
    expect(editText.substring(editText.length - 1), '\u2022');
  },
      variant: const TargetPlatformVariant(
          <TargetPlatform>{TargetPlatform.iOS, TargetPlatform.android}));

  testMongolWidgets('desktop obscureText control test', (tester) async {
    await tester.pumpWidget(
      overlay(
        child: const MongolTextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Placeholder',
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(MongolTextField));

    const String testValue = 'ABC';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue,
      selection: TextSelection.collapsed(offset: testValue.length),
    ));

    await tester.pump();

    // Enter a character into the obscured field and verify that the character
    // isn't shown to the user.
    const String newChar = 'X';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue + newChar,
      selection: TextSelection.collapsed(offset: testValue.length + 1),
    ));

    await tester.pump();

    final String editText = findRenderEditable(tester).text!.text!;
    expect(editText.substring(editText.length - 1), '\u2022');
  },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
      }));

  testMongolWidgets('Caret position is updated on tap', (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          controller: controller,
        ),
      ),
    );
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(MongolTextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Tap to reposition the caret.
    final int tapIndex = testValue.indexOf('e');
    final Offset ePos = textOffsetToPosition(tester, tapIndex);
    await tester.tapAt(ePos);
    await tester.pump();

    expect(controller.selection.baseOffset, tapIndex);
    expect(controller.selection.extentOffset, tapIndex);
  });

  testMongolWidgets('enableInteractiveSelection = false, tap', (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          controller: controller,
          enableInteractiveSelection: false,
        ),
      ),
    );
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(MongolTextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Tap would ordinarily reposition the caret.
    final int tapIndex = testValue.indexOf('e');
    final Offset ePos = textOffsetToPosition(tester, tapIndex);
    await tester.tapAt(ePos);
    await tester.pump();

    expect(controller.selection.baseOffset, testValue.length);
    expect(controller.selection.isCollapsed, isTrue);
  });

  testMongolWidgets('Can long press to select', (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(MongolTextField), testValue);
    expect(controller.value.text, testValue);
    await skipPastScrollingAnimation(tester);

    expect(controller.selection.isCollapsed, true);

    // Long press the 'e' to select 'def'.
    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    await tester.longPressAt(ePos, pointer: 7);
    await tester.pump();

    // 'def' is selected.
    expect(controller.selection.baseOffset, testValue.indexOf('d'));
    expect(controller.selection.extentOffset, testValue.indexOf('f') + 1);

    // Tapping elsewhere immediately collapses and moves the cursor.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('h')));
    await tester.pump();

    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, testValue.indexOf('h'));
  });

  testMongolWidgets("Slight movements in longpress don't hide/show handles",
      (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(MongolTextField), testValue);
    expect(controller.value.text, testValue);
    await skipPastScrollingAnimation(tester);

    expect(controller.selection.isCollapsed, true);

    // Long press the 'e' to select 'def', but don't release the gesture.
    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    final TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Handles are shown
    final Finder fadeFinder = find.byType(FadeTransition);
    expect(fadeFinder, findsNWidgets(2)); // 2 handles, 1 toolbar
    FadeTransition handle = tester.widget(fadeFinder.at(0));
    expect(handle.opacity.value, equals(1.0));

    // Move the gesture very slightly
    await gesture.moveBy(const Offset(1.0, 1.0));
    await tester.pump(TextSelectionOverlay.fadeDuration * 0.5);
    handle = tester.widget(fadeFinder.at(0));

    // The handle should still be fully opaque.
    expect(handle.opacity.value, equals(1.0));
  });

  // testMongolWidgets('Long pressing a field with selection 0,0 shows the selection menu', (tester) async {
  //   await tester.pumpWidget(overlay(
  //     child: MongolTextField(
  //       controller: TextEditingController.fromValue(
  //         const TextEditingValue(
  //           selection: TextSelection(baseOffset: 0, extentOffset: 0),
  //         ),
  //       ),
  //     ),
  //   ));

  //   expect(findMongol.text('Paste'), findsNothing);
  //   final Offset emptyPos = textOffsetToPosition(tester, 0);
  //   await tester.longPressAt(emptyPos, pointer: 7);
  //   await tester.pumpAndSettle();
  //   expect(findMongol.text('Paste'), findsOneWidget);
  // });

  testMongolWidgets('Entering text hides selection handle caret',
      (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abcdefghi';
    await tester.enterText(find.byType(MongolTextField), testValue);
    expect(controller.value.text, testValue);
    await skipPastScrollingAnimation(tester);

    // Handle not shown.
    expect(controller.selection.isCollapsed, true);
    final Finder fadeFinder = find.byType(FadeTransition);
    expect(fadeFinder, findsNothing);

    // Tap on the text field to show the handle.
    await tester.tap(find.byType(MongolTextField));
    await tester.pumpAndSettle();
    expect(controller.selection.isCollapsed, true);
    expect(fadeFinder, findsNWidgets(1));
    final FadeTransition handle = tester.widget(fadeFinder.at(0));
    expect(handle.opacity.value, equals(1.0));

    // Enter more text.
    const String testValueAddition = 'jklmni';
    await tester.enterText(find.byType(MongolTextField), testValueAddition);
    expect(controller.value.text, testValueAddition);
    await skipPastScrollingAnimation(tester);

    // Handle not shown.
    expect(controller.selection.isCollapsed, true);
    expect(fadeFinder, findsNothing);
  });

  testMongolWidgets('Mouse long press is just like a tap', (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(MongolTextField), testValue);
    expect(controller.value.text, testValue);
    await skipPastScrollingAnimation(tester);

    expect(controller.selection.isCollapsed, true);

    // Long press the 'e' using a mouse device.
    final int eIndex = testValue.indexOf('e');
    final Offset ePos = textOffsetToPosition(tester, eIndex);
    final TestGesture gesture =
        await tester.startGesture(ePos, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    // The cursor is placed just like a regular tap.
    expect(controller.selection.baseOffset, eIndex);
    expect(controller.selection.extentOffset, eIndex);
  });

  // testMongolWidgets('Read only text field basic', (tester) async {
  //   final TextEditingController controller =
  //       TextEditingController(text: 'readonly');

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         controller: controller,
  //         readOnly: true,
  //       ),
  //     ),
  //   );
  //   // Read only text field cannot open keyboard.
  //   await tester.showKeyboard(find.byType(MongolTextField));
  //   expect(tester.testTextInput.hasAnyClients, false);
  //   await skipPastScrollingAnimation(tester);

  //   expect(controller.selection.isCollapsed, true);

  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pump();
  //   expect(tester.testTextInput.hasAnyClients, false);
  //   final MongolEditableTextState editableText =
  //       tester.state(find.byType(MongolEditableText));
  //   // Collapse selection should not paint.
  //   expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
  //   // Long press on the 'd' character of text 'readOnly' to show context menu.
  //   const int dIndex = 3;
  //   final Offset dPos = textOffsetToPosition(tester, dIndex);
  //   await tester.longPressAt(dPos);
  //   await tester.pumpAndSettle();

  //   // Context menu should not have paste and cut.
  //   expect(find.text('Copy'), findsOneWidget);
  //   expect(find.text('Paste'), findsNothing);
  //   expect(find.text('Cut'), findsNothing);
  // });

  // testMongolWidgets('does not paint toolbar when no options available', (tester) async {
  //   await tester.pumpWidget(
  //       const MaterialApp(
  //         home: Material(
  //           child: MongolTextField(
  //             readOnly: true,
  //           ),
  //         ),
  //       ),
  //   );

  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pump(const Duration(milliseconds: 50));

  //   await tester.tap(find.byType(MongolTextField));
  //   // Wait for context menu to be built.
  //   await tester.pumpAndSettle();

  //   expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testMongolWidgets('text field build empty toolbar when no options available',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MongolTextField(
            readOnly: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MongolTextField));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(MongolTextField));
    // Wait for context menu to be built.
    await tester.pumpAndSettle();
    final RenderBox container = tester.renderObject(find
        .descendant(
          of: find.byType(FadeTransition),
          matching: find.byType(SizedBox),
        )
        .first);
    expect(container.size, Size.zero);
  },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.fuchsia,
        TargetPlatform.linux,
        TargetPlatform.windows
      }));

  testMongolWidgets('Swaping controllers should update selection',
      (tester) async {
    TextEditingController controller = TextEditingController(text: 'readonly');
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: MongolTextField(
              controller: controller,
              readOnly: true,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    const int dIndex = 3;
    final Offset dPos = textOffsetToPosition(tester, dIndex);
    await tester.longPressAt(dPos);
    await tester.pumpAndSettle();
    final MongolEditableTextState state =
        tester.state(find.byType(MongolEditableText));
    TextSelection currentOverlaySelection =
        state.selectionOverlay!.value.selection;
    expect(currentOverlaySelection.baseOffset, 0);
    expect(currentOverlaySelection.extentOffset, 8);

    // Update selection from [0 to 8] to [1 to 7].
    controller = TextEditingController.fromValue(
      controller.value.copyWith(
          selection: const TextSelection(
        baseOffset: 1,
        extentOffset: 7,
      )),
    );

    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();

    await tester.pump();
    currentOverlaySelection = state.selectionOverlay!.value.selection;
    expect(currentOverlaySelection.baseOffset, 1);
    expect(currentOverlaySelection.extentOffset, 7);
  });

  testMongolWidgets('Read only text should not compose', (tester) async {
    final TextEditingController controller = TextEditingController.fromValue(
      const TextEditingValue(
        text: 'readonly',
        composing: TextRange(start: 0, end: 8), // Simulate text composing.
      ),
    );

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          controller: controller,
          readOnly: true,
        ),
      ),
    );

    final MongolRenderEditable renderEditable = findRenderEditable(tester);
    // There should be no composing.
    expect(renderEditable.text,
        TextSpan(text: 'readonly', style: renderEditable.text!.style));
  });

  testMongolWidgets(
      'Dynamically switching between read only and not read only should hide or show collapse cursor',
      (tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'readonly');
    bool readOnly = true;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: MongolTextField(
              controller: controller,
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    await tester.tap(find.byType(MongolTextField));
    await tester.pump();

    final MongolEditableTextState editableText =
        tester.state(find.byType(MongolEditableText));
    // Collapse selection should not paint.
    expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);

    readOnly = false;
    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();
    await tester.pumpAndSettle();
    expect(editableText.selectionOverlay!.handlesAreVisible, isTrue);

    readOnly = true;
    entry.markNeedsBuild();
    await tester.pumpAndSettle();
    expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
  });

  testMongolWidgets(
      'Dynamically switching to read only should close input connection',
      (tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'readonly');
    bool readOnly = false;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: MongolTextField(
              controller: controller,
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    await tester.tap(find.byType(MongolTextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, true);

    readOnly = true;
    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);
  });

  testMongolWidgets(
      'Dynamically switching to non read only should open input connection',
      (tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'readonly');
    bool readOnly = true;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: MongolTextField(
              controller: controller,
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    await tester.tap(find.byType(MongolTextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);

    readOnly = false;
    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, true);
  });

  // testMongolWidgets('enableInteractiveSelection = false, long-press',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         controller: controller,
  //         enableInteractiveSelection: false,
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   expect(controller.value.text, testValue);
  //   await skipPastScrollingAnimation(tester);

  //   expect(controller.selection.isCollapsed, true);

  //   // Long press the 'e' to select 'def'.
  //   final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
  //   await tester.longPressAt(ePos, pointer: 7);
  //   await tester.pump();

  //   expect(controller.selection.isCollapsed, true);
  //   expect(controller.selection.baseOffset, -1);
  //   expect(controller.selection.extentOffset, -1);
  // });

  // // TODO: This one is probably important to make work
  // testMongolWidgets('Can select text by dragging with a mouse', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           dragStartBehavior: DragStartBehavior.down,
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
  //   final Offset gPos = textOffsetToPosition(tester, testValue.indexOf('g'));

  //   final TestGesture gesture = await tester.startGesture(ePos, kind: PointerDeviceKind.mouse);
  //   addTearDown(gesture.removePointer);
  //   await tester.pump();
  //   await gesture.moveTo(gPos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();

  //   expect(controller.selection.baseOffset, testValue.indexOf('e'));
  //   expect(controller.selection.extentOffset, testValue.indexOf('g'));
  // });

  // // TODO: This one is probably important to make work
  // testMongolWidgets('Continuous dragging does not cause flickering', (tester) async {
  //   int selectionChangedCount = 0;
  //   const String testValue = 'abc def ghi';
  //   final TextEditingController controller = TextEditingController(text: testValue);

  //   controller.addListener(() {
  //     selectionChangedCount++;
  //   });

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           dragStartBehavior: DragStartBehavior.down,
  //           controller: controller,
  //           style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset cPos = textOffsetToPosition(tester, 2); // Index of 'c'.
  //   final Offset gPos = textOffsetToPosition(tester, 8); // Index of 'g'.
  //   final Offset hPos = textOffsetToPosition(tester, 9); // Index of 'h'.

  //   // Drag from 'c' to 'g'.
  //   final TestGesture gesture = await tester.startGesture(cPos, kind: PointerDeviceKind.mouse);
  //   addTearDown(gesture.removePointer);
  //   await tester.pump();
  //   await gesture.moveTo(gPos);
  //   await tester.pumpAndSettle();

  //   expect(selectionChangedCount, isNonZero);
  //   selectionChangedCount = 0;
  //   expect(controller.selection.baseOffset, 2);
  //   expect(controller.selection.extentOffset, 8);

  //   // Tiny movement shouldn't cause text selection to change.
  //   await gesture.moveTo(gPos + const Offset(4.0, 0.0));
  //   await tester.pumpAndSettle();
  //   expect(selectionChangedCount, 0);

  //   // Now a text selection change will occur after a significant movement.
  //   await gesture.moveTo(hPos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();

  //   expect(selectionChangedCount, 1);
  //   expect(controller.selection.baseOffset, 2);
  //   expect(controller.selection.extentOffset, 9);
  // });

  // // TODO: This one is probably important to make work
  // testMongolWidgets('Dragging in opposite direction also works', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           dragStartBehavior: DragStartBehavior.down,
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
  //   final Offset gPos = textOffsetToPosition(tester, testValue.indexOf('g'));

  //   final TestGesture gesture = await tester.startGesture(gPos, kind: PointerDeviceKind.mouse);
  //   addTearDown(gesture.removePointer);
  //   await tester.pump();
  //   await gesture.moveTo(ePos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();

  //   expect(controller.selection.baseOffset, testValue.indexOf('g'));
  //   expect(controller.selection.extentOffset, testValue.indexOf('e'));
  // });

  // testMongolWidgets('Slow mouse dragging also selects text', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           dragStartBehavior: DragStartBehavior.down,
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
  //   final Offset gPos = textOffsetToPosition(tester, testValue.indexOf('g'));

  //   final TestGesture gesture = await tester.startGesture(ePos, kind: PointerDeviceKind.mouse);
  //   addTearDown(gesture.removePointer);
  //   await tester.pump(const Duration(seconds: 2));
  //   await gesture.moveTo(gPos);
  //   await tester.pump();
  //   await gesture.up();

  //   expect(controller.selection.baseOffset, testValue.indexOf('e'));
  //   expect(controller.selection.extentOffset, testValue.indexOf('g'));
  // });

  // testMongolWidgets('Can drag handles to change selection', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         dragStartBehavior: DragStartBehavior.down,
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   // Long press the 'e' to select 'def'.
  //   final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
  //   TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
  //   await tester.pump(const Duration(seconds: 2));
  //   await gesture.up();
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

  //   final TextSelection selection = controller.selection;
  //   expect(selection.baseOffset, 4);
  //   expect(selection.extentOffset, 7);

  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(selection),
  //     renderEditable,
  //   );
  //   expect(endpoints.length, 2);

  //   // Drag the right handle 2 letters to the right.
  //   // We use a small offset because the endpoint is on the very corner
  //   // of the handle.
  //   Offset handlePos = endpoints[1].point + const Offset(1.0, 1.0);
  //   Offset newHandlePos = textOffsetToPosition(tester, testValue.length);
  //   gesture = await tester.startGesture(handlePos, pointer: 7);
  //   await tester.pump();
  //   await gesture.moveTo(newHandlePos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump();

  //   expect(controller.selection.baseOffset, 4);
  //   expect(controller.selection.extentOffset, 11);

  //   // Drag the left handle 2 letters to the left.
  //   handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
  //   newHandlePos = textOffsetToPosition(tester, 0);
  //   gesture = await tester.startGesture(handlePos, pointer: 7);
  //   await tester.pump();
  //   await gesture.moveTo(newHandlePos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump();

  //   expect(controller.selection.baseOffset, 0);
  //   expect(controller.selection.extentOffset, 11);
  // });

  // testMongolWidgets('Cannot drag one handle past the other', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         dragStartBehavior: DragStartBehavior.down,
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   // Long press the 'e' to select 'def'.
  //   final Offset ePos = textOffsetToPosition(tester, 5); // Position before 'e'.
  //   TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
  //   await tester.pump(const Duration(seconds: 2));
  //   await gesture.up();
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

  //   final TextSelection selection = controller.selection;
  //   expect(selection.baseOffset, 4);
  //   expect(selection.extentOffset, 7);

  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(selection),
  //     renderEditable,
  //   );
  //   expect(endpoints.length, 2);

  //   // Drag the right handle until there's only 1 char selected.
  //   // We use a small offset because the endpoint is on the very corner
  //   // of the handle.
  //   final Offset handlePos = endpoints[1].point + const Offset(4.0, 0.0);
  //   Offset newHandlePos = textOffsetToPosition(tester, 5); // Position before 'e'.
  //   gesture = await tester.startGesture(handlePos, pointer: 7);
  //   await tester.pump();
  //   await gesture.moveTo(newHandlePos);
  //   await tester.pump();

  //   expect(controller.selection.baseOffset, 4);
  //   expect(controller.selection.extentOffset, 5);

  //   newHandlePos = textOffsetToPosition(tester, 2); // Position before 'c'.
  //   await gesture.moveTo(newHandlePos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump();

  //   expect(controller.selection.baseOffset, 4);
  //   // The selection doesn't move beyond the left handle. There's always at
  //   // least 1 char selected.
  //   expect(controller.selection.extentOffset, 5);
  // });

  // testMongolWidgets('Can use selection toolbar', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   // Tap the selection handle to bring up the "paste / select all" menu.
  //   await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
  //   await tester.pump();
  //   await tester.pump(const Duration(
  //       milliseconds: 200)); // skip past the frame where the opacity is zero
  //   MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(controller.selection),
  //     renderEditable,
  //   );
  //   // Tapping on the part of the handle's GestureDetector where it overlaps
  //   // with the text itself does not show the menu, so add a small vertical
  //   // offset to tap below the text.
  //   await tester.tapAt(endpoints[0].point + const Offset(1.0, 13.0));
  //   await tester.pump();
  //   await tester.pump(const Duration(
  //       milliseconds: 200)); // skip past the frame where the opacity is zero

  //   // Select all should select all the text.
  //   await tester.tap(find.text('Select all'));
  //   await tester.pump();
  //   expect(controller.selection.baseOffset, 0);
  //   expect(controller.selection.extentOffset, testValue.length);

  //   // Copy should reset the selection.
  //   await tester.tap(find.text('Copy'));
  //   await skipPastScrollingAnimation(tester);
  //   expect(controller.selection.isCollapsed, true);

  //   // Tap again to bring back the menu.
  //   await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
  //   await tester.pump();
  //   // Allow time for handle to appear and double tap to time out.
  //   await tester.pump(const Duration(milliseconds: 300));
  //   expect(controller.selection.isCollapsed, true);
  //   expect(controller.selection.baseOffset, testValue.indexOf('e'));
  //   expect(controller.selection.extentOffset, testValue.indexOf('e'));
  //   renderEditable = findRenderEditable(tester);
  //   endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(controller.selection),
  //     renderEditable,
  //   );
  //   await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
  //   await tester.pump();
  //   await tester.pump(const Duration(
  //       milliseconds: 200)); // skip past the frame where the opacity is zero
  //   expect(controller.selection.isCollapsed, true);
  //   expect(controller.selection.baseOffset, testValue.indexOf('e'));
  //   expect(controller.selection.extentOffset, testValue.indexOf('e'));

  //   // Paste right before the 'e'.
  //   await tester.tap(find.text('Paste'));
  //   await tester.pump();
  //   expect(controller.text, 'abc d${testValue}ef ghi');
  // });

  // Show the selection menu at the given index into the text by tapping to
  // place the cursor and then tapping on the handle.
  Future<void> _showSelectionMenuAt(MongolWidgetTester tester,
      TextEditingController controller, int index) async {
    await tester.tapAt(tester.getCenter(find.byType(MongolEditableText)));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds: 200)); // skip past the frame where the opacity is zero
    expect(find.text('Select all'), findsNothing);

    // Tap the selection handle to bring up the "paste / select all" menu for
    // the last line of text.
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds: 200)); // skip past the frame where the opacity is zero
    final MongolRenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    // Tapping on the part of the handle's GestureDetector where it overlaps
    // with the text itself does not show the menu, so add a small vertical
    // offset to tap below the text.
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 13.0));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds: 200)); // skip past the frame where the opacity is zero
  }

  // testMongolWidgets(
  //   'Check the toolbar appears below the MongolTextField when there is not enough space above the MongolTextField to show it',
  //   (tester) async {
  //     // This is a regression test for
  //     // https://github.com/flutter/flutter/issues/29808
  //     final TextEditingController controller = TextEditingController();

  //     await tester.pumpWidget(MaterialApp(
  //       home: Scaffold(
  //         body: Padding(
  //           padding: const EdgeInsets.all(30.0),
  //           child: MongolTextField(
  //             controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     const String testValue = 'abc def ghi';
  //     await tester.enterText(find.byType(MongolTextField), testValue);
  //     await skipPastScrollingAnimation(tester);

  //     await _showSelectionMenuAt(tester, controller, testValue.indexOf('e'));

  //     // Verify the selection toolbar position is below the text.
  //     Offset toolbarTopLeft = tester.getTopLeft(findMongol.text('Select all'));
  //     Offset textFieldTopLeft = tester.getTopLeft(find.byType(MongolTextField));
  //     expect(textFieldTopLeft.dy, lessThan(toolbarTopLeft.dy));

  //     await tester.pumpWidget(MaterialApp(
  //       home: Scaffold(
  //         body: Padding(
  //           padding: const EdgeInsets.all(150.0),
  //           child: MongolTextField(
  //             controller: controller,
  //           ),
  //         ),
  //       ),
  //     ));

  //     await tester.enterText(find.byType(MongolTextField), testValue);
  //     await skipPastScrollingAnimation(tester);

  //     await _showSelectionMenuAt(tester, controller, testValue.indexOf('e'));

  //     // Verify the selection toolbar position
  //     toolbarTopLeft = tester.getTopLeft(findMongol.text('Select all'));
  //     textFieldTopLeft = tester.getTopLeft(find.byType(MongolTextField));
  //     expect(toolbarTopLeft.dy, lessThan(textFieldTopLeft.dy));
  //   },
  // );

  // testMongolWidgets(
  //   'Toolbar appears in the right places in multiline inputs',
  //   (tester) async {
  //     // This is a regression test for
  //     // https://github.com/flutter/flutter/issues/36749
  //     final TextEditingController controller = TextEditingController();

  //     await tester.pumpWidget(MaterialApp(
  //       home: Scaffold(
  //         body: Padding(
  //           padding: const EdgeInsets.all(30.0),
  //           child: MongolTextField(
  //             controller: controller,
  //             minLines: 6,
  //             maxLines: 6,
  //           ),
  //         ),
  //       ),
  //     ));

  //     expect(findMongol.text('Select all'), findsNothing);
  //     const String testValue = 'abc\ndef\nghi\njkl\nmno\npqr';
  //     await tester.enterText(find.byType(MongolTextField), testValue);
  //     await skipPastScrollingAnimation(tester);

  //     // Show the selection menu on the first line and verify the selection
  //     // toolbar position is below the first line.
  //     await _showSelectionMenuAt(tester, controller, testValue.indexOf('c'));
  //     expect(findMongol.text('Select all'), findsOneWidget);
  //     final Offset firstLineToolbarTopLeft = tester.getTopLeft(findMongol.text('Select all'));
  //     final Offset firstLineTopLeft = textOffsetToPosition(tester, testValue.indexOf('a'));
  //     expect(firstLineTopLeft.dy, lessThan(firstLineToolbarTopLeft.dy));

  //     // Show the selection menu on the second to last line and verify the
  //     // selection toolbar position is above that line and above the first
  //     // line's toolbar.
  //     await _showSelectionMenuAt(tester, controller, testValue.indexOf('o'));
  //     expect(findMongol.text('Select all'), findsOneWidget);
  //     final Offset penultimateLineToolbarTopLeft = tester.getTopLeft(findMongol.text('Select all'));
  //     final Offset penultimateLineTopLeft = textOffsetToPosition(tester, testValue.indexOf('p'));
  //     expect(penultimateLineToolbarTopLeft.dy, lessThan(penultimateLineTopLeft.dy));
  //     expect(penultimateLineToolbarTopLeft.dy, lessThan(firstLineToolbarTopLeft.dy));

  //     // Show the selection menu on the last line and verify the selection
  //     // toolbar position is above that line and below the position of the
  //     // second to last line's toolbar.
  //     await _showSelectionMenuAt(tester, controller, testValue.indexOf('r'));
  //     expect(findMongol.text('Select all'), findsOneWidget);
  //     final Offset lastLineToolbarTopLeft = tester.getTopLeft(findMongol.text('Select all'));
  //     final Offset lastLineTopLeft = textOffsetToPosition(tester, testValue.indexOf('p'));
  //     expect(lastLineToolbarTopLeft.dy, lessThan(lastLineTopLeft.dy));
  //     expect(lastLineToolbarTopLeft.dy, greaterThan(penultimateLineToolbarTopLeft.dy));
  //   },
  // );

  // testMongolWidgets('Selection toolbar fades in', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   const String testValue = 'abc def ghi';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   // Tap the selection handle to bring up the "paste / select all" menu.
  //   await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
  //   await tester.pump();
  //   // Allow time for the handle to appear and for a double tap to time out.
  //   await tester.pump(const Duration(milliseconds: 600));
  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(controller.selection),
  //     renderEditable,
  //   );
  //   await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
  //   // Pump an extra frame to allow the selection menu to read the clipboard.
  //   await tester.pump();
  //   await tester.pump();

  //   // Toolbar should fade in. Starting at 0% opacity.
  //   final Element target = tester.element(find.text('Select all'));
  //   final FadeTransition opacity =
  //       target.findAncestorWidgetOfExactType<FadeTransition>()!;
  //   expect(opacity.opacity.value, equals(0.0));

  //   // Still fading in.
  //   await tester.pump(const Duration(milliseconds: 50));
  //   final FadeTransition opacity2 =
  //       target.findAncestorWidgetOfExactType<FadeTransition>()!;
  //   expect(opacity, same(opacity2));
  //   expect(opacity.opacity.value, greaterThan(0.0));
  //   expect(opacity.opacity.value, lessThan(1.0));

  //   // End the test here to ensure the animation is properly disposed of.
  // });

  testMongolWidgets('An obscured MongolTextField is selectable by default',
      (tester) async {
    // This is a regression test for
    // https://github.com/flutter/flutter/issues/32845

    final TextEditingController controller = TextEditingController();
    Widget buildFrame(bool obscureText) {
      return overlay(
        child: MongolTextField(
          controller: controller,
          obscureText: obscureText,
        ),
      );
    }

    // Obscure text and don't enable or disable selection.
    await tester.pumpWidget(buildFrame(true));
    await tester.enterText(find.byType(MongolTextField), 'abcdefghi');
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.isCollapsed, true);

    // Long press does select text.
    final Offset ePos = textOffsetToPosition(tester, 1);
    await tester.longPressAt(ePos, pointer: 7);
    await tester.pump();
    expect(controller.selection.isCollapsed, false);
  });

  testMongolWidgets(
      'An obscured MongolTextField is not selectable when disabled',
      (tester) async {
    // This is a regression test for
    // https://github.com/flutter/flutter/issues/32845

    final TextEditingController controller = TextEditingController();
    Widget buildFrame(bool obscureText, bool enableInteractiveSelection) {
      return overlay(
        child: MongolTextField(
          controller: controller,
          obscureText: obscureText,
          enableInteractiveSelection: enableInteractiveSelection,
        ),
      );
    }

    // Explicitly disabled selection on obscured text.
    await tester.pumpWidget(buildFrame(true, false));
    await tester.enterText(find.byType(MongolTextField), 'abcdefghi');
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.isCollapsed, true);

    // Long press doesn't select text.
    final Offset ePos2 = textOffsetToPosition(tester, 1);
    await tester.longPressAt(ePos2, pointer: 7);
    await tester.pump();
    expect(controller.selection.isCollapsed, true);
  });

  testMongolWidgets('An obscured MongolTextField is selected as one word',
      (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(overlay(
      child: MongolTextField(
        controller: controller,
        obscureText: true,
      ),
    ));
    await tester.enterText(find.byType(MongolTextField), 'abcde fghi');
    await skipPastScrollingAnimation(tester);

    // Long press does select text.
    final Offset bPos = textOffsetToPosition(tester, 1);
    await tester.longPressAt(bPos, pointer: 7);
    await tester.pump();
    final TextSelection selection = controller.selection;
    expect(selection.isCollapsed, false);
    expect(selection.baseOffset, 0);
    expect(selection.extentOffset, 10);
  });

  // testMongolWidgets(
  //     'An obscured MongolTextField has correct default context menu',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(overlay(
  //     child: MongolTextField(
  //       controller: controller,
  //       obscureText: true,
  //     ),
  //   ));
  //   await tester.enterText(find.byType(MongolTextField), 'abcde fghi');
  //   await skipPastScrollingAnimation(tester);

  //   // Long press to select text.
  //   final Offset bPos = textOffsetToPosition(tester, 1);
  //   await tester.longPressAt(bPos, pointer: 7);
  //   await tester.pumpAndSettle();

  //   // Should only have paste option when whole obscure text is selected.
  //   expect(find.text('Paste'), findsOneWidget);
  //   expect(find.text('Copy'), findsNothing);
  //   expect(find.text('Cut'), findsNothing);
  //   expect(find.text('Select all'), findsNothing);

  //   // Long press at the end
  //   final Offset iPos = textOffsetToPosition(tester, 10);
  //   final Offset slightRight = iPos + const Offset(0.0, 30.0);
  //   await tester.longPressAt(slightRight, pointer: 7);
  //   await tester.pumpAndSettle();

  //   // Should have paste and select all options when collapse.
  //   expect(find.text('Paste'), findsOneWidget);
  //   expect(find.text('Select all'), findsOneWidget);
  //   expect(find.text('Copy'), findsNothing);
  //   expect(find.text('Cut'), findsNothing);
  // });

  // testMongolWidgets('MongolTextField height with minLines unset', (tester) async {
  //   await tester.pumpWidget(textFieldBuilder());

  //   RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

  //   final RenderBox inputBox = findInputBox();
  //   final Size emptyInputSize = inputBox.size;

  //   await tester.enterText(find.byType(MongolTextField), 'No wrapping here.');
  //   await tester.pumpWidget(textFieldBuilder());
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, equals(emptyInputSize));

  //   // Even when entering multiline text, MongolTextField doesn't grow. It's a single
  //   // line input.
  //   await tester.enterText(find.byType(MongolTextField), kThreeLines);
  //   await tester.pumpWidget(textFieldBuilder());
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, equals(emptyInputSize));

  //   // maxLines: 3 makes the MongolTextField 3 lines tall
  //   await tester.enterText(find.byType(MongolTextField), '');
  //   await tester.pumpWidget(textFieldBuilder(maxLines: 3));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size.height, greaterThan(emptyInputSize.height));
  //   expect(inputBox.size.width, emptyInputSize.width);

  //   final Size threeLineInputSize = inputBox.size;

  //   // Filling with 3 lines of text stays the same size
  //   await tester.enterText(find.byType(MongolTextField), kThreeLines);
  //   await tester.pumpWidget(textFieldBuilder(maxLines: 3));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, threeLineInputSize);

  //   // An extra line won't increase the size because we max at 3.
  //   await tester.enterText(find.byType(MongolTextField), kMoreThanFourLines);
  //   await tester.pumpWidget(textFieldBuilder(maxLines: 3));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, threeLineInputSize);

  //   // But now it will... but it will max at four
  //   await tester.enterText(find.byType(MongolTextField), kMoreThanFourLines);
  //   await tester.pumpWidget(textFieldBuilder(maxLines: 4));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size.height, greaterThan(threeLineInputSize.height));
  //   expect(inputBox.size.width, threeLineInputSize.width);

  //   final Size fourLineInputSize = inputBox.size;

  //   // Now it won't max out until the end
  //   await tester.enterText(find.byType(MongolTextField), '');
  //   await tester.pumpWidget(textFieldBuilder(maxLines: null));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, equals(emptyInputSize));
  //   await tester.enterText(find.byType(MongolTextField), kThreeLines);
  //   await tester.pump();
  //   expect(inputBox.size, equals(threeLineInputSize));
  //   await tester.enterText(find.byType(MongolTextField), kMoreThanFourLines);
  //   await tester.pump();
  //   expect(inputBox.size.height, greaterThan(fourLineInputSize.height));
  //   expect(inputBox.size.width, fourLineInputSize.width);
  // });

  // testMongolWidgets('MongolTextField height with minLines and maxLines', (tester) async {
  //   await tester.pumpWidget(textFieldBuilder());

  //   RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

  //   final RenderBox inputBox = findInputBox();
  //   final Size emptyInputSize = inputBox.size;

  //   await tester.enterText(find.byType(MongolTextField), 'No wrapping here.');
  //   await tester.pumpWidget(textFieldBuilder());
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, equals(emptyInputSize));

  //   // min and max set to same value locks height to value.
  //   await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: 3));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size.height, greaterThan(emptyInputSize.height));
  //   expect(inputBox.size.width, emptyInputSize.width);

  //   final Size threeLineInputSize = inputBox.size;

  //   // maxLines: null with minLines set grows beyond minLines
  //   await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: null));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, threeLineInputSize);
  //   await tester.enterText(find.byType(MongolTextField), kMoreThanFourLines);
  //   await tester.pump();
  //   expect(inputBox.size.height, greaterThan(threeLineInputSize.height));
  //   expect(inputBox.size.width, threeLineInputSize.width);

  //   // With minLines and maxLines set, input will expand through the range
  //   await tester.enterText(find.byType(MongolTextField), '');
  //   await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: 4));
  //   expect(findInputBox(), equals(inputBox));
  //   expect(inputBox.size, equals(threeLineInputSize));
  //   await tester.enterText(find.byType(MongolTextField), kMoreThanFourLines);
  //   await tester.pump();
  //   expect(inputBox.size.height, greaterThan(threeLineInputSize.height));
  //   expect(inputBox.size.width, threeLineInputSize.width);

  //   // minLines can't be greater than maxLines.
  //   expect(() async {
  //     await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: 2));
  //   }, throwsAssertionError);

  //   // maxLines defaults to 1 and can't be less than minLines
  //   expect(() async {
  //     await tester.pumpWidget(textFieldBuilder(minLines: 3));
  //   }, throwsAssertionError);
  // });

  // // TODO: this one is probably important to fix
  // testMongolWidgets('Multiline text when wrapped in Expanded', (tester) async {
  //   Widget expandedTextFieldBuilder({
  //     int? maxLines = 1,
  //     int? minLines,
  //     bool expands = false,
  //   }) {
  //     return boilerplate(
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           Expanded(
  //             child: MongolTextField(
  //               key: textFieldKey,
  //               style: const TextStyle(color: Colors.black, fontSize: 34.0),
  //               maxLines: maxLines,
  //               minLines: minLines,
  //               expands: expands,
  //               decoration: const InputDecoration(
  //                 hintText: 'Placeholder',
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(expandedTextFieldBuilder());

  //   RenderBox findBorder() {
  //     return tester.renderObject(find.descendant(
  //       of: find.byType(MongolInputDecorator),
  //       matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_BorderContainer'),
  //     ));
  //   }
  //   final RenderBox border = findBorder();

  //   // Without expanded: true and maxLines: null, the MongolTextField does not expand
  //   // to fill its parent when wrapped in an Expanded widget.
  //   final Size unexpandedInputSize = border.size;

  //   // It does expand to fill its parent when expands: true, maxLines: null, and
  //   // it's wrapped in an Expanded widget.
  //   await tester.pumpWidget(expandedTextFieldBuilder(expands: true, maxLines: null));
  //   expect(border.size.height, greaterThan(unexpandedInputSize.height));
  //   expect(border.size.width, unexpandedInputSize.width);

  //   // min/maxLines that is not null and expands: true contradict each other.
  //   expect(() async {
  //     await tester.pumpWidget(expandedTextFieldBuilder(expands: true, maxLines: 4));
  //   }, throwsAssertionError);
  //   expect(() async {
  //     await tester.pumpWidget(expandedTextFieldBuilder(expands: true, minLines: 1, maxLines: null));
  //   }, throwsAssertionError);
  // });

  // // Regression test for https://github.com/flutter/flutter/pull/29093
  // testMongolWidgets('Multiline text when wrapped in IntrinsicHeight', (tester) async {
  //   final Key intrinsicHeightKey = UniqueKey();
  //   Widget intrinsicTextFieldBuilder(bool wrapInIntrinsic) {
  //     final TextFormField textField = TextFormField(
  //       key: textFieldKey,
  //       style: const TextStyle(color: Colors.black, fontSize: 34.0),
  //       maxLines: null,
  //       decoration: const InputDecoration(
  //         counterText: 'I am counter',
  //       ),
  //     );
  //     final Widget widget = wrapInIntrinsic
  //       ? IntrinsicHeight(key: intrinsicHeightKey, child: textField)
  //       : textField;
  //     return boilerplate(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[widget],
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(intrinsicTextFieldBuilder(false));
  //   expect(find.byKey(intrinsicHeightKey), findsNothing);

  //   RenderBox findEditableText() => tester.renderObject(find.byType(MongolEditableText));
  //   RenderBox editableText = findEditableText();
  //   final Size unwrappedEditableTextSize = editableText.size;

  //   // Wrapping in IntrinsicHeight should not affect the height of the input
  //   await tester.pumpWidget(intrinsicTextFieldBuilder(true));
  //   editableText = findEditableText();
  //   expect(editableText.size.height, unwrappedEditableTextSize.height);
  //   expect(editableText.size.width, unwrappedEditableTextSize.width);
  // });

  // // Regression test for https://github.com/flutter/flutter/pull/29093
  // testMongolWidgets('errorText empty string', (tester) async {
  //   Widget textFormFieldBuilder(String? errorText) {
  //     return boilerplate(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           TextFormField(
  //             key: textFieldKey,
  //             maxLength: 3,
  //             maxLengthEnforcement: MaxLengthEnforcement.none,
  //             decoration: InputDecoration(
  //               counterText: '',
  //               errorText: errorText,
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(textFormFieldBuilder(null));

  //   RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));
  //   final RenderBox inputBox = findInputBox();
  //   final Size errorNullInputSize = inputBox.size;

  //   // Setting errorText causes the input's height to increase to accommodate it
  //   await tester.pumpWidget(textFormFieldBuilder('im errorText'));
  //   expect(inputBox, findInputBox());
  //   expect(inputBox.size.height, greaterThan(errorNullInputSize.height));
  //   expect(inputBox.size.width, errorNullInputSize.width);
  //   final Size errorInputSize = inputBox.size;

  //   // Setting errorText to an empty string causes the input's height to
  //   // increase to accommodate it, even though it's not displayed.
  //   // This may or may not be ideal behavior, but it is legacy behavior and
  //   // there are visual tests that rely on it (see Github issue referenced at
  //   // the top of this test). A counterText of empty string does not affect
  //   // input height, however.
  //   await tester.pumpWidget(textFormFieldBuilder(''));
  //   expect(inputBox, findInputBox());
  //   expect(inputBox.size.height, errorInputSize.height);
  //   expect(inputBox.size.width, errorNullInputSize.width);
  // });

  // testMongolWidgets('Growable MongolTextField when content height exceeds parent', (tester) async {
  //   const double width = 200.0;
  //   const double padding = 24.0;

  //   Widget containedTextFieldBuilder({
  //     Widget? counter,
  //     String? helperText,
  //     String? labelText,
  //     Widget? prefix,
  //   }) {
  //     return boilerplate(
  //       child: Container(
  //         width: width,
  //         child: MongolTextField(
  //           key: textFieldKey,
  //           maxLines: null,
  //           decoration: InputDecoration(
  //             counter: counter,
  //             helperText: helperText,
  //             labelText: labelText,
  //             prefix: prefix,
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(containedTextFieldBuilder());
  //   RenderBox findEditableText() => tester.renderObject(find.byType(MongolEditableText));

  //   final RenderBox inputBox = findEditableText();

  //   // With no decoration and when overflowing with content, the MongolEditableText
  //   // takes up the full width minus the padding, so the input fits perfectly
  //   // inside the parent.
  //   await tester.enterText(find.byType(MongolTextField), 'a\n' * 11);
  //   await tester.pump();
  //   expect(findEditableText(), equals(inputBox));
  //   expect(inputBox.size.width, width - padding);

  //   // Adding a counter causes the MongolEditableText to shrink to fit the counter
  //   // inside the parent as well.
  //   const double counterWidth = 40.0;
  //   const double subtextGap = 8.0;
  //   const double counterSpace = counterWidth + subtextGap;
  //   await tester.pumpWidget(containedTextFieldBuilder(
  //     counter: Container(width: counterWidth),
  //   ));
  //   expect(findEditableText(), equals(inputBox));
  //   expect(inputBox.size.width, width - padding - counterSpace);

  //   // Including helperText causes the MongolEditableText to shrink to fit the text
  //   // inside the parent as well.
  //   await tester.pumpWidget(containedTextFieldBuilder(
  //     helperText: 'I am helperText',
  //   ));
  //   expect(findEditableText(), equals(inputBox));
  //   const double helperTextSpace = 12.0;
  //   expect(inputBox.size.width, width - padding - helperTextSpace - subtextGap);

  //   // When both helperText and counter are present, MongolEditableText shrinks by the
  //   // width of the wider of the two in order to fit both within the parent.
  //   await tester.pumpWidget(containedTextFieldBuilder(
  //     counter: Container(width: counterWidth),
  //     helperText: 'I am helperText',
  //   ));
  //   expect(findEditableText(), equals(inputBox));
  //   expect(inputBox.size.width, width - padding - counterSpace);

  //   // When a label is present, MongolEditableText shrinks to fit it at the top so
  //   // that the right side of the input still lines up perfectly with the parent.
  //   await tester.pumpWidget(containedTextFieldBuilder(
  //     labelText: 'I am labelText',
  //   ));
  //   const double labelSpace = 16.0;
  //   expect(findEditableText(), equals(inputBox));
  //   expect(inputBox.size.width, width - padding - labelSpace);

  //   // When decoration is present on the left and right, MongolEditableText shrinks to
  //   // fit both inside the parent independently.
  //   await tester.pumpWidget(containedTextFieldBuilder(
  //     counter: Container(width: counterWidth),
  //     labelText: 'I am labelText',
  //   ));
  //   expect(findEditableText(), equals(inputBox));
  //   expect(inputBox.size.width, width - padding - counterSpace - labelSpace);

  //   // When a prefix or suffix is present in an input that's full of content,
  //   // it is ignored and allowed to expand beyond the top of the input. Other
  //   // top and bottom decoration is still respected.
  //   await tester.pumpWidget(containedTextFieldBuilder(
  //     counter: Container(width: counterWidth),
  //     labelText: 'I am labelText',
  //     prefix: const SizedBox(
  //       width: 10,
  //       height: 60,
  //     ),
  //   ));
  //   expect(findEditableText(), equals(inputBox));
  //   expect(
  //     inputBox.size.width,
  //     width
  //     - padding
  //     - labelSpace
  //     - counterSpace,
  //   );
  // });

  // testMongolWidgets('Multiline hint text will wrap up to maxLines', (tester) async {
  //   final Key textFieldKey = UniqueKey();

  //   Widget builder(int? maxLines, final String hintMsg) {
  //     return boilerplate(
  //       child: MongolTextField(
  //         key: textFieldKey,
  //         style: const TextStyle(color: Colors.black, fontSize: 34.0),
  //         maxLines: maxLines,
  //         decoration: InputDecoration(
  //           hintText: hintMsg,
  //         ),
  //       ),
  //     );
  //   }

  //   const String hintPlaceholder = 'Placeholder';
  //   const String multipleLineText = "Here's a text, which is more than one line, to demostrate the multiple line hint text";
  //   await tester.pumpWidget(builder(null, hintPlaceholder));

  //   RenderBox findHintText(String hint) => tester.renderObject(find.text(hint));

  //   final RenderBox hintTextBox = findHintText(hintPlaceholder);
  //   final Size oneLineHintSize = hintTextBox.size;

  //   await tester.pumpWidget(builder(null, hintPlaceholder));
  //   expect(findHintText(hintPlaceholder), equals(hintTextBox));
  //   expect(hintTextBox.size, equals(oneLineHintSize));

  //   const int maxLines = 3;
  //   await tester.pumpWidget(builder(maxLines, multipleLineText));
  //   final MongolText hintTextWidget = tester.widget(find.text(multipleLineText));
  //   expect(hintTextWidget.maxLines, equals(maxLines));
  //   expect(findHintText(multipleLineText).size.width, greaterThanOrEqualTo(oneLineHintSize.width));
  //   expect(findHintText(multipleLineText).size.height, greaterThanOrEqualTo(oneLineHintSize.height));
  // });

  // testMongolWidgets('Can drag handles to change selection in multiline', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         dragStartBehavior: DragStartBehavior.down,
  //         controller: controller,
  //         style: const TextStyle(color: Colors.black, fontSize: 34.0),
  //         maxLines: 3,
  //       ),
  //     ),
  //   );

  //   const String testValue = kThreeLines;
  //   const String cutValue = 'First line of stuff';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);

  //   // Check that the text spans multiple lines.
  //   final Offset firstPos = textOffsetToPosition(tester, testValue.indexOf('First'));
  //   final Offset secondPos = textOffsetToPosition(tester, testValue.indexOf('Second'));
  //   final Offset thirdPos = textOffsetToPosition(tester, testValue.indexOf('Third'));
  //   final Offset middleStringPos = textOffsetToPosition(tester, testValue.indexOf('irst'));
  //   expect(firstPos.dx, 0);
  //   expect(secondPos.dx, 0);
  //   expect(thirdPos.dx, 0);
  //   expect(middleStringPos.dx, 34);
  //   expect(firstPos.dx, secondPos.dx);
  //   expect(firstPos.dx, thirdPos.dx);
  //   expect(firstPos.dy, lessThan(secondPos.dy));
  //   expect(secondPos.dy, lessThan(thirdPos.dy));

  //   // Long press the 'n' in 'until' to select the word.
  //   final Offset untilPos = textOffsetToPosition(tester, testValue.indexOf('until')+1);
  //   TestGesture gesture = await tester.startGesture(untilPos, pointer: 7);
  //   await tester.pump(const Duration(seconds: 2));
  //   await gesture.up();
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

  //   expect(controller.selection.baseOffset, 39);
  //   expect(controller.selection.extentOffset, 44);

  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(controller.selection),
  //     renderEditable,
  //   );
  //   expect(endpoints.length, 2);

  //   // Drag the right handle to the third line, just after 'Third'.
  //   Offset handlePos = endpoints[1].point + const Offset(1.0, 1.0);
  //   Offset newHandlePos = textOffsetToPosition(tester, testValue.indexOf('Third') + 5);
  //   gesture = await tester.startGesture(handlePos, pointer: 7);
  //   await tester.pump();
  //   await gesture.moveTo(newHandlePos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump();

  //   expect(controller.selection.baseOffset, 39);
  //   expect(controller.selection.extentOffset, 50);

  //   // Drag the left handle to the first line, just after 'First'.
  //   handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
  //   newHandlePos = textOffsetToPosition(tester, testValue.indexOf('First') + 5);
  //   gesture = await tester.startGesture(handlePos, pointer: 7);
  //   await tester.pump();
  //   await gesture.moveTo(newHandlePos);
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump();

  //   expect(controller.selection.baseOffset, 5);
  //   expect(controller.selection.extentOffset, 50);

  //   await tester.tap(find.text('Cut'));
  //   await tester.pump();
  //   expect(controller.selection.isCollapsed, true);
  //   expect(controller.text, cutValue);
  // });

  // testMongolWidgets('Can scroll multiline input', (tester) async {
  //   final Key textFieldKey = UniqueKey();
  //   final TextEditingController controller = TextEditingController(
  //     text: kMoreThanFourLines,
  //   );

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         dragStartBehavior: DragStartBehavior.down,
  //         key: textFieldKey,
  //         controller: controller,
  //         style: const TextStyle(color: Colors.black, fontSize: 34.0),
  //         maxLines: 2,
  //       ),
  //     ),
  //   );

  //   RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));
  //   final RenderBox inputBox = findInputBox();

  //   // Check that the last line of text is not displayed.
  //   final Offset firstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
  //   final Offset fourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));
  //   expect(0, firstPos.dy);
  //   expect(0, fourthPos.dy);
  //   expect(firstPos.dy, fourthPos.dy);
  //   expect(firstPos.dx, lessThan(fourthPos.dx));
  //   expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(firstPos)), isTrue);
  //   expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(fourthPos)), isFalse);

  //   TestGesture gesture = await tester.startGesture(firstPos, pointer: 7);
  //   await tester.pump();
  //   await gesture.moveBy(const Offset(-1000.0, 0.0));
  //   await tester.pump(const Duration(seconds: 1));
  //   // Wait and drag again to trigger https://github.com/flutter/flutter/issues/6329
  //   // (No idea why this is necessary, but the bug wouldn't repro without it.)
  //   await gesture.moveBy(const Offset(-1000.0, 0.0));
  //   await tester.pump(const Duration(seconds: 1));
  //   await gesture.up();
  //   await tester.pump();
  //   await tester.pump(const Duration(seconds: 1));

  //   // Now the first line is scrolled up, and the fourth line is visible.
  //   Offset newFirstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
  //   Offset newFourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));

  //   expect(newFirstPos.dx, lessThan(firstPos.dx));
  //   expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isFalse);
  //   expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isTrue);

  //   // Now try scrolling by dragging the selection handle.
  //   // Long press the middle of the word "won't" in the fourth line.
  //   final Offset selectedWordPos = textOffsetToPosition(
  //     tester,
  //     kMoreThanFourLines.indexOf('Fourth line') + 14,
  //   );

  //   gesture = await tester.startGesture(selectedWordPos, pointer: 7);
  //   await tester.pump(const Duration(seconds: 1));
  //   await gesture.up();
  //   await tester.pump();
  //   await tester.pump(const Duration(seconds: 1));

  //   expect(controller.selection.base.offset, 77);
  //   expect(controller.selection.extent.offset, 82);
  //   // Sanity check for the word selected is the intended one.
  //   expect(
  //     controller.text.substring(controller.selection.baseOffset, controller.selection.extentOffset),
  //     "won't",
  //   );

  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(controller.selection),
  //     renderEditable,
  //   );
  //   expect(endpoints.length, 2);

  //   // Drag the left handle to the first line, just after 'First'.
  //   final Offset handlePos = endpoints[0].point + const Offset(-1, 1);
  //   final Offset newHandlePos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First') + 5);
  //   gesture = await tester.startGesture(handlePos, pointer: 7);
  //   await tester.pump(const Duration(seconds: 1));
  //   await gesture.moveTo(newHandlePos + const Offset(0.0, -10.0));
  //   await tester.pump(const Duration(seconds: 1));
  //   await gesture.up();
  //   await tester.pump(const Duration(seconds: 1));

  //   // The text should have scrolled up with the handle to keep the active
  //   // cursor visible, back to its original position.
  //   newFirstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
  //   newFourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));
  //   expect(newFirstPos.dy, firstPos.dy);
  //   expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isTrue);
  //   expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isFalse);
  // });

  testMongolWidgets('MongolTextField smoke test', (tester) async {
    late String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          decoration: null,
          onChanged: (String value) {
            textFieldValue = value;
          },
        ),
      ),
    );

    Future<void> checkText(String testValue) {
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(MongolTextField), testValue);

        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));

        await tester.pump();
      });
    }

    await checkText('Hello World');
  });

  testMongolWidgets('MongolTextField with global key', (tester) async {
    final GlobalKey textFieldKey = GlobalKey(debugLabel: 'textFieldKey');
    late String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          key: textFieldKey,
          decoration: const InputDecoration(
            hintText: 'Placeholder',
          ),
          onChanged: (String value) {
            textFieldValue = value;
          },
        ),
      ),
    );

    Future<void> checkText(String testValue) async {
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(MongolTextField), testValue);

        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));

        await tester.pump();
      });
    }

    await checkText('Hello World');
  });

  testMongolWidgets('MongolTextField errorText trumps helperText',
      (tester) async {
    await tester.pumpWidget(
      overlay(
        child: const MongolTextField(
          decoration: InputDecoration(
            errorText: 'error text',
            helperText: 'helper text',
          ),
        ),
      ),
    );
    expect(findMongol.text('helper text'), findsNothing);
    expect(findMongol.text('error text'), findsOneWidget);
  });

  testMongolWidgets('MongolTextField with default helperStyle', (tester) async {
    final ThemeData themeData = ThemeData(hintColor: Colors.blue[500]);
    await tester.pumpWidget(
      overlay(
        child: Theme(
          data: themeData,
          child: const MongolTextField(
            decoration: InputDecoration(
              helperText: 'helper text',
            ),
          ),
        ),
      ),
    );
    final MongolText helperText = tester.widget(findMongol.text('helper text'));
    expect(helperText.style!.color, themeData.hintColor);
    expect(helperText.style!.fontSize,
        Typography.englishLike2014.caption!.fontSize);
  });

  testMongolWidgets('MongolTextField with specified helperStyle',
      (tester) async {
    final TextStyle style = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          decoration: InputDecoration(
            helperText: 'helper text',
            helperStyle: style,
          ),
        ),
      ),
    );
    final MongolText helperText = tester.widget(findMongol.text('helper text'));
    expect(helperText.style, style);
  });

  testMongolWidgets('MongolTextField with default hintStyle', (tester) async {
    final TextStyle style = TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final ThemeData themeData = ThemeData(
      hintColor: Colors.blue[500],
    );

    await tester.pumpWidget(
      overlay(
        child: Theme(
          data: themeData,
          child: MongolTextField(
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
            style: style,
          ),
        ),
      ),
    );

    final MongolText hintText = tester.widget(findMongol.text('Placeholder'));
    expect(hintText.style!.color, themeData.hintColor);
    expect(hintText.style!.fontSize, style.fontSize);
  });

  testMongolWidgets('MongolTextField with specified hintStyle', (tester) async {
    final TextStyle hintStyle = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          decoration: InputDecoration(
            hintText: 'Placeholder',
            hintStyle: hintStyle,
          ),
        ),
      ),
    );

    final MongolText hintText = tester.widget(findMongol.text('Placeholder'));
    expect(hintText.style, hintStyle);
  });

  testMongolWidgets('MongolTextField with specified prefixStyle',
      (tester) async {
    final TextStyle prefixStyle = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          decoration: InputDecoration(
            prefixText: 'Prefix:',
            prefixStyle: prefixStyle,
          ),
        ),
      ),
    );

    final MongolText prefixText = tester.widget(findMongol.text('Prefix:'));
    expect(prefixText.style, prefixStyle);
  });

  testMongolWidgets('MongolTextField with specified suffixStyle',
      (tester) async {
    final TextStyle suffixStyle = TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          decoration: InputDecoration(
            suffixText: '.com',
            suffixStyle: suffixStyle,
          ),
        ),
      ),
    );

    final MongolText suffixText = tester.widget(findMongol.text('.com'));
    expect(suffixText.style, suffixStyle);
  });

  testMongolWidgets(
      'MongolTextField prefix and suffix appear correctly with no hint or label',
      (tester) async {
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Row(
          children: <Widget>[
            const MongolTextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            MongolTextField(
              key: secondKey,
              decoration: const InputDecoration(
                prefixText: 'Prefix',
                suffixText: 'Suffix',
              ),
            ),
          ],
        ),
      ),
    );

    expect(findMongol.text('Prefix'), findsOneWidget);
    expect(findMongol.text('Suffix'), findsOneWidget);

    // Focus the Input. The prefix should still display.
    await tester.tap(find.byKey(secondKey));
    await tester.pump();

    expect(findMongol.text('Prefix'), findsOneWidget);
    expect(findMongol.text('Suffix'), findsOneWidget);

    // Enter some text, and the prefix should still display.
    await tester.enterText(find.byKey(secondKey), 'Hi');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(findMongol.text('Prefix'), findsOneWidget);
    expect(findMongol.text('Suffix'), findsOneWidget);
  });

  testMongolWidgets(
      'MongolTextField prefix and suffix appear correctly with hint text',
      (tester) async {
    final TextStyle hintStyle = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Row(
          children: <Widget>[
            const MongolTextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            MongolTextField(
              key: secondKey,
              decoration: InputDecoration(
                hintText: 'Hint',
                hintStyle: hintStyle,
                prefixText: 'Prefix',
                suffixText: 'Suffix',
              ),
            ),
          ],
        ),
      ),
    );

    // Neither the prefix or the suffix should initially be visible, only the hint.
    expect(getOpacity(tester, findMongol.text('Prefix')), 0.0);
    expect(getOpacity(tester, findMongol.text('Suffix')), 0.0);
    expect(getOpacity(tester, findMongol.text('Hint')), 1.0);

    await tester.tap(find.byKey(secondKey));
    await tester.pumpAndSettle();

    // Focus the Input. The hint, prefix, and suffix should appear
    expect(getOpacity(tester, findMongol.text('Prefix')), 1.0);
    expect(getOpacity(tester, findMongol.text('Suffix')), 1.0);
    expect(getOpacity(tester, findMongol.text('Hint')), 1.0);

    // Enter some text, and the hint should disappear and the prefix and suffix
    // should continue to be visible
    await tester.enterText(find.byKey(secondKey), 'Hi');
    await tester.pumpAndSettle();

    expect(getOpacity(tester, findMongol.text('Prefix')), 1.0);
    expect(getOpacity(tester, findMongol.text('Suffix')), 1.0);
    expect(getOpacity(tester, findMongol.text('Hint')), 0.0);

    // Check and make sure that the right styles were applied.
    final MongolText prefixText = tester.widget(findMongol.text('Prefix'));
    expect(prefixText.style, hintStyle);
    final MongolText suffixText = tester.widget(findMongol.text('Suffix'));
    expect(suffixText.style, hintStyle);
  });

  testMongolWidgets(
      'MongolTextField prefix and suffix appear correctly with label text',
      (tester) async {
    final TextStyle prefixStyle = TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final TextStyle suffixStyle = TextStyle(
      color: Colors.green[500],
      fontSize: 12.0,
    );
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Row(
          children: <Widget>[
            const MongolTextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            MongolTextField(
              key: secondKey,
              decoration: InputDecoration(
                labelText: 'Label',
                prefixText: 'Prefix',
                prefixStyle: prefixStyle,
                suffixText: 'Suffix',
                suffixStyle: suffixStyle,
              ),
            ),
          ],
        ),
      ),
    );

    // Not focused. The prefix and suffix should not appear, but the label should.
    expect(getOpacity(tester, findMongol.text('Prefix')), 0.0);
    expect(getOpacity(tester, findMongol.text('Suffix')), 0.0);
    expect(findMongol.text('Label'), findsOneWidget);

    // Focus the input. The label, prefix, and suffix should appear.
    await tester.tap(find.byKey(secondKey));
    await tester.pumpAndSettle();

    expect(getOpacity(tester, findMongol.text('Prefix')), 1.0);
    expect(getOpacity(tester, findMongol.text('Suffix')), 1.0);
    expect(findMongol.text('Label'), findsOneWidget);

    // Enter some text. The label, prefix, and suffix should remain visible.
    await tester.enterText(find.byKey(secondKey), 'Hi');
    await tester.pumpAndSettle();

    expect(getOpacity(tester, findMongol.text('Prefix')), 1.0);
    expect(getOpacity(tester, findMongol.text('Suffix')), 1.0);
    expect(findMongol.text('Label'), findsOneWidget);

    // Check and make sure that the right styles were applied.
    final MongolText prefixText = tester.widget(findMongol.text('Prefix'));
    expect(prefixText.style, prefixStyle);
    final MongolText suffixText = tester.widget(findMongol.text('Suffix'));
    expect(suffixText.style, suffixStyle);
  });

  testMongolWidgets('MongolTextField label text animates', (tester) async {
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Row(
          children: <Widget>[
            const MongolTextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            MongolTextField(
              key: secondKey,
              decoration: const InputDecoration(
                labelText: 'Second',
              ),
            ),
          ],
        ),
      ),
    );

    Offset pos = tester.getTopLeft(findMongol.text('Second'));

    // Focus the Input. The label should start animating upwards.
    await tester.tap(find.byKey(secondKey));
    await tester.idle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    Offset newPos = tester.getTopLeft(findMongol.text('Second'));
    expect(newPos.dx, lessThan(pos.dx));

    // Label should still be sliding upward.
    await tester.pump(const Duration(milliseconds: 50));
    pos = newPos;
    newPos = tester.getTopLeft(findMongol.text('Second'));
    expect(newPos.dx, lessThan(pos.dx));
  });

  // testMongolWidgets('Icon is separated from input/label by 16+12', (tester) async {
  //   await tester.pumpWidget(
  //     overlay(
  //       child: const MongolTextField(
  //         decoration: InputDecoration(
  //           icon: Icon(Icons.phone),
  //           labelText: 'label',
  //           filled: true,
  //         ),
  //       ),
  //     ),
  //   );
  //   final double iconRight = tester.getTopRight(find.byType(Icon)).dx;
  //   // Per https://material.io/go/design-text-fields#text-fields-layout
  //   // There's a 16 dps gap between the right edge of the icon and the text field's
  //   // container, and the 12dps more padding between the left edge of the container
  //   // and the left edge of the input and label.
  //   expect(iconRight + 28.0, equals(tester.getTopLeft(findMongol.text('label')).dx));
  //   expect(iconRight + 28.0, equals(tester.getTopLeft(find.byType(MongolEditableText)).dx));
  // });

  // testMongolWidgets('Collapsed hint text placement', (tester) async {
  //   await tester.pumpWidget(
  //     overlay(
  //       child: const MongolTextField(
  //         decoration: InputDecoration.collapsed(
  //           hintText: 'hint',
  //         ),
  //         strutStyle: StrutStyle.disabled,
  //       ),
  //     ),
  //   );

  //   expect(tester.getTopLeft(findMongol.text('hint')), equals(tester.getTopLeft(find.byType(MongolEditableText))));
  // });

  // testMongolWidgets('Can align to center', (tester) async {
  //   await tester.pumpWidget(
  //     overlay(
  //       child: Container(
  //         height: 300.0,
  //         child: const MongolTextField(
  //           textAlign: MongolTextAlign.center,
  //           decoration: null,
  //         ),
  //       ),
  //     ),
  //   );

  //   final MongolRenderEditable editable = findRenderEditable(tester);
  //   Offset topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 0)).topLeft,
  //   );

  //   expect(topLeft.dy, equals(399.0));

  //   await tester.enterText(find.byType(MongolTextField), 'abcd');
  //   await tester.pump();

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
  //   );

  //   // TextPosition(offset: 2) - center of 'abcd'
  //   expect(topLeft.dy, equals(399.0));
  // });

  // testMongolWidgets('Can align to center within center', (tester) async {
  //   await tester.pumpWidget(
  //     overlay(
  //       child: Container(
  //         width: 300.0,
  //         child: const Center(
  //           child: MongolTextField(
  //             textAlign: TextAlign.center,
  //             decoration: null,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final MongolRenderEditable editable = findRenderEditable(tester);
  //   Offset topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 0)).topLeft,
  //   );

  //   // The overlay() function centers its child within a 800x600 window.
  //   // Default cursorWidth is 2.0, test windowWidth is 800
  //   // Centered cursor topLeft.dx: 399 == windowWidth/2 - cursorWidth/2
  //   expect(topLeft.dx, equals(399.0));

  //   await tester.enterText(find.byType(MongolTextField), 'abcd');
  //   await tester.pump();

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
  //   );

  //   // TextPosition(offset: 2) - center of 'abcd'
  //   expect(topLeft.dx, equals(399.0));
  // });

  testMongolWidgets('Controller can update server', (tester) async {
    final TextEditingController controller1 = TextEditingController(
      text: 'Initial Text',
    );
    final TextEditingController controller2 = TextEditingController(
      text: 'More Text',
    );

    TextEditingController? currentController;
    late StateSetter setState;

    await tester.pumpWidget(
      overlay(
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MongolTextField(controller: currentController);
        }),
      ),
    );
    expect(tester.testTextInput.editingState, isNull);

    // Initial state with null controller.
    await tester.tap(find.byType(MongolTextField));
    await tester.pump();
    expect(tester.testTextInput.editingState!['text'], isEmpty);

    // Update the controller from null to controller1.
    setState(() {
      currentController = controller1;
    });
    await tester.pump();
    expect(tester.testTextInput.editingState!['text'], equals('Initial Text'));

    // Verify that updates to controller1 are handled.
    controller1.text = 'Updated Text';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('Updated Text'));

    // Verify that switching from controller1 to controller2 is handled.
    setState(() {
      currentController = controller2;
    });
    await tester.pump();
    expect(tester.testTextInput.editingState!['text'], equals('More Text'));

    // Verify that updates to controller1 are ignored.
    controller1.text = 'Ignored Text';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('More Text'));

    // Verify that updates to controller text are handled.
    controller2.text = 'Additional Text';
    await tester.idle();
    expect(
        tester.testTextInput.editingState!['text'], equals('Additional Text'));

    // Verify that updates to controller selection are handled.
    controller2.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.idle();
    expect(tester.testTextInput.editingState!['selectionBase'], equals(0));
    expect(tester.testTextInput.editingState!['selectionExtent'], equals(5));

    // Verify that calling clear() clears the text.
    controller2.clear();
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals(''));

    // Verify that switching from controller2 to null preserves current text.
    controller2.text = 'The Final Cut';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('The Final Cut'));
    setState(() {
      currentController = null;
    });
    await tester.pump();
    expect(tester.testTextInput.editingState!['text'], equals('The Final Cut'));

    // Verify that changes to controller2 are ignored.
    controller2.text = 'Goodbye Cruel World';
    expect(tester.testTextInput.editingState!['text'], equals('The Final Cut'));
  });

  testMongolWidgets('Cannot enter new lines onto single line TextField',
      (tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: MongolTextField(controller: textController, decoration: null),
    ));

    await tester.enterText(find.byType(MongolTextField), 'abc\ndef');

    expect(textController.text, 'abcdef');
  });

  testMongolWidgets('Injected formatters are chained', (tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: MongolTextField(
        controller: textController,
        decoration: null,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.deny(
            RegExp(r'[a-z]'),
            replacementString: '#',
          ),
        ],
      ),
    ));

    await tester.enterText(find.byType(MongolTextField), 'a一b二c三\nd四e五f六');
    // The default single line formatter replaces \n with empty string.
    expect(textController.text, '#一#二#三#四#五#六');
  });

  testMongolWidgets('Injected formatters are chained (deprecated names)',
      (tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: MongolTextField(
        controller: textController,
        decoration: null,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.deny(
            RegExp(r'[a-z]'),
            replacementString: '#',
          ),
        ],
      ),
    ));

    await tester.enterText(find.byType(MongolTextField), 'a一b二c三\nd四e五f六');
    // The default single line formatter replaces \n with empty string.
    expect(textController.text, '#一#二#三#四#五#六');
  });

  testMongolWidgets('Chained formatters are in sequence', (tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: MongolTextField(
        controller: textController,
        decoration: null,
        maxLines: 2,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.deny(
            RegExp(r'[a-z]'),
            replacementString: '12\n',
          ),
          FilteringTextInputFormatter.allow(RegExp(r'\n[0-9]')),
        ],
      ),
    ));

    await tester.enterText(find.byType(MongolTextField), 'a1b2c3');
    // The first formatter turns it into
    // 12\n112\n212\n3
    // The second formatter turns it into
    // \n1\n2\n3
    // Multiline is allowed since maxLine != 1.
    expect(textController.text, '\n1\n2\n3');
  });

  testMongolWidgets('Chained formatters are in sequence (deprecated names)',
      (tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: MongolTextField(
        controller: textController,
        decoration: null,
        maxLines: 2,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.deny(
            RegExp(r'[a-z]'),
            replacementString: '12\n',
          ),
          FilteringTextInputFormatter.allow(RegExp(r'\n[0-9]')),
        ],
      ),
    ));

    await tester.enterText(find.byType(MongolTextField), 'a1b2c3');
    // The first formatter turns it into
    // 12\n112\n212\n3
    // The second formatter turns it into
    // \n1\n2\n3
    // Multiline is allowed since maxLine != 1.
    expect(textController.text, '\n1\n2\n3');
  });

  // testMongolWidgets('Pasted values are formatted', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         controller: textController,
  //         decoration: null,
  //         inputFormatters: <TextInputFormatter> [
  //           FilteringTextInputFormatter.digitsOnly,
  //         ],
  //       ),
  //     ),
  //   );

  //   await tester.enterText(find.byType(MongolTextField), 'a1b\n2c3');
  //   expect(textController.text, '123');
  //   await skipPastScrollingAnimation(tester);

  //   await tester.tapAt(textOffsetToPosition(tester, '123'.indexOf('2')));
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(textController.selection),
  //     renderEditable,
  //   );
  //   await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

  //   Clipboard.setData(const ClipboardData(text: '一4二\n5三6'));
  //   await tester.tap(findMongol.text('Paste'));
  //   await tester.pump();
  //   // Puts 456 before the 2 in 123.
  //   expect(textController.text, '145623');
  // });

  // testMongolWidgets('Pasted values are formatted (deprecated names)', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         controller: textController,
  //         decoration: null,
  //         inputFormatters: <TextInputFormatter> [
  //           FilteringTextInputFormatter.digitsOnly,
  //         ],
  //       ),
  //     ),
  //   );

  //   await tester.enterText(find.byType(MongolTextField), 'a1b\n2c3');
  //   expect(textController.text, '123');
  //   await skipPastScrollingAnimation(tester);

  //   await tester.tapAt(textOffsetToPosition(tester, '123'.indexOf('2')));
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(textController.selection),
  //     renderEditable,
  //   );
  //   await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

  //   Clipboard.setData(const ClipboardData(text: '一4二\n5三6'));
  //   await tester.tap(findMongol.text('Paste'));
  //   await tester.pump();
  //   // Puts 456 before the 2 in 123.
  //   expect(textController.text, '145623');
  // });

  testMongolWidgets(
      'Do not add LengthLimiting formatter to the user supplied list',
      (tester) async {
    final List<TextInputFormatter> formatters = <TextInputFormatter>[];

    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          decoration: null,
          maxLength: 5,
          inputFormatters: formatters,
        ),
      ),
    );

    expect(formatters.isEmpty, isTrue);
  });

  testMongolWidgets('Text field scrolls the caret into view', (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: Container(
          height: 100.0,
          child: MongolTextField(
            controller: controller,
          ),
        ),
      ),
    );

    final String longText = 'a' * 20;
    await tester.enterText(find.byType(MongolTextField), longText);
    await skipPastScrollingAnimation(tester);

    ScrollableState scrollableState =
        tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, equals(0.0));

    // Move the caret to the end of the text and check that the text field
    // scrolls to make the caret visible.
    controller.selection = TextSelection.collapsed(offset: longText.length);
    await tester
        .pump(); // TODO(ianh): Figure out why this extra pump is needed.
    await skipPastScrollingAnimation(tester);

    scrollableState = tester.firstState(find.byType(Scrollable));
    // For a horizontal input, scrolls to the exact position of the caret.
    expect(scrollableState.position.pixels, equals(222.0));
  });

  testMongolWidgets('Multiline text field scrolls the caret into view',
      (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: Container(
          child: MongolTextField(
            controller: controller,
            maxLines: 6,
          ),
        ),
      ),
    );

    const String tallText = 'a\nb\nc\nd\ne\nf\ng'; // One line over max
    await tester.enterText(find.byType(MongolTextField), tallText);
    await skipPastScrollingAnimation(tester);

    ScrollableState scrollableState =
        tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, equals(0.0));

    // Move the caret to the end of the text and check that the text field
    // scrolls to make the caret visible.
    controller.selection =
        const TextSelection.collapsed(offset: tallText.length);
    await tester.pump();
    await skipPastScrollingAnimation(tester);

    // Should have scrolled down exactly one line height (7 lines of text in 6
    // line text field).
    final double lineWidth = findRenderEditable(tester).preferredLineWidth;
    scrollableState = tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels,
        moreOrLessEquals(lineWidth, epsilon: 0.1));
  });

  // testMongolWidgets('haptic feedback', (tester) async {
  //   final FeedbackTester feedback = FeedbackTester();
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: Container(
  //         width: 100.0,
  //         child: MongolTextField(
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pumpAndSettle(const Duration(seconds: 1));
  //   expect(feedback.clickSoundCount, 0);
  //   expect(feedback.hapticCount, 0);

  //   await tester.longPress(find.byType(MongolTextField));
  //   await tester.pumpAndSettle(const Duration(seconds: 1));
  //   expect(feedback.clickSoundCount, 0);
  //   expect(feedback.hapticCount, 1);

  //   feedback.dispose();
  // });

  testMongolWidgets('Text field drops selection when losing focus',
      (tester) async {
    final Key key1 = UniqueKey();
    final TextEditingController controller1 = TextEditingController();
    final Key key2 = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Row(
          children: <Widget>[
            MongolTextField(
              key: key1,
              controller: controller1,
            ),
            MongolTextField(key: key2),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(key1));
    await tester.enterText(find.byKey(key1), 'abcd');
    await tester.pump();
    controller1.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
    await tester.pump();
    expect(controller1.selection, isNot(equals(TextRange.empty)));

    await tester.tap(find.byKey(key2));
    await tester.pump();
    expect(controller1.selection, equals(TextRange.empty));
  });

  testMongolWidgets('Selection is consistent with text length', (tester) async {
    final TextEditingController controller = TextEditingController();

    controller.text = 'abcde';
    controller.selection = const TextSelection.collapsed(offset: 5);

    controller.text = '';
    expect(controller.selection.start, lessThanOrEqualTo(0));
    expect(controller.selection.end, lessThanOrEqualTo(0));

    late FlutterError error;
    try {
      controller.selection = const TextSelection.collapsed(offset: 10);
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error.diagnostics.length, 1);
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   invalid text selection: TextSelection(baseOffset: 10,\n'
          '   extentOffset: 10, affinity: TextAffinity.downstream,\n'
          '   isDirectional: false)\n',
        ),
      );
    }
  });

  // Regression test for https://github.com/flutter/flutter/issues/35848
  testMongolWidgets(
      'Clearing text field with suffixIcon does not cause text selection exception',
      (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Prefilled text.',
    );

    await tester.pumpWidget(
      boilerplate(
        child: MongolTextField(
          controller: controller,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.clear,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    expect(controller.text, '');
  });

  // testMongolWidgets('maxLength limits input.', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), '0123456789101112');
  //   expect(textController.text, '0123456789');
  // });

  // testMongolWidgets('maxLength limits input with surrogate pairs.', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //     ),
  //   ));

  //   const String surrogatePair = '😆';
  //   await tester.enterText(find.byType(MongolTextField), surrogatePair + '0123456789101112');
  //   expect(textController.text, surrogatePair + '012345678');
  // });

  // testMongolWidgets('maxLength limits input with grapheme clusters.', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //     ),
  //   ));

  //   const String graphemeCluster = '👨‍👩‍👦';
  //   await tester.enterText(find.byType(MongolTextField), graphemeCluster + '0123456789101112');
  //   expect(textController.text, graphemeCluster + '012345678');
  // });

  // testMongolWidgets('maxLength limits input in the center of a maxed-out field.', (tester) async {
  //   // Regression test for https://github.com/flutter/flutter/issues/37420.
  //   final TextEditingController textController = TextEditingController();
  //   const String testValue = '0123456789';

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //     ),
  //   ));

  //   // Max out the character limit in the field.
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   expect(textController.text, testValue);

  //   // Entering more characters at the end does nothing.
  //   await tester.enterText(find.byType(MongolTextField), testValue + '9999999');
  //   expect(textController.text, testValue);

  //   // Entering text in the middle of the field also does nothing.
  //   await tester.enterText(find.byType(MongolTextField), '0123455555555556789');
  //   expect(textController.text, testValue);
  // });

  // testMongolWidgets('maxLength limits input length even if decoration is null.', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       decoration: null,
  //       maxLength: 10,
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), '0123456789101112');
  //   expect(textController.text, '0123456789');
  // });

  // testMongolWidgets('maxLength still works with other formatters', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //       inputFormatters: <TextInputFormatter> [
  //         FilteringTextInputFormatter.deny(
  //           RegExp(r'[a-z]'),
  //           replacementString: '#',
  //         ),
  //       ],
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), 'a一b二c三\nd四e五f六');
  //   // The default single line formatter replaces \n with empty string.
  //   expect(textController.text, '#一#二#三#四#五');
  // });

  // testMongolWidgets('maxLength still works with other formatters (deprecated names)', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //       inputFormatters: <TextInputFormatter> [
  //         FilteringTextInputFormatter.deny(
  //           RegExp(r'[a-z]'),
  //           replacementString: '#',
  //         ),
  //       ],
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), 'a一b二c三\nd四e五f六');
  //   // The default single line formatter replaces \n with empty string.
  //   expect(textController.text, '#一#二#三#四#五');
  // });

  // testMongolWidgets("maxLength isn't enforced when maxLengthEnforced is false.", (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //       maxLengthEnforcement: MaxLengthEnforcement.none,
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), '0123456789101112');
  //   expect(textController.text, '0123456789101112');
  // });

  // testMongolWidgets('maxLength shows warning when maxLengthEnforced is false.', (tester) async {
  //   final TextEditingController textController = TextEditingController();
  //   const TextStyle testStyle = TextStyle(color: Colors.deepPurpleAccent);

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       decoration: const InputDecoration(errorStyle: testStyle),
  //       controller: textController,
  //       maxLength: 10,
  //       maxLengthEnforcement: MaxLengthEnforcement.none,
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), '0123456789101112');
  //   await tester.pump();

  //   expect(textController.text, '0123456789101112');
  //   expect(findMongol.text('16/10'), findsOneWidget);
  //   MongolText counterTextWidget = tester.widget(findMongol.text('16/10'));
  //   expect(counterTextWidget.style!.color, equals(Colors.deepPurpleAccent));

  //   await tester.enterText(find.byType(MongolTextField), '0123456789');
  //   await tester.pump();

  //   expect(textController.text, '0123456789');
  //   expect(findMongol.text('10/10'), findsOneWidget);
  //   counterTextWidget = tester.widget(findMongol.text('10/10'));
  //   expect(counterTextWidget.style!.color, isNot(equals(Colors.deepPurpleAccent)));
  // });

  // testMongolWidgets('maxLength shows warning when maxLengthEnforced is false with surrogate pairs.', (tester) async {
  //   final TextEditingController textController = TextEditingController();
  //   const TextStyle testStyle = TextStyle(color: Colors.deepPurpleAccent);

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       decoration: const InputDecoration(errorStyle: testStyle),
  //       controller: textController,
  //       maxLength: 10,
  //       maxLengthEnforcement: MaxLengthEnforcement.none,
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), '😆012345678910111');
  //   await tester.pump();

  //   expect(textController.text, '😆012345678910111');
  //   expect(findMongol.text('16/10'), findsOneWidget);
  //   MongolText counterTextWidget = tester.widget(findMongol.text('16/10'));
  //   expect(counterTextWidget.style!.color, equals(Colors.deepPurpleAccent));

  //   await tester.enterText(find.byType(MongolTextField), '😆012345678');
  //   await tester.pump();

  //   expect(textController.text, '😆012345678');
  //   expect(findMongol.text('10/10'), findsOneWidget);
  //   counterTextWidget = tester.widget(findMongol.text('10/10'));
  //   expect(counterTextWidget.style!.color, isNot(equals(Colors.deepPurpleAccent)));
  // });

  // testMongolWidgets('maxLength shows warning when maxLengthEnforced is false with grapheme clusters.', (tester) async {
  //   final TextEditingController textController = TextEditingController();
  //   const TextStyle testStyle = TextStyle(color: Colors.deepPurpleAccent);

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       decoration: const InputDecoration(errorStyle: testStyle),
  //       controller: textController,
  //       maxLength: 10,
  //       maxLengthEnforcement: MaxLengthEnforcement.none,
  //     ),
  //   ));

  //   await tester.enterText(find.byType(MongolTextField), '👨‍👩‍👦012345678910111');
  //   await tester.pump();

  //   expect(textController.text, '👨‍👩‍👦012345678910111');
  //   expect(findMongol.text('16/10'), findsOneWidget);
  //   MongolText counterTextWidget = tester.widget(findMongol.text('16/10'));
  //   expect(counterTextWidget.style!.color, equals(Colors.deepPurpleAccent));

  //   await tester.enterText(find.byType(MongolTextField), '👨‍👩‍👦012345678');
  //   await tester.pump();

  //   expect(textController.text, '👨‍👩‍👦012345678');
  //   expect(findMongol.text('10/10'), findsOneWidget);
  //   counterTextWidget = tester.widget(findMongol.text('10/10'));
  //   expect(counterTextWidget.style!.color, isNot(equals(Colors.deepPurpleAccent)));
  // });

  // testMongolWidgets('maxLength limits input with surrogate pairs.', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //     ),
  //   ));

  //   const String surrogatePair = '😆';
  //   await tester.enterText(find.byType(MongolTextField), surrogatePair + '0123456789101112');
  //   expect(textController.text, surrogatePair + '012345678');
  // });

  // testMongolWidgets('maxLength limits input with grapheme clusters.', (tester) async {
  //   final TextEditingController textController = TextEditingController();

  //   await tester.pumpWidget(boilerplate(
  //     child: MongolTextField(
  //       controller: textController,
  //       maxLength: 10,
  //     ),
  //   ));

  //   const String graphemeCluster = '👨‍👩‍👦';
  //   await tester.enterText(find.byType(MongolTextField), graphemeCluster + '0123456789101112');
  //   expect(textController.text, graphemeCluster + '012345678');
  // });

  // testMongolWidgets('setting maxLength shows counter', (tester) async {
  //   await tester.pumpWidget(const MaterialApp(
  //     home: Material(
  //       child: Center(
  //           child: MongolTextField(
  //             maxLength: 10,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(findMongol.text('0/10'), findsOneWidget);

  //   await tester.enterText(find.byType(MongolTextField), '01234');
  //   await tester.pump();

  //   expect(findMongol.text('5/10'), findsOneWidget);
  // });

  // testMongolWidgets('maxLength counter measures surrogate pairs as one character', (tester) async {
  //   await tester.pumpWidget(const MaterialApp(
  //     home: Material(
  //       child: Center(
  //           child: MongolTextField(
  //             maxLength: 10,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(findMongol.text('0/10'), findsOneWidget);

  //   const String surrogatePair = '😆';
  //   await tester.enterText(find.byType(MongolTextField), surrogatePair);
  //   await tester.pump();

  //   expect(findMongol.text('1/10'), findsOneWidget);
  // });

  // testMongolWidgets('maxLength counter measures grapheme clusters as one character', (tester) async {
  //   await tester.pumpWidget(const MaterialApp(
  //     home: Material(
  //       child: Center(
  //           child: MongolTextField(
  //             maxLength: 10,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(findMongol.text('0/10'), findsOneWidget);

  //   const String familyEmoji = '👨‍👩‍👦';
  //   await tester.enterText(find.byType(MongolTextField), familyEmoji);
  //   await tester.pump();

  //   expect(findMongol.text('1/10'), findsOneWidget);
  // });

  // testMongolWidgets('setting maxLength to TextField.noMaxLength shows only entered length', (tester) async {
  //   await tester.pumpWidget(const MaterialApp(
  //     home: Material(
  //       child: Center(
  //           child: MongolTextField(
  //             maxLength: TextField.noMaxLength,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(findMongol.text('0'), findsOneWidget);

  //   await tester.enterText(find.byType(MongolTextField), '01234');
  //   await tester.pump();

  //   expect(findMongol.text('5'), findsOneWidget);
  // });

  // testMongolWidgets('passing a buildCounter shows returned widget', (tester) async {
  //   await tester.pumpWidget(MaterialApp(
  //     home: Material(
  //       child: Center(
  //           child: MongolTextField(
  //             buildCounter: (BuildContext context, { required int currentLength, int? maxLength, required bool isFocused }) {
  //               return Text('${currentLength.toString()} of ${maxLength.toString()}');
  //             },
  //             maxLength: 10,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(findMongol.text('0 of 10'), findsOneWidget);

  //   await tester.enterText(find.byType(MongolTextField), '01234');
  //   await tester.pump();

  //   expect(findMongol.text('5 of 10'), findsOneWidget);
  // });

  testMongolWidgets('MongolTextField identifies as text field in semantics',
      (tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              maxLength: 10,
            ),
          ),
        ),
      ),
    );

    expect(semantics,
        includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.isTextField]));

    semantics.dispose();
  });

  testMongolWidgets('Disabled text field does not have tap action',
      (tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              maxLength: 10,
              enabled: false,
            ),
          ),
        ),
      ),
    );

    expect(
        semantics,
        isNot(
            includesNodeWith(actions: <SemanticsAction>[SemanticsAction.tap])));

    semantics.dispose();
  });

  testMongolWidgets('Readonly text field does not have tap action',
      (tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              maxLength: 10,
              readOnly: true,
            ),
          ),
        ),
      ),
    );

    expect(
        semantics,
        isNot(
            includesNodeWith(actions: <SemanticsAction>[SemanticsAction.tap])));

    semantics.dispose();
  });

  // testMongolWidgets('Disabled text field hides helper and counter', (tester) async {
  //   const String helperText = 'helper text';
  //   const String counterText = 'counter text';
  //   const String errorText = 'error text';
  //   Widget buildFrame(bool enabled, bool hasError) {
  //     return MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             decoration: InputDecoration(
  //               labelText: 'label text',
  //               helperText: helperText,
  //               counterText: counterText,
  //               errorText: hasError ? errorText : null,
  //               enabled: enabled,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(buildFrame(true, false));
  //   MongolText helperWidget = tester.widget(findMongol.text(helperText));
  //   MongolText counterWidget = tester.widget(findMongol.text(counterText));
  //   expect(helperWidget.style!.color, isNot(equals(Colors.transparent)));
  //   expect(counterWidget.style!.color, isNot(equals(Colors.transparent)));
  //   await tester.pumpWidget(buildFrame(true, true));
  //   counterWidget = tester.widget(findMongol.text(counterText));
  //   MongolText errorWidget = tester.widget(findMongol.text(errorText));
  //   expect(helperWidget.style!.color, isNot(equals(Colors.transparent)));
  //   expect(errorWidget.style!.color, isNot(equals(Colors.transparent)));

  //   // When enabled is false, the helper/error and counter are not visible.
  //   await tester.pumpWidget(buildFrame(false, false));
  //   helperWidget = tester.widget(findMongol.text(helperText));
  //   counterWidget = tester.widget(findMongol.text(counterText));
  //   expect(helperWidget.style!.color, equals(Colors.transparent));
  //   expect(counterWidget.style!.color, equals(Colors.transparent));
  //   await tester.pumpWidget(buildFrame(false, true));
  //   errorWidget = tester.widget(findMongol.text(errorText));
  //   counterWidget = tester.widget(findMongol.text(counterText));
  //   expect(counterWidget.style!.color, equals(Colors.transparent));
  //   expect(errorWidget.style!.color, equals(Colors.transparent));
  // });

  testMongolWidgets('currentValueLength/maxValueLength are in the tree',
      (tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              controller: controller,
              maxLength: 10,
            ),
          ),
        ),
      ),
    );

    expect(
        semantics,
        includesNodeWith(
          flags: <SemanticsFlag>[SemanticsFlag.isTextField],
          maxValueLength: 10,
          currentValueLength: 0,
        ));

    await tester.showKeyboard(find.byType(MongolTextField));
    const String testValue = '123';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue,
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 0, end: testValue.length),
    ));
    await tester.pump();

    expect(
        semantics,
        includesNodeWith(
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused
          ],
          maxValueLength: 10,
          currentValueLength: 3,
        ));

    semantics.dispose();
  });

  testMongolWidgets(
      'Read only MongolTextField identifies as read only text field in semantics',
      (tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              maxLength: 10,
              readOnly: true,
            ),
          ),
        ),
      ),
    );

    expect(
      semantics,
      includesNodeWith(flags: <SemanticsFlag>[
        SemanticsFlag.isTextField,
        SemanticsFlag.isReadOnly
      ]),
    );

    semantics.dispose();
  });

  testMongolWidgets(
      "Disabled MongolTextField can't be traversed to when disabled.",
      (tester) async {
    final FocusNode focusNode1 = FocusNode(debugLabel: 'MongolTextField 1');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'MongolTextField 2');
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: Row(
              children: <Widget>[
                MongolTextField(
                  focusNode: focusNode1,
                  autofocus: true,
                  maxLength: 10,
                  enabled: true,
                ),
                MongolTextField(
                  focusNode: focusNode2,
                  maxLength: 10,
                  enabled: false,
                ),
              ],
            ),
          ),
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


  // group('Keyboard Tests', () {
  //   late TextEditingController controller;

  //   setUp(() {
  //     controller = TextEditingController();
  //   });

  //   Future<void> setupWidget(MongolWidgetTester tester) async {
  //     final FocusNode focusNode = FocusNode();
  //     controller = TextEditingController();

  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: RawKeyboardListener(
  //             focusNode: focusNode,
  //             onKey: null,
  //             child: MongolTextField(
  //               controller: controller,
  //               maxLines: 3,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //     await tester.pump();
  //   }

  //   testMongolWidgets('Shift test 1', (tester) async {
  //     await setupWidget(tester);
  //     const String testValue = 'a big house';
  //     await tester.enterText(find.byType(MongolTextField), testValue);

  //     await tester.idle();
  //     // Need to wait for selection to catch up.
  //     await tester.pump();
  //     await tester.tap(find.byType(MongolTextField));
  //     await tester.pumpAndSettle();

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         -1);
  //   });

  //   testMongolWidgets('Shift test 2', (tester) async {
  //     await setupWidget(tester);

  //     const String testValue = 'abcdefghi';
  //     await tester.showKeyboard(find.byType(MongolTextField));
  //     tester.testTextInput.updateEditingValue(const TextEditingValue(
  //       text: testValue,
  //       selection: TextSelection.collapsed(offset: 3),
  //       composing: TextRange(start: 0, end: testValue.length),
  //     ));
  //     await tester.pump();

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         1);
  //   });

  //   testMongolWidgets('Control Shift test', (tester) async {
  //     await setupWidget(tester);
  //     const String testValue = 'their big house';
  //     await tester.enterText(find.byType(MongolTextField), testValue);

  //     await tester.idle();
  //     await tester.tap(find.byType(MongolTextField));
  //     await tester.pumpAndSettle();
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         5);
  //   });

  //   testMongolWidgets('Right and left test', (tester) async {
  //     await setupWidget(tester);
  //     const String testValue = 'a big house';
  //     await tester.enterText(find.byType(MongolTextField), testValue);

  //     await tester.idle();
  //     // Need to wait for selection to catch up.
  //     await tester.pump();
  //     await tester.tap(find.byType(MongolTextField));
  //     await tester.pumpAndSettle();

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         -11);

  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         0);
  //   });

  //   testMongolWidgets('Right and left test 2', (tester) async {
  //     await setupWidget(tester);
  //     const String testValue =
  //         'a big house\njumped over a mouse\nOne more line yay'; // 11 \n 19
  //     await tester.enterText(find.byType(MongolTextField), testValue);

  //     await tester.idle();
  //     await tester.tap(find.byType(MongolTextField));
  //     await tester.pumpAndSettle();

  //     for (int i = 0; i < 5; i += 1) {
  //       await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
  //       await tester.pumpAndSettle();
  //       await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
  //       await tester.pumpAndSettle();
  //     }
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         12);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         32);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         12);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         0);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         -5);
  //   });

  //   testMongolWidgets('Read only keyboard selection test', (tester) async {
  //     final TextEditingController controller =
  //         TextEditingController(text: 'readonly');
  //     await tester.pumpWidget(
  //       overlay(
  //         child: MongolTextField(
  //           controller: controller,
  //           readOnly: true,
  //         ),
  //       ),
  //     );

  //     await tester.idle();
  //     await tester.tap(find.byType(MongolTextField));
  //     await tester.pumpAndSettle();

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
  //     expect(
  //         controller.selection.extentOffset - controller.selection.baseOffset,
  //         -1);
  //   });
  // });

  // testMongolWidgets('Copy paste test', (tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   final TextEditingController controller = TextEditingController();
  //   final MongolTextField textField = MongolTextField(
  //     controller: controller,
  //     maxLines: 3,
  //   );

  //   String clipboardContent = '';
  //   SystemChannels.platform
  //       .setMockMethodCallHandler((MethodCall methodCall) async {
  //     if (methodCall.method == 'Clipboard.setData') {
  //       clipboardContent = methodCall.arguments['text'] as String;
  //     } else if (methodCall.method == 'Clipboard.getData') {
  //       return <String, dynamic>{'text': clipboardContent};
  //     }
  //     return null;
  //   });

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: null,
  //           child: textField,
  //         ),
  //       ),
  //     ),
  //   );
  //   focusNode.requestFocus();
  //   await tester.pump();

  //   const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
  //   await tester.enterText(find.byType(MongolTextField), testValue);

  //   await tester.idle();
  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pumpAndSettle();

  //   // Select the first 5 characters
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

  //   // Copy them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  //   await tester.pumpAndSettle();
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   expect(clipboardContent, 'a big');

  //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //   await tester.pumpAndSettle();

  //   // Paste them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
  //   await tester.pumpAndSettle();
  //   await tester.pump(const Duration(milliseconds: 200));
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   const String expected = 'a biga big house\njumped over a mouse';
  //   expect(findMongol.text(expected), findsOneWidget,
  //       reason: 'Because text contains ${controller.text}');
  // });

  // testMongolWidgets('Copy paste obscured text test', (tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   final TextEditingController controller = TextEditingController();
  //   final MongolTextField textField = MongolTextField(
  //     controller: controller,
  //     obscureText: true,
  //   );

  //   String clipboardContent = '';
  //   SystemChannels.platform
  //       .setMockMethodCallHandler((MethodCall methodCall) async {
  //     if (methodCall.method == 'Clipboard.setData') {
  //       clipboardContent = methodCall.arguments['text'] as String;
  //     } else if (methodCall.method == 'Clipboard.getData') {
  //       return <String, dynamic>{'text': clipboardContent};
  //     }
  //     return null;
  //   });

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: null,
  //           child: textField,
  //         ),
  //       ),
  //     ),
  //   );
  //   focusNode.requestFocus();
  //   await tester.pump();

  //   const String testValue = 'a big house jumped over a mouse';
  //   await tester.enterText(find.byType(MongolTextField), testValue);

  //   await tester.idle();
  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pumpAndSettle();

  //   // Select the first 5 characters
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

  //   // Copy them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  //   await tester.pumpAndSettle();
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   expect(clipboardContent, 'a big');

  //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //   await tester.pumpAndSettle();

  //   // Paste them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
  //   await tester.pumpAndSettle();
  //   await tester.pump(const Duration(milliseconds: 200));
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   const String expected = 'a biga big house jumped over a mouse';
  //   expect(findMongol.text(expected), findsOneWidget,
  //       reason: 'Because text contains ${controller.text}');
  // });

  // testMongolWidgets('Cut test', (tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   final TextEditingController controller = TextEditingController();
  //   final MongolTextField textField = MongolTextField(
  //     controller: controller,
  //     maxLines: 3,
  //   );
  //   String clipboardContent = '';
  //   SystemChannels.platform
  //       .setMockMethodCallHandler((MethodCall methodCall) async {
  //     if (methodCall.method == 'Clipboard.setData') {
  //       clipboardContent = methodCall.arguments['text'] as String;
  //     } else if (methodCall.method == 'Clipboard.getData') {
  //       return <String, dynamic>{'text': clipboardContent};
  //     }
  //     return null;
  //   });

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: null,
  //           child: textField,
  //         ),
  //       ),
  //     ),
  //   );
  //   focusNode.requestFocus();
  //   await tester.pump();

  //   const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
  //   await tester.enterText(find.byType(MongolTextField), testValue);

  //   await tester.idle();
  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pumpAndSettle();

  //   // Select the first 5 characters
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();
  //   }

  //   // Cut them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
  //   await tester.pumpAndSettle();
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   expect(clipboardContent, 'a big');

  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //   }

  //   // Paste them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
  //   await tester.pumpAndSettle();
  //   await tester.pump(const Duration(milliseconds: 200));
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   const String expected = ' housa bige\njumped over a mouse';
  //   expect(findMongol.text(expected), findsOneWidget);
  // });

  // testMongolWidgets('Cut obscured text test', (tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   final TextEditingController controller = TextEditingController();
  //   final MongolTextField textField = MongolTextField(
  //     controller: controller,
  //     obscureText: true,
  //   );
  //   String clipboardContent = '';
  //   SystemChannels.platform
  //       .setMockMethodCallHandler((MethodCall methodCall) async {
  //     if (methodCall.method == 'Clipboard.setData') {
  //       clipboardContent = methodCall.arguments['text'] as String;
  //     } else if (methodCall.method == 'Clipboard.getData') {
  //       return <String, dynamic>{'text': clipboardContent};
  //     }
  //     return null;
  //   });

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: null,
  //           child: textField,
  //         ),
  //       ),
  //     ),
  //   );
  //   focusNode.requestFocus();
  //   await tester.pump();

  //   const String testValue = 'a big house jumped over a mouse';
  //   await tester.enterText(find.byType(MongolTextField), testValue);

  //   await tester.idle();
  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pumpAndSettle();

  //   // Select the first 5 characters
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();
  //   }

  //   // Cut them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
  //   await tester.pumpAndSettle();
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   expect(clipboardContent, 'a big');

  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //   }

  //   // Paste them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
  //   await tester.pumpAndSettle();
  //   await tester.pump(const Duration(milliseconds: 200));
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   const String expected = ' housa bige jumped over a mouse';
  //   expect(findMongol.text(expected), findsOneWidget);
  // });

  testMongolWidgets('Select all test', (tester) async {
    final FocusNode focusNode = FocusNode();
    final TextEditingController controller = TextEditingController();
    final MongolTextField textField = MongolTextField(
      controller: controller,
      maxLines: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: null,
            child: textField,
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
    await tester.enterText(find.byType(MongolTextField), testValue);

    await tester.idle();
    await tester.tap(find.byType(MongolTextField));
    await tester.pumpAndSettle();

    // Select All
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    // Delete them
    await tester.sendKeyDownEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    const String expected = '';
    expect(findMongol.text(expected), findsOneWidget);
  });

  testMongolWidgets('Delete test', (tester) async {
    final FocusNode focusNode = FocusNode();
    final TextEditingController controller = TextEditingController();
    final MongolTextField textField = MongolTextField(
      controller: controller,
      maxLines: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: null,
            child: textField,
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
    await tester.enterText(find.byType(MongolTextField), testValue);

    await tester.idle();
    await tester.tap(find.byType(MongolTextField));
    await tester.pumpAndSettle();

    // Delete
    for (int i = 0; i < 6; i += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
    }

    const String expected = 'house\njumped over a mouse';
    expect(findMongol.text(expected), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    const String expected2 = '';
    expect(findMongol.text(expected2), findsOneWidget);
  });

  // testMongolWidgets('Changing positions of text fields', (tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   final List<RawKeyEvent> events = <RawKeyEvent>[];

  //   final TextEditingController c1 = TextEditingController();
  //   final TextEditingController c2 = TextEditingController();
  //   final Key key1 = UniqueKey();
  //   final Key key2 = UniqueKey();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: events.add,
  //           child: Row(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: <Widget>[
  //               MongolTextField(
  //                 key: key1,
  //                 controller: c1,
  //                 maxLines: 3,
  //               ),
  //               MongolTextField(
  //                 key: key2,
  //                 controller: c2,
  //                 maxLines: 3,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   const String testValue = 'a big house';
  //   await tester.enterText(find.byType(MongolTextField).first, testValue);

  //   await tester.idle();
  //   // Need to wait for selection to catch up.
  //   await tester.pump();
  //   await tester.tap(find.byType(MongolTextField).first);
  //   await tester.pumpAndSettle();

  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

  //   expect(c1.selection.extentOffset - c1.selection.baseOffset, -5);

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: events.add,
  //           child: Row(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: <Widget>[
  //               MongolTextField(
  //                 key: key2,
  //                 controller: c2,
  //                 maxLines: 3,
  //               ),
  //               MongolTextField(
  //                 key: key1,
  //                 controller: c1,
  //                 maxLines: 3,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

  //   expect(c1.selection.extentOffset - c1.selection.baseOffset, -10);
  // });

  // testMongolWidgets('Changing focus test', (tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   final List<RawKeyEvent> events = <RawKeyEvent>[];

  //   final TextEditingController c1 = TextEditingController();
  //   final TextEditingController c2 = TextEditingController();
  //   final Key key1 = UniqueKey();
  //   final Key key2 = UniqueKey();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: events.add,
  //           child: Row(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: <Widget>[
  //               MongolTextField(
  //                 key: key1,
  //                 controller: c1,
  //                 maxLines: 3,
  //               ),
  //               MongolTextField(
  //                 key: key2,
  //                 controller: c2,
  //                 maxLines: 3,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   const String testValue = 'a big house';
  //   await tester.enterText(find.byType(MongolTextField).first, testValue);
  //   await tester.idle();
  //   await tester.pump();

  //   await tester.idle();
  //   await tester.tap(find.byType(MongolTextField).first);
  //   await tester.pumpAndSettle();

  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

  //   expect(c1.selection.extentOffset - c1.selection.baseOffset, -5);
  //   expect(c2.selection.extentOffset - c2.selection.baseOffset, 0);

  //   await tester.enterText(find.byType(MongolTextField).last, testValue);
  //   await tester.idle();
  //   await tester.pump();

  //   await tester.idle();
  //   await tester.tap(find.byType(MongolTextField).last);
  //   await tester.pumpAndSettle();

  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

  //   expect(c1.selection.extentOffset - c1.selection.baseOffset, 0);
  //   expect(c2.selection.extentOffset - c2.selection.baseOffset, -5);
  // });

  // testMongolWidgets('Caret works when maxLines is null', (tester) async {
  //   final TextEditingController controller = TextEditingController();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         controller: controller,
  //         maxLines: null,
  //       ),
  //     ),
  //   );

  //   const String testValue = 'x';
  //   await tester.enterText(find.byType(MongolTextField), testValue);
  //   await skipPastScrollingAnimation(tester);
  //   expect(controller.selection.baseOffset, -1);

  //   // Tap the selection handle to bring up the "paste / select all" menu.
  //   await tester.tapAt(textOffsetToPosition(tester, 0));
  //   await tester.pump();
  //   await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is

  //   // Confirm that the selection was updated.
  //   expect(controller.selection.baseOffset, 0);
  // });

  // testMongolWidgets('MongolTextField baseline alignment no-strut', (tester) async {
  //   final TextEditingController controllerA = TextEditingController(text: 'A');
  //   final TextEditingController controllerB = TextEditingController(text: 'B');
  //   final Key keyA = UniqueKey();
  //   final Key keyB = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.baseline,
  //         textBaseline: TextBaseline.alphabetic,
  //         children: <Widget>[
  //           Expanded(
  //             child: MongolTextField(
  //               key: keyA,
  //               decoration: null,
  //               controller: controllerA,
  //               style: const TextStyle(fontSize: 10.0),
  //               strutStyle: StrutStyle.disabled,
  //             ),
  //           ),
  //           const Text(
  //             'abc',
  //             style: TextStyle(fontSize: 20.0),
  //           ),
  //           Expanded(
  //             child: MongolTextField(
  //               key: keyB,
  //               decoration: null,
  //               controller: controllerB,
  //               style: const TextStyle(fontSize: 30.0),
  //               strutStyle: StrutStyle.disabled,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );

  //   // The Ahem font extends 0.2 * fontSize below the baseline.
  //   // So the three row elements line up like this:
  //   //
  //   //  A  abc  B
  //   //  ---------   baseline
  //   //  2  4    6   space below the baseline = 0.2 * fontSize
  //   //  ---------   rowBottomY

  //   final double rowBottomY = tester.getBottomLeft(find.byType(Row)).dy;
  //   expect(tester.getBottomLeft(find.byKey(keyA)).dy, moreOrLessEquals(rowBottomY - 4.0, epsilon: 0.001));
  //   expect(tester.getBottomLeft(findMongol.text('abc')).dy, moreOrLessEquals(rowBottomY - 2.0, epsilon: 0.001));
  //   expect(tester.getBottomLeft(find.byKey(keyB)).dy, rowBottomY);
  // });

  // testMongolWidgets('MongolTextField baseline alignment', (tester) async {
  //   final TextEditingController controllerA = TextEditingController(text: 'A');
  //   final TextEditingController controllerB = TextEditingController(text: 'B');
  //   final Key keyA = UniqueKey();
  //   final Key keyB = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.baseline,
  //         textBaseline: TextBaseline.alphabetic,
  //         children: <Widget>[
  //           Expanded(
  //             child: MongolTextField(
  //               key: keyA,
  //               decoration: null,
  //               controller: controllerA,
  //               style: const TextStyle(fontSize: 10.0),
  //             ),
  //           ),
  //           const Text(
  //             'abc',
  //             style: TextStyle(fontSize: 20.0),
  //           ),
  //           Expanded(
  //             child: MongolTextField(
  //               key: keyB,
  //               decoration: null,
  //               controller: controllerB,
  //               style: const TextStyle(fontSize: 30.0),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );

  //   final double rowRightX = tester.getTopRight(find.byType(Column)).dx;
  //   // The values here should match the version with strut disabled ('MongolTextField baseline alignment no-strut')
  //   expect(tester.getTopRight(find.byKey(keyA)).dx, moreOrLessEquals(rowRightX - 4.0, epsilon: 0.001));
  //   expect(tester.getTopRight(findMongol.text('abc')).dx, moreOrLessEquals(rowRightX - 2.0, epsilon: 0.001));
  //   expect(tester.getTopRight(find.byKey(keyB)).dx, rowRightX);
  // });

  // testMongolWidgets('MongolTextField semantics include label when unfocused and label/hint when focused', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController(text: 'value');
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //         decoration: const InputDecoration(
  //           hintText: 'hint',
  //           labelText: 'label',
  //         ),
  //       ),
  //     ),
  //   );

  //   final SemanticsNode node = tester.getSemantics(find.byKey(key));

  //   expect(node.label, 'label');
  //   expect(node.value, 'value');

  //   // Focus text field.
  //   await tester.tap(find.byKey(key));
  //   await tester.pump();

  //   expect(node.label, 'label\nhint');
  //   expect(node.value, 'value');
  //   semantics.dispose();
  // });

  // testMongolWidgets('MongolTextField semantics always include label when no hint is given', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController(text: 'value');
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //         decoration: const InputDecoration(
  //           labelText: 'label',
  //         ),
  //       ),
  //     ),
  //   );

  //   final SemanticsNode node = tester.getSemantics(find.byKey(key));

  //   expect(node.label, 'label');
  //   expect(node.value, 'value');

  //   // Focus text field.
  //   await tester.tap(find.byKey(key));
  //   await tester.pump();

  //   expect(node.label, 'label');
  //   expect(node.value, 'value');
  //   semantics.dispose();
  // });

  // testMongolWidgets('MongolTextField semantics always include hint when no label is given', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController(text: 'value');
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //         decoration: const InputDecoration(
  //           hintText: 'hint',
  //         ),
  //       ),
  //     ),
  //   );

  //   final SemanticsNode node = tester.getSemantics(find.byKey(key));

  //   expect(node.label, 'hint');
  //   expect(node.value, 'value');

  //   // Focus text field.
  //   await tester.tap(find.byKey(key));
  //   await tester.pump();

  //   expect(node.label, 'hint');
  //   expect(node.value, 'value');
  //   semantics.dispose();
  // });

  // testMongolWidgets('MongolTextField semantics', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController();
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 textDirection: TextDirection.ltr,
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   controller.text = 'Guten Tag';
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 textDirection: TextDirection.ltr,
  //                 value: 'Guten Tag',
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   await tester.tap(find.byKey(key));
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 textDirection: TextDirection.ltr,
  //                 value: 'Guten Tag',
  //                 textSelection: const TextSelection.collapsed(offset: 9),
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   SemanticsAction.moveCursorBackwardByCharacter,
  //                   SemanticsAction.moveCursorBackwardByWord,
  //                   SemanticsAction.setSelection,
  //                   SemanticsAction.paste,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   controller.selection = const TextSelection.collapsed(offset: 4);
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 textDirection: TextDirection.ltr,
  //                 textSelection: const TextSelection.collapsed(offset: 4),
  //                 value: 'Guten Tag',
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   SemanticsAction.moveCursorBackwardByCharacter,
  //                   SemanticsAction.moveCursorForwardByCharacter,
  //                   SemanticsAction.moveCursorBackwardByWord,
  //                   SemanticsAction.moveCursorForwardByWord,
  //                   SemanticsAction.setSelection,
  //                   SemanticsAction.paste,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   controller.text = 'Schönen Feierabend';
  //   controller.selection = const TextSelection.collapsed(offset: 0);
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 textDirection: TextDirection.ltr,
  //                 textSelection: const TextSelection.collapsed(offset: 0),
  //                 value: 'Schönen Feierabend',
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   SemanticsAction.moveCursorForwardByCharacter,
  //                   SemanticsAction.moveCursorForwardByWord,
  //                   SemanticsAction.setSelection,
  //                   SemanticsAction.paste,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   semantics.dispose();
  // });

  // testMongolWidgets(
  //     'MongolTextField semantics, enableInteractiveSelection = false',
  //     (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController();
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //         enableInteractiveSelection: false,
  //       ),
  //     ),
  //   );

  //   await tester.tap(find.byKey(key));
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 textDirection: TextDirection.ltr,
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   // Absent the following because enableInteractiveSelection: false
  //                   // SemanticsAction.moveCursorBackwardByCharacter,
  //                   // SemanticsAction.moveCursorBackwardByWord,
  //                   // SemanticsAction.setSelection,
  //                   // SemanticsAction.paste,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   semantics.dispose();
  // });

  // testMongolWidgets('MongolTextField semantics for selections', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController()
  //     ..text = 'Hello';
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 value: 'Hello',
  //                 textDirection: TextDirection.ltr,
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   // Focus the text field
  //   await tester.tap(find.byKey(key));
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 value: 'Hello',
  //                 textSelection: const TextSelection.collapsed(offset: 5),
  //                 textDirection: TextDirection.ltr,
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   SemanticsAction.moveCursorBackwardByCharacter,
  //                   SemanticsAction.moveCursorBackwardByWord,
  //                   SemanticsAction.setSelection,
  //                   SemanticsAction.paste,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   controller.selection = const TextSelection(baseOffset: 5, extentOffset: 3);
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: 1,
  //                 value: 'Hello',
  //                 textSelection:
  //                     const TextSelection(baseOffset: 5, extentOffset: 3),
  //                 textDirection: TextDirection.ltr,
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   SemanticsAction.moveCursorBackwardByCharacter,
  //                   SemanticsAction.moveCursorForwardByCharacter,
  //                   SemanticsAction.moveCursorBackwardByWord,
  //                   SemanticsAction.moveCursorForwardByWord,
  //                   SemanticsAction.setSelection,
  //                   SemanticsAction.paste,
  //                   SemanticsAction.cut,
  //                   SemanticsAction.copy,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   semantics.dispose();
  // });

  // testMongolWidgets('MongolTextField change selection with semantics',
  //     (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final SemanticsOwner semanticsOwner =
  //       tester.binding.pipelineOwner.semanticsOwner!;
  //   final TextEditingController controller = TextEditingController()
  //     ..text = 'Hello';
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   // Focus the text field
  //   await tester.tap(find.byKey(key));
  //   await tester.pump();

  //   const int inputFieldId = 1;

  //   expect(
  //       controller.selection,
  //       const TextSelection.collapsed(
  //           offset: 5, affinity: TextAffinity.upstream));
  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: inputFieldId,
  //                 value: 'Hello',
  //                 textSelection: const TextSelection.collapsed(offset: 5),
  //                 textDirection: TextDirection.ltr,
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   SemanticsAction.moveCursorBackwardByCharacter,
  //                   SemanticsAction.moveCursorBackwardByWord,
  //                   SemanticsAction.setSelection,
  //                   SemanticsAction.paste,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   // move cursor back once
  //   semanticsOwner.performAction(
  //       inputFieldId, SemanticsAction.setSelection, <dynamic, dynamic>{
  //     'base': 4,
  //     'extent': 4,
  //   });
  //   await tester.pump();
  //   expect(controller.selection, const TextSelection.collapsed(offset: 4));

  //   // move cursor to front
  //   semanticsOwner.performAction(
  //       inputFieldId, SemanticsAction.setSelection, <dynamic, dynamic>{
  //     'base': 0,
  //     'extent': 0,
  //   });
  //   await tester.pump();
  //   expect(controller.selection, const TextSelection.collapsed(offset: 0));

  //   // select all
  //   semanticsOwner.performAction(
  //       inputFieldId, SemanticsAction.setSelection, <dynamic, dynamic>{
  //     'base': 0,
  //     'extent': 5,
  //   });
  //   await tester.pump();
  //   expect(controller.selection,
  //       const TextSelection(baseOffset: 0, extentOffset: 5));
  //   expect(
  //       semantics,
  //       hasSemantics(
  //           TestSemantics.root(
  //             children: <TestSemantics>[
  //               TestSemantics.rootChild(
  //                 id: inputFieldId,
  //                 value: 'Hello',
  //                 textSelection:
  //                     const TextSelection(baseOffset: 0, extentOffset: 5),
  //                 textDirection: TextDirection.ltr,
  //                 actions: <SemanticsAction>[
  //                   SemanticsAction.tap,
  //                   SemanticsAction.moveCursorBackwardByCharacter,
  //                   SemanticsAction.moveCursorBackwardByWord,
  //                   SemanticsAction.setSelection,
  //                   SemanticsAction.paste,
  //                   SemanticsAction.cut,
  //                   SemanticsAction.copy,
  //                 ],
  //                 flags: <SemanticsFlag>[
  //                   SemanticsFlag.isTextField,
  //                   SemanticsFlag.isFocused,
  //                 ],
  //               ),
  //             ],
  //           ),
  //           ignoreTransform: true,
  //           ignoreRect: true));

  //   semantics.dispose();
  // });

  // testMongolWidgets(
  //     'Can activate MongolTextField with explicit controller via semantics ',
  //     (tester) async {
  //   // Regression test for https://github.com/flutter/flutter/issues/17801

  //   const String textInTextField = 'Hello';

  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final SemanticsOwner semanticsOwner =
  //       tester.binding.pipelineOwner.semanticsOwner!;
  //   final TextEditingController controller = TextEditingController()
  //     ..text = textInTextField;
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   const int inputFieldId = 1;

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics(
  //               id: inputFieldId,
  //               flags: <SemanticsFlag>[SemanticsFlag.isTextField],
  //               actions: <SemanticsAction>[SemanticsAction.tap],
  //               value: textInTextField,
  //               textDirection: TextDirection.ltr,
  //             ),
  //           ],
  //         ),
  //         ignoreRect: true,
  //         ignoreTransform: true,
  //       ));

  //   semanticsOwner.performAction(inputFieldId, SemanticsAction.tap);
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics(
  //               id: inputFieldId,
  //               flags: <SemanticsFlag>[
  //                 SemanticsFlag.isTextField,
  //                 SemanticsFlag.isFocused,
  //               ],
  //               actions: <SemanticsAction>[
  //                 SemanticsAction.tap,
  //                 SemanticsAction.moveCursorBackwardByCharacter,
  //                 SemanticsAction.moveCursorBackwardByWord,
  //                 SemanticsAction.setSelection,
  //                 SemanticsAction.paste,
  //               ],
  //               value: textInTextField,
  //               textDirection: TextDirection.ltr,
  //               textSelection: const TextSelection(
  //                 baseOffset: textInTextField.length,
  //                 extentOffset: textInTextField.length,
  //               ),
  //             ),
  //           ],
  //         ),
  //         ignoreRect: true,
  //         ignoreTransform: true,
  //       ));

  //   semantics.dispose();
  // });

  // testMongolWidgets('When clipboard empty, no semantics paste option',
  //     (tester) async {
  //   const String textInTextField = 'Hello';

  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final SemanticsOwner semanticsOwner =
  //       tester.binding.pipelineOwner.semanticsOwner!;
  //   final TextEditingController controller = TextEditingController()
  //     ..text = textInTextField;
  //   final Key key = UniqueKey();

  //   // Clear the clipboard.
  //   await Clipboard.setData(const ClipboardData(text: ''));

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //       ),
  //     ),
  //   );

  //   const int inputFieldId = 1;

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics(
  //               id: inputFieldId,
  //               flags: <SemanticsFlag>[SemanticsFlag.isTextField],
  //               actions: <SemanticsAction>[SemanticsAction.tap],
  //               value: textInTextField,
  //               textDirection: TextDirection.ltr,
  //             ),
  //           ],
  //         ),
  //         ignoreRect: true,
  //         ignoreTransform: true,
  //       ));

  //   semanticsOwner.performAction(inputFieldId, SemanticsAction.tap);
  //   await tester.pump();

  //   expect(
  //       semantics,
  //       hasSemantics(
  //         TestSemantics.root(
  //           children: <TestSemantics>[
  //             TestSemantics(
  //               id: inputFieldId,
  //               flags: <SemanticsFlag>[
  //                 SemanticsFlag.isTextField,
  //                 SemanticsFlag.isFocused,
  //               ],
  //               actions: <SemanticsAction>[
  //                 SemanticsAction.tap,
  //                 SemanticsAction.moveCursorBackwardByCharacter,
  //                 SemanticsAction.moveCursorBackwardByWord,
  //                 SemanticsAction.setSelection,
  //                 // No paste option.
  //               ],
  //               value: textInTextField,
  //               textDirection: TextDirection.ltr,
  //               textSelection: const TextSelection(
  //                 baseOffset: textInTextField.length,
  //                 extentOffset: textInTextField.length,
  //               ),
  //             ),
  //           ],
  //         ),
  //         ignoreRect: true,
  //         ignoreTransform: true,
  //       ));

  //   semantics.dispose();
  // });

  testMongolWidgets(
      'MongolTextField throws when not descended from a Material widget',
      (tester) async {
    const Widget textField = MongolTextField();
    await tester.pumpWidget(textField);
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.toString(), startsWith('No Material widget found.'));
    expect(
        exception.toString(),
        endsWith(
            ':\n  $textField\nThe ancestors of this widget were:\n  [root]'));
  });

  testMongolWidgets('MongolTextField loses focus when disabled',
      (tester) async {
    final FocusNode focusNode =
        FocusNode(debugLabel: 'MongolTextField Focus Node');

    await tester.pumpWidget(
      boilerplate(
        child: MongolTextField(
          focusNode: focusNode,
          autofocus: true,
          enabled: true,
        ),
      ),
    );
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(
      boilerplate(
        child: MongolTextField(
          focusNode: focusNode,
          autofocus: true,
          enabled: false,
        ),
      ),
    );
    expect(focusNode.hasFocus, isFalse);

    await tester.pumpWidget(
      boilerplate(
        child: Builder(builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              navigationMode: NavigationMode.directional,
            ),
            child: MongolTextField(
              focusNode: focusNode,
              autofocus: true,
              enabled: true,
            ),
          );
        }),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(
      boilerplate(
        child: Builder(builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              navigationMode: NavigationMode.directional,
            ),
            child: MongolTextField(
              focusNode: focusNode,
              autofocus: true,
              enabled: false,
            ),
          );
        }),
      ),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
  });

  // testMongolWidgets('MongolTextField displays text with text direction', (tester) async {
  //   await tester.pumpWidget(
  //     const MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           textDirection: TextDirection.rtl,
  //         ),
  //       ),
  //     ),
  //   );

  //   RenderEditable editable = findRenderEditable(tester);

  //   await tester.enterText(find.byType(MongolTextField), '0123456789101112');
  //   await tester.pumpAndSettle();
  //   Offset topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 10)).topLeft,
  //   );

  //   expect(topLeft.dx, equals(701));

  //   await tester.pumpWidget(
  //     const MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           textDirection: TextDirection.ltr,
  //         ),
  //       ),
  //     ),
  //   );

  //   editable = findRenderEditable(tester);

  //   await tester.enterText(find.byType(MongolTextField), '0123456789101112');
  //   await tester.pumpAndSettle();
  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 10)).topLeft,
  //   );

  //   expect(topLeft.dx, equals(160.0));
  // });

  // testMongolWidgets('MongolTextField semantics', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController();
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //         maxLength: 10,
  //         decoration: const InputDecoration(
  //           labelText: 'label',
  //           hintText: 'hint',
  //           helperText: 'helper',
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(semantics, hasSemantics(TestSemantics.root(
  //     children: <TestSemantics>[
  //       TestSemantics.rootChild(
  //         label: 'label',
  //         id: 1,
  //         textDirection: TextDirection.ltr,
  //         actions: <SemanticsAction>[
  //           SemanticsAction.tap,
  //         ],
  //         flags: <SemanticsFlag>[
  //           SemanticsFlag.isTextField,
  //         ],
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             id: 2,
  //             label: 'helper',
  //             textDirection: TextDirection.ltr,
  //           ),
  //           TestSemantics(
  //             id: 3,
  //             label: '10 characters remaining',
  //             textDirection: TextDirection.ltr,
  //           ),
  //         ],
  //       ),
  //     ],
  //   ), ignoreTransform: true, ignoreRect: true));

  //   await tester.tap(find.byType(MongolTextField));
  //   await tester.pump();

  //   expect(semantics, hasSemantics(TestSemantics.root(
  //     children: <TestSemantics>[
  //       TestSemantics.rootChild(
  //         label: 'label\nhint',
  //         id: 1,
  //         textDirection: TextDirection.ltr,
  //         textSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
  //         actions: <SemanticsAction>[
  //           SemanticsAction.tap,
  //           SemanticsAction.setSelection,
  //           SemanticsAction.paste,
  //         ],
  //         flags: <SemanticsFlag>[
  //           SemanticsFlag.isTextField,
  //           SemanticsFlag.isFocused,
  //         ],
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             id: 2,
  //             label: 'helper',
  //             textDirection: TextDirection.ltr,
  //           ),
  //           TestSemantics(
  //             id: 3,
  //             label: '10 characters remaining',
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.isLiveRegion,
  //             ],
  //             textDirection: TextDirection.ltr,
  //           ),
  //         ],
  //       ),
  //     ],
  //   ), ignoreTransform: true, ignoreRect: true));

  //   controller.text = 'hello';
  //   await tester.pump();
  //   semantics.dispose();
  // });

  // testMongolWidgets('InputDecoration counterText can have a semanticCounterText', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController();
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //         decoration: const InputDecoration(
  //           labelText: 'label',
  //           hintText: 'hint',
  //           helperText: 'helper',
  //           counterText: '0/10',
  //           semanticCounterText: '0 out of 10',
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(semantics, hasSemantics(TestSemantics.root(
  //     children: <TestSemantics>[
  //       TestSemantics.rootChild(
  //         label: 'label',
  //         textDirection: TextDirection.ltr,
  //         actions: <SemanticsAction>[
  //           SemanticsAction.tap,
  //         ],
  //         flags: <SemanticsFlag>[
  //           SemanticsFlag.isTextField,
  //         ],
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             label: 'helper',
  //             textDirection: TextDirection.ltr,
  //           ),
  //           TestSemantics(
  //             label: '0 out of 10',
  //             textDirection: TextDirection.ltr,
  //           ),
  //         ],
  //       ),
  //     ],
  //   ), ignoreTransform: true, ignoreRect: true, ignoreId: true));

  //   semantics.dispose();
  // });

  // testMongolWidgets('InputDecoration errorText semantics', (tester) async {
  //   final SemanticsTester semantics = SemanticsTester(tester);
  //   final TextEditingController controller = TextEditingController();
  //   final Key key = UniqueKey();

  //   await tester.pumpWidget(
  //     overlay(
  //       child: MongolTextField(
  //         key: key,
  //         controller: controller,
  //         decoration: const InputDecoration(
  //           labelText: 'label',
  //           hintText: 'hint',
  //           errorText: 'oh no!',
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(semantics, hasSemantics(TestSemantics.root(
  //     children: <TestSemantics>[
  //       TestSemantics.rootChild(
  //         label: 'label',
  //         textDirection: TextDirection.ltr,
  //         actions: <SemanticsAction>[
  //           SemanticsAction.tap,
  //         ],
  //         flags: <SemanticsFlag>[
  //           SemanticsFlag.isTextField,
  //         ],
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             label: 'oh no!',
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.isLiveRegion,
  //             ],
  //             textDirection: TextDirection.ltr,
  //           ),
  //         ],
  //       ),
  //     ],
  //   ), ignoreTransform: true, ignoreRect: true, ignoreId: true));

  //   semantics.dispose();
  // });

  testMongolWidgets(
      'floating label does not overlap with value at large textScaleFactors',
      (tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'Just some text');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData.fromWindow(ui.window)
                .copyWith(textScaleFactor: 4.0),
            child: Center(
              child: MongolTextField(
                decoration: const InputDecoration(
                    labelText: 'Label', border: UnderlineInputBorder()),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MongolTextField));
    final Rect labelRect = tester.getRect(findMongol.text('Label'));
    final Rect fieldRect = tester.getRect(findMongol.text('Just some text'));
    expect(labelRect.right, lessThanOrEqualTo(fieldRect.left));
  });

  // testMongolWidgets('MongolTextField scrolls into view but does not bounce (SingleChildScrollView)', (tester) async {
  //   // This is a regression test for https://github.com/flutter/flutter/issues/20485

  //   final Key textField1 = UniqueKey();
  //   final Key textField2 = UniqueKey();
  //   final ScrollController scrollController = ScrollController();

  //   double? minOffset;
  //   double? maxOffset;

  //   scrollController.addListener(() {
  //     final double offset = scrollController.offset;
  //     minOffset = math.min(minOffset ?? offset, offset);
  //     maxOffset = math.max(maxOffset ?? offset, offset);
  //   });

  //   Widget buildFrame(Axis scrollDirection) {
  //     return MaterialApp(
  //       home: Scaffold(
  //         body: SafeArea(
  //           child: SingleChildScrollView(
  //             physics: const BouncingScrollPhysics(),
  //             controller: scrollController,
  //             child: Row(
  //               children: <Widget>[
  //                 SizedBox( // visible when scrollOffset is 0.0
  //                   height: 100.0,
  //                   width: 100.0,
  //                   child: MongolTextField(key: textField1, scrollPadding: const EdgeInsets.all(200.0)),
  //                 ),
  //                 const SizedBox(
  //                   height: 800.0, // Same size as the frame. Initially
  //                   width: 600.0,  // textField2 is not visible
  //                 ),
  //                 SizedBox( // visible when scrollOffset is 200.0
  //                   height: 100.0,
  //                   width: 100.0,
  //                   child: MongolTextField(key: textField2, scrollPadding: const EdgeInsets.all(200.0)),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(buildFrame(Axis.horizontal));
  //   await tester.enterText(find.byKey(textField1), '1');
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
  //   await tester.pumpAndSettle();

  //   expect(minOffset, 0.0);
  //   expect(maxOffset, 200.0);

  //   minOffset = null;
  //   maxOffset = null;

  //   await tester.pumpWidget(buildFrame(Axis.vertical));
  //   await tester.enterText(find.byKey(textField1), '1');
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
  //   await tester.pumpAndSettle();

  //   expect(minOffset, 0.0);
  //   expect(maxOffset, 200.0);
  // });

  // testMongolWidgets('MongolTextField scrolls into view but does not bounce (ListView)', (tester) async {
  //   // This is a regression test for https://github.com/flutter/flutter/issues/20485

  //   final Key textField1 = UniqueKey();
  //   final Key textField2 = UniqueKey();
  //   final ScrollController scrollController = ScrollController();

  //   double? minOffset;
  //   double? maxOffset;

  //   scrollController.addListener(() {
  //     final double offset = scrollController.offset;
  //     minOffset = math.min(minOffset ?? offset, offset);
  //     maxOffset = math.max(maxOffset ?? offset, offset);
  //   });

  //   Widget buildFrame(Axis scrollDirection) {
  //     return MaterialApp(
  //       home: Scaffold(
  //         body: SafeArea(
  //           child: ListView(
  //             physics: const BouncingScrollPhysics(),
  //             controller: scrollController,
  //             children: <Widget>[
  //               SizedBox( // visible when scrollOffset is 0.0
  //                 height: 100.0,
  //                 width: 100.0,
  //                 child: MongolTextField(key: textField1, scrollPadding: const EdgeInsets.all(200.0)),
  //               ),
  //               const SizedBox(
  //                 height: 450.0, // 50.0 smaller than the overall frame so that both
  //                 width: 650.0,  // textfields are always partially visible.
  //               ),
  //               SizedBox( // visible when scrollOffset = 50.0
  //                 height: 100.0,
  //                 width: 100.0,
  //                 child: MongolTextField(key: textField2, scrollPadding: const EdgeInsets.all(200.0)),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(buildFrame(Axis.vertical));
  //   await tester.enterText(find.byKey(textField1), '1'); // textfield1 is visible
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
  //   await tester.pumpAndSettle();

  //   expect(minOffset, 0.0);
  //   expect(maxOffset, 50.0);

  //   minOffset = null;
  //   maxOffset = null;

  //   await tester.pumpWidget(buildFrame(Axis.horizontal));
  //   await tester.enterText(find.byKey(textField1), '1'); // textfield1 is visible
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
  //   await tester.pumpAndSettle();
  //   await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
  //   await tester.pumpAndSettle();

  //   expect(minOffset, 0.0);
  //   expect(maxOffset, 50.0);
  // });

  testMongolWidgets('onTap is called upon tap', (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          onTap: () {
            tapCount += 1;
          },
        ),
      ),
    );

    expect(tapCount, 0);
    await tester.tap(find.byType(MongolTextField));
    // Wait a bit so they're all single taps and not double taps.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(MongolTextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(MongolTextField));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tapCount, 3);
  });

  testMongolWidgets('onTap is not called, field is disabled', (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      overlay(
        child: MongolTextField(
          enabled: false,
          onTap: () {
            tapCount += 1;
          },
        ),
      ),
    );

    expect(tapCount, 0);
    await tester.tap(find.byType(MongolTextField));
    await tester.tap(find.byType(MongolTextField));
    await tester.tap(find.byType(MongolTextField));
    expect(tapCount, 0);
  });

  testMongolWidgets('Includes cursor for TextField', (tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/24612

    Widget buildFrame({
      required double cursorHeight,
      required MongolTextAlign textAlign,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IntrinsicHeight(
                  child: MongolTextField(
                    textAlign: textAlign,
                    cursorHeight: cursorHeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // A cursor of default size doesn't cause the MongolTextField to increase its
    // height.
    const String text = '1234';
    await tester.pumpWidget(buildFrame(
      cursorHeight: 2.0,
      textAlign: MongolTextAlign.top,
    ));
    await tester.enterText(find.byType(MongolTextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MongolTextField)).height, 66);

    // A thick cursor is counted in the height of the text and causes the
    // MongolTextField to increase its height.
    await tester.pumpWidget(buildFrame(
      cursorHeight: 18.0,
      textAlign: MongolTextAlign.top,
    ));
    await tester.enterText(find.byType(MongolTextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MongolTextField)).height, 82);

    // MongolTextField perfectly wraps the text plus the cursor regardless of
    // alignment.
    const double HEIGHT_OF_CHAR = 16.0;
    await tester.pumpWidget(buildFrame(
      cursorHeight: 18.0,
      textAlign: MongolTextAlign.top,
    ));
    await tester.enterText(find.byType(MongolTextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MongolTextField)).height,
        HEIGHT_OF_CHAR * text.length + 18.0);
    await tester.pumpWidget(buildFrame(
      cursorHeight: 18.0,
      textAlign: MongolTextAlign.bottom,
    ));
    await tester.enterText(find.byType(MongolTextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MongolTextField)).height,
        HEIGHT_OF_CHAR * text.length + 18.0);
  });

  testMongolWidgets('MongolTextField style is merged with theme',
      (tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/23994

    final ThemeData themeData = ThemeData(
      textTheme: TextTheme(
        subtitle1: TextStyle(
          color: Colors.blue[500],
        ),
      ),
    );

    Widget buildFrame(TextStyle style) {
      return MaterialApp(
        theme: themeData,
        home: Material(
          child: Center(
            child: MongolTextField(
              style: style,
            ),
          ),
        ),
      );
    }

    // Empty TextStyle is overridden by theme
    await tester.pumpWidget(buildFrame(const TextStyle()));
    MongolEditableText editableText =
        tester.widget(find.byType(MongolEditableText));
    expect(editableText.style.color, themeData.textTheme.subtitle1!.color);
    expect(editableText.style.background,
        themeData.textTheme.subtitle1!.background);
    expect(editableText.style.shadows, themeData.textTheme.subtitle1!.shadows);
    expect(editableText.style.decoration,
        themeData.textTheme.subtitle1!.decoration);
    expect(editableText.style.locale, themeData.textTheme.subtitle1!.locale);
    expect(editableText.style.wordSpacing,
        themeData.textTheme.subtitle1!.wordSpacing);

    // Properties set on TextStyle override theme
    const Color setColor = Colors.red;
    await tester.pumpWidget(buildFrame(const TextStyle(color: setColor)));
    editableText = tester.widget(find.byType(MongolEditableText));
    expect(editableText.style.color, setColor);

    // inherit: false causes nothing to be merged in from theme
    await tester.pumpWidget(buildFrame(const TextStyle(
      fontSize: 24.0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    )));
    editableText = tester.widget(find.byType(MongolEditableText));
    expect(editableText.style.color, isNull);
  });

  testMongolWidgets('style enforces required fields', (tester) async {
    Widget buildFrame(TextStyle style) {
      return MaterialApp(
        home: Material(
          child: MongolTextField(
            style: style,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(const TextStyle(
      inherit: false,
      fontSize: 12.0,
      textBaseline: TextBaseline.alphabetic,
    )));
    expect(tester.takeException(), isNull);

    // With inherit not set to false, will pickup required fields from theme
    await tester.pumpWidget(buildFrame(const TextStyle(
      fontSize: 12.0,
    )));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildFrame(const TextStyle(
      inherit: false,
      fontSize: 12.0,
    )));
    expect(tester.takeException(), isNotNull);
  });

  // testMongolWidgets('tap moves cursor to the edge of the word it tapped',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart =
  //       tester.getTopLeft(find.byType(MongolTextField));

  //   await tester.tapAt(textfieldStart + const Offset(9.0, 50.0));
  //   await tester.pump();

  //   // We moved the cursor.
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
  //   );

  //   // But don't trigger the toolbar.
  //   expect(find.byType(CupertinoButton), findsNothing);
  // },
  //     variant: const TargetPlatformVariant(
  //         <TargetPlatform>{TargetPlatform.iOS, TargetPlatform.macOS}));

  // testMongolWidgets(
  //     'tap with a mouse does not move cursor to the edge of the word',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart =
  //       tester.getTopLeft(find.byType(MongolTextField));

  //   final TestGesture gesture = await tester.startGesture(
  //     textfieldStart + const Offset(9.0, 50.0),
  //     pointer: 1,
  //     kind: PointerDeviceKind.mouse,
  //   );
  //   addTearDown(gesture.removePointer);
  //   await gesture.up();

  //   // Cursor at tap position, not at word edge.
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(
  //         offset: 3, affinity: TextAffinity.downstream),
  //   );
  // },
  //     variant: const TargetPlatformVariant(
  //         <TargetPlatform>{TargetPlatform.iOS, TargetPlatform.macOS}));

  testMongolWidgets('tap moves cursor to the position tapped', (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              controller: controller,
            ),
          ),
        ),
      ),
    );

    final Offset textfieldStart =
        tester.getTopLeft(find.byType(MongolTextField));

    await tester.tapAt(textfieldStart + const Offset(9.0, 50.0));
    await tester.pump();

    // We moved the cursor.
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 3),
    );

    // But don't trigger the toolbar.
    expect(find.byType(TextButton), findsNothing);
  },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.fuchsia,
        TargetPlatform.linux,
        TargetPlatform.windows
      }));

  // testMongolWidgets('two slow taps do not trigger a word selection',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart =
  //       tester.getTopLeft(find.byType(MongolTextField));

  //   await tester.tapAt(textfieldStart + const Offset(9.0, 50.0));
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await tester.tapAt(textfieldStart + const Offset(9.0, 50.0));
  //   await tester.pump();

  //   // Plain collapsed selection.
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
  //   );

  //   // No toolbar.
  //   expect(find.byType(CupertinoButton), findsNothing);
  // },
  //     variant: const TargetPlatformVariant(
  //         <TargetPlatform>{TargetPlatform.iOS, TargetPlatform.macOS}));

  // testMongolWidgets(
  //   'double tap selects word and first tap of double tap moves cursor',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     // This tap just puts the cursor somewhere different than where the double
  //     // tap will occur to test that the double tap moves the existing cursor first.
  //     await tester.tapAt(textfieldStart + const Offset(9.0, 50.0));
  //     await tester.pump(const Duration(milliseconds: 500));

  //     await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
  //     await tester.pumpAndSettle();

  //     // Second tap selects the word around the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );

  //     // Selected text shows 3 toolbar buttons.
  //     expect(find.byType(CupertinoButton), findsNWidgets(3));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'double tap selects word and first tap of double tap moves cursor and shows toolbar',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     // This tap just puts the cursor somewhere different than where the double
  //     // tap will occur to test that the double tap moves the existing cursor first.
  //     await tester.tapAt(textfieldStart + const Offset(9.0, 50.0));
  //     await tester.pump(const Duration(milliseconds: 500));

  //     await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 9),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
  //     await tester.pumpAndSettle();

  //     // Second tap selects the word around the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );

  //     // Selected text shows 4 toolbar buttons: cut, copy, paste, select all
  //     expect(find.byType(TextButton), findsNWidgets(4));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.windows }));

  testMongolWidgets('Custom toolbar test - Android text selection controls',
      (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
                controller: controller,
                selectionControls: materialTextSelectionControls),
          ),
        ),
      ),
    );

    final Offset textfieldStart =
        tester.getTopLeft(find.byType(MongolTextField));

    await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
    await tester.pumpAndSettle();

    // Selected text shows 4 toolbar buttons: cut, copy, paste, select all
    expect(find.byType(TextButton), findsNWidgets(4));
  }, variant: TargetPlatformVariant.all());

  testMongolWidgets('Custom toolbar test - Cupertino text selection controls',
      (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              controller: controller,
              selectionControls: cupertinoTextSelectionControls,
            ),
          ),
        ),
      ),
    );

    final Offset textfieldStart =
        tester.getTopLeft(find.byType(MongolTextField));

    await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
    await tester.pumpAndSettle();

    // Selected text shows 3 toolbar buttons: cut, copy, paste
    expect(find.byType(CupertinoButton), findsNWidgets(3));
  }, variant: TargetPlatformVariant.all());

  testMongolWidgets('selectionControls is passed to MongolEditableText',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Scaffold(
            body: MongolTextField(
              selectionControls: materialTextSelectionControls,
            ),
          ),
        ),
      ),
    );

    final MongolEditableText widget =
        tester.widget(find.byType(MongolEditableText));
    expect(widget.selectionControls, equals(materialTextSelectionControls));
  });

  testMongolWidgets('double tap on top of cursor also selects word',
      (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              controller: controller,
            ),
          ),
        ),
      ),
    );

    // Tap to put the cursor after the "w".
    const int index = 3;
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: index),
    );

    // Double tap on the same location.
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pump(const Duration(milliseconds: 50));

    // First tap doesn't change the selection
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: index),
    );

    // Second tap selects the word around the cursor.
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pumpAndSettle();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 7),
    );

    // Selected text shows 4 toolbar buttons: cut, copy, paste, select all
    expect(find.byType(IconButton), findsNWidgets(4));
  },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.fuchsia,
        TargetPlatform.linux,
        TargetPlatform.windows
      }));

  // testMongolWidgets(
  //   'double double tap just shows the selection menu',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: '',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     // Double tap on the same location shows the selection menu.
  //     await tester.tapAt(textOffsetToPosition(tester, 0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     await tester.tapAt(textOffsetToPosition(tester, 0));
  //     await tester.pumpAndSettle();
  //     expect(findMongol.text('Paste'), findsOneWidget);

  //     // Double tap again keeps the selection menu visible.
  //     await tester.tapAt(textOffsetToPosition(tester, 0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     await tester.tapAt(textOffsetToPosition(tester, 0));
  //     await tester.pumpAndSettle();
  //     expect(findMongol.text('Paste'), findsOneWidget);
  //   },
  // );

  // testMongolWidgets(
  //   'double long press just shows the selection menu',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: '',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     // Long press shows the selection menu.
  //     await tester.longPressAt(textOffsetToPosition(tester, 0));
  //     await tester.pumpAndSettle();
  //     expect(findMongol.text('Paste'), findsOneWidget);

  //     // Long press again keeps the selection menu visible.
  //     await tester.longPressAt(textOffsetToPosition(tester, 0));
  //     await tester.pump();
  //     expect(findMongol.text('Paste'), findsOneWidget);
  //   },
  // );

  // testMongolWidgets(
  //   'A single tap hides the selection menu',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: '',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     // Long press shows the selection menu.
  //     await tester.longPress(find.byType(MongolTextField));
  //     await tester.pumpAndSettle();
  //     expect(findMongol.text('Paste'), findsOneWidget);

  //     // Tap hides the selection menu.
  //     await tester.tap(find.byType(MongolTextField));
  //     await tester.pump();
  //     expect(findMongol.text('Paste'), findsNothing);
  //   },
  // );

  // testMongolWidgets(
  //   'Long press on an autofocused field shows the selection menu',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: '',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               autofocus: true,
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //     // This extra pump allows the selection set by autofocus to propagate to
  //     // the RenderEditable.
  //     await tester.pump();

  //     // Long press shows the selection menu.
  //     expect(findMongol.text('Paste'), findsNothing);
  //     await tester.longPress(find.byType(MongolTextField));
  //     await tester.pumpAndSettle();
  //     expect(findMongol.text('Paste'), findsOneWidget);
  //   },
  // );

  // testMongolWidgets(
  //   'double tap hold selects word',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     final TestGesture gesture =
  //        await tester.startGesture(textfieldStart + const Offset(9.0, 150.0));
  //     // Hold the press.
  //     await tester.pumpAndSettle();

  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );

  //     // Selected text shows 3 toolbar buttons.
  //     expect(find.byType(CupertinoButton), findsNWidgets(3));

  //     await gesture.up();
  //     await tester.pump();

  //     // Still selected.
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );
  //     // The toolbar is still showing.
  //     expect(find.byType(CupertinoButton), findsNWidgets(3));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'tap after a double tap select is not affected',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 500));

  //     await tester.tapAt(textfieldStart + const Offset(100.0, 9.0));
  //     await tester.pump();

  //     // Plain collapsed selection at the edge of first word. In iOS 12, the
  //     // first tap after a double tap ends up putting the cursor at where
  //     // you tapped instead of the edge like every other single tap. This is
  //     // likely a bug in iOS 12 and not present in other versions.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
  //     );

  //     // No toolbar.
  //     expect(find.byType(CupertinoButton), findsNothing);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'long press moves cursor to the exact long press position and shows toolbar',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.longPressAt(textfieldStart + const Offset(50.0, 9.0));
  //     await tester.pumpAndSettle();

  //     // Collapsed cursor for iOS long press.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 3),
  //     );

  //     // Collapsed toolbar shows 2 buttons.
  //     expect(find.byType(CupertinoButton), findsNWidgets(2));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'long press selects word and shows toolbar',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.longPressAt(textfieldStart + const Offset(9.0, 50.0));
  //     await tester.pumpAndSettle();

  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 0, extentOffset: 7),
  //     );

  //     // Collapsed toolbar shows 4 buttons: cut, copy, paste, select all
  //     expect(find.byType(TextButton), findsNWidgets(4));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.windows }));

  // testMongolWidgets(
  //   'long press tap cannot initiate a double tap',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.longPressAt(textfieldStart + const Offset(50.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));

  //     await tester.tapAt(textfieldStart + const Offset(50.0, 9.0));
  //     await tester.pump();

  //     // We ended up moving the cursor to the edge of the same word and dismissed
  //     // the toolbar.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
  //     );

  //     // Collapsed toolbar shows 2 buttons.
  //     expect(find.byType(CupertinoButton), findsNothing);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'long press drag moves the cursor under the drag and shows toolbar on lift',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     final TestGesture gesture =
  //         await tester.startGesture(textfieldStart + const Offset(50.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 500));

  //     // Long press on iOS shows collapsed selection cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 3, affinity: TextAffinity.downstream),
  //     );
  //     // Cursor move doesn't trigger a toolbar initially.
  //     expect(find.byType(CupertinoButton), findsNothing);

  //     await gesture.moveBy(const Offset(50, 0));
  //     await tester.pump();

  //     // The selection position is now moved with the drag.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 6, affinity: TextAffinity.downstream),
  //     );
  //     // Still no toolbar.
  //     expect(find.byType(CupertinoButton), findsNothing);

  //     await gesture.moveBy(const Offset(50, 0));
  //     await tester.pump();

  //     // The selection position is now moved with the drag.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 9, affinity: TextAffinity.downstream),
  //     );
  //     // Still no toolbar.
  //     expect(find.byType(CupertinoButton), findsNothing);

  //     await gesture.up();
  //     await tester.pumpAndSettle();

  //     // The selection isn't affected by the gesture lift.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 9, affinity: TextAffinity.downstream),
  //     );
  //     // The toolbar now shows up.
  //     expect(find.byType(CupertinoButton), findsNWidgets(2));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets('long press drag can edge scroll', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure Angrignon Peel Côte-des-Neiges',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //             maxLines: 1,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);

  //   List<TextSelectionPoint> lastCharEndpoint = renderEditable.getEndpointsForSelection(
  //     const TextSelection.collapsed(offset: 66), // Last character's position.
  //   );

  //   expect(lastCharEndpoint.length, 1);
  //   // Just testing the test and making sure that the last character is off
  //   // the right side of the screen.
  //   expect(lastCharEndpoint[0].point.dx, 1056);

  //   final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //   final TestGesture gesture =
  //       await tester.startGesture(textfieldStart + const Offset(300, 5));
  //   await tester.pump(const Duration(milliseconds: 500));

  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 19, affinity: TextAffinity.upstream),
  //   );
  //   expect(find.byType(CupertinoButton), findsNothing);

  //   await gesture.moveBy(const Offset(600, 0));
  //   // To the edge of the screen basically.
  //   await tester.pump();
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 56, affinity: TextAffinity.downstream),
  //   );
  //   // Keep moving out.
  //   await gesture.moveBy(const Offset(1, 0));
  //   await tester.pump();
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 62, affinity: TextAffinity.downstream),
  //   );
  //   await gesture.moveBy(const Offset(1, 0));
  //   await tester.pump();
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 66, affinity: TextAffinity.upstream),
  //   ); // We're at the edge now.
  //   expect(find.byType(CupertinoButton), findsNothing);

  //   await gesture.up();
  //   await tester.pumpAndSettle();

  //   // The selection isn't affected by the gesture lift.
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 66, affinity: TextAffinity.upstream),
  //   );
  //   // The toolbar now shows up.
  //   expect(find.byType(CupertinoButton), findsNWidgets(2));

  //   lastCharEndpoint = renderEditable.getEndpointsForSelection(
  //     const TextSelection.collapsed(offset: 66), // Last character's position.
  //   );

  //   expect(lastCharEndpoint.length, 1);
  //   // The last character is now on screen near the right edge.
  //   expect(lastCharEndpoint[0].point.dx, moreOrLessEquals(798, epsilon: 1));

  //   final List<TextSelectionPoint> firstCharEndpoint = renderEditable.getEndpointsForSelection(
  //     const TextSelection.collapsed(offset: 0), // First character's position.
  //   );
  //   expect(firstCharEndpoint.length, 1);
  //   // The first character is now offscreen to the left.
  //   expect(firstCharEndpoint[0].point.dx, moreOrLessEquals(-257, epsilon: 1));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'long tap after a double tap select is not affected',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor to the beginning of the second word.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 500));

  //     await tester.longPressAt(textfieldStart + const Offset(100.0, 9.0));
  //     await tester.pumpAndSettle();

  //     // Plain collapsed selection at the exact tap position.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 6),
  //     );

  //     // Long press toolbar.
  //     expect(find.byType(CupertinoButton), findsNWidgets(2));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'double tap after a long tap is not affected',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.longPressAt(textfieldStart + const Offset(50.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 3, affinity: TextAffinity.downstream),
  //     );

  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pumpAndSettle();

  //     // Double tap selection.
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );
  //     expect(find.byType(CupertinoButton), findsNWidgets(3));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }));

  // testMongolWidgets(
  //   'double click after a click on Mac',
  //   (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textFieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     final TestGesture gesture = await tester.startGesture(
  //       textFieldStart + const Offset(50.0, 9.0),
  //       pointer: 7,
  //       kind: PointerDeviceKind.mouse,
  //     );
  //     addTearDown(gesture.removePointer);
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 3, affinity: TextAffinity.downstream),
  //     );

  //     await gesture.down(textFieldStart + const Offset(150.0, 9.0));
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First click moved the cursor to the precise location, not the start of
  //     // the word.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 9, affinity: TextAffinity.downstream),
  //     );

  //     // Double click selection.
  //     await gesture.down(textFieldStart + const Offset(150.0, 9.0));
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );
  //     // The text selection toolbar isn't shown on Mac without a right click.
  //     expect(find.byType(CupertinoButton), findsNothing);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux }), skip: kIsWeb);

  // testMongolWidgets('double tap chains work', (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     await tester.tapAt(textfieldStart + const Offset(50.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(50.0, 9.0));
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 0, extentOffset: 7),
  //     );
  //     expect(find.byType(CupertinoButton), findsNWidgets(3));

  //     // Double tap selecting the same word somewhere else is fine.
  //     await tester.tapAt(textfieldStart + const Offset(100.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(100.0, 9.0));
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 0, extentOffset: 7),
  //     );
  //     expect(find.byType(CupertinoButton), findsNWidgets(3));

  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
  //     );
  //     await tester.tapAt(textfieldStart + const Offset(150.0, 9.0));
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );
  //     expect(find.byType(CupertinoButton), findsNWidgets(3));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }));

  // testMongolWidgets('double click chains work', (tester) async {
  //     final TextEditingController controller = TextEditingController(
  //       text: 'Atwater Peel Sherbrooke Bonaventure',
  //     );
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Material(
  //           child: Center(
  //             child: MongolTextField(
  //               controller: controller,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     final Offset textFieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //     // First click moves the cursor to the point of the click, not the edge of
  //     // the clicked word.
  //     final TestGesture gesture = await tester.startGesture(
  //       textFieldStart + const Offset(50.0, 9.0),
  //       pointer: 7,
  //       kind: PointerDeviceKind.mouse,
  //     );
  //     addTearDown(gesture.removePointer);
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pump(const Duration(milliseconds: 50));
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 3, affinity: TextAffinity.downstream),
  //     );

  //     // Second click selects.
  //     await gesture.down(textFieldStart + const Offset(50.0, 9.0));
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 0, extentOffset: 7),
  //     );
  //     expect(find.byType(CupertinoButton), findsNothing);

  //     // Double tap selecting the same word somewhere else is fine.
  //     await gesture.down(textFieldStart + const Offset(100.0, 9.0));
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 6, affinity: TextAffinity.downstream),
  //     );
  //     await gesture.down(textFieldStart + const Offset(100.0, 9.0));
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 0, extentOffset: 7),
  //     );
  //     expect(find.byType(CupertinoButton), findsNothing);

  //     await gesture.down(textFieldStart + const Offset(150.0, 9.0));
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pump(const Duration(milliseconds: 50));
  //     // First tap moved the cursor.
  //     expect(
  //       controller.selection,
  //       const TextSelection.collapsed(offset: 9, affinity: TextAffinity.downstream),
  //     );
  //     await gesture.down(textFieldStart + const Offset(150.0, 9.0));
  //     await tester.pump();
  //     await gesture.up();
  //     await tester.pumpAndSettle();
  //     expect(
  //       controller.selection,
  //       const TextSelection(baseOffset: 8, extentOffset: 12),
  //     );
  //     expect(find.byType(CupertinoButton), findsNothing);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux }), skip: kIsWeb);

  // testMongolWidgets('double tapping a space selects the previous word on iOS', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: ' blah blah  \n  blah',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, -1);
  //   expect(controller.value.selection.extentOffset, -1);

  //   // Put the cursor at the end of the field.
  //   await tester.tapAt(textOffsetToPosition(tester, 19));
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 19);
  //   expect(controller.value.selection.extentOffset, 19);

  //   // Double tapping does the same thing.
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await tester.tapAt(textOffsetToPosition(tester, 5));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await tester.tapAt(textOffsetToPosition(tester, 5));
  //   await tester.pumpAndSettle();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.extentOffset, 5);
  //   expect(controller.value.selection.baseOffset, 1);

  //   // Put the cursor at the end of the field.
  //   await tester.tapAt(textOffsetToPosition(tester, 19));
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 19);
  //   expect(controller.value.selection.extentOffset, 19);

  //   // Double tapping does the same thing for the first space.
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await tester.tapAt(textOffsetToPosition(tester, 0));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await tester.tapAt(textOffsetToPosition(tester, 0));
  //   await tester.pumpAndSettle();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 0);
  //   expect(controller.value.selection.extentOffset, 1);

  //   // Put the cursor at the end of the field.
  //   await tester.tapAt(textOffsetToPosition(tester, 19));
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 19);
  //   expect(controller.value.selection.extentOffset, 19);

  //   // Double tapping the last space selects all previous contiguous spaces on
  //   // both lines and the previous word.
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await tester.tapAt(textOffsetToPosition(tester, 14));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await tester.tapAt(textOffsetToPosition(tester, 14));
  //   await tester.pumpAndSettle();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 6);
  //   expect(controller.value.selection.extentOffset, 14);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

  // testMongolWidgets('selecting a space selects the space on non-iOS platforms', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: ' blah blah',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, -1);
  //   expect(controller.value.selection.extentOffset, -1);

  //   // Put the cursor at the end of the field.
  //   await tester.tapAt(textOffsetToPosition(tester, 10));
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 10);
  //   expect(controller.value.selection.extentOffset, 10);

  //   // Double tapping the second space selects it.
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await tester.tapAt(textOffsetToPosition(tester, 5));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await tester.tapAt(textOffsetToPosition(tester, 5));
  //   await tester.pumpAndSettle();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 5);
  //   expect(controller.value.selection.extentOffset, 6);

  //   // Put the cursor at the end of the field.
  //   await tester.tapAt(textOffsetToPosition(tester, 10));
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 10);
  //   expect(controller.value.selection.extentOffset, 10);

  //   // Double tapping the second space selects it.
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await tester.tapAt(textOffsetToPosition(tester, 0));
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await tester.tapAt(textOffsetToPosition(tester, 0));
  //   await tester.pumpAndSettle();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 0);
  //   expect(controller.value.selection.extentOffset, 1);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia, TargetPlatform.android }));

  // testMongolWidgets('selecting a space selects the space on Mac', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: ' blah blah',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: Center(
  //           child: MongolTextField(
  //             controller: controller,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, -1);
  //   expect(controller.value.selection.extentOffset, -1);

  //   // Put the cursor at the end of the field.
  //   final TestGesture gesture = await tester.startGesture(
  //     textOffsetToPosition(tester, 10),
  //     pointer: 7,
  //     kind: PointerDeviceKind.mouse,
  //   );
  //   addTearDown(gesture.removePointer);
  //   await tester.pump();
  //   await gesture.up();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 10);
  //   expect(controller.value.selection.extentOffset, 10);

  //   // Double clicking the second space selects it.
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await gesture.down(textOffsetToPosition(tester, 5));
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await gesture.down(textOffsetToPosition(tester, 5));
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 5);
  //   expect(controller.value.selection.extentOffset, 6);

  //   // Put the cursor at the end of the field.
  //   await gesture.down(textOffsetToPosition(tester, 10));
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 10);
  //   expect(controller.value.selection.extentOffset, 10);

  //   // Double tapping the second space selects it.
  //   await tester.pump(const Duration(milliseconds: 500));
  //   await gesture.down(textOffsetToPosition(tester, 0));
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pump(const Duration(milliseconds: 50));
  //   await gesture.down(textOffsetToPosition(tester, 0));
  //   await tester.pump();
  //   await gesture.up();
  //   await tester.pumpAndSettle();
  //   expect(controller.value.selection, isNotNull);
  //   expect(controller.value.selection.baseOffset, 0);
  //   expect(controller.value.selection.extentOffset, 1);
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux }), skip: kIsWeb);

  testMongolWidgets('force press does not select a word', (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolTextField(
            controller: controller,
          ),
        ),
      ),
    );

    final Offset offset = tester.getTopLeft(find.byType(MongolTextField)) +
        const Offset(150.0, 9.0);

    final int pointerValue = tester.nextPointer;
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      offset,
      PointerDownEvent(
        pointer: pointerValue,
        position: offset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await gesture.updateWithCustomEvent(
      PointerMoveEvent(
        pointer: pointerValue,
        position: offset + const Offset(150.0, 9.0),
        pressure: 0.5,
        pressureMin: 0,
        pressureMax: 1,
      ),
    );

    // We don't want this gesture to select any word on Android.
    expect(controller.selection, const TextSelection.collapsed(offset: -1));

    await gesture.up();
    await tester.pump();
    expect(find.byType(TextButton), findsNothing);
  },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.fuchsia,
        TargetPlatform.linux,
        TargetPlatform.windows
      }));

  // testMongolWidgets('force press selects word', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure',
  //   );
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart = tester.getTopLeft(find.byType(MongolTextField));

  //   final int pointerValue = tester.nextPointer;
  //   final Offset offset = textfieldStart + const Offset(9.0, 150.0);
  //   final TestGesture gesture = await tester.createGesture();
  //   await gesture.downWithCustomEvent(
  //     offset,
  //     PointerDownEvent(
  //       pointer: pointerValue,
  //       position: offset,
  //       pressure: 0.0,
  //       pressureMax: 6.0,
  //       pressureMin: 0.0,
  //     ),
  //   );

  //   await gesture.updateWithCustomEvent(
  //     PointerMoveEvent(
  //       pointer: pointerValue,
  //       position: textfieldStart + const Offset(9.0, 150.0),
  //       pressure: 0.5,
  //       pressureMin: 0,
  //       pressureMax: 1,
  //     ),
  //   );
  //   // We expect the force press to select a word at the given location.
  //   expect(
  //     controller.selection,
  //     const TextSelection(baseOffset: 8, extentOffset: 12),
  //   );

  //   await gesture.up();
  //   await tester.pumpAndSettle();
  //   expect(find.byType(CupertinoButton), findsNWidgets(3));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

  // testMongolWidgets('tap on non-force-press-supported devices work',
  //     (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'Atwater Peel Sherbrooke Bonaventure',
  //   );
  //   await tester.pumpWidget(Container(key: GlobalKey()));
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   final Offset textfieldStart =
  //       tester.getTopLeft(find.byType(MongolTextField));

  //   final int pointerValue = tester.nextPointer;
  //   final Offset offset = textfieldStart + const Offset(9.0, 150.0);
  //   final TestGesture gesture = await tester.createGesture();
  //   await gesture.downWithCustomEvent(
  //     offset,
  //     PointerDownEvent(
  //       pointer: pointerValue,
  //       position: offset,
  //       // iPhone 6 and below report 0 across the board.
  //       pressure: 0,
  //       pressureMax: 0,
  //       pressureMin: 0,
  //     ),
  //   );

  //   await gesture.updateWithCustomEvent(
  //     PointerMoveEvent(
  //       pointer: pointerValue,
  //       position: textfieldStart + const Offset(9.0, 150.0),
  //       pressure: 0.5,
  //       pressureMin: 0,
  //       pressureMax: 1,
  //     ),
  //   );
  //   await gesture.up();
  //   // The event should fallback to a normal tap and move the cursor.
  //   // Single taps selects the edge of the word.
  //   expect(
  //     controller.selection,
  //     const TextSelection.collapsed(offset: 8),
  //   );

  //   await tester.pump();
  //   // Single taps shouldn't trigger the toolbar.
  //   expect(find.byType(CupertinoButton), findsNothing);

  //   // TODO(gspencergoog): Add in TargetPlatform.macOS in the line below when we figure out what global state is leaking.
  //   // https://github.com/flutter/flutter/issues/43445
  // }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testMongolWidgets('default MongolTextField debugFillProperties',
      (tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const MongolTextField().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testMongolWidgets('MongolTextField implements debugFillProperties',
      (tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    // Not checking controller, inputFormatters, focusNode
    const MongolTextField(
      decoration: InputDecoration(labelText: 'foo'),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      style: TextStyle(color: Color(0xff00ff00)),
      textAlign: MongolTextAlign.bottom,
      autofocus: true,
      obscureText: false,
      autocorrect: false,
      maxLines: 10,
      maxLength: 100,
      enabled: false,
      cursorWidth: 1.0,
      cursorHeight: 1.0,
      cursorRadius: Radius.zero,
      cursorColor: Color(0xff00ff00),
      keyboardAppearance: Brightness.dark,
      scrollPadding: EdgeInsets.zero,
      scrollPhysics: ClampingScrollPhysics(),
      enableInteractiveSelection: false,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'enabled: false',
      'decoration: InputDecoration(labelText: "foo")',
      'style: TextStyle(inherit: true, color: Color(0xff00ff00))',
      'autofocus: true',
      'autocorrect: false',
      'maxLines: 10',
      'maxLength: 100',
      'textInputAction: done',
      'textAlign: bottom',
      'cursorWidth: 1.0',
      'cursorHeight: 1.0',
      'cursorRadius: Radius.circular(0.0)',
      'cursorColor: Color(0xff00ff00)',
      'keyboardAppearance: Brightness.dark',
      'scrollPadding: EdgeInsets.zero',
      'selection disabled',
      'scrollPhysics: ClampingScrollPhysics',
    ]);
  });

  // testMongolWidgets(
  //   'strut basic single line',
  //   (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // The MongolTextField will be as tall as the decoration (24) plus the metrics
  //       // from the default TextStyle of the theme (16), or 40 altogether.
  //       // Because this is less than the kMinInteractiveDimension, it will be
  //       // increased to that value (48).
  //       const Size(800, kMinInteractiveDimension),
  //     );
  //   },
  // );

  // testMongolWidgets(
  //   'strut TextStyle increases height',
  //   (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(
  //               style: TextStyle(fontSize: 20),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // Strut should inherit the TextStyle.fontSize by default and produce the
  //       // same height as if it were disabled.
  //       const Size(800, kMinInteractiveDimension), // Because 44 < 48.
  //     );

  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(
  //               style: TextStyle(fontSize: 20),
  //               strutStyle: StrutStyle.disabled,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // The height here should match the previous version with strut enabled.
  //       const Size(800, kMinInteractiveDimension), // Because 44 < 48.
  //     );
  //   },
  // );

  // testMongolWidgets(
  //   'strut basic multi line',
  //   (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(
  //               maxLines: 6,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // The height should be the input decoration (24) plus 6x the strut height (16).
  //       const Size(800, 120),
  //     );
  //   },
  // );

  // testMongolWidgets(
  //   'strut no force small strut',
  //   (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(
  //               maxLines: 6,
  //               strutStyle: StrutStyle(
  //                 // The small strut is overtaken by the larger
  //                 // TextStyle fontSize.
  //                 fontSize: 5,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // When the strut's height is smaller than TextStyle's and forceStrutHeight
  //       // is disabled, then the TextStyle takes precedence. Should be the same height
  //       // as 'strut basic multi line'.
  //       const Size(800, 120),
  //     );
  //   },
  // );

  // testMongolWidgets(
  //   'strut no force large strut',
  //   (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(
  //               maxLines: 6,
  //               strutStyle: StrutStyle(
  //                 fontSize: 25,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // When the strut's height is larger than TextStyle's and forceStrutHeight
  //       // is disabled, then the StrutStyle takes precedence.
  //       const Size(800, 174),
  //     );
  //   },
  // );

  // testMongolWidgets(
  //   'strut height override',
  //   (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(
  //               maxLines: 3,
  //               strutStyle: StrutStyle(
  //                 fontSize: 8,
  //                 forceStrutHeight: true,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // The smaller font size of strut make the field shorter than normal.
  //       const Size(800, 48),
  //     );
  //   },
  // );

  // testMongolWidgets(
  //   'strut forces field taller',
  //   (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: ThemeData(platform: TargetPlatform.android),
  //         home: const Material(
  //           child: Center(
  //             child: MongolTextField(
  //               maxLines: 3,
  //               style: TextStyle(fontSize: 10),
  //               strutStyle: StrutStyle(
  //                 fontSize: 18,
  //                 forceStrutHeight: true,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );

  //     expect(
  //       tester.getSize(find.byType(MongolTextField)),
  //       // When the strut fontSize is larger than a provided TextStyle, the
  //       // the strut's height takes precedence.
  //       const Size(800, 78),
  //     );
  //   },
  // );

  // testMongolWidgets('Caret center position', (tester) async {
  //   await tester.pumpWidget(
  //     overlay(
  //       child: Container(
  //         height: 300.0,
  //         child: const MongolTextField(
  //           textAlign: MongolTextAlign.center,
  //           decoration: null,
  //         ),
  //       ),
  //     ),
  //   );

  //   final MongolRenderEditable editable = findRenderEditable(tester);

  //   await tester.enterText(find.byType(MongolTextField), 'abcd');
  //   await tester.pump();

  //   Offset topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 4)).topLeft,
  //   );
  //   expect(topLeft.dy, equals(431));

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 3)).topLeft,
  //   );
  //   expect(topLeft.dy, equals(415));

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
  //   );
  //   expect(topLeft.dy, equals(399));

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 1)).topLeft,
  //   );
  //   expect(topLeft.dy, equals(383));
  // });

  // testMongolWidgets('Caret indexes into trailing whitespace center align', (tester) async {
  //   await tester.pumpWidget(
  //     overlay(
  //       child: Container(
  //         width: 300.0,
  //         child: const MongolTextField(
  //           textAlign: TextAlign.center,
  //           decoration: null,
  //         ),
  //       ),
  //     ),
  //   );

  //   final MongolRenderEditable editable = findRenderEditable(tester);

  //   await tester.enterText(find.byType(MongolTextField), 'abcd    ');
  //   await tester.pump();

  //   Offset topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 7)).topLeft,
  //   );
  //   expect(topLeft.dx, equals(479));

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 8)).topLeft,
  //   );
  //   expect(topLeft.dx, equals(495));

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 4)).topLeft,
  //   );
  //   expect(topLeft.dx, equals(431));

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 3)).topLeft,
  //   );
  //   expect(topLeft.dx, equals(415)); // Should be same as equivalent in 'Caret center position'

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
  //   );
  //   expect(topLeft.dx, equals(399)); // Should be same as equivalent in 'Caret center position'

  //   topLeft = editable.localToGlobal(
  //     editable.getLocalRectForCaret(const TextPosition(offset: 1)).topLeft,
  //   );
  //   expect(topLeft.dx, equals(383)); // Should be same as equivalent in 'Caret center position'
  // });

  // testMongolWidgets('selection handles are rendered and not faded away', (tester) async {
  //   const String testText = 'lorem ipsum';
  //   final TextEditingController controller = TextEditingController(text: testText);

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   final MongolEditableTextState state =
  //     tester.state<EditableTextState>(find.byType(MongolEditableText));
  //   final MongolRenderEditable renderEditable = state.renderEditable;

  //   await tester.tapAt(const Offset(20, 10));
  //   renderEditable.selectWord(cause: SelectionChangedCause.longPress);
  //   await tester.pumpAndSettle();

  //   final List<FadeTransition> transitions = find.descendant(
  //     of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_TextSelectionHandleOverlay'),
  //     matching: find.byType(FadeTransition),
  //   ).evaluate().map((Element e) => e.widget).cast<FadeTransition>().toList();
  //   expect(transitions.length, 2);
  //   final FadeTransition left = transitions[0];
  //   final FadeTransition right = transitions[1];
  //   expect(left.opacity.value, equals(1.0));
  //   expect(right.opacity.value, equals(1.0));
  // });

  // testMongolWidgets('iOS selection handles are rendered and not faded away', (tester) async {
  //   const String testText = 'lorem ipsum';
  //   final TextEditingController controller = TextEditingController(text: testText);

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(
  //           controller: controller,
  //         ),
  //       ),
  //     ),
  //   );

  //   final MongolRenderEditable renderEditable =
  //     tester.state<EditableTextState>(find.byType(MongolEditableText)).renderEditable;

  //   await tester.tapAt(const Offset(20, 10));
  //   renderEditable.selectWord(cause: SelectionChangedCause.longPress);
  //   await tester.pumpAndSettle();

  //   final List<FadeTransition> transitions =
  //     find.byType(FadeTransition).evaluate().map((Element e) => e.widget).cast<FadeTransition>().toList();
  //   expect(transitions.length, 2);
  //   final FadeTransition left = transitions[0];
  //   final FadeTransition right = transitions[1];

  //   expect(left.opacity.value, equals(1.0));
  //   expect(right.opacity.value, equals(1.0));
  // }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testMongolWidgets('Tap shows handles but not toolbar', (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolTextField(controller: controller),
        ),
      ),
    );

    // Tap to trigger the text field.
    await tester.tap(find.byType(MongolTextField));
    await tester.pump();

    final MongolEditableTextState editableText =
        tester.state(find.byType(MongolEditableText));
    expect(editableText.selectionOverlay!.handlesAreVisible, isTrue);
    expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
  });

  testMongolWidgets(
    'Tap in empty text field does not show handles nor toolbar',
    (tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MongolTextField(controller: controller),
          ),
        ),
      );

      // Tap to trigger the text field.
      await tester.tap(find.byType(MongolTextField));
      await tester.pump();

      final MongolEditableTextState editableText =
          tester.state(find.byType(MongolEditableText));
      expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
      expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
    },
  );

  testMongolWidgets('Long press shows handles and toolbar', (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolTextField(controller: controller),
        ),
      ),
    );

    // Long press to trigger the text field.
    await tester.longPress(find.byType(MongolTextField));
    await tester.pump();

    final MongolEditableTextState editableText =
        tester.state(find.byType(MongolEditableText));
    expect(editableText.selectionOverlay!.handlesAreVisible, isTrue);
    expect(editableText.selectionOverlay!.toolbarIsVisible, isTrue);
  });

  testMongolWidgets(
    'Long press in empty text field shows handles and toolbar',
    (tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MongolTextField(controller: controller),
          ),
        ),
      );

      // Tap to trigger the text field.
      await tester.longPress(find.byType(MongolTextField));
      await tester.pump();

      final MongolEditableTextState editableText =
          tester.state(find.byType(MongolEditableText));
      expect(editableText.selectionOverlay!.handlesAreVisible, isTrue);
      expect(editableText.selectionOverlay!.toolbarIsVisible, isTrue);
    },
  );

  testMongolWidgets('Double tap shows handles and toolbar', (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolTextField(controller: controller),
        ),
      ),
    );

    // Double tap to trigger the text field.
    await tester.tap(find.byType(MongolTextField));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(MongolTextField));
    await tester.pump();

    final MongolEditableTextState editableText =
        tester.state(find.byType(MongolEditableText));
    expect(editableText.selectionOverlay!.handlesAreVisible, isTrue);
    expect(editableText.selectionOverlay!.toolbarIsVisible, isTrue);
  });

  testMongolWidgets(
    'Double tap in empty text field shows toolbar but not handles',
    (tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MongolTextField(controller: controller),
          ),
        ),
      );

      // Double tap to trigger the text field.
      await tester.tap(find.byType(MongolTextField));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(MongolTextField));
      await tester.pump();

      final MongolEditableTextState editableText =
          tester.state(find.byType(MongolEditableText));
      expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
      expect(editableText.selectionOverlay!.toolbarIsVisible, isTrue);
    },
  );

  testMongolWidgets(
    'Mouse tap does not show handles nor toolbar',
    (tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'abc def ghi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MongolTextField(controller: controller),
          ),
        ),
      );

      // Long press to trigger the text field.
      final Offset textFieldPos =
          tester.getCenter(find.byType(MongolTextField));
      final TestGesture gesture = await tester.startGesture(
        textFieldPos,
        pointer: 7,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final MongolEditableTextState editableText =
          tester.state(find.byType(MongolEditableText));
      expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
      expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
    },
  );

  testMongolWidgets(
    'Mouse long press does not show handles nor toolbar',
    (tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'abc def ghi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MongolTextField(controller: controller),
          ),
        ),
      );

      // Long press to trigger the text field.
      final Offset textFieldPos =
          tester.getCenter(find.byType(MongolTextField));
      final TestGesture gesture = await tester.startGesture(
        textFieldPos,
        pointer: 7,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(seconds: 2));
      await gesture.up();
      await tester.pump();

      final MongolEditableTextState editableText =
          tester.state(find.byType(MongolEditableText));
      expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
      expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
    },
  );

  testMongolWidgets(
    'Mouse double tap does not show handles nor toolbar',
    (tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'abc def ghi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MongolTextField(controller: controller),
          ),
        ),
      );

      // Double tap to trigger the text field.
      final Offset textFieldPos =
          tester.getCenter(find.byType(MongolTextField));
      final TestGesture gesture = await tester.startGesture(
        textFieldPos,
        pointer: 7,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();
      await gesture.down(textFieldPos);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final MongolEditableTextState editableText =
          tester.state(find.byType(MongolEditableText));
      expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
      expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
    },
  );

  testMongolWidgets('Does not show handles when updated from the web engine',
      (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MongolTextField(controller: controller),
        ),
      ),
    );

    // Interact with the text field to establish the input connection.
    final Offset topLeft = tester.getTopLeft(find.byType(MongolEditableText));
    final TestGesture gesture = await tester.startGesture(
      topLeft + const Offset(5.0, 0.0),
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    final MongolEditableTextState state =
        tester.state(find.byType(MongolEditableText));
    expect(state.selectionOverlay!.handlesAreVisible, isFalse);
    expect(controller.selection, const TextSelection.collapsed(offset: 0));

    if (kIsWeb) {
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        selection: TextSelection(baseOffset: 2, extentOffset: 7),
      ));
      // Wait for all the `setState` calls to be flushed.
      await tester.pumpAndSettle();
      expect(
        state.currentTextEditingValue.selection,
        const TextSelection(baseOffset: 2, extentOffset: 7),
      );
      expect(state.selectionOverlay!.handlesAreVisible, isFalse);
    }
  });

  // testMongolWidgets('Tapping selection handles toggles the toolbar', (tester) async {
  //   final TextEditingController controller = TextEditingController(
  //     text: 'abc def ghi',
  //   );

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: MongolTextField(controller: controller),
  //       ),
  //     ),
  //   );

  //   // Tap to position the cursor and show the selection handles.
  //   final Offset ePos = textOffsetToPosition(tester, 5); // Index of 'e'.
  //   await tester.tapAt(ePos, pointer: 7);
  //   await tester.pumpAndSettle();

  //   final MongolEditableTextState editableText = tester.state(find.byType(MongolEditableText));
  //   expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
  //   expect(editableText.selectionOverlay!.handlesAreVisible, isTrue);

  //   final MongolRenderEditable renderEditable = findRenderEditable(tester);
  //   final List<TextSelectionPoint> endpoints = globalize(
  //     renderEditable.getEndpointsForSelection(controller.selection),
  //     renderEditable,
  //   );
  //   expect(endpoints.length, 1);

  //   // Tap the handle to show the toolbar.
  //   final Offset handlePos = endpoints[0].point + const Offset(0.0, 1.0);
  //   await tester.tapAt(handlePos, pointer: 7);
  //   expect(editableText.selectionOverlay!.toolbarIsVisible, isTrue);

  //   // Tap the handle again to hide the toolbar.
  //   await tester.tapAt(handlePos, pointer: 7);
  //   expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
  // });

  // testMongolWidgets('when MongolTextField would be blocked by keyboard, it is shown with enough space for the selection handle', (tester) async {
  //   final ScrollController scrollController = ScrollController();

  //   await tester.pumpWidget(MaterialApp(
  //     theme: ThemeData(),
  //     home: Scaffold(
  //       body: Center(
  //         child: ListView(
  //           scrollDirection: Axis.horizontal,
  //           controller: scrollController,
  //           children: <Widget>[
  //             Container(width: 579), // Push field almost off screen.
  //             const MongolTextField(),
  //             Container(width: 1000),
  //           ],
  //         ),
  //       ),
  //     ),
  //   ));

  //   // Tap the MongolTextField to put the cursor into it and bring it into view.
  //   expect(scrollController.offset, 0.0);
  //   await tester.tapAt(tester.getTopLeft(find.byType(MongolTextField)));
  //   await tester.pumpAndSettle();

  //   // The ListView has scrolled to keep the MongolTextField and cursor handle
  //   // visible.
  //   expect(scrollController.offset, 48.0);
  // });

  group('width', () {
    testMongolWidgets(
        'By default, MongolTextField is at least kMinInteractiveDimension wide',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(),
        home: const Scaffold(
          body: Center(
            child: MongolTextField(),
          ),
        ),
      ));

      final RenderBox renderBox =
          tester.renderObject(find.byType(MongolTextField));
      expect(
          renderBox.size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    });

    testMongolWidgets(
        "When text is very small, MongolTextField still doesn't go below kMinInteractiveDimension width",
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(),
        home: const Scaffold(
          body: Center(
            child: MongolTextField(
              style: TextStyle(fontSize: 2.0),
            ),
          ),
        ),
      ));

      final RenderBox renderBox =
          tester.renderObject(find.byType(MongolTextField));
      expect(renderBox.size.width, kMinInteractiveDimension);
    });

    testMongolWidgets(
        'When isDense, MongolTextField can go below kMinInteractiveDimension width',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(),
        home: const Scaffold(
          body: Center(
            child: MongolTextField(
              decoration: InputDecoration(
                isDense: true,
              ),
            ),
          ),
        ),
      ));

      final RenderBox renderBox =
          tester.renderObject(find.byType(MongolTextField));
      expect(renderBox.size.width, lessThan(kMinInteractiveDimension));
    });

    group('intrinsics', () {
      Widget _buildTest({required bool isDense}) {
        return MaterialApp(
            home: Scaffold(
                body: CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: <Widget>[
            SliverFillRemaining(
                hasScrollBody: false,
                child: Row(
                  children: <Widget>[
                    MongolTextField(
                        decoration: InputDecoration(
                      isDense: isDense,
                    )),
                    Container(
                      width: 1000,
                    ),
                  ],
                ))
          ],
        )));
      }

      testMongolWidgets(
          'By default, intrinsic width is at least kMinInteractiveDimension wide',
          (tester) async {
        // Regression test for https://github.com/flutter/flutter/issues/54729
        // If the intrinsic width does not match that of the width after
        // performLayout, this will fail.
        tester.pumpWidget(_buildTest(isDense: false));
      });

      testMongolWidgets(
          'When isDense, intrinsic width can go below kMinInteractiveDimension width',
          (tester) async {
        // Regression test for https://github.com/flutter/flutter/issues/54729
        // If the intrinsic width does not match that of the width after
        // performLayout, this will fail.
        tester.pumpWidget(_buildTest(isDense: true));
      });
    });
  });

  // testMongolWidgets("Arrow keys don't move input focus", (tester) async {
  //   final TextEditingController controller1 = TextEditingController();
  //   final TextEditingController controller2 = TextEditingController();
  //   final TextEditingController controller3 = TextEditingController();
  //   final TextEditingController controller4 = TextEditingController();
  //   final TextEditingController controller5 = TextEditingController();
  //   final FocusNode focusNode1 = FocusNode(debugLabel: 'Field 1');
  //   final FocusNode focusNode2 = FocusNode(debugLabel: 'Field 2');
  //   final FocusNode focusNode3 = FocusNode(debugLabel: 'Field 3');
  //   final FocusNode focusNode4 = FocusNode(debugLabel: 'Field 4');
  //   final FocusNode focusNode5 = FocusNode(debugLabel: 'Field 5');

  //   // Lay out text fields in a "+" formation, and focus the center one.
  //   await tester.pumpWidget(MaterialApp(
  //     theme: ThemeData(),
  //     home: Scaffold(
  //       body: Center(
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           mainAxisSize: MainAxisSize.min,
  //           children: <Widget>[
  //             Container(
  //               height: 100.0,
  //               child: MongolTextField(
  //                 controller: controller1,
  //                 focusNode: focusNode1,
  //               ),
  //             ),
  //             Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: <Widget>[
  //                   Container(
  //                     height: 100.0,
  //                     child: MongolTextField(
  //                       controller: controller2,
  //                       focusNode: focusNode2,
  //                     ),
  //                   ),
  //                   Container(
  //                     height: 100.0,
  //                     child: MongolTextField(
  //                       controller: controller3,
  //                       focusNode: focusNode3,
  //                     ),
  //                   ),
  //                   Container(
  //                     height: 100.0,
  //                     child: MongolTextField(
  //                       controller: controller4,
  //                       focusNode: focusNode4,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             Container(
  //               height: 100.0,
  //               child: MongolTextField(
  //                 controller: controller5,
  //                 focusNode: focusNode5,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   ),);

  //   focusNode3.requestFocus();
  //   await tester.pump();
  //   expect(focusNode3.hasPrimaryFocus, isTrue);

  //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //   await tester.pump();
  //   expect(focusNode3.hasPrimaryFocus, isTrue);

  //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //   await tester.pump();
  //   expect(focusNode3.hasPrimaryFocus, isTrue);

  //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  //   await tester.pump();
  //   expect(focusNode3.hasPrimaryFocus, isTrue);

  //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  //   await tester.pump();
  //   expect(focusNode3.hasPrimaryFocus, isTrue);
  // });

  testMongolWidgets('Scrolling shortcuts are disabled in text fields',
      (tester) async {
    bool scrollInvoked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Actions(
          actions: <Type, Action<Intent>>{
            ScrollIntent:
                CallbackAction<ScrollIntent>(onInvoke: (Intent intent) {
              scrollInvoked = true;
            }),
          },
          child: Material(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const <Widget>[
                Padding(padding: EdgeInsets.symmetric(vertical: 200)),
                MongolTextField(),
                Padding(padding: EdgeInsets.symmetric(vertical: 800)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(scrollInvoked, isFalse);

    // Set focus on the text field.
    await tester.tapAt(tester.getTopLeft(find.byType(MongolTextField)));

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(scrollInvoked, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(scrollInvoked, isFalse);
  });

  testMongolWidgets(
      "A buildCounter that returns null doesn't affect the size of the MongolTextField",
      (tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/44909

    final GlobalKey textField1Key = GlobalKey();
    final GlobalKey textField2Key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: <Widget>[
              MongolTextField(key: textField1Key),
              MongolTextField(
                key: textField2Key,
                maxLength: 1,
                buildCounter: (BuildContext context,
                        {required int currentLength,
                        required bool isFocused,
                        int? maxLength}) =>
                    null,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final Size textFieldSize1 = tester.getSize(find.byKey(textField1Key));
    final Size textFieldSize2 = tester.getSize(find.byKey(textField2Key));

    expect(textFieldSize1, equals(textFieldSize2));
  });

  testMongolWidgets(
    'The selection menu displays in an Overlay without error',
    (tester) async {
      // This is a regression test for
      // https://github.com/flutter/flutter/issues/43787
      final TextEditingController controller = TextEditingController(
        text:
            'This is a test that shows some odd behavior with Text Selection!',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Container(
            color: Colors.grey,
            child: Center(
              child: Container(
                color: Colors.red,
                width: 600,
                height: 300,
                child: Overlay(
                  initialEntries: <OverlayEntry>[
                    OverlayEntry(
                      builder: (BuildContext context) => Center(
                        child: MongolTextField(
                          controller: controller,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ));

      await _showSelectionMenuAt(
          tester, controller, controller.text.indexOf('test'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testMongolWidgets('Web does not check the clipboard status', (tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MongolTextField(
              controller: controller,
            ),
          ),
        ),
      ),
    );

    bool triedToReadClipboard = false;
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData') {
        triedToReadClipboard = true;
      }
      return null;
    });

    final Offset textfieldStart =
        tester.getTopLeft(find.byType(MongolTextField));

    // Double tap like when showing the text selection menu on Android/iOS.
    await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(textfieldStart + const Offset(9.0, 150.0));
    await tester.pump();

    if (kIsWeb) {
      // The clipboard is not checked because it requires user permissions and
      // web doesn't show a custom text selection menu.
      expect(triedToReadClipboard, false);
    } else {
      // The clipboard is checked in order to decide if the content can be
      // pasted.
      expect(triedToReadClipboard, true);
    }
  });

  testMongolWidgets('MongolTextField changes mouse cursor when hovered',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: MongolTextField(
              mouseCursor: SystemMouseCursors.grab,
              decoration: InputDecoration(
                // Add an icon so that the left edge is not the text area
                icon: Icon(Icons.person),
              ),
            ),
          ),
        ),
      ),
    );

    // Center, which is within the text area
    final Offset center = tester.getCenter(find.byType(MongolTextField));
    // Top left, which is not the text area
    final Offset edge =
        tester.getTopLeft(find.byType(MongolTextField)) + const Offset(1, 1);

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: center);
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.grab);

    // Test default cursor
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: MongolTextField(
              decoration: InputDecoration(
                icon: Icon(Icons.person),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text);
    await gesture.moveTo(edge);
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text);
    await gesture.moveTo(center);

    // Test default cursor when disabled
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: MongolTextField(
              enabled: false,
              decoration: InputDecoration(
                icon: Icon(Icons.person),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic);
    await gesture.moveTo(edge);
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic);
    await gesture.moveTo(center);
  });

  // testMongolWidgets('Caret rtl with changing width', (tester) async {
  //   late StateSetter setState;
  //   bool isWide = false;
  //   const double wideWidth = 300.0;
  //   const double narrowWidth = 200.0;
  //   final TextEditingController controller = TextEditingController();
  //   await tester.pumpWidget(
  //     boilerplate(
  //       child: StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setter) {
  //           setState = setter;
  //           return Container(
  //             width: isWide ? wideWidth : narrowWidth,
  //             child: MongolTextField(
  //               key: textFieldKey,
  //               controller: controller,
  //               textDirection: TextDirection.rtl,
  //             ),
  //           );
  //         }
  //       ),
  //     ),
  //   );

  //   // The cursor is on the right of the input because it's RTL.
  //   RenderEditable editable = findRenderEditable(tester);
  //   double cursorRight = editable.getLocalRectForCaret(
  //     TextPosition(offset: controller.value.text.length),
  //   ).topRight.dx;
  //   double inputWidth = editable.size.width;
  //   expect(inputWidth, narrowWidth);
  //   expect(cursorRight, inputWidth - kCaretGap);

  //   // After entering some text, the cursor remains on the right of the input.
  //   await tester.enterText(find.byType(MongolTextField), '12345');
  //   await tester.pump();
  //   editable = findRenderEditable(tester);
  //   cursorRight = editable.getLocalRectForCaret(
  //     TextPosition(offset: controller.value.text.length),
  //   ).topRight.dx;
  //   inputWidth = editable.size.width;
  //   expect(cursorRight, inputWidth - kCaretGap);

  //   // Since increasing the width of the input moves its right edge further to
  //   // the right, the cursor has followed this change and still appears on the
  //   // right of the input.
  //   setState(() {
  //     isWide = true;
  //   });
  //   await tester.pump();
  //   editable = findRenderEditable(tester);
  //   cursorRight = editable.getLocalRectForCaret(
  //     TextPosition(offset: controller.value.text.length),
  //   ).topRight.dx;
  //   inputWidth = editable.size.width;
  //   expect(inputWidth, wideWidth);
  //   expect(cursorRight, inputWidth - kCaretGap);
  // });

  // // Regressing test for https://github.com/flutter/flutter/issues/70625
  // testMongolWidgets('TextFields can inherit [FloatingLabelBehaviour] from InputDecorationTheme.', (tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   Widget textFieldBuilder({ FloatingLabelBehavior behavior = FloatingLabelBehavior.auto }) {
  //     return MaterialApp(
  //       theme: ThemeData(
  //         inputDecorationTheme: InputDecorationTheme(
  //           floatingLabelBehavior: behavior,
  //         ),
  //       ),
  //       home: Scaffold(
  //         body: MongolTextField(
  //           focusNode: focusNode,
  //           decoration: const InputDecoration(
  //             labelText: 'Label',
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   await tester.pumpWidget(textFieldBuilder(behavior: FloatingLabelBehavior.auto));
  //   // The label will be positioned within the content when unfocused.
  //   expect(tester.getTopLeft(findMongol.text('Label')).dx, 20.0);

  //   focusNode.requestFocus();
  //   await tester.pumpAndSettle(); // label animation.
  //   // The label will float to left of the content when focused.
  //   expect(tester.getTopLeft(findMongol.text('Label')).dx, 12.0);

  //   focusNode.unfocus();
  //   await tester.pumpAndSettle(); // label animation.

  //   await tester.pumpWidget(textFieldBuilder(behavior: FloatingLabelBehavior.never));
  //   await tester.pumpAndSettle(); // theme animation.
  //   // The label will be positioned within the content.
  //   expect(tester.getTopLeft(findMongol.text('Label')).dx, 20.0);

  //   focusNode.requestFocus();
  //   await tester.pumpAndSettle(); // label animation.
  //   // The label will always be positioned within the content.
  //   expect(tester.getTopLeft(findMongol.text('Label')).dy, 20.0);

  //   await tester.pumpWidget(textFieldBuilder(behavior: FloatingLabelBehavior.always));
  //   await tester.pumpAndSettle(); // theme animation.
  //   // The label will always float above the content.
  //   expect(tester.getTopLeft(findMongol.text('Label')).dy, 12.0);

  //   focusNode.unfocus();
  //   await tester.pumpAndSettle(); // label animation.
  //   // The label will always float above the content.
  //   expect(tester.getTopLeft(findMongol.text('Label')).dy, 12.0);
  // });

  // group('MaxLengthEnforcement', () {
  //   const int maxLength = 5;

  // Future<void> setupWidget(
  //   MongolWidgetTester tester,
  //   MaxLengthEnforcement? enforcement,
  // ) async {
  //   final Widget widget = MaterialApp(
  //     home: Material(
  //       child: MongolTextField(
  //         maxLength: maxLength,
  //         maxLengthEnforcement: enforcement,
  //       ),
  //     ),
  //   );

  //   await tester.pumpWidget(widget);
  //   await tester.pumpAndSettle();
  // }

  //   testMongolWidgets('using none enforcement.', (tester) async {
  //     const MaxLengthEnforcement enforcement = MaxLengthEnforcement.none;

  //     await setupWidget(tester, enforcement);

  //     final MongolEditableTextState state = tester.state(find.byType(MongolEditableText));

  //     state.updateEditingValue(const TextEditingValue(text: 'abc'));
  //     expect(state.currentTextEditingValue.text, 'abc');
  //     expect(state.currentTextEditingValue.composing, TextRange.empty);

  //     state.updateEditingValue(const TextEditingValue(text: 'abcdef', composing: TextRange(start: 3, end: 6)));
  //     expect(state.currentTextEditingValue.text, 'abcdef');
  //     expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 6));

  //     state.updateEditingValue(const TextEditingValue(text: 'abcdef'));
  //     expect(state.currentTextEditingValue.text, 'abcdef');
  //     expect(state.currentTextEditingValue.composing, TextRange.empty);
  //   });

  //   testMongolWidgets('using enforced.', (tester) async {
  //     const MaxLengthEnforcement enforcement = MaxLengthEnforcement.enforced;

  //     await setupWidget(tester, enforcement);

  //     final MongolEditableTextState state = tester.state(find.byType(MongolEditableText));

  //     state.updateEditingValue(const TextEditingValue(text: 'abc'));
  //     expect(state.currentTextEditingValue.text, 'abc');
  //     expect(state.currentTextEditingValue.composing, TextRange.empty);

  //     state.updateEditingValue(const TextEditingValue(text: 'abcde', composing: TextRange(start: 3, end: 5)));
  //     expect(state.currentTextEditingValue.text, 'abcde');
  //     expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

  //     state.updateEditingValue(const TextEditingValue(text: 'abcdef', composing: TextRange(start: 3, end: 6)));
  //     expect(state.currentTextEditingValue.text, 'abcde');
  //     expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

  //     state.updateEditingValue(const TextEditingValue(text: 'abcdef'));
  //     expect(state.currentTextEditingValue.text, 'abcde');
  //     expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));
  //   });

  //   testMongolWidgets('using truncateAfterCompositionEnds.', (tester) async {
  //     const MaxLengthEnforcement enforcement = MaxLengthEnforcement.truncateAfterCompositionEnds;

  //     await setupWidget(tester, enforcement);

  //     final MongolEditableTextState state = tester.state(find.byType(MongolEditableText));

  //     state.updateEditingValue(const TextEditingValue(text: 'abc'));
  //     expect(state.currentTextEditingValue.text, 'abc');
  //     expect(state.currentTextEditingValue.composing, TextRange.empty);

  //     state.updateEditingValue(const TextEditingValue(text: 'abcde', composing: TextRange(start: 3, end: 5)));
  //     expect(state.currentTextEditingValue.text, 'abcde');
  //     expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

  //     state.updateEditingValue(const TextEditingValue(text: 'abcdef', composing: TextRange(start: 3, end: 6)));
  //     expect(state.currentTextEditingValue.text, 'abcdef');
  //     expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 6));

  //     state.updateEditingValue(const TextEditingValue(text: 'abcdef'));
  //     expect(state.currentTextEditingValue.text, 'abcde');
  //     expect(state.currentTextEditingValue.composing, TextRange.empty);
  //   });

  //   testMongolWidgets('using default behavior for different platforms.', (tester) async {
  //     await setupWidget(tester, null);

  //     final MongolEditableTextState state = tester.state(find.byType(MongolEditableText));

  //     state.updateEditingValue(const TextEditingValue(text: '侬好啊'));
  //     expect(state.currentTextEditingValue.text, '侬好啊');
  //     expect(state.currentTextEditingValue.composing, TextRange.empty);

  //     state.updateEditingValue(const TextEditingValue(text: '侬好啊旁友', composing: TextRange(start: 3, end: 5)));
  //     expect(state.currentTextEditingValue.text, '侬好啊旁友');
  //     expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

  //     state.updateEditingValue(const TextEditingValue(text: '侬好啊旁友们', composing: TextRange(start: 3, end: 6)));
  //     if (kIsWeb ||
  //       defaultTargetPlatform == TargetPlatform.iOS ||
  //       defaultTargetPlatform == TargetPlatform.macOS ||
  //       defaultTargetPlatform == TargetPlatform.linux ||
  //       defaultTargetPlatform == TargetPlatform.fuchsia
  //     ) {
  //       expect(state.currentTextEditingValue.text, '侬好啊旁友们');
  //       expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 6));
  //     } else {
  //       expect(state.currentTextEditingValue.text, '侬好啊旁友');
  //       expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));
  //     }

  //     state.updateEditingValue(const TextEditingValue(text: '侬好啊旁友'));
  //     expect(state.currentTextEditingValue.text, '侬好啊旁友');
  //     expect(state.currentTextEditingValue.composing, TextRange.empty);
  //   });
  // });
}
