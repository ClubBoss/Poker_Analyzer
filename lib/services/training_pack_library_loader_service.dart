import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'cloud_retry_policy.dart';
import 'training_pack_template_storage.dart';

class TrainingPackLibraryLoaderService {
  TrainingPackLibraryLoaderService._({
    TrainingPackTemplateStorage? storage,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? TrainingPackTemplateStorage(firestore: firestore);

  static final instance = TrainingPackLibraryLoaderService._();

  final FirebaseFirestore _db;
  final TrainingPackTemplateStorage _storage;

  final List<TrainingPackTemplateV2> _templates = [];
  final Map<String, TrainingPackTemplateV2> _index = {};

  Future<void> preloadLibrary({int limit = 500}) async {
    if (_templates.isNotEmpty) return;

    final snap = await CloudRetryPolicy.execute(
      () => _db.collection('trainingTemplates').limit(limit).get(),
    );
    for (final doc in snap.docs) {
      final data = doc.data();
      final yaml = data['yaml'];
      if (yaml is! String) continue;
      try {
        final tpl = _storage.codec.decode(yaml);
        _templates.add(tpl);
        _index[tpl.id] = tpl;
      } catch (_) {}
    }
  }

  List<TrainingPackTemplateV2> get loadedTemplates =>
      List.unmodifiable(_templates);

  TrainingPackTemplateV2? findById(String id) => _index[id];
}
