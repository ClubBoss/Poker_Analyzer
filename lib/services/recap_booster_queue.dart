class RecapBoosterQueue {
  RecapBoosterQueue._();
  static final RecapBoosterQueue instance = RecapBoosterQueue._();

  final List<String> _queue = [];

  Future<void> add(String lessonId) async {
    if (!_queue.contains(lessonId)) {
      _queue.add(lessonId);
    }
  }

  List<String> getQueue() => List.unmodifiable(_queue);

  void clear() => _queue.clear();
}
