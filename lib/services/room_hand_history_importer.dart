import '../models/saved_hand.dart';
import '../plugins/converters/pokerstars_hand_history_converter.dart';
import '../plugins/converters/simple_hand_history_converter.dart';
import '../plugins/converters/winamax_hand_history_converter.dart';
import '../plugins/converters/ggpoker_hand_history_converter.dart';

class RoomHandHistoryImporter {
  RoomHandHistoryImporter();

  static Future<RoomHandHistoryImporter> create() async {
    return RoomHandHistoryImporter();
  }


  List<SavedHand> parse(String text) {
    final parts = _split(text);
    final stars = PokerStarsHandHistoryConverter();
    final simple = SimpleHandHistoryConverter();
    final winamax = WinamaxHandHistoryConverter();
    final gg = GGPokerHandHistoryConverter();
    final result = <SavedHand>[];
    for (final part in parts) {
      final trimmed = part.trimLeft();
      SavedHand? hand;
      if (trimmed.startsWith('PokerStars Hand #')) {
        hand = stars.convertFrom(part);
      } else if (trimmed.startsWith('GGPoker Hand #') ||
          trimmed.startsWith('Hand #')) {
        hand = gg.convertFrom(part);
      } else if (trimmed.toLowerCase().contains('winamax')) {
        hand = winamax.convertFrom(part);
      } else {
        hand = simple.convertFrom(part);
      }
      if (hand != null) result.add(hand);
    }
    return result;
  }

  List<String> _split(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final hands = <String>[];
    final buffer = StringBuffer();
    bool isFirst = true;
    for (final line in lines) {
      final trimmed = line.trim();
      if (!isFirst && (trimmed.startsWith('PokerStars Hand #') ||
          trimmed.startsWith('Hand #') ||
          trimmed.startsWith('GGPoker Hand #'))) {
        hands.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.writeln(line);
      isFirst = false;
    }
    if (buffer.isNotEmpty) hands.add(buffer.toString().trim());
    return hands.where((h) => h.isNotEmpty).toList();
  }
}
