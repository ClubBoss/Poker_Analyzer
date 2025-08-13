import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/learning_path_library.dart';
import '../services/smart_path_validator.dart';
import '../models/path_validation_issue.dart';
import '../models/learning_path_template_v2.dart';
import '../theme/app_colors.dart';

class LearningPathValidationScreen extends StatefulWidget {
  const LearningPathValidationScreen({super.key});

  @override
  State<LearningPathValidationScreen> createState() =>
      _LearningPathValidationScreenState();
}

class _LearningPathValidationScreenState
    extends State<LearningPathValidationScreen> {
  bool _loading = true;
  final List<PathValidationIssue> _issues = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final json = [for (final p in LearningPathLibrary.main.paths) p.toJson()];
    final data = await compute(_validateTask, json);
    if (!mounted) return;
    setState(() {
      _issues
        ..clear()
        ..addAll(data.map((e) => PathValidationIssue.fromJson(e)));
      _loading = false;
    });
  }

  Map<String, List<PathValidationIssue>> _grouped() {
    final map = <String, List<PathValidationIssue>>{};
    for (final i in _issues) {
      map.putIfAbsent(i.pathId, () => []).add(i);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Path Validation'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Total issues: ${_issues.length}'),
                const SizedBox(height: 16),
                for (final entry in _grouped().entries)
                  Card(
                    color: AppColors.cardBackground,
                    child: ExpansionTile(
                      title: Text(entry.key),
                      subtitle: Text('Issues: ${entry.value.length}'),
                      children: [
                        for (final i in entry.value)
                          ListTile(
                            title: Text('${i.issueType.name}: ${i.message}'),
                            subtitle: i.stageId != null
                                ? Text(
                                    'stage: ${i.stageId}${i.subStageId != null ? ' / ${i.subStageId}' : ''}')
                                : null,
                          ),
                      ],
                    ),
                  ),
                if (_issues.isEmpty)
                  const Center(child: Text('No issues found')),
              ],
            ),
    );
  }
}

Future<List<Map<String, dynamic>>> _validateTask(
    List<Map<String, dynamic>> json) async {
  final paths = [for (final m in json) LearningPathTemplateV2.fromJson(m)];
  final issues = const SmartPathValidator().validateAll(paths);
  return [for (final i in issues) i.toJson()];
}
