import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';
import 'package:mongol/mongol_font.dart';

class TextSpanDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          color: Colors.blue[100],
          child: MongolRichText(
            text: text,
          ),
        ),
      ),
    );
  }
}

const text = TextSpan(
  style: TextStyle(fontFamily: MongolFont.qagan),
  children: [
    // TextSpan(text: 'a'),
    TextSpan(text: 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ '),
    TextSpan(text: 'ᠳᠦᠷᠪᠡ '),
    TextSpan(text: 'ᠲᠠ'),
    TextSpan(text: 'ᠪᠤ', style: TextStyle(color: Colors.blue)),
    TextSpan(text: 'ᠳᠤᠭᠠᠷ'),
  ],
);
//const text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';
