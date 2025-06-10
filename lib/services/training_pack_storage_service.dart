import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/training_pack.dart';

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
    if (!await file.exists()) return;
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
}
