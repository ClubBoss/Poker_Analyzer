import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/skill_tag_coverage_tracker_service.dart';

/// Debug screen visualizing how often each skill tag appears.
class SkillTagCoverageDebuggerScreen extends StatefulWidget {
  const SkillTagCoverageDebuggerScreen({super.key});

  @override
  State<SkillTagCoverageDebuggerScreen> createState() =>
      _SkillTagCoverageDebuggerScreenState();
}

class _SkillTagCoverageDebuggerScreenState
    extends State<SkillTagCoverageDebuggerScreen> {
  Map<String, int> _stats = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _stats = SkillTagCoverageTrackerService.instance.getTagStats();
    setState(() {});
  }

  void _reset() {
    SkillTagCoverageTrackerService.instance.reset();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final entries = _stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tag Coverage'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          return ListTile(
            title: Text(e.key),
            trailing: Text('${e.value}'),
            subtitle: LinearProgressIndicator(
              value: e.value / max,
            ),
          );
        },
      ),
    );
  }
}
