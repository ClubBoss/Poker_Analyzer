import 'package:uuid/uuid.dart';

import '../models/theory_pack_model.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/theory_booster_queue_service.dart';
import 'theory_training_launcher.dart';
import 'user_action_logger.dart';

/// Builds a temporary theory pack from queued booster tags and launches it.
class TheoryBoosterTrainingLauncher {
  final TheoryBoosterQueueService queue;
  final MiniLessonLibraryService library;
  final TheoryTrainingLauncher launcher;

  TheoryBoosterTrainingLauncher({
    this.queue = TheoryBoosterQueueService.instance,
    this.library = MiniLessonLibraryService.instance,
    this.launcher = const TheoryTrainingLauncher(),
  });

  /// Builds a pack from queued tags and launches it in review mode.
  Future<void> launch() async {
    final tags = queue.getQueue();
    if (tags.isEmpty) return;

    await library.loadAll();

    final sections = <TheorySectionModel>[];
    final seen = <String>{};

    for (final tag in tags) {
      final lessons = library.findByTags([tag]);
      for (final l in lessons) {
        if (seen.add(l.id)) {
          sections.add(
            TheorySectionModel(
              title: l.resolvedTitle,
              text: l.resolvedContent,
              type: 'booster',
            ),
          );
        }
      }
    }

    if (sections.isEmpty) {
      queue.clear();
      return;
    }

    final pack = TheoryPackModel(
      id: const Uuid().v4(),
      title: 'Theory Booster Review',
      sections: sections,
      tags: const ['theoryBooster'],
    );

    await launcher.launch(pack);
    queue.clear();
    await UserActionLogger.instance.log('theory_booster_launched');
  }
}
