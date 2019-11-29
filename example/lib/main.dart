import 'package:flutter/material.dart';
import 'package:mongol/mongol_text.dart';

void main() => runApp(DemoApp());

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('mongol package demo')),
        body: Stack(
          children: <Widget>[
            Center(
              child: Container(
                color: Colors.blue[100],
                child: MongolText(
                  'ᠮᠣᠩᠭᠣᠯ\nᠪᠢᠴᠢᠭ',
                  style: TextStyle(fontSize: 100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
