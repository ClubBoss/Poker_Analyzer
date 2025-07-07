import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/error_logger.dart';

class AssetSyncService {
  AssetSyncService._();
  static final instance = AssetSyncService._();
  static const _tsKey = 'asset_sync_ts';
  static const _prefix = 'store/v1/';

  Future<void> syncIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_tsKey);
    if (ts != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <
            const Duration(hours: 24)) return;
    try {
      await _sync(prefs);
    } catch (e, st) {
      ErrorLogger.instance.logError('Asset sync failed', e, st);
    }
  }

  Future<void> _sync(SharedPreferences prefs) async {
    final storage = FirebaseStorage.instance;
    final tmp = await getTemporaryDirectory();
    final root = Directory(p.join(tmp.path, 'asset_cache'));
    await root.create(recursive: true);
    final manifestRef = storage.ref('${_prefix}manifest.json');
    final manifestBytes = await manifestRef.getData();
    if (manifestBytes == null) throw Exception('manifest empty');
    final manifestPath = p.join(root.path, 'manifest.json');
    await File(manifestPath).writeAsBytes(manifestBytes);
    final manifest = jsonDecode(utf8.decode(manifestBytes)) as List;
    for (final item in manifest) {
      final png = (item as Map<String, dynamic>)['png'] as String?;
      if (png == null) continue;
      final file = File(p.join(root.path, 'preview', png));
      if (!await file.exists()) await file.create(recursive: true);
      try {
        final data =
            await storage.ref('${_prefix}preview/$png').getData();
        if (data != null) await file.writeAsBytes(data);
      } catch (_) {}
    }
    await prefs.setInt(_tsKey, DateTime.now().millisecondsSinceEpoch);
    ErrorLogger.instance.logError('Asset sync complete');
  }
}
