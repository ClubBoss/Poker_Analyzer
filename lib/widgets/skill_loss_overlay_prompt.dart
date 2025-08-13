import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_insight_reminder_engine.dart';
import '../services/skill_loss_feed_engine.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';

/// Full screen modal urging the user to review fading skills.
class SkillLossOverlayPrompt extends StatefulWidget {
  const SkillLossOverlayPrompt({super.key});

  /// Displays the prompt modally.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SkillLossOverlayPrompt(),
    );
  }

  @override
  State<SkillLossOverlayPrompt> createState() => _SkillLossOverlayPromptState();
}

class _SkillLossOverlayPromptState extends State<SkillLossOverlayPrompt>
    with SingleTickerProviderStateMixin {
  late Future<SkillLossFeedItem?> _future;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<SkillLossFeedItem?> _load() async {
    final reminder = context.read<TagInsightReminderEngine>();
    final losses = await reminder.loadLosses();
    final feed = await const SkillLossFeedEngine().buildFeed(losses);
    return feed.isEmpty ? null : feed.first;
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
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: FutureBuilder<SkillLossFeedItem?>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final item = snapshot.data;
            if (item == null) {
              Navigator.pop(context);
              return const SizedBox.shrink();
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(
                            alpha: 0.5 + 0.5 * _controller.value),
                        width: 8,
                      ),
                    ),
                    child: child,
                  ),
                  child:
                      const Icon(Icons.warning, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your skills are fading',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.tag,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _review(item);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Review now'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
