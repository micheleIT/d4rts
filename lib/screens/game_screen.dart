import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/models/dart_throw.dart';
import 'package:d4rts/models/turn.dart';
import 'package:d4rts/services/game_service.dart';
import 'package:d4rts/utils/checkout_tables.dart';
import 'package:d4rts/utils/dart_input_parser.dart';
import 'package:d4rts/widgets/dartboard_input.dart';
import 'package:d4rts/widgets/score_display.dart';
import 'package:d4rts/widgets/throw_input_field.dart';

enum InputMode { text, matrix }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  InputMode _inputMode = InputMode.text;

  final _dart1Controller = TextEditingController();
  final _dart2Controller = TextEditingController();
  final _dart3Controller = TextEditingController();
  final _focus1 = FocusNode();
  final _focus2 = FocusNode();
  final _focus3 = FocusNode();

  @override
  void dispose() {
    _dart1Controller.dispose();
    _dart2Controller.dispose();
    _dart3Controller.dispose();
    _focus1.dispose();
    _focus2.dispose();
    _focus3.dispose();
    super.dispose();
  }

  void _clearInputs() {
    _dart1Controller.clear();
    _dart2Controller.clear();
    _dart3Controller.clear();
    _focus1.requestFocus();
  }

  List<DartThrow>? _parseTextInputs() {
    final inputs = [
      _dart1Controller.text.trim(),
      _dart2Controller.text.trim(),
      _dart3Controller.text.trim(),
    ].where((s) => s.isNotEmpty).toList();

    if (inputs.isEmpty) return null;

    final darts = <DartThrow>[];
    for (final input in inputs) {
      try {
        darts.add(DartInputParser.parse(input));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid input: $input')),
        );
        return null;
      }
    }
    return darts;
  }

  void _submitTextTurn() {
    final darts = _parseTextInputs();
    if (darts == null || darts.isEmpty) return;
    _submitTurn(darts);
    _clearInputs();
  }

  void _submitTurn(List<DartThrow> darts) {
    final gameService = context.read<AppState>().gameService;
    final result = gameService.submitTurn(darts);

    if (result.isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Error')),
      );
      return;
    }

    if (result.isBust) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bust!'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    if (result.isLegWon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.message} wins the leg!'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    if (result.isGameWon) {
      context.go('/game/result');
    }
  }

  void _undo() {
    final gameService = context.read<AppState>().gameService;
    gameService.undoLastTurn();
    _clearInputs();
  }

  void _showEndGameDialog(BuildContext context, GameService gameService) {
    final appState = context.read<AppState>();
    final isTournamentGame = appState.hasPendingTournamentMatch;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Game?'),
        content: Text(
          isTournamentGame
              ? 'Do you want to abandon this tournament match?\n\nThe match result will not be recorded.'
              : 'Do you want to end the current game?\n\nThe game will be abandoned and progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Playing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              gameService.reset();
              if (isTournamentGame) {
                context.go('/tournament/bracket');
              } else {
                context.go('/');
              }
            },
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final gameService = appState.gameService;
        final game = gameService.game;

        if (game == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Game')),
            body: const Center(child: Text('No active game')),
          );
        }

        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('D4RTS'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: gameService.canUndo ? _undo : null,
                tooltip: 'Undo last turn',
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined),
                tooltip: 'End Game',
                onPressed: () => _showEndGameDialog(context, gameService),
              ),
            ],
          ),
          body: Column(
            children: [
              // Score cards
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: game.players.length,
                  itemBuilder: (ctx, i) {
                    final player = game.players[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: 140,
                        child: ChangeNotifierProvider.value(
                          value: gameService,
                          child: Consumer<GameService>(
                            builder: (ctx, gs, _) => ScoreDisplay(
                              playerName: player.name,
                              remainingScore:
                                  gs.getCurrentPlayerScore(player.name),
                              legWins: gs.getLegWins(player.name),
                              isActive:
                                  gs.currentPlayer?.name == player.name,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Current player & checkout hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ChangeNotifierProvider.value(
                  value: gameService,
                  child: Consumer<GameService>(
                    builder: (ctx, gs, _) {
                      final activePlayer = gs.currentPlayer;
                      if (activePlayer == null) return const SizedBox.shrink();
                      final score = gs.getCurrentPlayerScore(activePlayer.name);
                      final checkout = score <= 170 ? getCheckout(score) : null;
                      return Column(
                        children: [
                          Text(
                            '${activePlayer.name}\'s turn',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (checkout != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '🎯 $checkout',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const Divider(),

              // Input mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SegmentedButton<InputMode>(
                  segments: const [
                    ButtonSegment(
                      value: InputMode.text,
                      icon: Icon(Icons.keyboard),
                      label: Text('Text'),
                    ),
                    ButtonSegment(
                      value: InputMode.matrix,
                      icon: Icon(Icons.grid_view),
                      label: Text('Board'),
                    ),
                  ],
                  selected: {_inputMode},
                  onSelectionChanged: (s) =>
                      setState(() => _inputMode = s.first),
                ),
              ),

              // Input area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _inputMode == InputMode.text
                      ? _TextInputArea(
                          dart1Controller: _dart1Controller,
                          dart2Controller: _dart2Controller,
                          dart3Controller: _dart3Controller,
                          focus1: _focus1,
                          focus2: _focus2,
                          focus3: _focus3,
                          onSubmit: _submitTextTurn,
                        )
                      : DartboardInput(
                          onConfirm: _submitTurn,
                        ),
                ),
              ),

              // Recent turns
              ChangeNotifierProvider.value(
                value: gameService,
                child: Consumer<GameService>(
                  builder: (ctx, gs, _) {
                    final activePlayer = gs.currentPlayer;
                    if (activePlayer == null) return const SizedBox.shrink();
                    final recentTurns = gs.getRecentTurns(activePlayer.name);
                    if (recentTurns.isEmpty) return const SizedBox.shrink();
                    return _RecentTurns(turns: recentTurns);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextInputArea extends StatelessWidget {
  final TextEditingController dart1Controller;
  final TextEditingController dart2Controller;
  final TextEditingController dart3Controller;
  final FocusNode focus1;
  final FocusNode focus2;
  final FocusNode focus3;
  final VoidCallback onSubmit;

  const _TextInputArea({
    required this.dart1Controller,
    required this.dart2Controller,
    required this.dart3Controller,
    required this.focus1,
    required this.focus2,
    required this.focus3,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ThrowInputField(
                controller: dart1Controller,
                label: 'Dart 1',
                autoFocus: true,
                focusNode: focus1,
                nextFocusNode: focus2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ThrowInputField(
                controller: dart2Controller,
                label: 'Dart 2',
                focusNode: focus2,
                nextFocusNode: focus3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ThrowInputField(
                controller: dart3Controller,
                label: 'Dart 3',
                focusNode: focus3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.check),
          label: const Text('Confirm Turn'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

class _RecentTurns extends StatelessWidget {
  final List<Turn> turns;

  const _RecentTurns({required this.turns});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Turns',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          Row(
            children: turns.reversed.take(3).map((t) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  t.isBust
                      ? 'BUST (${t.totalScore})'
                      : '${t.totalScore}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.isBust ? Colors.red : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
