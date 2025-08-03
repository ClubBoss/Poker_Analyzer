/// Centralized SharedPreferences keys used across the app.
class SharedPrefsKeys {
  SharedPrefsKeys._();

  static String boosterInboxLast(String tag) => 'booster_inbox_last_$tag';
  static const String boosterInboxTotalDate = 'booster_inbox_total_date';
  static const String boosterInboxTotalCount = 'booster_inbox_total_count';

  static const String boosterOpenedPrefix = 'booster_opened_';
  static String boosterOpened(String tag) => '${boosterOpenedPrefix}$tag';

  static const String boosterDismissedPrefix = 'booster_dismissed_';
  static String boosterDismissed(String tag) => '${boosterDismissedPrefix}$tag';

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
  static const String trainingCustomTagPresets =
      'training_custom_tag_presets';
  static const String trainingQuickPreset = 'training_quick_preset';
  static const String trainingSearchHistory = 'training_search_history';
  static const String trainingSpotListSort = 'training_spot_list_sort';
  static const String trainingQuickSortOption = 'training_quick_sort_option';
}
