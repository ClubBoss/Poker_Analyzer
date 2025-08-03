import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BTN cash push/fold pack loads and filters correctly', () async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final pack = TrainingPackLibraryV2.instance.getById('push_fold_btn_cash');
    expect(pack, isNotNull);
    expect(pack!.name, 'BTN Push/Fold Cash 10bb');
    expect(pack.meta['schemaVersion'], '2.0.0');
    expect(TrainingPackLibraryV2.instance.packs.first.id,
        TrainingPackLibraryV2.mvpPackId);
    final filtered = TrainingPackLibraryV2.instance
        .filterBy(tags: ['pushFold', 'btn', 'cash', 'beginner']);
    expect(filtered.map((p) => p.id), contains('push_fold_btn_cash'));
  });
}
