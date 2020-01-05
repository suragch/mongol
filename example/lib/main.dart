import 'package:flutter/material.dart';
import 'package:mongol_demo_app/text_demo.dart';

void main() => runApp(DemoApp());

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mongol',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Mongol package demo')),
        body: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('MongolText'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TextDemo()),
            );
          },
        ),
      ],
    );
  }
}
