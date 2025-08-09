import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/smart_resume_engine.dart';
import '../services/training_pack_storage_service.dart';
import '../services/training_pack_stats_service.dart';
import '../screens/training_pack_screen.dart';
import '../screens/v2/training_pack_play_screen.dart';
import '../widgets/difficulty_chip.dart';
import '../models/training_pack.dart';

class QuickAccessMenu extends StatefulWidget {
  const QuickAccessMenu({super.key});

  @override
  State<QuickAccessMenu> createState() => _QuickAccessMenuState();
}

class _QuickAccessMenuState extends State<QuickAccessMenu> {
  UnfinishedPack? _unfinished;
  var _recent = <_RecentPack>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resume = await SmartResumeEngine.instance.getRecentUnfinished(limit: 1);
    final storage = context.read<TrainingPackStorageService>();
    final packs = List<TrainingPack>.from(storage.packs)
      ..removeWhere((p) => p.history.isEmpty)
      ..sort((a, b) => b.lastAttemptDate.compareTo(a.lastAttemptDate));
    final recent = <_RecentPack>[];
    for (final p in packs.take(3)) {
      final done = await TrainingPackStatsService.getHandsCompleted(p.id);
      final progress = p.hands.isEmpty ? 0.0 : done / p.hands.length;
      recent.add(_RecentPack(pack: p, progress: progress.clamp(0, 1))); 
    }
    if (!mounted) return;
    setState(() {
      _unfinished = resume.isNotEmpty ? resume.first : null;
      _recent = recent;
    });
  }

  Future<void> _resume() async {
    final p = _unfinished;
    if (p == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(
          template: p.template,
          original: p.template,
        ),
      ),
    );
    await _load();
  }

  Future<void> _open(_RecentPack p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: p.pack)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_unfinished == null && _recent.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_unfinished != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resume,
                child: const Text('Resume Last Pack'),
              ),
            ),
          for (final r in _recent)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: DifficultyChip(r.pack.difficulty),
              title: Text(r.pack.name),
              subtitle: LinearProgressIndicator(value: r.progress),
              trailing: Text('${(r.progress * 100).round()}%'),
              onTap: () => _open(r),
            ),
        ],
      ),
    );
  }
}

class _RecentPack {
  final TrainingPack pack;
  final double progress;
  _RecentPack({required this.pack, required this.progress});
}
