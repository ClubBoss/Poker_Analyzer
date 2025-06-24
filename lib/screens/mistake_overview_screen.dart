import 'package:flutter/material.dart';

import 'tag_mistake_overview_screen.dart';
import 'position_mistake_overview_screen.dart';
import 'street_mistake_overview_screen.dart';

class MistakeOverviewScreen extends StatefulWidget {
  const MistakeOverviewScreen({super.key});

  @override
  State<MistakeOverviewScreen> createState() => _MistakeOverviewScreenState();
}

class _MistakeOverviewScreenState extends State<MistakeOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки'),
        centerTitle: true,
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: 'По тегам'),
            Tab(text: 'По позициям'),
            Tab(text: 'По улицам'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [
          TagMistakeOverviewScreen(),
          PositionMistakeOverviewScreen(),
          StreetMistakeOverviewScreen(),
        ],
      ),
    );
  }
}
