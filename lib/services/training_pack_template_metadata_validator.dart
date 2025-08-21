import 'package:flutter/foundation.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

/// Validates [TrainingPackTemplateV2] metadata and spot data.
///
/// Returns a record containing lists of valid and rejected templates. Rejected
/// packs are logged with the reasons for failure.
class TrainingPackTemplateMetadataValidator {
  const TrainingPackTemplateMetadataValidator();

  ({List<TrainingPackTemplateV2> valid, List<TrainingPackTemplateV2> rejected})
      filter(List<TrainingPackTemplateV2> packs) {
    final valid = <TrainingPackTemplateV2>[];
    final rejected = <TrainingPackTemplateV2>[];
    for (final tpl in packs) {
      final errors = _validateTemplate(tpl);
      if (errors.isEmpty) {
        valid.add(tpl);
      } else {
        debugPrint(
          'TrainingPackTemplateMetadataValidator: rejected ${tpl.id}: ${errors.join(', ')}',
        );
        rejected.add(tpl);
      }
    }
    return (valid: valid, rejected: rejected);
  }

  List<String> _validateTemplate(TrainingPackTemplateV2 tpl) {
    final errors = <String>[];

    final level = tpl.meta['level'];
    if (level is! int) {
      errors.add('missing_level');
    }

    final topic = tpl.meta['topic'];
    if (topic is! String || topic.trim().isEmpty) {
      errors.add('missing_topic');
    }

    final tags = {for (final t in tpl.tags) t.toLowerCase()};
    const requiredTags = {'preflop', 'postflop', 'theory'};
    if (tags.intersection(requiredTags).isEmpty) {
      errors.add('missing_core_tag');
    }

    if (tpl.spotCount != tpl.spots.length) {
      errors.add('spotCount_mismatch');
    }

    for (final s in tpl.spots) {
      if (_invalidSpot(s)) {
        errors.add('invalid_spot:${s.id}');
        break;
      }
    }

    return errors;
  }

  bool _invalidSpot(TrainingPackSpot spot) {
    if (spot.id.trim().isEmpty) return true;
    if (spot.hand.heroCards.trim().isEmpty) return true;
    if (spot.heroOptions.isEmpty) return true;
    if (spot.heroOptions.any((o) => o.trim().isEmpty)) return true;
    return false;
  }
}
