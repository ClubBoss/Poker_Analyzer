import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_block_model.dart';
import 'package:poker_analyzer/models/inbox_card_model.dart';
import 'package:poker_analyzer/services/pinned_block_tracker_service.dart';
import 'package:poker_analyzer/services/smart_pinned_block_inbox_provider.dart';
import 'package:poker_analyzer/services/theory_block_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('creates inbox cards for pinned blocks', () async {
    final tracker = PinnedBlockTrackerService.instance;
    await tracker.logPin('b1');
    const block = TheoryBlockModel(
      id: 'b1',
      title: 'Block One',
      nodeIds: [],
      practicePackIds: [],
    );
    final library = _FakeBlockLibrary({block.id: block});
    final provider = SmartPinnedBlockInboxProvider(
      tracker: tracker,
      library: library,
    );
    final cards = await provider.getCards();
    expect(cards.length, 1);
    final InboxCardModel card = cards.first;
    expect(card.title, 'Block One');
    expect(card.subtitle, 'You pinned this for later');
  });
}

class _FakeBlockLibrary implements TheoryBlockLibraryService {
  _FakeBlockLibrary(this._map);
  final Map<String, TheoryBlockModel> _map;

  @override
  List<TheoryBlockModel> get all => _map.values.toList();

  @override
  TheoryBlockModel? getById(String id) => _map[id];

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}
}

