import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/training_pack_template.dart';

class TemplateStorageService extends ChangeNotifier {
  final List<TrainingPackTemplate> _templates = [];
  List<TrainingPackTemplate> get templates => List.unmodifiable(_templates);

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
}
