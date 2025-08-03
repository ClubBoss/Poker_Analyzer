import '../models/training_spot.dart';
import 'board_texture_filter_service.dart';

class ConstraintResolverEngine {
  static const _textureFilter = BoardTextureFilterService();

  /// Returns a normalized copy of [rawParams] where all constraint values
  /// are converted into canonical forms (e.g. lower‑cased lists).
  static Map<String, dynamic> normalizeParams(Map<String, dynamic> rawParams) {
    final result = <String, dynamic>{};
    rawParams.forEach((key, value) {
      switch (key) {
        case 'positions':
        case 'streets':
        case 'excludedCombos':
        case 'requiredCombos':
        case 'textureTags':
        case 'boardTextureTags':
          result[key] = _asStringList(value);
          break;
        case 'boardFilter':
          if (value is Map<String, dynamic>) {
            result[key] = Map<String, dynamic>.from(value);
          } else {
            result[key] = _asStringList(value);
          }
          break;
        case 'rankBias':
        case 'suitBias':
          if (value is Map) {
            final map = <String, double>{};
            value.forEach((k, v) {
              if (v is num) map[k.toString()] = v.toDouble();
            });
            result[key] = map;
          }
          break;
        default:
          result[key] = value;
          break;
      }
    });
    return result;
  }

  static List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return [for (final e in v) e.toString().toLowerCase()];
    }
    return [v.toString().toLowerCase()];
  }

  static bool isValidSpot(
    TrainingSpot spot,
    Map<String, dynamic> dynamicParams,
  ) {
    final params = normalizeParams(dynamicParams);

    final positions = params['positions'] as List<String>?;
    if (positions != null && positions.isNotEmpty) {
      final pos = spot.heroPosition?.toLowerCase() ?? '';
      if (!positions.contains(pos)) return false;
    }

    final streets = params['streets'] as List<String>?;
    if (streets != null && streets.isNotEmpty) {
      final street = _streetFromBoard(spot.boardCards.length);
      if (!streets.contains(street)) return false;
    }

    final bf = params['boardFilter'];
    if (bf is List) {
      final board = spot.boardCards.map((c) => c.toString()).toList();
      if (!_textureFilter.filter(board, bf)) return false;
    } else if (bf is Map<String, dynamic>) {
      if (!_textureFilter.isMatch(spot.boardCards, bf)) return false;
    }

    final required = params['requiredCombos'] as List<String>?;
    if (required != null && required.isNotEmpty) {
      final hero = spot.playerCards[spot.heroIndex];
      final combo = _handToCombo(hero);
      if (!required.contains(combo)) return false;
    }

    final excluded = params['excludedCombos'] as List<String>?;
    if (excluded != null && excluded.isNotEmpty) {
      final hero = spot.playerCards[spot.heroIndex];
      final combo = _handToCombo(hero);
      if (excluded.contains(combo)) return false;
    }

    return true;
  }

  static String _handToCombo(List<CardModel> cards) {
    if (cards.length < 2) return '';
    return '${cards[0].rank}${cards[0].suit}${cards[1].rank}${cards[1].suit}'
        .toLowerCase();
  }

  static String _streetFromBoard(int len) {
    switch (len) {
      case 4:
        return 'turn';
      case 5:
        return 'river';
      default:
        return 'flop';
    }
  }
}
