enum SortOption {
  buyInAsc,
  buyInDesc,
  gameType,
  tournamentId,
  difficultyAsc,
  difficultyDesc,
}

enum RatingSortOrder { highFirst, lowFirst }

enum SimpleSortField { createdAt, difficulty, rating }

enum SimpleSortOrder { ascending, descending }

enum ListSortOption { dateNew, dateOld, rating, difficulty, comment }

enum QuickSortOption { id, difficulty, rating }

class FilterState {
  const FilterState({
    required this.searchText,
    required this.selectedTags,
    required this.difficultyFilters,
    required this.ratingFilters,
    required this.icmOnly,
    required this.ratedOnly,
  });

  final String searchText;
  final Set<String> selectedTags;
  final Set<int> difficultyFilters;
  final Set<int> ratingFilters;
  final bool icmOnly;
  final bool ratedOnly;
}
