import 'dart:io';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class BoosterAutoTestReport {
  final List<String> passed;
  final Map<String, List<String>> failed;

  BoosterAutoTestReport({
    List<String>? passed,
    Map<String, List<String>>? failed,
  }) : passed = passed ?? <String>[],
       failed = failed ?? <String, List<String>>{};

  Map<String, dynamic> toJson() => {'passed': passed, 'failed': failed};
}

class BoosterPackAutoTester {
  BoosterPackAutoTester();

  Future<BoosterAutoTestReport> testAll({
    String dir = 'yaml_out/boosters',
  }) async {
    final report = BoosterAutoTestReport();
    final directory = Directory(dir);
    if (!directory.existsSync()) return report;
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final file in files) {
      final path = file.path;
      try {
        final yaml = await file.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlString(yaml);
        final errors = _validate(tpl);
        if (errors.isEmpty) {
          report.passed.add(path);
        } else {
          report.failed[path] = errors;
        }
      } catch (e) {
        report.failed[path] = ['load_failed: $e'];
      }
    }
    return report;
  }

  List<String> _validate(TrainingPackTemplateV2 pack) {
    final errors = <String>[];
    if (pack.spots.isEmpty) errors.add('missing_spots');
    final ids = <String>{};
    for (final s in pack.spots) {
      if (!ids.add(s.id)) errors.add('duplicate_id:${s.id}');
      errors.addAll(_validateSpot(s));
    }
    return errors;
  }

  List<String> _validateSpot(TrainingPackSpot s) {
    final errs = <String>[];
    if (s.hand.heroCards.trim().isEmpty) errs.add('no_cards:${s.id}');
    if (s.hand.position == HeroPosition.unknown) errs.add('no_pos:${s.id}');
    if (_heroAction(s) == null) errs.add('no_action:${s.id}');
    return errs;
  }

  String? _heroAction(TrainingPackSpot s) {
    for (final acts in s.hand.actions.values) {
      for (final a in acts) {
        if (a.playerIndex == s.hand.heroIndex) return a.action.toLowerCase();
      }
    }
    return null;
  }
}
