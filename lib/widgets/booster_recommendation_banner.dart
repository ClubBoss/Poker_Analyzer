import 'package:flutter/material.dart';

import '../services/theory_booster_recommender.dart';
import '../services/booster_library_service.dart';
import '../services/training_session_launcher.dart';

/// Persistent banner recommending a booster pack after theory lessons.
class BoosterRecommendationBanner extends StatefulWidget {
  final BoosterRecommendationResult recommendation;
  final VoidCallback? onStarted;
  final VoidCallback? onDismissed;

  const BoosterRecommendationBanner({
    super.key,
    required this.recommendation,
    this.onStarted,
    this.onDismissed,
  });

  @override
  State<BoosterRecommendationBanner> createState() =>
      _BoosterRecommendationBannerState();
}

class _BoosterRecommendationBannerState
    extends State<BoosterRecommendationBanner> {
  bool _loading = true;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await BoosterLibraryService.instance.loadAll();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _start() async {
    final tpl = BoosterLibraryService.instance.getById(
      widget.recommendation.boosterId,
    );
    if (tpl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booster pack not found')));
      return;
    }
    await const TrainingSessionLauncher().launch(tpl);
    widget.onStarted?.call();
    if (mounted) setState(() => _visible = false);
  }

  void _dismiss() {
    widget.onDismissed?.call();
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _loading) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final rec = widget.recommendation;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Укрепите теорию на практике',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Booster: ${rec.reasonTag}',
            style: const TextStyle(color: Colors.white70),
          ),
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
