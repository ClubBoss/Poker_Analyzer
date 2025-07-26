import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/theory_pack_library_service.dart';
import '../models/theory_pack_model.dart';
import '../ui/tools/theory_pack_quick_view.dart';
import '../theme/app_colors.dart';
import '../services/theory_pack_review_status_engine.dart';
import '../services/theory_pack_completion_estimator.dart';

/// Developer screen to browse and preview all bundled theory packs.
class TheoryPackDebuggerScreen extends StatefulWidget {
  const TheoryPackDebuggerScreen({super.key});

  @override
  State<TheoryPackDebuggerScreen> createState() => _TheoryPackDebuggerScreenState();
}

class _TheoryPackDebuggerScreenState extends State<TheoryPackDebuggerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TheoryPackModel> _packs = [];
  bool _loading = true;
  final _reviewEngine = const TheoryPackReviewStatusEngine();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await TheoryPackLibraryService.instance.loadAll();
    if (!mounted) return;
    setState(() {
      _packs = TheoryPackLibraryService.instance.all;
      _loading = false;
    });
  }

  List<TheoryPackModel> get _filtered {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _packs;
    return [
      for (final p in _packs)
        if (p.id.toLowerCase().contains(query) ||
            p.title.toLowerCase().contains(query))
          p
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('📘 Theory Pack Debugger'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search by ID or title'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final pack = _filtered[i];
                final status = _reviewEngine.getStatus(pack);
                final completion = const TheoryPackCompletionEstimator()
                    .estimate(pack);
                Widget icon;
                switch (status) {
                  case ReviewStatus.approved:
                    icon = const Icon(Icons.check_circle, color: Colors.green);
                    break;
                  case ReviewStatus.draft:
                    icon = const Icon(Icons.edit, color: Colors.yellow);
                    break;
                  case ReviewStatus.rewrite:
                    icon = const Icon(Icons.error, color: Colors.orange);
                    break;
                }
                return ListTile(
                  title: Text(pack.title.isNotEmpty ? pack.title : '(no title)'),
                  subtitle: Text(
                    '${pack.id} • ${completion.wordCount}w • ${completion.estimatedMinutes}m',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${pack.sections.length}'),
                      const SizedBox(width: 8),
                      Text('${(completion.completionRatio * 100).toStringAsFixed(0)}%'),
                      const SizedBox(width: 8),
                      icon,
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => TheoryPackQuickView.launch(context, pack),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

