import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/gpt_pack_template_generator.dart';
import '../core/training/generation/pack_yaml_config_parser.dart';
import '../core/training/engine/training_type_engine.dart';
import '../ui/tools/training_pack_yaml_previewer.dart';

class DevMenuScreen extends StatefulWidget {
  const DevMenuScreen({super.key});

  @override
  State<DevMenuScreen> createState() => _DevMenuScreenState();
}

class _DevMenuScreenState extends State<DevMenuScreen> {
  bool _loading = false;
  static const _prompt = 'Создай тренировочный YAML пак для турниров 10 BB push/fold';
  static const _apiKey = '';

  Future<void> _createPack() async {
    setState(() => _loading = true);
    final gpt = GptPackTemplateGenerator(apiKey: _apiKey);
    final yaml = await gpt.generateYamlTemplate(_prompt);
    setState(() => _loading = false);
    if (!mounted || yaml.isEmpty) return;
    try {
      final config = const PackYamlConfigParser().parse(yaml);
      if (config.requests.isNotEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final custom = Directory('${dir.path}/training_packs/custom');
          await custom.create(recursive: true);
          final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
          final file = File('${custom.path}/pack_$ts.yaml');
          await file.writeAsString(yaml);
          if (mounted) {
            final name = file.path.split(Platform.pathSeparator).last;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Файл сохранён: $name')),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка сохранения')),
            );
          }
        }
        final tpl = await TrainingTypeEngine().build(
          TrainingType.pushfold,
          config.requests.first,
        );
        await showTrainingPackYamlPreviewer(context, tpl);
        return;
      }
    } catch (_) {}
    final ctr = TextEditingController(text: yaml);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        content: TextField(
          controller: ctr,
          readOnly: true,
          maxLines: null,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ctr.text));
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Menu')),
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: ElevatedButton(
          onPressed: _loading ? null : _createPack,
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
              : const Text('Создать тренировку (GPT)'),
        ),
      ),
    );
  }
}
