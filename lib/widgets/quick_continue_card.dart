import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/spot_of_the_day_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/weekly_challenge_service.dart';
import '../services/training_pack_storage_service.dart';
import '../screens/training_pack_review_screen.dart';
import '../screens/training_pack_screen.dart';
import '../screens/training_screen.dart';

class QuickContinueCard extends StatefulWidget {
  const QuickContinueCard({super.key});

  @override
  State<QuickContinueCard> createState() => _QuickContinueCardState();
}

class _ContinueItem {
  final String title;
  final int progress;
  final int total;
  final DateTime date;
  final WidgetBuilder builder;
  const _ContinueItem({
    required this.title,
    required this.progress,
    required this.total,
    required this.date,
    required this.builder,
  });
}

class _QuickContinueCardState extends State<QuickContinueCard> {
  _ContinueItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final spot = context.read<SpotOfTheDayService>().currentSpot;
    final spotResult = context.read<SpotOfTheDayService>().result;
    final mistake = context.read<MistakeReviewPackService>();
    final challenge = context.read<WeeklyChallengeService>();
    final packs = context.read<TrainingPackStorageService>().packs;
    final prefs = await SharedPreferences.getInstance();
    final items = <_ContinueItem>[];
    if (spot != null && spotResult == null) {
      items.add(
        _ContinueItem(
          title: 'Spot of the Day',
          progress: 0,
          total: 1,
          date: DateTime.now(),
          builder: (_) => TrainingScreen(spot: spot),
        ),
      );
    }
    final mPack = mistake.pack;
    if (mPack != null && mistake.progress < mPack.hands.length) {
      items.add(
        _ContinueItem(
          title: 'Repeat Mistakes',
          progress: mistake.progress,
          total: mPack.hands.length,
          date: DateTime.now(),
          builder: (_) => TrainingPackReviewScreen(
            pack: mPack,
            mistakenNames: {for (final h in mPack.hands) h.name},
          ),
        ),
      );
    }
    final c = challenge.current;
    final cProgress = challenge.progressValue;
    if (cProgress > 0 && cProgress < c.target) {
      items.add(
        _ContinueItem(
          title: c.title,
          progress: cProgress,
          total: c.target,
          date: DateTime.now(),
          builder: (_) => TrainingPackReviewScreen(pack: challenge.currentPack),
        ),
      );
    }
    for (final p in packs) {
      final idx = prefs.getInt('training_progress_${p.name}') ?? 0;
      if (idx > 0 && idx < p.hands.length) {
        final date = p.history.isNotEmpty
            ? p.history.last.date
            : DateTime.now();
        items.add(
          _ContinueItem(
            title: p.name,
            progress: idx,
            total: p.hands.length,
            date: date,
            builder: (_) => TrainingPackScreen(pack: p),
          ),
        );
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _item = items.isNotEmpty ? items.first : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final item = _item;
    if (item == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final value = (item.progress / item.total).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_arrow, color: Colors.lightBlueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${item.progress}/${item.total}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: item.builder),
              ).then((_) => _load());
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
