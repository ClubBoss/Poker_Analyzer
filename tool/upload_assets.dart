import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/upload_assets.dart <assetsDir> [--bucket=bucket-name] [--dry]');
    exit(1);
  }
  final dir = Directory(args.first);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${args.first}');
    exit(1);
  }
  String? bucket;
  var dry = false;
  for (final a in args.skip(1)) {
    if (a.startsWith('--bucket=')) {
      bucket = a.substring(9);
    } else if (a == '--dry') {
      dry = true;
    }
  }
  await Firebase.initializeApp();
  bucket ??= Firebase.app().options.storageBucket;
  if (bucket == null || bucket.isEmpty) {
    stderr.writeln('Bucket not specified');
    exit(1);
  }
  if (!bucket.startsWith('gs://')) bucket = 'gs://$bucket';
  final storage = FirebaseStorage.instanceFor(bucket: bucket);
  final manifestFile = File(p.join(dir.path, 'manifest.json'));
  if (!manifestFile.existsSync()) {
    stderr.writeln('manifest.json not found in ${dir.path}');
    exit(1);
  }
  final manifest = jsonDecode(await manifestFile.readAsString()) as List;
  final pngNames = <String>[];
  for (final item in manifest) {
    final name = (item as Map<String, dynamic>)['png'] as String?;
    if (name != null) pngNames.add(name);
  }
  final start = DateTime.now();
  var uploaded = 0;
  var skipped = 0;
  var errors = 0;
  Future<void> handle(File file, Reference ref, String name, String type) async {
    var same = false;
    try {
      final meta = await ref.getMetadata();
      if (meta.size == file.lengthSync()) same = true;
    } catch (_) {}
    if (same) {
      stdout.writeln('[SKIP] $name  (unchanged)');
      skipped++;
      return;
    }
    if (dry) {
      stdout.writeln('[OK]  $name');
      uploaded++;
      return;
    }
    try {
      final bytes = await file.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(
          cacheControl: 'public, max-age=86400',
          contentType: type,
        ),
      );
      stdout.writeln('[OK]  $name');
      uploaded++;
    } catch (_) {
      stdout.writeln('[ERROR] $name');
      errors++;
    }
  }
  for (final name in pngNames) {
    final file = File(p.join(dir.path, name));
    if (!file.existsSync()) {
      stdout.writeln('[ERROR] preview/$name  (missing)');
      errors++;
      continue;
    }
    final ref = storage.ref('preview/$name');
    await handle(file, ref, 'preview/$name', 'image/png');
  }
  await handle(
    manifestFile,
    storage.ref('manifest.json'),
    'manifest.json',
    'application/json',
  );
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Uploaded: $uploaded  |  Skipped: $skipped  |  Errors: $errors');
  stdout.writeln('Time: ${elapsed.toStringAsFixed(1)} s');
}
