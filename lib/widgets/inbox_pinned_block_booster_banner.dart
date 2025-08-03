import 'package:flutter/material.dart';

import '../services/smart_pinned_block_booster_provider.dart';
import '../services/pack_library_service.dart';
import '../services/theory_block_library_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../screens/v2/training_pack_play_screen.dart';
import '../screens/mini_lesson_screen.dart';

/// Banner that surfaces booster suggestions from pinned theory blocks with
/// decayed tags.
class InboxPinnedBlockBoosterBanner extends StatelessWidget {
  final List<PinnedBlockBoosterSuggestion> suggestions;

  const InboxPinnedBlockBoosterBanner({super.key, required this.suggestions});

  Future<void> _open(
    BuildContext context,
    PinnedBlockBoosterSuggestion s,
  ) async {
    if (s.action == 'resumePack' && s.packId != null) {
      final tpl = await PackLibraryService.instance.getById(s.packId!);
      if (tpl == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingPackPlayScreen(template: tpl),
        ),
      );
      return;
    }
    await TheoryBlockLibraryService.instance.loadAll();
    await MiniLessonLibraryService.instance.loadAll();
    final block = TheoryBlockLibraryService.instance.getById(s.blockId);
    final firstId = block?.nodeIds.isNotEmpty == true
        ? block!.nodeIds.first
        : null;
    if (firstId == null) return;
    final lesson = MiniLessonLibraryService.instance.getById(firstId);
    if (lesson == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Column(
      children: [
        for (final s in suggestions)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.blockTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.tag,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ActionChip(
                  label: Text(
                    s.action == 'resumePack' ? '🎯 Drill' : '📘 Review',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: accent,
                  onPressed: () => _open(context, s),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
