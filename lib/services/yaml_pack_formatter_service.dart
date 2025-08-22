import 'dart:collection';
import 'package:yaml/yaml.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class YamlPackFormatterService {
  YamlPackFormatterService();

  String format(TrainingPackTemplateV2 pack) {
    final map = _packMap(pack);
    return const YamlEncoder().convert(map);
  }

  Map<String, dynamic> _packMap(TrainingPackTemplateV2 p) {
    final map = <String, dynamic>{};
    final meta = _cleanMap(p.meta);
    meta['trainingType'] = p.trainingType.name;
    if (meta.isNotEmpty) map['meta'] = meta;
    map['name'] = p.name;
    if (p.goal.trim().isNotEmpty) map['goal'] = p.goal;
    if (p.tags.isNotEmpty) {
      final tags = List<String>.from(p.tags)..sort();
      map['tags'] = tags;
    }
    final spots = p.spots.toList()
      ..sort((a, b) {
        final c = a.hand.position.name.compareTo(b.hand.position.name);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    if (spots.isNotEmpty) {
      map['spots'] = [for (final s in spots) _spotMap(s)];
    }
    if (p.id.trim().isNotEmpty) map['id'] = p.id;
    if (p.description.trim().isNotEmpty) map['description'] = p.description;
    if (p.audience != null && p.audience!.trim().isNotEmpty) {
      map['audience'] = p.audience;
    }
    if (p.category != null && p.category!.trim().isNotEmpty) {
      map['category'] = p.category;
    }
    map['trainingType'] = p.trainingType.name;
    map['spotCount'] = spots.length;
    map['created'] = p.created.toIso8601String();
    map['gameType'] = p.gameType.name;
    map['bb'] = p.bb;
    if (p.positions.isNotEmpty) map['positions'] = p.positions;
    if (p.recommended) map['recommended'] = true;
    return map;
  }

  Map<String, dynamic> _spotMap(TrainingPackSpot s) {
    final map = LinkedHashMap<String, dynamic>.from(s.toJson());
    map.removeWhere((k, v) => v == null || (v is String && v.isEmpty));
    map['hand'] = _cleanMap(s.hand.toJson());
    map.updateAll((_, v) => _cleanValue(v));
    return map;
  }

  Map<String, dynamic> _cleanMap(Map<String, dynamic> source) {
    final out = <String, dynamic>{};
    for (final e in source.entries) {
      final v = _cleanValue(e.value);
      if (v == null) continue;
      if (v is String && v.isEmpty) continue;
      if (v is List && v.isEmpty) continue;
      if (v is Map && v.isEmpty) continue;
      out[e.key] = v;
    }
    return out;
  }

  dynamic _cleanValue(dynamic v) {
    if (v is num) {
      if (v is int) return v;
      return double.parse(v.toStringAsFixed(2));
    }
    if (v is Map<String, dynamic>) return _cleanMap(v);
    if (v is List) return [for (final e in v) _cleanValue(e)];
    return v;
  }
}
