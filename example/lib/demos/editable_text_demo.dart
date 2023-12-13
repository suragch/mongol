import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class MongolEditableTextDemo extends StatelessWidget {
  const MongolEditableTextDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongolEditableText')),
      body: const SearchBody(),
    );
  }
}

class SearchBody extends StatefulWidget {
  const SearchBody({super.key});
  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  TextEditingController controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
          child: MongolEditableText(
            style: const TextStyle(fontSize: 24, color: Colors.black),
            controller: controller,
            maxLines: null,
            cursorColor: Colors.blue,
            focusNode: focusNode,
            autofocus: true,
          ),
        ),
      ),
    );
  }
}
