import '../models/v2/training_pack_template_v2.dart';

class SmartTagSuggestor {
  SmartTagSuggestor();

  static const Map<String, List<String>> _keywords = {
    'sb vs bb': [
      'sb vs bb',
      'blind battle',
      'sb vs bb',
      'sb vs bb battle',
      'blind vs blind',
    ],
    'icm': ['icm', 'bubble', 'payout'],
    'limp pot': ['limp pot', 'limped pot', 'limp', 'limped'],
  };

  List<(String, double)> suggestTags(
    TrainingPackTemplateV2 pack, {
    int max = 5,
  }) {
    final nameText = '${pack.name} ${pack.description}'.toLowerCase();
    final spotText = [
      for (final s in pack.spots) s.explanation?.toLowerCase() ?? '',
    ].join(' ');

    final scores = <String, double>{};
    for (final entry in _keywords.entries) {
      var score = 0.0;
      for (final kw in entry.value) {
        final c1 = _count(nameText, kw);
        final c2 = _count(spotText, kw);
        score += c1 * 2 + c2;
      }
      if (score > 0) scores[entry.key] = score;
    }

    final list = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in list.take(max)) (e.key, e.value)];
  }

  int _count(String text, String term) {
    final re = RegExp(RegExp.escape(term), caseSensitive: false);
    return re.allMatches(text).length;
  }
}
