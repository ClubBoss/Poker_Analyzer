class TextureFilterConfig {
  final Set<String> include;
  final Set<String> exclude;
  final Map<String, double> targetMix;

  const TextureFilterConfig({
    this.include = const {},
    this.exclude = const {},
    this.targetMix = const {},
  });

  Map<String, dynamic> toJson() => {
        if (include.isNotEmpty) 'include': include.toList(),
        if (exclude.isNotEmpty) 'exclude': exclude.toList(),
        if (targetMix.isNotEmpty) 'targetMix': targetMix,
      };
}
