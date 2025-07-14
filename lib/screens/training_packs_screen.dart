import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import '../models/game_type.dart';
import '../services/training_pack_storage_service.dart';
import '../helpers/color_utils.dart';
import '../widgets/difficulty_chip.dart';
import '../widgets/info_tooltip.dart';
import '../theme/app_colors.dart';
import '../widgets/progress_chip.dart';
import '../widgets/new_chip.dart';
import '../widgets/color_picker_dialog.dart';
import 'training_pack_screen.dart';
import '../helpers/training_onboarding.dart';
import 'training_pack_comparison_screen.dart';
import 'create_pack_screen.dart';
import 'mixed_drill_history_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/weekly_drill_stats_card.dart';
import '../widgets/xp_progress_card.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_session_service.dart';
import 'training_recommendation_screen.dart';
import '../services/smart_suggestion_service.dart';
import 'training_session_screen.dart';
import '../models/saved_hand.dart';

class TrainingPacksScreen extends StatefulWidget {
  const TrainingPacksScreen({super.key});

  @override
  State<TrainingPacksScreen> createState() => _TrainingPacksScreenState();
}

class _TrainingPacksScreenState extends State<TrainingPacksScreen> {
  static const _hideKey = 'hide_completed_packs';
  static const _typeKey = 'pack_game_type_filter';
  static const _diffKey = 'pack_diff_filter';
  static const _colorKey = 'pack_color_filter';
  static const _groupKey = 'group_by_color';
  static const _lastColorKey = 'pack_last_color';

  final TextEditingController _searchController = TextEditingController();

  bool _hideCompleted = false;
  GameType? _typeFilter;
  int _diffFilter = 0;
  String _colorFilter = 'All';
  bool _groupByColor = false;
  Color _lastColor = Colors.blue;
  SharedPreferences? _prefs;
  List<TrainingPack> _suggestions = [];

