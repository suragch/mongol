import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class HorizontalListviewDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SearchBody(),
    );
  }
}

class SearchBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Container(
              //width: 30,
              child: MongolTextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sampleText.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MongolText(sampleText[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final sampleText = [
  'ᠨᠢᠭᠡ',
  'ᠬᠣᠶᠠᠷ',
  'ᠭᠤᠷᠪᠠ',
  'ᠳᠦᠷᠪᠡ',
  'ᠲᠠᠪᠤ',
  'ᠵᠢᠷᠭᠤᠭ᠎ᠠ',
  'ᠳᠣᠯᠣᠭ᠎ᠠ',
  'ᠨᠠᠢᠮ',
  'ᠶᠢᠰᠦ',
  'ᠠᠷᠪᠠ',
  'ᠨᠢᠭᠡ',
  'ᠬᠣᠶᠠᠷ',
  'ᠭᠤᠷᠪᠠ',
  'ᠳᠦᠷᠪᠡ',
  'ᠲᠠᠪᠤ',
  'ᠵᠢᠷᠭᠤᠭ᠎ᠠ',
  'ᠳᠣᠯᠣᠭ᠎ᠠ',
  'ᠨᠠᠢᠮ',
  'ᠶᠢᠰᠦ',
  'ᠠᠷᠪᠠ',
  'ᠨᠢᠭᠡ',
  'ᠬᠣᠶᠠᠷ',
  'ᠭᠤᠷᠪᠠ',
  'ᠳᠦᠷᠪᠡ',
  'ᠲᠠᠪᠤ',
  'ᠵᠢᠷᠭᠤᠭ᠎ᠠ',
  'ᠳᠣᠯᠣᠭ᠎ᠠ',
  'ᠨᠠᠢᠮ',
  'ᠶᠢᠰᠦ',
  'ᠠᠷᠪᠠ',
];
