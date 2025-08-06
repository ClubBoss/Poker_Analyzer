import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/v2/training_pack_spot.dart';
import '../helpers/hand_utils.dart';

/// Generates a stable fingerprint for a [TrainingPackSpot].
///
/// The fingerprint is based on key semantic features of the spot so that
/// logically equivalent spots produce the same hash.
class SpotFingerprintGenerator {
  const SpotFingerprintGenerator();

  /// Builds a SHA1 hash from the spot's hero hand, board, position and action.
  String generate(TrainingPackSpot spot) {
    final hero = handCode(spot.hand.heroCards) ?? '';
    final boardCards = (spot.board.isNotEmpty ? spot.board : spot.hand.board)
        .map((c) => c.toUpperCase())
        .join(',');
    final pos = spot.hand.position.name;
    final action = spot.correctAction ?? spot.villainAction ?? '';

    final buffer = StringBuffer()
      ..write(spot.type)
      ..write('|')
      ..write(hero)
      ..write('|')
      ..write(boardCards)
      ..write('|')
      ..write(pos)
      ..write('|')
      ..write(action);

    final bytes = utf8.encode(buffer.toString());
    return sha1.convert(bytes).toString();
  }
}
