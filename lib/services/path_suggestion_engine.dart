import '../models/learning_path_template_v2.dart';

class PathSuggestionEngine {
  PathSuggestionEngine();

  Future<LearningPathTemplateV2?> suggestNextPath({
    required List<LearningPathTemplateV2> allPaths,
    required Set<String> completedPathIds,
  }) async {
    final remaining = [
      for (final p in allPaths)
        if (!completedPathIds.contains(p.id)) p,
    ];
    if (remaining.isEmpty) return null;

    final preferred = [
      for (final p in remaining)
        if (_isRecommended(p)) p,
    ];
    final list = preferred.isNotEmpty ? preferred : remaining;

    list.sort(_comparePaths);
    return list.first;
  }

  bool _isRecommended(LearningPathTemplateV2 path) {
    for (final t in path.tags) {
      final tag = t.toLowerCase();
      if (tag == 'recommended' || tag == 'starter') return true;
    }
    try {
      final dynamic meta = (path as dynamic).meta;
      if (meta is Map) {
        if (meta['recommended'] == true || meta['starter'] == true) {
          return true;
        }
      }
    } catch (_) {}
    try {
      if ((path as dynamic).recommended == true) return true;
    } catch (_) {}
    try {
      if ((path as dynamic).starter == true) return true;
    } catch (_) {}
    return false;
  }

  int _comparePaths(LearningPathTemplateV2 a, LearningPathTemplateV2 b) {
    final oa = _orderOf(a);
    final ob = _orderOf(b);
    if (oa != ob) return oa.compareTo(ob);
    final da = _difficultyOf(a);
    final db = _difficultyOf(b);
    if (da != db) return da.compareTo(db);
    final ca = _createdAt(a);
    final cb = _createdAt(b);
    if (ca != null && cb != null) {
      return ca.compareTo(cb);
    } else if (ca != null) {
      return -1;
    } else if (cb != null) {
      return 1;
    }
    return a.id.compareTo(b.id);
  }

  int _orderOf(LearningPathTemplateV2 path) {
    try {
      final dynamic meta = (path as dynamic).meta;
      if (meta is Map && meta['order'] is num) {
        return (meta['order'] as num).toInt();
      }
    } catch (_) {}
    try {
      final dynamic order = (path as dynamic).order;
      if (order is num) return order.toInt();
    } catch (_) {}
    return 0;
  }

  int _difficultyOf(LearningPathTemplateV2 path) {
    try {
      final dynamic meta = (path as dynamic).meta;
      if (meta is Map && meta['difficultyLevel'] is num) {
        return (meta['difficultyLevel'] as num).toInt();
      }
    } catch (_) {}
    try {
      final dynamic diff = (path as dynamic).difficultyLevel;
      if (diff is num) return diff.toInt();
    } catch (_) {}
    return 0;
  }

  DateTime? _createdAt(LearningPathTemplateV2 path) {
    try {
      final dynamic meta = (path as dynamic).meta;
      if (meta is Map) {
        final v = meta['createdAt'];
        if (v is String) return DateTime.tryParse(v);
        if (v is DateTime) return v;
      }
    } catch (_) {}
    try {
      final dynamic created = (path as dynamic).createdAt;
      if (created is DateTime) return created;
      if (created is String) return DateTime.tryParse(created);
    } catch (_) {}
    return null;
  }
}
