import 'line_graph_node.dart';

class LineGraphEdge {
  final LineGraphNode from;
  final LineGraphNode to;
  final double? weight;
  final Set<String> tags;

  LineGraphEdge({
    required this.from,
    required this.to,
    this.weight,
    Set<String>? tags,
  }) : tags = tags ?? <String>{};
}
