import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class YamlPackMarkdownPreviewService {
  const YamlPackMarkdownPreviewService();

  String generateMarkdownPreview(TrainingPackTemplateV2 pack) {
    final spots = pack.spots;
    final total = spots.length;
    final evCount = spots.where((s) => s.heroEv != null).length;
    final icmCount = spots.where((s) => s.heroIcmEv != null).length;
    final positions = <String>{for (final s in spots) s.hand.position.label};
    final author = pack.meta['author']?.toString();
    final buffer = StringBuffer()
      ..writeln('# ${pack.name}')
      ..writeln();
    if (pack.description.trim().isNotEmpty) {
      buffer.writeln(pack.description.trim());
      buffer.writeln();
    }
    if (author != null && author.isNotEmpty) {
      buffer.writeln('_Author: $author_');
      buffer.writeln();
    }
    buffer
      ..writeln('|id|heroPos|action|EV|ICM|comment|')
      ..writeln('|---|---|---|---|---|---|');
    for (final s in spots) {
      final id = s.id;
      final pos = s.hand.position.label;
      final action = _heroAction(s) ?? '—';
      final ev = s.heroEv != null ? s.heroEv!.toStringAsFixed(2) : '—';
      final icm = s.heroIcmEv != null ? s.heroIcmEv!.toStringAsFixed(2) : '—';
      final note = s.note.trim().isNotEmpty ? s.note.replaceAll('|', '\\|') : '—';
      buffer.writeln('|$id|$pos|$action|$ev|$icm|$note|');
    }
    buffer
      ..writeln()
      ..writeln('**Всего спотов:** $total')
      ..writeln('**EV заполнено:** ${total == 0 ? 0 : (evCount * 100 / total).round()}%')
      ..writeln('**ICM заполнено:** ${total == 0 ? 0 : (icmCount * 100 / total).round()}%')
      ..writeln('**Позиции:** ${positions.length}');
    return buffer.toString().trimRight();
  }

  String? _heroAction(TrainingPackSpot spot) {
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex) return a.action;
    }
    return null;
  }
}
