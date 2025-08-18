import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../helpers/hand_utils.dart';
import '../theme/app_colors.dart';

class YamlPackPreviewerScreen extends StatefulWidget {
  const YamlPackPreviewerScreen({super.key});

  @override
  State<YamlPackPreviewerScreen> createState() =>
      _YamlPackPreviewerScreenState();
}

class _YamlPackPreviewerScreenState extends State<YamlPackPreviewerScreen> {
  TrainingPackTemplateV2? _pack;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pick();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
    );
    if (result == null || result.files.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final path = result.files.single.path;
    if (path == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      final yaml = await File(path).readAsString();
      final map = const YamlReader().read(yaml);
      final pack = TrainingPackTemplateV2.fromJson(
        Map<String, dynamic>.from(map),
      );
      if (mounted) {
        setState(() {
          _pack = pack;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  double _avgPriority(List<TrainingPackSpot> spots) {
    if (spots.isEmpty) return 0;
    var sum = 0;
    for (final s in spots) {
      sum += s.priority;
    }
    return sum / spots.length;
  }

  Map<String, int> _posCoverage() {
    final map = <String, int>{};
    final pack = _pack;
    if (pack == null) return map;
    for (final s in pack.spots) {
      final label = s.hand.position.label;
      map[label] = (map[label] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> _handCoverage() {
    final map = <String, int>{};
    final pack = _pack;
    if (pack == null) return map;
    for (final s in pack.spots) {
      final code = handCode(s.hand.heroCards) ?? '';
      if (code.isEmpty) continue;
      map[code] = (map[code] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final pack = _pack;
    return Scaffold(
      appBar: AppBar(title: const Text('YAML Pack Preview')),
      backgroundColor: AppColors.background,
      body: _loading || pack == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    pack.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (pack.audience != null && pack.audience!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Audience: ${pack.audience}'),
                    ),
                  if (pack.goal.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Goal: ${pack.goal}'),
                    ),
                  if (pack.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(pack.description),
                    ),
                  const SizedBox(height: 12),
                  Text('Spots: ${pack.spots.length}'),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Average priority: ${_avgPriority(pack.spots).toStringAsFixed(1)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Positions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final e in _posCoverage().entries)
                        Chip(label: Text('${e.key} ${e.value}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hand types:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final e in _handCoverage().entries)
                        Chip(label: Text('${e.key} ${e.value}')),
                    ],
                  ),
                  if (pack.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final t in pack.tags) Chip(label: Text(t)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
