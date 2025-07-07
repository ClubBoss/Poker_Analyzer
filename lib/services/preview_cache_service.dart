import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/error_logger.dart';

class PreviewCacheService {
  PreviewCacheService._();
  static final instance = PreviewCacheService._();

  Future<String?> getPreviewPath(String filename) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'asset_cache', 'preview', filename));
      if (await file.exists()) return file.path;
      final data =
          await FirebaseStorage.instance.ref('store/v1/preview/$filename').getData();
      if (data == null) return null;
      await file.create(recursive: true);
      await file.writeAsBytes(data, flush: true);
      return file.path;
    } catch (e, st) {
      ErrorLogger.instance.logError('Preview load failed: $filename', e, st);
      return null;
    }
  }
}
