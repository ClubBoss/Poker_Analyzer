import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../services/inline_theory_linker_service.dart';

/// Displays theory descriptions for a training pack with inline lesson links.
class TrainingPackTheoryScreen extends StatelessWidget {
  final TrainingPackTemplateV2 template;
  TrainingPackTheoryScreen({super.key, required this.template});

  final _linker = InlineTheoryLinkerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${template.name} — теория')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (template.description.isNotEmpty)
            _linker
                .link(
                  template.description,
                  contextTags: template.tags,
                )
                .toRichText(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  linkStyle:
                      const TextStyle(color: Colors.lightBlueAccent),
                ),
          if (template.goal.isNotEmpty) ...[
            const SizedBox(height: 8),
            _linker
                .link(
                  template.goal,
                  contextTags: template.tags,
                )
                .toRichText(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  linkStyle:
                      const TextStyle(color: Colors.lightBlueAccent),
                ),
          ],
        ],
      ),
    );
  }
}

