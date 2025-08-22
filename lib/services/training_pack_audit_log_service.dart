import 'package:collection/collection.dart';

import '../models/training_pack_model.dart';
import '../models/training_pack_audit_entry.dart';
import 'audit_log_storage_service.dart';

class TrainingPackAuditLogService {
  final AuditLogStorageService _storage;

  TrainingPackAuditLogService({AuditLogStorageService? storage})
    : _storage = storage ?? AuditLogStorageService();

  Future<void> recordChange(
    TrainingPackModel oldPack,
    TrainingPackModel newPack, {
    String userId = 'unknown',
    DateTime? timestamp,
  }) async {
    final changedFields = <String>[];
    final diff = <String, dynamic>{};
    if (oldPack.title != newPack.title) {
      changedFields.add('title');
      diff['title'] = {'old': oldPack.title, 'new': newPack.title};
    }
    if (!_listEquals(oldPack.tags, newPack.tags)) {
      changedFields.add('tags');
      diff['tags'] = {'old': oldPack.tags, 'new': newPack.tags};
    }
    if (!_spotsEquals(oldPack.spots, newPack.spots)) {
      changedFields.add('spots');
      diff['spots'] = {
        'oldCount': oldPack.spots.length,
        'newCount': newPack.spots.length,
      };
    }
    if (!_mapEquals(oldPack.metadata, newPack.metadata)) {
      changedFields.add('metadata');
      diff['metadata'] = {'old': oldPack.metadata, 'new': newPack.metadata};
    }
    if (changedFields.isEmpty) {
      return;
    }
    final entry = TrainingPackAuditEntry(
      packId: newPack.id,
      timestamp: timestamp ?? DateTime.now(),
      userId: userId,
      changedFields: changedFields,
      diffSnapshot: diff,
    );
    await _storage.append(entry);
  }

  Future<List<TrainingPackAuditEntry>> getLogs({
    String? packId,
    DateTime? from,
    DateTime? to,
  }) async {
    return _storage.query(packId: packId, from: from, to: to);
  }

  bool _listEquals(List a, List b) =>
      DeepCollectionEquality().equals(a, b);

  bool _mapEquals(Map a, Map b) => const DeepCollectionEquality().equals(a, b);

  bool _spotsEquals(List a, List b) {
    final convert = const DeepCollectionEquality().equals;
    final oldYaml = a.map((s) => s.toYaml()).toList();
    final newYaml = b.map((s) => s.toYaml()).toList();
    return convert(oldYaml, newYaml);
  }
}
