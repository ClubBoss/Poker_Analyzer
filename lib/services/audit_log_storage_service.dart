import 'dart:convert';
import 'dart:io';

import '../models/training_pack_audit_entry.dart';

class AuditLogStorageService {
  final File _file;

  AuditLogStorageService({String? filePath})
    : _file = File(filePath ?? 'training_pack_audit_log.json');

  Future<List<TrainingPackAuditEntry>> _readAll() async {
    if (!await _file.exists()) {
      return [];
    }
    final content = await _file.readAsString();
    if (content.trim().isEmpty) return [];
    final list = jsonDecode(content) as List;
    return list
        .map(
          (e) => TrainingPackAuditEntry.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<void> append(TrainingPackAuditEntry entry) async {
    final logs = await _readAll();
    logs.add(entry);
    final encoded = jsonEncode(logs.map((e) => e.toJson()).toList());
    await _file.writeAsString(encoded);
  }

  Future<List<TrainingPackAuditEntry>> query({
    String? packId,
    DateTime? from,
    DateTime? to,
  }) async {
    final logs = await _readAll();
    return logs.where((e) {
      if (packId != null && e.packId != packId) return false;
      if (from != null && e.timestamp.isBefore(from)) return false;
      if (to != null && e.timestamp.isAfter(to)) return false;
      return true;
    }).toList();
  }
}
