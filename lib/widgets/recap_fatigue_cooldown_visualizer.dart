import 'package:flutter/material.dart';

import '../services/booster_fatigue_guard.dart';
import '../services/smart_theory_recap_dismissal_memory.dart';
import '../services/theory_booster_recap_delay_manager.dart';
import '../services/smart_booster_dropoff_detector.dart';
import '../services/theory_recap_suppression_engine.dart';

/// Visualizes suppression state for theory recap attempts.
class RecapFatigueCooldownVisualizer extends StatefulWidget {
  final String lessonId;
  final List<String> tags;
  final String trigger;
  final DateTime timestamp;

  const RecapFatigueCooldownVisualizer({
    super.key,
    required this.lessonId,
    required this.tags,
    required this.trigger,
    required this.timestamp,
  });

  @override
  State<RecapFatigueCooldownVisualizer> createState() =>
      _RecapFatigueCooldownVisualizerState();
}

class _ChipInfo {
  final String emoji;
  final String label;
  final String tooltip;
  const _ChipInfo(this.emoji, this.label, this.tooltip);
}

class _RecapFatigueCooldownVisualizerState
    extends State<RecapFatigueCooldownVisualizer> {
  late Future<List<_ChipInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ChipInfo>> _load() async {
    final keys = <String>[];
    if (widget.lessonId.isNotEmpty) {
      keys.add('lesson:${widget.lessonId}');
    }
    keys.addAll(widget.tags.map((t) => 'tag:$t'));

    final fatigued = await BoosterFatigueGuard.instance.isFatigued(
      lessonId: widget.lessonId,
      trigger: widget.trigger,
    );

    bool dismissed = false;
    for (final k in keys) {
      if (await SmartTheoryRecapDismissalMemory.instance.shouldThrottle(k)) {
        dismissed = true;
        break;
      }
    }

    bool cooldown = false;
    for (final k in keys) {
      if (await TheoryBoosterRecapDelayManager.isUnderCooldown(
        k,
        const Duration(hours: 24),
      )) {
        cooldown = true;
        break;
      }
    }

    final dropoff =
        await SmartBoosterDropoffDetector.instance.isInDropoffState();

    final suppressed = await TheoryRecapSuppressionEngine.instance
        .shouldSuppress(lessonId: widget.lessonId, trigger: widget.trigger);

    final chips = <_ChipInfo>[];
    if (cooldown) {
      chips.add(
        _ChipInfo(
          '❗',
          'Cooldown',
          'Under cooldown since ${widget.timestamp.toIso8601String()}',
        ),
      );
    }
    if (fatigued) {
      chips.add(
        const _ChipInfo('💤', 'Fatigue', 'User dismissed previous prompts'),
      );
    }
    if (suppressed) {
      chips.add(
        const _ChipInfo('🚫', 'Suppressed', 'Suppressed by analytics rules'),
      );
    }
    if (dismissed) {
      chips.add(
        const _ChipInfo(
          '😒',
          'Dismissed recently',
          'Dismissed recap prompts earlier',
        ),
      );
    }
    if (dropoff) {
      chips.add(const _ChipInfo('🔇', 'Dropoff', 'User is in dropoff state'));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ChipInfo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final chips = snapshot.data ?? [];
        if (chips.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          children: [
            for (final c in chips)
              Tooltip(
                message: c.tooltip,
                child: Chip(label: Text('${c.emoji} ${c.label}')),
              ),
          ],
        );
      },
    );
  }
}
