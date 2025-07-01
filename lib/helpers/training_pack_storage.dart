import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template.dart';
import '../data/seed_packs.dart';

class TrainingPackStorage {
  static const _key = 'training_pack_templates';

  static Future<List<TrainingPackTemplate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return List<TrainingPackTemplate>.from(seedPacks);
    final list = jsonDecode(raw) as List;
    if (list.isEmpty) return List<TrainingPackTemplate>.from(seedPacks);
    return [for (final m in list) TrainingPackTemplate.fromJson(m)];
  }

  static Future<void> save(List<TrainingPackTemplate> t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final x in t) x.toJson()]));
  }
}
