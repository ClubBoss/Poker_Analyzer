import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../app_config.dart';
import 'dev_console_log_service.dart';
import '../utils/app_logger.dart';

class YamlPackArchiveAutoCleanerService {
  YamlPackArchiveAutoCleanerService();

  Future<void> clean({int maxAgeDays = 60}) async {
    if (!kDebugMode && !appConfig.archiveAutoClean) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory(p.join(docs.path, 'training_packs', 'archive'));
      if (!await root.exists()) return;
      final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
      var deleted = 0;
      for (final entity in root.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.bak.yaml')) {
          final stat = entity.statSync();
          if (stat.modified.isBefore(cutoff)) {
            try {
              entity.deleteSync();
              deleted++;
            } catch (_) {}
          }
        }
      }
      if (deleted > 0) {
        final msg = 'Archive auto-clean removed $deleted files';
        AppLogger.log(msg);
        DevConsoleLogService.instance.log(msg);
      }
    } catch (e, stack) {
      AppLogger.error('Archive auto-clean failed', e, stack);
    }
  }
}
