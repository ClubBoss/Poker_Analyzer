part of 'training_pack_template_list_screen.dart';

mixin TrainingPackTemplateSortFilter on State<TrainingPackTemplateListScreen> {
  final List<TrainingPackTemplate> _templates = [];
  String _sort = 'coverage';
  String? _stackFilter;
  HeroPosition? _posFilter;
  String? _difficultyFilter;
  String? _streetFilter;

  Future<void> _loadSort() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(TrainingPackTemplatePrefs.sortOption);
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
    await prefs.setString(TrainingPackTemplatePrefs.sortOption, value);
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
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
  }

  Future<void> _setShowInProgressOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _showInProgressOnly = value);
    await prefs.setBool(TrainingPackTemplatePrefs.inProgress, value);
  }

  Future<void> _loadStackFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _stackFilter = prefs.getString(
          TrainingPackTemplatePrefs.stackFilter,
        ),
      );
    }
  }

  Future<void> _loadPosFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(TrainingPackTemplatePrefs.posFilter);
    if (mounted) {
      setState(
        () => _posFilter = name == null
            ? null
            : HeroPosition.values.firstWhere(
                (e) => e.name == name,
                orElse: () => HeroPosition.sb,
              ),
      );
    }
  }

  Future<void> _loadDifficultyFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _difficultyFilter = prefs.getString(
          TrainingPackTemplatePrefs.difficultyFilter,
        ),
      );
    }
  }

  Future<void> _loadStreetFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _streetFilter = prefs.getString(
          TrainingPackTemplatePrefs.streetFilter,
        ),
      );
    }
  }

  Future<void> _setStackFilter(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _stackFilter = value);
    if (value == null) {
      await prefs.remove(TrainingPackTemplatePrefs.stackFilter);
    } else {
      await prefs.setString(TrainingPackTemplatePrefs.stackFilter, value);
    }
  }

  Future<void> _setPosFilter(HeroPosition? value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _posFilter = value);
    if (value == null) {
      await prefs.remove(TrainingPackTemplatePrefs.posFilter);
    } else {
      await prefs.setInt(TrainingPackTemplatePrefs.posFilter, value.index);
    }
  }

  Future<void> _setDifficultyFilter(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _difficultyFilter = value);
    if (value == null) {
      await prefs.remove(TrainingPackTemplatePrefs.difficultyFilter);
    } else {
      await prefs.setString(TrainingPackTemplatePrefs.difficultyFilter, value);
    }
  }

  Future<void> _setStreetFilter(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _streetFilter = value);
    if (value == null) {
      await prefs.remove(TrainingPackTemplatePrefs.streetFilter);
    } else {
      await prefs.setString(TrainingPackTemplatePrefs.streetFilter, value);
    }
  }

  String _filterSummary() {
    final parts = <String>[];
    if (_difficultyFilter != null) parts.add(_difficultyFilter!);
    if (_posFilter != null) parts.add(_posFilter!.label);
    if (_stackFilter != null) parts.add('${_stackFilter}bb');
    String sortLabel() {
      switch (_sort) {
        case 'coverage':
          return 'Coverage';
        case 'created':
          return 'Newest';
        case 'spots':
          return 'Most Spots';
        case 'tag':
          return 'Tag';
        case 'last_trained':
          return 'Last Trained';
        default:
          return 'Name';
      }
    }

    parts.add('Sort: ${sortLabel()}');
    return parts.join(' • ');
  }

  Future<void> _resetFilters() async {
    setState(() {
      _difficultyFilter = null;
      _posFilter = null;
      _stackFilter = null;
      _streetFilter = null;
      _selectedTag = null;
      _tagFilters.clear();
      _icmOnly = false;
      _completedOnly = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TrainingPackTemplatePrefs.difficultyFilter);
    await prefs.remove(TrainingPackTemplatePrefs.posFilter);
    await prefs.remove(TrainingPackTemplatePrefs.stackFilter);
    await prefs.remove(TrainingPackTemplatePrefs.streetFilter);
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

  bool _isIcmTemplate(TrainingPackTemplate t) {
    if (t.meta['icmType'] != null) return true;
    if (t.spots.isEmpty) return false;
    for (final s in t.spots) {
      if (!s.tags.contains('icm')) return false;
    }
    return true;
  }

  List<TrainingPackTemplate> _visibleTemplates() {
    final base = _showFavoritesOnly
        ? [
            for (final t in _templates)
              if (_favorites.contains(t.id) ||
                  FavoritePackService.instance.isFavorite(t.id))
                t,
          ]
        : _templates;
    final byType = _selectedType == null
        ? base
        : [
            for (final t in base)
              if (t.gameType == _selectedType) t,
          ];
    final filtered = _selectedTag == null
        ? byType
        : [
            for (final t in byType)
              if (t.tags.contains(_selectedTag)) t,
          ];
    final icmFiltered = !_icmOnly
        ? filtered
        : [
            for (final t in filtered)
              if (_isIcmTemplate(t)) t,
          ];
    final stackFiltered = _stackFilter == null
        ? icmFiltered
        : [
            for (final t in icmFiltered)
              if (_matchStack(t.heroBbStack)) t,
          ];
    final posFiltered = _posFilter == null
        ? stackFiltered
        : [
            for (final t in stackFiltered)
              if (t.heroPos == _posFilter) t,
          ];
    final diffFiltered = _difficultyFilter == null
        ? posFiltered
        : [
            for (final t in posFiltered)
              if (t.difficulty == _difficultyFilter ||
                  t.tags.contains(_difficultyFilter!))
                t,
          ];
    final streetFiltered = _streetFilter == null
        ? diffFiltered
        : [
            for (final t in diffFiltered)
              if (t.targetStreet == _streetFilter) t,
          ];
    final evalFiltered = !_showNeedsEvalOnly
        ? streetFiltered
        : [
            for (final t in streetFiltered)
              if (t.evCovered < t.totalWeight || t.icmCovered < t.totalWeight)
                t,
          ];
    final completed = _completedOnly
        ? [
            for (final t in evalFiltered)
              if (t.goalAchieved) t,
          ]
        : evalFiltered;
    final visible = _hideCompleted
        ? [
            for (final t in completed)
              if ((t.spots.isEmpty
                          ? 0.0
                          : (_progress[t.id] ?? 0) / t.spots.length) <
                      1.0 ||
                  !t.goalAchieved)
                t,
          ]
        : completed;
    final inProgressFiltered = !_showInProgressOnly
        ? visible
        : [
            for (final t in visible)
              if ((_stats[t.id]?.lastIndex ?? 0) > 0 &&
                  (_stats[t.id]?.accuracy ?? 1.0) < 1.0)
                t,
          ];
    return [
      for (final t in inProgressFiltered)
        if ((_query.isEmpty || t.name.toLowerCase().contains(_query)) &&
            (_tagFilters.isEmpty ||
                t.tags.any((tag) => _tagFilters.contains(tag))))
          t,
    ];
  }

  String _streetLabel(String? street) {
    switch (street) {
      case 'preflop':
        return 'Preflop';
      case 'flop':
        return 'Flop';
      case 'turn':
        return 'Turn';
      case 'river':
        return 'River';
      default:
        return 'All Streets';
    }
  }
}
