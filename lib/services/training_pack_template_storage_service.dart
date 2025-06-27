import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack_template_model.dart';
import '../repositories/training_pack_template_repository.dart';

class TrainingPackTemplateStorageService extends ChangeNotifier {
  static const _key = 'training_pack_templates';

  final List<TrainingPackTemplateModel> _templates = [];
  List<TrainingPackTemplateModel> get templates => List.unmodifiable(_templates);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _templates
      ..clear()
      ..addAll(raw.map((e) =>
          TrainingPackTemplateModel.fromJson(jsonDecode(e) as Map<String, dynamic>)));
    if (_templates.isEmpty) {
      _templates.addAll(await TrainingPackTemplateRepository.getAll());
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      [for (final t in _templates) jsonEncode(t.toJson())],
    );
  }

  Future<void> add(TrainingPackTemplateModel model) async {
    _templates.add(model);
    await _persist();
    notifyListeners();
  }

  Future<void> update(TrainingPackTemplateModel model) async {
    final index = _templates.indexWhere((t) => t.id == model.id);
    if (index == -1) return;
    _templates[index] = model;
    await _persist();
    notifyListeners();
  }

  Future<void> remove(TrainingPackTemplateModel model) async {
    _templates.removeWhere((t) => t.id == model.id);
    await _persist();
    notifyListeners();
  }

  void merge(List<TrainingPackTemplateModel> list) {
    for (final m in list) {
      final index = _templates.indexWhere((t) => t.id == m.id);
      if (index == -1) {
        _templates.add(m);
      } else {
        _templates[index] = m;
      }
    }
  }

  Future<void> saveAll() async {
    await _persist();
    notifyListeners();
  }
}
