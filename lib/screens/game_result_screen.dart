import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';

class GameResultScreen extends StatefulWidget {
  const GameResultScreen({super.key});

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  bool _saved = false;
  bool _wasTournamentGame = false;
  bool _dependenciesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) return;
    _dependenciesInitialized = true;
    // Capture synchronously before completeGame() clears the pending match id
    final appState = context.read<AppState>();
    _wasTournamentGame = appState.hasPendingTournamentMatch;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_saved) return;
      _saved = true;
      final game = appState.gameService.game;
      if (game != null && game.isCompleted) {
        await appState.completeGame(game);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final game = appState.gameService.game;
    final theme = Theme.of(context);

    if (game == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No game result available'),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
    }

    final winner = game.winnerName ?? 'Unknown';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.emoji_events,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '🎯 $winner Wins!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Per-player stats
              ...game.players.map((player) {
                final key = player.name.toLowerCase();
                var legsWon = 0;
                var totalDarts = 0;
                var totalScore = 0;
                var turnCount = 0;

                for (final leg in game.legs) {
                  if (leg.winnerName?.toLowerCase() == key) legsWon++;
                  final playerTurns = leg.turns[key] ?? [];
                  for (final turn in playerTurns) {
                    if (!turn.isBust) {
                      totalDarts += turn.darts.length;
                      totalScore += turn.totalScore;
                      turnCount++;
                    }
                  }
                }

                final avg = totalDarts > 0
                    ? (totalScore / totalDarts * 3).toStringAsFixed(1)
                    : '0.0';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                player.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (player.name == winner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Winner',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatChip(label: 'Legs', value: '$legsWon'),
                            const SizedBox(width: 8),
                            _StatChip(label: '3-Dart Avg', value: avg),
                            const SizedBox(width: 8),
                            _StatChip(label: 'Turns', value: '$turnCount'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const Spacer(),

              if (_wasTournamentGame) ...[
                // Tournament match: only offer return to bracket
                FilledButton.icon(
                  onPressed: () => context.go('/tournament/bracket'),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Back to Tournament'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/game/setup'),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Play Again'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
