import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/adaptive_pack_recommender_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/training_session_launcher.dart';
import '../services/user_action_logger.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

/// Card widget showing the top adaptive pack recommendation.
class RecommendedNextPackCard extends StatefulWidget {
  const RecommendedNextPackCard({super.key});

  @override
  State<RecommendedNextPackCard> createState() =>
      _RecommendedNextPackCardState();
}

class _RecommendedNextPackCardState extends State<RecommendedNextPackCard> {
  TrainingPackTemplateV2? _pack;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final mastery = context.read<TagMasteryService>();
    final service = AdaptivePackRecommenderService(masteryService: mastery);
    final recs = await service.recommend(count: 1);
    if (!mounted) return;
    setState(() {
      _pack = recs.isNotEmpty ? recs.first.pack : null;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final pack = _pack;
    if (pack == null) return;
    await const TrainingSessionLauncher().launch(pack);
    await UserActionLogger.instance.log('adaptive_recommendation_launched');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final tags = _pack!.tags.take(3).join(', ');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Рекомендовано для тебя',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_pack!.name, style: const TextStyle(color: Colors.white)),
          if (tags.isNotEmpty)
            Text(tags, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Начать тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}
