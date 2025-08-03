import 'package:flutter/material.dart';

import '../services/inline_theory_linker.dart';

/// Displays a compact card linking to relevant theory for the provided [tags].
///
/// If no lesson is found, renders an empty widget.
class InlineTheoryLinkerWidget extends StatelessWidget {
  final List<String> tags;
  final InlineTheoryLinker linker;

  const InlineTheoryLinkerWidget({
    super.key,
    required this.tags,
    InlineTheoryLinker? linker,
  }) : linker = linker ?? InlineTheoryLinker();

  @override
  Widget build(BuildContext context) {
    final link = linker.getLink(tags);
    if (link == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.school),
        title: Text('Review Theory: ${link.title}'),
        trailing: TextButton(
          onPressed: link.onTap,
          child: const Text('Open'),
        ),
      ),
    );
  }
}
