import 'inline_theory_entry.dart';

class HandActionNode {
  final String actor;
  final String action;
  final String? tag;
  final List<HandActionNode> next;
  InlineTheoryEntry? theory;

  HandActionNode({
    required this.actor,
    required this.action,
    this.tag,
    List<HandActionNode>? next,
    this.theory,
  }) : next = next ?? [];
}

class LineGraphResult {
  final String heroPosition;
  final Map<String, List<HandActionNode>> streets;
  final List<String> tags;

  LineGraphResult({
    required this.heroPosition,
    required this.streets,
    required this.tags,
  });
}
