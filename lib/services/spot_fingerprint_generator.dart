import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/action_entry.dart';

/// Generates a stable fingerprint for a [TrainingPackSpot].
///
/// The fingerprint is based on key semantic features of the spot so that
/// logically equivalent spots produce the same hash.
class SpotFingerprintGenerator {
  const SpotFingerprintGenerator();

  /// Builds a SHA1 hash from the spot's hero/villain positions, action line,
  /// board structure and spot type.
  String generate(TrainingPackSpot spot) {
    final buffer = StringBuffer()
      ..write(spot.type)
      ..write('|')
      ..write(spot.hand.position.name)
      ..write('|')
      ..write(spot.board.join(','))
      ..write('|');

    final actions = spot.hand.actions;
    final keys = actions.keys.toList()..sort();
    for (final k in keys) {
      buffer.write('$k:');
      for (final ActionEntry a in actions[k]!) {
        buffer.write('${a.playerIndex}${a.type}${a.amount ?? ''};');
      }
      buffer.write('|');
    }

    final bytes = utf8.encode(buffer.toString());
    return sha1.convert(bytes).toString();
  }
}
