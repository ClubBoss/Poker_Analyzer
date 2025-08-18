import '../models/inbox_card_model.dart';
import '../services/pinned_block_tracker_service.dart';
import '../services/theory_block_library_service.dart';
import '../widgets/theory_block_context_sheet.dart';

/// Generates inbox cards for pinned theory blocks for quick access.
class SmartPinnedBlockInboxProvider {
  SmartPinnedBlockInboxProvider({
    PinnedBlockTrackerService? tracker,
    TheoryBlockLibraryService? library,
  }) : tracker = tracker ?? PinnedBlockTrackerService.instance,
       library = library ?? TheoryBlockLibraryService.instance;

  final PinnedBlockTrackerService tracker;
  final TheoryBlockLibraryService library;

  /// Returns a list of [InboxCardModel]s representing pinned blocks.
  Future<List<InboxCardModel>> getCards() async {
    final ids = await tracker.getPinnedBlockIds();
    if (ids.isEmpty) return [];
    await library.loadAll();

    final cards = <InboxCardModel>[];
    for (final id in ids) {
      final block = library.getById(id);
      if (block == null) continue;
      cards.add(
        InboxCardModel(
          id: block.id,
          title: block.title,
          subtitle: 'You pinned this for later',
          onTap: (context) => showTheoryBlockContextSheet(context, block),
        ),
      );
    }
    return cards;
  }
}
