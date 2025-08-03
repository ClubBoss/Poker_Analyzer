/// Helper to construct board filtering params from texture tags.
///
/// The [build] method takes a list of high level texture labels such as
/// `['aceHigh', 'paired', 'rainbow']` and converts them to a map that can be
/// passed into [FullBoardGeneratorService] via `boardFilterParams`.
library board_filtering_params_builder;

class BoardFilteringParamsBuilder {
  /// Builds a map of filter parameters based on [textureTags].
  ///
  /// Supported tags include:
  /// - `rainbow`, `twoTone`, `monotone`
  /// - `paired`
  /// - `aceHigh`
  /// - `lowBoard`
  /// - `connected` (straight draw heavy)
  /// - `broadway`
  static Map<String, dynamic> build(List<String> textureTags) {
    final filter = <String, dynamic>{};
    final boardTextures = <String>{};
    String? suitPattern;

    for (final t in textureTags) {
      final tag = t.toLowerCase();
      switch (tag) {
        case 'rainbow':
          suitPattern = 'rainbow';
          break;
        case 'twotone':
        case 'two-tone':
        case 'two_tone':
          suitPattern = 'twoTone';
          break;
        case 'monotone':
          suitPattern = 'monotone';
          break;
        case 'paired':
          boardTextures.add('paired');
          break;
        case 'acehigh':
          boardTextures.add('aceHigh');
          break;
        case 'lowboard':
        case 'low':
          boardTextures.add('low');
          break;
        case 'connected':
          boardTextures.add('straightDrawHeavy');
          break;
        case 'broadway':
          boardTextures.add('broadway');
          break;
        default:
          break;
      }
    }

    if (boardTextures.isNotEmpty) {
      filter['boardTexture'] = boardTextures.toList();
    }
    if (suitPattern != null) {
      filter['suitPattern'] = suitPattern;
    }

    return filter;
  }
}
