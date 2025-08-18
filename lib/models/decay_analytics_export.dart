import "../services/booster_adaptation_tuner.dart";

class DecayAnalyticsExport {
  final String tag;
  final double decay;
  final BoosterAdaptation adaptation;
  final DateTime? lastInteraction;
  final int recommendedDaysUntilReview;

  const DecayAnalyticsExport({
    required this.tag,
    required this.decay,
    required this.adaptation,
    this.lastInteraction,
    required this.recommendedDaysUntilReview,
  });

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'decay': decay,
    'adaptation': adaptation.name,
    if (lastInteraction != null)
      'lastInteraction': lastInteraction!.toIso8601String(),
    'recommendedDaysUntilReview': recommendedDaysUntilReview,
  };

  factory DecayAnalyticsExport.fromJson(Map<String, dynamic> json) =>
      DecayAnalyticsExport(
        tag: json['tag'] as String? ?? '',
        decay: (json['decay'] as num?)?.toDouble() ?? 0.0,
        adaptation: _parseAdaptation(json['adaptation'] as String?),
        lastInteraction: DateTime.tryParse(
          json['lastInteraction'] as String? ?? '',
        ),
        recommendedDaysUntilReview:
            (json['recommendedDaysUntilReview'] as num?)?.toInt() ?? 0,
      );

  static BoosterAdaptation _parseAdaptation(String? value) {
    switch (value) {
      case 'increase':
        return BoosterAdaptation.increase;
      case 'reduce':
        return BoosterAdaptation.reduce;
      default:
        return BoosterAdaptation.keep;
    }
  }
}
