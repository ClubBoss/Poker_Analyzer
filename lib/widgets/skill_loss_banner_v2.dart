import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/skill_loss_feed_engine.dart';
import '../services/tag_insight_reminder_engine.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/engagement_analytics_service.dart';

/// Compact banner showing top skill losses as review chips.
class SkillLossBannerV2 extends StatefulWidget {
  const SkillLossBannerV2({super.key});

  @override
  State<SkillLossBannerV2> createState() => _SkillLossBannerV2State();
}

class _SkillLossBannerV2State extends State<SkillLossBannerV2> {
  late Future<List<SkillLossFeedItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SkillLossFeedItem>> _load() async {
    final reminder = context.read<TagInsightReminderEngine>();
    final losses = await reminder.loadLosses();
    return const SkillLossFeedEngine().buildFeed(losses);
  }

  Future<void> _review(SkillLossFeedItem item) async {
    final id = item.suggestedPackId;
    if (id == null) return;
    final pack = await PackLibraryService.instance.getById(id);
    if (pack != null) {
      await const TrainingSessionLauncher().launch(pack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<List<SkillLossFeedItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        final display = items.take(3).toList();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent),
          ),
          child: Wrap(
            spacing: 8,
            children: [
              for (final item in display)
                ActionChip(
                  onPressed: () {
                    unawaited(
                      EngagementAnalyticsService.instance.logEvent(
                        'review_cta.tap',
                        source: 'SkillLossBannerV2',
                        tag: item.tag,
                        packId: item.suggestedPackId,
                      ),
                    );
                    _review(item);
                  },
                  backgroundColor: Colors.grey[700],
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.tag,
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(item.urgencyScore * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
