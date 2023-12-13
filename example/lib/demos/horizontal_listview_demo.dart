import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class HorizontalListviewDemo extends StatelessWidget {
  const HorizontalListviewDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ListView with Axis.horizontal')),
      body: const SearchBody(),
    );
  }
}

class SearchBody extends StatelessWidget {
  const SearchBody({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
