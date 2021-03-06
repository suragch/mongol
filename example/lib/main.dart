import 'package:flutter/material.dart';
import 'package:mongol_demo_app/demos/horizontal_listview_demo.dart';

import 'demos/alert_dialog_demo.dart';
import 'demos/emoji_cjk_demo.dart';
import 'demos/max_lines_demo.dart';
import 'demos/mongol_text_field_demo.dart';
import 'demos/text_demo.dart';
import 'demos/keyboard_demo.dart';
import 'demos/text_span_demo.dart';

void main() {
  runApp(DemoApp());
}

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'mongol',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'MenksoftQagan'),
      home: Scaffold(
        appBar: AppBar(title: Text('Mongol package demo')),
        body: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        DemoTile(
          title: 'MongolText',
          destination: TextDemo(),
        ),
        DemoTile(
          title: 'MongolText.rich',
          destination: RichTextDemo(),
        ),
        DemoTile(
          title: 'MongolTextField',
          destination: MongolTextFieldDemo(),
        ),
        DemoTile(
          title: 'Emoji and CJK',
          destination: EmojiCjkDemo(),
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
          title: 'Maxlines demo',
          destination: MaxLinesDemo(),
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
