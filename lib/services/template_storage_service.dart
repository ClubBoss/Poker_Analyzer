import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/training_pack_template.dart';

class TemplateStorageService extends ChangeNotifier {
  final List<TrainingPackTemplate> _templates = [];
  List<TrainingPackTemplate> get templates => List.unmodifiable(_templates);

  void addTemplate(TrainingPackTemplate template) {
    _templates.add(template);
    notifyListeners();
  }

  void removeTemplate(TrainingPackTemplate template) {
    if (template.isBuiltIn) return;
    _templates.remove(template);
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final manifest =
          jsonDecode(await rootBundle.loadString('AssetManifest.json')) as Map;
      final paths = manifest.keys.where((e) =>
          e.startsWith('assets/training_templates/') && e.endsWith('.json'));
      _templates.clear();
      for (final p in paths) {
        final data = jsonDecode(await rootBundle.loadString(p));
        if (data is Map<String, dynamic>) {
          _templates.add(TrainingPackTemplate.fromJson(data));
        }
      }
      // сортируем по type → revision ↓ → name
      _templates.sort((a, b) {
        if (a.gameType != b.gameType) return a.gameType.compareTo(b.gameType);
        final rev = b.revision.compareTo(a.revision);
        return rev == 0 ? a.name.compareTo(b.name) : rev;
      });
    } catch (_) {}
    notifyListeners();
  }

  Future<TrainingPackTemplate?> importTemplateFromFile() async {
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
      final template =
          TrainingPackTemplate.fromJson(Map<String, dynamic>.from(data));
      _templates.add(template);
      notifyListeners();
      return template;
    } catch (_) {
      return null;
    }
  }
}
