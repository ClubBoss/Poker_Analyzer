import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../services/theory_yaml_importer.dart';
import '../theme/app_colors.dart';
import 'training_pack_preview_screen.dart';
import '../services/booster_preview_launcher.dart';

class TheoryBoosterPreviewScreen extends StatefulWidget {
  const TheoryBoosterPreviewScreen({super.key});

  @override
  State<TheoryBoosterPreviewScreen> createState() =>
      _TheoryBoosterPreviewScreenState();
}

class _TheoryBoosterPreviewScreenState
    extends State<TheoryBoosterPreviewScreen> {
  final List<TrainingPackTemplateV2> _packs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    const importer = TheoryYamlImporter();
    final list = await importer.importFromDirectory('yaml_out/boosters');
    if (!mounted) return;
    setState(() {
      _packs
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  void _open(TrainingPackTemplateV2 tpl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPreviewScreen(template: tpl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Theory Preview')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _packs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final tpl = _packs[i];
                final type = tpl.meta['booster'] == true ? 'booster' : 'theory';
                final count = tpl.spotCount;
                return ListTile(
                  title: Text(tpl.name),
                  subtitle: Text('Spots: $count • $type'),
                  onTap: () => _open(tpl),
                  trailing: TextButton.icon(
                    onPressed: () =>
                        const BoosterPreviewLauncher().launch(context, tpl),
                    icon: const Text("▶️"),
                    label: const Text("Запустить"),
                  ),
                );
              },
            ),
    );
  }
}
