import 'package:flutter/foundation.dart';
import 'package:d4rts/models/dart_throw.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/leg.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/models/turn.dart';
import 'package:d4rts/utils/constants.dart';

enum TurnResultType { normal, bust, legWon, gameWon, error }

class TurnResult {
  final TurnResultType type;
  final String? message;
  final int? remaining;

  const TurnResult._({required this.type, this.message, this.remaining});

  factory TurnResult.normal(int remaining) =>
      TurnResult._(type: TurnResultType.normal, remaining: remaining);

  factory TurnResult.bust() =>
      const TurnResult._(type: TurnResultType.bust, message: 'Bust!');

  factory TurnResult.legWon(String player) =>
      TurnResult._(type: TurnResultType.legWon, message: player);

  factory TurnResult.gameWon(String player) =>
      TurnResult._(type: TurnResultType.gameWon, message: player);

  factory TurnResult.error(String msg) =>
      TurnResult._(type: TurnResultType.error, message: msg);

  bool get isBust => type == TurnResultType.bust;
  bool get isLegWon => type == TurnResultType.legWon;
  bool get isGameWon => type == TurnResultType.gameWon;
  bool get isError => type == TurnResultType.error;
  bool get isNormal => type == TurnResultType.normal;
}

class _TurnRecord {
  final String playerName;
  final int previousScore;
  final int playerIndex;
  final int legIndex;
  final bool wasLegWon;
  final String? legWinner;
  final Map<String, int> legWinsSnapshot;

  _TurnRecord({
    required this.playerName,
    required this.previousScore,
    required this.playerIndex,
    required this.legIndex,
    this.wasLegWon = false,
    this.legWinner,
    required this.legWinsSnapshot,
  });
}

class GameService extends ChangeNotifier {
  Game? _game;
  int _currentPlayerIndex = 0;
  int _currentLegIndex = 0;
  final Map<String, int> _legWins = {};
  final Map<String, int> _currentScores = {};
  final List<_TurnRecord> _turnHistory = [];

  Game? get game => _game;
  int get currentPlayerIndex => _currentPlayerIndex;
  int get currentLegIndex => _currentLegIndex;

  Player? get currentPlayer {
    if (_game == null) return null;
    if (_currentPlayerIndex >= _game!.players.length) return null;
    return _game!.players[_currentPlayerIndex];
  }

  bool get isGameOver => _game?.winnerName != null;
  bool get hasActiveGame => _game != null && !isGameOver;

  void startGame(Game game) {
    _game = game;
    _currentPlayerIndex = 0;
    _currentLegIndex = 0;
    _legWins.clear();
    _currentScores.clear();
    _turnHistory.clear();

    for (final p in game.players) {
      _legWins[p.name.toLowerCase()] = 0;
    }

    _initCurrentLeg();
    notifyListeners();
  }

  void _initCurrentLeg() {
    if (_game == null) return;
    // Add new leg if needed
    while (_game!.legs.length <= _currentLegIndex) {
      _game!.legs.add(Leg(
        startingScore: _game!.startingScore,
        checkoutMode: _game!.checkoutMode,
      ));
    }
    // Reset scores with handicaps applied (handicap adds extra points)
    for (final player in _game!.players) {
      final key = player.name.toLowerCase();
      final handicap = _game!.handicaps[key] ?? 0;
      _currentScores[key] = _game!.startingScore + handicap;
    }
  }

  int getCurrentPlayerScore(String playerName) {
    return _currentScores[playerName.toLowerCase()] ?? (_game?.startingScore ?? 0);
  }

  int getLegWins(String playerName) {
    return _legWins[playerName.toLowerCase()] ?? 0;
  }

  Leg? get currentLeg {
    if (_game == null || _currentLegIndex >= _game!.legs.length) return null;
    return _game!.legs[_currentLegIndex];
  }

