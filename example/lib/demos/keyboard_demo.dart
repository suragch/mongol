import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mongol/mongol_font.dart';
import 'package:mongol/mongol_text.dart';

class KeyboardDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BodyWidget(),
    );
  }
}

class BodyWidget extends StatefulWidget {
  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  TextEditingController _textEditingController;
  @override
  void initState() {
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(50.0),
          child: TextField(
            controller: _textEditingController,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                hintText: 'Enter Unicode text'),
            style: TextStyle(
              fontFamily: MongolFont.qagan,
              fontSize: 24,
            ),
            showCursor: true,
            readOnly: true,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: MongolKeyboard(
            onTextInput: (myText) {
              String text = _textEditingController.text;
              TextSelection textSelection = _textEditingController.selection;
              String newText = text.replaceRange(
                  textSelection.start, textSelection.end, myText);
              final myTextLength = myText.length;
              _textEditingController.text = newText;
              _textEditingController.selection = textSelection.copyWith(
                baseOffset: textSelection.start + myTextLength,
                extentOffset: textSelection.start + myTextLength,
              );
            },
          ),
        ),
      ],
    );
  }
}

class MongolKeyboard extends StatelessWidget {
  MongolKeyboard({Key key, this.onTextInput}) : super(key: key);

  final ValueSetter<String> onTextInput;

  void textInputHandler(String text) {
    if (onTextInput == null) return;
    onTextInput(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: Colors.blue,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                MongolKeyboardKey(
                  text: 'ᠴ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠣ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠡ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠷ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠲ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠶ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠦ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠢ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠥ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠫ',
                  onTextInput: textInputHandler,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                MongolKeyboardKey(
                  text: 'ᠠ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠰ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠳ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠹ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠭ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠬ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠵ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠬ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠯ',
                  onTextInput: textInputHandler,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                MongolKeyboardKey(
                  text: 'ᠽ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠱ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠼ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠤ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠪ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠨ',
                  onTextInput: textInputHandler,
                ),
                MongolKeyboardKey(
                  text: 'ᠮ',
                  onTextInput: textInputHandler,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                MongolKeyboardKey(
                  text: ' ',
                  onTextInput: textInputHandler,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MongolKeyboardKey extends StatelessWidget {
  final String text;

  const MongolKeyboardKey({Key key, this.text, this.onTextInput})
      : super(key: key);

  final ValueSetter<String> onTextInput;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          color: Colors.blue.shade300,
          child: InkWell(
            onTap: () {
              onTextInput(text);
            },
            child: Container(
              child: Center(child: MongolText(text)),
            ),
          ),
        ),
      ),
    );
  }
}
