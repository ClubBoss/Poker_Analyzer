part of 'training_pack_template_list_screen.dart';

mixin TrainingPackTemplateSortFilterController on State<TrainingPackTemplateListScreen> {
  static const _prefsHideKey = 'tpl_hide_completed';
  static const _prefsGroupKey = 'tpl_group_by_street';
  static const _prefsTypeKey = 'tpl_group_by_type';
  static const _prefsShowFavOnlyKey = 'tpl_show_fav_only';
  static const _prefsSortKey = 'tpl_sort_option';
  static const _prefsStackKey = 'tpl_stack_filter';
  static const _prefsPosKey = 'tpl_pos_filter';
  static const _prefsDifficultyKey = 'tpl_diff_filter';
  static const _prefsStreetKey = 'tpl_street_filter';
  static const _prefsInProgressKey = 'tpl_in_progress';

  String _query = '';
  final Set<String> _tagFilters = {};
  GameType? _selectedType;
  String? _selectedTag;
  bool _filtersShown = false;
  bool _completedOnly = false;
  bool _hideCompleted = false;
  bool _groupByStreet = false;
  bool _groupByType = false;
  bool _icmOnly = false;
  String _sort = 'coverage';
  bool _showFavoritesOnly = false;
  bool _showNeedsEvalOnly = false;
  bool _showInProgressOnly = false;
  String? _stackFilter;
  HeroPosition? _posFilter;
  String? _difficultyFilter;
  String? _streetFilter;

  Future<void> _loadSort() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsSortKey);
    if (mounted && value != null) {
      setState(() {
        _sort = value;
        _sortTemplates();
      });
    }
  }

  Future<void> _setSort(String value) async {
    setState(() {
      _sort = value;
      _sortTemplates();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsSortKey, value);
  }

  void _sortTemplates() {
    switch (_sort) {
      case 'coverage':
        _templates.sort((a, b) {
          double cov(TrainingPackTemplate t) => t.coveragePercent ?? -1;
          final r = cov(b).compareTo(cov(a));
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'created':
        _templates.sort((a, b) {
          final r = b.createdAt.compareTo(a.createdAt);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'spots':
        _templates.sort((a, b) {
          final r = b.spots.length.compareTo(a.spots.length);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'tag':
        _templates.sort((a, b) {
          final tagA = a.tags.isNotEmpty ? a.tags.first.toLowerCase() : '';
          final tagB = b.tags.isNotEmpty ? b.tags.first.toLowerCase() : '';
          final r = tagA.compareTo(tagB);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'last_trained':
        _templates.sort((a, b) {
          final aDt = a.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDt = b.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final r = bDt.compareTo(aDt);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      default:
        _templates.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  Future<void> _loadHideCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _hideCompleted = prefs.getBool(_prefsHideKey) ?? false);
    }
  }

  Future<void> _setHideCompleted(bool value) async {
    setState(() => _hideCompleted = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsHideKey, value);
  }

  Future<void> _loadGroupByStreet() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _groupByStreet = prefs.getBool(_prefsGroupKey) ?? false);
    }
  }

  Future<void> _setGroupByStreet(bool value) async {
    setState(() => _groupByStreet = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsGroupKey, value);
  }

  Future<void> _loadGroupByType() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _groupByType = prefs.getBool(_prefsTypeKey) ?? false);
    }
  }

  Future<void> _setGroupByType(bool value) async {
    setState(() => _groupByType = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsTypeKey, value);
  }

  Future<void> _loadShowFavoritesOnly() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _showFavoritesOnly = prefs.getBool(_prefsShowFavOnlyKey) ?? false);
    }
  }

  Future<void> _setShowFavoritesOnly(bool value) async {
    setState(() => _showFavoritesOnly = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsShowFavOnlyKey, value);
  }

  Future<void> _loadShowInProgressOnly() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _showInProgressOnly = prefs.getBool(_prefsInProgressKey) ?? false);
    }
  }

  Future<void> _setShowInProgressOnly(bool value) async {
    setState(() => _showInProgressOnly = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsInProgressKey, value);
  }

  Future<void> _loadStackFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _stackFilter = prefs.getString(_prefsStackKey));
  }

  Future<void> _setStackFilter(String? value) async {
    setState(() => _stackFilter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefsStackKey);
    } else {
      await prefs.setString(_prefsStackKey, value);
    }
  }

  Future<void> _loadPosFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsPosKey);
    if (mounted) {
      setState(() => _posFilter = name == null
          ? null
          : HeroPosition.values.firstWhere(
              (e) => e.name == name,
              orElse: () => HeroPosition.sb,
            ));
    }
  }

  Future<void> _setPosFilter(HeroPosition? value) async {
    setState(() => _posFilter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefsPosKey);
    } else {
      await prefs.setString(_prefsPosKey, value.name);
    }
  }

  Future<void> _loadDifficultyFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _difficultyFilter = prefs.getString(_prefsDifficultyKey));
  }

  Future<void> _setDifficultyFilter(String? value) async {
    setState(() => _difficultyFilter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefsDifficultyKey);
    } else {
      await prefs.setString(_prefsDifficultyKey, value);
    }
  }

  Future<void> _loadStreetFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _streetFilter = prefs.getString(_prefsStreetKey));
  }

  Future<void> _setStreetFilter(String? value) async {
    setState(() => _streetFilter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefsStreetKey);
    } else {
      await prefs.setString(_prefsStreetKey, value);
    }
  }

  bool _isIcmTemplate(TrainingPackTemplate t) {
    if (t.meta['icmType'] != null) return true;
    if (t.spots.isEmpty) return false;
    for (final s in t.spots) {
      if (!s.tags.contains('icm')) return false;
    }
    return true;
  }

  bool _matchStack(int stack) {
    final r = _stackFilter;
    if (r == null) return true;
    if (r.endsWith('+')) {
      final min = int.tryParse(r.substring(0, r.length - 1)) ?? 0;
      return stack >= min;
    }
    final parts = r.split('-');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0]) ?? 0;
      final max = int.tryParse(parts[1]) ?? 0;
      return stack >= min && stack <= max;
    }
    return true;
  }

  List<TrainingPackTemplate> _visibleTemplates() {
    final base = _showFavoritesOnly
        ? [
            for (final t in _templates)
              if (_favorites.contains(t.id) ||
                  FavoritePackService.instance.isFavorite(t.id))
                t
          ]
        : _templates;
    final byType = _selectedType == null
        ? base
        : [for (final t in base) if (t.gameType == _selectedType) t];
    final filtered = _selectedTag == null
        ? byType
        : [for (final t in byType) if (t.tags.contains(_selectedTag)) t];
    final icmFiltered = !_icmOnly
        ? filtered
        : [for (final t in filtered) if (_isIcmTemplate(t)) t];
    final stackFiltered = _stackFilter == null
        ? icmFiltered
        : [for (final t in icmFiltered) if (_matchStack(t.heroBbStack)) t];
    final posFiltered = _posFilter == null
        ? stackFiltered
        : [for (final t in stackFiltered) if (t.heroPos == _posFilter) t];
    final diffFiltered = _difficultyFilter == null
        ? posFiltered
        : [
            for (final t in posFiltered)
              if (t.difficulty == _difficultyFilter ||
                  t.tags.contains(_difficultyFilter!))
                t
          ];
    final streetFiltered = _streetFilter == null
        ? diffFiltered
        : [for (final t in diffFiltered) if (t.targetStreet == _streetFilter) t];
    final evalFiltered = !_showNeedsEvalOnly
        ? streetFiltered
        : [
            for (final t in streetFiltered)
              if (t.evCovered < t.totalWeight ||
                  t.icmCovered < t.totalWeight)
                t
          ];
    final completed = _completedOnly
        ? [for (final t in evalFiltered) if (t.goalAchieved) t]
        : evalFiltered;
    final visible = _hideCompleted
        ? [
            for (final t in completed)
              if ((t.spots.isEmpty
                      ? 0.0
                      : (_progress[t.id] ?? 0) / t.spots.length) < 1.0 ||
                  !t.goalAchieved)
                t
          ]
        : completed;
    final inProgressFiltered = !_showInProgressOnly
        ? visible
        : [
            for (final t in visible)
              if ((_stats[t.id]?.lastIndex ?? 0) > 0 &&
                  (_stats[t.id]?.accuracy ?? 1.0) < 1.0)
                t
          ];
    return [
      for (final t in inProgressFiltered)
        if ((_query.isEmpty || t.name.toLowerCase().contains(_query)) &&
            (_tagFilters.isEmpty ||
                t.tags.any((tag) => _tagFilters.contains(tag))))
          t
    ];
  }

  Map<String, List<TrainingPackTemplate>> groupByStreet(
      List<TrainingPackTemplate> shown) {
    final streetGroups = <String, List<TrainingPackTemplate>>{};
    if (_groupByStreet) {
      for (final t in shown) {
        final key = t.targetStreet ?? 'any';
        streetGroups.putIfAbsent(key, () => []).add(t);
      }
    } else {
      streetGroups['all'] = shown;
    }
    return streetGroups;
  }

  List<String> topTags(List<TrainingPackTemplate> templates) {
    final tagCounts = <String, int>{};
    for (final t in templates) {
      for (final tag in t.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.keys.toList()
      ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));
    return topTags.take(10).toList();
  }
}
