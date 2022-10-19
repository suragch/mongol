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
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: MongolTextField(
            decoration: InputDecoration(
              border: _borderValue.border,
            ),
          ),
        ),
        const Spacer(),
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
