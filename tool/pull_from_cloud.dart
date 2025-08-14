import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/services/pack_cloud_service.dart';

Future<void> main(List<String> args) async {
  var outDir = './bundles';
  String? sinceArg;
  for (final a in args) {
    if (a.startsWith('--since=')) {
      sinceArg = a.substring(8);
    } else if (!a.startsWith('--')) {
      outDir = a;
    }
  }
  final since = sinceArg != null ? DateTime.tryParse(sinceArg) : null;
  if (sinceArg != null && since == null) {
    stderr.writeln('Invalid date: $sinceArg');
    exit(1);
  }
  final dir = Directory(outDir)..createSync(recursive: true);
  final service = PackCloudService();
  final docs = await service.listBundles();
  final items = <Map<String, dynamic>>[];
  for (final d in docs) {
    final tsStr =
        d['lastGenerated'] as String? ?? d['createdAt'] as String? ?? '';
    final ts = DateTime.tryParse(tsStr);
    if (since != null && (ts == null || ts.isBefore(since))) continue;
    items.add(d);
  }
  stdout.writeln('Downloading ${items.length} bundles...');
  final start = DateTime.now();
  var index = 0;
  for (final item in items) {
    index++;
    final id = item['id'] as String;
    try {
      final bytes = await service.downloadBundle(id);
      if (bytes == null) throw 'not found';
      final path = p.join(dir.path, '$id.pka');
      final file = File(path);
      if (file.existsSync() && file.lengthSync() == bytes.length) {
        stdout.writeln(
            '[$index/${items.length}] ${p.basename(path)}  -  SKIP (up-to-date)');
        continue;
      }
      file.writeAsBytesSync(bytes);
      stdout.writeln('[$index/${items.length}] ${p.basename(path)}  -  OK');
    } catch (_) {
      stdout.writeln('[$index/${items.length}] $id.pka  -  [ERROR]');
    }
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Done in ${elapsed.toStringAsFixed(1)} s');
}
