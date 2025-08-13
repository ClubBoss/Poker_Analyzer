import 'package:flutter/material.dart';

import '../services/pinned_learning_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/smart_pinned_recommender_service.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_screen.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/pinned_learning_item.dart';
import '../services/theory_block_library_service.dart';
import '../services/theory_block_launcher.dart';

class PinnedTopPickCard extends StatelessWidget {
  const PinnedTopPickCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PinnedLearningService.instance;
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final items = service.items;
        if (items.isEmpty) return const SizedBox.shrink();
        return FutureBuilder<PinnedLearningItem?>(
          future: SmartPinnedRecommenderService().recommendNext(),
          builder: (context, snapshot) {
            final item = snapshot.data ?? items.first;
            if (item.type == 'lesson') {
              return FutureBuilder<void>(
                future: MiniLessonLibraryService.instance.loadAll(),
                builder: (context, snapshot) {
                  final lesson =
                      MiniLessonLibraryService.instance.getById(item.id);
                  if (lesson == null) return const SizedBox.shrink();
                  return _buildCard(
                    context,
                    title: lesson.title,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MiniLessonScreen(
                            lesson: lesson,
                            initialPosition: item.lastPosition,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }
            if (item.type == 'block') {
              return FutureBuilder<void>(
                future: TheoryBlockLibraryService.instance.loadAll(),
                builder: (context, snapshot) {
                  final block =
                      TheoryBlockLibraryService.instance.getById(item.id);
                  if (block == null) return const SizedBox.shrink();
                  return _buildCard(
                    context,
                    title: block.title,
                    onTap: () {
                      const TheoryBlockLauncher()
                          .launch(context: context, block: block);
                    },
                  );
                },
              );
            }
            return FutureBuilder<TrainingPackTemplateV2?>(
              future: PackLibraryService.instance.getById(item.id),
              builder: (context, snapshot) {
                final tpl = snapshot.data;
                if (tpl == null) return const SizedBox.shrink();
                return _buildCard(
                  context,
                  title: tpl.name,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackScreen(
                          pack: tpl,
                          initialPosition: item.lastPosition,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '📌 Top pick: $title',
          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
