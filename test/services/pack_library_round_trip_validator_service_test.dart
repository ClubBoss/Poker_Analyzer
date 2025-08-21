import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/pack_library_round_trip_validator_service.dart';
import 'package:poker_analyzer/services/training_pack_library_exporter.dart';
import 'package:poker_analyzer/services/training_pack_library_importer.dart';

TrainingPackModel buildPack() {
  final spot = TrainingPackSpot(
    id: 's1',
    hand: HandData(heroCards: 'AhAd', position: HeroPosition.btn),
    board: ['As', 'Kd', 'Qh'],
  );
  return TrainingPackModel(
    id: 'p1',
    title: 'Pack 1',
    spots: [spot],
    tags: ['tag1'],
  );
}

class TagTamperingImporter extends TrainingPackLibraryImporter {
  @override
  List<TrainingPackModel> importFromMap(Map<String, String> files) {
    final packs = super.importFromMap(files);
    if (packs.isNotEmpty) {
      packs.first.tags.add('extra');
    }
    return packs;
  }
}

class BrokenExporter extends TrainingPackLibraryExporter {
  @override
  Map<String, String> exportToMap(List<TrainingPackModel> packs) {
    final map = <String, String>{};
    for (final p in packs) {
      map['${p.id}.yaml'] = 'id: ${p.id}\n'
          'title: ${p.title}\n'
          'spots:\n'
          '  - 123\n';
    }
    return map;
  }
}

void main() {
  test('returns success when round trip matches', () {
    final service = PackLibraryRoundTripValidatorService();
    final pack = buildPack();
    final result = service.validate([pack]);
    expect(result.success, isTrue);
    expect(result.errors, isEmpty);
  });

  test('detects tag mismatches', () {
    final service = PackLibraryRoundTripValidatorService(
      importer: TagTamperingImporter(),
    );
    final pack = buildPack();
    final result = service.validate([pack]);
    expect(result.success, isFalse);
    expect(result.errors, contains('Pack p1: tags mismatch'));
  });

  test('reports structural issues in spot serialization', () {
    final service = PackLibraryRoundTripValidatorService(
      exporter: BrokenExporter(),
    );
    final pack = buildPack();
    final result = service.validate([pack]);
    expect(result.success, isFalse);
    expect(result.errors.any((e) => e.contains('spot is not a map')), isTrue);
  });
}
