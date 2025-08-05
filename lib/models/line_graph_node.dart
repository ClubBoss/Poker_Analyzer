class LineGraphNode {
  final String street;
  final String action;
  final String position;
  final Set<String> tagSet;

  LineGraphNode({
    required this.street,
    required this.action,
    required this.position,
    Set<String>? tagSet,
  }) : tagSet = tagSet ?? <String>{};

  @override
  String toString() => '$position $action $street';
}
