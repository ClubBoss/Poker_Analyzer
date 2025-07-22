import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../services/pack_library_loader_service.dart';
import '../services/training_session_launcher.dart';
import '../models/v2/training_pack_template_v2.dart';

class TagDrillLauncher extends StatefulWidget {
  final String tag;
  const TagDrillLauncher({super.key, required this.tag});

  @override
  State<TagDrillLauncher> createState() => _TagDrillLauncherState();
}

class _TagDrillLauncherState extends State<TagDrillLauncher> {
  bool _loading = true;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final tag = widget.tag.toLowerCase();
    final list = PackLibraryLoaderService.instance.library;
    final pack = list.firstWhereOrNull(
      (p) => p.tags.map((t) => t.toLowerCase()).contains(tag),
    );
    if (mounted) {
      setState(() {
        _pack = pack;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    await const TrainingSessionLauncher().launch(tpl);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: _start,
        child: const Text('🎯 Practice this tag now'),
      ),
    );
  }
}
