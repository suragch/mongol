import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongol/mongol.dart';

import 'keyboard_demo.dart';

class TextInputControlKeyboardDemo extends StatelessWidget {
  const TextInputControlKeyboardDemo({super.key});

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
  State<BodyWidget> createState() => MyStatefulWidgetState();
}

class MyStatefulWidgetState extends State<BodyWidget> {
  // final TextEditingController _controller = TextEditingController();
  // final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    // _controller.dispose();
    // _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: MongolTextField(
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
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: MyVirtualKeyboard(),
          ),
        ],
      ),
      // bottomSheet: MyVirtualKeyboard(),
    );
  }
}

class MyVirtualKeyboard extends StatefulWidget {
  const MyVirtualKeyboard({super.key});

  @override
  MyVirtualKeyboardState createState() => MyVirtualKeyboardState();
}

class MyVirtualKeyboardState extends State<MyVirtualKeyboard> {
  final MyTextInputControl _inputControl = MyTextInputControl();

  @override
  void initState() {
    super.initState();
    _inputControl.register();
  }

  @override
  void dispose() {
    super.dispose();
    _inputControl.unregister();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _inputControl.visible,
      builder: (_, bool visible, __) {
        return Visibility(
          visible: visible,
          child: FocusScope(
            canRequestFocus: false,
            child: TextFieldTapRegion(
              child: MongolKeyboard(
                onTextInput: _inputControl.insertText,
                onBackspace: _inputControl.backspace,
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyTextInputControl with TextInputControl {
  TextEditingValue _editingState = TextEditingValue.empty;
  final ValueNotifier<bool> _visible = ValueNotifier<bool>(false);

  /// The input control's visibility state for updating the visual presentation.
  ValueListenable<bool> get visible => _visible;

  /// Register the input control.
  void register() => TextInput.setInputControl(this);

  /// Restore the original platform input control.
  void unregister() => TextInput.restorePlatformInputControl();

  @override
  void show() => _visible.value = true;

  @override
  void hide() => _visible.value = false;

  @override
  void setEditingState(TextEditingValue value) => _editingState = value;

  void insertText(String myText) {
    final text = _editingState.text;
    final textSelection = _editingState.selection;
    final newText =
        text.replaceRange(textSelection.start, textSelection.end, myText);
    final myTextLength = myText.length;
    _editingState = _editingState.copyWith(
      text: newText,
      selection: textSelection.copyWith(
        baseOffset: textSelection.start + myTextLength,
        extentOffset: textSelection.start + myTextLength,
      ),
    );
    // Request the attached client to update accordingly.
    TextInput.updateEditingValue(_editingState);
  }

  void backspace() {
    final text = _editingState.text;
    final textSelection = _editingState.selection;
    final selectionLength = textSelection.end - textSelection.start;

    // There is a selection.
    if (selectionLength > 0) {
      final newText =
          text.replaceRange(textSelection.start, textSelection.end, '');
      _editingState = _editingState.copyWith(
          text: newText,
          selection: textSelection.copyWith(
            baseOffset: textSelection.start,
            extentOffset: textSelection.start,
          ));
      // Request the attached client to update accordingly.
      TextInput.updateEditingValue(_editingState);
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
    _editingState = _editingState.copyWith(
        text: newText,
        selection: textSelection.copyWith(
          baseOffset: newStart,
          extentOffset: newStart,
        ));
    // Request the attached client to update accordingly.
    TextInput.updateEditingValue(_editingState);
  }
}
