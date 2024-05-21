import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class TextDemo extends StatefulWidget {
  const TextDemo({super.key});
  @override
  State<TextDemo> createState() => _TextDemoState();
}

class _TextDemoState extends State<TextDemo> {
  var _alignment = MongolTextAlign.top;
  var _selected = MongolTextAlign.top;

  void _updateAlignment(MongolTextAlign alignment) {
    setState(() {
      _alignment = alignment;
      _selected = alignment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongolText')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Button(
                  title: 'Top',
                  isSelected: _selected == MongolTextAlign.top,
                  onPressed: () => _updateAlignment(MongolTextAlign.top),
                ),
                Button(
                  title: 'Center',
                  isSelected: _selected == MongolTextAlign.center,
                  onPressed: () => _updateAlignment(MongolTextAlign.center),
                ),
                Button(
                  title: 'Bottom',
                  isSelected: _selected == MongolTextAlign.bottom,
                  onPressed: () => _updateAlignment(MongolTextAlign.bottom),
                ),
                Button(
                  title: 'Justify',
                  isSelected: _selected == MongolTextAlign.justify,
                  onPressed: () => _updateAlignment(MongolTextAlign.justify),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Container(
                color: Colors.blue[100],
                child: MongolText(
                  text,
                  style: const TextStyle(fontSize: 30),
                  textAlign: _alignment,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.title,
    required this.onPressed,
    required this.isSelected,
  });

  final String title;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: MaterialButton(
        minWidth: 70,
        elevation: 0,
        color: (isSelected)
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        onPressed: onPressed,
        child: Text(title),
      ),
    );
  }
}

const text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';
