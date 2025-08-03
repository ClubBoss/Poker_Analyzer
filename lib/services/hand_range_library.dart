import 'pack_generator_service.dart';

class HandRangeLibrary {
  static List<String> getGroup(String name) {
    final match = RegExp(r'^top(\d+)').firstMatch(name);
    if (match != null) {
      final pct = int.parse(match.group(1)!);
      return PackGeneratorService.topNHands(pct).toList();
    }
    switch (name) {
      case 'tilt':
        return PackGeneratorService.topNHands(70).toList();
      case 'icm':
        return PackGeneratorService.topNHands(10).toList();
      case 'broadway':
      case 'broadways':
        const ranks = ['A', 'K', 'Q', 'J', 'T'];
        final hands = <String>[];
        for (var i = 0; i < ranks.length; i++) {
          hands.add('${ranks[i]}${ranks[i]}');
          for (var j = i + 1; j < ranks.length; j++) {
            hands.add('${ranks[i]}${ranks[j]}s');
            hands.add('${ranks[i]}${ranks[j]}o');
          }
        }
        return hands;
      case 'pockets':
        return [
          'AA',
          'KK',
          'QQ',
          'JJ',
          'TT',
          '99',
          '88',
          '77',
          '66',
          '55',
          '44',
          '33',
          '22',
        ];
      case 'suitedAx':
        const kickers = [
          'K',
          'Q',
          'J',
          'T',
          '9',
          '8',
          '7',
          '6',
          '5',
          '4',
          '3',
          '2',
        ];
        return [for (final k in kickers) 'A${k}s'];
      case 'nash-10bb':
        return [
          '22',
          '33',
          'A2s',
          'A3s',
          'K9s',
          'Q9s',
          'J9s',
          'T9s',
          '98s',
          'AJo',
          'KQo',
          'A2o',
          'A3o',
          'A4o',
          'A5o',
          'A6o',
          'A7o',
          'A8o',
          'A9o',
          'ATo',
        ];
      case 'suitedconnectors':
        return ['54s', '65s', '76s', '87s', '98s', 'T9s', 'JTs'];
      case 'lowax':
        return ['A2s', 'A3s', 'A4s', 'A5s', 'A2o', 'A3o', 'A4o', 'A5o'];
      case 'kxsuited':
        const kxKickers = [
          'Q',
          'J',
          'T',
          '9',
          '8',
          '7',
          '6',
          '5',
          '4',
          '3',
          '2',
        ];
        return [for (final k in kxKickers) 'K${k}s'];
    }
    throw ArgumentError('Range group not found: $name');
  }
}
