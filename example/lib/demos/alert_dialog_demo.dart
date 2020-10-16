import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class AlertDialogDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: RaisedButton(
          child: Text('Show Dialog'),
          onPressed: () {
            showAlertDialog(context);
          },
        ),
      ),
    );
  }
}

void showAlertDialog(BuildContext context) {
  // set up the buttons
  Widget actionButton = FlatButton(
    child: MongolText('ᠮᠡᠳᠡᠭᠰᠡᠨ'),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  final alert = MongolAlertDialog(
    title: MongolText('ᠠᠰᠠᠭᠤᠳᠠᠯ ᠲᠠᠢ'),
    content: MongolText('ᠬᠣᠯᠪᠣᠭᠳᠠᠬᠤ ᠪᠣᠯᠤᠮᠵᠢ ᠦᠭᠡᠢ ᠪᠠᠶᠢᠨ᠎ᠠ'),
    actions: [
      actionButton,
    ],
  );

  // show the dialog
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
