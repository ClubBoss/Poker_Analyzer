import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../asset_manifest.dart';
import '../theme/app_colors.dart';

import '../helpers/color_utils.dart';
import '../services/template_storage_service.dart';
import '../models/training_pack_template.dart';
import '../models/training_pack_template_model.dart';
import '../models/v2/training_pack_template.dart' as v2;
import '../services/training_pack_sort_engine.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/training_type_filter_service.dart';
import '../utils/template_difficulty.dart';
import '../services/training_session_service.dart';
import '../services/training_session_launcher.dart';
import 'training_session_screen.dart';
import 'create_pack_from_template_screen.dart';
import 'create_template_screen.dart';
import 'template_hands_editor_screen.dart';
import 'template_preview_dialog.dart';
import '../widgets/sync_status_widget.dart';
import 'session_history_screen.dart';
import 'v2/training_pack_template_editor_screen.dart';
import '../repositories/training_pack_preset_repository.dart';
import '../models/v2/training_pack_preset.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/bulk_evaluator_service.dart';
import '../utils/template_coverage_utils.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_pack_storage_service.dart';
import '../services/daily_pack_service.dart';
import '../services/motivation_service.dart';
import 'mistake_review_screen.dart';
import '../services/tag_cache_service.dart';
import '../services/recommended_pack_service.dart';
import '../services/smart_pack_suggestion_engine.dart';
import '../services/training_topic_suggestion_engine.dart';
import '../services/pack_recommendation_engine.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_log.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_type_stats_service.dart';
import '../services/pack_unlocking_rules_engine.dart';
import '../services/user_profile_preference_service.dart';
import '../app_config.dart';
import 'package:intl/intl.dart';
import 'training_stats_screen.dart';
import '../helpers/category_translations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/user_action_logger.dart';
import '../widgets/category_section.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../widgets/pack_suggestion_banner.dart';
import '../widgets/suggestion_banner.dart';
import '../services/weak_training_type_detector.dart';
import '../widgets/training_gap_prompt_banner.dart';
import '../widgets/training_type_gap_prompt_banner.dart';
import '../widgets/suggested_pack_tile.dart';
import 'pack_suggestion_preview_screen.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/tag_mastery_service.dart';
import '../widgets/sample_pack_preview_button.dart';
import '../widgets/sample_pack_preview_tooltip.dart';
import '../widgets/pack_resume_banner.dart';
import '../services/training_pack_sampler.dart';
import 'v2/training_pack_play_screen.dart';
import '../widgets/pack_progress_overlay.dart';
import '../widgets/pack_unlock_requirement_badge.dart';
import '../widgets/library_pack_badge_renderer.dart';
import '../services/pack_sorting_engine.dart';

