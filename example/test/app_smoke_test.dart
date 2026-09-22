import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';
import 'package:mongol_demo_app/demos/alert_dialog_demo.dart';
import 'package:mongol_demo_app/demos/button_demo.dart';
import 'package:mongol_demo_app/demos/editable_text_demo.dart';
import 'package:mongol_demo_app/demos/emoji_cjk_demo.dart';
import 'package:mongol_demo_app/demos/horizontal_listview_demo.dart';
import 'package:mongol_demo_app/demos/input_decorations_demo.dart';
import 'package:mongol_demo_app/demos/input_shortcuts_demo.dart';
import 'package:mongol_demo_app/demos/keyboard_demo.dart';
import 'package:mongol_demo_app/demos/list_tile_demo.dart';
import 'package:mongol_demo_app/demos/max_lines_demo.dart';
import 'package:mongol_demo_app/demos/mongol_text_field_demo.dart';
import 'package:mongol_demo_app/demos/popup_menu_demo.dart';
import 'package:mongol_demo_app/demos/resizable_text_demo.dart';
import 'package:mongol_demo_app/demos/text_demo.dart';
import 'package:mongol_demo_app/demos/text_painter_demo.dart';
import 'package:mongol_demo_app/demos/text_span_demo.dart';
import 'package:mongol_demo_app/main.dart';

void main() {
  group('Demo App Smoke Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize =
          const Size(1200, 900);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('boots and displays HomeScreen with title and list',
        (WidgetTester tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      expect(find.text(versionTitle), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to every demo screen and back to HomeScreen',
        (WidgetTester tester) async {
      final demos = <(String, Type)>[
        ('MongolText', TextDemo),
        ('MongolText.rich', RichTextDemo),
        ('Emoji and CJK', EmojiCjkDemo),
        ('MongolTextField', MongolTextFieldDemo),
        ('Input decoration', InputDecorationsDemo),
        ('Input Shortcuts', InputShortcutsDemo),
        ('MongolEditableText', MongolEditableTextDemo),
        ('MongolAlertDialog', AlertDialogDemo),
        ('Keyboard', KeyboardDemo),
        ('Horizontal Listview', HorizontalListviewDemo),
        ('Max lines', MaxLinesDemo),
        ('Resizable text', ResizableTextDemo),
        ('Popup Menu', PopupMenuDemo),
        ('MongolListTile', ListTileDemo),
        ('Buttons', ButtonDemo),
        ('MongolTextPainter', TextPainterDemo),
      ];

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(Scrollable).first;

      for (final (title, demoType) in demos) {
        final tileFinder = find.widgetWithText(DemoTile, title);

        // Ensure the tile is visible in the scrollable list.
        await tester.scrollUntilVisible(
          tileFinder,
          100.0,
          scrollable: scrollableFinder,
        );
        expect(tileFinder, findsOneWidget);

        // Navigate to the demo.
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        // Verify the demo screen is mounted.
        expect(find.byType(demoType), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        // Navigate back to HomeScreen.
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Verify we are back on HomeScreen.
        expect(find.byType(HomeScreen), findsOneWidget);
      }
    });

    testWidgets('MongolAlertDialog demo opens and closes dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      final tileFinder = find.widgetWithText(DemoTile, 'MongolAlertDialog');
      await tester.scrollUntilVisible(
        tileFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialogDemo), findsOneWidget);

      // Open the MongolAlertDialog.
      final showDialogButton =
          find.widgetWithText(ElevatedButton, 'Show Dialog');
      expect(showDialogButton, findsOneWidget);
      await tester.tap(showDialogButton);
      await tester.pumpAndSettle();

      // Verify the dialog is visible.
      expect(find.byType(MongolAlertDialog), findsOneWidget);

      // Tap the action button to dismiss.
      final dismissButton = find.byType(MongolTextButton);
      expect(dismissButton, findsOneWidget);
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();

      // Verify the dialog is dismissed.
      expect(find.byType(MongolAlertDialog), findsNothing);

      // Navigate back.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Horizontal Listview demo scrolls horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      final tileFinder = find.widgetWithText(DemoTile, 'Horizontal Listview');
      await tester.scrollUntilVisible(
        tileFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(find.byType(HorizontalListviewDemo), findsOneWidget);

      // Find the horizontal listview and perform a horizontal drag.
      final horizontalListView = find.byType(ListView);
      expect(horizontalListView, findsOneWidget);
      await tester.drag(horizontalListView, const Offset(-200.0, 0.0));
      await tester.pumpAndSettle();

      // Navigate back.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Buttons demo displays vertical Mongol buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      final tileFinder = find.widgetWithText(DemoTile, 'Buttons');
      await tester.scrollUntilVisible(
        tileFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ButtonDemo), findsOneWidget);
      expect(find.byType(MongolElevatedButton), findsWidgets);
      expect(find.byType(MongolOutlinedButton), findsWidgets);
      expect(find.byType(MongolTextButton), findsWidgets);

      // Navigate back.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
