import 'dart:convert';
import 'dart:io';

import '../models/training_spot.dart';
import 'training_spot_storage_service.dart';
import 'error_logger_service.dart';

class TrainingHistoryImportService {
  TrainingHistoryImportService({TrainingSpotStorageService? storage})
    : _storage = storage ?? TrainingSpotStorageService();

  final TrainingSpotStorageService _storage;

  Future<int> importFromJson(File file) async {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! List) return 0;
      int count = 0;
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          if (!item.containsKey('playerCards') ||
              !item.containsKey('actions') ||
              !item.containsKey('heroIndex')) {
            continue;
          }
          try {
            final spot = TrainingSpot.fromJson(Map<String, dynamic>.from(item));
            await _storage.addSpot(spot);
            count++;
          } catch (e, st) {
            ErrorLoggerService.instance.logError(
              'History spot import failed',
              e,
              st,
            );
          }
        }
      }
      return count;
    } catch (e, st) {
      ErrorLoggerService.instance.logError('History import failed', e, st);
      return 0;
    }
  }
}
