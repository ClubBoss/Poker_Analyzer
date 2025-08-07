import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/pack_tag_counter_service.dart';

/// Debug screen that visualizes tag usage counts from [PackTagCounterService].
class PackTagCounterDebuggerScreen extends StatefulWidget {
  const PackTagCounterDebuggerScreen({super.key});

  @override
  State<PackTagCounterDebuggerScreen> createState() =>
      _PackTagCounterDebuggerScreenState();
}

class _PackTagCounterDebuggerScreenState
    extends State<PackTagCounterDebuggerScreen> {
  Map<String, int> _counts = const <String, int>{};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void _loadCounts() {
    setState(() {
      _counts = PackTagCounterService.instance.getTagCounts();
    });
  }

  void _reset() {
    PackTagCounterService.instance.reset();
    _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final entries = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Coverage'),
        actions: [TextButton(onPressed: _reset, child: const Text('Reset'))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final e = entries[i];
          final progress = maxCount == 0 ? 0.0 : e.value / maxCount;
          return ListTile(
            title: Text(e.key),
            subtitle: LinearProgressIndicator(value: progress),
            trailing: Text('${e.value}'),
          );
        },
      ),
    );
  }
}
