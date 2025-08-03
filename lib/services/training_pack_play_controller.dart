import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import '../helpers/training_pack_storage.dart';
import '../models/v2/training_pack_template.dart';
import '../screens/v2/training_pack_play_screen.dart';

class TrainingPackPlayController extends ChangeNotifier {
  final ValueNotifier<bool> hasIncompleteSession = ValueNotifier(false);
  TrainingPackTemplate? _template;
  int _progress = 0;

  TrainingPackTemplate? get template => _template;
  int get progress => _progress;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    String? id;
    int ts = 0;
    for (final k in prefs.getKeys()) {
      if (k.startsWith('tpl_prog_')) {
        final pack = k.substring(9);
        final t = prefs.getInt('tpl_ts_$pack') ?? 0;
        if (t > ts) {
          ts = t;
          id = pack;
        }
      }
    }
    if (id == null || ts == 0) {
      hasIncompleteSession.value = false;
      _template = null;
      _progress = 0;
      return;
    }
    final templates = await TrainingPackStorage.load();
    final tpl = templates.firstWhere(
      (t) => t.id == id,
      orElse: () => TrainingPackTemplate(id: '', name: ''),
    );
    if (tpl.id.isEmpty) {
      hasIncompleteSession.value = false;
      _template = null;
      _progress = 0;
      return;
    }
    final idx = prefs.getInt('tpl_prog_$id') ?? 0;
    if (idx >= tpl.spots.length - 1) {
      hasIncompleteSession.value = false;
      _template = null;
      _progress = 0;
      return;
    }
    _template = tpl;
    _progress = (((idx + 1) / tpl.spots.length) * 100).round();
    hasIncompleteSession.value = true;
  }

  Future<void> resume(BuildContext context) async {
    final tpl = _template;
    if (tpl == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(template: tpl, original: tpl),
      ),
    );
    await load();
  }
}
