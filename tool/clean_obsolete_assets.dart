import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

const kPrefix = 'store/v1/';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/clean_obsolete_assets.dart <assetsDir> [--bucket=bucket-name] [--dry]',
    );
    exit(1);
  }
  final dir = Directory(args.first);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${args.first}');
    exit(1);
  }
  String? bucket;
  var dry = false;
  var verbose = false;
  for (final a in args.skip(1)) {
    if (a.startsWith('--bucket=')) {
      bucket = a.substring(9);
    } else if (a == '--dry') {
      dry = true;
    } else if (a == '--verbose') {
      verbose = true;
    }
  }
  await Firebase.initializeApp();
  bucket ??= Firebase.app().options.storageBucket;
  if (bucket == null || bucket.isEmpty) {
    stderr.writeln('Bucket not specified');
    exit(1);
  }
  bucket =
      bucket.replaceAll(RegExp(r'^gs://'), '').replaceAll(RegExp(r'/$'), '');
  final storage = FirebaseStorage.instanceFor(bucket: bucket);

  final manifestFile = File(p.join(dir.path, 'manifest.json'));
  if (!manifestFile.existsSync()) {
    stderr.writeln('manifest.json not found in ${dir.path}');
    exit(1);
  }
  final manifest = jsonDecode(await manifestFile.readAsString()) as List;
  final keep = <String>{storage.ref(p.join(kPrefix, 'manifest.json')).fullPath};
  final manifestRegex = RegExp(r'manifest.*\.json$');
  for (final item in manifest) {
    final name = (item as Map<String, dynamic>)['png'] as String?;
    if (name != null) {
      keep.add(storage.ref(p.join(kPrefix, 'preview', name)).fullPath);
    }
  }

  stdout.writeln('Fetching remote files...');
  final queue = <Reference>[storage.ref(kPrefix)];
  final remote = <Reference>[];
  while (queue.isNotEmpty) {
    final ref = queue.removeLast();
    String? token;
    do {
      final res = await ref.list(
        ListOptions(maxResults: 1000, pageToken: token),
      );
      remote.addAll(res.items);
      queue.addAll(res.prefixes);
      token = res.nextPageToken;
    } while (token != null);
  }
  final start = DateTime.now();
  var deleted = 0;
  var skipped = 0;
  var errors = 0;
  var wouldDelete = 0;
  Future<void> handle(Reference ref) async {
    final path = ref.fullPath;
    final lower = path.toLowerCase();
    final isPng = lower.endsWith('.png');
    final isJson = lower.endsWith('.json');
    final isManifest = manifestRegex.hasMatch(p.basename(lower));
    final keepIt = keep.contains(path) || isManifest;
    final shouldDelete = (isPng || isJson) && !keepIt;
    if (!shouldDelete) {
      if (verbose) stdout.writeln('[SKIP] $path');
      skipped++;
      return;
    }
    if (dry) {
      stdout.writeln('[DRY] $path');
      wouldDelete++;
      return;
    }
    try {
      await ref.delete();
      stdout.writeln('[DEL] $path');
      deleted++;
    } catch (_) {
      stdout.writeln('[ERROR] $path');
      errors++;
    }
  }

  for (var i = 0; i < remote.length; i += 8) {
    final batch = remote.skip(i).take(8).toList();
    await Future.wait(batch.map(handle));
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln(
    'Deleted: $deleted${dry ? '  |  Would delete: $wouldDelete' : ''}  |  Skipped: $skipped  |  Errors: $errors',
  );
  stdout.writeln('Time: ${elapsed.toStringAsFixed(1)} s');
  if (errors > 0) exitCode = 1;
}
