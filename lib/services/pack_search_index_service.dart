import '../models/v2/training_pack_template_v2.dart';

class PackSearchIndexService {
  PackSearchIndexService._();
  static final instance = PackSearchIndexService._();

  final Map<String, Set<String>> _index = <String, Set<String>>{};
  final Map<String, TrainingPackTemplateV2> _templates =
      <String, TrainingPackTemplateV2>{};

  Future<void> buildIndex(List<TrainingPackTemplateV2> templates) async {
    _index.clear();
    _templates.clear();
    for (final tpl in templates) {
      _templates[tpl.id] = tpl;
      final terms = <String>{
        ..._tokenize(tpl.name),
        ..._tokenize(tpl.description),
        ..._tokenize(tpl.goal),
        for (final t in tpl.tags) _normalize(t),
      }..removeWhere((e) => e.isEmpty);
      for (final term in terms) {
        _index.putIfAbsent(term, () => <String>{}).add(tpl.id);
      }
    }
  }

  List<TrainingPackTemplateV2> search(String query) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return <TrainingPackTemplateV2>[];
    final ids = <String>{};
    for (final t in tokens) {
      ids.addAll(_index[t] ?? const <String>{});
    }
    return [
      for (final id in ids)
        if (_templates.containsKey(id)) _templates[id]!,
    ];
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  String _normalize(String text) => text.trim().toLowerCase();
}
