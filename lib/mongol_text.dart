import 'package:flutter/widgets.dart';

import 'mongol_rich_text.dart';

class MongolText extends StatelessWidget {
  const MongolText(
    this.data, {
    Key key,
  })  : assert(data != null, 'The data cannot be null.'),
        super(key: key);

  /// This is the text that the MongolText widget will display.
  final String data;

  @override
  Widget build(BuildContext context) {
    Widget result = MongolRichText(
      text: TextSpan(
        text: data,
      ),
    );
    return result;
  }
}
