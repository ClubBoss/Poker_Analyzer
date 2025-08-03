import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/shared_prefs_keys.dart';
import 'training_spot_list_models.dart';

class TrainingSpotFilters {
  TrainingSpotFilters({
    this.searchText = '',
    Set<String>? selectedTags,
    this.tagFiltersExpanded = true,
    this.icmOnly = false,
    this.ratedOnly = false,
    this.hideCompleted = false,
    this.listVisible = true,
    Set<int>? difficultyFilters,
    Set<int>? ratingFilters,
    this.ratingSort,
    this.simpleSortField,
    this.simpleSortOrder = SimpleSortOrder.ascending,
    this.listSort,
    this.quickSort,
    this.sortOption,
    this.mistakesOnly = false,
    this.activeQuickPreset,
  })  : selectedTags = selectedTags ?? <String>{},
        difficultyFilters = difficultyFilters ?? <int>{},
        ratingFilters = ratingFilters ?? <int>{};

  String searchText;
  final Set<String> selectedTags;
  bool tagFiltersExpanded;
  bool icmOnly;
  bool ratedOnly;
  bool hideCompleted;
  bool listVisible;
  final Set<int> difficultyFilters;
  final Set<int> ratingFilters;
  RatingSortOrder? ratingSort;
  SimpleSortField? simpleSortField;
  SimpleSortOrder simpleSortOrder;
  ListSortOption? listSort;
  QuickSortOption? quickSort;
  SortOption? sortOption;
  bool mistakesOnly;
  String? activeQuickPreset;

