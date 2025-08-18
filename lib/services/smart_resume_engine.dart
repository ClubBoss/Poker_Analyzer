import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/training_pack_storage.dart';
import '../models/resume_target.dart';
import '../models/v2/training_pack_template.dart';
import 'pinned_block_resume_strategy.dart';
import 'resume_strategy.dart';

class UnfinishedPack {
  final TrainingPackTemplate template;
  final int index;
  UnfinishedPack({required this.template, required this.index});

  int get progressPercent =>
      (((index + 1) / template.spots.length) * 100).round();
}

class SmartResumeEngine {
  SmartResumeEngine({List<ResumeStrategy>? strategies})
    : _strategies = strategies ?? [PinnedBlockResumeStrategy()];

  static final SmartResumeEngine instance = SmartResumeEngine();

  final List<ResumeStrategy> _strategies;

  Future<ResumeTarget?> getResumeTarget() async {
    for (final strategy in _strategies) {
      final target = await strategy.getResumeTarget();
      if (target != null) return target;
    }
    return null;
  }

  static const _playPrefix = 'tpl_prog_';
  static const _playTsPrefix = 'tpl_ts_';
  static const _sessionPrefix = 'ts_idx_';
  static const _sessionTsPrefix = 'ts_ts_';

  Future<int> getProgressPercent(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await TrainingPackStorage.load();
    final t = templates.firstWhere(
      (e) => e.id == templateId,
      orElse: () => TrainingPackTemplate(id: '', name: ''),
    );
    if (t.id.isEmpty) return 0;
    final idx =
        prefs.getInt('$_playPrefix$templateId') ??
        prefs.getInt('$_sessionPrefix$templateId');
    if (idx == null) return 0;
    final count = t.spots.length;
    if (count == 0) return 0;
    return (((idx + 1) / count) * 100).round().clamp(0, 100);
  }

  Future<List<UnfinishedPack>> getRecentUnfinished({int limit = 3}) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await TrainingPackStorage.load();
    final entries = <MapEntry<UnfinishedPack, int>>[];
    for (final t in templates) {
      int? idx;
      int ts = 0;
      if (prefs.containsKey('$_playPrefix${t.id}')) {
        idx = prefs.getInt('$_playPrefix${t.id}');
        ts = prefs.getInt('$_playTsPrefix${t.id}') ?? 0;
      } else if (prefs.containsKey('$_sessionPrefix${t.id}')) {
        idx = prefs.getInt('$_sessionPrefix${t.id}');
        ts = prefs.getInt('$_sessionTsPrefix${t.id}') ?? 0;
      }
      if (idx == null) continue;
      if (idx >= 3 && idx < t.spots.length - 1) {
        entries.add(MapEntry(UnfinishedPack(template: t, index: idx), ts));
      }
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries.take(limit)) e.key];
  }
}
