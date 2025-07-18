import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_service.dart';

class SkillMapScreen extends StatefulWidget {
  const SkillMapScreen({super.key});

  @override
  State<SkillMapScreen> createState() => _SkillMapScreenState();
}

class _SkillMapScreenState extends State<SkillMapScreen> {
  bool _loading = true;
  Map<String, double> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = context.read<TagMasteryService>();
    final map = await service.computeMastery(force: true);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    setState(() {
      _data = {for (final e in entries) e.key: e.value};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Карта навыков'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tag = _data.keys.elementAt(index);
                final mastery = _data[tag] ?? 0.0;
                return ListTile(
                  title: Text('#$tag'),
                  subtitle: LinearProgressIndicator(value: mastery),
                  trailing: Text('${(mastery * 100).toStringAsFixed(0)}%'),
                );
              },
            ),
    );
  }
}
