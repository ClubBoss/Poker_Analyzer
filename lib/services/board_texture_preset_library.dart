import '../models/constraint_set.dart';
import '../models/board_stages.dart';
import '../models/card_model.dart';
import '../helpers/board_filtering_params_builder.dart';
import 'board_texture_filter_service.dart';
import 'board_filtering_service_v2.dart';

/// Provides predefined board texture presets that expand to board constraint
/// parameter maps suitable for [ConstraintSet.boardConstraints].
class BoardTexturePresetLibrary {
  static final Map<String, Map<String, dynamic>> _presets = {
    'lowpaired': {
      'requiredTextures': ['paired', 'low', 'rainbow'],
    },
    'dryacehigh': {
      'requiredTextures': ['aceHigh', 'rainbow'],
      'excludedTags': ['straightDrawHeavy'],
    },
    'connectedmono': {
      'requiredTextures': ['connected', 'monotone'],
    },
    'broadwayrainbow': {
      'requiredTextures': ['broadway', 'rainbow'],
    },
  };

  /// Returns a constraint map for the given [presetName].
  ///
  /// Throws [ArgumentError] if [presetName] is not a supported preset.
  static Map<String, dynamic> get(String presetName) {
    final key = presetName.toLowerCase();
    final preset = _presets[key];
    if (preset == null) {
      throw ArgumentError('Unknown board texture preset: $presetName');
    }
    // Return a copy to prevent external mutation.
    return Map<String, dynamic>.from(preset);
  }

  /// Checks whether [board] satisfies the texture constraints of [presetName].
  ///
  /// The board must satisfy all `requiredTextures` and `requiredTags` while
  /// avoiding any `excludedTags` defined by the preset. Returns `true` if the
  /// board matches the preset, otherwise `false`.
  static bool matches(List<CardModel> board, String presetName) {
    if (board.isEmpty) return false;
    final preset = get(presetName);

    final textures = <String>[
      for (final t in (preset['requiredTextures'] as List? ?? [])) t.toString(),
    ];
    final filter = BoardFilteringParamsBuilder.build(textures);
    if (!_textureFilter.isMatch(board, filter)) {
      return false;
    }

    final requiredTags = <String>{
      for (final t in (filter['boardTexture'] as List? ?? []))
        t == 'broadway' ? 'broadwayHeavy' : t.toString(),
      for (final t in (preset['requiredTags'] as List? ?? [])) t.toString(),
    };
    final excludedTags = <String>{
      for (final t in (preset['excludedTags'] as List? ?? [])) t.toString(),
    };

    final stages = _toBoardStages(board);
    return _boardFilter.isMatch(
      stages,
      requiredTags,
      excludedTags: excludedTags,
    );
  }

  static BoardStages _toBoardStages(List<CardModel> board) {
    final flop = <String>[];
    for (var i = 0; i < 3; i++) {
      flop.add(i < board.length ? board[i].toString() : '2c');
    }
    final turn = board.length > 3 ? board[3].toString() : '2d';
    final river = board.length > 4 ? board[4].toString() : '3c';
    return BoardStages(flop: flop, turn: turn, river: river);
  }

  static final BoardTextureFilterService _textureFilter =
      BoardTextureFilterService();
  static final BoardFilteringServiceV2 _boardFilter =
      BoardFilteringServiceV2();
}