  Future<void> _importPack() async {
    final service = context.read<TrainingPackStorageService>();
    final msg = await service.importPackFromFile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg ?? 'Пак импортирован')),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DrillHistoryScreen()),
    );
  }

  void _loadSuggestions() {
    final service = context.read<SmartSuggestionService>();
    setState(() {
      _suggestions = service.getSuggestions();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _hideCompleted = prefs.getBool(_hideKey) ?? false;
      final t = prefs.getString(_typeKey);
      if (t == 'tournament') _typeFilter = GameType.tournament;
      if (t == 'cash') _typeFilter = GameType.cash;
      _diffFilter = prefs.getInt(_diffKey) ?? 0;
      _colorFilter = prefs.getString(_colorKey) ?? 'All';
      _groupByColor = prefs.getBool(_groupKey) ?? false;
      _lastColor = colorFromHex(prefs.getString(_lastColorKey) ?? '#2196F3');
    });
  }

  Future<void> _toggleHideCompleted(bool value) async {
    setState(() => _hideCompleted = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_hideKey, value);
  }

  Future<void> _setTypeFilter(GameType? value) async {
    setState(() => _typeFilter = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_typeKey);
    } else {
      await prefs.setString(_typeKey, value.name);
    }
  }

  Future<void> _setDiffFilter(int value) async {
    setState(() => _diffFilter = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == 0) {
      await prefs.remove(_diffKey);
    } else {
      await prefs.setInt(_diffKey, value);
    }
  }

  Future<void> _setColorFilter(String value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == 'Custom') {
      final color = await showColorPickerDialog(
        context,
        initialColor: _lastColor,
      );
      if (color == null) return;
      final hex = colorToHex(color);
      setState(() {
        _colorFilter = hex;
        _lastColor = color;
      });
      await prefs.setString(_lastColorKey, hex);
      await prefs.setString(_colorKey, hex);
      return;
    }
    setState(() => _colorFilter = value);
    if (value == 'All') {
      await prefs.remove(_colorKey);
    } else {
      await prefs.setString(_colorKey, value);
    }
  }


  bool _isPackCompleted(TrainingPack pack) {
    final progress = _prefs?.getInt('training_progress_${pack.name}') ?? 0;
    return progress >= pack.hands.length;
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs;
    final hands = context.watch<SavedHandManagerService>().hands;

    if (_prefs == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тренировочные споты'),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: _openHistory,
            ),
            SyncStatusIcon.of(context)
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<TrainingPack> visible = _hideCompleted
        ? [for (final p in packs) if (!_isPackCompleted(p)) p]
        : packs;

    if (_typeFilter != null) {
      visible = [for (final p in visible) if (p.gameType == _typeFilter) p];
    }

    if (_diffFilter > 0) {
      visible = [for (final p in visible) if (p.difficulty == _diffFilter) p];
    }

    if (_colorFilter != 'All') {
      if (_colorFilter == 'None') {
        visible = [for (final p in visible) if (p.colorTag.isEmpty) p];
      } else if (_colorFilter.startsWith('#')) {
        visible = [for (final p in visible) if (p.colorTag == _colorFilter) p];
      } else {
        const map = {
          'Red': '#F44336',
          'Blue': '#2196F3',
          'Orange': '#FF9800',
          'Green': '#4CAF50',
          'Purple': '#9C27B0',
          'Grey': '#9E9E9E',
        };
        final hex = map[_colorFilter];
        if (hex != null) {
          visible = [for (final p in visible) if (p.colorTag == hex) p];
        }
      }
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final p in visible)
          if (p.name.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query))
            p
      ];
    }

    final bool noRealPacks = packs.isEmpty;
    final draftWidget = hands.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Загрузите раздачи, чтобы быстро начать тренировку',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () async {
                final manager = context.read<SavedHandManagerService>();
                final list = manager.hands;
                final recent = list.length > 10
                    ? list.sublist(list.length - 10)
                    : List<SavedHand>.from(list);
                var tpl = manager
                    .createPack('Draft', recent)
                    .copyWith(isDraft: true);
                final session = await context
                    .read<TrainingSessionService>()
                    .startFromTemplate(tpl);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingSessionScreen(session: session),
                  ),
                );
              },
              child: const Text('Сгенерировать пак из последних 10 раздач'),
            ),
          );

    if (noRealPacks) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тренировочные споты'),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: _openHistory,
            ),
            SyncStatusIcon.of(context)
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WeeklyDrillStatsCard(),
              const XPProgressCard(),
              const Icon(Icons.auto_awesome, size: 96, color: Colors.white30),
              const SizedBox(height: 24),
              draftWidget,
              ElevatedButton(
                onPressed: () => openTrainingTemplates(context),
                child: const Text('Создать из шаблона'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _importPack,
                child: const Text('Импортировать'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final pack = await Navigator.push<TrainingPack>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePackScreen()),
                  );
                  if (pack != null && context.mounted) {
                    await context.read<TrainingPackStorageService>().addPack(pack);
                  }
                },
                child: const Text('Создать с нуля'),
              ),
            ],
          ),
        ),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные споты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _openHistory,
          ),
          SyncStatusIcon.of(context)
        ],
      ),
      body: Column(
        children: [
          const WeeklyDrillStatsCard(),
          const XPProgressCard(),
          if (_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Рекомендуем вам',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(right: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final pack = _suggestions[index];
                        final pct = pack.pctComplete;
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainingPackScreen(pack: pack),
                              ),
                            );
                            if (mounted) _loadSuggestions();
                          },
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text(pack.name,
                                            style: const TextStyle(color: Colors.white))),
                                    if (DateTime.now().difference(pack.createdAt).inDays < 7)
                                      const SizedBox(width: 4),
                                    if (DateTime.now().difference(pack.createdAt).inDays < 7)
                                      const NewChip(),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    DifficultyChip(pack.difficulty),
                                    const SizedBox(width: 4),
                                    ProgressChip(pct),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: _suggestions.length,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrainingRecommendationScreen(),
                          ),
                        );
                      },
                      child: const Text('Показать все рекомендации'),
                    ),
                  )
                ],
              ),
            ),
          draftWidget,
          SwitchListTile(
            title: const Text('Скрыть завершённые'),
            value: _hideCompleted,
            onChanged: _toggleHideCompleted,
            activeColor: Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<GameType?>(
            value: _typeFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) => _setTypeFilter(v),
            items: const [
              DropdownMenuItem(value: null, child: Text('Все')),
              DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
              DropdownMenuItem(value: GameType.cash, child: Text('Cash Game')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<int>(
            value: _diffFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) => _setDiffFilter(v ?? 0),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Difficulty: All')),
              DropdownMenuItem(value: 1, child: Text('Beginner')),
              DropdownMenuItem(value: 2, child: Text('Intermediate')),
              DropdownMenuItem(value: 3, child: Text('Advanced')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<String>(
            value: _colorFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) => _setColorFilter(v ?? 'All'),
            items: [
              const DropdownMenuItem(value: 'All', child: Text('Color: All')),
              const DropdownMenuItem(value: 'Red', child: Text('Red')),
              const DropdownMenuItem(value: 'Blue', child: Text('Blue')),
              const DropdownMenuItem(value: 'Orange', child: Text('Orange')),
              const DropdownMenuItem(value: 'Green', child: Text('Green')),
              const DropdownMenuItem(value: 'Purple', child: Text('Purple')),
              const DropdownMenuItem(value: 'Grey', child: Text('Grey')),
              const DropdownMenuItem(value: 'None', child: Text('None')),
              const DropdownMenuItem(value: 'Custom', child: Text('Custom...')),
              if (_colorFilter.startsWith('#'))
                DropdownMenuItem(
                  value: _colorFilter,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorFromHex(_colorFilter),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_colorFilter),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Group by Color'),
          value: _groupByColor,
          onChanged: (v) async {
            setState(() => _groupByColor = v);
            final prefs = _prefs ?? await SharedPreferences.getInstance();
            await prefs.setBool(_groupKey, v);
          },
          activeColor: Colors.orange,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingPackComparisonScreen(),
                      ),
                    );
                  },
                  child: const Text('📊 Сравнить паки'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                onPressed: () => openTrainingTemplates(context),
                  child: const Text('📑 Шаблоны'),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('По текущему фильтру пакетов не найдено'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hideCompleted = false;
                              _typeFilter = null;
                              _searchController.clear();
                            });
                          },
                          child: const Text('Сбросить фильтры'),
                        ),
                      ],
                    ),
                  )
                : _groupByColor
                    ? _buildGroupedList(visible)
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final pack = visible[index];
                          final pct = pack.pctComplete;
                          final completed = _isPackCompleted(pack);
                          return ListTile(
                            leading: pack.isBuiltIn
                                ? const Text('📦')
                                : InfoTooltip(
                                    message: pack.colorTag.isEmpty
                                        ? 'No color tag'
                                        : 'Color tag ${pack.colorTag} (tap to edit)',
                                    child: pack.colorTag.isEmpty
                                        ? const Icon(Icons.circle_outlined, color: Colors.white24)
                                        : Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: colorFromHex(pack.colorTag),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                  ),
                            title: Row(
                              children: [
                                Expanded(child: Text(pack.name)),
                                if (DateTime.now().difference(pack.createdAt).inDays < 7)
                                  const SizedBox(width: 4),
                                if (DateTime.now().difference(pack.createdAt).inDays < 7)
                                  const NewChip(),
                                const SizedBox(width: 4),
                                DifficultyChip(pack.difficulty),
                                const SizedBox(width: 4),
                                InfoTooltip(
                                  message: pct == 1
                                      ? 'Completed!'
                                      : 'Solved ${pack.solved} of ${pack.hands.length} hands',
                                  child: ProgressChip(pct),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                InfoTooltip(
                                  message: pack.gameType == GameType.tournament
                                      ? 'Blind levels, ICM pressure.'
                                      : '100 BB deep, no blind escalation.',
                                  child: Text(pack.gameType.label),
                                ),
                                const Text(' • '),
                                Text(pack.spots.isNotEmpty
                                    ? '${pack.spots.length} spots'
                                    : '${pack.hands.length} hands'),
                              ],
                            ),
                            trailing: completed ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrainingPackScreen(pack: pack),
                                ),
                              );
                              setState(() {});
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildGroupedList(List<TrainingPack> packs) {
    const order = ['Red', 'Blue', 'Orange', 'Green', 'Purple', 'Grey', 'Custom', 'None'];
    const map = {
      '#F44336': 'Red',
      '#2196F3': 'Blue',
      '#FF9800': 'Orange',
      '#4CAF50': 'Green',
      '#9C27B0': 'Purple',
      '#9E9E9E': 'Grey',
    };
    final groups = <String, List<TrainingPack>>{};
    for (final p in packs) {
      final name = map[p.colorTag] ?? (p.colorTag.isEmpty ? 'None' : 'Custom');
      groups.putIfAbsent(name, () => []).add(p);
    }
    for (final g in groups.values) {
      g.sort((a, b) => a.name.compareTo(b.name));
    }
    final colors = [for (final c in order) if (groups.containsKey(c)) c];
    final itemCount = colors.fold<int>(0, (s, c) => s + 1 + groups[c]!.length);
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        int count = 0;
        for (final color in colors) {
          if (index == count) {
            return Container(
              color: AppColors.cardBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(color,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
          count++;
          final list = groups[color]!;
          if (index < count + list.length) {
            final pack = list[index - count];
            final pct = pack.pctComplete;
            final completed = _isPackCompleted(pack);
            return ListTile(
              leading: pack.isBuiltIn
                  ? const Text('📦')
                  : InfoTooltip(
                      message: pack.colorTag.isEmpty
                          ? 'No color tag'
                          : 'Color tag ${pack.colorTag} (tap to edit)',
                      child: pack.colorTag.isEmpty
                          ? const Icon(Icons.circle_outlined, color: Colors.white24)
                          : Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colorFromHex(pack.colorTag),
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
              title: Row(
                children: [
                  Expanded(child: Text(pack.name)),
                  if (DateTime.now().difference(pack.createdAt).inDays < 7)
                    const SizedBox(width: 4),
                  if (DateTime.now().difference(pack.createdAt).inDays < 7)
                    const NewChip(),
                  const SizedBox(width: 4),
                  DifficultyChip(pack.difficulty),
                  const SizedBox(width: 4),
                  InfoTooltip(
                    message: pct == 1
                        ? 'Completed!'
                        : 'Solved ${pack.solved} of ${pack.hands.length} hands',
                    child: ProgressChip(pct),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  InfoTooltip(
                    message: pack.gameType == GameType.tournament
                        ? 'Blind levels, ICM pressure.'
                        : '100 BB deep, no blind escalation.',
                    child: Text(pack.gameType.label),
                  ),
                  const Text(' • '),
                  Text(pack.spots.isNotEmpty
                      ? '${pack.spots.length} spots'
                      : '${pack.hands.length} hands'),
                ],
              ),
              trailing:
                  completed ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingPackScreen(pack: pack),
                  ),
                );
                setState(() {});
              },
            );
          }
          count += list.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}
