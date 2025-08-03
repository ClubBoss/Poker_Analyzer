class SmartInboxItem {
  final String type;
  final String tag;
  final String source;
  final double? urgency;

  const SmartInboxItem({
    required this.type,
    required this.tag,
    required this.source,
    this.urgency,
  });
}
