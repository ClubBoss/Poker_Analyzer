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
    final streetMap = <String, List<String>>{};
    final rawStreets = json['streets'] as Map? ?? const {};
    rawStreets.forEach((key, value) {
      streetMap[key.toString()] = [
        for (final a in (value as List? ?? const [])) a.toString(),
      ];
    });
    return LinePattern(
      streets: streetMap,
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
