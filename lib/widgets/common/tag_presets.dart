import 'dart:collection';

const List<String> _availableTagsList = [
  '3бет пот',
  'Фиш',
  'Рег',
  'ICM',
  'vs агро',
];

/// Unmodifiable list of available tags.
final List<String> availableTags = UnmodifiableListView(_availableTagsList);

const Map<String, List<String>> _tagPresetsMap = {
  '3бет пот': ['3бет пот'],
  'Фиш': ['Фиш'],
  'Рег': ['Рег'],
  'ICM': ['ICM'],
  'vs агро': ['vs агро'],
};

/// Unmodifiable map of tag presets.
final Map<String, List<String>> tagPresets =
    UnmodifiableMapView(_tagPresetsMap);

const Map<String, String> _quickFilterPresetsMap = {
  'ICM': 'ICM',
  'Push/Fold': 'Push/Fold',
  'Postflop': 'Postflop',
  '3-bet': '3-bet',
  'Bubble': 'Bubble',
};

/// Unmodifiable map of quick filter presets.
final Map<String, String> quickFilterPresets =
    UnmodifiableMapView(_quickFilterPresetsMap);

