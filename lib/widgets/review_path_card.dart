import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../services/scheduled_training_queue_service.dart';
import '../services/pack_library_service.dart';
import '../services/tag_insight_reminder_engine.dart';
import '../services/training_session_launcher.dart';
import '../services/skill_loss_detector.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/engagement_analytics_service.dart';

/// Card showing the top scheduled recovery pack.
class ReviewPathCard extends StatefulWidget {
  const ReviewPathCard({
    super.key,
    this.queue,
    this.library,
    this.reminder,
    this.launcher = const TrainingSessionLauncher(),
  });

  final ScheduledTrainingQueueService? queue;
  final PackLibraryService? library;
  final TagInsightReminderEngine? reminder;
  final TrainingSessionLauncher launcher;

  @override
  State<ReviewPathCard> createState() => _ReviewPathCardState();
}

class _ReviewPathCardState extends State<ReviewPathCard> {
  late Future<_CardData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CardData?> _load() async {
    final queue = widget.queue ?? ScheduledTrainingQueueService.instance;
    await queue.load();
    if (queue.queue.isEmpty) return null;
    final id = queue.queue.first;
    final pack = await (widget.library ?? PackLibraryService.instance).getById(
      id,
    );
    if (pack == null) return null;
    final tag = pack.tags.isNotEmpty ? pack.tags.first : '';
    final reminder =
        widget.reminder ?? context.read<TagInsightReminderEngine>();
    final losses = await reminder.loadLosses();
    final loss = losses.firstWhereOrNull((l) => l.tag == tag);
    return _CardData(pack: pack, tag: tag, loss: loss);
  }

  Future<void> _startRecovery(_CardData data) async {
    await widget.launcher.launch(data.pack);
    await (widget.queue ?? ScheduledTrainingQueueService.instance).pop();
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<_CardData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final loss = data.loss;
        final score = loss?.drop;
        final reason =
            loss != null ? 'Skill drop, ${loss.trend}' : 'Scheduled review';
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.tag,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (score != null)
                      Text(
                        'Urgency ${(score * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    Text(reason, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final d = data;
                  unawaited(
                    EngagementAnalyticsService.instance.logEvent(
                      'review_cta.tap',
                      source: 'ReviewPathCard',
                      tag: d.tag,
                      packId: d.pack.id,
                    ),
                  );
                  _startRecovery(d);
                },
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Recover now'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardData {
  final TrainingPackTemplateV2 pack;
  final String tag;
  final SkillLoss? loss;
  const _CardData({required this.pack, required this.tag, this.loss});
}
