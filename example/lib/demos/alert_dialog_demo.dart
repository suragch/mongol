import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class AlertDialogDemo extends StatelessWidget {
  const AlertDialogDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongolAlertDialog')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Dialog'),
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
  Widget actionButton = MongolTextButton(
    child: const MongolText('ᠮᠡᠳᠡᠭᠰᠡᠨ'),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  final alert = MongolAlertDialog(
    title: const MongolText('ᠠᠰᠠᠭᠤᠳᠠᠯ ᠲᠠᠢ'),
    content: const MongolText('ᠬᠣᠯᠪᠣᠭᠳᠠᠬᠤ ᠪᠣᠯᠤᠮᠵᠢ ᠦᠭᠡᠢ ᠪᠠᠶᠢᠨ᠎ᠠ'),
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
