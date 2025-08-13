import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/error_logger.dart';
import '../utils/asset_paths.dart';

class PreviewCacheService {
  PreviewCacheService._();
  static final instance = PreviewCacheService._();

  final _inFlight = <String, Future<String?>>{};

  Future<String?> getPreviewPath(String filename) {
    final safe = p.basename(filename);
    if (_inFlight.containsKey(safe)) return _inFlight[safe]!;
    final future = _load(safe);
    _inFlight[safe] = future.whenComplete(() => _inFlight.remove(safe));
    return future;
  }

  Future<String?> _load(String safe) async {
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn == ConnectivityResult.none) return null;
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'asset_cache', 'preview', safe));
      if (await file.exists()) return file.path;
      final data = await FirebaseStorage.instance
          .ref('${kAssetPrefix}preview/$safe')
          .getData();
      if (data == null) return null;
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data, flush: true);
      return file.path;
    } on FirebaseException catch (e, st) {
      if (e.code == 'object-not-found' || e.code == 'unknown') return null;
      ErrorLogger.instance.logError('Preview load failed: $safe', e, st);
      return null;
    } catch (e, st) {
      ErrorLogger.instance.logError('Preview load failed: $safe', e, st);
      return null;
    }
  }
}
