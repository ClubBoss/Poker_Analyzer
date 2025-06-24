import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/constants.dart';

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppConstants.radius8),
              ),
              child: TabBar(
                controller: _controller,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white70,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radius8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'По тегам'),
                  Tab(text: 'По позициям'),
                  Tab(text: 'По улицам'),
                ],
              ),
            ),
          ),
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