  TurnResult submitTurn(List<DartThrow> darts) {
    if (_game == null || isGameOver) {
      return TurnResult.error('No active game');
    }
    if (darts.isEmpty) {
      return TurnResult.error('No darts thrown');
    }

    final player = currentPlayer!;
    final key = player.name.toLowerCase();
    final currentScore = _currentScores[key]!;
    final turn = Turn(darts: darts);
    final totalScore = turn.totalScore;
    final newScore = currentScore - totalScore;

    // Save undo record
    _turnHistory.add(_TurnRecord(
      playerName: key,
      previousScore: currentScore,
      playerIndex: _currentPlayerIndex,
      legIndex: _currentLegIndex,
      legWinsSnapshot: Map.from(_legWins),
    ));

    // Bust: score goes below 0
    if (newScore < 0) {
      _recordTurn(player.name, Turn(darts: darts, isBust: true));
      _advancePlayer();
      notifyListeners();
      return TurnResult.bust();
    }

    // Bust: remaining == 1 with doubleOut or masterOut (can't finish)
    if (newScore == 1 &&
        (_game!.checkoutMode == CheckoutMode.doubleOut ||
            _game!.checkoutMode == CheckoutMode.masterOut)) {
      _recordTurn(player.name, Turn(darts: darts, isBust: true));
      _advancePlayer();
      notifyListeners();
      return TurnResult.bust();
    }

    // Checkout attempt (newScore == 0)
    if (newScore == 0) {
      final lastDart = darts.last;
      bool validCheckout = false;

      switch (_game!.checkoutMode) {
        case CheckoutMode.straightOut:
          validCheckout = true;
          break;
        case CheckoutMode.doubleOut:
          validCheckout = lastDart.isDouble;
          break;
        case CheckoutMode.tripleOut:
          validCheckout = lastDart.isTriple;
          break;
        case CheckoutMode.masterOut:
          validCheckout = lastDart.isDouble || lastDart.isTriple;
          break;
      }

      if (!validCheckout) {
        // Invalid checkout → bust
        _recordTurn(player.name, Turn(darts: darts, isBust: true));
        _advancePlayer();
        notifyListeners();
        return TurnResult.bust();
      }

      // Valid checkout!
      _currentScores[key] = 0;
      _recordTurn(player.name, turn);

      final leg = _game!.legs[_currentLegIndex];
      leg.winnerName = player.name;
      _legWins[key] = (_legWins[key] ?? 0) + 1;

      // Check if game is won
      if (_legWins[key]! >= _game!.legsToWin) {
        _game!.winnerName = player.name;
        _game!.completedAt = DateTime.now();
        notifyListeners();
        return TurnResult.gameWon(player.name);
      }

      // Start new leg
      _currentLegIndex++;
      _initCurrentLeg();
      _advancePlayer();
      notifyListeners();
      return TurnResult.legWon(player.name);
    }

    // Normal turn
    _currentScores[key] = newScore;
    _recordTurn(player.name, turn);
    _advancePlayer();
    notifyListeners();
    return TurnResult.normal(newScore);
  }

  void _recordTurn(String playerName, Turn turn) {
    if (_game == null || _currentLegIndex >= _game!.legs.length) return;
    _game!.legs[_currentLegIndex].addTurn(playerName, turn);
  }

  void _advancePlayer() {
    if (_game == null) return;
    _currentPlayerIndex =
        (_currentPlayerIndex + 1) % _game!.players.length;
  }

  bool get canUndo => _turnHistory.isNotEmpty;

  void undoLastTurn() {
    if (_turnHistory.isEmpty || _game == null) return;

    final record = _turnHistory.removeLast();

    // Restore scores
    _currentScores[record.playerName] = record.previousScore;

    // Restore player index and leg index
    _currentPlayerIndex = record.playerIndex;

    // If leg changed (leg was won), remove the extra leg
    if (record.legIndex < _currentLegIndex) {
      while (_game!.legs.length > record.legIndex + 1) {
        _game!.legs.removeLast();
      }
      _currentLegIndex = record.legIndex;
    }

    // Restore leg wins
    _legWins
      ..clear()
      ..addAll(record.legWinsSnapshot);

    // Clear leg winner if set
    final leg = _game!.legs[_currentLegIndex];
    leg.winnerName = null;

    // Remove last turn for this player
    final playerTurns = leg.turns[record.playerName];
    if (playerTurns != null && playerTurns.isNotEmpty) {
      playerTurns.removeLast();
    }

    // Clear game winner if set
    _game!.winnerName = null;
    _game!.completedAt = null;

    notifyListeners();
  }

  List<Turn> getRecentTurns(String playerName, {int count = 3}) {
    if (_game == null) return [];
    final key = playerName.toLowerCase();
    final allTurns = <Turn>[];
    for (final leg in _game!.legs) {
      allTurns.addAll(leg.turns[key] ?? []);
    }
    if (allTurns.length <= count) return allTurns;
    return allTurns.sublist(allTurns.length - count);
  }

  void reset() {
    _game = null;
    _currentPlayerIndex = 0;
    _currentLegIndex = 0;
    _legWins.clear();
    _currentScores.clear();
    _turnHistory.clear();
    notifyListeners();
  }
}
