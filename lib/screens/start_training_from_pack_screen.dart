import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import '../helpers/training_pack_storage.dart';
import '../models/v2/training_pack_template.dart';
import '../helpers/pack_spot_utils.dart';
import 'training_screen.dart';

class StartTrainingFromPackScreen extends StatefulWidget {
  const StartTrainingFromPackScreen({super.key});

  @override
  State<StartTrainingFromPackScreen> createState() =>
      _StartTrainingFromPackScreenState();
}

class _StartTrainingFromPackScreenState
    extends State<StartTrainingFromPackScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = true;
  String? _last;
  static const _lastKey = 'last_pack_template';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await TrainingPackStorage.load();
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastKey);
    if (!mounted) return;
    setState(() {
      _templates.addAll(list);
      _last = last;
      _loading = false;
    });
  }

  Future<void> _start(TrainingPackTemplate tpl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, tpl.name);
    setState(() => _last = tpl.name);
    final hands = [
      for (final s in tpl.spots) handFromPackSpot(s, anteBb: tpl.anteBb),
    ];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScreen.drill(
          hands: hands,
          templateId: tpl.id,
          templateName: tpl.name,
          minEvForCorrect: tpl.minEvForCorrect,
          anteBb: tpl.anteBb,
        ),
      ),
    );
  }

  void _continueLast() {
    final tpl = _templates.firstWhereOrNull((t) => t.name == _last);
    if (tpl != null) {
      _start(tpl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Training')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _templates.length + (_last != null ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (_last != null && index == 0) {
                  return ListTile(
                    title: const Text('Continue Last Pack'),
                    subtitle: Text(_last!),
                    leading: const Icon(Icons.play_arrow),
                    onTap: _continueLast,
                  );
                }
                final t = _templates[index - (_last != null ? 1 : 0)];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.spots.length} spots'),
                  onTap: () => _start(t),
                );
              },
            ),
    );
  }
}
