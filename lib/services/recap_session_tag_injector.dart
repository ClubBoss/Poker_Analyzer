class RecapSessionTagInjector {
  RecapSessionTagInjector();

  static final RecapSessionTagInjector instance = RecapSessionTagInjector();

  /// Returns tags to use for sessions started from recap.
  List<String> getSessionTags() => const ['recap', 'reinforcement'];
}
