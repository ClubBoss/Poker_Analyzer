import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/ignored_mistake_service.dart';

import 'tag_mistake_overview_screen.dart';
import 'position_mistake_overview_screen.dart';
import 'street_mistake_overview_screen.dart';
import '../widgets/sync_status_widget.dart';

class MistakeOverviewScreen extends StatefulWidget {
  const MistakeOverviewScreen({super.key});

  @override
  State<MistakeOverviewScreen> createState() => _MistakeOverviewScreenState();
}

class _MistakeOverviewScreenState extends State<MistakeOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  String _dateFilter = 'Все';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
    _controller.addListener(() {
      if (_currentIndex != _controller.index) {
        setState(() => _currentIndex = _controller.index);
      }
    });
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
        actions: [
          SyncStatusIcon.of(context),
          if (context.watch<IgnoredMistakeService>().ignored.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Сбросить игнор',
              onPressed: () => context.read<IgnoredMistakeService>().reset(),
            ),
        ],
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
                  borderRadius: BorderRadius.circular(AppConstants.radius8),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: _dateFilter,
              dropdownColor: const Color(0xFF2A2B2E),
              onChanged: (v) => setState(() => _dateFilter = v ?? 'Все'),
              items: const ['Сегодня', '7 дней', '30 дней', 'Все']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: _buildCurrentTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return TagMistakeOverviewScreen(
          key: ValueKey('tag-$_dateFilter'),
          dateFilter: _dateFilter,
        );
      case 1:
        return PositionMistakeOverviewScreen(
          key: ValueKey('position-$_dateFilter'),
          dateFilter: _dateFilter,
        );
      default:
        return StreetMistakeOverviewScreen(
          key: ValueKey('street-$_dateFilter'),
          dateFilter: _dateFilter,
        );
    }
  }
}
