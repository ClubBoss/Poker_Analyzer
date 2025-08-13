import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_learning_goal_service.dart';

class DailyGoalStreakScreen extends StatefulWidget {
  const DailyGoalStreakScreen({super.key});

  @override
  State<DailyGoalStreakScreen> createState() => _DailyGoalStreakScreenState();
}

class _DailyGoalStreakScreenState extends State<DailyGoalStreakScreen> {
  Set<DateTime> _completed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final list = context.read<DailyLearningGoalService>().getCompletedDays();
      setState(() {
        _completed = {for (final d in list) DateTime(d.year, d.month, d.day)};
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyLearningGoalService>();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final days = [for (var i = 0; i < 30; i++) start.add(Duration(days: i))];
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Цепочка целей'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Текущий стрик: ${service.getCurrentStreak()} дней',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Рекорд: ${service.getMaxStreak()} дней',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
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
                final completed =
                    _completed.contains(DateTime(d.year, d.month, d.day));
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: completed ? Colors.blue : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed ? Colors.blue : Colors.white38,
                    ),
                  ),
                  child: Text(
                    '${d.day}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
