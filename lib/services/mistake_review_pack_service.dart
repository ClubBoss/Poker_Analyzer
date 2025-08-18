import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'achievements_engine.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../models/mistake_pack.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../services/template_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'saved_hand_manager_service.dart';
import 'mistake_pack_cloud_service.dart';

class MistakeReviewPackService extends ChangeNotifier {
  static const _progressKey = 'mistake_review_progress';
  static const _dateKey = 'mistake_review_date';
  static const _packsKey = 'mistake_packs';

  static TrainingPackTemplate? _latestTemplate;

  static void setLatestTemplate(TrainingPackTemplate template) {
    _latestTemplate = template;
  }

  static TrainingPackTemplate? get cachedTemplate => _latestTemplate;

  static Future<TrainingPackTemplate?> latestTemplate(
    BuildContext context,
  ) async {
    if (_latestTemplate != null) return _latestTemplate;
    final service = context.read<MistakeReviewPackService>();
    if (service.packs.isEmpty) return null;
    final templates = context.read<TemplateStorageService>().templates;
    final map = <String, TrainingPackSpot>{};
    for (final t in templates) {
      for (final s in t.spots) {
        map[s.id] = s;
      }
    }
    final spots = <TrainingPackSpot>[];
    for (final id in service.packs.first.spotIds) {
      final s = map[id];
      if (s != null) spots.add(TrainingPackSpot.fromJson(s.toJson()));
    }
    if (spots.isEmpty) return null;
    _latestTemplate = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Review Mistakes',
      createdAt: DateTime.now(),
      spots: spots,
    );
    return _latestTemplate;
  }

  final SavedHandManagerService hands;
  final MistakePackCloudService? cloud;
  Box<dynamic>? _box;

  final List<MistakePack> _packs = [];
  List<MistakePack> get packs => List.unmodifiable(_packs);

  bool hasMistakes() => _packs.isNotEmpty;

  Future<TrainingPackTemplate?> buildPack(BuildContext context) =>
      MistakeReviewPackService.latestTemplate(context);

  void _trim() {
    _packs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = <String>{};
    final result = <MistakePack>[];
    for (final p in _packs) {
      final key =
          '${p.templateId}_${(p.spotIds.toSet().toList()..sort()).join(',')}';
      if (seen.add(key)) {
        result.add(p);
        if (result.length >= 50) break;
      }
    }
    _packs
      ..clear()
      ..addAll(result);
  }

  TrainingPack? _pack;
  int _progress = 0;
  DateTime? _date;
  Timer? _timer;
  final Map<String, Set<String>> _packSpots = {};
  bool _busy = false;

  Map<String, Set<String>> get templateMistakes => _packSpots;

  TrainingPack? get pack => _pack;
  int get progress => _progress;

  MistakeReviewPackService({required this.hands, this.cloud});

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    if (!Hive.isBoxOpen('mistake_packs')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('mistake_packs');
    } else {
      _box = Hive.box('mistake_packs');
    }
    final prefs = await SharedPreferences.getInstance();
    _progress = prefs.getInt(_progressKey) ?? 0;
    final str = prefs.getString(_dateKey);
    _date = str != null ? DateTime.tryParse(str) : null;
    final list = prefs.getStringList(_packsKey) ?? [];
    _packs
      ..clear()
      ..addAll(
        list.map(
          (e) => MistakePack.fromJson(jsonDecode(e) as Map<String, dynamic>),
        ),
      );
    _packSpots.clear();
    for (final p in _packs) {
      final set = _packSpots.putIfAbsent(p.templateId, () => <String>{});
      set.addAll(p.spotIds);
    }
    _trim();
    _generate();
    _schedule();
    unawaited(syncDown());
  }

  List<SavedHand> _mistakes() {
    final list = [
      for (final h in hands.hands)
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ];
    list.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    return list.take(10).toList();
  }

  void _generate() {
    final today = DateTime.now();
    if (_pack != null && _date != null && _sameDay(_date!, today)) return;
    final hs = _mistakes();
    _pack = TrainingPack(
      name: 'Repeat Mistakes',
      description: '',
      isBuiltIn: true,
      tags: const [],
      hands: hs,
      spots: const [],
      difficulty: 1,
    );
    _date = today;
    _progress = 0;
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressKey, _progress);
    await prefs.setString(_dateKey, _date!.toIso8601String());
    await prefs.setStringList(_packsKey, [
      for (final p in _packs) jsonEncode(p.toJson()),
    ]);
  }

  Future<void> setProgress(int value) async {
    _progress = value.clamp(0, _pack?.hands.length ?? 0);
    await _save();
    notifyListeners();
    if (_progress > 0) {
      unawaited(AchievementsEngine.instance.checkAll());
    }
  }

  Future<void> addPack(
    List<String> spotIds, {
    required String templateId,
    String note = '',
  }) async {
    (_packSpots[templateId] ??= <String>{}).addAll(spotIds);
    _packs.add(
      MistakePack(templateId: templateId, spotIds: spotIds, note: note),
    );
    await _save();
    await syncUp();
    _generate();
  }

  Future<void> addSpot(
    TrainingPackTemplate template,
    TrainingPackSpot spot,
  ) async {
    await addPack([spot.id], templateId: template.id, note: template.name);
  }

  bool hasMistakes(String templateId) =>
      _packSpots[templateId]?.isNotEmpty ?? false;

  int mistakeCount(String templateId) => _packSpots[templateId]?.length ?? 0;

  Future<TrainingPackTemplate?> review(
    BuildContext context,
    String templateId,
  ) async {
    if (_busy) return null;
    _busy = true;
    final ids = _packSpots[templateId];
    if (ids == null || ids.isEmpty) {
      _busy = false;
      return null;
    }
    final tpl = context
        .read<TemplateStorageService>()
        .templates
        .firstWhereOrNull((t) => t.id == templateId);
    if (tpl == null) {
      _busy = false;
      return null;
    }
    final spots = [
      for (final s in tpl.spots)
        if (ids.contains(s.id)) TrainingPackSpot.fromJson(s.toJson()),
    ];
    if (spots.isEmpty) {
      _busy = false;
      return null;
    }
    final reviewTpl = tpl.copyWith(id: const Uuid().v4(), spots: spots);
    setLatestTemplate(reviewTpl);
    _packSpots.remove(templateId);
    _busy = false;
    return reviewTpl;
  }

  Future<void> syncDown() async {
    if (cloud == null) return;
    final remote = await cloud!.loadPacks();
    final now = DateTime.now();
    _packs
      ..clear()
      ..addAll([
        for (final p in remote)
          if (now.difference(p.createdAt).inDays <= 30) p,
      ]);
    _trim();
    await _save();
    _generate();
  }

  Future<void> syncUp() async {
    if (cloud == null) return;
    _trim();
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    for (final p in List<MistakePack>.from(_packs)) {
      if (p.createdAt.isBefore(cutoff)) {
        await cloud!.deletePack(p.id);
        _packs.remove(p);
        // cleanup orphaned cached entries
        try {
          await SharedPreferences.getInstance().then(
            (prefs) => prefs.remove('mistake_pack_${p.id}'),
          );
          if (_box != null) await _box!.delete('mistake_pack_${p.id}');
        } catch (_) {}
      }
    }
    await _save();
    for (final p in _packs) {
      await cloud!.savePack(p);
    }
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), () {
      _generate();
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
