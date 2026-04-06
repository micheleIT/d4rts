import 'package:flutter_test/flutter_test.dart';
import 'package:d4rts/models/dart_throw.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/leg.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/models/turn.dart';
import 'package:d4rts/services/stats_service.dart';
import 'package:d4rts/utils/constants.dart';
import 'package:uuid/uuid.dart';

Game _makeCompletedGame({
  required String winnerId,
  required List<Player> players,
}) {
  const uuid = Uuid();
  final leg = Leg(
    startingScore: 501,
    checkoutMode: CheckoutMode.doubleOut,
  );

  // Alice throws a 180 turn
  leg.addTurn(
    'alice',
    Turn(darts: [
      const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple),
      const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple),
      const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple),
    ]),
  );

  // Bob throws 60
  leg.addTurn(
    'bob',
    Turn(darts: [
      const DartThrow(baseValue: 20, multiplier: ThrowMultiplier.triple),
    ]),
  );

  leg.winnerName = winnerId == 'alice' ? 'Alice' : 'Bob';

  final game = Game(
    id: uuid.v4(),
    startedAt: DateTime.now(),
    players: players,
    startingScore: 501,
    legsToWin: 1,
    checkoutMode: CheckoutMode.doubleOut,
    winnerName: winnerId == 'alice' ? 'Alice' : 'Bob',
    completedAt: DateTime.now(),
    legs: [leg],
  );

  return game;
}

void main() {
  group('StatsService', () {
    late StatsService service;

    setUp(() {
      service = StatsService();
    });

    test('computeStats returns empty map for no games', () {
      final stats = service.computeStats([]);
      expect(stats, isEmpty);
    });

    test('gamesPlayed and gamesWon tracked correctly', () {
      final players = [const Player(name: 'Alice'), const Player(name: 'Bob')];
      final game = _makeCompletedGame(winnerId: 'alice', players: players);
      final stats = service.computeStats([game]);

      expect(stats['alice']?.gamesPlayed, 1);
      expect(stats['alice']?.gamesWon, 1);
      expect(stats['bob']?.gamesPlayed, 1);
      expect(stats['bob']?.gamesWon, 0);
    });

    test('180s counted correctly', () {
      final players = [const Player(name: 'Alice'), const Player(name: 'Bob')];
      final game = _makeCompletedGame(winnerId: 'alice', players: players);
      final stats = service.computeStats([game]);

      expect(stats['alice']?.count180s, 1);
    });

    test('legsPlayed and legsWon tracked', () {
      final players = [const Player(name: 'Alice'), const Player(name: 'Bob')];
      final game = _makeCompletedGame(winnerId: 'alice', players: players);
      final stats = service.computeStats([game]);

      expect(stats['alice']?.legsPlayed, 1);
      expect(stats['alice']?.legsWon, 1);
      expect(stats['bob']?.legsPlayed, 1);
      expect(stats['bob']?.legsWon, 0);
    });

    test('getGamesToday filters to today only', () {
      final players = [const Player(name: 'Alice'), const Player(name: 'Bob')];
      final todayGame = _makeCompletedGame(winnerId: 'alice', players: players);

      final oldGame = Game(
        id: const Uuid().v4(),
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        players: players,
        startingScore: 501,
        legsToWin: 1,
        checkoutMode: CheckoutMode.doubleOut,
        winnerName: 'Alice',
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      final todayGames = service.getGamesToday([todayGame, oldGame]);
      expect(todayGames.length, 1);
      expect(todayGames.first.id, todayGame.id);
    });

    test('threeDartAverage is computed', () {
      final players = [const Player(name: 'Alice'), const Player(name: 'Bob')];
      final game = _makeCompletedGame(winnerId: 'alice', players: players);
      final stats = service.computeStats([game]);

      // Alice threw T20 T20 T20 = 180 in 3 darts → 3-dart avg = 180
      expect(stats['alice']?.threeDartAverage, greaterThan(0));
    });
  });
}
