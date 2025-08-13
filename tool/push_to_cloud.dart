import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/services/pack_cloud_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/push_to_cloud.dart <bundlesDir>');
    exit(1);
  }
  final dir = Directory(args.first);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${args.first}');
    exit(1);
  }
  final service = PackCloudService();
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.pka'))
      .toList();
  stdout.writeln('Uploading ${files.length} bundles…');
  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    try {
      final uploaded = await service.uploadBundle(file);
      final status = uploaded ? '[OK]' : 'SKIP';
      stdout.writeln(
          '[${i + 1}/${files.length}] ${p.basename(file.path)}  –  $status');
    } catch (_) {
      stdout.writeln(
          '[${i + 1}/${files.length}] ${p.basename(file.path)}  –  [ERROR]');
    }
  }
}
