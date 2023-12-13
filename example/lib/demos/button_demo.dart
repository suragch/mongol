import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class ButtonDemo extends StatelessWidget {
  const ButtonDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buttons'),
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
                MongolIconButton(
                  onPressed: () {
                    _showStackBar(context, 'MongolIconButton');
                  },
                  icon: const Icon(Icons.local_florist),
                  mongolTooltip: 'ᠳᠦᠷᠪᠡ',
                ),
              ],
            ),
          ],
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
