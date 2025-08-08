import 'dart:convert';
import 'dart:io';

/// Stores recent theory bundles per user to avoid repetition.
class TheoryNoveltyRegistry {
  final String path;
  TheoryNoveltyRegistry({this.path = 'autogen_cache/theory_bundles.json'});

  Future<List<Map<String, dynamic>>> _load() async {
    final file = File(path);
    if (!file.existsSync()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final data = jsonDecode(raw);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> _save(List<Map<String, dynamic>> list) async {
    final file = File(path);
    file.parent.createSync(recursive: true);
    await file.writeAsString(jsonEncode(list));
  }

  Future<void> record(String userId, List<String> tags, List<String> theoryIds) async {
    final list = await _load();
    list.add({
      'userId': userId,
      'tags': List<String>.from(tags)..sort(),
      'theoryIds': List<String>.from(theoryIds)..sort(),
      'ts': DateTime.now().toIso8601String(),
    });
    await _save(list);
  }

  Future<bool> isRecentDuplicate(
    String userId,
    List<String> tags,
    List<String> theoryIds, {
    Duration within = const Duration(hours: 72),
    double minOverlap = 0.6,
  }) async {
    final list = await _load();
    if (list.isEmpty) return false;
    final now = DateTime.now();
    final tagSet = tags.toSet();
    final idSet = theoryIds.toSet();
    for (final item in list) {
      if (item['userId'] != userId) continue;
      final ts = DateTime.tryParse(item['ts']?.toString() ?? '');
      if (ts == null || now.difference(ts) > within) continue;
      final prevTags = (item['tags'] as List).cast<String>().toSet();
      if (prevTags.length != tagSet.length || !prevTags.containsAll(tagSet)) continue;
      final prevIds = (item['theoryIds'] as List).cast<String>().toSet();
      final inter = prevIds.intersection(idSet).length;
      final union = prevIds.union(idSet).length;
      if (union == 0) continue;
      final overlap = inter / union;
      if (overlap >= minOverlap) return true;
    }
    return false;
  }
}
