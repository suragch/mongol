import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class EmojiCjkDemo extends StatefulWidget {
  const EmojiCjkDemo({super.key});

  @override
  State<EmojiCjkDemo> createState() => _EmojiCjkDemoState();
}

class _EmojiCjkDemoState extends State<EmojiCjkDemo> {
  bool _rotateCJK = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MongolText with emoji and CJK'),
        actions: [
          IconButton(
            icon: Icon(_rotateCJK ? Icons.crop_rotate : Icons.crop_portrait),
            tooltip: 'Toggle CJK Rotation',
            onPressed: () {
              setState(() {
                _rotateCJK = !_rotateCJK;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          color: Colors.blue[100],
          child: MongolText.rich(
            text,
            style: const TextStyle(fontSize: 30),
            rotateCJK: _rotateCJK,
          ),
        ),
      ),
    );
  }
}

const text = TextSpan(
  children: [
    TextSpan(
        text:
            'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠣᠷᠪᠠ ᠳᠥᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ \uD83D\uDE42 ᠬᠣᠷᠢᠨ ᠨᠢᠭᠡ ᠬᠣᠷᠢᠨ ᠬᠣᠶᠠᠷ ᠬᠣᠷᠢᠨ ᠭᠣᠷᠪᠠ '),
    TextSpan(text: 'one two three four five six seven eight nine ten '),
    TextSpan(text: '👨‍👩‍👧'),
    TextSpan(text: '👋🏿'),
    TextSpan(text: '🇭🇺'),
    TextSpan(text: '一二三四五六七八九十'),
    TextSpan(
        text:
            '\uD83D\uDE03\uD83D\uDE0A\uD83D\uDE1C\uD83D\uDE01\uD83D\uDE2C\uD83D\uDE2E\uD83D\uDC34\uD83D\uDC02\uD83D\uDC2B\uD83D\uDC11\uD83D\uDC10'),
    TextSpan(text: '①②③㉑㊿〖汉字〗한국어モンゴル語English? ︽ᠮᠣᠩᠭᠣᠯ︖︾'),
    TextSpan(text: '123１２３'),
  ],
);
