import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class TextPainterDemo extends StatefulWidget {
  const TextPainterDemo({super.key});

  @override
  State<TextPainterDemo> createState() => _TextPainterDemoState();
}

class _TextPainterDemoState extends State<TextPainterDemo> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MongolTextPainter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _controller.text = 'ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ 👨‍👩‍👧 ᠭᠣᠷᠪᠠ '
                        'ᠳᠥᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ 四五六 ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ';

                    setState(() {});
                  },
                  icon: const Icon(Icons.abc),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: CustomPaint(
                    size: const Size(100, 300),
                    painter: MyPainter(text: _controller.text),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  const MyPainter({
    required this.text,
    super.repaint,
  });
  final String text;

  @override
  void paint(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 30,
      fontFamily: 'MenksoftQagan',
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = MongolTextPainter(
      text: textSpan,
    );
    textPainter.layout(
      minHeight: 0,
      maxHeight: size.height,
    );
    textPainter.paint(canvas, Offset.zero);

    final rectPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(0, 0, textPainter.width, textPainter.height);
    canvas.drawRect(rect, rectPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
