import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/training/engine/training_type_engine.dart';
import '../services/tag_matrix_coverage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/tag_matrix_coverage_filters.dart';
import '../widgets/tag_matrix_coverage_table.dart';

class TagMatrixCoverageScreen extends StatefulWidget {
  const TagMatrixCoverageScreen({super.key});

  @override
  State<TagMatrixCoverageScreen> createState() =>
      _TagMatrixCoverageScreenState();
}

class _TagMatrixCoverageScreenState extends State<TagMatrixCoverageScreen> {
  bool _loading = true;
  TrainingType? _type;
  bool _starter = false;
  TagMatrixResult? _result;
  final _service = const TagMatrixCoverageService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _service.load(type: _type, starter: _starter);
    if (!mounted) return;
    setState(() {
      _result = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Matrix Coverage'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TagMatrixCoverageFilters(
            type: _type,
            starter: _starter,
            onTypeChanged: (v) {
              setState(() => _type = v);
              _load();
            },
            onStarterChanged: (v) {
              setState(() => _starter = v);
              _load();
            },
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: _loading || _result == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TagMatrixCoverageTable(
                  axes: _result!.axes,
                  data: _result!.cells,
                  max: _result!.max,
                ),
              ],
            ),
    );
  }
}
