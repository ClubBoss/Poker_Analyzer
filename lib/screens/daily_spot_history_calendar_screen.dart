import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/goals_service.dart';
import '../widgets/sync_status_widget.dart';

class DailySpotHistoryCalendarScreen extends StatefulWidget {
  const DailySpotHistoryCalendarScreen({super.key});

  @override
  State<DailySpotHistoryCalendarScreen> createState() =>
      _DailySpotHistoryCalendarScreenState();
}

class _DailySpotHistoryCalendarScreenState
    extends State<DailySpotHistoryCalendarScreen> {
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  final DateTime _focusedDay = DateTime.now();
  Set<DateTime> _history = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstDay = DateTime(now.year, now.month, 1);
    _lastDay = DateTime(now.year, now.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final list = await context.read<GoalsService>().getDailySpotHistory();
      setState(() {
        _history = {for (final d in list) DateTime(d.year, d.month, d.day)};
      });
    });
  }

  List _eventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _history.contains(d) ? [d] : [];
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('История спотов дня'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: TableCalendar(
        locale: 'ru_RU',
        firstDay: _firstDay,
        lastDay: _lastDay,
        focusedDay: _focusedDay,
        eventLoader: _eventsForDay,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: Colors.white),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white70),
          outsideTextStyle: const TextStyle(color: Colors.white38),
          todayDecoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          markersAlignment: Alignment.bottomCenter,
          markersMaxCount: 1,
        ),
      ),
    );
  }
}
