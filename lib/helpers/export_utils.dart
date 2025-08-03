import 'package:pdf/widgets.dart' as pw;

import '../models/saved_hand.dart';
import 'date_utils.dart';

class ExportUtils {
  const ExportUtils._();

  static Map<String, String?> _handFields(SavedHand hand) => {
        'Действие': hand.expectedAction,
        'GTO': hand.gtoAction,
        'Группа': hand.rangeGroup,
        'Комментарий': hand.comment,
      };

  static String handMarkdown(SavedHand hand, {int level = 2}) {
    final buffer = StringBuffer();
    final title = hand.name.isNotEmpty ? hand.name : 'Без названия';
    buffer.writeln('${'#' * level} $title');
    for (final entry in _handFields(hand).entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        buffer.writeln('- ${entry.key}: $value');
      }
    }
    buffer.writeln();
    return buffer.toString();
  }

  static List<pw.Widget> handPdfWidgets(
    SavedHand hand,
    pw.Font regular,
    pw.Font bold, {
    double titleSize = 18,
  }) {
    final widgets = <pw.Widget>[
      pw.Text(
        hand.name.isNotEmpty ? hand.name : 'Без названия',
        style: pw.TextStyle(font: bold, fontSize: titleSize),
      ),
      pw.SizedBox(height: 8),
    ];
    for (final entry in _handFields(hand).entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        widgets.add(pw.Text('${entry.key}: $value',
            style: pw.TextStyle(font: regular)));
      }
    }
    widgets.add(pw.SizedBox(height: 12));
    return widgets;
  }

  static String durationString(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final parts = <String>[];
    if (h > 0) parts.add('$hч');
    parts.add('$mм');
    return parts.join(' ');
  }

  static List<dynamic> csvRow(
    DateTime date,
    Duration duration,
    int count,
    int correct,
    double? evAvg,
    double? icmAvg,
  ) {
    final ev = evAvg != null ? evAvg.toStringAsFixed(1) : '';
    final icm = icmAvg != null ? icmAvg.toStringAsFixed(3) : '';
    return [
      formatDateTime(date),
      durationString(duration),
      count,
      correct,
      ev,
      icm,
    ];
  }
}
