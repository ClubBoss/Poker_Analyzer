class TrainingPackTemplateSetValidator {
  const TrainingPackTemplateSetValidator._();

  static void validate(Map<String, dynamic> json, {String source = ''}) {
    final outputs = json['outputVariants'];
    if (outputs == null) return;
    if (outputs is List) {
      _fail(
        'outputVariants must be a map of keys to variant objects. '
        'See docs/training_pack_template_schema.md#outputvariants',
        source,
      );
    }
    if (outputs is! Map) {
      _fail('outputVariants must be a map', source);
    }
    final allowed = {
      'targetStreet',
      'boardConstraints',
      'requiredTags',
      'excludedTags',
      'seed',
    };
    outputs.forEach((key, value) {
      if (value is! Map) {
        _fail('outputVariants.$key must be a map', source);
      }
      for (final k in value.keys) {
        if (!allowed.contains(k)) {
          _fail('Unknown field outputVariants.$key.$k', source);
        }
      }
      final street = value['targetStreet'];
      if (street != null) {
        const streets = {'preflop', 'flop', 'turn', 'river'};
        if (!streets.contains(street.toString().toLowerCase())) {
          _fail(
            'outputVariants.$key.targetStreet must be one of preflop, flop, turn, river',
            source,
          );
        }
      }
      final bc = value['boardConstraints'];
      if (bc != null) {
        if (bc is! List) {
          _fail('outputVariants.$key.boardConstraints must be a list', source);
        }
        for (var i = 0; i < (bc).length; i++) {
          final entry = bc[i];
          if (entry is! Map) {
            _fail(
              'outputVariants.$key.boardConstraints[$i] must be a map',
              source,
            );
          }
          final s = entry['targetStreet'];
          if (s != null) {
            const streets = {'preflop', 'flop', 'turn', 'river'};
            if (!streets.contains(s.toString().toLowerCase())) {
              _fail(
                'outputVariants.$key.boardConstraints[$i].targetStreet must be one of preflop, flop, turn, river',
                source,
              );
            }
          }
        }
      }
    });
  }

  static Never _fail(String message, String source) {
    final prefix = source.isNotEmpty ? '$source: ' : '';
    throw FormatException(prefix + message);
  }
}
