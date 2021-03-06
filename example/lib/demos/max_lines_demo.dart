import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class MaxLinesDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.blue[100],
            child: MongolText(
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
            child: MongolText(
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
            child: MongolText(
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
            child: MongolText(
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
            child: MongolText(
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
            child: MongolText(
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
            child: MongolText(
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
