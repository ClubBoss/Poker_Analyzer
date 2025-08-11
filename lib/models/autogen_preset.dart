import 'texture_filter_config.dart';
import 'theory_injector_config.dart';

class AutogenPreset {
  final String id;
  final String name;
  final String? description;
  final TextureFilterConfig textures;
  final TheoryInjectorConfig theory;
  final int spotsPerPack;
  final int streets;
  final double theoryRatio;
  final String outputDir;
  final Map<String, dynamic> extras;

  const AutogenPreset({
    required this.id,
    required this.name,
    this.description,
    this.textures = const TextureFilterConfig(),
    this.theory = const TheoryInjectorConfig(),
    this.spotsPerPack = 12,
    this.streets = 1,
    this.theoryRatio = 0.5,
    this.outputDir = 'packs/generated',
    this.extras = const {},
  });

  factory AutogenPreset.fromJson(Map<String, dynamic> json) {
    return AutogenPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      textures: json['textures'] is Map<String, dynamic>
          ? TextureFilterConfig.fromJson(
              (json['textures'] as Map).cast<String, dynamic>(),
            )
          : const TextureFilterConfig(),
      theory: json['theory'] is Map<String, dynamic>
          ? TheoryInjectorConfig.fromJson(
              (json['theory'] as Map).cast<String, dynamic>(),
            )
          : const TheoryInjectorConfig(),
      spotsPerPack: json['spotsPerPack'] as int? ?? 12,
      streets: json['streets'] as int? ?? 1,
      theoryRatio: (json['theoryRatio'] as num?)?.toDouble() ?? 0.5,
      outputDir: json['outputDir'] as String? ?? 'packs/generated',
      extras: json['extras'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['extras'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'textures': textures.toJson(),
        'theory': theory.toJson(),
        'spotsPerPack': spotsPerPack,
        'streets': streets,
        'theoryRatio': theoryRatio,
        'outputDir': outputDir,
        if (extras.isNotEmpty) 'extras': extras,
      };
}
