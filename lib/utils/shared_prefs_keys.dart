/// Centralized SharedPreferences keys used across the app.
class SharedPrefsKeys {
  SharedPrefsKeys._();

  static const String _boosterPrefix = 'booster';
  static String _boosterKey(String suffix) => '$_boosterPrefix_$suffix';
  static String _boosterTagKey(String type, String tag) =>
      _boosterKey('$type_$tag');

  static String boosterInboxLast(String tag) =>
      _boosterTagKey('inbox_last', tag);
  static final String boosterInboxTotalDate = _boosterKey('inbox_total_date');
  static final String boosterInboxTotalCount = _boosterKey('inbox_total_count');
  static final String boosterExclusionLog = _boosterKey('exclusion_log');

  static String boosterOpened(String tag) => _boosterTagKey('opened', tag);

  static String boosterDismissed(String tag) =>
      _boosterTagKey('dismissed', tag);

  static String targetedBoosterLast(String tag) =>
      _boosterTagKey('targeted_last', tag);

  // Training spot list keys
  static const String trainingPresetTags = 'training_preset_tags';
  static const String trainingPresetSearch = 'training_preset_search';
  static const String trainingPresetExpanded = 'training_preset_expanded';
  static const String trainingPresetSort = 'training_preset_sort';
  static const String trainingPresetIcmOnly = 'training_preset_icm_only';
  static const String trainingPresetRatedOnly = 'training_preset_rated_only';
  static const String trainingHideCompleted = 'training_hide_completed';
  static const String trainingMistakesOnly = 'training_mistakes_only';
  static const String trainingSpotsOrder = 'training_spots_order';
  static const String trainingSpotListVisible = 'training_spot_list_visible';
  static const String trainingPresetDifficulties =
      'training_preset_difficulties';
  static const String trainingPresetRatings = 'training_preset_ratings';
  static const String trainingPresetRatingSort = 'training_preset_rating_sort';
  static const String trainingSimpleSortField = 'training_simple_sort_field';
  static const String trainingSimpleSortOrder = 'training_simple_sort_order';
  static const String trainingCustomTagPresets = 'training_custom_tag_presets';
  static const String trainingQuickPreset = 'training_quick_preset';
  static const String trainingSearchHistory = 'training_search_history';
  static const String trainingSpotListSort = 'training_spot_list_sort';
  static const String trainingQuickSortOption = 'training_quick_sort_option';

  // Skill tag coverage report
  static const String skillTagCoverageReport = 'skill_tag_coverage_report';

  // Theory gap detector
  static const String theoryGapReport = 'theory_gap_report';

  // Theory auto-injector
  static const String theoryInjectReport = 'theory_inject_report';
}
