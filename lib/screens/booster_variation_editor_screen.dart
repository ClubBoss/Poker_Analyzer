import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../services/booster_cluster_engine.dart';
import 'v2/training_pack_spot_editor_screen.dart';
import '../theme/app_colors.dart';
import '../core/training/engine/training_type_engine.dart';

class BoosterVariationEditorScreen extends StatefulWidget {
  const BoosterVariationEditorScreen({super.key});
  @override
  State<BoosterVariationEditorScreen> createState() =>
      _BoosterVariationEditorScreenState();
}

class _BoosterVariationEditorScreenState
    extends State<BoosterVariationEditorScreen> {
  File? _file;
  TrainingPackTemplateV2? _pack;
  bool _loading = true;
  List<SpotCluster> _clusters = [];

  @override
  void initState() {
    super.initState();
    _pick();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['yaml', 'yml'],
    );
    if (result == null || result.files.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final path = result.files.single.path;
    if (path == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final file = File(path);
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      final clusters = const BoosterClusterEngine().analyzePack(tpl);
      if (!mounted) return;
      setState(() {
        _file = file;
        _pack = tpl;
        _clusters = clusters;
        _loading = false;
      });
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    final pack = _pack;
    final file = _file;
    if (pack == null || file == null) return;
    pack.spotCount = pack.spots.length;
    await file.writeAsString(pack.toYamlString());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  Future<void> _editSpot(TrainingPackSpot spot) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackSpotEditorScreen(
          spot: spot,
          templateTags: _pack?.tags ?? const [],
          trainingType: _pack?.trainingType ?? TrainingType.postflop,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _removeSpot(TrainingPackSpot spot) {
    setState(() {
      _pack?.spots.removeWhere((s) => s.id == spot.id);
    });
  }

  Future<void> _cloneVariation(TrainingPackSpot spot) async {
    final copy = spot.copyWith(
      id: const Uuid().v4(),
      meta: {
        ...spot.meta,
        'variation': true,
      },
    );
    _pack?.spots.add(copy);
    await _editSpot(copy);
  }

  Future<void> _addVariation(TrainingPackSpot original) async {
    final copy = original.copyWith(
      id: const Uuid().v4(),
      meta: {
        ...original.meta,
        'variation': true,
      },
    );
    _pack?.spots.add(copy);
    await _editSpot(copy);
  }

  bool _isVariation(TrainingPackSpot s) =>
      s.meta['variation'] == true || s.id.contains('_var');

  String _spotTitle(TrainingPackSpot s) {
    return s.title.isNotEmpty ? s.title : s.hand.heroCards;
  }

  String _spotSub(TrainingPackSpot s) {
    final board = (s.board.isNotEmpty ? s.board : s.hand.board).join(' ');
    return '${s.hand.position.label} $board';
  }

  Map<TrainingPackSpot, List<TrainingPackSpot>> _buildGroups() {
    final map = <TrainingPackSpot, List<TrainingPackSpot>>{};
    final pack = _pack;
    if (pack == null) return map;
    final originals =
        pack.spots.where((s) => !_isVariation(s)).toList();
    for (final o in originals) {
      map[o] = [];
    }
    for (final varSpot in pack.spots.where(_isVariation)) {
      final m = RegExp(r'^(.*)_var').firstMatch(varSpot.id);
      final id = m?.group(1);
      final orig = originals.firstWhereOrNull((e) => e.id == id);
      if (orig != null) {
        map[orig]!.add(varSpot);
      } else {
        for (final c in _clusters) {
          if (c.spots.any((s) => s.id == varSpot.id)) {
            final cand = c.spots.firstWhereOrNull((s) => !_isVariation(s));
            if (cand != null) {
              map.putIfAbsent(cand, () => []).add(varSpot);
            }
            break;
          }
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final pack = _pack;
    return Scaffold(
      appBar: AppBar(
        title: Text(_file == null
            ? 'Booster Variation Editor'
            : _file!.path.split(Platform.pathSeparator).last),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      backgroundColor: AppColors.background,
      body: _loading || pack == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in _buildGroups().entries)
                  Card(
                    color: AppColors.cardBackground,
                    child: ExpansionTile(
                      title: Text(_spotTitle(entry.key)),
                      subtitle: Text(_spotSub(entry.key)),
                      children: [
                        for (final v in entry.value)
                          ListTile(
                            title: Text(_spotTitle(v)),
                            subtitle: Text(_spotSub(v)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: v.meta['disabled'] != true,
                                  onChanged: (on) {
                                    setState(() {
                                      if (on) {
                                        v.meta.remove('disabled');
                                      } else {
                                        v.meta['disabled'] = true;
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => _cloneVariation(v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeSpot(v),
                                ),
                              ],
                            ),
                            onTap: () => _editSpot(v),
                          ),
                        TextButton(
                          onPressed: () => _addVariation(entry.key),
                          child: const Text('＋ Variation'),
                        ),
                      ],
                    ),
                  ),
                if (pack.spots.isEmpty)
                  const Center(child: Text('No spots')),
              ],
            ),
    );
  }
}
