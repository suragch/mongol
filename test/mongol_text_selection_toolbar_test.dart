// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mongol/mongol.dart';

/// Answers the platform clipboard channel so paste can be enabled in tests.
class _MockClipboard {
  String? text;

  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return <String, dynamic>{'text': text};
      case 'Clipboard.hasStrings':
        return <String, bool>{'value': text != null && text!.isNotEmpty};
      case 'Clipboard.setData':
        text =
            (methodCall.arguments as Map<Object?, Object?>)['text'] as String?;
    }
    return null;
  }
}

/// Pumps a bare [MongolEditableText] and returns its state.
Future<MongolEditableTextState> pumpEditableText(
  WidgetTester tester, {
  required TextEditingController controller,
  TextSelectionControls? selectionControls,
  // ignore: deprecated_member_use
  ToolbarOptions? toolbarOptions,
  MongolEditableTextContextMenuBuilder? contextMenuBuilder,
  int? maxLines = 1,
}) async {
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 300,
            child: MongolEditableText(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 20),
              cursorColor: Colors.black,
              selectionControls: selectionControls,
              // ignore: deprecated_member_use_from_same_package
              toolbarOptions: toolbarOptions,
              contextMenuBuilder: contextMenuBuilder,
              maxLines: maxLines,
            ),
          ),
        ),
      ),
    ),
  );
  return tester.state<MongolEditableTextState>(find.byType(MongolEditableText));
}

