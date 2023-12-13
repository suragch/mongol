import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

//const text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';
class ListTileDemo extends StatelessWidget {
  const ListTileDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongolListTile')),
      body: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          Card(child: MongolListTile(title: MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ'))),
          Card(
            child: MongolListTile(
              leading: FlutterLogo(),
              title: MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ'),
            ),
          ),
          Card(
            child: MongolListTile(
              title: MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ'),
              trailing: Icon(Icons.more_vert),
            ),
          ),
          Card(
            child: MongolListTile(
              leading: FlutterLogo(),
              title: MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ'),
              trailing: Icon(Icons.more_vert),
            ),
          ),
          Card(
            child: MongolListTile(
              title: MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ'),
              dense: true,
            ),
          ),
          Card(
            child: MongolListTile(
              leading: FlutterLogo(size: 56.0),
              title: MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ'),
              subtitle: MongolText('ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ'),
              trailing: Icon(Icons.more_vert),
            ),
          ),
          Card(
            child: MongolListTile(
              leading: FlutterLogo(size: 72.0),
              title: MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ'),
              subtitle: MongolText(
                'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ',
                maxLines: 2,
              ),
              trailing: Icon(Icons.more_vert),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}
