import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_retention_tracker.dart';

class RefreshSkillsBlock extends StatefulWidget {
  const RefreshSkillsBlock({super.key});

  @override
  State<RefreshSkillsBlock> createState() => _RefreshSkillsBlockState();
}

class _RefreshSkillsBlockState extends State<RefreshSkillsBlock> {
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<TagRetentionTracker>().getDecayedTags();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final tags = snapshot.data!;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔁 Refresh skills',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in tags)
                    Chip(label: Text(t), backgroundColor: accent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
