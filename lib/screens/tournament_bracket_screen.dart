import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/tournament.dart';
import 'package:d4rts/widgets/bracket_view.dart';

class TournamentBracketScreen extends StatefulWidget {
  const TournamentBracketScreen({super.key});

  @override
  State<TournamentBracketScreen> createState() =>
      _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _playMatch(BuildContext context, Game match, Tournament tournament) {
    final appState = context.read<AppState>();

    // Create a fresh copy of the match to play
    final gameToPlay = Game(
      id: match.id,
      startedAt: DateTime.now(),
      players: match.players,
      startingScore: tournament.startingScore,
      legsToWin: tournament.legsToWin,
      checkoutMode: tournament.checkoutMode,
    );

    appState.startTournamentMatch(gameToPlay);
    context.push('/game/play');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final tournament = appState.activeTournament;

        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tournament')),
            body: const Center(child: Text('No active tournament')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Tournament (${tournament.players.length} players)',
            ),
            leading: BackButton(onPressed: () => context.pop()),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Group Stage'),
                Tab(text: 'Knockout'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Group Stage Tab
              _GroupStageView(
                tournament: tournament,
                onMatchTap: (match) =>
                    _playMatch(context, match, tournament),
              ),
              // Knockout Tab
              _KnockoutView(
                tournament: tournament,
                onMatchTap: (match) =>
                    _playMatch(context, match, tournament),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupStageView extends StatelessWidget {
  final Tournament tournament;
  final void Function(Game match) onMatchTap;

  const _GroupStageView({
    required this.tournament,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tournament.groups.isEmpty) {
      return const Center(child: Text('No groups generated'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournament.groups.length,
      itemBuilder: (ctx, groupIdx) {
        final group = tournament.groups[groupIdx];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group ${String.fromCharCode(65 + group.index)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  group.players.map((p) => p.name).join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(),
                ...group.matches.map((match) {
                  final isCompleted = match.isCompleted;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      match.players.map((p) => p.name).join(' vs '),
                    ),
                    subtitle: isCompleted
                        ? Text(
                            'Winner: ${match.winnerName}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Text('Not played'),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: () => onMatchTap(match),
                            child: const Text('Play'),
                          ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KnockoutView extends StatelessWidget {
  final Tournament tournament;
  final void Function(Game match) onMatchTap;

  const _KnockoutView({
    required this.tournament,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament.knockoutRounds.isEmpty) {
      final allGroupMatchesDone = tournament.groups.every(
        (g) => g.matches.every((m) => m.isCompleted),
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                allGroupMatchesDone
                    ? 'Group stage complete!\nKnockout bracket will be generated.'
                    : 'Complete all group matches first to unlock the knockout stage.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BracketView(
        rounds: tournament.knockoutRounds,
        onMatchTap: (match) {
          if (!match.isCompleted) onMatchTap(match);
        },
      ),
    );
  }
}
