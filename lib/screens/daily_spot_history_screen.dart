import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/goals_service.dart';
import '../widgets/sync_status_widget.dart';

class DailySpotHistoryScreen extends StatefulWidget {
  const DailySpotHistoryScreen({super.key});

  @override
  State<DailySpotHistoryScreen> createState() => _DailySpotHistoryScreenState();
}

class _DailySpotHistoryScreenState extends State<DailySpotHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _history = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final list = await context.read<GoalsService>().getDailySpotHistory();
      setState(() {
        _history = {for (final d in list) DateTime(d.year, d.month, d.day)};
      });
    });
  }

  List<dynamic> _eventsForDay(DateTime day) {
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
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ru_RU',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _eventsForDay,
            calendarFormat: CalendarFormat.month,
            onDaySelected: (sel, foc) {
              setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              });
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white70),
              outsideTextStyle: const TextStyle(color: Colors.white38),
              todayDecoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blueGrey,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markersMaxCount: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedDay == null
                ? '—'
                : _history.contains(DateTime(_selectedDay!.year,
                        _selectedDay!.month, _selectedDay!.day))
                    ? '✅ Выполнено'
                    : '—',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
