import 'package:flutter/material.dart';
import '../models/mistake_tag.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/mistake_tag_history_service.dart';
import '../models/mistake_tag_history_entry.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/smart_theory_booster_bridge.dart';
import '../services/booster_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/theory_replay_cooldown_manager.dart';
import '../services/recall_analytics_service.dart';
import '../widgets/theory_recap_dialog.dart';
import '../services/weak_theory_review_launcher.dart';
import '../services/theory_boost_recap_linker.dart';
import '../services/theory_recap_review_tracker.dart';
import '../models/theory_recap_review_entry.dart';
import '../services/theory_prompt_dismiss_tracker.dart';
import 'package:collection/collection.dart';

/// Banner suggesting theory recap or booster after a session.
class TheoryProgressRecoveryBanner extends StatefulWidget {
  const TheoryProgressRecoveryBanner({super.key});

  @override
  State<TheoryProgressRecoveryBanner> createState() =>
      _TheoryProgressRecoveryBannerState();
}

class _TheoryProgressRecoveryBannerState
    extends State<TheoryProgressRecoveryBanner> {
  bool _loading = true;
  bool _visible = true;
  TheoryMiniLessonNode? _lesson;
  MistakeTag? _tag;
  BoosterRecommendationResult? _booster;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _load);
  }

  Future<MistakeTag?> _findWeakTag() async {
    const launcher = WeakTheoryReviewLauncher();
    final history = await MistakeTagHistoryService.getRecentHistory(limit: 100);
    if (history.isEmpty) return null;
    final packs = <String>[];
    final relevant = <MistakeTagHistoryEntry>[];
    for (final entry in history) {
      if (!packs.contains(entry.packId)) {
        packs.add(entry.packId);
        if (packs.length > launcher.sessionLimit) break;
      }
      if (packs.contains(entry.packId)) {
        relevant.add(entry);
      }
    }
    final tagCounts = <MistakeTag, int>{};
    final tagPacks = <MistakeTag, Set<String>>{};
    for (final entry in relevant) {
      for (final tag in entry.tags) {
        tagCounts.update(tag, (v) => v + 1, ifAbsent: () => 1);
        tagPacks.putIfAbsent(tag, () => <String>{}).add(entry.packId);
      }
    }
    if (tagCounts.isEmpty) return null;
    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      final tag = e.key;
      final count = e.value;
      final packCount = tagPacks[tag]?.length ?? 0;
      if (count < launcher.threshold || packCount < 2) continue;
      final key = 'weak_theory_${tag.name.toLowerCase()}';
      final under = await TheoryReplayCooldownManager.isUnderCooldown(
        key,
        cooldown: const Duration(days: 1),
      );
      if (under) continue;
      await TheoryReplayCooldownManager.markSuggested(key);
      return tag;
    }
    return null;
  }

  Future<void> _load() async {
    final tag = await _findWeakTag();
    if (tag != null) {
      _tag = tag;
      await MiniLessonLibraryService.instance.loadAll();
      final linker = const TheoryBoostRecapLinker();
      _lesson = await linker.fetchLesson(tag.name);
      _lesson ??=
          MiniLessonLibraryService.instance.findByTags([tag.name]).firstOrNull;
      if (_lesson != null) {
        if (await TheoryPromptDismissTracker.instance
            .isRecentlyDismissed(_lesson!.id)) {
          if (mounted) {
            setState(() {
              _loading = false;
              _visible = false;
            });
          }
          return;
        }
        final bridge = SmartTheoryBoosterBridge();
        final recs = await bridge.recommend([_lesson!]);
        if (recs.isNotEmpty) {
          _booster = recs.first;
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startBooster() async {
    final rec = _booster;
    final tag = _tag;
    if (rec == null || tag == null) return;
    await BoosterLibraryService.instance.loadAll();
    final tpl = BoosterLibraryService.instance.getById(rec.boosterId);
    if (tpl == null) return;
    await const TrainingSessionLauncher().launch(tpl);
    RecallAnalyticsService.instance.logPrompt(
      trigger: 'recoveryBanner',
      lessonId: _lesson?.id,
      tags: [tag.name],
      dismissed: false,
    );
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _startRecap() async {
    final tag = _tag;
    if (tag == null) return;
    await showTheoryRecapDialog(
      context,
      lessonId: _lesson?.id,
      tags: _lesson == null ? [tag.name] : null,
      trigger: 'recoveryBanner',
    );
    await TheoryRecapReviewTracker.instance.log(
      TheoryRecapReviewEntry(
        lessonId: _lesson?.id ?? '',
        trigger: 'recoveryBanner',
        timestamp: DateTime.now(),
      ),
    );
    RecallAnalyticsService.instance.logPrompt(
      trigger: 'recoveryBanner',
      lessonId: _lesson?.id,
      tags: [tag.name],
      dismissed: false,
    );
    if (mounted) setState(() => _visible = false);
  }

  void _dismiss() {
    final tag = _tag;
    if (tag != null) {
      RecallAnalyticsService.instance.logPrompt(
        trigger: 'recoveryBanner',
        lessonId: _lesson?.id,
        tags: [tag.name],
        dismissed: true,
      );
      if (_lesson != null) {
        TheoryPromptDismissTracker.instance
            .markDismissed(_lesson!.id, trigger: 'recoveryBanner');
      }
    }
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_visible || _tag == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    if (_booster != null) {
      final booster =
          BoosterLibraryService.instance.getById(_booster!.boosterId);
      final name = booster?.name ?? _booster!.boosterId;
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
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: _dismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Booster: ${_booster!.reasonTag}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _dismiss,
                  style: OutlinedButton.styleFrom(foregroundColor: accent),
                  child: const Text('Напомнить позже'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _startBooster,
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Повторить сейчас'),
                ),
              ],
            )
          ],
        ),
      );
    }

    final title = _lesson?.resolvedTitle ?? _tag!.label;
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Теория: ${_tag!.label}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _dismiss,
                style: OutlinedButton.styleFrom(foregroundColor: accent),
                child: const Text('Напомнить позже'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _startRecap,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Повторить сейчас'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
