import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class PopupMenuDemo extends StatefulWidget {
  const PopupMenuDemo({super.key});

  @override
  State<PopupMenuDemo> createState() => _PopupMenuDemoState();
}

class _PopupMenuDemoState extends State<PopupMenuDemo> {
  var _material3 = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'MenksoftQagan',
        useMaterial3: _material3,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MongolPopupMenuButton'),
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 1, child: Text('ᠨᠢᠭᠡ')),
                PopupMenuItem(value: 2, child: Text('ᠬᠤᠶᠠᠷ')),
                PopupMenuItem(value: 3, child: Text('ᠭᠤᠷᠪᠠ')),
              ],
              tooltip: 'Popup Menu Button',
              onSelected: (value) => _showStackBar(context, value),
            ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _material3 = !_material3;
            });
          },
          child: const Icon(Icons.refresh),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopupMenuButton(
                icon: const Icon(Icons.other_houses),
                itemBuilder: (context) => const [
                  CheckedPopupMenuItem(value: 1, child: Text('ᠨᠢᠭᠡ')),
                  CheckedPopupMenuItem(value: 2, child: Text('ᠬᠤᠶᠠᠷ')),
                  CheckedPopupMenuItem(value: 3, child: Text('ᠭᠤᠷᠪᠠ')),
                ],
                tooltip: 'Popup Menu Button',
                onSelected: (value) => _showStackBar(context, value),
              ),
              const SizedBox(width: 16),
              MongolPopupMenuButton(
                icon: const Icon(Icons.other_houses),
                itemBuilder: (context) => const [
                  MongolCheckedPopupMenuItem(value: 1, child: MongolText('ᠨᠢᠭᠡ')),
                  MongolCheckedPopupMenuItem(value: 2, child: MongolText('ᠬᠤᠶᠠᠷ')),
                  MongolCheckedPopupMenuItem(value: 3, child: MongolText('ᠭᠤᠷᠪᠠ')),
                ],
                tooltip: 'Mongol Popup Menu Button',
                onSelected: (value) => _showStackBar(context, value),
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
      duration: const Duration(milliseconds: 500),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
