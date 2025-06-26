import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/training_pack.dart';
import '../models/training_pack_template.dart';

class TrainingPackStorageService extends ChangeNotifier {
  static const _storageFile = 'training_packs.json';

  final List<TrainingPack> _packs = [];
  List<TrainingPack> get packs => List.unmodifiable(_packs);

  final List<TrainingPackTemplate> _templates = [];
  List<TrainingPackTemplate> get templates => List.unmodifiable(_templates);

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

    try {
      final manifest =
          jsonDecode(await rootBundle.loadString('AssetManifest.json')) as Map;
      final templatePaths = manifest.keys.where((e) =>
          e.startsWith('assets/training_templates/') && e.endsWith('.json'));
      _templates.clear();
      for (final p in templatePaths) {
        final data = jsonDecode(await rootBundle.loadString(p));
        if (data is Map<String, dynamic>) {
          _templates.add(TrainingPackTemplate.fromJson(data));
        }
      }
    } catch (_) {}
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
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final safeName = pack.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safeName.json');
    await file.writeAsString(jsonEncode(pack.toJson()));
    return file;
  }

  Future<TrainingPack?> importPack() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    final file = File(path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! Map<String, dynamic>) return null;
      if (!data.containsKey('name') || !data.containsKey('hands')) return null;
      var pack = TrainingPack.fromJson(Map<String, dynamic>.from(data));
      String baseName = pack.name;
      String name = baseName;
      int idx = 1;
      while (_packs.any((p) => p.name == name)) {
        name = '$baseName-copy${idx > 1 ? idx : ''}';
        idx++;
      }
      if (name != pack.name) {
        pack = TrainingPack(
          name: name,
          description: pack.description,
          category: pack.category,
          gameType: pack.gameType,
          hands: pack.hands,
          history: pack.history,
        );
      }
      _packs.add(pack);
      await _persist();
      notifyListeners();
      return pack;
    } catch (_) {
      return null;
    }
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
      isBuiltIn: pack.isBuiltIn,
      hands: pack.hands,
      history: pack.history,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> duplicatePack(TrainingPack pack) async {
    String base = pack.name;
    String name = '${base}-copy';
    int idx = 1;
    while (_packs.any((p) => p.name == name)) {
      name = '${base}-copy${idx > 1 ? idx : ''}';
      idx++;
    }
    final map = {...pack.toJson(), 'name': name, 'isBuiltIn': false};
    final copy = TrainingPack.fromJson(map);
    _packs.add(copy);
    await _persist();
    notifyListeners();
  }

  Future<void> createFromTemplate(TrainingPackTemplate template) async {
    String base = template.name;
    String name = base;
    int idx = 1;
    while (_packs.any((p) => p.name == name)) {
      name = '${base}-copy${idx > 1 ? idx : ''}';
      idx++;
    }
    final pack = TrainingPack(
      name: name,
      description: template.description,
      gameType: template.gameType,
      hands: template.hands,
    );
    _packs.add(pack);
    await _persist();
    notifyListeners();
  }
}
