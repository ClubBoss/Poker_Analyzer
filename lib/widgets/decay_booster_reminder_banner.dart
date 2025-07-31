import 'package:flutter/material.dart';

import '../services/decay_booster_reminder_engine.dart';
import '../services/decay_booster_training_launcher.dart';

/// Banner reminding the user to run decay boosters when skills have faded.
class DecayBoosterReminderBanner extends StatefulWidget {
  const DecayBoosterReminderBanner({super.key});

  @override
  State<DecayBoosterReminderBanner> createState() =>
      _DecayBoosterReminderBannerState();
}

class _DecayBoosterReminderBannerState
    extends State<DecayBoosterReminderBanner> {
  static bool _shown = false;

  bool _loading = true;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (_shown) {
      _loading = false;
    } else {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  Future<void> _check() async {
    final show = await DecayBoosterReminderEngine().shouldShowReminder();
    if (!mounted) return;
    setState(() {
      _visible = show;
      _loading = false;
    });
  }

  Future<void> _start() async {
    await const DecayBoosterTrainingLauncher().launch();
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
                  '⚠️ Навык начал забываться — пора повторить!',
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
              child: const Text('Запустить повторение'),
            ),
          ),
        ],
      ),
    );
  }
}

