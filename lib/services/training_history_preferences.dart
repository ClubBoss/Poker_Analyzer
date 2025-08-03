import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'training_history_prefs.dart';

/// Service to manage persistence of Training History preferences.
class TrainingHistoryPreferences {
  TrainingHistoryPreferences(this._prefs);

  final SharedPreferences _prefs;

  static Future<TrainingHistoryPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return TrainingHistoryPreferences(prefs);
  }

  SortOption get sort => SortOption.values[_prefs.getInt(sortKey) ?? 0];
  Future<void> setSort(SortOption value) =>
      _prefs.setInt(sortKey, value.index);

  RatingFilter get ratingFilter =>
      RatingFilter.values[_prefs.getInt(ratingKey) ?? 0];
  Future<void> setRatingFilter(RatingFilter value) =>
      _prefs.setInt(ratingKey, value.index);

  AccuracyRange get accuracyRange =>
      AccuracyRange.values[_prefs.getInt(accuracyRangeKey) ?? 0];
  Future<void> setAccuracyRange(AccuracyRange value) =>
      _prefs.setInt(accuracyRangeKey, value.index);

  Set<String> get selectedTags =>
      _prefs.getStringList(tagKey)?.toSet() ?? {};
  Future<void> setSelectedTags(Set<String> tags) =>
      _prefs.setStringList(tagKey, tags.toList());

  Set<String> get selectedTagColors =>
      _prefs.getStringList(tagColorKey)?.toSet() ?? {};
  Future<void> setSelectedTagColors(Set<String> colors) =>
      _prefs.setStringList(tagColorKey, colors.toList());

  bool get showCharts => _prefs.getBool(showChartsKey) ?? true;
  Future<void> setShowCharts(bool value) =>
      _prefs.setBool(showChartsKey, value);

  bool get showAvgChart => _prefs.getBool(showAvgChartKey) ?? true;
  Future<void> setShowAvgChart(bool value) =>
      _prefs.setBool(showAvgChartKey, value);

  bool get showDistribution =>
      _prefs.getBool(showDistributionKey) ?? true;
  Future<void> setShowDistribution(bool value) =>
      _prefs.setBool(showDistributionKey, value);

  bool get showTrendChart =>
      _prefs.getBool(showTrendChartKey) ?? true;
  Future<void> setShowTrendChart(bool value) =>
      _prefs.setBool(showTrendChartKey, value);

  bool get hideEmptyTags => _prefs.getBool(hideEmptyTagsKey) ?? false;
  Future<void> setHideEmptyTags(bool value) =>
      _prefs.setBool(hideEmptyTagsKey, value);

  bool get sortByTag => _prefs.getBool(sortByTagKey) ?? false;
  Future<void> setSortByTag(bool value) =>
      _prefs.setBool(sortByTagKey, value);

  ChartMode get chartMode =>
      ChartMode.values[_prefs.getInt(chartModeKey) ?? 0];
  Future<void> setChartMode(ChartMode mode) =>
      _prefs.setInt(chartModeKey, mode.index);

  TagCountFilter get tagCountFilter =>
      TagCountFilter.values[_prefs.getInt(tagCountKey) ?? 0];
  Future<void> setTagCountFilter(TagCountFilter value) =>
      _prefs.setInt(tagCountKey, value.index);

  WeekdayFilter get weekdayFilter =>
      WeekdayFilter.values[_prefs.getInt(weekdayKey) ?? 0];
  Future<void> setWeekdayFilter(WeekdayFilter value) =>
      _prefs.setInt(weekdayKey, value.index);

  SessionLengthFilter get lengthFilter =>
      SessionLengthFilter.values[_prefs.getInt(lengthKey) ?? 0];
  Future<void> setLengthFilter(SessionLengthFilter value) =>
      _prefs.setInt(lengthKey, value.index);

  bool get includeChartInPdf =>
      _prefs.getBool(pdfIncludeChartKey) ?? true;
  Future<void> setIncludeChartInPdf(bool value) =>
      _prefs.setBool(pdfIncludeChartKey, value);

  bool get exportTags3Only =>
      _prefs.getBool(exportTags3OnlyKey) ?? false;
  Future<void> setExportTags3Only(bool value) =>
      _prefs.setBool(exportTags3OnlyKey, value);

  bool get exportNotesOnly =>
      _prefs.getBool(exportNotesOnlyKey) ?? false;
  Future<void> setExportNotesOnly(bool value) =>
      _prefs.setBool(exportNotesOnlyKey, value);

  DateTime? get dateFrom {
    final millis = _prefs.getInt(dateFromKey);
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;
  }

  DateTime? get dateTo {
    final millis = _prefs.getInt(dateToKey);
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (from != null) {
      await _prefs.setInt(
          dateFromKey, DateUtils.dateOnly(from).millisecondsSinceEpoch);
    } else {
      await _prefs.remove(dateFromKey);
    }
    if (to != null) {
      await _prefs.setInt(
          dateToKey, DateUtils.dateOnly(to).millisecondsSinceEpoch);
    } else {
      await _prefs.remove(dateToKey);
    }
  }

  Future<void> resetFilters() async {
    await _prefs.setInt(sortKey, SortOption.newest.index);
    await _prefs.setInt(ratingKey, RatingFilter.all.index);
    await _prefs.setInt(accuracyRangeKey, AccuracyRange.all.index);
    await _prefs.setInt(tagCountKey, TagCountFilter.any.index);
    await _prefs.setInt(weekdayKey, WeekdayFilter.all.index);
    await _prefs.setInt(lengthKey, SessionLengthFilter.any.index);
    await _prefs.setBool(sortByTagKey, false);
    await _prefs.remove(tagKey);
    await _prefs.remove(tagColorKey);
    await _prefs.remove(dateFromKey);
    await _prefs.remove(dateToKey);
  }

  Future<void> clearTagFilters() => _prefs.remove(tagKey);

  Future<void> clearColorFilters() => _prefs.remove(tagColorKey);

  Future<void> clearLengthFilter() =>
      _prefs.setInt(lengthKey, SessionLengthFilter.any.index);

  Future<void> clearAccuracyFilter() =>
      _prefs.setInt(accuracyRangeKey, AccuracyRange.all.index);

  Future<void> clearDateFilter() async {
    await _prefs.remove(dateFromKey);
    await _prefs.remove(dateToKey);
  }
}

