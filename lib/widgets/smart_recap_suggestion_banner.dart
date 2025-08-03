import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goal_analytics_service.dart';
import '../services/booster_pack_factory.dart';
import '../screens/training_session_screen.dart';
import '../services/user_goal_engine.dart';
import '../models/user_goal.dart';
import '../utils/snackbar_util.dart';

/// Banner suggesting a quick recap for a recently completed goal.
class SmartRecapSuggestionBanner extends StatefulWidget {
  const SmartRecapSuggestionBanner({super.key});

  @override
  State<SmartRecapSuggestionBanner> createState() =>
      _SmartRecapSuggestionBannerState();
}

class _SmartRecapSuggestionBannerState
    extends State<SmartRecapSuggestionBanner> {
  static const Duration _lookback = Duration(days: 2);

  bool _loading = true;
  UserGoal? _goal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final history = await GoalAnalyticsService.instance.getGoalHistory();
    final now = DateTime.now();
    final cutoff = now.subtract(_lookback);
    Map<String, dynamic>? latest;
    DateTime latestTs = DateTime.fromMillisecondsSinceEpoch(0);
    for (final e in history) {
      if (e['event'] != 'goal_completed') continue;
      final tsStr = e['timestamp'] as String? ?? e['time'] as String?;
      final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
      if (ts == null || ts.isBefore(cutoff)) continue;
      if (ts.isAfter(latestTs)) {
        latestTs = ts;
        latest = e;
      }
    }
    if (latest != null) {
      final id = latest['goalId'] as String?;
      final engine = context.read<UserGoalEngine>();
      _goal = engine.goals.firstWhere(
        (g) => g.id == id,
        orElse: () => UserGoal(
          id: id ?? '',
          title: latest!['tag'] ?? '',
          type: '',
          target: 0,
          base: 0,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startRecap() async {
    final tag = _goal?.tag ?? _goal?.title;
    if (tag == null || tag.isEmpty) return;
    final pack = await BoosterPackFactory.buildFromTags([tag]);
    if (pack == null) {
      if (mounted) {
        SnackbarUtil.showMessage(context, 'Нет тренировок по тегу');
      }
      return;
    }
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      TrainingSessionScreen.route,
      arguments: pack,
    );
    if (mounted) setState(() => _goal = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _goal == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final tag = _goal!.tag ?? _goal!.title;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('🎓', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Повторить цель: #$tag',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _startRecap,
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            child: const Text('Review again'),
          ),
        ],
      ),
    );
  }
}
