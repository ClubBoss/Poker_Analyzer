import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MVP push/fold pack is loaded and first', () async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final pack = TrainingPackLibraryV2.instance.getById('push_fold_mvp');
    expect(pack, isNotNull);
    expect(pack!.name, 'Push/Fold Beginner Pack');
    expect(pack.audience, 'Beginner');
    expect(pack.trainingType.name, 'pushFold');
    final first = TrainingPackLibraryV2.instance.packs.first;
    expect(first.id, 'push_fold_mvp');
  });
}
