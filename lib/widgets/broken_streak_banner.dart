import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/review_streak_evaluator_service.dart';
import '../services/pack_recall_stats_service.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/training_session_launcher.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../helpers/date_utils.dart';
import '../models/v2/training_pack_template_v2.dart';

class BrokenStreakBanner extends StatefulWidget {
  final String? packId;
  const BrokenStreakBanner({super.key, this.packId});

  @override
  State<BrokenStreakBanner> createState() => _BrokenStreakBannerState();
}

class _BrokenStreakBannerState extends State<BrokenStreakBanner> {
  late Future<List<_StreakInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_StreakInfo>> _load() async {
    const evaluator = ReviewStreakEvaluatorService();
    List<String> ids;
    if (widget.packId != null) {
      final broken = await evaluator.streakBreakDate(widget.packId!);
      ids = broken != null ? [widget.packId!] : <String>[];
    } else {
      ids = await evaluator.packsWithBrokenStreaks();
    }
    final storage = context.read<TrainingPackTemplateStorageService>();
    final stats = PackRecallStatsService.instance;
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final result = <_StreakInfo>[];
    for (final id in ids) {
      final tpl = await storage.loadById(id);
      if (tpl == null) continue;
      final breakDate = await evaluator.streakBreakDate(id);
      if (breakDate == null) continue;
      final history = await stats.getReviewHistory(id);
      final last = history.isNotEmpty ? history.last : breakDate;
      result.add(_StreakInfo(tpl, breakDate, last));
    }
    result.sort((a, b) => a.breakDate.compareTo(b.breakDate));
    final limit = widget.packId != null ? 1 : 2;
    return result.take(limit).toList();
  }

  Future<void> _start(TrainingPackTemplateV2 tpl) async {
    await const TrainingSessionLauncher().launch(tpl);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<List<_StreakInfo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
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
              const Text(
                'Возобновите серию тренировок',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < items.length; i++) ...[
                _itemRow(items[i], accent),
                if (i < items.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _itemRow(_StreakInfo info, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info.tpl.name, style: const TextStyle(color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Последняя сессия: ${formatDate(info.lastReview)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _start(info.tpl),
          style: ElevatedButton.styleFrom(backgroundColor: accent),
          child: const Text('Восстановить повторение'),
        ),
      ],
    );
  }
}

class _StreakInfo {
  final TrainingPackTemplateV2 tpl;
  final DateTime breakDate;
  final DateTime lastReview;
  _StreakInfo(this.tpl, this.breakDate, this.lastReview);
}
