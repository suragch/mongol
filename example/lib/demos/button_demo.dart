import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class ButtonDemo extends StatefulWidget {
  const ButtonDemo({super.key});

  @override
  State<ButtonDemo> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<ButtonDemo> {
  var _material3 = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'MenksoftQagan',
        useMaterial3: _material3,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Buttons'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _material3 = !_material3;
            });
          },
          child: const Icon(Icons.refresh),
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MongolTextButton(
                    onPressed: () {
                      _showStackBar(context, 'MongolTextButton');
                    },
                    child: const MongolText('ᠨᠢᠭᠡ'),
                  ),
                  const SizedBox(width: 16),
                  MongolOutlinedButton(
                    onPressed: () {
                      _showStackBar(context, 'MongolOutlinedButton');
                    },
                    child: const MongolText('ᠬᠣᠶᠠᠷ'),
                  ),
                  const SizedBox(width: 16),
                  MongolElevatedButton(
                    onPressed: () {
                      _showStackBar(context, 'MongolElevatedButton');
                    },
                    child: const MongolText('ᠭᠤᠷᠪᠠ'),
                  ),
                  const SizedBox(width: 16),
                  MongolFilledButton(
                    onPressed: () {
                      _showStackBar(context, 'MongolFilledButton');
                    },
                    child: const MongolText('ᠳᠦᠷᠪᠡ'),
                  ),
                  const SizedBox(width: 16),
                  MongolFilledButton.tonal(
                    onPressed: () {
                      _showStackBar(context, 'MongolFilledButton.tonal');
                    },
                    child: const MongolText('ᠲᠠᠪᠤ'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MongolTextButton.icon(
                    onPressed: () {
                      _showStackBar(context, 'MongolTextButton.icon');
                    },
                    icon: const Icon(Icons.local_florist),
                    label: const MongolText('ᠨᠢᠭᠡ'),
                  ),
                  const SizedBox(width: 16),
                  MongolOutlinedButton.icon(
                    onPressed: () {
                      _showStackBar(context, 'MongolOutlinedButton.icon');
                    },
                    icon: const Icon(Icons.local_florist),
                    label: const MongolText('ᠬᠣᠶᠠᠷ'),
                  ),
                  const SizedBox(width: 16),
                  MongolElevatedButton.icon(
                    onPressed: () {
                      _showStackBar(context, 'MongolElevatedButton.icon');
                    },
                    icon: const Icon(Icons.local_florist),
                    label: const MongolText('ᠭᠤᠷᠪᠠ'),
                  ),
                  const SizedBox(width: 16),
                  MongolFilledButton.icon(
                    onPressed: () {
                      _showStackBar(context, 'MongolFilledButton.icon');
                    },
                    label: const MongolText('ᠳᠦᠷᠪᠡ'),
                    icon: const Icon(Icons.local_florist),
                  ),
                  const SizedBox(width: 16),
                  MongolFilledButton.tonalIcon(
                    onPressed: () {
                      _showStackBar(context, 'MongolFilledButton.tonalIcon');
                    },
                    label: const MongolText('ᠲᠠᠪᠤ'),
                    icon: const Icon(Icons.local_florist),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MongolIconButton(
                    onPressed: () {
                      _showStackBar(context, 'MongolIconButton');
                    },
                    icon: const Icon(Icons.local_florist),
                    tooltip: 'ᠨᠢᠭᠡ',
                  ),
                  const SizedBox(width: 16),
                  MongolIconButton.filled(
                    onPressed: () {
                      _showStackBar(context, 'MongolIconButton.filled');
                    },
                    icon: const Icon(Icons.local_florist),
                    tooltip: 'ᠬᠣᠶᠠᠷ',
                  ),
                  const SizedBox(width: 16),
                  MongolIconButton.filledTonal(
                    onPressed: () {
                      _showStackBar(context, 'MongolIconButton.filledTonal');
                    },
                    icon: const Icon(Icons.local_florist),
                    tooltip: 'ᠭᠤᠷᠪᠠ',
                  ),
                  const SizedBox(width: 16),
                  MongolIconButton.outlined(
                    onPressed: () {
                      _showStackBar(context, 'MongolIconButton.outlined');
                    },
                    icon: const Icon(Icons.local_florist),
                    tooltip: 'ᠳᠦᠷᠪᠡ',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showStackBar(BuildContext context, Object? value) {
    final snackBar = SnackBar(
      content: Text('$value'),
      duration: const Duration(milliseconds: 1000),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
