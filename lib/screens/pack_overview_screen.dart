
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/color_utils.dart';
import '../helpers/date_utils.dart';
import '../models/training_pack.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../services/training_pack_storage_service.dart';
import '../services/pack_filter_controller.dart';
import '../helpers/poker_street_helper.dart';
import '../services/pack_sort_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';
import 'pack_editor_screen.dart';
import 'training_pack_screen.dart';

class PackOverviewScreen extends StatefulWidget {
  const PackOverviewScreen({super.key});

  @override
  State<PackOverviewScreen> createState() => _PackOverviewScreenState();
}

class _PackOverviewScreenState extends State<PackOverviewScreen> {
  final _filter = PackFilterController();
  final _searchController = TextEditingController();
  final _sort = PackSortController();

  double _calcAverage(List<TrainingPack> packs) {
    var sum = 0.0;
    var count = 0;
    for (final p in packs) {
      if (p.history.isEmpty) continue;
      final h = p.history.last;
      if (h.total == 0) continue;
      sum += h.correct * 100 / h.total;
      count++;
    }
    return count > 0 ? sum / count : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _filter.load().then((_) {
      _searchController.text = _filter.query.value;
      _filter.query.addListener(() {
        if (_searchController.text != _filter.query.value) {
          _searchController.text = _filter.query.value;
        }
      });
      if (mounted) setState(() {});
    });
    _sort.load().then((_) {
      if (mounted) setState(() {});
    });
    final storage = context.read<TrainingPackStorageService>();
    context
        .read<TrainingPackCloudSyncService>()
        .watch(storage)
        ?.onData((_) {
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    context.read<TrainingPackCloudSyncService>().cancelWatch();
    _filter.dispose();
    _sort.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sharePack(TrainingPack pack) async {
    final file = await context.read<TrainingPackStorageService>().exportPackTemp(pack);
    if (!mounted || file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Check out my Poker Analyzer pack!');
    if (await file.exists()) await file.delete();
  }

  Future<void> _exportPack(TrainingPack pack) async {
    final file = await context.read<TrainingPackStorageService>().exportPack(pack);
    if (!mounted || file == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранён: ${file.path}')),
    );
  }

  Future<void> _renamePack(TrainingPack pack) async {
    final controller = TextEditingController(text: pack.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != pack.name) {
      await context.read<TrainingPackStorageService>().renamePack(pack, result);
    }
  }

  Future<void> _duplicatePack(TrainingPack pack) async {
    final copy = await context.read<TrainingPackStorageService>().duplicatePack(pack);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PackEditorScreen(pack: copy)),
    );
  }

  Future<void> _deletePack(TrainingPack pack) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить пак "${pack.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (confirm == true) {
      final result = await context.read<TrainingPackStorageService>().removePack(pack);
      if (result != null && mounted) {
        final snack = SnackBar(
          content: const Text('Пак удалён'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                context.read<TrainingPackStorageService>().restorePack(result.\$1, result.\$2),
          ),
          duration: const Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snack);
      }
    }
  }

  void _showMenu(TrainingPack pack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _sharePack(pack);
              },
            ),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.white),
            title: const Text('Export', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await _exportPack(pack);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline, color: Colors.white),
            title: const Text('Rename', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await _renamePack(pack);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: Colors.white),
            title: const Text('Duplicate', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await _duplicatePack(pack);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.white),
            title: const Text('Delete', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
                await _deletePack(pack);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = context
        .watch<TrainingPackStorageService>()
        .packs
        .where((p) => !p.isBuiltIn)
        .toList();
    final categories = {for (final p in all) p.category};
    List<TrainingPack> packs = all.where((p) {
      final q = _filter.query.value.trim().toLowerCase();
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) return false;
      if (_filter.categories.isNotEmpty && !_filter.categories.contains(p.category)) {
        return false;
      }
      if (_filter.difficulties.isNotEmpty && !_filter.difficulties.contains(p.difficulty)) {
        return false;
      }
      if (_filter.streets.isNotEmpty) {
        final streets = {for (final h in p.hands) streetName(h.boardStreet)};
        if (!_filter.streets.every(streets.contains)) return false;
      }
      return true;
    }).toList();
    switch (_sort.value) {
      case PackSort.nameAsc:
        packs.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PackSort.lastPlayed:
        packs.sort((a, b) => b.lastAttemptDate.compareTo(a.lastAttemptDate));
        break;
      case PackSort.difficulty:
        packs.sort((a, b) => a.difficulty.compareTo(b.difficulty));
        break;
      case PackSort.updatedDesc:
        packs.sort((a, b) => b.lastAttemptDate.compareTo(a.lastAttemptDate));
        break;
    }
    final avg = _calcAverage(packs);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Packs'),
        centerTitle: true,
        actions: [
          ValueListenableBuilder(
            valueListenable: _sort,
            builder: (context, sort, _) => DropdownButton<PackSort>(
              value: sort,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.sort, color: Colors.white),
              dropdownColor: AppColors.cardBackground,
              onChanged: (v) => v == null ? null : _sort.setSort(v),
              items: const [
                DropdownMenuItem(
                    value: PackSort.nameAsc, child: Text('A-Z')),
                DropdownMenuItem(
                    value: PackSort.lastPlayed, child: Text('Последний запуск')),
                DropdownMenuItem(
                    value: PackSort.difficulty, child: Text('Сложность')),
                DropdownMenuItem(
                    value: PackSort.updatedDesc, child: Text('Обновлено')),
              ],
            ),
          ),
          SyncStatusIcon.of(context)
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Паков: ${packs.length}', style: const TextStyle(color: Colors.white)),
                Text('Средняя точность: ${avg.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: _filter.setQuery,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(c),
                      selected: _filter.categories.contains(c),
                      onSelected: (_) => setState(() => _filter.toggleCategory(c)),
                    ),
                  ),
                for (final s in kStreetNames)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(s),
                      selected: _filter.streets.contains(s),
                      onSelected: (_) => setState(() => _filter.toggleStreet(s)),
                    ),
                  ),
                for (final d in [1, 2, 3])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text('D$d'),
                      selected: _filter.difficulties.contains(d),
                      onSelected: (_) => setState(() => _filter.toggleDifficulty(d)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context
                  .read<TrainingPackCloudSyncService>()
                  .syncDown(context.read<TrainingPackStorageService>()),
              child: ListView.separated(
                itemCount: packs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = packs[index];
                  final color = p.colorTag.isEmpty ? Colors.white24 : colorFromHex(p.colorTag);
                  final progress = p.pctComplete;
                  final date = p.lastAttempted > 0 ? formatDate(p.lastAttemptDate) : '-';
                  return GestureDetector(
                    onLongPress: () => _showMenu(p),
                    child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: p)),
                      );
                    },
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    title: Text(p.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Последняя: $date',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
