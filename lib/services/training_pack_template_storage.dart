import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'cloud_retry_policy.dart';
import '../utils/training_pack_yaml_codec_v2.dart';

class TrainingPackTemplateStorage {
  static const _boxName = 'training_templates';

  final TrainingPackYamlCodecV2 codec;
  final FirebaseFirestore _db;
  Box<dynamic>? _box;

  TrainingPackTemplateStorage({
    TrainingPackYamlCodecV2? codec,
    FirebaseFirestore? firestore,
  })  : codec = codec ?? const TrainingPackYamlCodecV2(),
        _db = firestore ?? FirebaseFirestore.instance;

  Future<void> _openBox() async {
    if (_box != null) return;
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  Future<void> saveLocal(TrainingPackTemplateV2 template) async {
    await _openBox();
    final yaml = codec.encode(template);
    await _box!.put(template.id, yaml);
  }

  Future<TrainingPackTemplateV2?> loadLocal(String id) async {
    await _openBox();
    final yaml = _box!.get(id);
    if (yaml is String) {
      try {
        return codec.decode(yaml);
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveRemote(TrainingPackTemplateV2 template) async {
    final yaml = codec.encode(template);
    await CloudRetryPolicy.execute<void>(() async {
      await _db.collection('trainingTemplates').doc(template.id).set({
        'yaml': yaml,
      });
    });
  }

  Future<TrainingPackTemplateV2?> loadRemote(String id) async {
    final doc = await CloudRetryPolicy.execute(
      () => _db.collection('trainingTemplates').doc(id).get(),
    );
    if (!doc.exists) return null;
    final data = doc.data();
    final yaml = data?['yaml'];
    if (yaml is String) {
      try {
        return codec.decode(yaml);
      } catch (_) {}
    }
    return null;
  }
}
