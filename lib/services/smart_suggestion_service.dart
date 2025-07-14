import '../models/training_pack.dart';
import 'training_pack_storage_service.dart';
import 'goals_service.dart';
import 'mistake_review_pack_service.dart';

class SmartSuggestionService {
  final TrainingPackStorageService storage;
  SmartSuggestionService({required this.storage});

  List<TrainingPack> getSuggestions() {
    final now = DateTime.now();
    final list = storage.packs.toList();
    list.sort((a, b) {
      final ascore = (1 - a.pctComplete) * 100 + now.difference(a.lastAttemptDate).inDays;
      final bscore = (1 - b.pctComplete) * 100 + now.difference(b.lastAttemptDate).inDays;
      return bscore.compareTo(ascore);
    });
    return list.take(3).toList();
  }

  Map<String, List<TrainingPack>> getExtendedSuggestions(
    GoalsService goals,
    MistakeReviewPackService mistakes, {
    int limit = 20,
  }) {
    final now = DateTime.now();
    final packs = storage.packs.toList();

    List<TrainingPack> almost = [
      for (final p in packs)
        if (p.pctComplete >= 0.6 && p.pctComplete < 1) p
    ]
      ..sort((a, b) => b.pctComplete.compareTo(a.pctComplete));

    List<TrainingPack> stale = [
      for (final p in packs)
        if (now.difference(p.lastAttemptDate).inDays > 7) p
    ]
      ..sort((a, b) => a.lastAttemptDate.compareTo(b.lastAttemptDate));

    final goal = goals.currentGoal;
    List<TrainingPack> goalPacks = [];
    if (goal != null) {
      for (final p in packs) {
        if (p.hands.any(goal.isViolatedBy)) {
          goalPacks.add(p);
        }
      }
    }

    final mistakesPack = mistakes.pack;
    List<TrainingPack> mistakeList = mistakesPack == null ? [] : [mistakesPack];

    almost = almost.take(limit).toList();
    stale = stale.take(limit).toList();
    goalPacks = goalPacks.take(limit).toList();
    mistakeList = mistakeList.take(limit).toList();

    return {
      'almost': almost,
      'stale': stale,
      'goal': goalPacks,
      'mistakes': mistakeList,
    };
  }
}
