import 'package:flutter/material.dart';
import '../services/decay_boosted_practice_queue.dart';
import '../services/booster_queue_service.dart';
import '../services/decay_booster_training_launcher.dart';
import '../models/v2/training_spot_v2.dart';

/// Banner prompting the user to refresh decayed skills.
class DecayBoostedBanner extends StatefulWidget {
  const DecayBoostedBanner({super.key});

  @override
  State<DecayBoostedBanner> createState() => _DecayBoostedBannerState();
}

class _DecayBoostedBannerState extends State<DecayBoostedBanner> {
  bool _loading = true;
  bool _visible = false;
  List<TrainingSpotV2> _spots = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final list = await DecayBoostedPracticeQueue().prepareQueue();
    if (!mounted) return;
    setState(() {
      _spots = list;
      _visible = list.length >= 3;
      _loading = false;
    });
  }

  Future<void> _start() async {
    if (_spots.isEmpty) return;
    await BoosterQueueService.instance.addSpots(_spots);
    await const DecayBoosterTrainingLauncher().launch();
    if (!mounted) return;
    setState(() => _visible = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Навык восстановлен')));
  }

  void _dismiss() {
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_visible) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
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
            children: [
              const Expanded(
                child: Text(
                  '📉 Подзабытые навыки',
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
          const Text(
            'Освежи 3+ спота с низким мастерством',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Тренировать сейчас'),
            ),
          ),
        ],
      ),
    );
  }
}
