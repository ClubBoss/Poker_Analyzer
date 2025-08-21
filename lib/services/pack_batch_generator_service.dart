import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../core/error_logger.dart';
import '../core/training/generation/gpt_pack_template_generator.dart';
import '../core/training/generation/pack_yaml_config_parser.dart';
import 'pack_matrix_config.dart';
import 'tag_frequency_analyzer.dart';
import 'training_pack_index_writer.dart';

class PackBatchGeneratorService {
  const PackBatchGeneratorService({
    required this.gpt,
    PackYamlConfigParser? parser,
  }) : parser = parser ?? const PackYamlConfigParser();

  final GptPackTemplateGenerator gpt;
  final PackYamlConfigParser parser;
  static const _basePrompt = 'Создай тренировочный YAML пак';

  Future<int> generateFullLibrary([
    List<(String audience, List<String> tags)>? matrix,
  ]) async {
    matrix ??= await const PackMatrixConfig().loadMatrix();
    final dir = await getApplicationDocumentsDirectory();
    final out = Directory('${dir.path}/training_packs/library');
    await out.create(recursive: true);
    for (final f in out.listSync(recursive: true).whereType<File>()) {
      if (f.path.toLowerCase().endsWith('.yaml')) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    var success = 0;
    for (final item in matrix) {
      final audience = item.$1;
      final tags = item.$2.length > 5 ? item.$2.sublist(0, 5) : item.$2;
      final tagStr = tags.join(', ');
      final prompt =
          '$_basePrompt для audience: $audience, tags: $tagStr, формат: 10 BB турниры';
      final yaml = await gpt.generateYamlTemplate(prompt);
      if (yaml.isEmpty) {
        ErrorLogger.instance.logError(
          'Skip empty result for $audience $tagStr',
        );
        continue;
      }
      try {
        final cfg = parser.parse(yaml);
        if (cfg.requests.isEmpty) {
          ErrorLogger.instance.logError('Invalid yaml for $audience $tagStr');
          continue;
        }
        final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        final safeA = audience.replaceAll(' ', '_');
        final safeT =
            tags.isNotEmpty ? tags.first.replaceAll(' ', '_') : 'pack';
        final file = File('${out.path}/lib_${safeA}_${safeT}_$ts.yaml');
        await file.writeAsString(yaml);
        success++;
      } catch (e) {
        ErrorLogger.instance.logError('Pack gen error', e as Object?);
      }
    }
    await const TrainingPackIndexWriter().writeIndex();
    await const TagFrequencyAnalyzer().generate();
    return success;
  }
}
