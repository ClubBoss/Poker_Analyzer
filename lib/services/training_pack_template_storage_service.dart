import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack_template_model.dart';

class TrainingPackTemplateStorageService {
  static const _key = 'training_pack_templates';

  Future<List<TrainingPackTemplateModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return [
      for (final item in raw)
        TrainingPackTemplateModel.fromJson(
            jsonDecode(item) as Map<String, dynamic>)
    ];
  }

  Future<void> saveAll(List<TrainingPackTemplateModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      [for (final t in list) jsonEncode(t.toJson())],
    );
  }
}
