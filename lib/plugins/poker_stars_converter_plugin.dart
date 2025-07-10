import 'package:poker_analyzer/plugins/converters/pokerstars_hand_history_converter.dart';
import 'package:poker_analyzer/plugins/plugin.dart';
import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/services/service_registry.dart';

class PokerStarsConverterPlugin extends PokerStarsHandHistoryConverter implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    registry.registerIfAbsent<ConverterRegistry>(ConverterRegistry());
    registry.get<ConverterRegistry>().register(this);
  }
}
