import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../services/learning_path_registry_service.dart';
import '../widgets/smart_path_preview_card.dart';
import '../models/path_difficulty.dart';

/// Sorting options for [PathLibraryScreen].
enum PathSort { name, length, date }

/// Screen displaying all learning paths as [SmartPathPreviewCard] widgets.
class PathLibraryScreen extends StatefulWidget {
  const PathLibraryScreen({super.key});

  @override
  State<PathLibraryScreen> createState() => _PathLibraryScreenState();
}

class _PathLibraryScreenState extends State<PathLibraryScreen> {
  late Future<List<LearningPathTemplateV2>> _future;
  PathDifficulty? _filter;
  PathSort _sort = PathSort.name;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LearningPathTemplateV2>> _load() async {
    try {
      final list = await LearningPathRegistryService.instance.loadAll();
      return list;
    } catch (_) {
      _error = true;
      return [];
    }
  }

  PathDifficulty _difficultyOf(LearningPathTemplateV2 tpl) {
    if (tpl.difficulty != null) return tpl.difficulty!;
    final count = tpl.stages.length;
    if (count <= 3) return PathDifficulty.easy;
    if (count <= 6) return PathDifficulty.medium;
    return PathDifficulty.hard;
  }

  List<LearningPathTemplateV2> _process(List<LearningPathTemplateV2> list) {
    var result = List<LearningPathTemplateV2>.from(list);
    if (_filter != null) {
      result = result.where((p) => _difficultyOf(p) == _filter).toList();
    }
    switch (_sort) {
      case PathSort.length:
        result.sort((a, b) => a.stages.length.compareTo(b.stages.length));
        break;
      case PathSort.name:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case PathSort.date:
        result.sort((a, b) => a.id.compareTo(b.id));
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пути обучения')),
      body: FutureBuilder<List<LearningPathTemplateV2>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error) {
            return const Center(child: Text('Ошибка загрузки'));
          }
          final list = _process(snapshot.data ?? const []);
          if (list.isEmpty) {
            return const Center(child: Text('Нет доступных путей'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    DropdownButton<PathDifficulty?>(
                      value: _filter,
                      hint: const Text('Сложность'),
                      onChanged: (val) => setState(() => _filter = val),
                      items: [
                        const DropdownMenuItem<PathDifficulty?>(
                          value: null,
                          child: Text('Все'),
                        ),
                        const DropdownMenuItem(
                          value: PathDifficulty.easy,
                          child: Text('Легкие'),
                        ),
                        const DropdownMenuItem(
                          value: PathDifficulty.medium,
                          child: Text('Средние'),
                        ),
                        const DropdownMenuItem(
                          value: PathDifficulty.hard,
                          child: Text('Сложные'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<PathSort>(
                      value: _sort,
                      onChanged: (val) {
                        if (val != null) setState(() => _sort = val);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: PathSort.name,
                          child: Text('По названию'),
                        ),
                        DropdownMenuItem(
                          value: PathSort.length,
                          child: Text('По длине'),
                        ),
                        DropdownMenuItem(
                          value: PathSort.date,
                          child: Text('По дате'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final tpl = list[index];
                    return SmartPathPreviewCard(
                      pathId: tpl.id,
                      pathTitle: tpl.title,
                      pathDescription: tpl.description,
                      stageCount: tpl.stages.length,
                      packCount: tpl.packCount,
                      coverAsset: tpl.coverAsset,
                      difficulty: _difficultyOf(tpl),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
