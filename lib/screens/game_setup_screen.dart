import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/utils/constants.dart';
import 'package:d4rts/widgets/player_list_tile.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _nameController = TextEditingController();
  final List<Player> _players = [];
  final Map<String, int> _handicaps = {};
  late int _startingScore;
  late int _legsToWin;
  late CheckoutMode _checkoutMode;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
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
      _handicaps[name.toLowerCase()] = 0;
      _nameController.clear();
    });
  }

  void _removePlayer(Player player) {
    setState(() {
      _players.remove(player);
      _handicaps.remove(player.name.toLowerCase());
    });
  }

  void _startGame() {
    if (_players.length < 2) return;
    final appState = context.read<AppState>();
    final game = appState.createGame(
      players: _players,
      startingScore: _startingScore,
      handicaps: _handicaps,
      legsToWin: _legsToWin,
      checkoutMode: _checkoutMode,
    );
    appState.startGame(game);
    context.go('/game/play');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Add player row
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
              FilledButton(
                onPressed: _addPlayer,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Player list
          if (_players.isEmpty)
            Center(
              child: Text(
                'Add at least 2 players to start',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ..._players.map(
              (p) => PlayerListTile(
                player: p,
                handicap: _handicaps[p.name.toLowerCase()] ?? 0,
                onRemove: () => _removePlayer(p),
                onHandicapChanged: (v) {
                  setState(() => _handicaps[p.name.toLowerCase()] = v);
                },
              ),
            ),

          const Divider(height: 32),

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
            onSelectionChanged: (s) =>
                setState(() => _legsToWin = s.first),
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
            onPressed: _players.length >= 2 ? _startGame : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Game'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
