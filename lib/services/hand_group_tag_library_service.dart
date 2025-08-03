import 'hand_range_library.dart';

/// Provides expansion of abstract hand group tags into concrete hand group
/// identifiers understood by [HandRangeLibrary].
class HandGroupTagLibraryService {
  /// Mapping of normalized tag id to a list of hand group identifiers.
  static final Map<String, List<String>> _tagMap = {
    'pockets': const ['pockets'],
    'broadway': const ['broadways'],
    'broadways': const ['broadways'],
    'suitedconnectors': const ['suitedConnectors'],
    'lowax': const ['lowAx'],
    'kxsuited': const ['KxSuited'],
  };

  /// Expands [tags] into a list of concrete hand group identifiers.
  ///
  /// Unknown tags are ignored. Returned identifiers are unique.
  static List<String> expandTags(List<String> tags) {
    final result = <String>{};
    for (final t in tags) {
      final key = t.toLowerCase();
      final groups = _tagMap[key];
      if (groups != null) {
        result.addAll(groups);
      }
    }
    return result.toList();
  }

  /// Exposes all supported tag identifiers.
  static List<String> supportedTagIds() => _tagMap.keys.toList();
}
