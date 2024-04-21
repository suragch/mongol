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
                MongolIconButton(
                  onPressed: () {
                    _showStackBar(context, 'MongolIconButton');
                  },
                  icon: const Icon(Icons.local_florist),
                  mongolTooltip: 'ᠳᠦᠷᠪᠡ',
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
