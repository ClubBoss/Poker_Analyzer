class LinePattern {
  final Map<String, List<String>> streets;
  final String? startingPosition;
  final String? boardTexture;
  final String? potType;

  LinePattern({
    required this.streets,
    this.startingPosition,
    this.boardTexture,
    this.potType,
  });

  factory LinePattern.fromJson(Map<String, dynamic> json) {
    final streets = <String, List<String>>{};
    if (json['streets'] is Map) {
      (json['streets'] as Map).forEach((key, value) {
        streets[key.toString()] = [
          for (final v in (value as List? ?? [])) v.toString(),
        ];
      });
    }
    return LinePattern(
      streets: streets,
      startingPosition: json['startingPosition']?.toString(),
      boardTexture: json['boardTexture']?.toString(),
      potType: json['potType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'streets': streets,
    if (startingPosition != null) 'startingPosition': startingPosition,
    if (boardTexture != null) 'boardTexture': boardTexture,
    if (potType != null) 'potType': potType,
  };
}
