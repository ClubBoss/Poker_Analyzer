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
  static const kSyncInterval = Duration(hours: 24);

  Future<void> syncIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_tsKey);
    if (ts != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <
            kSyncInterval) return;
    try {
      await _sync(prefs);
    } catch (e, st) {
      ErrorLogger.instance.logError('Asset sync failed', e, st);
    }
  }

  Future<void> _sync(SharedPreferences prefs) async {
    final storage = FirebaseStorage.instance;
    final dir = await getApplicationSupportDirectory();
    final root = Directory(p.join(dir.path, 'asset_cache'));
    await root.create(recursive: true);
    final manifestRef = storage.ref('${_prefix}manifest.json');
    final manifestBytes = await manifestRef.getData();
    if (manifestBytes == null) throw Exception('manifest empty');
    final manifestPath = p.join(root.path, 'manifest.json');
    await File(manifestPath).writeAsBytes(manifestBytes);
    List manifest;
    try {
      manifest = jsonDecode(utf8.decode(manifestBytes)) as List;
    } on FormatException catch (e, st) {
      ErrorLogger.instance.logError('Asset manifest parse failed', e, st);
      return;
    }
    final previews = <String>{};
    for (final item in manifest) {
      final png = (item as Map<String, dynamic>)['png'] as String?;
      if (png != null) previews.add(png);
    }
    final previewDir = Directory(p.join(root.path, 'preview'));
    await previewDir.create(recursive: true);
    if (await previewDir.exists()) {
      for (final f in previewDir.listSync().whereType<File>()) {
        if (!previews.contains(p.basename(f.path))) await f.delete();
      }
    }
    final toDownload = <String>[];
    for (final png in previews) {
      final file = File(p.join(previewDir.path, png));
      if (!await file.exists()) toDownload.add(png);
    }
    for (var i = 0; i < toDownload.length; i += 8) {
      final batch = toDownload.skip(i).take(8);
      await Future.wait(batch.map((png) async {
        final data =
            await storage.ref('${_prefix}preview/$png').getData();
        if (data != null) {
          final file = File(p.join(previewDir.path, png));
          await file.writeAsBytes(data, flush: true);
        }
      }));
    }
    await prefs.setInt(_tsKey, DateTime.now().millisecondsSinceEpoch);
    print('Asset sync complete');
  }
}
