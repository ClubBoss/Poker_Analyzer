import 'package:flutter/material.dart';

import '../services/inline_theory_linker.dart';

/// Renders a tappable chip linking to a [TheoryMiniLessonNode] resolved by tag.
///
/// If [theoryTag] is `null` or no lesson is found, renders an empty widget.
class InlineTheoryLinkChip extends StatelessWidget {
  final String? theoryTag;
  final InlineTheoryLinker linker;

  const InlineTheoryLinkChip({
    super.key,
    required this.theoryTag,
    InlineTheoryLinker? linker,
  }) : linker = linker ?? InlineTheoryLinker();

  @override
  Widget build(BuildContext context) {
    final tag = theoryTag;
    if (tag == null) return const SizedBox.shrink();
    final link = linker.getLink([tag]);
    if (link == null) return const SizedBox.shrink();
    return ActionChip(
      avatar: const Icon(Icons.school, size: 16),
      label: Text('Theory: ${link.title}'),
      onPressed: link.onTap,
    );
  }
}
