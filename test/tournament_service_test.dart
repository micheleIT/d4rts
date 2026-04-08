import 'package:flutter_test/flutter_test.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/models/tournament.dart';
import 'package:d4rts/services/tournament_service.dart';
import 'package:d4rts/utils/constants.dart';

void main() {
  group('TournamentService', () {
    late TournamentService service;

    setUp(() {
      service = TournamentService();
    });

    group('generateGroups', () {
      test('distributes players across groups', () {
        final players = List.generate(
          8,
          (i) => Player(name: 'Player ${i + 1}'),
        );
        final groups = service.generateGroups(players, 2);

        expect(groups.length, 2);
        final totalPlayers = groups.fold<int>(
          0,
          (sum, g) => sum + g.players.length,
        );
        expect(totalPlayers, 8);
      });

      test('distributes evenly for 4 players into 2 groups', () {
        final players = List.generate(
          4,
          (i) => Player(name: 'Player ${i + 1}'),
        );
        final groups = service.generateGroups(players, 2);

        expect(groups.length, 2);
        expect(groups[0].players.length, 2);
        expect(groups[1].players.length, 2);
      });

      test('handles uneven distribution', () {
        final players = List.generate(
          5,
          (i) => Player(name: 'Player ${i + 1}'),
        );
        final groups = service.generateGroups(players, 2);

        expect(groups.length, 2);
        final lengths = groups.map((g) => g.players.length).toList()..sort();
        expect(lengths, [2, 3]);
      });
    });

    group('generateRoundRobin', () {
      test('generates correct number of matches for 4 players', () {
        final players = List.generate(
          4,
          (i) => Player(name: 'Player ${i + 1}'),
        );
        final group = TournamentGroup(index: 0, players: players);
        final matches = service.generateRoundRobin(
          group,
          startingScore: 501,
          legsToWin: 3,
          checkoutMode: CheckoutMode.doubleOut,
        );
        // 4 players: C(4,2) = 6 matches
        expect(matches.length, 6);
      });

      test('generates correct number of matches for 3 players', () {
        final players = List.generate(
          3,
          (i) => Player(name: 'Player ${i + 1}'),
        );
        final group = TournamentGroup(index: 0, players: players);
        final matches = service.generateRoundRobin(
          group,
          startingScore: 501,
          legsToWin: 3,
          checkoutMode: CheckoutMode.doubleOut,
        );
        // 3 players: C(3,2) = 3 matches
        expect(matches.length, 3);
      });

      test('each match has 2 players', () {
        final players = List.generate(
          4,
          (i) => Player(name: 'Player ${i + 1}'),
        );
        final group = TournamentGroup(index: 0, players: players);
        final matches = service.generateRoundRobin(
          group,
          startingScore: 501,
          legsToWin: 3,
          checkoutMode: CheckoutMode.doubleOut,
        );
        for (final match in matches) {
          expect(match.players.length, 2);
        }
      });

      test('each player plays against every other player once', () {
        final players = List.generate(
          4,
          (i) => Player(name: 'Player ${i + 1}'),
        );
        final group = TournamentGroup(index: 0, players: players);
        final matches = service.generateRoundRobin(
          group,
          startingScore: 501,
          legsToWin: 3,
          checkoutMode: CheckoutMode.doubleOut,
        );

        // Each pair should appear exactly once
        for (var i = 0; i < players.length; i++) {
          for (var j = i + 1; j < players.length; j++) {
            final p1 = players[i];
            final p2 = players[j];
            final count = matches.where((m) {
              final names = m.players.map((p) => p.name).toSet();
              return names.contains(p1.name) && names.contains(p2.name);
            }).length;
            expect(count, 1, reason: '${p1.name} vs ${p2.name} should appear once');
          }
        }
      });
    });

    group('rankGroup', () {
      test('ranks by wins descending', () {
        final players = [
          const Player(name: 'Alice'),
          const Player(name: 'Bob'),
          const Player(name: 'Charlie'),
        ];
        final group = TournamentGroup(index: 0, players: players);
        final matches = service.generateRoundRobin(
          group,
          startingScore: 501,
          legsToWin: 1,
          checkoutMode: CheckoutMode.doubleOut,
        );

        // Manually set winners
        matches[0].winnerName = 'Alice'; // Alice vs Bob
        matches[1].winnerName = 'Alice'; // Alice vs Charlie
        matches[2].winnerName = 'Bob';   // Bob vs Charlie
        group.matches.addAll(matches);

        final ranked = service.rankGroup(group);
        expect(ranked[0].name, 'Alice'); // 2 wins
        expect(ranked[1].name, 'Bob');   // 1 win
        expect(ranked[2].name, 'Charlie'); // 0 wins
      });
    });

    group('generateKnockoutBracket', () {
      test('generates bracket from 2 groups of 2', () {
        final groups = List.generate(2, (gi) {
          final groupPlayers = List.generate(
            2,
            (pi) => Player(name: 'P${gi * 2 + pi + 1}'),
          );
          return TournamentGroup(
            index: gi,
            players: groupPlayers,
            standings: groupPlayers,
          );
        });

        final rounds = service.generateKnockoutBracket(
          groups,
          startingScore: 501,
          legsToWin: 1,
          checkoutMode: CheckoutMode.doubleOut,
        );

        expect(rounds, isNotEmpty);
        expect(rounds.first.matches.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
