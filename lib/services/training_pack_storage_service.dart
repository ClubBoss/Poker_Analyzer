import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_log.dart';
import '../asset_manifest.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';

import '../models/training_pack.dart';
import '../models/training_pack_template.dart';
import '../models/pack_snapshot.dart';
import '../models/saved_hand.dart';

class TrainingPackStorageService extends ChangeNotifier {
  static const _storageFile = 'training_packs.json';
  static final _manifestFuture = AssetManifest.instance;

  Timer? _persistTimer;

  TrainingPackStorageService({this.cloud});

  final CloudSyncService? cloud;

  Future<void> _sync(TrainingPack pack) async {
    if (cloud != null && !pack.isBuiltIn) {
      await cloud!.queueMutation('training_packs', pack.id, pack.toJson());
      unawaited(cloud!.syncUp());
    }
  }

  final List<TrainingPack> _packs = [];
  List<TrainingPack> get packs => List.unmodifiable(_packs);

  static const _logsKey = 'session_logs_updated';
  final List<TrainingPack> _hotCache = [];
  DateTime _hotTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _hotLogs = DateTime.fromMillisecondsSinceEpoch(0);
  final List<(TrainingPack, int)> _topCache = [];
  DateTime _topTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _topLogs = DateTime.fromMillisecondsSinceEpoch(0);

