import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class EmojiCjkDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          color: Colors.blue[100],
          child: MongolText.rich(
            text,
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }
}

//const text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';

const text = TextSpan(
  children: [
    TextSpan(text: 'ᠰᠠᠶᠢᠨ ᠪᠠᠶᠢᠨ᠎ᠠ ᠤᠤ︖ '),
    TextSpan(text: '你好 '),
    //TextSpan(text: '👋 ', style: TextStyle(rotated: true)),
    TextSpan(text: '👨‍👩‍👧 '),
    TextSpan(text: '🇭🇺 '),
    TextSpan(text: '2 '),
    TextSpan(text: '22 '),
    TextSpan(text: '222 '),
    TextSpan(text: 'hello'),
  ],
);