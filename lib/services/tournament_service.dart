import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/models/player_stats.dart';
import 'package:d4rts/models/tournament.dart';
import 'package:d4rts/utils/constants.dart';

class TournamentService {
  final _uuid = const Uuid();
  final _random = Random();

  /// Distribute players evenly across groups (random shuffle)
  List<TournamentGroup> generateGroups(
    List<Player> players,
    int numGroups,
  ) {
    final shuffled = List<Player>.from(players)..shuffle(_random);
    final groups = <TournamentGroup>[];

    for (var i = 0; i < numGroups; i++) {
      groups.add(TournamentGroup(index: i, players: []));
    }

    for (var i = 0; i < shuffled.length; i++) {
      groups[i % numGroups].players.add(shuffled[i]);
    }

    return groups;
  }

  /// Generate round-robin fixtures for a group
  List<Game> generateRoundRobin(
    TournamentGroup group, {
    required int startingScore,
    required int legsToWin,
    required CheckoutMode checkoutMode,
  }) {
    final matches = <Game>[];
    final players = group.players;

    for (var i = 0; i < players.length; i++) {
      for (var j = i + 1; j < players.length; j++) {
        matches.add(Game(
          id: _uuid.v4(),
          startedAt: DateTime.now(),
          players: [players[i], players[j]],
          startingScore: startingScore,
          legsToWin: legsToWin,
          checkoutMode: checkoutMode,
        ));
      }
    }

    return matches;
  }

  /// Rank players in a group by wins, then leg difference, then 3-dart avg
  List<Player> rankGroup(
    TournamentGroup group, [
    Map<String, PlayerStats>? statsMap,
  ]) {
    final wins = <String, int>{};
    final legDiff = <String, int>{};

    for (final p in group.players) {
      wins[p.name.toLowerCase()] = 0;
      legDiff[p.name.toLowerCase()] = 0;
    }

    for (final match in group.matches) {
      if (!match.isCompleted) continue;
      if (match.winnerName != null) {
        wins[match.winnerName!.toLowerCase()] =
            (wins[match.winnerName!.toLowerCase()] ?? 0) + 1;
      }

      // Calculate leg diff for each player
      for (final player in match.players) {
        final key = player.name.toLowerCase();
        var legsWon = 0;
        var legsLost = 0;
        for (final leg in match.legs) {
          if (leg.winnerName?.toLowerCase() == key) {
            legsWon++;
          } else if (leg.winnerName != null) {
            legsLost++;
          }
        }
        legDiff[key] = (legDiff[key] ?? 0) + legsWon - legsLost;
      }
    }

    final sorted = List<Player>.from(group.players);
    sorted.sort((a, b) {
      final ak = a.name.toLowerCase();
      final bk = b.name.toLowerCase();
      final wDiff = (wins[bk] ?? 0).compareTo(wins[ak] ?? 0);
      if (wDiff != 0) return wDiff;
      final ldDiff = (legDiff[bk] ?? 0).compareTo(legDiff[ak] ?? 0);
      if (ldDiff != 0) return ldDiff;
      // 3-dart average tiebreaker
      if (statsMap != null) {
        final aAvg = statsMap[ak]?.threeDartAverage ?? 0;
        final bAvg = statsMap[bk]?.threeDartAverage ?? 0;
        return bAvg.compareTo(aAvg);
      }
      return 0;
    });

    return sorted;
  }

