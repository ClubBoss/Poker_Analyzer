import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hypothetical Deals',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Hypothetical Deals'),
        ),
        body: ListView(
          children: const [
            ListTile(
              title: Text('Раздача #1'),
              subtitle: Text('Ваше решение: Колл'),
            ),
            ListTile(
              title: Text('Раздача #2'),
              subtitle: Text('Ваше решение: Фолд'),
            ),
          ],
        ),
      ),
    );
  }
}

