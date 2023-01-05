import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class InputShortcutsDemo extends StatefulWidget {
  const InputShortcutsDemo({super.key});

  @override
  State<StatefulWidget> createState() => _InputShortcutsDemoState();
}

class _InputShortcutsDemoState extends State<InputShortcutsDemo> {
  final mongolInputController = TextEditingController(text: '''
// arrowUp arrowDown
// arrowLeft arrowRight
// macos ios meta
// windows android fushia control
// alt
// + shift''');
  final systemInputController = TextEditingController(text: '''
// arrowUp arrowDown
// arrowLeft arrowRight
// macos ios meta
// windows android fushia control
// alt
// + shift''');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Shortcuts')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MongolTextField(
                controller: mongolInputController,
                maxLines: null,
                textAlignHorizontal: TextAlignHorizontal.left,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: systemInputController,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
