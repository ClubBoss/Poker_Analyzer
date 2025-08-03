import 'package:pdf/widgets.dart' as pw;

import '../models/saved_hand.dart';
import 'date_utils.dart';

class ExportUtils {
  const ExportUtils._();

  static String handMarkdown(SavedHand hand, {int level = 2}) {
    final buffer = StringBuffer();
    final title = hand.name.isNotEmpty ? hand.name : 'Без названия';
    buffer.writeln('${'#' * level} $title');
    final userAction = hand.expectedAction;
    if (userAction != null && userAction.isNotEmpty) {
      buffer.writeln('- Действие: $userAction');
    }
    if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty) {
      buffer.writeln('- GTO: ${hand.gtoAction}');
    }
    if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty) {
      buffer.writeln('- Группа: ${hand.rangeGroup}');
    }
    if (hand.comment != null && hand.comment!.isNotEmpty) {
      buffer.writeln('- Комментарий: ${hand.comment}');
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
    if (hand.expectedAction != null && hand.expectedAction!.isNotEmpty) {
      widgets.add(pw.Text('Действие: ${hand.expectedAction}',
          style: pw.TextStyle(font: regular)));
    }
    if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty) {
      widgets.add(pw.Text('GTO: ${hand.gtoAction}',
          style: pw.TextStyle(font: regular)));
    }
    if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty) {
      widgets.add(pw.Text('Группа: ${hand.rangeGroup}',
          style: pw.TextStyle(font: regular)));
    }
    if (hand.comment != null && hand.comment!.isNotEmpty) {
      widgets.add(pw.Text('Комментарий: ${hand.comment}',
          style: pw.TextStyle(font: regular)));
    }
    widgets.add(pw.SizedBox(height: 12));
    return widgets;
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
      formatDuration(duration),
      count,
      correct,
      ev,
      icm,
    ];
  }
}
