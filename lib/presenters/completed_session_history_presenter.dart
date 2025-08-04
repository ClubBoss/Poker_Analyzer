import 'package:intl/intl.dart';
import 'package:poker_analyzer/services/completed_session_summary_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

class CompletedSessionDisplayItem {
  final String title;
  final String subtitle;
  final String fingerprint;
  final DateTime timestamp;

  const CompletedSessionDisplayItem({
    required this.title,
    required this.subtitle,
    required this.fingerprint,
    required this.timestamp,
  });
}

class CompletedSessionHistoryPresenter {
  const CompletedSessionHistoryPresenter();

  List<CompletedSessionDisplayItem> present(
    List<CompletedSessionSummary> summaries,
  ) {
    return summaries.map(_buildItem).toList();
  }

  CompletedSessionDisplayItem _buildItem(CompletedSessionSummary summary) {
    String packName = 'Unknown Pack';
    try {
      packName = TrainingPackTemplateV2.fromYamlString(summary.yaml).name;
    } catch (_) {}

    TrainingType? typeEnum;
    try {
      typeEnum = TrainingType.values.firstWhere(
        (t) => t.name == summary.trainingType,
      );
    } catch (_) {}
    final typeLabel = typeEnum?.label ?? summary.trainingType;

    final title = '$typeLabel Pack: $packName';

    final dateStr = DateFormat.yMMMd(
      Intl.getCurrentLocale(),
    ).format(summary.timestamp);
    var subtitle = 'Completed on $dateStr';
    if (summary.accuracy != null) {
      final percent = (summary.accuracy! * 100).toStringAsFixed(0);
      subtitle += ', Accuracy: $percent%';
    }

    return CompletedSessionDisplayItem(
      title: title,
      subtitle: subtitle,
      fingerprint: summary.fingerprint,
      timestamp: summary.timestamp,
    );
  }
}
