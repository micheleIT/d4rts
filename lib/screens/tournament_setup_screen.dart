import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/utils/constants.dart';
import 'package:d4rts/widgets/player_list_tile.dart';

class TournamentSetupScreen extends StatefulWidget {
  const TournamentSetupScreen({super.key});

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  final _nameController = TextEditingController();
  final List<Player> _players = [];
  late int _numberOfGroups;
  late int _startingScore;
  late int _legsToWin;
  late CheckoutMode _checkoutMode;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    _numberOfGroups = settings.defaultTournamentGroups;
    _startingScore = settings.defaultStartingScore;
    _legsToWin = settings.defaultLegsToWin;
    _checkoutMode = settings.defaultCheckoutMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_players.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player already added')),
      );
      return;
    }
    setState(() {
      _players.add(Player(name: name));
      _nameController.clear();
    });
  }

  void _generateBracket() {
    if (_players.length < 2) return;
    final effectiveGroups = _numberOfGroups.clamp(1, _players.length ~/ 2);
    final appState = context.read<AppState>();
    final tournament = appState.createTournament(
      players: _players,
      numberOfGroups: effectiveGroups,
      startingScore: _startingScore,
      legsToWin: _legsToWin,
      checkoutMode: _checkoutMode,
    );
    appState.setActiveTournament(tournament);
    appState.saveTournament(tournament);
    context.push('/tournament/bracket');
  }

  int get _maxGroups => (_players.length ~/ 2).clamp(1, 8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Setup'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Add player
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Player name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addPlayer, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),

          if (_players.isEmpty)
            Center(
              child: Text(
                'Add at least 2 players',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ..._players.map(
              (p) => PlayerListTile(
                player: p,
                showHandicap: false,
                onRemove: () => setState(() => _players.remove(p)),
              ),
            ),

          const Divider(height: 32),

          // Number of groups
          Text('Number of Groups', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _numberOfGroups > 1
                    ? () => setState(() => _numberOfGroups--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_numberOfGroups',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ),
              IconButton(
                onPressed: _numberOfGroups < _maxGroups
                    ? () => setState(() => _numberOfGroups++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Text(
            'Max groups for ${_players.length} players: $_maxGroups',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // Starting score
          Text('Starting Score', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: startingScoreOptions
                .map((s) => ButtonSegment(value: s, label: Text('$s')))
                .toList(),
            selected: {_startingScore},
            onSelectionChanged: (s) =>
                setState(() => _startingScore = s.first),
          ),

          const SizedBox(height: 16),

          // Legs to win
          Text('Legs to Win', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: legsToWinOptions
                .map((l) => ButtonSegment(value: l, label: Text('$l')))
                .toList(),
            selected: {_legsToWin},
            onSelectionChanged: (s) => setState(() => _legsToWin = s.first),
          ),

          const SizedBox(height: 16),

          // Checkout mode
          Text('Checkout Mode', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<CheckoutMode>(
            value: _checkoutMode,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: CheckoutMode.values
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(checkoutModeName(m)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _checkoutMode = v);
            },
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _players.length >= 2 ? _generateBracket : null,
            icon: const Icon(Icons.account_tree),
            label: const Text('Generate Bracket'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
