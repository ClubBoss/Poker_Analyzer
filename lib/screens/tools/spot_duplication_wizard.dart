import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/training/generation/yaml_reader.dart';
import '../../core/training/generation/yaml_writer.dart';
import '../../models/v2/hero_position.dart';
import '../../models/v2/hand_data.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/training_pack_template_v2.dart';
import '../../theme/app_colors.dart';

class SpotDuplicationWizard extends StatefulWidget {
  const SpotDuplicationWizard({super.key});

  @override
  State<SpotDuplicationWizard> createState() => _SpotDuplicationWizardState();
}

class _SpotDuplicationWizardState extends State<SpotDuplicationWizard> {
  TrainingPackTemplateV2? _pack;
  String? _filePath;
  final Map<String, bool> _selected = {};

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      final yaml = await File(path).readAsString();
      final map = const YamlReader().read(yaml);
      final pack = TrainingPackTemplateV2.fromJson(
        Map<String, dynamic>.from(map),
      );
      setState(() {
        _pack = pack;
        _filePath = path;
        _selected
          ..clear()
          ..addEntries(pack.spots.map((e) => MapEntry(e.id, false)));
      });
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка чтения файла')));
    }
  }

  void _toggle(String id, bool? v) {
    setState(() => _selected[id] = v ?? false);
  }

  Future<void> _editSpot(TrainingPackSpot spot) async {
    final tagsCtrl = TextEditingController(text: spot.tags.join(', '));
    final explCtrl = TextEditingController(text: spot.explanation ?? '');
    var pos = spot.hand.position;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Edit Spot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<HeroPosition>(
                value: pos,
                decoration: const InputDecoration(labelText: 'Position'),
                items: [
                  for (final p in kPositionOrder)
                    DropdownMenuItem(value: p, child: Text(p.label)),
                ],
                onChanged: (v) => pos = v ?? pos,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: explCtrl,
                decoration: const InputDecoration(labelText: 'Explanation'),
                maxLines: null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final tags = tagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final hand = HandData.fromJson(spot.hand.toJson())..position = pos;
      setState(() {
        final idx = _pack!.spots.indexOf(spot);
        _pack!.spots[idx] = spot.copyWith(
          tags: tags,
          explanation: explCtrl.text.trim().isEmpty
              ? null
              : explCtrl.text.trim(),
          hand: hand,
        );
      });
    }
    tagsCtrl.dispose();
    explCtrl.dispose();
  }

  Future<void> _duplicate() async {
    final pack = _pack;
    if (pack == null) return;
    final dup = TrainingPackTemplateV2.fromJson(pack.toJson());
    for (final spot in pack.spots) {
      if (_selected[spot.id] == true) {
        final copy = spot.copyWith(id: const Uuid().v4());
        dup.spots.add(copy);
      }
    }
    dup.spotCount = dup.spots.length;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save YAML',
      fileName: '${pack.id}-duplicated.yaml',
      type: FileType.custom,
      allowedExtensions: ['yaml'],
    );
    if (path == null) return;
    await const YamlWriter().write(dup.toJson(), path);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Файл сохранён')));
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final pack = _pack;
    return Scaffold(
      appBar: AppBar(title: const Text('Spot Duplication Wizard')),
      backgroundColor: AppColors.background,
      body: pack == null
          ? Center(
              child: ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Select YAML Pack'),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _filePath ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final s in pack.spots)
                        CheckboxListTile(
                          value: _selected[s.id] ?? false,
                          activeColor: Colors.greenAccent,
                          title: Text(
                            s.title.isNotEmpty ? s.title : s.hand.heroCards,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${s.hand.position.label} ${s.hand.board.join(' ')}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onChanged: (v) => _toggle(s.id, v),
                          onLongPress: () => _editSpot(s),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _selected.values.any((e) => e)
                        ? _duplicate
                        : null,
                    child: const Text('Duplicate Selected'),
                  ),
                ),
              ],
            ),
    );
  }
}