  static Future<TrainingSpotFilters> load({required bool defaultIcmOnly}) async {
    final prefs = await SharedPreferences.getInstance();
    final tags = prefs.getStringList(SharedPrefsKeys.trainingPresetTags) ?? <String>[];
    final search = prefs.getString(SharedPrefsKeys.trainingPresetSearch) ?? '';
    final expanded = prefs.getBool(SharedPrefsKeys.trainingPresetExpanded) ?? true;
    final listVisible = prefs.getBool(SharedPrefsKeys.trainingSpotListVisible) ?? true;
    final sortName = prefs.getString(SharedPrefsKeys.trainingPresetSort);
    final ratingSortName = prefs.getString(SharedPrefsKeys.trainingPresetRatingSort);
    final simpleFieldName = prefs.getString(SharedPrefsKeys.trainingSimpleSortField);
    final simpleOrderName = prefs.getString(SharedPrefsKeys.trainingSimpleSortOrder);
    final listSortName = prefs.getString(SharedPrefsKeys.trainingSpotListSort);
    final quickSortName = prefs.getString(SharedPrefsKeys.trainingQuickSortOption);
    final icmOnly = prefs.getBool(SharedPrefsKeys.trainingPresetIcmOnly) ?? defaultIcmOnly;
    final ratedOnly = prefs.getBool(SharedPrefsKeys.trainingPresetRatedOnly) ?? false;
    final hideCompleted = prefs.getBool(SharedPrefsKeys.trainingHideCompleted) ?? false;
    final mistakesOnly = prefs.getBool(SharedPrefsKeys.trainingMistakesOnly) ?? false;
    final diffs = prefs.getStringList(SharedPrefsKeys.trainingPresetDifficulties);
    final ratings = prefs.getStringList(SharedPrefsKeys.trainingPresetRatings);
    final quickPreset = prefs.getString(SharedPrefsKeys.trainingQuickPreset);

    SortOption? sortOption;
    if (sortName != null && sortName.isNotEmpty) {
      try {
        sortOption = SortOption.values.byName(sortName);
      } catch (_) {}
    }
    RatingSortOrder? ratingSort;
    if (ratingSortName != null && ratingSortName.isNotEmpty) {
      try {
        ratingSort = RatingSortOrder.values.byName(ratingSortName);
      } catch (_) {}
    }
    SimpleSortField? simpleField;
    if (simpleFieldName != null && simpleFieldName.isNotEmpty) {
      try {
        simpleField = SimpleSortField.values.byName(simpleFieldName);
      } catch (_) {}
    }
    SimpleSortOrder simpleOrder = SimpleSortOrder.ascending;
    if (simpleOrderName != null && simpleOrderName.isNotEmpty) {
      try {
        simpleOrder = SimpleSortOrder.values.byName(simpleOrderName);
      } catch (_) {}
    }
    ListSortOption? listSort;
    if (listSortName != null && listSortName.isNotEmpty) {
      try {
        listSort = ListSortOption.values.byName(listSortName);
      } catch (_) {}
    }
    QuickSortOption? quickSort;
    if (quickSortName != null && quickSortName.isNotEmpty) {
      try {
        quickSort = QuickSortOption.values.byName(quickSortName);
      } catch (_) {}
    }

    final difficultyFilters = <int>{
      if (diffs != null)
        for (final d in diffs.map(int.tryParse).whereType<int>().where((d) => d >= 1 && d <= 5)) d,
    };
    final ratingFilters = <int>{
      if (ratings != null)
        for (final r in ratings.map(int.tryParse).whereType<int>().where((r) => r >= 1 && r <= 5)) r,
    };

    return TrainingSpotFilters(
      searchText: search,
      selectedTags: tags.toSet(),
      tagFiltersExpanded: expanded,
      icmOnly: icmOnly,
      ratedOnly: ratedOnly,
      hideCompleted: hideCompleted,
      mistakesOnly: mistakesOnly,
      listVisible: listVisible,
      difficultyFilters: difficultyFilters,
      ratingFilters: ratingFilters,
      ratingSort: ratingSort,
      simpleSortField: simpleField,
      simpleSortOrder: simpleOrder,
      listSort: listSort,
      quickSort: quickSort,
      sortOption: sortOption,
      activeQuickPreset: quickPreset,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(SharedPrefsKeys.trainingPresetTags, selectedTags.toList());
    await prefs.setString(SharedPrefsKeys.trainingPresetSearch, searchText);
    await prefs.setBool(SharedPrefsKeys.trainingPresetExpanded, tagFiltersExpanded);
    await prefs.setBool(SharedPrefsKeys.trainingPresetIcmOnly, icmOnly);
    await prefs.setBool(SharedPrefsKeys.trainingPresetRatedOnly, ratedOnly);
    await prefs.setBool(SharedPrefsKeys.trainingHideCompleted, hideCompleted);
    await prefs.setBool(SharedPrefsKeys.trainingMistakesOnly, mistakesOnly);
    await prefs.setBool(SharedPrefsKeys.trainingSpotListVisible, listVisible);
    if (difficultyFilters.isNotEmpty) {
      await prefs.setStringList(
        SharedPrefsKeys.trainingPresetDifficulties,
        difficultyFilters.map((e) => e.toString()).toList(),
      );
    } else {
      await prefs.remove(SharedPrefsKeys.trainingPresetDifficulties);
    }
    if (ratingFilters.isNotEmpty) {
      await prefs.setStringList(
        SharedPrefsKeys.trainingPresetRatings,
        ratingFilters.map((e) => e.toString()).toList(),
      );
    } else {
      await prefs.remove(SharedPrefsKeys.trainingPresetRatings);
    }
    if (ratingSort != null) {
      await prefs.setString(SharedPrefsKeys.trainingPresetRatingSort, ratingSort!.name);
    } else {
      await prefs.remove(SharedPrefsKeys.trainingPresetRatingSort);
    }
    if (simpleSortField != null) {
      await prefs.setString(SharedPrefsKeys.trainingSimpleSortField, simpleSortField!.name);
    } else {
      await prefs.remove(SharedPrefsKeys.trainingSimpleSortField);
    }
    await prefs.setString(SharedPrefsKeys.trainingSimpleSortOrder, simpleSortOrder.name);
    if (listSort != null) {
      await prefs.setString(SharedPrefsKeys.trainingSpotListSort, listSort!.name);
    } else {
      await prefs.remove(SharedPrefsKeys.trainingSpotListSort);
    }
    if (quickSort != null) {
      await prefs.setString(SharedPrefsKeys.trainingQuickSortOption, quickSort!.name);
    } else {
      await prefs.remove(SharedPrefsKeys.trainingQuickSortOption);
    }
    if (sortOption != null) {
      await prefs.setString(SharedPrefsKeys.trainingPresetSort, sortOption!.name);
    } else {
      await prefs.remove(SharedPrefsKeys.trainingPresetSort);
    }
    if (activeQuickPreset != null) {
      await prefs.setString(SharedPrefsKeys.trainingQuickPreset, activeQuickPreset!);
    } else {
      await prefs.remove(SharedPrefsKeys.trainingQuickPreset);
    }
  }
}