  List<TrainingPack> getSortedPacks() {
    final list = List<TrainingPack>.from(_packs);
    list.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      if (c != 0) return c;
      final d = b.difficulty.compareTo(a.difficulty);
      if (d != 0) return d;
      return a.pctComplete.compareTo(b.pctComplete);
    });
    return List.unmodifiable(list);
  }

  Future<DateTime> _readLogsTime() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime.tryParse(prefs.getString(_logsKey) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> refreshHotPacks() async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    final count = <String, int>{};
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      count.update(log.templateId, (c) => c + 1, ifAbsent: () => 1);
    }
    _hotCache
      ..clear()
      ..addAll(
        [
          for (final p in _packs)
            if (count[p.id] != null) p,
        ]..sort((a, b) {
            final r = (count[b.id] ?? 0).compareTo(count[a.id] ?? 0);
            if (r != 0) return r;
            return b.lastAttemptDate.compareTo(a.lastAttemptDate);
          }),
      );
    _hotTime = DateTime.now();
    _hotLogs = await _readLogsTime();
  }

  Future<void> refreshTopPacks() async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    final count = <String, int>{};
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      if (log.mistakeCount == 0) {
        count.update(log.templateId, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    _topCache
      ..clear()
      ..addAll(
        [
          for (final p in _packs)
            if (count[p.id] != null) (p, count[p.id]!),
        ]..sort((a, b) {
            final r = b.$2.compareTo(a.$2);
            if (r != 0) return r;
            return b.$1.lastAttemptDate.compareTo(a.$1.lastAttemptDate);
          }),
      );
    _topTime = DateTime.now();
    _topLogs = await _readLogsTime();
  }

  Future<List<TrainingPack>> getHotPacks([int limit = 5]) async {
    final logsTime = await _readLogsTime();
    if (_hotCache.isEmpty ||
        logsTime.isAfter(_hotLogs) ||
        DateTime.now().difference(_hotTime) > const Duration(minutes: 10)) {
      await refreshHotPacks();
    }
    return limit < _hotCache.length ? _hotCache.sublist(0, limit) : _hotCache;
  }

  Future<List<(TrainingPack, int)>> getMostCompletedPacks([
    int limit = 10,
  ]) async {
    final logsTime = await _readLogsTime();
    if (_topCache.isEmpty ||
        logsTime.isAfter(_topLogs) ||
        DateTime.now().difference(_topTime) > const Duration(minutes: 10)) {
      await refreshTopPacks();
    }
    return limit < _topCache.length ? _topCache.sublist(0, limit) : _topCache;
  }

  Future<List<(TrainingPack, int)>> getTrendingPacks({
    Duration window = const Duration(days: 7),
  }) async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    final cutoff = DateTime.now().subtract(window);
    final count = <String, int>{};
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      if (log.completedAt.isBefore(cutoff)) continue;
      if (log.mistakeCount == 0) {
        count.update(log.templateId, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    final list = [
      for (final p in _packs)
        if (count[p.id] != null) (p, count[p.id]!),
    ]..sort((a, b) {
        final r = b.$2.compareTo(a.$2);
        if (r != 0) return r;
        return b.$1.lastAttemptDate.compareTo(a.$1.lastAttemptDate);
      });
    return list;
  }

  final Map<String, List<PackSnapshot>> _snapshots = {};
  List<PackSnapshot> snapshotsOf(TrainingPack pack) =>
      List.unmodifiable(_snapshots[pack.id] ?? const []);

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_storageFile');
  }

  Future<void> load() async {
    final file = await _getStorageFile();
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is List) {
          _packs
            ..clear()
            ..addAll(
              data.whereType<Map>().map(
                    (e) => TrainingPack.fromJson(Map<String, dynamic>.from(e)),
                  ),
            );
        } else if (data is Map) {
          final packsJson = data['packs'];
          if (packsJson is List) {
            _packs
              ..clear()
              ..addAll(
                packsJson.whereType<Map>().map(
                      (e) =>
                          TrainingPack.fromJson(Map<String, dynamic>.from(e)),
                    ),
              );
          }
          final snapsJson = data['snapshots'];
          if (snapsJson is Map) {
            _snapshots.clear();
            snapsJson.forEach((key, value) {
              if (value is List) {
                _snapshots[key] = [
                  for (final s in value.whereType<Map>())
                    PackSnapshot.fromJson(Map<String, dynamic>.from(s)),
                ];
              }
            });
          }
        }
      } catch (_) {}
    }
    if (_packs.isEmpty) {
      await loadBuiltInPacks();
    }

    await refreshHotPacks();
    await refreshTopPacks();

    notifyListeners();
  }

  Future<void> _persist() async {
    final file = await _getStorageFile();
    final data = {
      'packs': [for (final p in _packs) p.toJson()],
      if (_snapshots.isNotEmpty)
        'snapshots': {
          for (final e in _snapshots.entries)
            e.key: [for (final s in e.value) s.toJson()],
        },
    };
    await file.writeAsString(jsonEncode(data));
  }

  void _persistDebounced() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 1), () {
      unawaited(_persist());
    });
  }

  void schedulePersist() => _persistDebounced();

  Future<void> loadBuiltInPacks() async {
    try {
      final manifest = await _manifestFuture;
      final paths = manifest.keys.where(
        (e) => e.startsWith('assets/training_packs/') && e.endsWith('.json'),
      );
      for (final p in paths) {
        final data = jsonDecode(await rootBundle.loadString(p));
        if (data is Map<String, dynamic>) {
          final pack = TrainingPack.fromJson(data);
          if (_packs.every((x) => x.name != pack.name)) {
            _packs.add(pack);
          }
        }
      }
      await _persist();
      await refreshHotPacks();
      await refreshTopPacks();
    } catch (_) {}
  }

  Future<void> addPack(TrainingPack pack) async {
    _packs.add(pack);
    await _persist();
    await _sync(pack);
    notifyListeners();
  }

  Future<void> addCustomPack(TrainingPack pack) async {
    final newPack = pack.copyWith(isBuiltIn: false, history: const []);
    _packs.add(newPack);
    await _persist();
    await _sync(newPack);
    notifyListeners();
  }

  Future<void> clear() async {
    _packs.clear();
    await _persist();
    notifyListeners();
  }

  Future<(TrainingPack pack, int index)?> removePack(TrainingPack pack) async {
    if (pack.isBuiltIn) return null;
    final index = _packs.indexOf(pack);
    if (index == -1) return null;
    final removed = _packs.removeAt(index);
    await _persist();
    await _sync(removed);
    notifyListeners();
    return (removed, index);
  }

  Future<void> restorePack(TrainingPack pack, int index) async {
    final insertIndex = index.clamp(0, _packs.length);
    _packs.insert(insertIndex, pack);
    await _persist();
    await _sync(pack);
    notifyListeners();
  }

  Future<File?> exportPack(TrainingPack pack) async {
    if (pack.isBuiltIn) return null;
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final safeName = pack.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safeName.json');
    await file.writeAsString(jsonEncode(pack.toJson()));
    return file;
  }

  Future<File?> exportPackTemp(TrainingPack pack) async {
    if (pack.isBuiltIn) return null;
    final dir = await getTemporaryDirectory();
    final safeName = pack.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safeName.json');
    await file.writeAsString(jsonEncode(pack.toJson()));
    return file;
  }

  Future<String?> importPack(Uint8List data) async {
    try {
      final content = utf8.decode(data);
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) return 'Неверный формат файла';
      final pack = TrainingPack.fromJson(
        Map<String, dynamic>.from(json),
      ).copyWith(createdAt: DateTime.now());
      final String base = pack.name.isEmpty ? 'Pack' : pack.name;
      String name = base;
      int idx = 2;
      while (_packs.any((p) => p.name == name)) {
        name = '$base ($idx)';
        idx++;
      }
      final imported = pack.copyWith(name: name, isBuiltIn: false);
      _packs.add(imported);
      await _persist();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Ошибка чтения файла';
    }
  }

  Future<String?> importPackFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return 'Файл не выбран';
    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    return importPack(bytes);
  }

  Future<void> renamePack(TrainingPack pack, String newName) async {
    if (pack.isBuiltIn) return;
    final index = _packs.indexOf(pack);
    if (index == -1) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == pack.name) return;
    final updated = pack.copyWith(name: trimmed);
    _packs[index] = updated;
    await _persist();
    await _sync(updated);
    notifyListeners();
  }

  Future<void> setColorTag(TrainingPack pack, String color) async {
    final index = _packs.indexOf(pack);
    if (index == -1) return;
    final updated = pack.copyWith(colorTag: color);
    _packs[index] = updated;
    await _persist();
    await _sync(updated);
    notifyListeners();
  }

  Future<void> setTags(TrainingPack pack, List<String> tags) async {
    final index = _packs.indexOf(pack);
    if (index == -1) return;
    final updated = pack.copyWith(tags: tags);
    _packs[index] = updated;
    await _persist();
    await _sync(updated);
    notifyListeners();
  }

  Future<void> clearProgress(TrainingPack pack) async {
    final index = _packs.indexOf(pack);
    if (index == -1 || pack.history.isEmpty) return;
    final history = List<TrainingSessionResult>.from(pack.history)
      ..removeLast();
    final updated = pack.copyWith(history: history);
    _packs[index] = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('training_progress_${pack.name}');
    await _persist();
    await _sync(updated);
    notifyListeners();
  }

  Future<TrainingPack?> recordAttempt(TrainingPack pack, bool correct) async {
    if (pack.isBuiltIn) return null;
    final index = _packs.indexOf(pack);
    if (index == -1) return null;
    final history = List<TrainingSessionResult>.from(pack.history);
    final last = history.isNotEmpty ? history.last : null;
    final total = (last?.total ?? 0) + 1;
    final solved = (last?.correct ?? 0) + (correct ? 1 : 0);
    history.add(
      TrainingSessionResult(
        date: DateTime.now(),
        total: total,
        correct: solved,
      ),
    );
    final updated = pack.copyWith(history: history);
    _packs[index] = updated;
    await _persist();
    await _sync(updated);
    notifyListeners();
    return updated;
  }

  Future<void> save() async {
    await _persist();
    notifyListeners();
  }

  Future<void> updatePack(TrainingPack oldPack, TrainingPack newPack) async {
    final index = _packs.indexOf(oldPack);
    if (index == -1) return;
    _packs[index] = newPack;
    await _persist();
    await _sync(newPack);
    notifyListeners();
  }

  Future<TrainingPack> duplicatePack(TrainingPack pack) async {
    assert(!pack.isBuiltIn);
    final String base = pack.name.replaceAll(RegExp(r'\s*\(copy\d*\)\$'), '');
    String name = '$base (copy)';
    int idx = 2;
    while (_packs.any((p) => p.name == name)) {
      name = '$base (copy$idx)';
      idx++;
    }
    final map = {
      ...pack.toJson(),
      'name': name,
      'isBuiltIn': false,
      'history': [],
      'createdAt': DateTime.now().toIso8601String(),
    };
    final copy = TrainingPack.fromJson(map);
    _packs.add(copy);
    await _persist();
    await _sync(copy);
    notifyListeners();
    return copy;
  }

  Future<List<TrainingPack>> splitByTable(TrainingPack pack) async {
    final groups = <String, List<SavedHand>>{};
    for (final h in pack.hands) {
      final key = h.comment?.trim() ?? '';
      groups.putIfAbsent(key, () => []).add(h);
    }
    if (groups.length <= 1) return [pack];
    final index = _packs.indexOf(pack);
    if (index != -1) _packs.removeAt(index);
    final List<TrainingPack> result = [];
    int i = 1;
    for (final entry in groups.entries) {
      var name = pack.name;
      if (entry.key.isNotEmpty) {
        name = '$name (${entry.key})';
      } else {
        name = '$name ($i)';
      }
      final newPack = TrainingPack(
        name: name,
        description: pack.description,
        category: pack.category,
        gameType: pack.gameType,
        colorTag: pack.colorTag,
        isBuiltIn: false,
        tags: pack.tags,
        hands: entry.value,
        spots: pack.spots,
        difficulty: pack.difficulty,
        createdAt: DateTime.now(),
        history: const [],
      );
      _packs.insert(index + result.length, newPack);
      result.add(newPack);
      await _sync(newPack);
      i++;
    }
    await _persist();
    notifyListeners();
    return result;
  }

  Future<TrainingPack> createPackFromTemplate(TrainingPackTemplate tpl) async {
    final ts = DateFormat('dd.MM HH:mm').format(DateTime.now());
    final String base = 'Новый пак: ${tpl.name} ($ts)';
    String name = base;
    int idx = 2;
    while (_packs.any((p) => p.name == name)) {
      name = '$base ($idx)';
      idx++;
    }
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('pack_last_color');
    final reg = RegExp(r'^#[0-9A-Fa-f]{6}\$');
    final color = last != null && reg.hasMatch(last) ? last : tpl.defaultColor;
    final lastCat = prefs.getString('pack_last_category');
    final cat = lastCat != null && lastCat.isNotEmpty
        ? lastCat
        : tpl.category ?? 'Uncategorized';
    final pack = TrainingPack(
      name: name,
      description: tpl.description,
      category: cat,
      gameType: parseGameType(tpl.gameType),
      colorTag: color,
      tags: List.from(tpl.tags),
      hands: tpl.hands,
      spots: const [],
      difficulty: 1,
      createdAt: DateTime.now(),
    );
    _packs.add(pack);
    await save();
    await _sync(pack);
    return pack;
  }

  Future<TrainingPack> createFromTemplate(TrainingPackTemplate template) async {
    return createFromTemplateWithOptions(
      template,
      hands: template.hands,
      categoryOverride: template.category,
      colorTag: '#2196F3',
    );
  }

  Future<TrainingPack> createFromTemplateWithOptions(
    TrainingPackTemplate template, {
    List<SavedHand>? hands,
    String? categoryOverride,
    String? colorTag,
  }) async {
    final selected = hands ?? template.hands;
    final category =
        (template.category?.isNotEmpty == true ? template.category! : 'custom');
    final String base = 'Новый пак: $category';
    String name = base;
    int idx = 2;
    while (_packs.any((p) => p.name == name)) {
      name = '$base ($idx)';
      idx++;
    }
    final pack = TrainingPack(
      name: name,
      description: template.description,
      category: categoryOverride?.isNotEmpty == true
          ? categoryOverride!
          : (template.category?.isNotEmpty == true
              ? template.category!
              : 'Uncategorized'),
      gameType: parseGameType(template.gameType),
      colorTag: colorTag ?? '#2196F3',
      hands: selected,
      spots: const [],
      difficulty: 1,
      createdAt: DateTime.now(),
    );
    _packs.add(pack);
    await _persist();
    await _sync(pack);
    notifyListeners();
    return pack;
  }

  Future<TrainingPack?> restoreSnapshot(
    TrainingPack pack,
    PackSnapshot snap,
  ) async {
    final index = _packs.indexOf(pack);
    if (index == -1) return null;
    final updated = pack.copyWith(tags: snap.tags, hands: snap.hands);
    _packs[index] = updated;
    await _persist();
    await _sync(updated);
    notifyListeners();
    return updated;
  }

  Future<PackSnapshot> saveSnapshot(
    TrainingPack pack,
    List<SavedHand> hands,
    List<String> tags,
    String comment,
  ) async {
    final list = _snapshots.putIfAbsent(pack.id, () => []);
    final snapshot = PackSnapshot(
      comment: comment,
      hands: [for (final h in hands) h.copyWith()],
      tags: List.from(tags),
      orderHash: calcOrderHash(hands),
    );
    list.add(snapshot);
    await _persist();
    notifyListeners();
    return snapshot;
  }

  Future<void> deleteSnapshot(TrainingPack pack, PackSnapshot snap) async {
    final list = _snapshots[pack.id];
    if (list == null) return;
    list.removeWhere((e) => e.id == snap.id);
    await _persist();
    notifyListeners();
  }

  Future<void> renameSnapshot(
    TrainingPack pack,
    PackSnapshot snap,
    String comment,
  ) async {
    final list = _snapshots[pack.id];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == snap.id);
    if (idx == -1) return;
    list[idx] = PackSnapshot(
      id: snap.id,
      comment: comment,
      date: snap.date,
      hands: snap.hands,
      tags: snap.tags,
      orderHash: snap.orderHash,
    );
    await _persist();
    notifyListeners();
  }

  TrainingPack applyDiff(
    TrainingPack pack, {
    List<SavedHand> added = const [],
    List<SavedHand> removed = const [],
    List<SavedHand> modified = const [],
  }) {
    final index = _packs.indexOf(pack);
    if (index == -1) return pack;
    final prev = _packs[index];
    final mods = {
      for (final h in modified) h.savedAt.millisecondsSinceEpoch: h,
    };
    final updatedHands = <SavedHand>[];
    for (final h in prev.hands) {
      if (removed.any((r) => r.savedAt == h.savedAt)) continue;
      updatedHands.add(mods[h.savedAt.millisecondsSinceEpoch] ?? h);
    }
    updatedHands.addAll(added);
    final updated = prev.copyWith(hands: updatedHands);
    _packs[index] = updated;
    notifyListeners();
    return prev;
  }

  void merge(List<TrainingPack> list) {
    for (final p in list) {
      final index = _packs.indexWhere((e) => e.id == p.id);
      if (index == -1) {
        _packs.add(p);
      } else {
        _packs[index] = p;
      }
    }
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    super.dispose();
  }
}

extension PackProgress on TrainingPack {
  double get pctComplete =>
      (hands.isEmpty ? 0 : solved / hands.length).clamp(0, 1).toDouble();
}

int calcOrderHash(List<SavedHand> hands) {
  return hands
      .map((e) => e.savedAt.millisecondsSinceEpoch)
      .fold(0, (a, b) => a * 31 + b.hashCode);
}
