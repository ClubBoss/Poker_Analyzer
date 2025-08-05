import 'dart:io';

import 'package:poker_analyzer/services/audit_log_storage_service.dart';

void main(List<String> args) async {
  final storage = AuditLogStorageService();
  String? packId;
  DateTime? from;
  DateTime? to;
  for (final arg in args) {
    if (arg.startsWith('--pack=')) {
      packId = arg.substring(7);
    } else if (arg.startsWith('--from=')) {
      from = DateTime.tryParse(arg.substring(7));
    } else if (arg.startsWith('--to=')) {
      to = DateTime.tryParse(arg.substring(5));
    }
  }
  final logs = await storage.query(packId: packId, from: from, to: to);
  if (logs.isEmpty) {
    stdout.writeln('No logs found');
    return;
  }
  for (final e in logs) {
    stdout.writeln(
        '${e.timestamp.toIso8601String()} [${e.packId}] ${e.userId}: ${e.changedFields.join(', ')}');
  }
}
