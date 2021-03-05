import 'package:flutter/material.dart';
import 'package:mongol/mongol_input_decorator.dart';
import 'package:mongol/mongol_text_field.dart';

class MongolTextFieldDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SearchBody(),
    );
  }
}

class SearchBody extends StatefulWidget {
  @override
  _SearchBodyState createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: MongolTextField(
            controller: controller,
            maxLines: null,
            decoration: InputDecoration(
              //hintText: 'hint text', // TODO: fix input allignment
              border: OutlineInputBorder(),
            ),
            //scrollPadding: EdgeInsets.zero,
          ),
        ),
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
