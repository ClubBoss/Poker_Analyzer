import '../models/v2/training_pack_template.dart';
import 'smart_resume_engine.dart';

/// Available sort modes for training packs.
enum SortMode { progress, difficulty, recent, focus }

/// Provides custom sorting utilities for training packs.
class TrainingPackSortEngine {
  const TrainingPackSortEngine();

  static const instance = TrainingPackSortEngine();

  final Map<String, int> _progressCache = {};

  /// Preload progress percentages for the given templates using
  /// [SmartResumeEngine]. This allows synchronous sorting by progress later.
  Future<void> preloadProgress(List<TrainingPackTemplate> templates) async {
    _progressCache.clear();
    for (final t in templates) {
      _progressCache[t.id] =
          await SmartResumeEngine.instance.getProgressPercent(t.id);
    }
  }

  /// Returns a new list sorted according to [mode].
  List<TrainingPackTemplate> sort(
    List<TrainingPackTemplate> templates,
    SortMode mode,
  ) {
    final list = List<TrainingPackTemplate>.from(templates);
    switch (mode) {
      case SortMode.progress:
        list.sort((a, b) {
          final pa = _progressCache[a.id] ?? 0;
          final pb = _progressCache[b.id] ?? 0;
          final cmp = pb.compareTo(pa);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case SortMode.difficulty:
        list.sort((a, b) {
          final cmp = a.difficultyLevel.compareTo(b.difficultyLevel);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case SortMode.recent:
        list.sort((a, b) {
          final adt = a.lastTrainedAt ?? a.createdAt;
          final bdt = b.lastTrainedAt ?? b.createdAt;
          final cmp = bdt.compareTo(adt);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case SortMode.focus:
        list.sort((a, b) {
          final atag = a.focusTags.isNotEmpty ? a.focusTags.first : '';
          final btag = b.focusTags.isNotEmpty ? b.focusTags.first : '';
          final cmp = atag.compareTo(btag);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
    }
    return list;
  }
}
