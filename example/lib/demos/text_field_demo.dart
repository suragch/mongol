import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class TextFieldDemo extends StatelessWidget {
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
              child: RotatedBox(
                quarterTurns: 1,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Search',
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: europeanCountries.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MongolText(europeanCountries[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final europeanCountries = [
  'ᠨᠢᠭᠡ',
  'ᠬᠣᠶᠠᠷ',
  'ᠭᠤᠷᠪᠠ',
  'ᠳᠦᠷᠪᠡ',
  'ᠲᠠᠪᠤ',
  'ᠵᠢᠷᠭᠤᠭ᠎ᠠ',
  'ᠨᠠᠢᠮ',
  'ᠶᠢᠰᠦ',
  'ᠠᠷᠪᠠ',
  'ᠨᠢᠭᠡ',
  'ᠬᠣᠶᠠᠷ',
  'ᠭᠤᠷᠪᠠ',
  'ᠳᠦᠷᠪᠡ',
  'ᠲᠠᠪᠤ',
  'ᠵᠢᠷᠭᠤᠭ᠎ᠠ',
  'ᠨᠠᠢᠮ',
  'ᠶᠢᠰᠦ',
  'ᠠᠷᠪᠠ',
  'ᠨᠢᠭᠡ',
  'ᠬᠣᠶᠠᠷ',
  'ᠭᠤᠷᠪᠠ',
  'ᠳᠦᠷᠪᠡ',
  'ᠲᠠᠪᠤ',
  'ᠵᠢᠷᠭᠤᠭ᠎ᠠ',
  'ᠨᠠᠢᠮ',
  'ᠶᠢᠰᠦ',
  'ᠠᠷᠪᠠ',
];
