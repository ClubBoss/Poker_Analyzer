import 'package:test/test.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/generated/pack_library.g.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';

void main() {
  tearDown(() => packLibrary.clear());

  test('getPack returns empty list for unknown id', () {
    final result = PackLibraryService.instance.getPack('missing');
    expect(result, isEmpty);
  });

  test('getPack returns spots when id exists', () {
    final spot = TrainingPackSpot(id: 's1');
    packLibrary['sample'] = [spot];
    final service = PackLibraryService.instance;
    final spots = service.getPack('sample');
    expect(spots, hasLength(1));
    expect(spots.first.id, 's1');
    expect(service.getAvailablePackIds(), contains('sample'));
  });
}
