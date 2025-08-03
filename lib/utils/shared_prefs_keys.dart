/// Centralized SharedPreferences keys used across the app.
enum SharedPrefsKey {
  boosterInboxLast,
  boosterInboxTotalDate,
  boosterInboxTotalCount,
  boosterExclusionLog,
  boosterOpened,
  boosterDismissed,
  trainingPresetTags,
  trainingPresetSearch,
  trainingPresetExpanded,
  trainingPresetSort,
  trainingPresetIcmOnly,
  trainingPresetRatedOnly,
  trainingHideCompleted,
  trainingMistakesOnly,
  trainingSpotsOrder,
  trainingSpotListVisible,
  trainingPresetDifficulties,
  trainingPresetRatings,
  trainingPresetRatingSort,
  trainingSimpleSortField,
  trainingSimpleSortOrder,
  trainingCustomTagPresets,
  trainingQuickPreset,
  trainingSearchHistory,
  trainingSpotListSort,
  trainingQuickSortOption,
}

extension SharedPrefsKeyExt on SharedPrefsKey {
  /// Returns the string value for this key.
  ///
  /// [tag] is required for keys that are scoped per tag. When omitted for
  /// those keys, the base prefix is returned, allowing prefix matching.
  String asString([String? tag]) {
    switch (this) {
      case SharedPrefsKey.boosterInboxLast:
        return tag != null
            ? 'booster_inbox_last_\$tag'
            : 'booster_inbox_last_';
      case SharedPrefsKey.boosterInboxTotalDate:
        return 'booster_inbox_total_date';
      case SharedPrefsKey.boosterInboxTotalCount:
        return 'booster_inbox_total_count';
      case SharedPrefsKey.boosterExclusionLog:
        return 'booster_exclusion_log';
      case SharedPrefsKey.boosterOpened:
        return tag != null ? 'booster_opened_\$tag' : 'booster_opened_';
      case SharedPrefsKey.boosterDismissed:
        return tag != null ? 'booster_dismissed_\$tag' : 'booster_dismissed_';
      case SharedPrefsKey.trainingPresetTags:
        return 'training_preset_tags';
      case SharedPrefsKey.trainingPresetSearch:
        return 'training_preset_search';
      case SharedPrefsKey.trainingPresetExpanded:
        return 'training_preset_expanded';
      case SharedPrefsKey.trainingPresetSort:
        return 'training_preset_sort';
      case SharedPrefsKey.trainingPresetIcmOnly:
        return 'training_preset_icm_only';
      case SharedPrefsKey.trainingPresetRatedOnly:
        return 'training_preset_rated_only';
      case SharedPrefsKey.trainingHideCompleted:
        return 'training_hide_completed';
      case SharedPrefsKey.trainingMistakesOnly:
        return 'training_mistakes_only';
      case SharedPrefsKey.trainingSpotsOrder:
        return 'training_spots_order';
      case SharedPrefsKey.trainingSpotListVisible:
        return 'training_spot_list_visible';
      case SharedPrefsKey.trainingPresetDifficulties:
        return 'training_preset_difficulties';
      case SharedPrefsKey.trainingPresetRatings:
        return 'training_preset_ratings';
      case SharedPrefsKey.trainingPresetRatingSort:
        return 'training_preset_rating_sort';
      case SharedPrefsKey.trainingSimpleSortField:
        return 'training_simple_sort_field';
      case SharedPrefsKey.trainingSimpleSortOrder:
        return 'training_simple_sort_order';
      case SharedPrefsKey.trainingCustomTagPresets:
        return 'training_custom_tag_presets';
      case SharedPrefsKey.trainingQuickPreset:
        return 'training_quick_preset';
      case SharedPrefsKey.trainingSearchHistory:
        return 'training_search_history';
      case SharedPrefsKey.trainingSpotListSort:
        return 'training_spot_list_sort';
      case SharedPrefsKey.trainingQuickSortOption:
        return 'training_quick_sort_option';
    }
  }
}
