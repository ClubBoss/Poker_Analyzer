import 'package:shared_preferences/shared_preferences.dart';

class DebugPanelPreferences {
  static const _snapshotRetentionKey = 'snapshot_retention_enabled';
  static const _processingDelayKey = 'evaluation_processing_delay';
  static const _queueFilterKey = 'evaluation_queue_filter';
  static const _advancedFilterKey = 'evaluation_advanced_filters';
  static const _sortBySprKey = 'evaluation_sort_by_spr';
  static const _searchQueryKey = 'evaluation_search_query';

  /// Returns whether snapshot retention policy is enabled.
  Future<bool> getSnapshotRetentionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_snapshotRetentionKey) ?? true;
  }

  /// Persists snapshot retention policy state.
  Future<void> setSnapshotRetentionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_snapshotRetentionKey, value);
  }

  /// Returns evaluation processing delay in milliseconds.
  Future<int> getProcessingDelay() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_processingDelayKey) ?? 500).clamp(100, 2000);
  }

  /// Persists evaluation processing delay.
  Future<void> setProcessingDelay(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_processingDelayKey, value);
  }

  /// Returns active queue filters.
  Future<Set<String>> getQueueFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_queueFilterKey);
    final filters = list?.toSet() ?? {'pending'};
    if (filters.isEmpty) filters.add('pending');
    return filters;
  }

  /// Persists queue filters.
  Future<void> setQueueFilters(Set<String> value) async {
    if (value.isEmpty) value = {'pending'};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_queueFilterKey, value.toList());
  }

  /// Returns active advanced filters.
  Future<Set<String>> getAdvancedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_advancedFilterKey);
    return list?.toSet() ?? {};
  }

  /// Persists advanced filters.
  Future<void> setAdvancedFilters(Set<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_advancedFilterKey, value.toList());
  }

  /// Returns whether lists should be sorted by SPR.
  Future<bool> getSortBySpr() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sortBySprKey) ?? false;
  }

  /// Persists sort by SPR preference.
  Future<void> setSortBySpr(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sortBySprKey, value);
  }

  /// Returns search query string for evaluation queues.
  Future<String> getSearchQuery() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_searchQueryKey) ?? '';
  }

  /// Persists search query for evaluation queues.
  Future<void> setSearchQuery(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchQueryKey, value);
  }

  /// Clears all stored debug panel preferences.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotRetentionKey);
    await prefs.remove(_processingDelayKey);
    await prefs.remove(_queueFilterKey);
    await prefs.remove(_advancedFilterKey);
    await prefs.remove(_sortBySprKey);
    await prefs.remove(_searchQueryKey);
  }
}

