import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    await CloudRetryPolicy.execute(
      () => doc.set({
        'name': tpl.name,
        'description': tpl.description,
        'spots': tpl.spots.length,
        'evCovered': tpl.evCovered,
        'icmCovered': tpl.icmCovered,
        'createdAt': tpl.createdAt.toIso8601String(),
        if (tpl.lastGeneratedAt != null)
          'lastGenerated': tpl.lastGeneratedAt!.toIso8601String(),
        'bundle': bytes,
      }),
    );
    return true;
  }

  Future<List<Map<String, dynamic>>> listBundles() async {
    final snap = await CloudRetryPolicy.execute(
      () => _db.collection('bundles').get(),
    );
    return [
      for (final d in snap.docs) {...d.data(), 'id': d.id},
    ];
  }

  Future<Uint8List?> downloadBundle(String id) async {
    final doc = await CloudRetryPolicy.execute(
      () => _db.collection('bundles').doc(id).get(),
    );
    if (!doc.exists) return null;
    final data = doc.data();
    final bytes = data?['bundle'];
    if (bytes is Uint8List) return bytes;
    if (bytes is List<int>) return Uint8List.fromList(bytes);
    return null;
  }
}
