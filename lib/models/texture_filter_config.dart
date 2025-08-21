class TextureFilterConfig {
  final Set<String> include;
  final Set<String> exclude;
  final Map<String, double> targetMix;

  const TextureFilterConfig({
    this.include = const {},
    this.exclude = const {},
    this.targetMix = const {},
  });

  factory TextureFilterConfig.fromJson(Map<String, dynamic> json) {
    return TextureFilterConfig(
      include: (json['include'] as List?)?.cast<String>().toSet() ?? {},
      exclude: (json['exclude'] as List?)?.cast<String>().toSet() ?? {},
      targetMix:
          (json['targetMix'] as Map?)?.map(
            (key, value) => MapEntry(key as String, (value as num).toDouble()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
    if (include.isNotEmpty) 'include': include.toList(),
    if (exclude.isNotEmpty) 'exclude': exclude.toList(),
    if (targetMix.isNotEmpty) 'targetMix': targetMix,
  };
}
