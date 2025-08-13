import 'package:poker_analyzer/plugins/converter_registry.dart';
import 'package:poker_analyzer/plugins/plugin.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'converters/partypoker_hand_history_converter.dart';

class PartyPokerConverterPlugin extends PartypokerHandHistoryConverter
    implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    registry.registerIfAbsent<ConverterRegistry>(ConverterRegistry());
    registry.get<ConverterRegistry>().register(this);
  }

  @override
  String get name => 'PartyPoker Converter';

  @override
  String get description => 'Adds PartyPoker hand history conversion';

  @override
  String get version => '1.0.0';
}
