import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/widgets/win_pot_animation.dart';
import 'package:poker_analyzer/widgets/win_chips_animation.dart';
import 'package:poker_analyzer/widgets/win_text_widget.dart';
import 'package:poker_analyzer/widgets/winner_glow_widget.dart';
import 'package:poker_analyzer/widgets/winner_zone_highlight.dart';

void main() {
  testWidgets('win overlays render and complete animations', (tester) async {
    bool potDone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              WinPotAnimation(
                start: Offset.zero,
                end: const Offset(10, 10),
                amount: 100,
                onCompleted: () => potDone = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(potDone, isTrue);

    bool chipsDone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              WinChipsAnimation(
                start: Offset.zero,
                end: const Offset(10, 10),
                amount: 100,
                onCompleted: () => chipsDone = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(chipsDone, isTrue);

    bool chipsColoredDone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              WinChipsAnimation(
                start: Offset.zero,
                end: const Offset(10, 10),
                amount: 100,
                color: Colors.purple,
                onCompleted: () => chipsColoredDone = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(chipsColoredDone, isTrue);

    bool textDone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              WinTextWidget(
                position: Offset.zero,
                text: 'Winner',
                onCompleted: () => textDone = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
    expect(textDone, isTrue);

    bool glowDone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              WinnerGlowWidget(
                position: Offset.zero,
                onCompleted: () => glowDone = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(glowDone, isTrue);

    bool zoneDone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              WinnerZoneHighlight(
                rect: const Rect.fromLTWH(0, 0, 10, 10),
                onCompleted: () => zoneDone = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
    expect(zoneDone, isTrue);
  });
}
