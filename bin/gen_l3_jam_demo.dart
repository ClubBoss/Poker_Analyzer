import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  var outPath = 'out/packs/l3_jam_demo.jsonl';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    } else {
      stderr.writeln('Unknown or incomplete argument: ' + arg);
      exitCode = 64;
      return;
    }
  }

  final spots = [
    {
      'kind': 'l3_flop_jam_vs_bet',
      'hand': 'AsKd',
      'pos': 'BTN',
      'vsPos': 'BB',
      'stack': '20bb',
      'action': 'jam'
    },
    {
      'kind': 'l3_flop_jam_vs_bet',
      'hand': '7c7d',
      'pos': 'SB',
      'vsPos': 'BB',
      'stack': '25bb',
      'action': 'fold'
    },
    {
      'kind': 'l3_flop_jam_vs_raise',
      'hand': 'QcJh',
      'pos': 'BB',
      'vsPos': 'BTN',
      'stack': '30bb',
      'action': 'jam'
    },
    {
      'kind': 'l3_flop_jam_vs_raise',
      'hand': 'Ah9h',
      'pos': 'BTN',
      'vsPos': 'BB',
      'stack': '30bb',
      'action': 'fold'
    },
    {
      'kind': 'l3_turn_jam_vs_bet',
      'hand': 'TsTh',
      'pos': 'CO',
      'vsPos': 'BB',
      'stack': '22bb',
      'action': 'jam'
    },
    {
      'kind': 'l3_turn_jam_vs_bet',
      'hand': '8s7s',
      'pos': 'SB',
      'vsPos': 'BB',
      'stack': '25bb',
      'action': 'fold'
    },
    {
      'kind': 'l3_turn_jam_vs_raise',
      'hand': 'KcQh',
      'pos': 'BTN',
      'vsPos': 'BB',
      'stack': '28bb',
      'action': 'jam'
    },
    {
      'kind': 'l3_turn_jam_vs_raise',
      'hand': 'JdTd',
      'pos': 'BB',
      'vsPos': 'BTN',
      'stack': '18bb',
      'action': 'fold'
    },
    {
      'kind': 'l3_river_jam_vs_bet',
      'hand': 'AcAd',
      'pos': 'UTG',
      'vsPos': 'BB',
      'stack': '40bb',
      'action': 'jam'
    },
    {
      'kind': 'l3_river_jam_vs_bet',
      'hand': '9h8h',
      'pos': 'BTN',
      'vsPos': 'BB',
      'stack': '15bb',
      'action': 'fold'
    },
    {
      'kind': 'l3_river_jam_vs_raise',
      'hand': 'KhKs',
      'pos': 'CO',
      'vsPos': 'BB',
      'stack': '35bb',
      'action': 'jam'
    },
    {
      'kind': 'l3_river_jam_vs_raise',
      'hand': '6c5c',
      'pos': 'BB',
      'vsPos': 'BTN',
      'stack': '20bb',
      'action': 'fold'
    }
  ];

  final file = File(outPath);
  file.createSync(recursive: true);
  final buffer = StringBuffer();
  for (final spot in spots) {
    buffer.writeln(jsonEncode(spot));
  }
  file.writeAsStringSync(buffer.toString());
  stdout.writeln('Wrote ' + spots.length.toString() + ' spots to ' + outPath);
}
