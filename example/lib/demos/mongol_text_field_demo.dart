import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class MongolTextFieldDemo extends StatelessWidget {
  const MongolTextFieldDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongolTextField')),
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
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: MongolTextField(
                    style: const TextStyle(fontSize: 24),
                    controller: controller1,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: TextField(
                    style: const TextStyle(fontSize: 24),
                    controller: controller1,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MongolTextField(
                style: const TextStyle(fontSize: 24),
                controller: controller2,
                textAlignHorizontal: TextAlignHorizontal.left,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: MongolOutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
