import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class InputDecorationsDemo extends StatelessWidget {
  const InputDecorationsDemo({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input decorations')),
      body: const InputDecorationsBody(),
    );
  }
}

class InputDecorationsBody extends StatefulWidget {
  const InputDecorationsBody({Key? key}) : super(key: key);
  @override
  _InputDecorationsBodyState createState() => _InputDecorationsBodyState();
}

class _InputDecorationsBodyState extends State<InputDecorationsBody> {
  TextEditingController controller = TextEditingController();

  /// Border
  static BorderType _borderValue = BorderType.outline;
  bool _showSize = false;
  bool _showHint = false;
  bool _showError = false;
  bool _showCounterText = false;
  bool _showCounterWidget = false;
  bool _showIcon = false;
  bool _showPrefixIcon = false;
  bool _showSuffixIcon = false;

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
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton(
              hint: Text(_borderValue.name),
              items: BorderType.values
                  .map((v) => DropdownMenuItem<BorderType>(
                      value: v, child: Text(v.name)))
                  .toList(),
              onChanged: (BorderType? value) {
                setState(
                  () {
                    _borderValue = value!;
                  },
                );
              },
            ),
            CheckboxItem(
              title: 'Show size',
              value: _showSize,
              onChanged: (newValue) {
                setState(() {
                  _showSize = newValue!;
                });
              },
            ),
            CheckboxItem(
              title: 'Hint',
              value: _showHint,
              onChanged: (newValue) {
                setState(() {
                  _showHint = newValue!;
                });
              },
            ),
            CheckboxItem(
              title: 'Error',
              value: _showError,
              onChanged: (newValue) {
                setState(() {
                  _showError = newValue!;
                });
              },
            ),
            CheckboxItem(
              title: 'Counter text',
              value: _showCounterText,
              onChanged: (newValue) {
                setState(() {
                  _showCounterText = newValue!;
                });
              },
            ),
            CheckboxItem(
              title: 'Counter widget',
              value: _showCounterWidget,
              onChanged: (newValue) {
                setState(() {
                  _showCounterWidget = newValue!;
                });
              },
            ),
            CheckboxItem(
              title: 'Icon',
              value: _showIcon,
              onChanged: (newValue) {
                setState(() {
                  _showIcon = newValue!;
                });
              },
            ),
            CheckboxItem(
              title: 'Prefix icon',
              value: _showPrefixIcon,
              onChanged: (newValue) {
                setState(() {
                  _showPrefixIcon = newValue!;
                });
              },
            ),
            CheckboxItem(
              title: 'Suffix icon',
              value: _showSuffixIcon,
              onChanged: (newValue) {
                setState(() {
                  _showSuffixIcon = newValue!;
                });
              },
            ),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: (_showSize)
                      ? BoxDecoration(
                          border: Border.all(width: 1, color: Colors.red),
                        )
                      : null,
                  child: TextField(
                    decoration: InputDecoration(
                      border: (_borderValue == BorderType.sideline)
                          ? const UnderlineInputBorder()
                          : _borderValue.border,
                      hintText: (_showHint) ? 'ᠨᠢᠭᠡ ᠬᠤᠶᠠᠷ ᠭᠤᠷᠪᠠ' : null,
                      errorText: (_showError) ? 'ᠨᠢᠭᠡ ᠬᠤᠶᠠᠷ ᠭᠤᠷᠪᠠ' : null,
                      counterText:
                          (_showCounterText) ? 'ᠨᠢᠭᠡ ᠬᠤᠶᠠᠷ ᠭᠤᠷᠪᠠ' : null,
                      counter: (_showCounterWidget)
                          ? Container(
                              width: 20,
                              height: 20,
                              color: Colors.green,
                            )
                          : null,
                      icon: (_showIcon) ? const Icon(Icons.star) : null,
                      prefix: (_showPrefixIcon) ? const Icon(Icons.star) : null,
                      suffix: (_showSuffixIcon) ? const Icon(Icons.star) : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Container(
                    decoration: (_showSize)
                        ? BoxDecoration(
                            border: Border.all(width: 1, color: Colors.red),
                          )
                        : null,
                    child: MongolTextField(
                      decoration: InputDecoration(
                        border: _borderValue.border,
                        hintText: (_showHint) ? 'ᠨᠢᠭᠡ ᠬᠤᠶᠠᠷ ᠭᠤᠷᠪᠠ' : null,
                        errorText: (_showError) ? 'ᠨᠢᠭᠡ ᠬᠤᠶᠠᠷ ᠭᠤᠷᠪᠠ' : null,
                        counterText:
                            (_showCounterText) ? 'ᠨᠢᠭᠡ ᠬᠤᠶᠠᠷ ᠭᠤᠷᠪᠠ' : null,
                        counter: (_showCounterWidget)
                            ? Container(
                                width: 20,
                                height: 20,
                                color: Colors.green,
                              )
                            : null,
                        icon: (_showIcon) ? const Icon(Icons.star) : null,
                        prefix:
                            (_showPrefixIcon) ? const Icon(Icons.star) : null,
                        suffix:
                            (_showSuffixIcon) ? const Icon(Icons.star) : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum BorderType {
  none('InputBorder.none', InputBorder.none),
  sideline('SidelineInputBorder', SidelineInputBorder()),
  outline('OutlineInputBorder', OutlineInputBorder());

  const BorderType(this.name, this.border);

  final String name;
  final InputBorder border;
}

class CheckboxItem extends StatelessWidget {
  const CheckboxItem({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final Function(bool?)? onChanged;
  final bool? value;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Text(title),
      ],
    );
  }
}
