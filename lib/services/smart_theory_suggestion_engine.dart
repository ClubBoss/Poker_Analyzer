import 'learning_path_stage_library.dart';
import 'tag_mastery_service.dart';
import '../models/stage_type.dart';

class TheorySuggestion {
  final String tag;
  final String proposedTitle;
  final String proposedPackId;

  TheorySuggestion({
    required this.tag,
    required this.proposedTitle,
    required this.proposedPackId,
  });

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'proposedTitle': proposedTitle,
    'proposedPackId': proposedPackId,
  };

  factory TheorySuggestion.fromJson(Map<String, dynamic> j) => TheorySuggestion(
    tag: j['tag']?.toString() ?? '',
    proposedTitle: j['proposedTitle']?.toString() ?? '',
    proposedPackId: j['proposedPackId']?.toString() ?? '',
  );
}

class SmartTheorySuggestionEngine {
  final TagMasteryService mastery;

  SmartTheorySuggestionEngine({required this.mastery});

  Future<List<TheorySuggestion>> suggestMissingTheoryStages({
    double threshold = 0.3,
  }) async {
    final masteryMap = await mastery.computeMastery();
    final library = LearningPathStageLibrary.instance;

    final existingTags = <String>{};
    for (final stage in library.stages) {
      if (stage.type == StageType.theory) {
        for (final t in stage.tags) {
          final tag = t.trim().toLowerCase();
          if (tag.isNotEmpty) existingTags.add(tag);
        }
      }
    }

    final suggestions = <TheorySuggestion>[];
    for (final entry in masteryMap.entries) {
      if (entry.value >= threshold) continue;
      final tag = entry.key;
      if (existingTags.contains(tag)) continue;
      final sanitized = tag.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      suggestions.add(
        TheorySuggestion(
          tag: tag,
          proposedTitle: 'Теория: $tag',
          proposedPackId: 'theory_$sanitized',
        ),
      );
    }
    return suggestions;
  }
}
