class StageRemedialMeta {
  final String remedialPackId;
  final int sourceAttempts;
  final Map<String, int> missTags;
  final Map<String, int> missTextures;
  final DateTime createdAt;
  final bool completed;

  StageRemedialMeta({
    required this.remedialPackId,
    this.sourceAttempts = 0,
    Map<String, int>? missTags,
    Map<String, int>? missTextures,
    DateTime? createdAt,
    this.completed = false,
  })  : missTags = missTags ?? const {},
        missTextures = missTextures ?? const {},
        createdAt = createdAt ?? DateTime.now();

  factory StageRemedialMeta.fromJson(Map<String, dynamic> json) {
    return StageRemedialMeta(
      remedialPackId: json['remedialPackId'] as String? ?? '',
      sourceAttempts: (json['sourceAttempts'] as num?)?.toInt() ?? 0,
      missTags: json['missTags'] is Map
          ? Map<String, int>.from(
              json['missTags'].map((k, v) => MapEntry(k.toString(), (v as num).toInt())))
          : const {},
      missTextures: json['missTextures'] is Map
          ? Map<String, int>.from(
              json['missTextures'].map((k, v) => MapEntry(k.toString(), (v as num).toInt())))
          : const {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'remedialPackId': remedialPackId,
        'sourceAttempts': sourceAttempts,
        if (missTags.isNotEmpty) 'missTags': missTags,
        if (missTextures.isNotEmpty) 'missTextures': missTextures,
        'createdAt': createdAt.toIso8601String(),
        if (completed) 'completed': true,
      };
}

