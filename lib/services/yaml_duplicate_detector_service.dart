import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../models/duplicate_group.dart';
import '../models/v2/training_pack_template_v2.dart';

class YamlDuplicateDetectorService {
  const YamlDuplicateDetectorService();

  List<DuplicateGroup> detectDuplicates(List<TrainingPackTemplateV2> packs) {
    final nameMap = <String, List<TrainingPackTemplateV2>>{};
    final idMap = <String, List<TrainingPackTemplateV2>>{};
    final hashMap = <String, List<TrainingPackTemplateV2>>{};
    for (final p in packs) {
      nameMap.putIfAbsent(p.name, () => []).add(p);
      idMap.putIfAbsent(p.id, () => []).add(p);
      final hash = md5.convert(utf8.encode(p.toYaml())).toString();
      hashMap.putIfAbsent(hash, () => []).add(p);
    }
    final groups = <DuplicateGroup>[];
    void add(Map<String, List<TrainingPackTemplateV2>> map, String type) {
      map.forEach((k, v) {
        if (v.length > 1) {
          groups.add(DuplicateGroup(type: type, key: k, matches: v));
        }
      });
    }

    add(nameMap, 'name');
    add(idMap, 'id');
    add(hashMap, 'hash');
    return groups;
  }
}
