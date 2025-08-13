import 'dart:collection';

/// Simple queue of theory tags scheduled for boosters.
class TheoryBoosterQueueService {
  TheoryBoosterQueueService._();
  static final TheoryBoosterQueueService instance =
      TheoryBoosterQueueService._();

  final Queue<String> _queue = Queue<String>();

  /// Adds [tag] to the queue if not already present.
  Future<void> enqueue(String tag) async {
    final lc = tag.trim().toLowerCase();
    if (lc.isEmpty) return;
    if (_queue.contains(lc)) return;
    _queue.addLast(lc);
  }

  /// Returns queued tags.
  List<String> getQueue() => List.unmodifiable(_queue);

  void clear() => _queue.clear();
}