void main() {
  group('buttonItemsForToolbarOptions', () {
    testWidgets('maps the cut option to a cut button', (tester) async {
      final controller = TextEditingController(text: 'abc')
        ..selection = const TextSelection(baseOffset: 0, extentOffset: 2);
      addTearDown(controller.dispose);

      final state = await pumpEditableText(
        tester,
        controller: controller,
        selectionControls: mongolTextSelectionHandleControls,
        // ignore: deprecated_member_use
        toolbarOptions: const ToolbarOptions(
          cut: true,
          copy: true,
          selectAll: true,
        ),
      );

      expect(state.contextMenuButtonItems.map((item) => item.type).toList(), [
        ContextMenuButtonType.cut,
        ContextMenuButtonType.copy,
        ContextMenuButtonType.selectAll,
      ]);
    });
  });

  group('contextMenuAnchors', () {
    testWidgets('sit to the left and right of a vertical selection', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'abc def')
        ..selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      addTearDown(controller.dispose);

      final state = await pumpEditableText(
        tester,
        controller: controller,
        selectionControls: mongolTextSelectionHandleControls,
      );
      final render = state.renderEditable;
      final region = Rect.fromPoints(
        render.localToGlobal(Offset.zero),
        render.localToGlobal(render.size.bottomRight(Offset.zero)),
      );
      final points = render.getEndpointsForSelection(controller.selection);
      final midY =
          region.top + (points.first.point.dy + points.last.point.dy) / 2;

      final anchors = state.contextMenuAnchors;

      expect(anchors.primaryAnchor.dy, midY);
      expect(anchors.secondaryAnchor, isNotNull);
      expect(anchors.secondaryAnchor!.dy, midY);
      // The toolbar prefers the space to the left of the selected line.
      expect(
        anchors.primaryAnchor.dx,
        lessThan(region.left + points.first.point.dx),
      );
      // Falling back to the right, clear of the selection handle.
      expect(
        anchors.secondaryAnchor!.dx,
        region.left + points.last.point.dx + 20.0,
      );
    });
  });

  group('contextMenuAnchors (multi-line)', () {
    testWidgets('center on the field when the selection spans lines', (
      tester,
    ) async {
      // Long enough to wrap inside a 300px tall field at 20px per glyph.
      final controller = TextEditingController(
        text: 'abcdefghij klmnopqrst uvwxyz abcdefghij klmnopqrst',
      );
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      addTearDown(controller.dispose);

      final state = await pumpEditableText(
        tester,
        controller: controller,
        selectionControls: mongolTextSelectionHandleControls,
        maxLines: null,
      );
      final render = state.renderEditable;
      final region = Rect.fromPoints(
        render.localToGlobal(Offset.zero),
        render.localToGlobal(render.size.bottomRight(Offset.zero)),
      );
      final points = render.getEndpointsForSelection(controller.selection);
      expect(
        points.last.point.dx - points.first.point.dx,
        greaterThan(render.preferredLineWidth * 1.5),
        reason: 'the selection should span more than one line',
      );

      final anchors = state.contextMenuAnchors;

      expect(anchors.primaryAnchor.dy, region.top + region.height / 2);
      expect(anchors.secondaryAnchor!.dy, region.top + region.height / 2);
    });
  });

  group('MongolAdaptiveTextSelectionToolbar', () {
    const anchors = TextSelectionToolbarAnchors(
      primaryAnchor: Offset(200, 100),
      secondaryAnchor: Offset(240, 100),
    );

    testWidgets('shows an icon button per item and runs its callback', (
      tester,
    ) async {
      final pressed = <ContextMenuButtonType>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MongolAdaptiveTextSelectionToolbar.buttonItems(
              anchors: anchors,
              buttonItems: [
                for (final type in [
                  ContextMenuButtonType.cut,
                  ContextMenuButtonType.copy,
                  ContextMenuButtonType.paste,
                  ContextMenuButtonType.selectAll,
                ])
                  ContextMenuButtonItem(
                    type: type,
                    onPressed: () => pressed.add(type),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cut), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.paste), findsOneWidget);
      expect(find.byIcon(Icons.select_all), findsOneWidget);

      await tester.tap(find.byIcon(Icons.paste));
      expect(pressed, [ContextMenuButtonType.paste]);
    });

    testWidgets('builds nothing when there are no items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MongolAdaptiveTextSelectionToolbar.buttonItems(
              anchors: anchors,
              buttonItems: const [],
            ),
          ),
        ),
      );

      expect(find.byType(MongolTextSelectionToolbar), findsNothing);
      expect(find.byType(MongolTextSelectionToolbarButton), findsNothing);
    });

    testWidgets('shows a custom item by its label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MongolAdaptiveTextSelectionToolbar.buttonItems(
              anchors: anchors,
              buttonItems: [
                ContextMenuButtonItem(
                  type: ContextMenuButtonType.custom,
                  label: 'Hello',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is MongolText && widget.data == 'Hello',
        ),
        findsOneWidget,
      );
    });
  });

  group('MongolTextField context menu', () {
    final clipboard = _MockClipboard();

    setUp(() {
      clipboard.text = null;
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            clipboard.handleMethodCall,
          );
    });

    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<TextEditingController> pumpField(
      WidgetTester tester, {
      String text = 'abc def',
      TextSelectionControls? selectionControls,
      // ignore: deprecated_member_use
      ToolbarOptions? toolbarOptions,
      MongolEditableTextContextMenuBuilder? contextMenuBuilder,
    }) async {
      final controller = TextEditingController(text: text);
      addTearDown(controller.dispose);
      // Passing null explicitly means "no menu", so only forward a builder
      // when the test supplies one and otherwise keep the field's default.
      final field = contextMenuBuilder == null
          ? MongolTextField(
              controller: controller,
              selectionControls: selectionControls,
              // ignore: deprecated_member_use_from_same_package
              toolbarOptions: toolbarOptions,
            )
          : MongolTextField(
              controller: controller,
              selectionControls: selectionControls,
              // ignore: deprecated_member_use_from_same_package
              toolbarOptions: toolbarOptions,
              contextMenuBuilder: contextMenuBuilder,
            );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(height: 300, child: field),
            ),
          ),
        ),
      );
      return controller;
    }

    Future<void> longPressFirstGlyph(WidgetTester tester) async {
      final topLeft = tester.getTopLeft(find.byType(MongolEditableText));
      await tester.longPressAt(topLeft + const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('long press shows the adaptive icon toolbar', (tester) async {
      clipboard.text = 'xyz';
      await pumpField(tester);

      await longPressFirstGlyph(tester);

      expect(find.byType(MongolAdaptiveTextSelectionToolbar), findsOneWidget);
      expect(find.byIcon(Icons.cut), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.paste), findsOneWidget);
      expect(find.byIcon(Icons.select_all), findsOneWidget);
    });

    testWidgets('the toolbar buttons edit the field', (tester) async {
      clipboard.text = null;
      final controller = await pumpField(tester);

      await longPressFirstGlyph(tester);
      expect(controller.selection.textInside(controller.text), 'abc');

      await tester.tap(find.byIcon(Icons.select_all));
      await tester.pump();
      expect(controller.selection.textInside(controller.text), 'abc def');

      await tester.tap(find.byIcon(Icons.cut));
      await tester.pump();
      expect(controller.text, '');
      expect(clipboard.text, 'abc def');
    });

    testWidgets('a custom contextMenuBuilder replaces the toolbar', (
      tester,
    ) async {
      await pumpField(
        tester,
        contextMenuBuilder: (context, editableTextState) =>
            const Text('custom menu'),
      );

      await longPressFirstGlyph(tester);

      expect(find.text('custom menu'), findsOneWidget);
      expect(find.byType(MongolAdaptiveTextSelectionToolbar), findsNothing);
    });

    testWidgets('legacy toolbarOptions still limit the buttons', (
      tester,
    ) async {
      clipboard.text = 'xyz';
      await pumpField(
        tester,
        // ignore: deprecated_member_use
        toolbarOptions: const ToolbarOptions(copy: true),
      );

      await longPressFirstGlyph(tester);

      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.cut), findsNothing);
      expect(find.byIcon(Icons.paste), findsNothing);
      expect(find.byIcon(Icons.select_all), findsNothing);
    });

    testWidgets('refreshes the clipboard state before showing the toolbar', (
      tester,
    ) async {
      clipboard.text = null;
      await pumpField(tester);
      // The clipboard gains content after the field has been built.
      clipboard.text = 'xyz';

      await longPressFirstGlyph(tester);

      expect(find.byIcon(Icons.paste), findsOneWidget);
    });

    testWidgets('legacy selectionControls still build their own toolbar', (
      tester,
    ) async {
      await pumpField(tester, selectionControls: mongolTextSelectionControls);

      await longPressFirstGlyph(tester);

      expect(find.byType(MongolTextSelectionToolbar), findsOneWidget);
      expect(find.byType(MongolAdaptiveTextSelectionToolbar), findsNothing);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });
  });

  group('MongolEditableText without selectionControls', () {
    testWidgets('still shows the context menu from contextMenuBuilder', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'abc def')
        ..selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      addTearDown(controller.dispose);

      final state = await pumpEditableText(
        tester,
        controller: controller,
        contextMenuBuilder: (context, editableTextState) =>
            const Text('custom menu'),
      );
      // Route the selection through the state so the overlay exists.
      state.userUpdateTextEditingValue(
        controller.value,
        SelectionChangedCause.tap,
      );
      await tester.pump();

      expect(state.showToolbar(), isTrue);
      await tester.pump();

      expect(find.text('custom menu'), findsOneWidget);
    });
  });

  group('MongolTextSelectionHandleControls', () {
    test('leaves the toolbar to contextMenuBuilder', () {
      expect(
        mongolTextSelectionHandleControls,
        isA<TextSelectionHandleControls>(),
      );
      expect(
        mongolTextSelectionHandleControls,
        isA<MongolTextSelectionControls>(),
      );
    });

    test('draws the same handle as the legacy controls', () {
      expect(
        mongolTextSelectionHandleControls.getHandleSize(20.0),
        mongolTextSelectionControls.getHandleSize(20.0),
      );
      expect(
        mongolTextSelectionHandleControls.getHandleAnchor(
          TextSelectionHandleType.left,
          20.0,
        ),
        mongolTextSelectionControls.getHandleAnchor(
          TextSelectionHandleType.left,
          20.0,
        ),
      );
    });
  });
}
