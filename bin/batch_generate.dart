import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:poker_ai_analyzer/core/error_logger.dart';
import 'package:poker_ai_analyzer/models/v2/training_pack_preset.dart';
import 'package:poker_ai_analyzer/services/pack_generator_service.dart';

Future<void> main(List<String> args) async {
  String? src;
  String out = '.';
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--src' && i + 1 < args.length) {
      src = args[++i];
    } else if (a == '--out' && i + 1 < args.length) {
      out = args[++i];
    }
  }
  if (src == null) {
    ErrorLogger.instance.logError('Missing --src');
    exit(1);
  }
  final file = File(src);
  if (!file.existsSync()) {
    ErrorLogger.instance.logError('File not found: ${file.path}');
    exit(1);
  }
  final data = jsonDecode(await file.readAsString());
  if (data is! List) {
    ErrorLogger.instance.logError('Invalid presets file');
    exit(1);
  }
  await Directory(out).create(recursive: true);
  for (final item in data.whereType<Map>()) {
    final preset = TrainingPackPreset.fromJson(Map<String, dynamic>.from(item));
    final tpl = await PackGeneratorService.generatePackFromPreset(preset);
    final path = p.join(out, '${preset.id}.json');
    await File(path).writeAsString(jsonEncode(tpl.toJson()));
    ErrorLogger.instance.logError('Generated ${preset.id}');
  }
}
