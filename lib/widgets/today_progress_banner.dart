import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/preference_state.dart';
import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';
import '../services/streak_counter_service.dart';
import 'package:intl/intl.dart';
import 'confetti_overlay.dart';

class TodayProgressBanner extends StatefulWidget {
  const TodayProgressBanner({super.key});

  @override
  State<TodayProgressBanner> createState() => _TodayProgressBannerState();
}

class _TodayProgressBannerState extends State<TodayProgressBanner>
    with SingleTickerProviderStateMixin, PreferenceState<TodayProgressBanner> {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  DateTime? _day;
  bool _celebrated = false;
  DateTime? _lastCelebration;
  static const _prefKey = 'today_progress_banner_confetti';
  StreamSubscription<int>? _recordSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50,
      ),
    ]).animate(_controller);
    _recordSub =
        context.read<StreakCounterService>().recordStream.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🏆 New record!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void onPrefsLoaded() {
    final str = prefs.getString(_prefKey);
    if (str != null) {
      _lastCelebration = DateTime.tryParse(str);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _checkCelebrate(int hands, int target) {
    if (!prefsReady) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_day == null || !_isSameDay(_day!, today)) {
      _day = today;
      _celebrated = false;
    }
    if (!_celebrated && hands >= target && target > 0) {
      if (_lastCelebration == null || !_isSameDay(_lastCelebration!, today)) {
        _celebrated = true;
        _lastCelebration = today;
        prefs.setString(_prefKey, today.toIso8601String());
        _controller.forward(from: 0);
        HapticFeedback.mediumImpact();
        showConfettiOverlay(context);
      }
    }
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final target = context.watch<DailyTargetService>().target;
    final streakService = context.watch<StreakCounterService>();
    final streak = streakService.count;
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final hands = stats.handsPerDay[today] ?? 0;
    final dailyMistakes = stats.mistakesDaily(1);
    final mistakes = dailyMistakes.isNotEmpty ? dailyMistakes.first.value : 0;
    final color = mistakes > 0
        ? Colors.redAccent
        : Theme.of(context).colorScheme.secondary;

    _checkCelebrate(hands, target);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today: $hands/$target hands \u00b7 $mistakes mistakes',
                style: const TextStyle(color: Colors.white),
              ),
              if (streak > 0)
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text('$streak',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          ScaleTransition(
            scale: _pulse,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (hands / target).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          if (streak == 0 && streakService.lastSuccess != null)
            Builder(builder: (context) {
              final last = streakService.lastSuccess!;
              final diff = today.difference(
                      DateTime(last.year, last.month, last.day))
                  .inDays;
              if (diff > 1) {
                final date =
                    DateFormat('d MMM', Intl.getCurrentLocale()).format(last);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🔥 Streak Lost',
                              style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 8),
                          Text(date,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => streakService.restart(),
                        child: const Text('Restart'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
        ],
      ),
    );
  }
}
