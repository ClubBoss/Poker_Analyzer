import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/training/generation/gpt_pack_template_generator.dart';
import '../core/training/generation/pack_yaml_config_parser.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/tag_service.dart';
import '../ui/tools/training_pack_yaml_previewer.dart';

class DevMenuScreen extends StatefulWidget {
  const DevMenuScreen({super.key});

  @override
  State<DevMenuScreen> createState() => _DevMenuScreenState();
}

class _DevMenuScreenState extends State<DevMenuScreen> {
  bool _loading = false;
  static const _basePrompt = 'Создай тренировочный YAML пак';
  static const _apiKey = '';
  String _audience = 'Beginner';
  final Set<String> _tags = {};

  String get _prompt {
    final tagStr = _tags.join(', ');
    return '${_basePrompt} для audience: ${_audience}, tags: ${tagStr}, формат: 10 BB турниры.';
  }

  Future<void> _selectTags() async {
    final tags = context.read<TagService>().tags.toSet();
    final local = Set<String>.from(_tags);
    final res = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: const Text('Выбор тегов'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in tags)
                      CheckboxListTile(
                        value: local.contains(t),
                        title: Text(t),
                        activeColor: Colors.greenAccent,
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v ?? false) {
                              local.add(t);
                            } else {
                              local.remove(t);
                            }
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (res != null) {
      setState(() {
        _tags
          ..clear()
          ..addAll(res);
      });
    }
  }

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _audience,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const [
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
              ],
              onChanged: (v) => setState(() => _audience = v ?? _audience),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _selectTags,
              child: Text(
                _tags.isEmpty ? 'Выбрать теги' : 'Теги: ${_tags.join(', ')}',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _createPack,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Создать тренировку (GPT)'),
            ),
          ],
        ),
      ),
    );
  }
}
