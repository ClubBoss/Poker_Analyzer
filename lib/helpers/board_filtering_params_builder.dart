/// Helper to construct board filtering params from texture tags.
///
/// The [build] method takes a list of high level texture labels such as
/// `['aceHigh', 'paired', 'rainbow']` and converts them to a map that can be
/// passed into [FullBoardGeneratorService] via `boardFilterParams`.
library board_filtering_params_builder;

import '../services/board_filtering_tag_library_service.dart';

class BoardFilteringParamsBuilder {
  /// Builds a map of filter parameters based on [textureTags].
  ///
  /// Supported tags include:
  /// - `rainbow`, `twoTone`, `monotone`
  /// - `paired`
  /// - `aceHigh`
  /// - `low`
  /// - `highCard`
  /// - `connected`/`wet`/`dynamic` (straight draw heavy)
  /// - `broadway`
  static Map<String, dynamic> build(List<String> textureTags) {
    final filter = <String, dynamic>{};
    final boardTextures = <String>{};
    String? suitPattern;

    for (final t in textureTags) {
      final tag = BoardFilteringTagLibraryService.resolve(t);
      if (tag == null) {
        throw ArgumentError('Unknown board texture tag: $t');
      }
      final resolved = tag.id;
      switch (resolved) {
        case 'rainbow':
          suitPattern = 'rainbow';
          break;
        case 'twoTone':
          suitPattern = 'twoTone';
          break;
        case 'monotone':
          suitPattern = 'monotone';
          break;
        case 'paired':
          boardTextures.add('paired');
          break;
        case 'aceHigh':
          boardTextures.add('aceHigh');
          break;
        case 'low':
          boardTextures.add('low');
          break;
        case 'highCard':
          boardTextures.add('highCard');
          break;
        case 'connected':
        case 'wet':
        case 'dynamic':
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
