class TheoryInjectorConfig {
  final bool enabled;
  final int maxLinksPerSpot;
  final double minScore;
  final double wTag;
  final double wTex;
  final double wCluster;
  final bool preferNovelty;

  const TheoryInjectorConfig({
    this.enabled = true,
    this.maxLinksPerSpot = 2,
    this.minScore = 0.5,
    this.wTag = 0.6,
    this.wTex = 0.25,
    this.wCluster = 0.15,
    this.preferNovelty = true,
  });

  factory TheoryInjectorConfig.fromJson(Map<String, dynamic> json) {
    return TheoryInjectorConfig(
      enabled: json['enabled'] as bool? ?? true,
      maxLinksPerSpot: json['maxLinksPerSpot'] as int? ?? 2,
      minScore: (json['minScore'] as num?)?.toDouble() ?? 0.5,
      wTag: (json['wTag'] as num?)?.toDouble() ?? 0.6,
      wTex: (json['wTex'] as num?)?.toDouble() ?? 0.25,
      wCluster: (json['wCluster'] as num?)?.toDouble() ?? 0.15,
      preferNovelty: json['preferNovelty'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'maxLinksPerSpot': maxLinksPerSpot,
        'minScore': minScore,
        'wTag': wTag,
        'wTex': wTex,
        'wCluster': wCluster,
        'preferNovelty': preferNovelty,
      };
}
