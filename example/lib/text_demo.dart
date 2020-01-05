import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class TextDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.blue[100],
          child: MongolText(
            'ᠮᠣᠩᠭᠣᠯ\nᠪᠢᠴᠢᠭ',
            style: TextStyle(fontSize: 100),
          ),
        ),
      ),
    );
  }
}
