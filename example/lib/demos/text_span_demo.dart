import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class RichTextDemo extends StatelessWidget {
  const RichTextDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongolText.rich')),
      body: const Center(
        child: ExampleWidget(),
      ),
    );
  }
}

class ExampleWidget extends StatelessWidget {
  const ExampleWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: const MongolText.rich(
        text,
        textScaleFactor: 2.5,
      ),
    );
  }
}

const text = TextSpan(
  style: TextStyle(fontSize: 30, color: Colors.black),
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
    TextSpan(
        text: 'ᠠᠷᠪᠠ',
        style:
            TextStyle(fontFamily: 'MenksoftAmuguleng', color: Colors.purple)),
  ],
);
//const text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';
