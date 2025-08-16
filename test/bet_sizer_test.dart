import 'package:test/test.dart';

// TODO: replace helper functions with BetSizer public API when available.

double _clamp(double v, double min, double max) => v.clamp(min, max).toDouble();

double _roundTo(double v, double unit) => (v / unit).round() * unit;

double _preset(String label, double pot, double stack) {
  switch (label) {
    case '1/4':
      return pot * 0.25;
    case '1/2':
      return pot * 0.5;
    case '2/3':
      return pot * 2 / 3;
    case '3/4':
      return pot * 0.75;
    case 'Pot':
      return pot;
    case 'All-in':
      return stack;
    default:
      throw ArgumentError('unknown preset $label');
  }
}

void main() {
  group('BetSizer logic', () {
    test('clamps and rounds bet values', () {
      expect(_clamp(5, 1, 10), 5);
      expect(_clamp(0, 1, 10), 1);
      expect(_clamp(11, 1, 10), 10);
      expect(_roundTo(3.7, 0.5), 3.5);
      expect(_roundTo(3.8, 1), 4);
    });

    test('preset mapping', () {
      const pot = 80.0;
      const stack = 200.0;
      expect(_preset('1/4', pot, stack), closeTo(20, 1e-9));
      expect(_preset('1/2', pot, stack), closeTo(40, 1e-9));
      expect(_preset('2/3', pot, stack), closeTo(53.3333, 1e-3));
      expect(_preset('3/4', pot, stack), closeTo(60, 1e-9));
      expect(_preset('Pot', pot, stack), closeTo(80, 1e-9));
      expect(_preset('All-in', pot, stack), closeTo(200, 1e-9));
    });
  });
}
