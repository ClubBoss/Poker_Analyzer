import 'dart:math';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_index_loader.dart';

/// Provides fuzzy search over training pack titles and tags.
class PackSearchEngine {
  PackSearchEngine({List<TrainingPackTemplateV2>? library})
    : _library = library;

  final List<TrainingPackTemplateV2>? _library;

  List<TrainingPackTemplateV2> search(String query, {int limit = 5}) {
    final library = _library ?? PackLibraryIndexLoader.instance.library;
    final q = query.trim().toLowerCase();
    if (library.isEmpty) return const [];
    if (q.isEmpty) return library.take(limit).toList();

    final scored = <(TrainingPackTemplateV2, double)>[];
    for (final tpl in library) {
      final title = tpl.name.toLowerCase();
      final tagScores = [
        for (final t in tpl.tags) _similarity(q, t.toLowerCase()),
      ];
      final tagScore = tagScores.isEmpty ? 0.0 : tagScores.reduce(max);
      final score = _similarity(q, title) * 0.7 + tagScore * 0.3;
      if (score > 0) scored.add((tpl, score));
    }
    if (scored.isEmpty) return library.take(limit).toList();
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(limit)) s.$1];
  }

  double _similarity(String a, String b) {
    final ta = _trigrams(a);
    final tb = _trigrams(b);
    if (ta.isEmpty || tb.isEmpty) return 0;
    final inter = ta.intersection(tb).length.toDouble();
    final union = ta.union(tb).length.toDouble();
    return union == 0 ? 0 : inter / union;
  }

  Set<String> _trigrams(String s) {
    final clean = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final set = <String>{};
    if (clean.length <= 3) {
      if (clean.isNotEmpty) set.add(clean);
      return set;
    }
    for (var i = 0; i <= clean.length - 3; i++) {
      set.add(clean.substring(i, i + 3));
    }
    return set;
  }
}
