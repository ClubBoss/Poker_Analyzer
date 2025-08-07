import '../models/session_log.dart';
import '../services/session_log_service.dart';

/// Repository for accessing training session logs.
class TrainingSessionLogRepository {
  final SessionLogService logs;
  TrainingSessionLogRepository({required this.logs});

  /// Returns logs filtered by [packId] and optional [variant] tag.
  List<SessionLog> getLogs({required String packId, String? variant}) {
    return logs.logs.where((log) {
      if (log.templateId != packId) return false;
      if (variant != null && variant.isNotEmpty && !log.tags.contains(variant)) {
        return false;
      }
      return true;
    }).toList();
  }
}
