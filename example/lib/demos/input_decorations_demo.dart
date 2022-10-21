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
  bool _showOutlineBorder = true;
  bool _showSidelineBorder = false;
  bool _showSize = false;
  bool _showLabel = false;
  bool _showLabelText = false;
  bool _showHint = false;
  bool _showError = false;
  bool _showCounterText = false;
  bool _showCounterWidget = false;
  bool _showIcon = false;
  bool _showPrefixIcon = false;
  bool _showPrefixText = false;
  bool _showPrefix = false;
  bool _showSuffix = false;
  bool _showSuffixIcon = false;
  bool _showSuffixText = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  final box = Container(
    width: 10,
    height: 10,
    color: Colors.green,
  );
  static const text = 'ᠨᠢᠭᠡ ᠬᠤᠶᠠᠷ ᠭᠤᠷᠪᠠ';
  final icon = const Icon(Icons.star);
  final redBorder = BoxDecoration(
    border: Border.all(width: 1, color: Colors.red),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxItem(
              title: 'Outline border',
              value: _showOutlineBorder,
              onChanged: (newValue) {
                _showOutlineBorder = newValue!;
                if (_showOutlineBorder) {
                  _showSidelineBorder = false;
                  _borderValue = BorderType.outline;
                } else {
                  _borderValue = BorderType.none;
                }
                setState(() {});
              },
            ),
            CheckboxItem(
              title: 'Sideline border',
              value: _showSidelineBorder,
              onChanged: (newValue) {
                _showSidelineBorder = newValue!;
                if (_showSidelineBorder) {
                  _showOutlineBorder = false;
                  _borderValue = BorderType.sideline;
                } else {
                  _borderValue = BorderType.none;
                }
                setState(() {});
              },
            ),
            CheckboxItem(
              title: 'Show size',
              value: _showSize,
              onChanged: (newValue) {
                setState(() => _showSize = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Label text',
              value: _showLabelText,
              onChanged: (newValue) {
                setState(() => _showLabelText = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Label widget',
              value: _showLabel,
              onChanged: (newValue) {
                setState(() => _showLabel = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Hint',
              value: _showHint,
              onChanged: (newValue) {
                setState(() => _showHint = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Error',
              value: _showError,
              onChanged: (newValue) {
                setState(() => _showError = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Counter text',
              value: _showCounterText,
              onChanged: (newValue) {
                setState(() => _showCounterText = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Counter widget',
              value: _showCounterWidget,
              onChanged: (newValue) {
                setState(() => _showCounterWidget = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Icon',
              value: _showIcon,
              onChanged: (newValue) {
                setState(() => _showIcon = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Prefix icon',
              value: _showPrefixIcon,
              onChanged: (newValue) {
                setState(() => _showPrefixIcon = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Prefix text',
              value: _showPrefixText,
              onChanged: (newValue) {
                setState(() => _showPrefixText = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Prefix widget',
              value: _showPrefix,
              onChanged: (newValue) {
                setState(() => _showPrefix = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Suffix icon',
              value: _showSuffixIcon,
              onChanged: (newValue) {
                setState(() => _showSuffixIcon = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Suffix text',
              value: _showSuffixText,
              onChanged: (newValue) {
                setState(() => _showSuffixText = newValue!);
              },
            ),
            CheckboxItem(
              title: 'Suffix widget',
              value: _showSuffix,
              onChanged: (newValue) {
                setState(() => _showSuffix = newValue!);
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
                  decoration: (_showSize) ? redBorder : null,
                  child: TextField(
                    decoration: InputDecoration(
                      border: (_borderValue == BorderType.sideline)
                          ? const UnderlineInputBorder()
                          : _borderValue.border,
                      labelText: (_showLabelText) ? text : null,
                      label: (_showLabel) ? box : null,
                      hintText: (_showHint) ? text : null,
                      errorText: (_showError) ? text : null,
                      counterText: (_showCounterText) ? text : null,
                      counter: (_showCounterWidget) ? box : null,
                      icon: (_showIcon) ? icon : null,
                      prefix: (_showPrefix) ? box : null,
                      prefixIcon: (_showPrefixIcon) ? icon : null,
                      prefixText: (_showPrefixText) ? text : null,
                      suffix: (_showSuffix) ? box : null,
                      suffixIcon: (_showSuffixIcon) ? icon : null,
                      suffixText: (_showSuffixText) ? text : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Container(
                    decoration: (_showSize) ? redBorder : null,
                    child: MongolTextField(
                      decoration: InputDecoration(
                        border: _borderValue.border,
                        labelText: (_showLabelText) ? text : null,
                        label: (_showLabel) ? box : null,
                        hintText: (_showHint) ? text : null,
                        errorText: (_showError) ? text : null,
                        counterText: (_showCounterText) ? text : null,
                        counter: (_showCounterWidget) ? box : null,
                        icon: (_showIcon) ? icon : null,
                        prefix: (_showPrefix) ? box : null,
                        prefixIcon: (_showPrefixIcon) ? icon : null,
                        prefixText: (_showPrefixText) ? text : null,
                        suffix: (_showSuffix) ? box : null,
                        suffixIcon: (_showSuffixIcon) ? icon : null,
                        suffixText: (_showSuffixText) ? text : null,
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
