import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_index_service.dart';
import 'package:poker_analyzer/generated/pack_library.g.dart';

void main() {
  tearDown(() => packLibrary.clear());

  test('getMeta returns metadata when id exists', () {
    packLibrary['starter_pushfold_10bb'] = [];
    final service = TrainingPackIndexService.instance;
    final meta = service.getMeta('starter_pushfold_10bb');
    expect(meta, isNotNull);
    expect(meta!.title, 'Starter Push/Fold 10bb');
    final all = service.getAll();
    expect(all.map((m) => m.id), contains('starter_pushfold_10bb'));
  });

  test('getMeta returns null when id missing', () {
    final service = TrainingPackIndexService.instance;
    final meta = service.getMeta('missing');
    expect(meta, isNull);
    expect(service.getAll(), isEmpty);
  });
}
