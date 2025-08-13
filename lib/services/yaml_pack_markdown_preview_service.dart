import '../models/v2/training_pack_template_v2.dart';
import '../helpers/hand_utils.dart';

class YamlPackMarkdownPreviewService {
  const YamlPackMarkdownPreviewService();

  String? generateMarkdownPreview(TrainingPackTemplateV2 pack) {
    try {
      final buffer = StringBuffer('# ${pack.name}\n');
      if (pack.goal.trim().isNotEmpty) buffer.writeln('\n${pack.goal}');
      if (pack.tags.isNotEmpty) {
        buffer.writeln('\n**Tags:** ${pack.tags.join(', ')}');
      }
      buffer
        ..writeln('\n**Spots:** ${pack.spotCount}')
        ..writeln(
            '**EV:** ${(pack.meta['evScore'] as num?)?.toStringAsFixed(1) ?? ''}')
        ..writeln(
            '**ICM:** ${(pack.meta['icmScore'] as num?)?.toStringAsFixed(1) ?? ''}');
      final preview = pack.spots.take(5);
      if (preview.isNotEmpty) {
        buffer
          ..writeln('\n|Pos|Hero|Board|EV|Tags|')
          ..writeln('|---|---|---|---|---|');
        for (final s in preview) {
          final hero = handCode(s.hand.heroCards) ?? s.hand.heroCards;
          final board = s.hand.board.join(' ');
          final ev = s.heroEv?.toStringAsFixed(2) ?? '';
          final tags = s.tags.join(', ');
          buffer.writeln('|${s.hand.position.label}|$hero|$board|$ev|$tags|');
        }
      }
      return buffer.toString().trimRight();
    } catch (_) {
      return null;
    }
  }
}
