import 'package:flutter/material.dart';

import '../services/tag_decay_forecast_service.dart';
import '../services/decay_spot_booster_engine.dart';
import '../services/decay_booster_training_launcher.dart';

/// Banner suggesting a quick booster for the most decayed tag.
class DecayBoosterShortcutBanner extends StatefulWidget {
  const DecayBoosterShortcutBanner({super.key});

  @override
  State<DecayBoosterShortcutBanner> createState() =>
      _DecayBoosterShortcutBannerState();
}

class _DecayBoosterShortcutBannerState
    extends State<DecayBoosterShortcutBanner> {
  bool _loading = true;
  String? _tag;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final tags = await const TagDecayForecastService().getCriticalTags();
    if (!mounted) return;
    setState(() {
      _tag = tags.isNotEmpty ? tags.first : null;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final tag = _tag;
    if (tag == null) return;
    await DecaySpotBoosterEngine().enqueueForTag(tag);
    await const DecayBoosterTrainingLauncher().launch();
    if (mounted) setState(() => _hidden = true);
  }

  void _dismiss() {
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _hidden || _tag == null) {
      return const SizedBox.shrink();
    }
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
              const Text('🧠', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ты теряешь знания по теме: $_tag',
                  style: const TextStyle(
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
              child: const Text('Повторить'),
            ),
          ),
        ],
      ),
    );
  }
}

