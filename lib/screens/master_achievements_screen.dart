import 'package:flutter/material.dart';
import '../services/daily_challenge_history_service.dart';
import '../services/daily_challenge_streak_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<int> _streakFuture;
  late Future<List<DateTime>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _streakFuture = DailyChallengeStreakService.instance.getCurrentStreak();
    _historyFuture = DailyChallengeHistoryService.instance.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\uD83C\uDFC6 Достижения'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_streakFuture, _historyFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final streak = snapshot.data![0] as int? ?? 0;
          final history = snapshot.data![1] as List<DateTime>;
          final completedCount = history.length;
          final achievements = [
            _Achievement(
              '\uD83E\uDD49 Первые шаги',
              'Заверши 1 челлендж',
              completedCount >= 1,
            ),
            _Achievement(
              '\uD83D\uDD25 Не остановиться!',
              'Заверши 3 дня подряд',
              streak >= 3,
            ),
            _Achievement(
              '\uD83E\uDDF1 Формируется привычка',
              'Заверши 7 дней подряд',
              streak >= 7,
            ),
            _Achievement(
              '\uD83E\uDD48 Настойчивый',
              'Заверши 14 дней подряд',
              streak >= 14,
            ),
            _Achievement(
              '\uD83C\uDFC6 Легенда',
              'Заверши 30 дней подряд',
              streak >= 30,
            ),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final a in achievements) _buildItem(a)],
          );
        },
      ),
    );
  }

  Widget _buildItem(_Achievement data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(data.desc, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            data.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: data.done ? Colors.green : Colors.white54,
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String desc;
  final bool done;
  const _Achievement(this.title, this.desc, this.done);
}
