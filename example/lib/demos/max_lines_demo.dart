import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class MaxLinesDemo extends StatelessWidget {
  const MaxLinesDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('MongolText with maxLines and overflow')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.blue[100],
            child: const MongolText(
              'ellipsis $text',
              style: TextStyle(
                fontSize: 30,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            color: Colors.blue[200],
            child: const MongolText(
              'fade $text',
              style: TextStyle(
                fontSize: 30,
              ),
              maxLines: 1,
              overflow: TextOverflow.fade,
            ),
          ),
          Container(
            color: Colors.blue[300],
            child: const MongolText(
              'clip $text',
              style: TextStyle(
                fontSize: 30,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
          Container(
            color: Colors.blue[400],
            child: const MongolText(
              'visible $text',
              style: TextStyle(
                fontSize: 30,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
          Container(
            color: Colors.blue[500],
            child: const MongolText(
              'null $text',
              style: TextStyle(
                fontSize: 30,
              ),
              maxLines: 1,
              overflow: null,
            ),
          ),
          Container(
            color: Colors.yellow[100],
            child: const MongolText(
              text,
              style: TextStyle(
                fontSize: 30,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            color: Colors.green[100],
            child: const MongolText(
              text,
              style: TextStyle(
                fontSize: 30,
              ),
              maxLines: null,
              overflow: null,
            ),
          ),
        ],
      ),
    );
  }
}

const text =
    'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';
