class HandActionNode {
  final String actor;
  final String action;
  final List<HandActionNode> next;

  HandActionNode({
    required this.actor,
    required this.action,
    List<HandActionNode>? next,
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
