import 'package:flutter_test/flutter_test.dart';
import 'package:d4rts/models/dart_throw.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/services/game_service.dart';
import 'package:d4rts/utils/constants.dart';
import 'package:uuid/uuid.dart';

Game _makeGame({
  CheckoutMode checkoutMode = CheckoutMode.doubleOut,
  int startingScore = 501,
  int legsToWin = 1,
  Map<String, int>? handicaps,
}) {
  return Game(
    id: const Uuid().v4(),
    startedAt: DateTime.now(),
    players: const [Player(name: 'Alice'), Player(name: 'Bob')],
    startingScore: startingScore,
    handicaps: handicaps,
    legsToWin: legsToWin,
    checkoutMode: checkoutMode,
  );
}

List<DartThrow> darts(int score1, [int score2 = 0, int score3 = 0]) {
  // convenience: builds darts as single throws
  final result = <DartThrow>[];
  if (score1 > 0 || score2 > 0 || score3 > 0) {
    result.add(DartThrow(baseValue: score1.clamp(0, 20), multiplier: ThrowMultiplier.single));
    if (score2 > 0) result.add(DartThrow(baseValue: score2.clamp(0, 20), multiplier: ThrowMultiplier.single));
    if (score3 > 0) result.add(DartThrow(baseValue: score3.clamp(0, 20), multiplier: ThrowMultiplier.single));
  }
  return result;
}

void main() {
  group('GameService', () {
    late GameService service;

    setUp(() {
      service = GameService();
    });

    test('startGame initializes scores', () {
      final game = _makeGame(startingScore: 501);
      service.startGame(game);
      expect(service.getCurrentPlayerScore('Alice'), 501);
      expect(service.getCurrentPlayerScore('Bob'), 501);
      expect(service.currentPlayer?.name, 'Alice');
    });

    test('submitTurn reduces score normally', () {
      final game = _makeGame(startingScore: 501);
      service.startGame(game);
      final result = service.submitTurn([
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple),
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple),
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple),
      ]);
      expect(result.isNormal, isTrue);
      expect(service.getCurrentPlayerScore('Alice'), 501 - 180);
      expect(service.currentPlayer?.name, 'Bob');
    });

    test('submitTurn causes bust when score goes below 0', () {
      final game = _makeGame(startingScore: 40);
      service.startGame(game);
      // Try to throw more than 40
      final result = service.submitTurn([
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple), // 60 > 40
      ]);
      expect(result.isBust, isTrue);
      // Score should be unchanged
      expect(service.getCurrentPlayerScore('Alice'), 40);
    });

    test('bust when remaining == 1 with doubleOut', () {
      final game = _makeGame(startingScore: 21, checkoutMode: CheckoutMode.doubleOut);
      service.startGame(game);
      // Score 20, leaving 1
      final result = service.submitTurn([
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.single),
      ]);
      expect(result.isBust, isTrue);
      expect(service.getCurrentPlayerScore('Alice'), 21);
    });

    test('valid doubleOut checkout wins the leg', () {
      final game = _makeGame(startingScore: 32, checkoutMode: CheckoutMode.doubleOut);
      service.startGame(game);
      // D16 = 32, valid double checkout
      final result = service.submitTurn([
        const DartThrow(baseValue: 16, multiplier: ThrowMultiplier.double_),
      ]);
      expect(result.isLegWon, isTrue);
      expect(result.message, 'Alice');
      expect(service.getLegWins('Alice'), 1);
    });

    test('invalid doubleOut checkout (last dart not double) is a bust', () {
      final game = _makeGame(startingScore: 32, checkoutMode: CheckoutMode.doubleOut);
      service.startGame(game);
      // 20 + 12 = 32 but last dart is not double → bust
      final result = service.submitTurn([
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.single),
        const DartThrow(baseValue: 12, multiplier: ThrowMultiplier.single),
      ]);
      expect(result.isBust, isTrue);
      expect(service.getCurrentPlayerScore('Alice'), 32);
    });

    test('straightOut checkout wins the leg with any dart', () {
      final game = _makeGame(startingScore: 20, checkoutMode: CheckoutMode.straightOut);
      service.startGame(game);
      final result = service.submitTurn([
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.single),
      ]);
      expect(result.isLegWon, isTrue);
    });

    test('game is won after legsToWin legs', () {
      final game = _makeGame(
        startingScore: 32,
        checkoutMode: CheckoutMode.doubleOut,
        legsToWin: 2,
      );
      service.startGame(game);

      // Win leg 1 as Alice (she goes first, index 0)
      var result = service.submitTurn([
        const DartThrow(baseValue: 16, multiplier: ThrowMultiplier.double_),
      ]);
      expect(result.isLegWon, isTrue);

      // Now leg 2 starts — Bob goes first (advance from Alice)
      // Bob throws a miss, no change to score
      result = service.submitTurn([
        const DartThrow(baseValue: 0, multiplier: ThrowMultiplier.single),
      ]);
      expect(result.isBust, isFalse); // just a normal miss
      expect(service.currentPlayer?.name, 'Alice');

      // Alice wins leg 2 → game won
      result = service.submitTurn([
        const DartThrow(baseValue: 16, multiplier: ThrowMultiplier.double_),
      ]);
      expect(result.isGameWon, isTrue);
      expect(result.message, 'Alice');
    });

    test('undoLastTurn restores previous score', () {
      final game = _makeGame(startingScore: 501);
      service.startGame(game);
      service.submitTurn([
        const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.single),
      ]);
      expect(service.getCurrentPlayerScore('Alice'), 481);
      expect(service.currentPlayer?.name, 'Bob');

      service.undoLastTurn();
      expect(service.getCurrentPlayerScore('Alice'), 501);
      expect(service.currentPlayer?.name, 'Alice');
    });

    test('canUndo is false at start and true after a turn', () {
      final game = _makeGame();
      service.startGame(game);
      expect(service.canUndo, isFalse);
      service.submitTurn([
        const DartThrow(baseValue: 5, multiplier: ThrowMultiplier.single),
      ]);
      expect(service.canUndo, isTrue);
    });

    test('handicap adds extra points to starting score', () {
      final game = _makeGame(
        startingScore: 501,
        handicaps: {'alice': 100},
      );
      service.startGame(game);
      // Alice should start at 601 (501 + 100 handicap)
      expect(service.getCurrentPlayerScore('Alice'), 601);
      // Bob has no handicap, stays at 501
      expect(service.getCurrentPlayerScore('Bob'), 501);
    });

    test('leg wins track correctly across multiple legs', () {
      final game = _makeGame(
        startingScore: 32,
        checkoutMode: CheckoutMode.doubleOut,
        legsToWin: 3,
      );
      service.startGame(game);

      // Alice wins leg 1
      service.submitTurn([const DartThrow(baseValue: 16, multiplier: ThrowMultiplier.double_)]);
      expect(service.getLegWins('Alice'), 1);

      // Bob's turn in new leg — Bob scores
      service.submitTurn([const DartThrow(baseValue: 1, multiplier: ThrowMultiplier.single)]);
      // Alice's turn
      service.submitTurn([const DartThrow(baseValue: 16, multiplier: ThrowMultiplier.double_)]);
      expect(service.getLegWins('Alice'), 2);
    });
  });
}
