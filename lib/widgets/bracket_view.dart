import 'package:flutter/material.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/tournament.dart';

class BracketView extends StatelessWidget {
  final List<KnockoutRound> rounds;
  final void Function(Game match)? onMatchTap;

  const BracketView({
    super.key,
    required this.rounds,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return const Center(
        child: Text('Knockout bracket not yet generated.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rounds.map((round) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    round.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...round.matches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _MatchCard(
                      match: match,
                      onTap: onMatchTap != null ? () => onMatchTap!(match) : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Game match;
  final VoidCallback? onTap;

  const _MatchCard({required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = match.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: isCompleted ? colorScheme.primary : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isCompleted
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surface,
        ),
        child: Column(
          children: match.players.map((player) {
            final isWinner =
                match.winnerName?.toLowerCase() == player.name.toLowerCase();
            int legWins = 0;
            for (final leg in match.legs) {
              if (leg.winnerName?.toLowerCase() == player.name.toLowerCase()) {
                legWins++;
              }
            }
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isWinner ? colorScheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight:
                            isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Text(
                      '$legWins',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isWinner
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
