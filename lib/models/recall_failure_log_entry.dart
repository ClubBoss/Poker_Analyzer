class RecallFailureLogEntry {
  final String? tag;
  final String? spotId;
  final DateTime timestamp;

  const RecallFailureLogEntry({this.tag, this.spotId, required this.timestamp});

  Map<String, dynamic> toJson() => {
    if (tag != null && tag!.isNotEmpty) 'tag': tag,
    if (spotId != null && spotId!.isNotEmpty) 'spotId': spotId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecallFailureLogEntry.fromJson(Map<String, dynamic> json) =>
      RecallFailureLogEntry(
        tag: json['tag'] as String?,
        spotId: json['spotId'] as String?,
        timestamp:
            DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      );
}
