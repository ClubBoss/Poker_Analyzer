import '../models/v2/training_pack_template_v2.dart';

class TrainingPackTagsService {
  TrainingPackTagsService._();
  static final instance = TrainingPackTagsService._();

  final Map<String, int> _tagFrequency = {};

  Map<String, int> get tagFrequency => Map.unmodifiable(_tagFrequency);

  List<String> get topTags {
    final entries = _tagFrequency.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });
    return [for (final e in entries.take(20)) e.key];
  }

  Future<void> load(List<TrainingPackTemplateV2> templates) async {
    _tagFrequency.clear();
    for (final tpl in templates) {
      for (final t in tpl.tags) {
        final tag = t.trim();
        if (tag.isEmpty) continue;
        _tagFrequency[tag] = (_tagFrequency[tag] ?? 0) + 1;
      }
    }
  }
}
