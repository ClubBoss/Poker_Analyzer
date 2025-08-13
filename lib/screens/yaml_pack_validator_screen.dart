import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../models/validation_issue.dart';
import '../services/yaml_pack_auto_fix_engine.dart';
import '../services/yaml_pack_history_service.dart';
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../services/training_pack_template_validator.dart';
import '../models/v2/training_pack_template_v2.dart';

class YamlPackValidatorScreen extends StatefulWidget {
  const YamlPackValidatorScreen({super.key});
  @override
  State<YamlPackValidatorScreen> createState() =>
      _YamlPackValidatorScreenState();
}

class _PackIssues {
  final String path;
  final String id;
  final List<ValidationIssue> issues;
  const _PackIssues(
      {required this.path, required this.id, required this.issues});
}

class _YamlPackValidatorScreenState extends State<YamlPackValidatorScreen> {
  bool _loading = true;
  final List<_PackIssues> _items = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await compute(_validateTask, '');
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(data.map((e) => _PackIssues(
              path: e['path'] as String,
              id: e['id'] as String,
              issues: [
                for (final j in (e['issues'] as List))
                  ValidationIssue.fromJson(Map<String, dynamic>.from(j))
              ],
            )));
      _loading = false;
    });
  }

  List<_PackIssues> _filtered() {
    if (_filter == 'all') return _items;
    return [
      for (final i in _items)
        if (i.issues.any((e) => e.type == _filter)) i
    ];
  }

  Future<void> _autoFix(String path) async {
    final json = await compute(_autoFixTask, path);
    if (json.isEmpty) return;
    final pack = TrainingPackTemplateV2.fromJson(json);
    await const YamlPackHistoryService().saveSnapshot(pack, 'fix');
    await const YamlWriter().write(json, path);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Готово')));
      _load();
    }
  }

  String _fileName(String path) => p.basename(path);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('YAML Pack Validator'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => setState(() => _filter = 'all'),
                child: Text('All',
                    style: TextStyle(
                        color: _filter == 'all' ? Colors.amber : Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => _filter = 'error'),
                child: Text('Errors',
                    style: TextStyle(
                        color:
                            _filter == 'error' ? Colors.amber : Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => _filter = 'warning'),
                child: Text('Warnings',
                    style: TextStyle(
                        color: _filter == 'warning'
                            ? Colors.amber
                            : Colors.white)),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in _filtered())
                  Card(
                    color: AppColors.cardBackground,
                    child: ExpansionTile(
                      title: Text(_fileName(item.path)),
                      subtitle: Text(item.id),
                      children: [
                        for (final i in item.issues)
                          if (_filter == 'all' || i.type == _filter)
                            ListTile(
                              title: Text('${i.type}: ${i.message}'),
                            ),
                        TextButton(
                          onPressed: () => _autoFix(item.path),
                          child: const Text('🛠 Поправить автоматически'),
                        ),
                      ],
                    ),
                  ),
                if (_items.isEmpty) const Center(child: Text('Нет проблем')),
              ],
            ),
    );
  }
}

Future<List<Map<String, dynamic>>> _validateTask(String _) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'training_packs', 'library'));
  const reader = YamlReader();
  const validator = TrainingPackTemplateValidator();
  final list = <Map<String, dynamic>>[];
  if (dir.existsSync()) {
    for (final f in dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      final issues = <ValidationIssue>[];
      String id = '';
      try {
        final map = reader.read(await f.readAsString());
        final tpl =
            TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
        id = tpl.id;
        issues.addAll(validator.validate(tpl));
        if (tpl.meta['schemaVersion']?.toString() != '2.0.0') {
          issues.add(const ValidationIssue(
              type: 'warning', message: 'schema_version'));
        }
        if (tpl.spots.any((s) => s.evalResult != null)) {
          issues.add(const ValidationIssue(
              type: 'warning', message: 'eval_result_present'));
        }
        for (final s in tpl.spots) {
          final stack = s.hand.stacks['${s.hand.heroIndex}'];
          if (stack != null && stack < tpl.bb) {
            final bad = s.hand.actions.values
                .any((l) => l.any((a) => (a.amount ?? 0) > tpl.bb));
            if (bad) {
              issues.add(
                  ValidationIssue(type: 'error', message: 'bad_bet:${s.id}'));
            }
          }
        }
      } catch (e) {
        issues.add(
            ValidationIssue(type: 'error', message: e.runtimeType.toString()));
      }
      list.add({
        'path': f.path,
        'id': id,
        'issues': [for (final i in issues) i.toJson()]
      });
    }
  }
  final count = <String, int>{};
  for (final m in list) {
    final id = m['id'] as String;
    count[id] = (count[id] ?? 0) + 1;
  }
  for (final m in list) {
    final issues = [
      for (final j in m['issues'] as List)
        ValidationIssue.fromJson(Map<String, dynamic>.from(j))
    ];
    final id = m['id'] as String;
    if (id.trim().isEmpty) {
      issues.add(const ValidationIssue(type: 'error', message: 'empty_id'));
    } else if (count[id]! > 1) {
      issues.add(const ValidationIssue(type: 'error', message: 'duplicate_id'));
    }
    m['issues'] = [for (final i in issues) i.toJson()];
  }
  return list;
}

Future<Map<String, dynamic>> _autoFixTask(String path) async {
  final file = File(path);
  if (!file.existsSync()) return {};
  final yaml = await file.readAsString();
  final map = const YamlReader().read(yaml);
  final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  final fixed = const YamlPackAutoFixEngine().autoFix(tpl);
  return fixed.toJson();
}