  /// Generate knockout bracket from group standings
  List<KnockoutRound> generateKnockoutBracket(
    List<TournamentGroup> groups, {
    required int startingScore,
    required int legsToWin,
    required CheckoutMode checkoutMode,
    Map<String, PlayerStats>? statsMap,
  }) {
    // Rank each group
    final rankedGroups = groups.map((g) => rankGroup(g, statsMap)).toList();

    // Cross-seed: 1st of group 0 vs 2nd of group 1, etc.
    final seeds = <Player>[];
    final maxGroupSize =
        rankedGroups.map((g) => g.length).fold(0, max);

    // Collect by rank position across groups
    for (var rank = 0; rank < maxGroupSize; rank++) {
      for (final group in rankedGroups) {
        if (rank < group.length) {
          seeds.add(group[rank]);
        }
      }
    }

    final rounds = <KnockoutRound>[];
    var currentPlayers = seeds;

    while (currentPlayers.length > 1) {
      // Pair up: seed 0 vs last, seed 1 vs second last, etc. (BYE for odd)
      final matches = <Game>[];
      final nextRoundPlayers = <Player>[];

      // If odd number, top seed gets a bye
      if (currentPlayers.length % 2 != 0) {
        nextRoundPlayers.add(currentPlayers[0]);
        currentPlayers = currentPlayers.sublist(1);
      }

      final half = currentPlayers.length ~/ 2;
      for (var i = 0; i < half; i++) {
        final p1 = currentPlayers[i];
        final p2 = currentPlayers[currentPlayers.length - 1 - i];
        matches.add(Game(
          id: _uuid.v4(),
          startedAt: DateTime.now(),
          players: [p1, p2],
          startingScore: startingScore,
          legsToWin: legsToWin,
          checkoutMode: checkoutMode,
        ));
      }

      final roundName = _getRoundName(matches.length + nextRoundPlayers.length);
      rounds.add(KnockoutRound(name: roundName, matches: matches));

      // Winners advance (placeholders until played)
      currentPlayers = [
        ...nextRoundPlayers,
        ...matches.map((m) => m.players[0]), // placeholder
      ];

      // Stop if only one player remains
      if (currentPlayers.length == 1) break;
      // Safety: prevent infinite loop
      if (matches.isEmpty) break;
    }

    return rounds;
  }

  String _getRoundName(int remaining) {
    if (remaining <= 2) return 'Final';
    if (remaining <= 4) return 'Semi-Finals';
    if (remaining <= 8) return 'Quarter-Finals';
    return 'Round of $remaining';
  }

  /// Get winner of a knockout round match (if completed)
  Player? getMatchWinner(Game match) {
    if (match.winnerName == null) return null;
    return match.players.firstWhere(
      (p) => p.name.toLowerCase() == match.winnerName!.toLowerCase(),
      orElse: () => match.players.first,
    );
  }

  /// Update knockout bracket after a match is played
  void updateKnockoutBracket(
    Tournament tournament,
    Game completedMatch, {
    required int startingScore,
    required int legsToWin,
    required CheckoutMode checkoutMode,
  }) {
    final winner = getMatchWinner(completedMatch);
    if (winner == null) return;

    // Find which round this match is in
    for (var roundIdx = 0;
        roundIdx < tournament.knockoutRounds.length;
        roundIdx++) {
      final round = tournament.knockoutRounds[roundIdx];
      final matchIdx =
          round.matches.indexWhere((m) => m.id == completedMatch.id);

      if (matchIdx >= 0) {
        // Update the match
        round.matches[matchIdx] = completedMatch;

        // If all matches in this round are done, generate next round
        if (roundIdx + 1 < tournament.knockoutRounds.length) {
          // Update the next round with actual winners
          _updateNextRound(
            tournament,
            roundIdx,
            startingScore: startingScore,
            legsToWin: legsToWin,
            checkoutMode: checkoutMode,
          );
        }
        break;
      }
    }
  }

  void _updateNextRound(
    Tournament tournament,
    int completedRoundIdx, {
    required int startingScore,
    required int legsToWin,
    required CheckoutMode checkoutMode,
  }) {
    final completedRound =
        tournament.knockoutRounds[completedRoundIdx];
    final winners = completedRound.matches
        .where((m) => m.isCompleted)
        .map((m) => getMatchWinner(m))
        .whereType<Player>()
        .toList();

    if (winners.length < 2) return;

    final nextRoundIdx = completedRoundIdx + 1;
    if (nextRoundIdx >= tournament.knockoutRounds.length) {
      // Generate the next round
      final matches = <Game>[];
      for (var i = 0; i < winners.length ~/ 2; i++) {
        matches.add(Game(
          id: _uuid.v4(),
          startedAt: DateTime.now(),
          players: [winners[i], winners[winners.length - 1 - i]],
          startingScore: startingScore,
          legsToWin: legsToWin,
          checkoutMode: checkoutMode,
        ));
      }
      if (matches.isNotEmpty) {
        tournament.knockoutRounds.add(KnockoutRound(
          name: _getRoundName(winners.length),
          matches: matches,
        ));
      }
    }
  }
}
