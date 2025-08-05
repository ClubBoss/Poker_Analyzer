import 'package:test/test.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/spot_seed_format.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/services/constraint_resolver_engine_v2.dart';

void main() {
  final engine = ConstraintResolverEngine();

  SpotSeedFormat buildCandidate({
    List<CardModel>? board,
    List<String>? handGroup,
    String position = 'btn',
    List<String>? villainActions,
  }) {
    return SpotSeedFormat(
      player: 'hero',
      handGroup: handGroup ?? ['broadways'],
      position: position,
      board: board,
      villainActions: villainActions,
    );
  }

  test('valid candidate passes all constraints', () {
    final candidate = buildCandidate(
      board: [
        CardModel(rank: '2', suit: 'h'),
        CardModel(rank: '2', suit: 'c'),
        CardModel(rank: '9', suit: 'd'),
      ],
      villainActions: ['check', 'bet'],
    );
    final constraints = ConstraintSet(
      boardTags: ['paired'],
      positions: ['btn'],
      handGroup: ['broadways'],
      villainActions: ['check', 'bet'],
      targetStreet: 'flop',
    );
    expect(engine.isValid(candidate, constraints), isTrue);
  });

  test('rejects when position mismatch', () {
    final candidate = buildCandidate();
    final constraints = ConstraintSet(positions: ['co']);
    expect(engine.isValid(candidate, constraints), isFalse);
  });

  test('rejects when board tags mismatch', () {
    final candidate = buildCandidate(
      board: [
        CardModel(rank: 'A', suit: 's'),
        CardModel(rank: 'K', suit: 'h'),
        CardModel(rank: '2', suit: 'd'),
      ],
    );
    final constraints = ConstraintSet(boardTags: ['low']);
    expect(engine.isValid(candidate, constraints), isFalse);
  });

  test('rejects when hand group mismatch', () {
    final candidate = buildCandidate(handGroup: ['smallPairs']);
    final constraints = ConstraintSet(handGroup: ['broadways']);
    expect(engine.isValid(candidate, constraints), isFalse);
  });

  test('rejects when villain actions mismatch', () {
    final candidate = buildCandidate(villainActions: ['bet', 'check']);
    final constraints = ConstraintSet(villainActions: ['check', 'bet']);
    expect(engine.isValid(candidate, constraints), isFalse);
  });

  test('matches villain actions using first word only', () {
    final candidate = buildCandidate(villainActions: ['bet 50', 'check 100']);
    final constraints = ConstraintSet(villainActions: ['bet', 'check']);
    expect(engine.isValid(candidate, constraints), isTrue);
  });

  test('board tag comparison is case-insensitive', () {
    final candidate = buildCandidate(
      board: [
        CardModel(rank: '2', suit: 'h'),
        CardModel(rank: '2', suit: 'c'),
        CardModel(rank: '9', suit: 'd'),
      ],
    );
    final constraints = ConstraintSet(boardTags: ['PAIRED']);
    expect(engine.isValid(candidate, constraints), isTrue);
  });

  test('rejects when street mismatch', () {
    final candidate = buildCandidate(
      board: [
        CardModel(rank: '2', suit: 'h'),
        CardModel(rank: '2', suit: 'c'),
        CardModel(rank: '9', suit: 'd'),
        CardModel(rank: 'K', suit: 's'),
      ],
    );
    final constraints = ConstraintSet(targetStreet: 'flop');
    expect(engine.isValid(candidate, constraints), isFalse);
  });

  test('enforces required and excluded spot tags', () {
    final candidate = buildCandidate().copyWith(tags: ['a', 'b']);
    final ok = ConstraintSet(requiredTags: ['a'], excludedTags: ['c']);
    final failReq = ConstraintSet(requiredTags: ['c']);
    final failExcl = ConstraintSet(excludedTags: ['b']);
    expect(engine.isValid(candidate, ok), isTrue);
    expect(engine.isValid(candidate, failReq), isFalse);
    expect(engine.isValid(candidate, failExcl), isFalse);
  });

  test('validates stack range when provided', () {
    final candidate = buildCandidate().copyWith(heroStack: 20);
    final ok = ConstraintSet(minStack: 10, maxStack: 25);
    final low = ConstraintSet(minStack: 30);
    final high = ConstraintSet(maxStack: 10);
    expect(engine.isValid(candidate, ok), isTrue);
    expect(engine.isValid(candidate, low), isFalse);
    expect(engine.isValid(candidate, high), isFalse);
  });
}
