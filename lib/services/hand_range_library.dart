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
    }
    throw ArgumentError('Range group not found: $name');
  }
}
