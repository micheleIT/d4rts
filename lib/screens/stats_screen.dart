import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/player_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overall'),
            Tab(text: 'Today'),
          ],
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final allGames = appState.games;
          final todayGames = appState.statsService.getGamesToday(allGames.toList());

          return TabBarView(
            controller: _tabController,
            children: [
              _StatsTab(
                games: allGames.toList(),
                appState: appState,
              ),
              _StatsTab(
                games: todayGames,
                appState: appState,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final List<Game> games;
  final AppState appState;

  const _StatsTab({required this.games, required this.appState});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No games recorded yet'),
          ],
        ),
      );
    }

    final statsMap = appState.statsService.computeStats(games);
    if (statsMap.isEmpty) {
      return const Center(child: Text('No stats available'));
    }

    final statsList = statsMap.values.toList()
      ..sort((a, b) => b.threeDartAverage.compareTo(a.threeDartAverage));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statsList.length,
      itemBuilder: (ctx, i) => _PlayerStatsCard(stats: statsList[i]),
    );
  }
}

class _PlayerStatsCard extends StatefulWidget {
  final PlayerStats stats;

  const _PlayerStatsCard({required this.stats});

  @override
  State<_PlayerStatsCard> createState() => _PlayerStatsCardState();
}

class _PlayerStatsCardState extends State<_PlayerStatsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.stats;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      stats.playerName.isNotEmpty
                          ? stats.playerName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.playerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '3-Dart Avg: ${stats.threeDartAverage.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (_expanded) ...[
                const Divider(height: 20),
                _StatsGrid(stats: stats),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final PlayerStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Games', '${stats.gamesWon}/${stats.gamesPlayed}'),
      ('Legs', '${stats.legsWon}/${stats.legsPlayed}'),
      ('Checkout %', '${stats.checkoutPercentage.toStringAsFixed(1)}%'),
      ('High Checkout', '${stats.highestCheckout}'),
      ('First 9 Avg', stats.firstNineAverage.toStringAsFixed(2)),
      ('180s', '${stats.count180s}'),
      ('140+', '${stats.count140plus}'),
      ('100+', '${stats.count100plus}'),
      ('Best Leg', stats.bestLegDarts > 0 ? '${stats.bestLegDarts} darts' : '-'),
      ('Worst Leg', stats.worstLegDarts > 0 ? '${stats.worstLegDarts} darts' : '-'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final theme = Theme.of(ctx);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                items[i].$1,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                items[i].$2,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
