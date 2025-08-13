import 'dart:convert';
import 'package:collection/collection.dart';
import '../models/v2/training_pack_template_v2.dart';

class YamlPackDiffService {
  const YamlPackDiffService();

  String generateMarkdownDiff(
    TrainingPackTemplateV2 oldPack,
    TrainingPackTemplateV2 newPack,
  ) {
    final buffer = StringBuffer();
    _section(buffer, 'Meta', _metaDiff(oldPack, newPack));
    _section(buffer, 'Tags', _tagsDiff(oldPack, newPack));
    _section(buffer, 'Spots', _spotsDiff(oldPack, newPack));
    _section(buffer, 'Explanation', _explDiff(oldPack, newPack));
    return buffer.toString().trimRight();
  }

  void _section(StringBuffer buf, String title, List<String> lines) {
    if (lines.isEmpty) return;
    buf
      ..writeln('## $title')
      ..writeln(lines.join('\n'))
      ..writeln();
  }

  List<String> _metaDiff(
    TrainingPackTemplateV2 a,
    TrainingPackTemplateV2 b,
  ) {
    const ignore = {'id', 'createdAt', 'updatedAt'};
    const eq = DeepCollectionEquality();
    final keys = {...a.meta.keys, ...b.meta.keys}..removeWhere(ignore.contains);
    final out = <String>[];
    for (final k in keys) {
      final av = a.meta[k];
      final bv = b.meta[k];
      if (eq.equals(av, bv)) continue;
      if (av == null) {
        out.add('- 🟩 `$k`: ${_fmt(bv)}');
      } else if (bv == null) {
        out.add('- 🟥 `$k`: ${_fmt(av)}');
      } else {
        out.add('- 🟨 `$k`: `${_fmt(av)}` → `${_fmt(bv)}`');
      }
    }
    return out;
  }

  List<String> _tagsDiff(
    TrainingPackTemplateV2 a,
    TrainingPackTemplateV2 b,
  ) {
    final setA = a.tags.toSet();
    final setB = b.tags.toSet();
    final out = <String>[];
    for (final t in setB.difference(setA)) {
      out.add('- 🟩 $t');
    }
    for (final t in setA.difference(setB)) {
      out.add('- 🟥 $t');
    }
    return out;
  }

  List<String> _spotsDiff(
    TrainingPackTemplateV2 a,
    TrainingPackTemplateV2 b,
  ) {
    final mapA = {for (final s in a.spots) s.id: s};
    final mapB = {for (final s in b.spots) s.id: s};
    final ids = {...mapA.keys, ...mapB.keys};
    final out = <String>[];
    const eq = DeepCollectionEquality();
    for (final id in ids) {
      final sa = mapA[id];
      final sb = mapB[id];
      if (sa == null) {
        out.add('- 🟩 $id');
      } else if (sb == null) {
        out.add('- 🟥 $id');
      } else {
        final ma = Map<String, dynamic>.from(sa.toJson())
          ..removeWhere((k, _) =>
              k == 'id' ||
              k == 'createdAt' ||
              k == 'updatedAt' ||
              k == 'editedAt' ||
              k == 'explanation');
        final mb = Map<String, dynamic>.from(sb.toJson())
          ..removeWhere((k, _) =>
              k == 'id' ||
              k == 'createdAt' ||
              k == 'updatedAt' ||
              k == 'editedAt' ||
              k == 'explanation');
        if (!eq.equals(ma, mb)) out.add('- 🟨 $id');
      }
    }
    return out;
  }

  List<String> _explDiff(
    TrainingPackTemplateV2 a,
    TrainingPackTemplateV2 b,
  ) {
    final mapA = {for (final s in a.spots) s.id: s};
    final mapB = {for (final s in b.spots) s.id: s};
    final ids = {...mapA.keys, ...mapB.keys};
    final out = <String>[];
    for (final id in ids) {
      final ea = mapA[id]?.explanation?.trim();
      final eb = mapB[id]?.explanation?.trim();
      if ((ea ?? '') == (eb ?? '')) continue;
      if (ea == null || ea.isEmpty) {
        out.add('- $id: 🟩 ${eb ?? ''}');
      } else if (eb == null || eb.isEmpty) {
        out.add('- $id: 🟥 $ea');
      } else {
        out.add('- $id: 🟨 `$ea` → `$eb`');
      }
    }
    return out;
  }

  String _fmt(dynamic v) {
    if (v is String) return v;
    return jsonEncode(v);
  }
}
