import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class KeyboardDemo extends StatelessWidget {
  const KeyboardDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard')),
      body: const BodyWidget(),
    );
  }
}

class BodyWidget extends StatefulWidget {
  const BodyWidget({super.key});
  @override
  State<BodyWidget> createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: MongolTextField(
              controller: _textEditingController,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                // hintText: 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ',
              ),
              style: const TextStyle(
                fontSize: 24,
              ),
              showCursor: true,
              readOnly: true,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: TextFieldTapRegion(
            child: MongolKeyboard(
              onTextInput: _insertText,
              onBackspace: _backspace,
            ),
          ),
        ),
      ],
    );
  }

  void _insertText(String myText) {
    final text = _textEditingController.text;
    final textSelection = _textEditingController.selection;
    final newText =
        text.replaceRange(textSelection.start, textSelection.end, myText);
    final myTextLength = myText.length;
    _textEditingController.text = newText;
    _textEditingController.selection = textSelection.copyWith(
      baseOffset: textSelection.start + myTextLength,
      extentOffset: textSelection.start + myTextLength,
    );
  }

  void _backspace() {
    final text = _textEditingController.text;
    final textSelection = _textEditingController.selection;
    final selectionLength = textSelection.end - textSelection.start;

    // There is a selection.
    if (selectionLength > 0) {
      final newText =
          text.replaceRange(textSelection.start, textSelection.end, '');
      _textEditingController.text = newText;
      _textEditingController.selection = textSelection.copyWith(
        baseOffset: textSelection.start,
        extentOffset: textSelection.start,
      );
      return;
    }

    // The cursor is at the beginning.
    if (textSelection.start == 0) {
      return;
    }

    // Delete the previous character
    final newStart = textSelection.start - 1;
    final newEnd = textSelection.start;
    final newText = text.replaceRange(newStart, newEnd, '');
    _textEditingController.text = newText;
    _textEditingController.selection = textSelection.copyWith(
      baseOffset: newStart,
      extentOffset: newStart,
    );
  }
}

class MongolKeyboard extends StatelessWidget {
  const MongolKeyboard({
    super.key,
    this.onTextInput,
    this.onBackspace,
  });

  final ValueSetter<String>? onTextInput;
  final VoidCallback? onBackspace;

  void textInputHandler(String text) {
    onTextInput?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: Colors.blue,
      child: Column(
        children: [
          buildRowOne(),
          buildRowTwo(),
          buildRowThree(),
          buildRowFour(),
          buildRowFive(),
        ],
      ),
    );
  }

  Expanded buildRowOne() {
    return Expanded(
      child: Row(
        children: [
          MongolKeyboardKey(
            text: 'ᠠ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠡ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠢ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠣ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠤ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠥ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠦ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠧ',
            onTextInput: textInputHandler,
          ),
        ],
      ),
    );
  }

  Expanded buildRowTwo() {
    return Expanded(
      child: Row(
        children: [
          MongolKeyboardKey(
            text: 'ᠨ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠩ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠪ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠫ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠬ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠭ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠮ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠯ',
            onTextInput: textInputHandler,
          ),
        ],
      ),
    );
  }

  Expanded buildRowThree() {
    return Expanded(
      child: Row(
        children: [
          MongolKeyboardKey(
            text: 'ᠰ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠱ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠲ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠳ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠴ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠵ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠶ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠷ',
            onTextInput: textInputHandler,
          ),
        ],
      ),
    );
  }

  Expanded buildRowFour() {
    return Expanded(
      child: Row(
        children: [
          MongolKeyboardKey(
            text: 'ᠸ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠹ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠻ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠼ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠽ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠾ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᠿ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᡀ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᡁ',
            onTextInput: textInputHandler,
          ),
          MongolKeyboardKey(
            text: 'ᡂ',
            onTextInput: textInputHandler,
          ),
        ],
      ),
    );
  }

  Expanded buildRowFive() {
    return Expanded(
      child: Row(
        children: [
          MongolKeyboardKey(
            text: ' ',
            flex: 4,
            onTextInput: textInputHandler,
          ),
          BackspaceKey(
            onBackspace: () {
              onBackspace?.call();
            },
          ),
        ],
      ),
    );
  }
}

class MongolKeyboardKey extends StatelessWidget {
  const MongolKeyboardKey({
    super.key,
    required this.text,
    this.onTextInput,
    this.flex = 1,
  });

  final String text;
  final ValueSetter<String>? onTextInput;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          color: Colors.blue.shade300,
          child: InkWell(
            onTap: () {
              onTextInput?.call(text);
            },
            child: Center(child: MongolText(text)),
          ),
        ),
      ),
    );
  }
}

class BackspaceKey extends StatelessWidget {
  const BackspaceKey({
    super.key,
    this.onBackspace,
    this.flex = 1,
  });

  final VoidCallback? onBackspace;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          color: Colors.blue.shade300,
          child: InkWell(
            onTap: () {
              onBackspace?.call();
            },
            child: const Center(
              child: Icon(Icons.backspace),
            ),
          ),
        ),
      ),
    );
  }
}
