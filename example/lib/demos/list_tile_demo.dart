import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

//const text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';
class ListTileDemo extends StatefulWidget {
  const ListTileDemo({super.key});

  @override
  State<ListTileDemo> createState() => _ListTileDemoState();
}

class _ListTileDemoState extends State<ListTileDemo> {
  var _material3 = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(useMaterial3: _material3, fontFamily: 'MenksoftQagan'),
      child: Scaffold(
        appBar: AppBar(title: const Text('MongolListTile')),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _material3 = !_material3;
            });
          },
          child: const Icon(Icons.refresh),
        ),
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
      ),
    );
  }
}
