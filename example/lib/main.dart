import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

import 'demos/alert_dialog_demo.dart';
import 'demos/button_demo.dart';
import 'demos/emoji_cjk_demo.dart';
import 'demos/horizontal_listview_demo.dart';
import 'demos/input_decorations_demo.dart';
import 'demos/input_shortcuts_demo.dart';
import 'demos/keyboard_demo.dart';
import 'demos/list_tile_demo.dart';
import 'demos/max_lines_demo.dart';
import 'demos/mongol_text_field_demo.dart';
import 'demos/popup_menu_demo.dart';
import 'demos/resizable_text_demo.dart';
import 'demos/text_demo.dart';
import 'demos/text_span_demo.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MongolTextEditingShortcuts(child: child);
      },
      title: 'mongol',
      theme: ThemeData(
        fontFamily: 'MenksoftQagan',
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter mongol package 3.2.0')),
        body: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const <Widget>[
        DemoTile(
          title: 'MongolText',
          destination: TextDemo(),
        ),
        DemoTile(
          title: 'MongolText.rich',
          destination: RichTextDemo(),
        ),
        DemoTile(
          title: 'Emoji and CJK',
          destination: EmojiCjkDemo(),
        ),
        DemoTile(
          title: 'MongolTextField',
          destination: MongolTextFieldDemo(),
        ),
        DemoTile(
          title: 'Input decoration',
          destination: InputDecorationsDemo(),
        ),
        DemoTile(
          title: 'Input Shortcuts',
          destination: InputShortcutsDemo(),
        ),
        DemoTile(
          title: 'MongolAlertDialog',
          destination: AlertDialogDemo(),
        ),
        DemoTile(
          title: 'Keyboard',
          destination: KeyboardDemo(),
        ),
        DemoTile(
          title: 'Horizontal Listview',
          destination: HorizontalListviewDemo(),
        ),
        DemoTile(
          title: 'Max lines',
          destination: MaxLinesDemo(),
        ),
        DemoTile(
          title: 'Resizable text',
          destination: ResizableTextDemo(),
        ),
        DemoTile(
          title: 'Popup Menu',
          destination: PopupMenuDemo(),
        ),
        DemoTile(
          title: 'MongolListTile',
          destination: ListTileDemo(),
        ),
        DemoTile(
          title: 'Buttons',
          destination: ButtonDemo(),
        ),
      ],
    );
  }
}

class DemoTile extends StatelessWidget {
  const DemoTile({
    Key? key,
    required this.title,
    required this.destination,
  }) : super(key: key);

  final String title;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }
}
