import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pinned_block_tracker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logs pin and unpin events', () async {
    final service = PinnedBlockTrackerService.instance;

    await service.logPin('b1');
    expect(await service.isPinned('b1'), isTrue);
    final time = await service.getLastPinTime('b1');
    expect(time, isNotNull);

    await service.logUnpin('b1');
    expect(await service.isPinned('b1'), isFalse);
    expect(await service.getLastPinTime('b1'), time);
  });

  test('returns all pinned block ids', () async {
    final service = PinnedBlockTrackerService.instance;

    await service.logPin('a');
    await service.logPin('b');
    await service.logUnpin('a');

    final ids = await service.getPinnedBlockIds();
    expect(ids, ['b']);
  });
}
