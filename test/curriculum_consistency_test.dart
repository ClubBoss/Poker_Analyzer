import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'tooling/curriculum_ids.dart';
import 'lib/packs/core_starting_hands_loader.dart';
import 'lib/ui/session_player/models.dart';

void main() {
  test('curriculum ids stay consistent with status and stub loader', () {
    final ids = List<String>.from(kCurriculumModuleIds);

    expect(
      ids.length,
      ids.toSet().length,
      reason: 'kCurriculumModuleIds has duplicates',
    );

    final status =
        jsonDecode(File('curriculum_status.json').readAsStringSync())
            as Map<String, dynamic>;
    final done = (status['modules_done'] as List).cast<String>();

    final extras = done.where((id) => !ids.contains(id)).toList();
    expect(
      extras,
      isEmpty,
      reason: 'modules_done contains unknown ids: $extras',
    );

    final spots = loadCoreStartingHandsStub();
    expect(
      spots.length,
      1,
      reason: 'core starting hands stub should load 1 spot',
    );
    expect(spots.single.kind, SpotKind.l1_core_call_vs_price);
  });
}
