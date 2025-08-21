import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../services/yaml_pack_diff_service.dart';
import '../widgets/markdown_preview_dialog.dart';

class PackLibraryDiffScreen extends StatefulWidget {
  final TrainingPackTemplateV2? packA;
  final TrainingPackTemplateV2? packB;
  const PackLibraryDiffScreen({super.key, this.packA, this.packB});

  @override
  State<PackLibraryDiffScreen> createState() => _PackLibraryDiffScreenState();
}

class _PackLibraryDiffScreenState extends State<PackLibraryDiffScreen> {
  TrainingPackTemplateV2? _packA;
  TrainingPackTemplateV2? _packB;
  String? _fileA;
  String? _fileB;

  @override
  void initState() {
    super.initState();
    _packA = widget.packA;
    _packB = widget.packB;
  }

  Future<void> _pickA() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml', 'bak.yaml'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      final yaml = await File(path).readAsString();
      setState(() {
        _fileA = path;
        _packA = TrainingPackTemplateV2.fromYamlAuto(yaml);
      });
    } catch (_) {}
  }

  Future<void> _pickB() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml', 'bak.yaml'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      final yaml = await File(path).readAsString();
      setState(() {
        _fileB = path;
        _packB = TrainingPackTemplateV2.fromYamlAuto(yaml);
      });
    } catch (_) {}
  }

  Future<void> _exportMarkdown() async {
    final a = _packA;
    final b = _packB;
    if (a == null || b == null) return;
    final md = const YamlPackDiffService().generateMarkdownDiff(a, b);
    await showMarkdownPreviewDialog(context, md);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Diff Viewer'),
        actions: [
          IconButton(
            onPressed:
                _packA != null && _packB != null ? _exportMarkdown : null,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _pickA,
            child: Text(_fileA == null ? 'Select Pack A' : _fileA!),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _pickB,
            child: Text(_fileB == null ? 'Select Pack B' : _fileB!),
          ),
          const SizedBox(height: 24),
          if (_packA != null && _packB != null) ...[
            _mapDiff('Meta', _packA!.meta, _packB!.meta),
            _listDiff('Tags', _packA!.tags, _packB!.tags),
            _listDiff(
              'Spots',
              [for (final s in _packA!.spots) s.toJson()],
              [for (final s in _packB!.spots) s.toJson()],
            ),
            if (_packA!.meta['config'] != null ||
                _packB!.meta['config'] != null)
              _mapDiff(
                'Config',
                (_packA!.meta['config'] as Map?)?.cast<String, dynamic>(),
                (_packB!.meta['config'] as Map?)?.cast<String, dynamic>(),
              ),
          ],
        ],
      ),
    );
  }

  final _eq = const DeepCollectionEquality();

  Widget _mapDiff(
    String title,
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    final keys = {...?a?.keys, ...?b?.keys};
    final children = <Widget>[];
    for (final k in keys) {
      final av = a?[k];
      final bv = b?[k];
      if (_eq.equals(av, bv)) continue;
      children.add(_buildDiff(k, av, bv));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(title: Text(title), children: children);
  }

  Widget _listDiff(String title, List<dynamic>? a, List<dynamic>? b) {
    final listA = a ?? [];
    final listB = b ?? [];
    final useId = listA.every((e) => e is Map && e['id'] != null) ||
        listB.every((e) => e is Map && e['id'] != null);
    final children = <Widget>[];
    if (useId) {
      final mapA = {for (final e in listA) e['id']: e};
      final mapB = {for (final e in listB) e['id']: e};
      final ids = {...mapA.keys, ...mapB.keys};
      for (final id in ids) {
        final av = mapA[id];
        final bv = mapB[id];
        if (_eq.equals(av, bv)) continue;
        children.add(_buildDiff(id.toString(), av, bv));
      }
    } else {
      final len = math.max(listA.length, listB.length);
      for (var i = 0; i < len; i++) {
        final av = i < listA.length ? listA[i] : null;
        final bv = i < listB.length ? listB[i] : null;
        if (_eq.equals(av, bv)) continue;
        children.add(_buildDiff('#$i', av, bv));
      }
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(title: Text(title), children: children);
  }

  Widget _buildDiff(String key, dynamic a, dynamic b) {
    if (a is Map || b is Map) {
      return _mapDiff(
        key,
        a as Map<String, dynamic>?,
        b as Map<String, dynamic>?,
      );
    }
    if (a is List || b is List) {
      return _listDiff(key, a as List<dynamic>?, b as List<dynamic>?);
    }
    final type = a == null
        ? _DiffType.added
        : b == null
            ? _DiffType.removed
            : _DiffType.changed;
    final text = a == null
        ? _fmt(b)
        : b == null
            ? _fmt(a)
            : '${_fmt(a)} → ${_fmt(b)}';
    return ListTile(
      title: Text(key),
      subtitle: Text(text),
      tileColor: _color(type),
    );
  }

  String _fmt(dynamic v) {
    if (v is String) return v;
    return jsonEncode(v);
  }

  Color _color(_DiffType type) {
    switch (type) {
      case _DiffType.added:
        return Colors.green.withValues(alpha: .2);
      case _DiffType.removed:
        return Colors.red.withValues(alpha: .2);
      case _DiffType.changed:
        return Colors.amber.withValues(alpha: .2);
    }
  }
}

enum _DiffType { added, removed, changed }
