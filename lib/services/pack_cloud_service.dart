import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/v2/training_pack_template.dart';
import 'cloud_retry_policy.dart';

class PackCloudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> uploadBundle(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final tplFile = archive.files.firstWhere((e) => e.name == 'template.json');
    final map =
        jsonDecode(utf8.decode(tplFile.content)) as Map<String, dynamic>;
    final tpl = TrainingPackTemplate.fromJson(map);
    final doc = _db.collection('bundles').doc(tpl.id);
    final exists = await doc.get().then((d) => d.exists);
    if (exists) return false;
    await CloudRetryPolicy.execute(() => doc.set({
          'name': tpl.name,
          'description': tpl.description,
          'spots': tpl.spots.length,
          'evCovered': tpl.evCovered,
          'icmCovered': tpl.icmCovered,
          'createdAt': tpl.createdAt.toIso8601String(),
          if (tpl.lastGeneratedAt != null)
            'lastGenerated': tpl.lastGeneratedAt!.toIso8601String(),
          'bundle': bytes,
        }));
    return true;
  }
}
