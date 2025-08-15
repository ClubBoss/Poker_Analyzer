import 'dart:io';

import 'package:poker_analyzer/l3/autogen_v4/board_street_generator.dart';

void main() {
  const seeds = [1337, 9001, 424242];
  const count = 40;
  const mix = TargetMix.mvsDefault();

  for (final seed in seeds) {
    final spots = generateSpots(seed: seed, count: count, mix: mix);
    var flop = 0, turn = 0, river = 0;
    var ip = 0, oop = 0;
    var short = 0, mid = 0, deep = 0;

    for (final s in spots) {
      switch (s.street) {
        case Street.flop:
          flop++;
          break;
        case Street.turn:
          turn++;
          break;
        case Street.river:
          river++;
          break;
      }
      switch (s.pos) {
        case Position.ip:
          ip++;
          break;
        case Position.oop:
          oop++;
          break;
      }
      switch (s.sprBin) {
        case SprBin.short:
          short++;
          break;
        case SprBin.mid:
          mid++;
          break;
        case SprBin.deep:
          deep++;
          break;
      }
    }
    stdout.writeln(
        'seed=$seed count=${spots.length} streets: F=$flop T=$turn R=$river pos: IP=$ip OOP=$oop spr: S=$short M=$mid D=$deep');
  }
}
