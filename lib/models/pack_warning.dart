class PackWarning {
  final String type;
  final String message;
  final String packId;
  const PackWarning(this.type, this.message, this.packId);
  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'packId': packId,
      };
  factory PackWarning.fromJson(Map<String, dynamic> j) => PackWarning(
      j['type']?.toString() ?? '',
      j['message']?.toString() ?? '',
      j['packId']?.toString() ?? '');
}
