import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/daily_challenge_history_service.dart';

class DailyChallengeHistoryScreen extends StatefulWidget {
  const DailyChallengeHistoryScreen({super.key});

  @override
  State<DailyChallengeHistoryScreen> createState() =>
      _DailyChallengeHistoryScreenState();
}

class _DailyChallengeHistoryScreenState
    extends State<DailyChallengeHistoryScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<DateTime> _history = {};

  @override
  void initState() {
    super.initState();
    DailyChallengeHistoryService.instance.loadHistorySet().then((set) {
      setState(() {
        _history = set;
      });
    });
  }

  List<DateTime> _daysForGrid() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startOffset =
        firstOfMonth.weekday % 7; // Monday=1 ... Sunday=7 -> 0..6
    final start = firstOfMonth.subtract(Duration(days: startOffset));
    return [for (int i = 0; i < 42; i++) start.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysForGrid();
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 История челленджей'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat.yMMMM('ru_RU').format(_focusedMonth),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final d = days[index];
                final key = DateTime(d.year, d.month, d.day);

                Color bgColor;
                if (key.isAfter(todayKey)) {
                  bgColor = Colors.white10;
                } else if (_history.contains(key)) {
                  bgColor = Colors.green;
                } else {
                  bgColor = Colors.red;
                }

                final inMonth = d.month == _focusedMonth.month;
                final textColor = inMonth ? Colors.white : Colors.white38;

                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${d.day}',
                      style: TextStyle(color: textColor, fontSize: 12)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
