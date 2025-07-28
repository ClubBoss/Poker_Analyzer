class TheoryTagStats {
  final String tag;
  final int count;
  final int incomingLinks;
  final int outgoingLinks;

  const TheoryTagStats({
    required this.tag,
    required this.count,
    required this.incomingLinks,
    required this.outgoingLinks,
  });
}
