import 'training_history_service_v2.dart';

class TrainingGapDetectorService {
  const TrainingGapDetectorService();

  Future<List<String>> detectNeglectedTags({Duration maxAge = const Duration(days: 7)}) async {
    final history = await TrainingHistoryServiceV2.getHistory(limit: 200);
    final map = <String, DateTime>{};
    for (final e in history) {
      for (final t in e.tags) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        final last = map[key];
        if (last == null || e.timestamp.isAfter(last)) {
          map[key] = e.timestamp;
        }
      }
    }
    final cutoff = DateTime.now().subtract(maxAge);
    final list = <String>[];
    map.forEach((tag, ts) {
      if (ts.isBefore(cutoff)) list.add(tag);
    });
    return list;
  }

  Future<Set<String>> detectNeglectedCategories({Duration maxAge = const Duration(days: 7)}) async {
    final tags = await detectNeglectedTags(maxAge: maxAge);
    return {for (final t in tags) if (t.startsWith('cat:')) t};
  }
}
