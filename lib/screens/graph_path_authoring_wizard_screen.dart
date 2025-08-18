import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../core/training/generation/yaml_reader.dart';
import '../services/graph_template_library.dart';
import '../services/graph_template_exporter.dart';
import '../services/graph_path_template_parser.dart';
import '../models/learning_path_node.dart';
import '../services/learning_path_validator.dart';
import '../theme/app_colors.dart';
import '../ui/tools/path_map_visualizer.dart';

class GraphPathAuthoringWizardScreen extends StatefulWidget {
  final String? initialTemplateId;
  const GraphPathAuthoringWizardScreen({super.key, this.initialTemplateId});

  @override
  State<GraphPathAuthoringWizardScreen> createState() => _GraphPathAuthoringWizardScreenState();
}

class _GraphPathAuthoringWizardScreenState extends State<GraphPathAuthoringWizardScreen> {
  int _step = 0;
  String? _templateId;
  final List<Map<String, dynamic>> _rawNodes = [];
  final List<LearningPathNode> _nodes = [];
  final List<String> _validationErrors = [];
  String _yaml = '';
  final _parser = GraphPathTemplateParser();

  @override
  void initState() {
    super.initState();
    final id = widget.initialTemplateId;
    if (id != null) {
      Future.microtask(() async {
        await _loadTemplate(id);
        if (mounted) {
          setState(() => _step = 1);
        }
      });
    }
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _loadTemplate(String id) async {
    final yaml = GraphTemplateLibrary.instance.getTemplate(id);
    if (yaml.isEmpty) return;
    final map = const YamlReader().read(yaml);
    final nodes = (map['nodes'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    setState(() {
      _templateId = id;
      _rawNodes
        ..clear()
        ..addAll(nodes);
    });
    await _rebuild();
  }

  Future<void> _rebuild() async {
    final yaml = const YamlEncoder().convert({'nodes': _rawNodes});
    final nodes = await _parser.parseFromYaml(yaml);
    final errors = LearningPathValidator.validate(nodes);
    setState(() {
      _yaml = yaml;
      _nodes
        ..clear()
        ..addAll(nodes);
      _validationErrors
        ..clear()
        ..addAll(errors);
    });
  }

  List<String> _splitList(String text) {
    return [for (final s in text.split(',')) if (s.trim().isNotEmpty) s.trim()];
  }

  Map<String, String> _parseBranches(String text) {
    final map = <String, String>{};
    for (final line in text.split('\n')) {
      final parts = line.split(':');
      if (parts.length >= 2) {
        final label = parts[0].trim();
        final target = parts.sublist(1).join(':').trim();
        if (label.isNotEmpty && target.isNotEmpty) {
          map[label] = target;
        }
      }
    }
    return map;
  }

  Future<Map<String, dynamic>?> _stageDialog([Map<String, dynamic>? node]) async {
    final idCtr = TextEditingController(text: node?['id'] ?? '');
    final nextCtr = TextEditingController(
        text: (node?['next'] as List?)?.join(', ') ?? '');
    final depCtr = TextEditingController(
        text: (node?['dependsOn'] as List?)?.join(', ') ?? '');
    String stageType = node?['stageType']?.toString() ?? 'practice';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(node == null ? 'Add Stage' : 'Edit Stage'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtr,
                decoration: const InputDecoration(labelText: 'id'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: stageType,
                decoration: const InputDecoration(labelText: 'stageType'),
                items: const [
                  DropdownMenuItem(value: 'practice', child: Text('practice')),
                  DropdownMenuItem(value: 'theory', child: Text('theory')),
                  DropdownMenuItem(value: 'booster', child: Text('booster')),
                ],
                onChanged: (v) => stageType = v ?? 'practice',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nextCtr,
                decoration:
                    const InputDecoration(labelText: 'next (comma separated)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: depCtr,
                decoration: const InputDecoration(
                    labelText: 'dependsOn (comma separated)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return null;
    return {
      'type': 'stage',
      'id': idCtr.text.trim(),
      if (stageType != 'practice') 'stageType': stageType,
      if (nextCtr.text.trim().isNotEmpty) 'next': _splitList(nextCtr.text),
      if (depCtr.text.trim().isNotEmpty) 'dependsOn': _splitList(depCtr.text),
    };
  }

  Future<Map<String, dynamic>?> _theoryDialog([Map<String, dynamic>? node]) async {
    final idCtr = TextEditingController(text: node?['id'] ?? '');
    final titleCtr = TextEditingController(text: node?['title'] ?? '');
    final contentCtr = TextEditingController(text: node?['content'] ?? '');
    final nextCtr = TextEditingController(
        text: (node?['next'] as List?)?.join(', ') ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(node == null ? 'Add Theory' : 'Edit Theory'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtr,
                decoration: const InputDecoration(labelText: 'id'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtr,
                decoration: const InputDecoration(labelText: 'title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtr,
                decoration: const InputDecoration(labelText: 'content'),
                maxLines: null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nextCtr,
                decoration:
                    const InputDecoration(labelText: 'next (comma separated)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return null;
    return {
      'type': 'theory',
      'id': idCtr.text.trim(),
      'title': titleCtr.text.trim(),
      'content': contentCtr.text.trim(),
      if (nextCtr.text.trim().isNotEmpty) 'next': _splitList(nextCtr.text),
    };
  }

  Future<Map<String, dynamic>?> _branchDialog([Map<String, dynamic>? node]) async {
    final idCtr = TextEditingController(text: node?['id'] ?? '');
    final promptCtr = TextEditingController(text: node?['prompt'] ?? '');
    final branchesCtr = TextEditingController(
      text: node?['branches'] is Map
          ? (node!['branches'] as Map).entries
              .map((e) => '${e.key}:${e.value}')
              .join('\n')
          : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(node == null ? 'Add Branch' : 'Edit Branch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtr,
                decoration: const InputDecoration(labelText: 'id'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptCtr,
                decoration: const InputDecoration(labelText: 'prompt'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: branchesCtr,
                decoration: const InputDecoration(
                    labelText: 'branches (label:target per line)'),
                maxLines: null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return null;
    return {
      'type': 'branch',
      'id': idCtr.text.trim(),
      'prompt': promptCtr.text.trim(),
      'branches': _parseBranches(branchesCtr.text),
    };
  }

  Future<void> _addStage() async {
    final node = await _stageDialog();
    if (node == null) return;
    setState(() => _rawNodes.add(node));
    await _rebuild();
  }

  Future<void> _addTheory() async {
    final node = await _theoryDialog();
    if (node == null) return;
    setState(() => _rawNodes.add(node));
    await _rebuild();
  }

  Future<void> _addBranch() async {
    final node = await _branchDialog();
    if (node == null) return;
    setState(() => _rawNodes.add(node));
    await _rebuild();
  }

  Future<void> _editNode(int index) async {
    final n = _rawNodes[index];
    final type = n['type'];
    final node = type == 'branch'
        ? await _branchDialog(n)
        : type == 'theory'
            ? await _theoryDialog(n)
            : await _stageDialog(n);
    if (node == null) return;
    setState(() => _rawNodes[index] = node);
    await _rebuild();
  }

  void _deleteNode(int index) {
    setState(() => _rawNodes.removeAt(index));
    _rebuild();
  }

  Future<void> _importFromFile() async {
    await GraphTemplateLibrary.instance.importFromFile();
  }

  Future<void> _saveYaml() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save YAML',
      fileName: '\${_templateId ?? 'path'}.yaml',
      type: FileType.custom,
      allowedExtensions: ['yaml'],
    );
    if (path == null) return;
    final file = File(path);
    await file.writeAsString(_yaml);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _exportTemplate() async {
    final id = _templateId;
    if (id == null) return;
    await const GraphTemplateExporter().exportTemplate(id);
  }

  Widget _validationStatus() {
    if (_validationErrors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Graph is valid ✅'),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade900,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Validation Errors',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          for (final e in _validationErrors)
            Text('- $e', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _templateStep() {
    final templates = GraphTemplateLibrary.instance.listTemplates();
    return ListView(
      children: [
        ElevatedButton(
          onPressed: _importFromFile,
          child: const Text('📂 Import YAML from file'),
        ),
        const SizedBox(height: 12),
        for (final t in templates)
          RadioListTile<String>(
            value: t,
            groupValue: _templateId,
            title: Text(t),
            activeColor: Colors.greenAccent,
            onChanged: (v) {
              if (v != null) _loadTemplate(v);
            },
          ),
      ],
    );
  }

  Widget _editStep() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PathMapVisualizer(
            nodes: _nodes,
            currentNodeId: null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(onPressed: _addStage, child: const Text('Add Stage')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _addTheory, child: const Text('Add Theory')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _addBranch, child: const Text('Add Branch')),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _rawNodes.length,
            itemBuilder: (context, i) {
              final n = _rawNodes[i];
              return ListTile(
                title: Text('${n['id']} [${n['type']}]'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editNode(i),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteNode(i),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _validationStatus(),
      ],
    );
  }

  Widget _exportStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: SelectableText(_yaml, style: const TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _yaml));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Copied')));
              },
              child: const Text('Copy'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _saveYaml, child: const Text('Save to File')),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _templateId == null ? null : _exportTemplate,
              child: const Text('💾 Export to file'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Graph Path Authoring Wizard')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: IndexedStack(
          index: _step,
          children: [
            _templateStep(),
            _editStep(),
            _exportStep(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (_step > 0)
              ElevatedButton(onPressed: _back, child: const Text('Back')),
            const Spacer(),
            if (_step < 2)
              ElevatedButton(
                onPressed: _step == 0 && _templateId == null ? null : _next,
                child: const Text('Next'),
              ),
          ],
        ),
      ),
    );
  }
}