class TemplateLibraryScreen extends StatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  static const _key = 'lib_game_type';
  static const _sortKey = 'lib_sort';
  static const _sortModeKey = 'lib_sort_mode';
  static const _favKey = 'fav_tpl_ids';
  static const _needsPracticeKey = 'lib_needs_practice';
  static const _needsRepetitionKey = 'lib_needs_repetition';
  static const _needsPracticeOnlyKey = 'lib_needs_practice_only';
  static const _favOnlyKey = 'lib_fav_only';
  static const _recentOnlyKey = 'lib_recent_only';
  static const _inProgressOnlyKey = 'lib_in_progress_only';
  static const _hideCompletedKey = 'lib_hide_completed';
  static const _completedOnlyKey = 'lib_completed_only';
  static const _popularOnlyKey = 'lib_popular_only';
  static const _recommendedOnlyKey = 'lib_recommended_only';
  static const _masteredOnlyKey = 'lib_mastered_only';
  static const _availableOnlyKey = 'lib_available_only';
  static const _weakOnlyKey = 'lib_weak_only';
  static const _effectivenessSortKey = 'lib_effectiveness_sort';
  static const _compactKey = 'lib_compact_mode';
  static const _pinKey = 'lib_pinned';
  static const _previewCompletedKey = 'lib_preview_completed';
  static const _selTagsKey = 'lib_sel_tags';
  static const _selCatsKey = 'lib_sel_cats';
  static const _diffKey = 'lib_difficulty_filter';
  static const _audienceKey = 'lib_audience_filter';
  static const _trainingTypeKey = 'lib_training_type';
  static const _streetKey = 'lib_target_streets';
  static const _actTagsKey = 'lib_act_tags';
  static const _actCatsKey = 'lib_act_cats';
  static const _lastCatKey = 'lib_last_selected_category';
  static const _recTagKey = 'recommendedTagOfTheDay';
  static const _recTagDateKey = 'recommendedTagOfTheDayDate';
  static const kStarterTag = 'starter';
  static const kFeaturedTag = 'featured';
  static const kSortEdited = 'edited';
  static const kSortSpots = 'spots';
  static const kSortName = 'name';
  static const kSortProgress = 'progress';
  static const kSortInProgress = 'resume';
  static const kSortCoverage = 'coverage';
  static const kSortCombinedTrending = 'combinedTrending';
  static const _libSortKey = 'lib_pack_sort';
  static const kLibSortProgress = 'lib_progress';
  static const kLibSortAccuracy = 'lib_accuracy';
  static const kLibSortLastTrained = 'lib_last_trained';
  static const _sortIcons = {
    kSortEdited: Icons.update,
    kSortSpots: Icons.format_list_numbered,
    kSortName: Icons.sort_by_alpha,
    kSortProgress: Icons.bar_chart,
    kSortInProgress: Icons.play_arrow,
    kSortCoverage: Icons.layers,
    kSortCombinedTrending: Icons.local_fire_department,
  };
  static final _manifestFuture = AssetManifest.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _listCtrl = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};
  String _filter = 'all';
  String _sort = kSortEdited;
  SortMode _sortMode = SortMode.recent;
  bool _effectivenessSort = false;
  bool _needsPractice = false;
  bool _loadingNeedsPractice = false;
  final Set<String> _needsPracticeIds = {};
  bool _needsRepetition = false;
  bool _loadingNeedsRepetition = false;
  final Set<String> _needsRepetitionIds = {};
  bool _needsPracticeOnly = false;
  bool _loadingNeedsPracticeOnly = false;
  final Set<String> _needsPracticeOnlyIds = {};
  final Set<String> _favorites = {};
  final Set<String> _pinned = {};
  final Set<String> _previewCompleted = {};
  final Set<String> _autoSampled = {};
  bool _favoritesOnly = false;
  bool _inProgressOnly = false;
  bool _showRecent = true;
  bool _hideCompleted = false;
  bool _completedOnly = false;
  bool _popularOnly = false;
  bool _recommendedOnly = false;
  bool _masteredOnly = false;
  bool _availableOnly = false;
  bool _weakOnly = false;
  bool _compactMode = false;
  final Set<String> _selectedTags = {};
  final Set<String> _selectedCategories = {};
  final Set<String> _activeTags = {};
  final Set<String> _activeCategories = {};
  final Set<int> _difficultyFilters = {};
  String _audienceFilter = 'all';
  TrainingType? _trainingType;
  final Set<String> _streetFilters = {};
  bool _importing = false;
  String _dailyQuote = '';
  List<String> _libraryTags = [];
  List<v2.TrainingPackTemplate> _librarySorted = [];
  String _librarySort = kLibSortProgress;

  List<TrainingPackTemplate> _recent = [];
  List<TrainingPackTemplate> _popular = [];
  List<String> _popularIds = [];
  List<TrainingPackTemplate> _newPacks = [];
  final Map<String, TrainingPackStat?> _stats = {};
  final Map<String, int> _playCounts = {};
  final Map<String, int> _handsCompleted = {};
  List<String> _weakCategories = [];
  String? _weakCategory;
  v2.TrainingPackTemplate? _weakCategoryPack;
  final Set<String> _mastered = {};
  final Map<String, bool> _packUnlocked = {};
  final Map<String, String?> _lockReasons = {};
  Map<TrainingType, double> _typeCompletion = {};
  TrainingType? _weakestType;
  Set<String> _weakTags = {};
  final Map<String, String> _weakTagMap = {};
  final Map<String, String> _weakLibTagMap = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferStarter());
    _init();
    MotivationService.getDailyQuote().then((q) {
      if (mounted) setState(() => _dailyQuote = q);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPreviewCompleted();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    await UserProfilePreferenceService.instance.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    PackUnlockingRulesEngine.instance.devOverride =
        kDebugMode && appConfig.devUnlockOverride;
    final counts = <String, int>{};
    for (final t in PackLibraryLoaderService.instance.library) {
      for (final tag in t.tags) {
        counts.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    _libraryTags = counts.keys.toList()
      ..sort((a, b) {
        final ca = counts[a]!;
        final cb = counts[b]!;
        final r = cb.compareTo(ca);
        return r == 0 ? a.compareTo(b) : r;
      });
    await _load(prefs);
    _applyProfilePreferences();
    await _autoImport(prefs);
    await _loadPlayCounts();
    await _updatePopular();
    await _updateNewPacks();
    await _updateRecent();
    await _loadStats();
    await _updateUnlockStatus();
    await _loadHandsCompleted();
    await _loadPreviewCompleted();
    await _loadWeakCategories();
    await _detectWeakCategory();
    await _loadTypeStats();
    await _loadWeakTags();
    await TrainingPackSortEngine.instance
        .preloadProgress(PackLibraryLoaderService.instance.library);
    await _updateLibrarySorted();
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  Future<void> _maybeOfferStarter() async {
    final hands = context.read<SavedHandManagerService>().hands;
    if (hands.isNotEmpty) return;
    final start = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _StarterTrainingDialog(),
    );
    if (start == true && mounted) {
      final tpl = await context
          .read<TrainingPackTemplateStorageService>()
          .loadBuiltinTemplate('starter_btn_vs_bb');
      await const TrainingSessionLauncher().launch(tpl);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    setState(() {
      _filter = prefs.getString(_key) ?? 'all';
      _sort = prefs.getString(_sortKey) ?? kSortEdited;
      final modeIndex = prefs.getInt(_sortModeKey) ?? SortMode.recent.index;
      _sortMode = SortMode.values[modeIndex];
      _librarySort = prefs.getString(_libSortKey) ?? kLibSortProgress;
      _effectivenessSort = prefs.getBool(_effectivenessSortKey) ?? false;
      _favorites
        ..clear()
        ..addAll(prefs.getStringList(_favKey) ?? []);
      _needsPractice = prefs.getBool(_needsPracticeKey) ?? false;
      _needsRepetition = prefs.getBool(_needsRepetitionKey) ?? false;
      _needsPracticeOnly = prefs.getBool(_needsPracticeOnlyKey) ?? false;
      _favoritesOnly = prefs.getBool(_favOnlyKey) ?? false;
      _selectedTags
        ..clear()
        ..addAll(prefs.getStringList(_selTagsKey) ?? []);
      _selectedCategories
        ..clear()
        ..addAll(prefs.getStringList(_selCatsKey) ?? []);
      _activeTags
        ..clear()
        ..addAll(prefs.getStringList(_actTagsKey) ?? []);
      _activeCategories
        ..clear()
        ..addAll(prefs.getStringList(_actCatsKey) ?? []);
      if (_activeCategories.isEmpty) {
        final c = prefs.getString(_lastCatKey);
        if (c != null && c.isNotEmpty) _activeCategories.add(c);
      }
      _audienceFilter = prefs.getString(_audienceKey) ?? 'all';
      final tName = prefs.getString(_trainingTypeKey);
      if (tName != null && tName.isNotEmpty) {
        try {
          _trainingType =
              TrainingType.values.firstWhere((e) => e.name == tName);
        } catch (_) {
          _trainingType = null;
        }
      } else {
        _trainingType = null;
      }
      _streetFilters
        ..clear()
        ..addAll(prefs.getStringList(_streetKey) ?? []);
      if (_streetFilters.isEmpty) {
        final legacy = prefs.getString('lib_target_street');
        if (legacy != null && legacy.isNotEmpty) _streetFilters.add(legacy);
      }
      _difficultyFilters
        ..clear()
        ..addAll(
            prefs.getStringList(_diffKey)?.map(int.tryParse).whereType<int>() ??
                []);
      _showRecent = prefs.getBool(_recentOnlyKey) ?? true;
      _inProgressOnly = prefs.getBool(_inProgressOnlyKey) ?? false;
      _hideCompleted = prefs.getBool(_hideCompletedKey) ?? false;
      _completedOnly = prefs.getBool(_completedOnlyKey) ?? false;
      _popularOnly = prefs.getBool(_popularOnlyKey) ?? false;
      _recommendedOnly = prefs.getBool(_recommendedOnlyKey) ?? false;
      _masteredOnly = prefs.getBool(_masteredOnlyKey) ?? false;
      _availableOnly = prefs.getBool(_availableOnlyKey) ?? false;
      _weakOnly = prefs.getBool(_weakOnlyKey) ?? false;
      _compactMode = prefs.getBool(_compactKey) ?? false;
      _pinned
        ..clear()
        ..addAll(prefs.getStringList(_pinKey) ?? []);
      _previewCompleted
        ..clear()
        ..addAll(prefs.getStringList(_previewCompletedKey) ?? []);
    });
    final cloud = context.read<CloudSyncService>();
    final remoteRaw = await cloud.load(_favKey);
    List<String> remote = [];
    try {
      if (remoteRaw != null) remote = List<String>.from(jsonDecode(remoteRaw));
    } catch (_) {}
    final before = {..._favorites};
    _favorites.addAll(remote);
    final merged = _favorites.toList()..sort();
    if (!setEquals(before, _favorites)) {
      await prefs.setStringList(_favKey, merged);
    }
    if (!setEquals(remote.toSet(), _favorites)) {
      unawaited(cloud.save(_favKey, jsonEncode(merged)).catchError((_) {}));
    }
    if (_needsPractice) _updateNeedsPractice(true);
    if (_needsRepetition) _updateNeedsRepetition(true);
    if (_needsPracticeOnly) _updateNeedsPracticeOnly(true);
  }

  void _applyProfilePreferences() {
    final profile = UserProfilePreferenceService.instance;
    setState(() {
      if (_activeTags.isEmpty && profile.preferredTags.isNotEmpty) {
        _activeTags.addAll(profile.preferredTags);
      }
      if (_audienceFilter == 'all' && profile.preferredAudiences.isNotEmpty) {
        _audienceFilter = profile.preferredAudiences.first;
      }
      if (_difficultyFilters.isEmpty &&
          profile.preferredDifficulties.isNotEmpty) {
        _difficultyFilters.addAll(profile.preferredDifficulties);
      }
    });
  }

  Future<void> _setFilter(String value) async {
    setState(() => _filter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == 'all') {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value);
    }
  }

  Future<void> _setSort(String value) async {
    setState(() => _sort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, value);
  }

  Future<void> _setSortMode(SortMode mode) async {
    setState(() => _sortMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortModeKey, mode.index);
  }

  Future<void> _setLibrarySort(String value) async {
    setState(() => _librarySort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_libSortKey, value);
    unawaited(_updateLibrarySorted());
  }

  Future<void> _updateNeedsPractice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_needsPracticeKey, value);
    setState(() {
      _needsPractice = value;
      if (!value) _needsPracticeIds.clear();
    });
    if (!value) return;
    setState(() => _loadingNeedsPractice = true);
    final templates = context.read<TemplateStorageService>().templates;
    final ids = <String>{};
    for (final t in templates) {
      final acc =
          (await TrainingPackStatsService.getStats(t.id))?.accuracy ?? 1.0;
      if (acc < .8) ids.add(t.id);
    }
    if (!mounted) return;
    setState(() {
      _needsPracticeIds
        ..clear()
        ..addAll(ids);
      _loadingNeedsPractice = false;
    });
  }

  Future<void> _updateNeedsRepetition(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_needsRepetitionKey, value);
    setState(() {
      _needsRepetition = value;
      if (!value) _needsRepetitionIds.clear();
    });
    if (!value) return;
    setState(() => _loadingNeedsRepetition = true);
    final templates = context.read<TemplateStorageService>().templates;
    final now = DateTime.now();
    final ids = <String>{};
    for (final t in templates) {
      final stat = await TrainingPackStatsService.getStats(t.id);
      final acc = stat?.accuracy ?? 1.0;
      if (acc >= .9) continue;
      DateTime? last;
      final s = prefs.getString('last_trained_tpl_${t.id}');
      if (s != null) last = DateTime.tryParse(s);
      last ??= stat?.last;
      if (last != null && now.difference(last).inDays > 7) ids.add(t.id);
    }
    if (!mounted) return;
    setState(() {
      _needsRepetitionIds
        ..clear()
        ..addAll(ids);
      _loadingNeedsRepetition = false;
    });
  }

  Future<void> _updateNeedsPracticeOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_needsPracticeOnlyKey, value);
    setState(() {
      _needsPracticeOnly = value;
      if (!value) _needsPracticeOnlyIds.clear();
    });
    if (!value) return;
    setState(() => _loadingNeedsPracticeOnly = true);
    final templates = context.read<TemplateStorageService>().templates;
    final ids = <String>{};
    for (final t in templates) {
      final stat = await TrainingPackStatsService.getStats(t.id);
      final acc = stat?.accuracy ?? 1.0;
      final ev = stat == null
          ? 100.0
          : (stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct);
      final icm = stat == null
          ? 100.0
          : (stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct);
      if (acc < .6 || ev < 60 || icm < 60) ids.add(t.id);
    }
    if (!mounted) return;
    setState(() {
      _needsPracticeOnlyIds
        ..clear()
        ..addAll(ids);
      _loadingNeedsPracticeOnly = false;
    });
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      if (!_favorites.add(id)) {
        _favorites.remove(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    final list = _favorites.toList()..sort();
    await prefs.setStringList(_favKey, list);
    unawaited(context
        .read<CloudSyncService>()
        .save(_favKey, jsonEncode(list))
        .catchError((_) {}));
  }

  Future<void> _togglePinned(String id) async {
    setState(() {
      if (!_pinned.add(id)) {
        _pinned.remove(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pinKey, _pinned.toList());
  }

  Future<void> _setFavoritesOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_favOnlyKey, value);
    setState(() => _favoritesOnly = value);
  }

  Future<void> _toggleTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_selectedTags.add(tag)) _selectedTags.remove(tag);
    if (_selectedTags.isEmpty) {
      await prefs.remove(_selTagsKey);
    } else {
      await prefs.setStringList(_selTagsKey, _selectedTags.toList());
    }
    setState(() {});
  }

  Future<void> _toggleCategory(String cat) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_selectedCategories.add(cat)) _selectedCategories.remove(cat);
    if (_selectedCategories.isEmpty) {
      await prefs.remove(_selCatsKey);
    } else {
      await prefs.setStringList(_selCatsKey, _selectedCategories.toList());
    }
    setState(() {});
  }

  Future<void> _setActiveTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeTags.contains(tag)) {
      _activeTags.clear();
      await prefs.remove(_actTagsKey);
    } else {
      _activeTags
        ..clear()
        ..add(tag);
      await prefs.setStringList(_actTagsKey, [tag]);
      _activeCategories.clear();
      await prefs.remove(_actCatsKey);
    }
    await UserProfilePreferenceService.instance.setPreferredTags(_activeTags);
    setState(() {});
  }

  Future<void> _toggleActiveTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_activeTags.add(tag)) _activeTags.remove(tag);
    if (_activeTags.isEmpty) {
      await prefs.remove(_actTagsKey);
    } else {
      await prefs.setStringList(_actTagsKey, _activeTags.toList());
    }
    await UserProfilePreferenceService.instance.setPreferredTags(_activeTags);
    setState(() {});
  }

  Future<void> _clearActiveTags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_actTagsKey);
    _activeTags.clear();
    await UserProfilePreferenceService.instance.setPreferredTags(_activeTags);
    setState(() {});
  }

  Future<void> _setActiveCategory(String cat) async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeCategories.contains(cat)) {
      _activeCategories.clear();
      await prefs.remove(_actCatsKey);
      await prefs.remove(_lastCatKey);
    } else {
      _activeCategories
        ..clear()
        ..add(cat);
      await prefs.setStringList(_actCatsKey, [cat]);
      await prefs.setString(_lastCatKey, cat);
      _activeTags.clear();
      await prefs.remove(_actTagsKey);
    }
    setState(() {});
  }

  Future<void> _clearActiveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_actTagsKey);
    await prefs.remove(_actCatsKey);
    await prefs.remove(_lastCatKey);
    _activeTags.clear();
    _activeCategories.clear();
    await UserProfilePreferenceService.instance.setPreferredTags(_activeTags);
    setState(() {});
  }

  Future<void> _setActiveTagForce(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    _activeTags
      ..clear()
      ..add(tag);
    await prefs.setStringList(_actTagsKey, [tag]);
    _activeCategories.clear();
    await prefs.remove(_actCatsKey);
    await UserProfilePreferenceService.instance.setPreferredTags(_activeTags);
    setState(() {});
  }

  Future<void> _showRecommendedTopic() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = prefs.getString(_recTagDateKey);
    final storedTag = prefs.getString(_recTagKey);
    String? tag;
    if (dateStr != null && storedTag != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        tag = storedTag;
      }
    }
    tag ??= await const TrainingTopicSuggestionEngine().suggestNextTag();
    if (tag == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет подходящих тем для рекомендации')),
        );
      }
      return;
    }
    await prefs.setString(_recTagKey, tag);
    await prefs.setString(_recTagDateKey,
        DateTime(now.year, now.month, now.day).toIso8601String());
    await _setActiveTagForce(tag);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToFirstWithTag(tag));
  }

  void _scrollToFirstWithTag(String tag) {
    final templates = context.read<TemplateStorageService>().templates;
    final filtered = _applyFilters([...templates]);
    final sorted = _applySorting(filtered);
    final tpl = sorted.firstWhereOrNull((t) => t.tags.contains(tag));
    final key = tpl == null ? null : _itemKeys[tpl.id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _toggleDifficulty(int level) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_difficultyFilters.add(level)) {
      _difficultyFilters.remove(level);
    }
    if (_difficultyFilters.isEmpty) {
      await prefs.remove(_diffKey);
    } else {
      await prefs.setStringList(
          _diffKey, _difficultyFilters.map((e) => e.toString()).toList());
    }
    await UserProfilePreferenceService.instance
        .setPreferredDifficulties(_difficultyFilters);
    setState(() {});
  }

  Future<void> _setAudience(String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == 'all') {
      await prefs.remove(_audienceKey);
    } else {
      await prefs.setString(_audienceKey, value);
    }
    await UserProfilePreferenceService.instance
        .setPreferredAudiences(value == 'all' ? {} : {value});
    setState(() => _audienceFilter = value);
  }

  Future<void> _setTrainingType(TrainingType? type) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == null) {
      await prefs.remove(_trainingTypeKey);
    } else {
      await prefs.setString(_trainingTypeKey, type.name);
    }
    setState(() => _trainingType = type);
  }

  Future<void> _toggleStreet(String street) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_streetFilters.add(street)) {
      _streetFilters.remove(street);
    }
    if (_streetFilters.isEmpty) {
      await prefs.remove(_streetKey);
    } else {
      await prefs.setStringList(_streetKey, _streetFilters.toList());
    }
    setState(() {});
  }

  Future<void> _clearTagFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selTagsKey);
    await prefs.remove(_selCatsKey);
    await prefs.remove(_actTagsKey);
    await prefs.remove(_actCatsKey);
    _selectedTags.clear();
    _selectedCategories.clear();
    _activeTags.clear();
    _activeCategories.clear();
    await UserProfilePreferenceService.instance.setPreferredTags(_activeTags);
    setState(() {});
  }

  Future<void> _setShowRecent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recentOnlyKey, value);
    setState(() => _showRecent = value);
  }

  Future<void> _setInProgressOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_inProgressOnlyKey, value);
    setState(() => _inProgressOnly = value);
  }

  Future<void> _setHideCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideCompletedKey, value);
    setState(() => _hideCompleted = value);
  }

  Future<void> _setCompletedOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedOnlyKey, value);
    setState(() => _completedOnly = value);
  }

  Future<void> _setPopularOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_popularOnlyKey, value);
    setState(() => _popularOnly = value);
    if (value) unawaited(_updatePopular());
  }

  Future<void> _setRecommendedOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recommendedOnlyKey, value);
    setState(() => _recommendedOnly = value);
  }

  Future<void> _setMasteredOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_masteredOnlyKey, value);
    setState(() => _masteredOnly = value);
  }

  Future<void> _setAvailableOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_availableOnlyKey, value);
    setState(() => _availableOnly = value);
  }

  Future<void> _setWeakOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weakOnlyKey, value);
    setState(() => _weakOnly = value);
  }

  Future<void> _setCompactMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactKey, value);
    setState(() => _compactMode = value);
  }

  Future<void> _setEffectivenessSort(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_effectivenessSortKey, value);
    setState(() => _effectivenessSort = value);
  }

  Future<void> _updateRecent() async {
    final templates = context.read<TemplateStorageService>().templates;
    final recent = await TrainingPackStatsService.recentlyPractisedTemplates(
      templates,
    );
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  Future<void> _updatePopular() async {
    final templates = context.read<TemplateStorageService>().templates;
    final ids = await TrainingPackStatsService.getPopularTemplates();
    final map = {for (final t in templates) t.id: t};
    final list = [
      for (final id in ids)
        if (map[id] != null) map[id]!
    ];
    if (!mounted) return;
    setState(() {
      _popularIds = ids;
      _popular = list.take(5).toList();
    });
  }

  Future<void> _updateNewPacks() async {
    final templates = context.read<TemplateStorageService>().templates;
    final now = DateTime.now();
    final list = [
      for (final t in templates)
        if (now.difference(t.createdAt).inDays < 7) t
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() => _newPacks = list);
  }

  Future<void> _loadStats() async {
    final templates = context.read<TemplateStorageService>().templates;
    final map = <String, TrainingPackStat?>{};
    final mastered = <String>{};
    for (final t in templates) {
      map[t.id] = await TrainingPackStatsService.getStats(t.id);
      if (await TrainingPackStatsService.isMastered(t.id)) {
        mastered.add(t.id);
      }
    }
    if (!mounted) return;
    setState(() {
      _stats
        ..clear()
        ..addAll(map);
      _mastered
        ..clear()
        ..addAll(mastered);
    });
  }

  Future<void> _updateUnlockStatus() async {
    final list = PackLibraryLoaderService.instance.library;
    final unlocked = <String, bool>{};
    final reasons = <String, String?>{};
    for (final p in list) {
      final unlockedRes = await PackUnlockingRulesEngine.instance.isUnlocked(p);
      unlocked[p.id] = unlockedRes;
      reasons[p.id] = unlockedRes
          ? null
          : PackUnlockingRulesEngine.instance.getUnlockRule(p)?.unlockHint;
    }
    if (!mounted) return;
    setState(() {
      _packUnlocked
        ..clear()
        ..addAll(unlocked);
      _lockReasons
        ..clear()
        ..addAll(reasons);
    });
  }

  Future<void> _loadPlayCounts() async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    final counts = <String, int>{};
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      counts.update(log.templateId, (c) => c + 1, ifAbsent: () => 1);
    }
    if (!mounted) return;
    setState(() {
      _playCounts
        ..clear()
        ..addAll(counts);
    });
  }

  Future<void> _loadHandsCompleted() async {
    final templates = context.read<TemplateStorageService>().templates;
    final map = <String, int>{};
    for (final t in templates) {
      final c = await TrainingPackStatsService.getHandsCompleted(t.id);
      if (c > 0) map[t.id] = c;
    }
    if (!mounted) return;
    setState(() {
      _handsCompleted
        ..clear()
        ..addAll(map);
    });
  }

  Future<void> _loadPreviewCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _previewCompleted
        ..clear()
        ..addAll(prefs.getStringList(_previewCompletedKey) ?? []);
    });
  }

  Future<void> _loadWeakCategories() async {
    final map = await TrainingPackStatsService.getCategoryStats();
    final list = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final limit = list.length > 5 ? 5 : list.length;
    if (!mounted) return;
    setState(() {
      _weakCategories = [for (final e in list.take(limit)) e.key];
    });
  }

  Future<void> _detectWeakCategory() async {
    final id =
        await context.read<TrainingGapDetectorService>().detectWeakCategory();
    if (!mounted) return;
    setState(() => _weakCategory = id);
    await _loadWeakCategoryPack();
  }

  Future<void> _loadWeakCategoryPack() async {
    final cat = _weakCategory;
    if (cat == null) return;
    final list = PackLibraryLoaderService.instance.library;
    final tpl = list.firstWhereOrNull((t) => t.category == cat);
    if (!mounted) return;
    setState(() => _weakCategoryPack = tpl);
  }

  Future<void> _loadTypeStats() async {
    final list = PackLibraryLoaderService.instance.library;
    final map =
        await const TrainingTypeStatsService().calculateCompletionPercent(list);
    final weak = const WeakTrainingTypeDetector().findWeakestType(map);
    if (!mounted) return;
    setState(() {
      _typeCompletion = map;
      _weakestType = weak;
    });
  }

  Future<void> _loadWeakTags() async {
    final tags =
        await context.read<TagMasteryService>().getWeakTags();
    final userTemplates = context.read<TemplateStorageService>().templates;
    final library = PackLibraryLoaderService.instance.library;
    final map = <String, String>{};
    final libMap = <String, String>{};
    for (final t in userTemplates) {
      final match = t.focusTags.firstWhereOrNull(tags.contains) ??
          t.tags.firstWhereOrNull(tags.contains);
      if (match != null) map[t.id] = match;
    }
    for (final t in library) {
      final match = t.focusTags.firstWhereOrNull(tags.contains) ??
          t.tags.firstWhereOrNull(tags.contains);
      if (match != null) libMap[t.id] = match;
    }
    if (!mounted) return;
    setState(() {
      _weakTags = tags.toSet();
      _weakTagMap
        ..clear()
        ..addAll(map);
      _weakLibTagMap
        ..clear()
        ..addAll(libMap);
    });
  }

  Future<void> _updateLibrarySorted() async {
    var list = PackLibraryLoaderService.instance.library.toList();
    switch (_librarySort) {
      case kLibSortAccuracy:
        list = await PackSortingEngine.sortByAccuracy(list, descending: true);
        break;
      case kLibSortLastTrained:
        list = await PackSortingEngine.sortByLastTrained(list);
        break;
      default:
        list = await PackSortingEngine.sortByProgress(list);
    }
    if (!mounted) return;
    setState(() => _librarySorted = list);
  }

  Color _colorFor(double val) {
    if (val >= .99) return Colors.green;
    if (val >= .5) return Colors.amber;
    return Colors.red;
  }

  Color _progressColor(double val) {
    if (val >= 80) return Colors.green;
    if (val >= 50) return Colors.amber;
    return Colors.red;
  }

  String getStreetLabel(String code) {
    switch (code) {
      case 'preflop':
        return 'Preflop';
      case 'flop':
        return 'Flop';
      case 'turn':
        return 'Turn';
      case 'river':
        return 'River';
      default:
        return code;
    }
  }

  Color _streetColor(String code) {
    switch (code) {
      case 'preflop':
        return Colors.deepPurple;
      case 'flop':
        return Colors.green;
      case 'turn':
        return Colors.orange;
      case 'river':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _streetBadge(String street, {required bool compact}) {
    final color = _streetColor(street);
    final label = getStreetLabel(street);
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        compact ? '🔥' : '🔥 $label',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Color _trainingTypeColor(String type) {
    switch (type) {
      case 'coverage':
        return Colors.blue;
      case 'mistakes':
        return Colors.orange;
      case 'streaks':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget trainingTypeBadge(String type, {required bool compact}) {
    final color = _trainingTypeColor(type);
    final label = switch (type) {
      'coverage' => 'Coverage',
      'mistakes' => 'Mistakes',
      'streaks' => 'Streaks',
      _ => 'Custom'
    };
    final icon = switch (type) {
      'coverage' => '📘',
      'mistakes' => '⚠️',
      'streaks' => '🔁',
      _ => '🛠'
    };
    final badge = Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        compact ? icon : '$icon $label',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      return Tooltip(message: label, child: badge);
    }
    return badge;
  }

  double _effectivenessScore(TrainingPackTemplate t) {
    final count = _playCounts[t.id] ?? 0;
    final ev = _stats[t.id]?.evSum ?? 0.0;
    final gain = count > 0 ? ev / count : ev;
    return gain * 100 + count;
  }

  double _progressPercentFor(TrainingPackTemplate t) {
    final stat = _stats[t.id];
    if (stat == null || t.spots.isEmpty) return 0;
    return ((stat.lastIndex + 1) * 100 / t.spots.length)
        .clamp(0, 100)
        .toDouble();
  }

  double _progressPercentForLib(v2.TrainingPackTemplate t) {
    final stat = _stats[t.id];
    final count = t.spots.isNotEmpty ? t.spots.length : t.spotCount;
    if (stat == null || count == 0) return 0;
    return ((stat.lastIndex + 1) * 100 / count).clamp(0, 100).toDouble();
  }

  int _compareCombinedTrending(TrainingPackTemplate a, TrainingPackTemplate b) {
    final ta = (a as dynamic).trending == true;
    final tb = (b as dynamic).trending == true;
    final r1 = (tb ? 1 : 0).compareTo(ta ? 1 : 0);
    if (r1 != 0) return r1;
    final pa = _playCounts[a.id] ?? 0;
    final pb = _playCounts[b.id] ?? 0;
    final r2 = pb.compareTo(pa);
    if (r2 != 0) return r2;
    final r3 = b.updatedAt.compareTo(a.updatedAt);
    return r3 == 0 ? a.name.compareTo(b.name) : r3;
  }

  List<TrainingPackTemplate> _applySorting(List<TrainingPackTemplate> list) {
    final copy = [...list];
    if (_effectivenessSort) {
      copy.sort((a, b) {
        final r = _effectivenessScore(b).compareTo(_effectivenessScore(a));
        return r == 0 ? a.name.compareTo(b.name) : r;
      });
      return copy;
    }
    if (_sortMode == SortMode.recent) {
      switch (_sort) {
      case kSortCoverage:
        copy.sort((a, b) {
          final ca = a.coveragePercent;
          final cb = b.coveragePercent;
          if (ca == null && cb == null) return 0;
          if (ca == null) return 1;
          if (cb == null) return -1;
          final r = cb.compareTo(ca);
          return r == 0 ? a.name.compareTo(b.name) : r;
        });
        break;
      case kSortName:
        copy.sort((a, b) => a.name.compareTo(b.name));
        break;
      case kSortSpots:
        copy.sort((a, b) {
          final cmp = b.hands.length.compareTo(a.hands.length);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case kSortProgress:
        copy.sort((a, b) {
          final aAcc = _stats[a.id]?.accuracy ?? 0.0;
          final bAcc = _stats[b.id]?.accuracy ?? 0.0;
          final cmp = aAcc.compareTo(bAcc);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case kSortInProgress:
        copy.sort((a, b) {
          final ai = _stats[a.id]?.lastIndex ?? 0;
          final bi = _stats[b.id]?.lastIndex ?? 0;
          final cmp = bi.compareTo(ai);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case kSortCombinedTrending:
        copy.sort(_compareCombinedTrending);
        break;
      default:
        copy.sort((a, b) {
          final cmp = b.updatedAt.compareTo(a.updatedAt);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
    }
    }
    return TrainingPackSortEngine.instance.sort(copy, _sortMode);
  }

  List<v2.TrainingPackTemplate> _applyAudienceFilter(
      List<v2.TrainingPackTemplate> list) {
    if (_audienceFilter == 'all') return list;
    return [
      for (final t in list)
        if (t.audience == _audienceFilter) t
    ];
  }

  List<v2.TrainingPackTemplate> _applyTrainingTypeFilter(
      List<v2.TrainingPackTemplate> list) {
    if (_trainingType == null) return list;
    return TrainingTypeFilterService.filterByType(
        list.toList(), {_trainingType!});
  }

  Widget _buildSortButtons(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(l.sortNewest),
            selected: _sort == kSortEdited,
            onSelected: (_) => _setSort(kSortEdited),
          ),
          ChoiceChip(
            label: Text(l.sortMostHands),
            selected: _sort == kSortSpots,
            onSelected: (_) => _setSort(kSortSpots),
          ),
          ChoiceChip(
            label: Text(l.sortName),
            selected: _sort == kSortName,
            onSelected: (_) => _setSort(kSortName),
          ),
          ChoiceChip(
            label: Text(l.sortProgress),
            selected: _sort == kSortProgress,
            onSelected: (_) => _setSort(kSortProgress),
          ),
          ChoiceChip(
            label: Text(l.sortCoverage),
            selected: _sort == kSortCoverage,
            onSelected: (_) => _setSort(kSortCoverage),
          ),
          ChoiceChip(
            label: const Text('🔥 Популярное'),
            selected: _sort == kSortCombinedTrending,
            onSelected: (_) => _setSort(kSortCombinedTrending),
          ),
          ChoiceChip(
            label: const Text('📈 Эффективность'),
            selected: _effectivenessSort,
            onSelected: (v) => _setEffectivenessSort(v),
          ),
          ChoiceChip(
            label: const Text('In Progress'),
            selected: _sort == kSortInProgress,
            onSelected: (_) => _setSort(kSortInProgress),
          ),
          DropdownButton<SortMode>(
            value: _sortMode,
            dropdownColor: const Color(0xFF2A2B2E),
            style: const TextStyle(color: Colors.white),
            onChanged: (m) {
              if (m != null) _setSortMode(m);
            },
            items: const [
              DropdownMenuItem(
                value: SortMode.progress,
                child: Text('Progress'),
              ),
              DropdownMenuItem(
                value: SortMode.difficulty,
                child: Text('Difficulty'),
              ),
              DropdownMenuItem(
                value: SortMode.recent,
                child: Text('Recent'),
              ),
              DropdownMenuItem(
                value: SortMode.focus,
                child: Text('Focus'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasTag(TrainingPackTemplate t, String tag) =>
      t.tags.any((x) => x.toLowerCase() == tag);

  bool _isStarter(TrainingPackTemplate t) => _hasTag(t, kStarterTag);

  bool _isFeatured(TrainingPackTemplate t) => _hasTag(t, kFeaturedTag);

  bool _isCompleted(String id) {
    final stat = _stats[id];
    if (stat == null) return false;
    final ev = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
    final icm = stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct;
    return stat.accuracy >= .9 && ev >= 80 && icm >= 80;
  }

  bool _isFullyCompleted(TrainingPackTemplate t) {
    final stat = _stats[t.id];
    if (stat == null) return false;
    final ev = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
    final icm = stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct;
    return _progressPercentFor(t) == 100 &&
        (stat.accuracy >= .9 || ev >= 90 || icm >= 90);
  }

  bool _matchesTagsAndCategories(TrainingPackTemplate t) {
    final tags = {..._selectedTags, ..._activeTags};
    final cats = {..._selectedCategories, ..._activeCategories};
    if (tags.isEmpty && cats.isEmpty) return true;
    final tagOk = tags.isEmpty || t.tags.any(tags.contains);
    var catOk = cats.isEmpty;
    if (!catOk) {
      if (t.category != null && cats.contains(t.category)) {
        catOk = true;
      } else {
        for (final h in t.hands) {
          final c = h.category;
          if (c != null && cats.contains(c)) {
            catOk = true;
            break;
          }
        }
      }
    }
    return tagOk && catOk;
  }

  List<TrainingPackTemplate> _applyFilters(
      List<TrainingPackTemplate> templates) {
    var visible = templates;
    if (_filter == 'tournament') {
      visible = [
        for (final t in visible)
          if (t.gameType.toLowerCase().startsWith('tour')) t
      ];
    } else if (_filter == 'cash') {
      visible = [
        for (final t in visible)
          if (t.gameType.toLowerCase().contains('cash')) t
      ];
    } else if (_filter == 'mistakes') {
      final service = context.read<MistakeReviewPackService>();
      visible = [
        for (final t in visible)
          if (service.hasMistakes(t.id)) t
      ];
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (t.name.toLowerCase().contains(query) ||
              t.tags.any((tag) => tag.toLowerCase().contains(query)))
            t
      ];
    }
    if (_needsPractice) {
      visible = [
        for (final t in visible)
          if (_needsPracticeIds.contains(t.id)) t
      ];
    }
    if (_needsRepetition) {
      visible = [
        for (final t in visible)
          if (_needsRepetitionIds.contains(t.id)) t
      ];
    }
    if (_needsPracticeOnly) {
      visible = [
        for (final t in visible)
          if (_needsPracticeOnlyIds.contains(t.id)) t
      ];
    }
    if (_favoritesOnly) {
      visible = [
        for (final t in visible)
          if (_favorites.contains(t.id)) t
      ];
    }
    if (_inProgressOnly) {
      visible = [
        for (final t in visible)
          if (_progressPercentFor(t) > 0 && _progressPercentFor(t) < 100) t
      ];
    }
    if (_masteredOnly) {
      visible = [
        for (final t in visible)
          if (_mastered.contains(t.id)) t
      ];
    }
    if (_completedOnly) {
      visible = [
        for (final t in visible)
          if (_isFullyCompleted(t)) t
      ];
    }
    if (_hideCompleted && !_favoritesOnly && !_completedOnly) {
      visible = [
        for (final t in visible)
          if (!_isCompleted(t.id) ||
              _favorites.contains(t.id) ||
              _recent.any((e) => e.id == t.id))
            t
      ];
    }
    if (_selectedTags.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _activeTags.isNotEmpty ||
        _activeCategories.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (_matchesTagsAndCategories(t)) t
      ];
    }
    if (_popularOnly) {
      visible = [
        for (final t in visible)
          if (_popularIds.contains(t.id)) t
      ];
    }
    if (_recommendedOnly) {
      final rec = context.read<RecommendedPackService>();
      visible = [
        for (final t in visible)
          if (t.tags.any(rec.preferredTags.contains) ||
              t.hands.any((h) =>
                  h.category != null &&
                  rec.preferredCategories.contains(h.category)))
            t
      ];
    }
    if (_difficultyFilters.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (_difficultyFilters.contains((t as dynamic).difficultyLevel)) t
      ];
    }
    if (_streetFilters.isNotEmpty) {
      visible = [
        for (final t in visible)
          if ((t as dynamic).targetStreet != null &&
              _streetFilters.contains((t as dynamic).targetStreet))
            t
      ];
    }
    if (_availableOnly) {
      visible = [
        for (final t in visible)
          if (_packUnlocked[t.id] != false) t
      ];
    }
    if (_weakOnly) {
      visible = [
        for (final t in visible)
          if (_weakTagMap.containsKey(t.id)) t
      ];
    }
    return visible;
  }

  Future<void> _importTemplate() async {
    if (_importing) return;
    _importing = true;
    if (mounted) setState(() {});
    String? path;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      Uint8List? data = result.files.single.bytes;
      path = result.files.single.path;
      data ??= path != null ? await File(path).readAsBytes() : null;
      if (data == null) throw 'Пустой файл';

      final service = context.read<TemplateStorageService>();
      final error = service.importTemplate(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Шаблон импортирован')),
      );
    } catch (e) {
      debugPrint('🛑 Импорт не удался${path != null ? ' ($path)' : ''}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось импортировать пак')),
        );
      }
    } finally {
      _importing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _createTemplate() async {
    final template = await Navigator.push<TrainingPackTemplate?>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
    );
    if (template == null) return;
    context.read<TemplateStorageService>().addTemplate(template);
    await _updateNewPacks();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateHandsEditorScreen(template: template),
      ),
    );
  }

  Future<void> _generateFromPreset() async {
    final presets = await TrainingPackPresetRepository.getAll();
    if (!mounted) return;
    final preset = await showModalBottomSheet<TrainingPackPreset>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final p in presets)
              ListTile(
                title: Text(p.name),
                subtitle: Text(p.description),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (preset == null) return;
    final tpl = await TrainingPackTemplateService.generateFromPreset(preset);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: tpl,
          templates: context.read<TemplateStorageService>().templates,
        ),
      ),
    );
  }

  Future<void> _importStarterPacks() async {
    final presets = await TrainingPackPresetRepository.getAll();
    if (!mounted) return;
    final service = context.read<TemplateStorageService>();
    var added = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setState) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (final p in presets) {
                  final exists = service.templates
                      .any((t) => t.id == p.id || t.name == p.name);
                  if (exists) continue;
                  final tpl =
                      await TrainingPackTemplateService.generateFromPreset(p);
                  tpl.isBuiltIn = true;
                  await BulkEvaluatorService().generateMissing(tpl);
                  TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
                  service.addTemplate(tpl);
                  added++;
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return const AlertDialog(
              content: LinearProgressIndicator(),
            );
          },
        );
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added $added packs')));
  }

  Future<void> _autoImport([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    if (_importing) return;
    if (prefs.getBool('imported_initial_templates') == true) return;
    final list = context.read<TemplateStorageService>().templates;
    if (list.isEmpty) {
      await _importInitialTemplates(prefs);
      if (mounted) setState(() {});
    }
  }

  Future<void> _importInitialTemplates([SharedPreferences? prefs]) async {
    if (_importing) return;
    _importing = true;
    FocusScope.of(context).unfocus();
    setState(() {});
    prefs ??= await SharedPreferences.getInstance();
    if (prefs.getBool('imported_initial_templates') == true) {
      setState(() => _importing = false);
      return;
    }
    final manifest = await _manifestFuture;
    final paths = manifest.keys.where((e) =>
        e.startsWith('assets/templates/initial/') && e.endsWith('.json'));
    final service = context.read<TemplateStorageService>();
    var added = 0;
    for (final p in paths) {
      try {
        final data = jsonDecode(await rootBundle.loadString(p));
        if (data is Map<String, dynamic>) {
          final tpl =
              TrainingPackTemplate.fromJson(Map<String, dynamic>.from(data))
                ..isBuiltIn = true;
          if (service.templates.every((t) => t.id != tpl.id)) {
            service.addTemplate(tpl);
            added++;
          } else {
            debugPrint('⚠️  Skip ${tpl.name}: duplicate id');
          }
        }
      } catch (e) {
        debugPrint('Импорт не удался для $p: $e');
      }
    }
    await prefs.setBool('imported_initial_templates', true);
    unawaited(context
        .read<CloudSyncService>()
        .save('imported_initial_templates', '1'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (added == 0) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Не удалось импортировать некоторые паки')));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(Intl.plural(added,
                zero: 'Паки не импортированы',
                one: 'Добавлён $added пак',
                few: 'Добавлено $added пака',
                many: 'Добавлено $added паков'))));
      }
    });
    setState(() => _importing = false);
  }

  Future<TrainingPackTemplate?> _loadLastPack(BuildContext context) async {
    final service = context.read<TemplateStorageService>();
    final list = [
      for (final t in service.templates)
        if (!t.isBuiltIn) t
    ];
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> _quickPractice() async {
    final templates = context.read<TemplateStorageService>().templates;
    TrainingPackTemplate? tpl;
    if (_needsPracticeIds.isNotEmpty) {
      tpl = templates.firstWhere(
        (t) => _needsPracticeIds.contains(t.id),
        orElse: () => TrainingPackTemplate(id: '', name: ''),
      );
      if (tpl.id.isEmpty) tpl = null;
    }
    tpl ??= (() {
      final builtIn = [
        for (final t in templates)
          if (t.isBuiltIn) t
      ];
      if (builtIn.isEmpty) return null;
      return builtIn[Random().nextInt(builtIn.length)];
    }());
    if (tpl == null) return;
    final tplV2 = TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: const TrainingTypeEngine().detectTrainingType(tpl),
    );
    await const TrainingSessionLauncher().launch(tplV2);
  }

  Future<void> _top3CategoriesDrill() async {
    final tpl = await TrainingPackService.createDrillFromTopCategories(context);
    if (tpl == null) return;
    final tplV2 = TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: const TrainingTypeEngine().detectTrainingType(tpl),
    );
    await const TrainingSessionLauncher().launch(tplV2);
  }

  Future<void> _weakCategoriesDrill() async {
    final tpl =
        await TrainingPackService.createDrillFromWeakCategories(context);
    if (tpl == null) return;
    final tplV2 = TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: const TrainingTypeEngine().detectTrainingType(tpl),
    );
    await const TrainingSessionLauncher().launch(tplV2);
  }

  Future<void> _worstCategoryDrill() async {
    final tpl = await TrainingPackService.createDrillFromWorstCategory(context);
    if (tpl == null) return;
    final tplV2 = TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: const TrainingTypeEngine().detectTrainingType(tpl),
    );
    await const TrainingSessionLauncher().launch(tplV2);
  }

  Future<void> _repeatCorrected() async {
    final tpl = await TrainingPackService.createRepeatForCorrected(context);
    if (tpl == null) return;
    final tplV2 = TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: const TrainingTypeEngine().detectTrainingType(tpl),
    );
    await const TrainingSessionLauncher().launch(tplV2);
  }

  Future<void> _smartReviewDrill() async {
    final tpl = await TrainingPackService.createSmartReviewDrill(context);
    if (tpl == null) return;
    final tplV2 = TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: const TrainingTypeEngine().detectTrainingType(tpl),
    );
    await const TrainingSessionLauncher().launch(tplV2);
  }

  Future<void> _startDailyPack() async {
    final tpl = context.read<DailyPackService>().template;
    if (tpl == null) return;
    await const TrainingSessionLauncher().launch(tpl);
  }

  Future<void> _startRecommendedPack() async {
    final engine = context.read<SmartPackSuggestionEngine>();
    final profile = UserProfile(
      recentTags: context.read<RecommendedPackService>().preferredTags,
      weakTags: _weakCategories,
    );
    final list = await engine.suggestTopPacks(profile);
    if (list.isEmpty) return;
    final tpl = list.first;
    await const TrainingSessionLauncher().launch(tpl);
  }

  Future<void> _showRecommendedForYou() async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final all = PackLibraryLoaderService.instance.library;
    final list = const PackRecommendationEngine().recommend(
      all: all,
      preferredTags: _activeTags.isEmpty ? null : _activeTags,
      preferredAudiences: _audienceFilter == 'all' ? null : {_audienceFilter},
      preferredDifficulties:
          _difficultyFilters.isEmpty ? null : _difficultyFilters,
    );
    if (!mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Нет рекомендаций')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackSuggestionPreviewScreen(packs: list),
      ),
    );
  }

  Widget _recommendedCategoryCard() {
    return FutureBuilder<String?>(
      future: context
          .read<WeakSpotRecommendationService>()
          .getRecommendedCategory(),
      builder: (context, snap) {
        final cat = snap.data;
        if (cat == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text(
                      '📂 Рекомендуемая категория',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  translateCategory(cat),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Подтяните навык в этой области',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _setActiveCategory(cat),
                    child: const Text('Начать'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Banner prompting the user to train the weakest statistical category.
  Widget _weakCategoryBanner() {
    final cat = _weakCategory;
    final pack = _weakCategoryPack;
    if (cat == null || pack == null) return const SizedBox.shrink();
    return TrainingGapPromptBanner(category: cat, pack: pack);
  }

  Widget _item(TrainingPackTemplate t, [String? note]) {
    final l = AppLocalizations.of(context)!;
    final parts = t.version.split('.');
    final version = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : t.version;
    final tags = t.tags.take(3).toList();
    final weakTag = _weakTagMap[t.id];
    final combinedNote = weakTag != null
        ? (note != null
            ? '$note • Weak skill: $weakTag'
            : 'Weak skill: $weakTag')
        : note;
    final isNew =
        t.isBuiltIn && DateTime.now().difference(t.createdAt).inDays < 7;
    Widget progress() {
      final stat = _stats[t.id];
      if (stat == null) return const SizedBox.shrink();
      final ev = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
      final icm = stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct;
      if (ev == 0 || icm == 0) return const SizedBox.shrink();
      final val = ((stat.accuracy * 100) + ev + icm) / 3;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Semantics(
          label: l.percentLabel(val.round()),
          child: LinearProgressIndicator(
            value: val / 100,
            backgroundColor: Colors.white12,
            color: _progressColor(val),
            minHeight: 3,
          ),
        ),
      );
    }

    Widget handsProgress() {
      final c = _handsCompleted[t.id];
      if (c == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '$c / ${t.spots.length}',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      );
    }

    final tagsWidget = tags.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final tag in tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final locked = _packUnlocked[t.id] == false;
    final reason = _lockReasons[t.id];
    final previewRequired =
        t.spots.length > 30 && !_previewCompleted.contains(t.id);

    if (_compactMode) {
      Widget card = Card(
        child: ListTile(
          dense: true,
          trailing: _progressPercentFor(t) == 100
              ? const Tooltip(
                  message: 'Пройден на 100%',
                  child: Icon(Icons.star, size: 16, color: Colors.amber),
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (combinedNote != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    combinedNote,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.name,
                      style: t.isBuiltIn
                          ? TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            )
                          : null,
                    ),
                  ),
                  if (t.targetStreet != null)
                    _streetBadge(t.targetStreet!, compact: true),
                  trainingTypeBadge(t.trainingType.name, compact: true),
                ],
              ),
              if (locked && reason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(reason,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              if (t.category != null && t.category!.isNotEmpty)
                Text(
                  translateCategory(t.category),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              handsProgress(),
              progress(),
              if (tags.isNotEmpty) tagsWidget,
            ],
          ),
          onTap: () async {
            if (await _maybeAutoSample(TrainingPackTemplateV2.fromTemplate(
              t,
              type: const TrainingTypeEngine().detectTrainingType(t),
            ))) {
              return;
            }
            final create = await showDialog<bool>(
              context: context,
              builder: (_) => TemplatePreviewDialog(template: t),
            );
            if (create == true && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreatePackFromTemplateScreen(template: t)),
              );
            }
          },
        ),
      );
      card = Stack(
        children: [
          card,
          if (weakTag != null)
          Positioned(
            top: 4,
            left: 4,
            child: Tooltip(
              message: 'Weak skill: $weakTag',
              child: const Icon(
                Icons.brightness_1,
                size: 10,
                color: Colors.redAccent,
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: PackProgressOverlay(templateId: t.id, size: 20),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: LibraryPackBadgeRenderer(packId: t.id),
        ),
        if (locked && reason != null)
          Positioned(
            bottom: 4,
            left: 4,
            child: PackUnlockRequirementBadge(
              text: reason,
              tooltip: reason,
            ),
          ),
      ],
    );
      if (_isStarter(t)) {
        card = Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: card,
        );
      }
      Widget widget = GestureDetector(
        onLongPress: () => _showPackSheet(context, t),
        child: card,
      );
      if (locked) {
        widget = Stack(
          children: [
            Opacity(opacity: 0.5, child: widget),
            Positioned.fill(
              child: Tooltip(
                message: reason == null
                    ? 'Пак заблокирован'
                    : 'Чтобы разблокировать: $reason',
                child: InkWell(
                  onTap: () => _onLockedPackTap(t, reason),
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child:
                        const Icon(Icons.lock, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return Container(
        key: _itemKeys.putIfAbsent(t.id, () => GlobalKey()),
        child: widget,
      );
    }

    Widget card = Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorFromHex(t.defaultColor)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (combinedNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  combinedNote,
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            if (_isStarter(t))
              Row(
                children: [
                  const Icon(Icons.rocket_launch,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(l.starterBadge,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueAccent)),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                if (t.isBuiltIn) ...[
                  const Icon(Icons.shield, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                if (_recent.any((e) => e.id == t.id)) ...[
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                if (_needsRepetitionIds.contains(t.id)) ...[
                  const Text('⏳', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                ],
                if (_needsPracticeOnlyIds.contains(t.id)) ...[
                  const Text('📉', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    t.name,
                    style: t.isBuiltIn
                        ? TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          )
                        : null,
                  ),
                ),
                if (t.targetStreet != null)
                  _streetBadge(t.targetStreet!, compact: false),
                trainingTypeBadge(t.trainingType.name, compact: false),
                if (t.category != null && t.category!.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    translateCategory(t.category),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (_mastered.contains(t.id)) ...[
                  const SizedBox(width: 4),
                  Text(
                    l.masteredBadge,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
                if (_progressPercentFor(t) == 100) ...[
                  const SizedBox(width: 4),
                  const Tooltip(
                    message: 'Пройден на 100%',
                    child: Icon(Icons.star, size: 16, color: Colors.amber),
                  ),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: isNew
                      ? Padding(
                          key: const ValueKey('new'),
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(l.newBadge,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        )
                      : const SizedBox.shrink(key: ValueKey('notNew')),
                ),
              ],
            ),
            handsProgress(),
            progress(),
            if (tags.isNotEmpty) tagsWidget,
          ],
        ),
        subtitle: () {
          final main = '${t.hands.length} ${l.hands} • v$version';
          final stat = _stats[t.id];
          if (stat == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(main),
                const SizedBox(height: 24),
              ],
            );
          }
          final date =
              DateFormat('dd MMM', Intl.getCurrentLocale()).format(stat.last);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(main),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l.accuracySemantics((stat.accuracy * 100).round()),
                      child: LinearProgressIndicator(
                        value: stat.accuracy.clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        color: _colorFor(stat.accuracy),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.percentLabel((stat.accuracy * 100).round()),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${l.lastTrained}: $date',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          );
        }(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _togglePinned(t.id),
              icon: Text('📌',
                  style: TextStyle(
                      fontSize: 20,
                      color: _pinned.contains(t.id)
                          ? Colors.orange
                          : Colors.white54)),
            ),
            IconButton(
              icon: Icon(
                _favorites.contains(t.id) ? Icons.star : Icons.star_border,
              ),
              color: _favorites.contains(t.id) ? Colors.amber : Colors.white54,
              onPressed: () => _toggleFavorite(t.id),
            ),
            TextButton(
              onPressed: locked || previewRequired
                  ? null
                  : () async {
                      final tplV2 = TrainingPackTemplateV2.fromTemplate(
                        t,
                        type:
                            const TrainingTypeEngine().detectTrainingType(t),
                      );
                      await const TrainingSessionLauncher().launch(tplV2);
                    },
              child: const Text('▶️ Train'),
            ),
            if (previewRequired) const SamplePackPreviewTooltip(),
            SamplePackPreviewButton(template: t, locked: locked),
          ],
        ),
        onTap: () async {
          if (await _maybeAutoSample(t)) return;
          final create = await showDialog<bool>(
            context: context,
            builder: (_) => TemplatePreviewDialog(template: t),
          );
          if (create == true && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreatePackFromTemplateScreen(template: t)),
            );
          }
        },
      ),
    );
    card = Stack(
      children: [
        card,
        if (weakTag != null)
          Positioned(
            top: 4,
            left: 4,
            child: Tooltip(
              message: 'Weak skill: $weakTag',
              child: const Icon(
                Icons.brightness_1,
                size: 10,
                color: Colors.redAccent,
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: PackProgressOverlay(templateId: t.id, size: 20),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: LibraryPackBadgeRenderer(packId: t.id),
        ),
        if (locked && reason != null)
          Positioned(
            bottom: 4,
            left: 4,
            child: PackUnlockRequirementBadge(
              text: reason,
              tooltip: reason,
            ),
          ),
      ],
    );
    if (_isStarter(t)) {
      card = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: card,
      );
    }
    Widget widget = GestureDetector(
      onLongPress: () => _showPackSheet(context, t),
      child: card,
    );
    if (locked) {
      widget = Stack(
        children: [
          Opacity(opacity: 0.5, child: widget),
          Positioned.fill(
            child: Tooltip(
              message: reason == null
                  ? 'Пак заблокирован'
                  : 'Чтобы разблокировать: $reason',
              child: InkWell(
                onTap: reason != null ? () => _showUnlockHint(reason) : null,
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const Icon(Icons.lock, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      key: _itemKeys.putIfAbsent(t.id, () => GlobalKey()),
      child: widget,
    );
  }

  void _showPackSheet(BuildContext context, TrainingPackTemplate t) {
    UserActionLogger.instance.logThrottled('sheet_open:${t.id}');
    final service = context.read<MistakeReviewPackService>();
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _PackSheetContent(
            template: t,
            showReview: service.hasMistakes(t.id),
            onStart: () async {
              Navigator.pop(context);
              final hasMistakes = service.hasMistakes(t.id);
              final choice = await showDialog<int>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(l.startTraining),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 1),
                      child: Text(l.startTraining),
                    ),
                    if (hasMistakes)
                      TextButton(
                        onPressed: () => Navigator.pop(context, 2),
                        child: Text(l.reviewMistakesOnly),
                      ),
                  ],
                ),
              );
              if (!context.mounted) return;
              if (choice == 2) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                final tpl = await service.review(context, t.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (tpl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.noMistakesLeft)),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MistakeReviewScreen(template: tpl)),
                );
              } else if (choice == 1) {
                final tplV2 = TrainingPackTemplateV2.fromTemplate(
                  t,
                  type: const TrainingTypeEngine().detectTrainingType(t),
                );
                await const TrainingSessionLauncher().launch(tplV2);
              }
            },
            onReview: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              final tpl = await service.review(context, t.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (tpl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.noMistakesLeft)),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MistakeReviewScreen(template: tpl)),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showUnlockHint(String reason) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Заблокировано'),
        content: Text('Чтобы разблокировать: $reason'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _maybeAutoSample(v2.TrainingPackTemplate t) async {
    if (_autoSampled.contains(t.id)) return false;
    if (t.spots.length <= 30) return false;
    if (_previewCompleted.contains(t.id)) return false;
    final stat = await TrainingPackStatsService.getStats(t.id);
    if (stat != null) return false;

    _autoSampled.add(t.id);
    const sampler = TrainingPackSampler();
    final sample = sampler.sample(t);
    final preview = TrainingPackTemplate.fromJson(sample.toJson());
    preview.meta['samplePreview'] = true;
    await context
        .read<TrainingSessionService>()
        .startSession(preview, persist: false);
    if (!context.mounted) return true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(
          template: preview,
          original: preview,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.autoSampleToast)),
    );
    return true;
  }

  Future<void> _onLockedPackTap(TrainingPackTemplate t, String? reason) async {
    final l = AppLocalizations.of(context)!;
    final previewRequired =
        t.spots.length > 30 && !_previewCompleted.contains(t.id);
    if (previewRequired) {
      final tplV2 = TrainingPackTemplateV2.fromTemplate(
        t,
        type: const TrainingTypeEngine().detectTrainingType(t),
      );
      if (await _maybeAutoSample(tplV2)) return;
    }
    if (previewRequired) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(l.samplePreviewPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(_, true),
              child: Text(l.previewSample),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        const sampler = TrainingPackSampler();
        final tplV2 = TrainingPackTemplateV2.fromTemplate(
          t,
          type: const TrainingTypeEngine().detectTrainingType(t),
        );
        final sample = sampler.sample(tplV2);
        final preview = TrainingPackTemplate.fromJson(sample.toJson());
        preview.meta['samplePreview'] = true;
        await context
            .read<TrainingSessionService>()
            .startSession(preview, persist: false);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingPackPlayScreen(
              template: preview,
              original: preview,
            ),
          ),
        );
        return;
      }
    }
    if (reason != null) _showUnlockHint(reason);
  }

  Future<void> _onLockedLibraryPackTap(
      v2.TrainingPackTemplate t, String? reason) async {
    final l = AppLocalizations.of(context)!;
    final previewRequired =
        t.spots.length > 30 && !_previewCompleted.contains(t.id);
    if (previewRequired && await _maybeAutoSample(t)) return;
    if (previewRequired) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(l.samplePreviewPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(_, true),
              child: Text(l.previewSample),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        const sampler = TrainingPackSampler();
        final sample = sampler.sample(t);
        final preview = TrainingPackTemplate.fromJson(sample.toJson());
        preview.meta['samplePreview'] = true;
        await context
            .read<TrainingSessionService>()
            .startSession(preview, persist: false);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingPackPlayScreen(
              template: preview,
              original: preview,
            ),
          ),
        );
        return;
      }
    }
    if (reason != null) _showUnlockHint(reason);
  }

  Widget _libraryTile(v2.TrainingPackTemplate t) {
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        );
    final meta = t.meta.isNotEmpty ? jsonEncode(t.meta) : '';
    final locked = _packUnlocked[t.id] == false;
    final reason = _lockReasons[t.id];
    final previewRequired =
        t.spots.length > 30 && !_previewCompleted.contains(t.id);
    Widget card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        title: Row(
          children: [
            Expanded(child: Text(t.name)),
            if (t.trainingType.name.isNotEmpty)
              trainingTypeBadge(t.trainingType.name, compact: false),
            if (_progressPercentForLib(t) == 100)
              const Tooltip(
                message: 'Пройден на 100%',
                child: Icon(Icons.star, size: 16, color: Colors.amber),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.goal, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (locked && reason != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(reason,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
        children: [
          if (t.goal.isNotEmpty) row(Icons.flag, t.goal),
          if (t.tags.isNotEmpty) row(Icons.sell, t.tags.join(', ')),
          if (t.audience != null && t.audience!.isNotEmpty)
            row(Icons.person, t.audience!),
          if (meta.isNotEmpty) row(Icons.info_outline, meta),
        ],
      ),
    );
    card = Stack(
      children: [
        card,
        if (_weakLibTagMap[t.id] != null)
          Positioned(
            top: 4,
            left: 4,
            child: Tooltip(
              message: 'Weak skill: ${_weakLibTagMap[t.id]}',
              child: const Icon(Icons.brightness_1, size: 10, color: Colors.redAccent),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: PackProgressOverlay(templateId: t.id, size: 20),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: LibraryPackBadgeRenderer(packId: t.id),
        ),
        if (locked && reason != null)
          Positioned(
            bottom: 4,
            left: 4,
            child: PackUnlockRequirementBadge(
              text: reason,
              tooltip: reason,
            ),
          ),
      ],
    );
    if (locked) {
      card = Stack(
        children: [
          Opacity(opacity: 0.5, child: card),
          Positioned.fill(
            child: InkWell(
              onTap: () => _onLockedLibraryPackTap(t, reason),
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔒 Заблокировано',
                        style: TextStyle(color: Colors.white)),
                    if (reason != null)
                      Text(reason,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return card;
  }

  Widget get _emptyTile => const ListTile(
        title: Center(
          child: Text(
            'Нет подходящих паков',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final templates = context.watch<TemplateStorageService>().templates;
    final cache = context.watch<TagCacheService>();
    final showNew = _newPacks.length >= 3;
    final tagSet = <String>{for (final t in templates) ...t.tags};
    final catSet = <String>{
      for (final t in templates)
        for (final h in t.hands)
          if (h.category != null && h.category!.isNotEmpty) h.category!
    };
    final templateCatSet = <String>{
      for (final t in templates)
        if (t.category != null && t.category!.isNotEmpty) t.category!
    };
    final tagList = [
      for (final t in cache.popularTags)
        if (tagSet.contains(t)) t,
      ...[
        for (final t in tagSet.toList()..sort())
          if (!cache.popularTags.contains(t)) t
      ]
    ];
    final categoryList = [
      for (final c in cache.popularCategories)
        if (catSet.contains(c)) c,
      ...[
        for (final c in catSet.toList()..sort())
          if (!cache.popularCategories.contains(c)) c
      ]
    ];
    final templateCategoryList = [
      for (final c in templateCatSet.toList()..sort()) c
    ];
    final libraryPopularTags = [
      for (final t in cache.getPopularTags(limit: 8))
        if (_libraryTags.contains(t)) t
    ];
    final pinnedTemplates = _applySorting([
      for (final t in templates)
        if (_pinned.contains(t.id) &&
            (!_needsPracticeOnly || _needsPracticeOnlyIds.contains(t.id)))
          t
    ]);
    final visible = _applyFilters([
      for (final t in templates)
        if (!_pinned.contains(t.id)) t
    ]);
    final sortedVisible = _applySorting(visible);
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtersCount = _selectedTags.length +
        _selectedCategories.length +
        _activeTags.length +
        _activeCategories.length +
        _difficultyFilters.length +
        (_trainingType == null ? 0 : 1) +
        _streetFilters.length;
    final hasResults = sortedVisible.isNotEmpty;
    final filteringActive = query.isNotEmpty ||
        _filter != 'all' ||
        _needsPractice ||
        _needsRepetition ||
        _needsPracticeOnly ||
        _favoritesOnly ||
        _popularOnly ||
        _recommendedOnly ||
        _masteredOnly ||
        _selectedTags.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _activeTags.isNotEmpty ||
        _activeCategories.isNotEmpty ||
        _difficultyFilters.isNotEmpty ||
        _trainingType != null ||
        _streetFilters.isNotEmpty;
    final fav = <TrainingPackTemplate>[];
    final nonFav = <TrainingPackTemplate>[];
    for (final t in sortedVisible) {
      (_favorites.contains(t.id) ? fav : nonFav).add(t);
    }
    final repeatList = _applySorting([
      for (final t in nonFav)
        if (_needsPracticeOnlyIds.contains(t.id)) t
    ]);
    final nonFavRest = [
      for (final t in nonFav)
        if (!_needsPracticeOnlyIds.contains(t.id)) t
    ];
    final continueList = [
      for (final t in nonFavRest)
        if (_progressPercentFor(t) >= 1 && _progressPercentFor(t) < 100) t
    ]..sort((a, b) {
        final ad = a.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    final sortedFav = _applySorting(fav);
    final featured = [
      for (final t in nonFavRest)
        if (t.isBuiltIn && _isFeatured(t)) t
    ]..sort(_compareCombinedTrending);
    final remaining = [
      for (final t in nonFavRest)
        if (!(t.isBuiltIn && _isFeatured(t))) t
    ];
    final builtInStarter = _applySorting([
      for (final t in remaining)
        if (t.isBuiltIn && _isStarter(t)) t
    ]);
    final builtInOther = _applySorting([
      for (final t in remaining)
        if (t.isBuiltIn && !_isStarter(t)) t
    ]);
    final baseLib = _librarySorted.isNotEmpty
        ? _librarySorted
        : PackLibraryLoaderService.instance.library;
    final libAll = _applyTrainingTypeFilter(
        _applyAudienceFilter(baseLib));
    List<v2.TrainingPackTemplate> libraryFiltered = _activeTags.isEmpty
        ? libAll
        : [
            for (final t in libAll)
              if (t.tags.any(_activeTags.contains)) t
          ];
    if (_availableOnly) {
      libraryFiltered = [
        for (final t in libraryFiltered)
          if (_packUnlocked[t.id] != false) t
      ];
    }
    if (_weakOnly) {
      libraryFiltered = [
        for (final t in libraryFiltered)
          if (_weakLibTagMap.containsKey(t.id)) t
      ];
    }
    final libraryMap = <String, List<v2.TrainingPackTemplate>>{};
    for (final t in libraryFiltered) {
      final tag = t.tags.isNotEmpty ? t.tags.first : 'Other';
      libraryMap.putIfAbsent(tag, () => []).add(t);
    }
    final librarySections = libraryMap.keys.toList()
      ..sort((a, b) {
        final cmp = libraryMap[b]!.length.compareTo(libraryMap[a]!.length);
        return cmp == 0 ? a.compareTo(b) : cmp;
      });
    final user = _applySorting([
      for (final t in remaining)
        if (!t.isBuiltIn) t
    ]);
    final masteredProgress = [
      for (final t in templates)
        if (_progressPercentFor(t) == 100) t
    ]..sort((a, b) {
        final ad = a.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    final popularFiltered = _applyFilters([
      for (final t in _popular)
        if (!_pinned.contains(t.id) && !_favorites.contains(t.id)) t
    ]);
    final weakMap = <String, List<TrainingPackTemplate>>{};
    if (_weakCategories.isNotEmpty) {
      final forWeak = _applyFilters([
        for (final t in templates)
          if (!_pinned.contains(t.id)) t
      ]);
      for (final c in _weakCategories.take(3)) {
        final list = [
          for (final t in forWeak)
            if (t.hands.any((h) => h.category == c)) t
        ];
        if (list.isNotEmpty) {
          weakMap[c] = _applySorting(list).take(2).toList();
        }
      }
    }
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Поиск', border: InputBorder.none),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _filter,
              underline: const SizedBox.shrink(),
              onChanged: (v) => v != null ? _setFilter(v) : null,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All')),
                const DropdownMenuItem(
                    value: 'tournament', child: Text('Tournament')),
                const DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(
                    value: 'mistakes', child: Text(l.filterMistakes)),
              ],
            ),
            const SizedBox(width: 8),
            DropdownButton<TrainingType?>(
              value: _trainingType,
              hint: const Text('Type'),
              underline: const SizedBox.shrink(),
              onChanged: _setTrainingType,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...[
                  for (final t in TrainingType.values)
                    DropdownMenuItem(value: t, child: Text(t.label))
                ]
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Street',
              onSelected: _toggleStreet,
              itemBuilder: (ctx) => [
                for (final street in ['preflop', 'flop', 'turn', 'river'])
                  CheckedPopupMenuItem(
                    value: street,
                    checked: _streetFilters.contains(street),
                    child: Text(getStreetLabel(street)),
                  ),
              ],
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, color: Colors.white70),
                  for (final s in _streetFilters)
                    _streetBadge(s, compact: true),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(_sortIcons[_sort], color: Colors.white70),
              onSelected: _setSort,
              initialValue: _sort,
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: kSortEdited,
                  child: Text(AppLocalizations.of(ctx)!.sortNewest),
                ),
                PopupMenuItem(
                  value: kSortSpots,
                  child: Text(AppLocalizations.of(ctx)!.sortMostHands),
                ),
                PopupMenuItem(
                  value: kSortName,
                  child: Text(AppLocalizations.of(ctx)!.sortName),
                ),
                PopupMenuItem(
                  value: kSortProgress,
                  child: Text(AppLocalizations.of(ctx)!.sortProgress),
                ),
                PopupMenuItem(
                  value: kSortCoverage,
                  child: Text(AppLocalizations.of(ctx)!.sortCoverage),
                ),
                const PopupMenuItem(
                  value: kSortCombinedTrending,
                  child: Text('🔥 Популярное'),
                ),
                const PopupMenuItem(
                  value: kSortInProgress,
                  child: Text('In Progress'),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.white70),
              onSelected: _setLibrarySort,
              initialValue: _librarySort,
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: kLibSortProgress,
                  child: Text('By Progress'),
                ),
                PopupMenuItem(
                  value: kLibSortAccuracy,
                  child: Text('By Accuracy'),
                ),
                PopupMenuItem(
                  value: kLibSortLastTrained,
                  child: Text('Last Trained'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Text('📊', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainingStatsScreen()),
              );
            },
          ),
          SyncStatusIcon.of(context),
        ],
      ),
      body: Column(
        children: [
          if (_dailyQuote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _dailyQuote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (context.watch<DailyPackService>().template != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _startDailyPack,
                child: Text(l.packOfDay),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _showRecommendedForYou,
              child: Text('🔍 ${l.recommendedForYou}'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _startRecommendedPack,
              child: Text('🎯 ${l.recommendedPacks}'),
            ),
          ),
          _recommendedCategoryCard(),
          _weakCategoryBanner(),
          TrainingTypeGapPromptBanner(
            selectedTags: _selectedTags,
            activeFilter: _trainingType,
          ),
          SwitchListTile(
            title: Text(l.favorites),
            value: _favoritesOnly,
            onChanged: _setFavoritesOnly,
            activeColor: Colors.orange,
          ),
          FutureBuilder<TrainingPackTemplate?>(
            future: _loadLastPack(context),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final t = snap.data!;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackTemplateEditorScreen(
                          template: t,
                          templates:
                              context.read<TemplateStorageService>().templates,
                        ),
                      ),
                    );
                  },
                  child: Text('Continue: ${t.name}'),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _importStarterPacks,
              child: const Text('Import Starter Packs'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _importInitialTemplates,
              child: const Text('Импортировать базовые паки'),
            ),
          ),
          Builder(
            builder: (context) {
              final service = context.watch<MistakeReviewPackService>();
              if (!service.hasMistakes()) return const SizedBox.shrink();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.error, color: AppColors.accent),
                    title: Text(l.reviewMistakes),
                    onTap: () async {
                      final tpl = await service.buildPack(context);
                      if (tpl == null) return;
                      final tplV2 = TrainingPackTemplateV2.fromTemplate(
                        tpl,
                        type:
                            const TrainingTypeEngine().detectTrainingType(tpl),
                      );
                      await const TrainingSessionLauncher().launch(tplV2);
                    },
                  ),
                ),
              );
            },
          ),
          if (cache.popularTags.isNotEmpty ||
              cache.popularCategories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final tag in cache.popularTags)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: _activeTags.contains(tag),
                        onSelected: (_) => _setActiveTag(tag),
                      ),
                    ),
                  for (final cat in cache.popularCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(translateCategory(cat)),
                        selected: _activeCategories.contains(cat),
                        onSelected: (_) => _setActiveCategory(cat),
                      ),
                    ),
                  if (_activeTags.isNotEmpty || _activeCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.white70,
                        onPressed: _clearActiveFilters,
                      ),
                    ),
                ],
              ),
            ),
          if (cache.popularCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final cat in cache.popularCategories)
                    ChoiceChip(
                      label: Text(translateCategory(cat)),
                      selected: _selectedCategories.contains(cat),
                      onSelected: (_) => _toggleCategory(cat),
                    ),
                ],
              ),
            ),
          if (templateCategoryList.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final cat in templateCategoryList)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(translateCategory(cat)),
                        selected: _selectedCategories.contains(cat),
                        onSelected: (_) => _toggleCategory(cat),
                      ),
                    ),
                ],
              ),
            ),
          if (cache.popularTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final tag in cache.popularTags)
                    FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (_) => _toggleTag(tag),
                    ),
                ],
              ),
            ),
          if (_weakCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 Мои категории',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final cat in _weakCategories)
                        ChoiceChip(
                          label: Text(translateCategory(cat)),
                          selected: _activeCategories.contains(cat),
                          onSelected: (_) => _setActiveCategory(cat),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (_typeCompletion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 Прогресс по типам',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  for (final type in TrainingType.values)
                    GestureDetector(
                      onTap: () =>
                          _setTrainingType(_trainingType == type ? null : type),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(type.icon, size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (_typeCompletion[type] ?? 0) / 100,
                                backgroundColor: Colors.white24,
                                color:
                                    _progressColor(_typeCompletion[type] ?? 0),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(_typeCompletion[type] ?? 0).round()}%',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_weakestType != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: _progressColor(
                              _typeCompletion[_weakestType] ?? 0),
                        ),
                        onPressed: () => _setTrainingType(_weakestType),
                        child: Text(
                          '🎯 Усилить слабое место: ${_weakestType!.label}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _showRecommendedTopic,
                  icon: const Text('📌', style: TextStyle(fontSize: 16)),
                  label: const Text('Рекомендованная тема'),
                ),
                FilterChip(
                  label: Text(l.needsPractice),
                  selected: _needsPractice,
                  onSelected: (v) => _updateNeedsPractice(v),
                ),
                ChoiceChip(
                  label: const Text('⏳ На повторение'),
                  selected: _needsRepetition,
                  onSelected: (v) => _updateNeedsRepetition(v),
                ),
                ChoiceChip(
                  label: const Text('📉 Нужно повторить'),
                  selected: _needsPracticeOnly,
                  onSelected: (v) => _updateNeedsPracticeOnly(v),
                ),
                FilterChip(
                  label: Text(l.favorites),
                  selected: _favoritesOnly,
                  onSelected: (v) => _setFavoritesOnly(v),
                ),
                ChoiceChip(
                  label: const Text('🔁 Начатые'),
                  selected: _inProgressOnly,
                  onSelected: (v) => _setInProgressOnly(v),
                ),
                ChoiceChip(
                  label: const Text('📍 Только завершённые'),
                  selected: _completedOnly,
                  onSelected: (v) => _setCompletedOnly(v),
                ),
                ChoiceChip(
                  label: const Text('🧹 Скрыть завершённые'),
                  selected: _hideCompleted,
                  onSelected: (v) => _setHideCompleted(v),
                ),
                FilterChip(
                  label: Text(l.recentPacks),
                  selected: _showRecent,
                  onSelected: (v) => _setShowRecent(v),
                ),
                ChoiceChip(
                  label: const Text('📈 Популярные'),
                  selected: _popularOnly,
                  onSelected: (v) => _setPopularOnly(v),
                ),
                ChoiceChip(
                  label: const Text('🔥 Рекомендуемые'),
                  selected: _recommendedOnly,
                  onSelected: (v) => _setRecommendedOnly(v),
                ),
                ChoiceChip(
                  label: Text(l.masteredBadge),
                  selected: _masteredOnly,
                  onSelected: (v) => _setMasteredOnly(v),
                ),
                ChoiceChip(
                  label: const Text('🔓 Доступные'),
                  selected: _availableOnly,
                  onSelected: (v) => _setAvailableOnly(v),
                ),
                ChoiceChip(
                  label: const Text('⚠️ Weak skills'),
                  selected: _weakOnly,
                  onSelected: (v) => _setWeakOnly(v),
                ),
                ChoiceChip(
                  label: const Text('📋 Компактно'),
                  selected: _compactMode,
                  onSelected: (v) => _setCompactMode(v),
                ),
                ChoiceChip(
                  label: const Text('Сложность: 👶'),
                  selected: _difficultyFilters.contains(1),
                  onSelected: (_) => _toggleDifficulty(1),
                ),
                ChoiceChip(
                  label: const Text('🎯'),
                  selected: _difficultyFilters.contains(2),
                  onSelected: (_) => _toggleDifficulty(2),
                ),
                ChoiceChip(
                  label: const Text('🔥'),
                  selected: _difficultyFilters.contains(3),
                  onSelected: (_) => _toggleDifficulty(3),
                ),
                for (final street in ['preflop', 'flop', 'turn', 'river'])
                  FilterChip(
                    label: Text(getStreetLabel(street)),
                    selected: _streetFilters.contains(street),
                    onSelected: (_) => _toggleStreet(street),
                  ),
              ],
            ),
          ),
          if (tagList.isNotEmpty || categoryList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        filtersCount > 0
                            ? l.filtersSelected(filtersCount)
                            : l.filtersNone,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in tagList)
                        FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          onSelected: (_) => _toggleTag(tag),
                        ),
                      for (final cat in categoryList)
                        FilterChip(
                          label: Text(translateCategory(cat)),
                          selected: _selectedCategories.contains(cat),
                          onSelected: (_) => _toggleCategory(cat),
                        ),
                      if (_selectedTags.isNotEmpty ||
                          _selectedCategories.isNotEmpty)
                        ActionChip(
                          label: const Text('Сбросить'),
                          onPressed: _clearTagFilters,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          _buildSortButtons(l),
          if (_loadingNeedsPractice || _loadingNeedsPracticeOnly)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: hasResults
                ? ListView(
                    controller: _listCtrl,
                    children: [
                      const SuggestionBanner(),
                      const PackResumeBanner(),
                      const PackSuggestionBanner(),
                      const SuggestedPackTile(),
                      if (_popularOnly && popularFiltered.isNotEmpty) ...[
                        ListTile(title: Text(l.popularPacks)),
                        for (final t in popularFiltered) _item(t),
                        if (showNew) ...[
                          const Divider(),
                          ListTile(title: Text(l.newPacks)),
                          for (final t in _newPacks) _item(t),
                        ],
                        if (pinnedTemplates.isNotEmpty ||
                            repeatList.isNotEmpty ||
                            sortedFav.isNotEmpty ||
                            _recent.isNotEmpty ||
                            featured.isNotEmpty)
                          const Divider(),
                      ],
                      if (pinnedTemplates.isNotEmpty) ...[
                        ListTile(title: Text(l.pinnedPacks)),
                        for (final t in pinnedTemplates) _item(t),
                        if (sortedFav.isNotEmpty ||
                            builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty ||
                            _recent.isNotEmpty ||
                            featured.isNotEmpty ||
                            (!_popularOnly && popularFiltered.length >= 3) ||
                            (_popularOnly && popularFiltered.isNotEmpty))
                          const Divider(),
                      ],
                      if (repeatList.isNotEmpty) ...[
                        const ListTile(title: Text('📉 Нужно повторить')),
                        for (final t in repeatList) _item(t),
                        if (sortedFav.isNotEmpty ||
                            continueList.length >= 2 ||
                            builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty ||
                            _recent.isNotEmpty ||
                            featured.isNotEmpty ||
                            (!_popularOnly && popularFiltered.length >= 3) ||
                            (_popularOnly && popularFiltered.isNotEmpty))
                          const Divider(),
                      ],
                      if (continueList.length >= 2) ...[
                        const ListTile(title: Text('⏳ Продолжить обучение')),
                        for (final t in continueList) _item(t),
                        if (sortedFav.isNotEmpty ||
                            builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty ||
                            _recent.isNotEmpty ||
                            featured.isNotEmpty ||
                            (!_popularOnly && popularFiltered.length >= 3) ||
                            (_popularOnly && popularFiltered.isNotEmpty))
                          const Divider(),
                      ],
                      if (sortedFav.isNotEmpty) ...[
                        ListTile(title: Text('★ ${l.favorites}')),
                        for (final t in sortedFav) _item(t),
                        if (builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ] else if (filteringActive) ...[
                        _emptyTile,
                        if (builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ],
                      if (!_popularOnly && popularFiltered.length >= 3) ...[
                        ListTile(title: Text(l.popularPacks)),
                        for (final t in popularFiltered) _item(t),
                        if (showNew) ...[
                          const Divider(),
                          ListTile(title: Text(l.newPacks)),
                          for (final t in _newPacks) _item(t),
                        ],
                        if (_recent.isNotEmpty ||
                            featured.isNotEmpty ||
                            builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ],
                      if (_recent.isNotEmpty &&
                          !_needsPractice &&
                          _showRecent) ...[
                        ListTile(title: Text(l.recentPacks)),
                        for (final t in _recent) _item(t),
                        if (featured.isNotEmpty ||
                            builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ],
                      if (featured.isNotEmpty) ...[
                        ListTile(title: Text(l.recommended)),
                        for (final t in featured) _item(t),
                        if (builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ] else if (filteringActive) ...[
                        _emptyTile,
                        if (builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ],
                      if (_weakCategories.isNotEmpty) ...[
                        CategorySection(
                          title: l.weakAreas,
                          categories: _weakCategories,
                          onTap: _setActiveCategory,
                        ),
                        if ((_popularOnly && popularFiltered.isNotEmpty) ||
                            (!_popularOnly && popularFiltered.length >= 3) ||
                            builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ],
                      if (weakMap.isNotEmpty) ...[
                        const ListTile(
                            title: Text(
                                '🧠 \u041f\u043e\u0432\u0442\u043e\u0440\u044b \u043f\u043e \u0441\u043b\u0430\u0431\u044b\u043c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f\u043c')),
                        for (final e in weakMap.entries) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Text(
                              translateCategory(e.key),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70),
                            ),
                          ),
                          for (final t in e.value)
                            _item(t,
                                'Weak Category: ${translateCategory(e.key)}'),
                        ],
                        if (builtInStarter.isNotEmpty ||
                            builtInOther.isNotEmpty ||
                            user.isNotEmpty)
                          const Divider(),
                      ],
                      if (builtInStarter.isNotEmpty) ...[
                        ListTile(title: Text(l.starterPacks)),
                        for (final t in builtInStarter) _item(t),
                        if (builtInOther.isNotEmpty || user.isNotEmpty)
                          const Divider(),
                      ] else if (filteringActive) ...[
                        _emptyTile,
                        if (builtInOther.isNotEmpty || user.isNotEmpty)
                          const Divider(),
                      ],
                      if (builtInOther.isNotEmpty) ...[
                        ListTile(title: Text(l.builtInPacks)),
                        for (final t in builtInOther) _item(t),
                        if (libraryFiltered.isNotEmpty || user.isNotEmpty)
                          const Divider(),
                      ] else if (filteringActive) ...[
                        _emptyTile,
                        if (libraryFiltered.isNotEmpty || user.isNotEmpty)
                          const Divider(),
                      ],
                      if (libraryFiltered.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Library',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Новички'),
                                    selected: _audienceFilter == 'Beginner',
                                    onSelected: (_) => _setAudience(
                                        _audienceFilter == 'Beginner'
                                            ? 'all'
                                            : 'Beginner'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Средний'),
                                    selected: _audienceFilter == 'Intermediate',
                                    onSelected: (_) => _setAudience(
                                        _audienceFilter == 'Intermediate'
                                            ? 'all'
                                            : 'Intermediate'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Профи'),
                                    selected: _audienceFilter == 'Advanced',
                                    onSelected: (_) => _setAudience(
                                        _audienceFilter == 'Advanced'
                                            ? 'all'
                                            : 'Advanced'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (libraryPopularTags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final tag in libraryPopularTags)
                                  FilterChip(
                                    label: Text(tag),
                                    selected: _activeTags.contains(tag),
                                    onSelected: (_) => _toggleActiveTag(tag),
                                  ),
                                if (_activeTags.isNotEmpty)
                                  ActionChip(
                                    label: const Text('Очистить'),
                                    onPressed: _clearActiveTags,
                                  ),
                              ],
                            ),
                          ),
                        if (_libraryTags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final tag in _libraryTags)
                                  FilterChip(
                                    label: Text(tag),
                                    selected: _activeTags.contains(tag),
                                    onSelected: (_) => _toggleActiveTag(tag),
                                  ),
                              ],
                            ),
                          ),
                        for (final tag in librarySections) ...[
                          ListTile(title: Text(tag)),
                          for (final t in libraryMap[tag]!) _libraryTile(t),
                          if (tag != librarySections.last) const Divider(),
                        ],
                        if (user.isNotEmpty) const Divider(),
                      ] else if (filteringActive) ...[
                        _emptyTile,
                        if (user.isNotEmpty) const Divider(),
                      ],
                      if (user.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(l.yourPacks,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                            child: ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Создать новый пак'),
                              onTap: _createTemplate,
                            ),
                          ),
                        ),
                        for (final t in user) _item(t),
                      ] else if (filteringActive) ...[
                        _emptyTile,
                      ],
                      if (masteredProgress.length >= 2) ...[
                        ListTile(title: Text(l.masteredPacks)),
                        for (final t in masteredProgress) _item(t),
                      ],
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 96, color: Colors.white30),
                        const SizedBox(height: 24),
                        const Text('Нет доступных паков'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _importStarterPacks,
                          child: const Text('Импортировать паки'),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'quickPracticeFab',
            onPressed: _quickPractice,
            label: const Text('Quick Practice'),
            icon: const Icon(Icons.play_arrow),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'top3CatFab',
            onPressed: _top3CategoriesDrill,
            label: const Text('Top 3 Mistakes'),
            icon: const Icon(Icons.leaderboard),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'weakCatsFab',
            onPressed: _weakCategoriesDrill,
            label: const Text('Собрать тренировку из слабых категорий'),
            icon: const Icon(Icons.bolt),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'worstCatFab',
            onPressed: _worstCategoryDrill,
            label: const Text('Частые ошибки (EV Loss)'),
            icon: const Icon(Icons.error_outline),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'repeatCorrectedFab',
            onPressed: _repeatCorrected,
            label: const Text('Повторить исправленную'),
            icon: const Icon(Icons.repeat),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'smartReviewFab',
            onPressed: _smartReviewDrill,
            label: const Text('📚 Умный повтор'),
            icon: const Icon(Icons.auto_stories),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'genFromPresetFab',
            onPressed: _generateFromPreset,
            label: const Text('Generate from Preset'),
            icon: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'importTemplateFab',
            onPressed: _importTemplate,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'createTemplateFab',
            onPressed: _createTemplate,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        scaffold,
        AnimatedOpacity(
          opacity: _importing ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const _ImportOverlay(),
        ),
      ],
    );
  }
}

class _ImportOverlay extends StatelessWidget {
  const _ImportOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        ModalBarrier(color: Colors.black38, dismissible: false),
        Center(
          child: Semantics(
            label: 'Импорт паков…',
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}

class _PackSheetContent extends StatelessWidget {
  const _PackSheetContent({
    required this.template,
    this.showReview = false,
    required this.onStart,
    this.onReview,
  });
  final TrainingPackTemplate template;
  final bool showReview;
  final VoidCallback onStart;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final diffVal = (template as dynamic).difficultyLevel;
    final diff = '★' * diffVal + '☆' * (3 - diffVal);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(template.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (template.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(template.description),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text('${template.hands.length} ${l.hands}'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(diff),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onStart,
          child: Text(l.startTraining),
        ),
        if (showReview) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onReview,
            child: Text(l.reviewMistakes),
          ),
        ],
      ],
    );
  }
}

class _StarterTrainingDialog extends StatelessWidget {
  const _StarterTrainingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Practice most common push/fold spots to build skill quickly',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Start Training Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
