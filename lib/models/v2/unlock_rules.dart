class UnlockRules {
  final List<String> requiredPacks;
  final double? minEV;
  final bool? requiresStarterPathCompleted;

  const UnlockRules({
    this.requiredPacks = const [],
    this.minEV,
    this.requiresStarterPathCompleted,
  });

  factory UnlockRules.fromJson(Map<String, dynamic> j) => UnlockRules(
        requiredPacks: [for (final p in (j['requiredPacks'] as List? ?? [])) p.toString()],
        minEV: (j['minEV'] as num?)?.toDouble(),
        requiresStarterPathCompleted: j['requiresStarterPathCompleted'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        if (requiredPacks.isNotEmpty) 'requiredPacks': requiredPacks,
        if (minEV != null) 'minEV': minEV,
        if (requiresStarterPathCompleted != null)
          'requiresStarterPathCompleted': requiresStarterPathCompleted,
      };
}
