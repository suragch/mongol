import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';
import 'package:mongol/mongol_font.dart';

class TextSpanDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Example1(),
      ),
    );
  }
}

class Example1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: MongolRichText(text: text),
    );
  }
}

const text = TextSpan(
  //style: TextStyle(fontSize: 30, color: Colors.black),
  children: [
    TextSpan(text: 'ᠨᠢᠭᠡ\n', style: TextStyle(fontSize: 40)),
    TextSpan(text: 'ᠬᠣᠶᠠᠷ', style: TextStyle(backgroundColor: Colors.yellow)),
    TextSpan(
      text: ' ᠭᠤᠷᠪᠠ ',
      style: TextStyle(shadows: [
        Shadow(
          blurRadius: 3.0,
          color: Colors.lightGreen,
          offset: Offset(3.0, -3.0),
        ),
      ]),
    ),
    TextSpan(text: 'ᠳᠦᠷ'),
    TextSpan(text: 'ᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤ', style: TextStyle(color: Colors.blue)),
    TextSpan(text: 'ᠭ᠎ᠠ ᠨᠠᠢᠮᠠ '),
    TextSpan(text: 'ᠶᠢᠰᠦ ', style: TextStyle(fontSize: 20)),
    TextSpan(text: 'ᠠᠷᠪᠠ'),
  ],
);
//const text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';
