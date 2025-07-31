import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/memory_reminder.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/decay_booster_reminder_orchestrator.dart';
import '../services/decay_booster_training_launcher.dart';
import '../services/theory_booster_injection_service.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/decay_tag_retention_tracker_service.dart';
import 'broken_streak_banner.dart';
import 'theory_modal_viewer.dart';

/// Displays the highest-priority memory reminder.
class DecayBoosterReminderBanner extends StatefulWidget {
  const DecayBoosterReminderBanner({super.key});

  @override
  State<DecayBoosterReminderBanner> createState() =>
      _DecayBoosterReminderBannerState();
}

class _DecayBoosterReminderBannerState
    extends State<DecayBoosterReminderBanner> {
  MemoryReminder? _reminder;
  String? _packTitle;
  TheoryMiniLessonNode? _lesson;
  bool _loading = true;
  bool _hidden = false;
  final TheoryBoosterInjectionService _injection = TheoryBoosterInjectionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final list = await DecayBoosterReminderOrchestrator().getRankedReminders();
    MemoryReminder? r = list.isNotEmpty ? list.first : null;
    String? title;
    TheoryMiniLessonNode? lesson;
    if (r?.packId != null) {
      final tpl = await context
          .read<TrainingPackTemplateStorageService>()
          .loadById(r!.packId!);
      title = tpl?.name;
    }
    if (r?.type == MemoryReminderType.decayBooster) {
      lesson = await _injection.getLesson();
    }
    if (!mounted) return;
    setState(() {
      _reminder = r;
      _packTitle = title;
      _lesson = lesson;
      _loading = false;
    });
  }

  Future<void> _startBooster() async {
    await const DecayBoosterTrainingLauncher().launch();
    if (mounted) setState(() => _hidden = true);
  }

  void _openLesson() {
    final lesson = _lesson;
    if (lesson == null) return;
    final tag = _injection.currentTag;
    if (tag != null) {
      context
          .read<DecayTagRetentionTrackerService>()
          .markTheoryReviewed(tag);
    }
    TheoryModalViewer.show(context, lesson);
  }

  void _dismiss() {
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _hidden || _reminder == null) {
      return const SizedBox.shrink();
    }
    switch (_reminder!.type) {
      case MemoryReminderType.decayBooster:
        return _buildDecayBooster(context);
      case MemoryReminderType.brokenStreak:
        return BrokenStreakBanner(packId: _reminder!.packId);
      case MemoryReminderType.upcomingReview:
        return _buildUpcomingBanner(context);
    }
  }

  Widget _buildDecayBooster(BuildContext context) {
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
          if (_lesson != null) ...[
            Text(
              _lesson!.resolvedTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _summary(_lesson!.resolvedContent),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openLesson,
                child: const Text('Review Theory'),
              ),
            ),
            const Divider(color: Colors.white30),
          ],
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
              onPressed: _startBooster,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Запустить повторение'),
            ),
          ),
        ],
      ),
    );
  }

  String _summary(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final reg = RegExp(r'^(.+?[.!?])\s+(.+?[.!?])');
    final m = reg.firstMatch(cleaned);
    var result = m != null ? '${m.group(1)} ${m.group(2)}' : cleaned;
    if (result.length > 160) {
      result = '${result.substring(0, 157)}...';
    }
    return result;
  }

  Widget _buildUpcomingBanner(BuildContext context) {
    final title = _packTitle ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Пора обновить навык: $title',
              style: const TextStyle(
                fontSize: 16,
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
    );
  }
}

