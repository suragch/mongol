import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

/// This demo shows that MongolText can be resized with pinch to zoom.
class GestureDetectorDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          color: Colors.blue[100],
          child: SafeArea(child: GestureText()),
        ),
      ),
    );
  }
}

class GestureText extends StatefulWidget {
  const GestureText({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _GestureTextState createState() => _GestureTextState();
}

class _GestureTextState extends State<GestureText> {
  double _fontSize = 100;
  final double _baseFontSize = 20;
  double _fontScale = 1;
  double _baseFontScale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (ScaleStartDetails scaleStartDetails) {
        _baseFontScale = _fontScale;
      },
      onScaleUpdate: (ScaleUpdateDetails scaleUpdateDetails) {
        setState(() {
          _fontScale =
              (_baseFontScale * scaleUpdateDetails.scale).clamp(0.5, 10.0) as double;
          _fontSize = _fontScale * _baseFontSize;
        });
      },
      child: MongolText(
        'ᠮᠣᠩᠭᠣᠯ\nᠪᠢᠴᠢᠭ',
        style: TextStyle(fontSize: _fontSize),
      ),
    );
  }
}
