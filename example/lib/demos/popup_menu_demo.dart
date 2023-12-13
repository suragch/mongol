import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class PopupMenuDemo extends StatelessWidget {
  const PopupMenuDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MongolPopupMenuButton'),
        actions: [
          MongolPopupMenuButton(
            itemBuilder: (context) => const [
              MongolPopupMenuItem(value: 1, child: MongolText('ᠨᠢᠭᠡ')),
              MongolPopupMenuItem(value: 2, child: MongolText('ᠬᠤᠶᠠᠷ')),
              MongolPopupMenuItem(value: 3, child: MongolText('ᠭᠤᠷᠪᠠ')),
            ],
            tooltip: 'Mongol Popup Menu Button',
            onSelected: (value) => _showStackBar(context, value),
          ),
        ],
      ),
      body: Center(
        child: MongolPopupMenuButton(
          icon: const Icon(Icons.other_houses),
          itemBuilder: (context) => const [
            MongolPopupMenuItem(value: 1, child: MongolText('ᠨᠢᠭᠡ')),
            MongolPopupMenuItem(value: 2, child: MongolText('ᠬᠤᠶᠠᠷ')),
            MongolPopupMenuItem(value: 3, child: MongolText('ᠭᠤᠷᠪᠠ')),
          ],
          tooltip: 'Mongol Popup Menu Button',
          onSelected: (value) => _showStackBar(context, value),
        ),
      ),
    );
  }

  _showStackBar(BuildContext context, Object? value) {
    final snackBar = SnackBar(
      content: Text('$value'),
      duration: const Duration(milliseconds: 500),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
