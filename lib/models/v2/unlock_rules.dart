class UnlockRules {
  final List<String> requiredPacks;
  final double? minAccuracy;
  final double? minEV;
  final double? minIcm;
  final bool? requiresStarterPathCompleted;
  final String? unlockHint;

  const UnlockRules({
    this.requiredPacks = const [],
    this.minAccuracy,
    this.minEV,
    this.minIcm,
    this.requiresStarterPathCompleted,
    this.unlockHint,
  });

  factory UnlockRules.fromJson(Map<String, dynamic> j) => UnlockRules(
    requiredPacks: [
      for (final p in (j['requiredPacks'] as List? ?? [])) p.toString(),
    ],
    minAccuracy: (j['minAccuracy'] as num?)?.toDouble(),
    minEV: (j['minEV'] as num?)?.toDouble(),
    minIcm: (j['minIcm'] as num?)?.toDouble(),
    requiresStarterPathCompleted: j['requiresStarterPathCompleted'] as bool?,
    unlockHint: j['unlockHint'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (requiredPacks.isNotEmpty) 'requiredPacks': requiredPacks,
    if (minAccuracy != null) 'minAccuracy': minAccuracy,
    if (minEV != null) 'minEV': minEV,
    if (minIcm != null) 'minIcm': minIcm,
    if (requiresStarterPathCompleted != null)
      'requiresStarterPathCompleted': requiresStarterPathCompleted,
    if (unlockHint != null && unlockHint!.isNotEmpty) 'unlockHint': unlockHint,
  };
}
