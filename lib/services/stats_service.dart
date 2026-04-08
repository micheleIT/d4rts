import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/player_stats.dart';
import 'package:d4rts/models/turn.dart';

class StatsService {
  /// Compute stats for all players from a list of completed games.
  Map<String, PlayerStats> computeStats(List<Game> games) {
    final statsMap = <String, PlayerStats>{};

    for (final game in games) {
      if (!game.isCompleted) continue;

      for (final player in game.players) {
        final key = player.name.toLowerCase();
        final stats = statsMap.putIfAbsent(
          key,
          () => PlayerStats(playerName: player.name),
        );

        stats.gamesPlayed++;
        if (game.winnerName?.toLowerCase() == key) {
          stats.gamesWon++;
        }

        for (final leg in game.legs) {
          final playerTurns = leg.turns[key] ?? [];
          if (playerTurns.isEmpty) continue;

          // Check if this player participated (has turns or won)
          final participated = playerTurns.isNotEmpty ||
              leg.winnerName?.toLowerCase() == key;
          if (!participated) continue;

          stats.legsPlayed++;
          if (leg.winnerName?.toLowerCase() == key) {
            stats.legsWon++;
          }

          final validTurns =
              playerTurns.where((t) => !t.isBust).toList();

          // 3-dart average
          if (validTurns.isNotEmpty) {
            final totalDartsThrown = validTurns.fold<int>(
                0, (sum, t) => sum + t.darts.length);
            final totalScore =
                validTurns.fold<int>(0, (sum, t) => sum + t.totalScore);
            if (totalDartsThrown > 0) {
              final avg = totalScore / totalDartsThrown * 3;
              // Running average
              stats.threeDartAverage =
                  (stats.threeDartAverage * (stats.legsPlayed - 1) + avg) /
                      stats.legsPlayed;
            }
          }

          // First 9 average (first 3 turns)
          final firstThreeTurns =
              validTurns.take(3).toList();
          if (firstThreeTurns.isNotEmpty) {
            final totalDarts = firstThreeTurns.fold<int>(
                0, (sum, t) => sum + t.darts.length);
            final totalScore = firstThreeTurns.fold<int>(
                0, (sum, t) => sum + t.totalScore);
            if (totalDarts > 0) {
              final avg = totalScore / totalDarts * 3;
              stats.firstNineAverage =
                  (stats.firstNineAverage * (stats.legsPlayed - 1) + avg) /
                      stats.legsPlayed;
            }
          }

          // High scores: 180, 140+, 100+
          for (final turn in validTurns) {
            final score = turn.totalScore;
            if (score == 180) stats.count180s++;
            if (score >= 140) stats.count140plus++;
            if (score >= 100) stats.count100plus++;
          }

          // Leg darts count
          if (leg.winnerName?.toLowerCase() == key) {
            final legDarts = playerTurns.fold<int>(
                0, (sum, t) => sum + t.darts.length);
            if (stats.bestLegDarts == 0 || legDarts < stats.bestLegDarts) {
              stats.bestLegDarts = legDarts;
            }
            if (legDarts > stats.worstLegDarts) {
              stats.worstLegDarts = legDarts;
            }

            // Checkout score
            if (playerTurns.isNotEmpty) {
              final lastTurn = playerTurns.last;
              if (!lastTurn.isBust && lastTurn.totalScore > stats.highestCheckout) {
                stats.highestCheckout = lastTurn.totalScore;
              }
            }
          }
        }
      }
    }

    // Compute checkout percentage
    for (final game in games) {
      if (!game.isCompleted) continue;
      for (final player in game.players) {
        final key = player.name.toLowerCase();
        final stats = statsMap[key];
        if (stats == null) continue;
        if (stats.legsPlayed > 0) {
          stats.checkoutPercentage =
              stats.legsWon / stats.legsPlayed * 100;
        }
      }
    }

    return statsMap;
  }

  /// Filter games by date range. Pass null for no filter.
  List<Game> filterGames(
    List<Game> games, {
    DateTime? from,
    DateTime? to,
  }) {
    return games.where((g) {
      if (from != null && g.startedAt.isBefore(from)) return false;
      if (to != null && g.startedAt.isAfter(to)) return false;
      return true;
    }).toList();
  }

  List<Game> getGamesToday(List<Game> games) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return filterGames(games, from: start, to: end);
  }
}
