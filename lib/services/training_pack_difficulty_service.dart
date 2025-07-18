import '../models/v2/training_pack_template_v2.dart';

class TrainingPackDifficultyService {
  TrainingPackDifficultyService._();
  static final instance = TrainingPackDifficultyService._();

  final Map<int, int> _difficultyFrequency = {};

  Map<int, int> get difficultyFrequency =>
      Map.unmodifiable(_difficultyFrequency);

  List<int> get topDifficulties {
    final entries = _difficultyFrequency.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });
    return [for (final e in entries) e.key];
  }

  Future<void> load(List<TrainingPackTemplateV2> templates) async {
    _difficultyFrequency.clear();
    for (final tpl in templates) {
      final v = tpl.meta['difficulty'];
      int? diff;
      if (v is num) diff = v.toInt();
      if (v is String) diff ??= int.tryParse(v);
      if (diff == null) continue;
      _difficultyFrequency[diff] = (_difficultyFrequency[diff] ?? 0) + 1;
    }
  }
}
