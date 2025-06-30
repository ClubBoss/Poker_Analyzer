import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template.dart';

class TrainingPackStorage {
  static const _key = 'training_pack_templates';

  static Future<List<TrainingPackTemplate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return [for (final m in list) TrainingPackTemplate.fromJson(m)];
  }

  static Future<void> save(List<TrainingPackTemplate> t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final x in t) x.toJson()]));
  }
}
