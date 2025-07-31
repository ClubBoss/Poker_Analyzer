import 'package:flutter/material.dart';

import '../services/booster_queue_service.dart';
import '../services/training_booster_launcher.dart';
import '../models/v2/training_spot_v2.dart';

/// Banner prompting the user to play queued decay boosters.
class DecayBoosterDashboardBanner extends StatefulWidget {
  const DecayBoosterDashboardBanner({super.key});

  @override
  State<DecayBoosterDashboardBanner> createState() =>
      _DecayBoosterDashboardBannerState();
}

class _DecayBoosterDashboardBannerState
    extends State<DecayBoosterDashboardBanner> {
  bool _loading = true;
  bool _visible = false;
  List<TrainingSpotV2> _spots = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final q = BoosterQueueService.instance.getQueue();
    if (mounted) {
      setState(() {
        _spots = q;
        _visible = q.isNotEmpty;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final spots = _spots;
    if (spots.isEmpty) return;
    await const TrainingBoosterLauncher().launch(spots);
    BoosterQueueService.instance.clear();
    if (mounted) setState(() => _visible = false);
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
                  '⚡ Восстановить забытые навыки',
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
