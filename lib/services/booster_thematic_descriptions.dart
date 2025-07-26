/// Provides short explanations for booster/theory tags.
class BoosterThematicDescriptions {
  static const Map<String, String> _data = {
    'push_sb':
        'Пуш с малого блайнда часто выгоден из-за отсутствия позиции.\nИзучите, когда лучше пушить против большого блайнда.',
  };

  static String? get(String tag) => _data[tag];

  /// Returns all known thematic tags.
  static List<String> get tags => _data.keys.toList();
}
