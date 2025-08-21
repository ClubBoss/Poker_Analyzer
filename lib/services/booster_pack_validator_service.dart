import 'package:flutter/foundation.dart';

import '../models/booster_validation_report.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';

class BoosterPackValidatorService {
  const BoosterPackValidatorService();

  BoosterValidationReport validate(TrainingPackTemplateV2 pack) {
    final errors = <String>[];
    final warnings = <String>[];
    final ids = <String>{};

    if (pack.id.trim().isEmpty) errors.add('missing_pack_id');
    if (pack.spots.isEmpty) errors.add('missing_spots');

    for (final s in pack.spots) {
      final id = s.id.trim();
      if (id.isEmpty) {
        errors.add('missing_id');
        continue;
      }
      if (!ids.add(id)) errors.add('duplicate_id:$id');
      final res = _validateSpot(s, pack.positions);
      errors.addAll(res.errors);
      warnings.addAll(res.warnings);
    }

    debugPrint(
      'BoosterPackValidatorService: ${errors.length} errors, ${warnings.length} warnings',
    );
    for (final e in errors) {
      debugPrint('Error: $e');
    }
    for (final w in warnings) {
      debugPrint('Warning: $w');
    }

    return BoosterValidationReport(
      errors: errors,
      warnings: warnings,
      isValid: errors.isEmpty,
    );
  }

  BoosterValidationReport validateAll(List<TrainingPackSpot> spots) {
    final template = TrainingPackTemplateV2(
      id: 'tmp',
      name: 'tmp',
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );
    return validate(template);
  }

  BoosterValidationReport _validateSpot(
    TrainingPackSpot spot,
    List<String> packPositions,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    if (spot.hand.heroCards.trim().isEmpty) {
      errors.add('empty_heroCards:${spot.id}');
    }
    if (spot.hand.position == HeroPosition.unknown) {
      errors.add('bad_heroPosition:${spot.id}');
    } else if (packPositions.isNotEmpty) {
      final matches = packPositions
          .map(parseHeroPosition)
          .contains(spot.hand.position);
      if (!matches) warnings.add('position_mismatch:${spot.id}');
    }

    final board = spot.board.isNotEmpty ? spot.board : spot.hand.board;
    if (board.any((c) => c.trim().isEmpty) || board.length > 5) {
      warnings.add('bad_board:${spot.id}');
    } else if (board.toSet().length != board.length) {
      warnings.add('duplicate_board:${spot.id}');
    }

    if (spot.tags.toSet().length != spot.tags.length) {
      warnings.add('duplicate_tags:${spot.id}');
    }

    if (spot.explanation != null && spot.explanation!.trim().isEmpty) {
      warnings.add('bad_explanation:${spot.id}');
    }

    return BoosterValidationReport(
      errors: errors,
      warnings: warnings,
      isValid: errors.isEmpty,
    );
  }
}
