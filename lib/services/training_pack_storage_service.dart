import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import '../models/training_pack_template.dart';
import '../models/game_type.dart';

class TrainingPackStorageService extends ChangeNotifier {
  static const _storageFile = 'training_packs.json';

  final List<TrainingPack> _packs = [];
  List<TrainingPack> get packs => List.unmodifiable(_packs);


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
            ..addAll(data.whereType<Map>().map((e) =>
                TrainingPack.fromJson(Map<String, dynamic>.from(e))));
        }
      } catch (_) {}
    }
    if (_packs.isEmpty) {
      try {
        final manifest =
            jsonDecode(await rootBundle.loadString('AssetManifest.json')) as Map;
        final packPaths = manifest.keys.where((e) =>
            e.startsWith('assets/training_packs/') && e.endsWith('.json'));
        for (final p in packPaths) {
          final data = jsonDecode(await rootBundle.loadString(p));
          if (data is Map<String, dynamic>) {
            _packs.add(TrainingPack.fromJson(data));
          }
        }
        await _persist();
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    final file = await _getStorageFile();
    await file.writeAsString(jsonEncode([for (final p in _packs) p.toJson()]));
  }

  Future<void> addPack(TrainingPack pack) async {
    _packs.add(pack);
    await _persist();
    notifyListeners();
  }

  Future<void> addCustomPack(TrainingPack pack) async {
    final newPack = TrainingPack(
      name: pack.name,
      description: pack.description,
      category: pack.category,
      gameType: pack.gameType,
      colorTag: pack.colorTag,
      isBuiltIn: false,
      tags: pack.tags,
      hands: pack.hands,
      spots: pack.spots,
      difficulty: pack.difficulty,
      history: const [],
    );
    _packs.add(newPack);
    await _persist();
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
    notifyListeners();
    return (removed, index);
  }

  Future<void> restorePack(TrainingPack pack, int index) async {
    final insertIndex = index.clamp(0, _packs.length);
    _packs.insert(insertIndex, pack);
    await _persist();
    notifyListeners();
  }

  Future<File?> exportPack(TrainingPack pack) async {
    if (pack.isBuiltIn) return null;
    final dir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
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
      var pack = TrainingPack.fromJson(Map<String, dynamic>.from(json));
      String base = pack.name.isEmpty ? 'Pack' : pack.name;
      String name = base;
      int idx = 2;
      while (_packs.any((p) => p.name == name)) {
        name = '$base ($idx)';
        idx++;
      }
      final imported = TrainingPack(
        name: name,
        description: pack.description,
        category: pack.category,
        gameType: pack.gameType,
        colorTag: pack.colorTag,
        isBuiltIn: false,
        tags: pack.tags,
        hands: pack.hands,
        spots: pack.spots,
        difficulty: pack.difficulty,
        history: pack.history,
      );
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
      _packs[index] = TrainingPack(
        name: trimmed,
        description: pack.description,
        category: pack.category,
        gameType: pack.gameType,
        colorTag: pack.colorTag,
        isBuiltIn: pack.isBuiltIn,
        tags: pack.tags,
        hands: pack.hands,
        spots: pack.spots,
        difficulty: pack.difficulty,
        history: pack.history,
      );
    await _persist();
    notifyListeners();
  }

  Future<void> setColorTag(TrainingPack pack, String color) async {
    final index = _packs.indexOf(pack);
    if (index == -1) return;
    _packs[index] = TrainingPack(
      name: pack.name,
      description: pack.description,
      category: pack.category,
      gameType: pack.gameType,
      colorTag: color,
      isBuiltIn: pack.isBuiltIn,
      tags: pack.tags,
      hands: pack.hands,
      spots: pack.spots,
      difficulty: pack.difficulty,
      history: pack.history,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setTags(TrainingPack pack, List<String> tags) async {
    final index = _packs.indexOf(pack);
    if (index == -1) return;
    _packs[index] = TrainingPack(
      name: pack.name,
      description: pack.description,
      category: pack.category,
      gameType: pack.gameType,
      colorTag: pack.colorTag,
      isBuiltIn: pack.isBuiltIn,
      tags: tags,
      hands: pack.hands,
      spots: pack.spots,
      difficulty: pack.difficulty,
      history: pack.history,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> clearProgress(TrainingPack pack) async {
    final index = _packs.indexOf(pack);
    if (index == -1 || pack.history.isEmpty) return;
    final history = List<TrainingSessionResult>.from(pack.history)..removeLast();
    _packs[index] = TrainingPack(
      name: pack.name,
      description: pack.description,
      category: pack.category,
      gameType: pack.gameType,
      colorTag: pack.colorTag,
      isBuiltIn: pack.isBuiltIn,
      tags: pack.tags,
      hands: pack.hands,
      spots: pack.spots,
      difficulty: pack.difficulty,
      history: history,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('training_progress_${pack.name}');
    await _persist();
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
    history.add(TrainingSessionResult(
      date: DateTime.now(),
      total: total,
      correct: solved,
    ));
    final updated = TrainingPack(
      name: pack.name,
      description: pack.description,
      category: pack.category,
      gameType: pack.gameType,
      colorTag: pack.colorTag,
      isBuiltIn: pack.isBuiltIn,
      tags: pack.tags,
      hands: pack.hands,
      spots: pack.spots,
      difficulty: pack.difficulty,
      history: history,
    );
    _packs[index] = updated;
    await _persist();
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
    notifyListeners();
  }

  Future<TrainingPack> duplicatePack(TrainingPack pack) async {
    assert(!pack.isBuiltIn);
    String base = pack.name.replaceAll(RegExp(r'(-copy\d*)+\$'), '');
    String name = '$base-copy';
    int idx = 1;
    while (_packs.any((p) => p.name == name)) {
      idx++;
      name = '$base-copy$idx';
    }
    final map = {
      ...pack.toJson(),
      'name': name,
      'isBuiltIn': false,
      'history': []
    };
    final copy = TrainingPack.fromJson(map);
    _packs.add(copy);
    await _persist();
    notifyListeners();
    return copy;
  }

  Future<TrainingPack> createPackFromTemplate(TrainingPackTemplate tpl) async {
    final ts = DateFormat('dd.MM HH:mm').format(DateTime.now());
    String base = 'Новый пак: ${tpl.name} ($ts)';
    String name = base;
    int idx = 2;
    while (_packs.any((p) => p.name == name)) {
      name = '$base ($idx)';
      idx++;
    }
    final pack = TrainingPack(
      name: name,
      description: tpl.description,
      category: tpl.category ?? 'Uncategorized',
      gameType: parseGameType(tpl.gameType),
      colorTag: tpl.defaultColor,
      tags: List.from(tpl.tags),
      hands: tpl.hands,
      spots: const [],
      difficulty: 1,
    );
    _packs.add(pack);
    await _persist();
    notifyListeners();
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
    String base = 'Новый пак: $category';
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
    );
    _packs.add(pack);
    await _persist();
    notifyListeners();
    return pack;
  }
}

extension PackProgress on TrainingPack {
  double get pctComplete =>
      (hands.isEmpty ? 0 : solved / hands.length).clamp(0, 1);
}
