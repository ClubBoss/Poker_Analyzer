import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_session.dart';
import '../services/pack_library_loader_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/training_session_launcher.dart';
import '../services/weakness_review_engine.dart';
import '../services/engagement_analytics_service.dart';

class MistakeReviewButton extends StatefulWidget {
  final TrainingSession session;
  final TrainingPackTemplate template;
  const MistakeReviewButton({
    super.key,
    required this.session,
    required this.template,
  });

  @override
  State<MistakeReviewButton> createState() => _MistakeReviewButtonState();
}

class _MistakeReviewButtonState extends State<MistakeReviewButton> {
  WeaknessReviewItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final total = widget.session.results.length;
    final correct = widget.session.results.values.where((e) => e).length;
    final acc = total == 0 ? 0.0 : correct / total;
    if (acc >= 0.6) {
      setState(() => _loading = false);
      return;
    }
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;

    final stats = <String, TrainingPackStat>{};
    for (final p in packs) {
      final s = await TrainingPackStatsService.getStats(p.id);
      if (s != null) stats[p.id] = s;
    }

    final attempts = <TrainingAttempt>[];
    final now = DateTime.now();
    widget.session.results.forEach((spotId, ok) {
      attempts.add(
        TrainingAttempt(
          packId: widget.template.id,
          spotId: spotId,
          timestamp: now,
          accuracy: ok ? 1.0 : 0.0,
          ev: 0,
          icm: 0,
        ),
      );
    });

    final deltas = await context.read<TagMasteryService>().computeDelta();

    final list = const WeaknessReviewEngine().analyze(
      attempts: attempts,
      stats: stats,
      tagDeltas: deltas,
      allPacks: packs,
    );

    if (!mounted) return;
    setState(() {
      _item = list.firstOrNull;
      _loading = false;
    });
  }

  Future<void> _startPack() async {
    final item = _item;
    if (item == null) return;
    final packs = PackLibraryLoaderService.instance.library;
    final tpl = packs.firstWhereOrNull((p) => p.id == item.packId);
    if (tpl == null) return;
    await const TrainingSessionLauncher().launch(tpl);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _item == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: () {
          final item = _item;
          if (item != null) {
            unawaited(
              EngagementAnalyticsService.instance.logEvent(
                'review_cta.tap',
                source: 'MistakeReviewButton',
                tag: item.tag,
                packId: item.packId,
              ),
            );
          }
          _startPack();
        },
        child: const Text('🔁 Review Related Spots'),
      ),
    );
  }
}
