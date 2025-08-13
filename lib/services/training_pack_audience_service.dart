import '../models/v2/training_pack_template_v2.dart';

class TrainingPackAudienceService {
  TrainingPackAudienceService._();
  static final instance = TrainingPackAudienceService._();

  final Map<String, int> _audienceFrequency = {};

  Map<String, int> get audienceFrequency =>
      Map.unmodifiable(_audienceFrequency);

  List<String> get topAudiences {
    final entries = _audienceFrequency.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });
    return [for (final e in entries.take(7)) e.key];
  }

  Future<void> load(List<TrainingPackTemplateV2> templates) async {
    _audienceFrequency.clear();
    for (final tpl in templates) {
      final aud = tpl.audience ?? tpl.meta['audience']?.toString();
      if (aud == null) continue;
      final a = aud.trim();
      if (a.isEmpty) continue;
      _audienceFrequency[a] = (_audienceFrequency[a] ?? 0) + 1;
    }
  }
}
