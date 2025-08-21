class SpotLineGraph {
  final SpotLineNode root;

  SpotLineGraph({required this.root});

  /// Returns all action lines from the root to every leaf node.
  List<SpotActionLine> getAllLines() {
    final result = <SpotActionLine>[];

    void visit(SpotLineNode node, List<SpotLineEdge> path) {
      if (node.edges.isEmpty) {
        result.add(SpotActionLine(List<SpotLineEdge>.from(path)));
        return;
      }
      for (final edge in node.edges) {
        path.add(edge);
        visit(edge.target, path);
        path.removeLast();
      }
    }

    visit(root, []);
    return result;
  }
}

class SpotLineNode {
  final int street;
  final double stack;
  final double pot;
  final String heroPosition;
  final List<String> actionHistory;
  final List<SpotLineEdge> edges;

  SpotLineNode({
    required this.street,
    required this.stack,
    required this.pot,
    required this.heroPosition,
    List<String>? actionHistory,
    List<SpotLineEdge>? edges,
  }) : actionHistory = actionHistory ?? [],
       edges = edges ?? [];
}

class SpotLineEdge {
  final String actor;
  final String action;
  final double? ev;
  final bool? correct;
  final SpotLineNode target;

  SpotLineEdge({
    required this.actor,
    required this.action,
    required this.target,
    this.ev,
    this.correct,
  });
}

class SpotActionLine {
  final List<SpotLineEdge> actions;

  const SpotActionLine(this.actions);
}
