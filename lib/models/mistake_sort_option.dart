enum MistakeSortOption { count, severity }

extension MistakeSortOptionLabel on MistakeSortOption {
  String get label {
    switch (this) {
      case MistakeSortOption.severity:
        return 'По уровню';
      case MistakeSortOption.count:
      default:
        return 'По количеству';
    }
  }
}
