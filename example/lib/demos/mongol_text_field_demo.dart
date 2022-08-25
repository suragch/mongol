import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class MongolTextFieldDemo extends StatelessWidget {
  const MongolTextFieldDemo({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongolTextField')),
      body: const SearchBody(),
    );
  }
}

class SearchBody extends StatefulWidget {
  const SearchBody({Key? key}) : super(key: key);
  @override
  _SearchBodyState createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  TextEditingController controller = TextEditingController();

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
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: MongolTextField(
            style: const TextStyle(fontSize: 24),
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
