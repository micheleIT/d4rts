import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/models/tournament.dart';
import 'package:d4rts/services/game_service.dart';
import 'package:d4rts/services/storage_service.dart';
import 'package:d4rts/services/stats_service.dart';
import 'package:d4rts/services/tournament_service.dart';
import 'package:d4rts/utils/constants.dart';

class AppSettings {
  int defaultStartingScore;
  int defaultLegsToWin;
  CheckoutMode defaultCheckoutMode;
  int defaultTournamentGroups;
  String themeMode; // 'system', 'light', 'dark'

  AppSettings({
    this.defaultStartingScore = 501,
    this.defaultLegsToWin = 3,
    this.defaultCheckoutMode = CheckoutMode.doubleOut,
    this.defaultTournamentGroups = 2,
    this.themeMode = 'system',
  });

  Map<String, dynamic> toJson() => {
        'defaultStartingScore': defaultStartingScore,
        'defaultLegsToWin': defaultLegsToWin,
        'defaultCheckoutMode': defaultCheckoutMode.name,
        'defaultTournamentGroups': defaultTournamentGroups,
        'themeMode': themeMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        defaultStartingScore:
            json['defaultStartingScore'] as int? ?? 501,
        defaultLegsToWin: json['defaultLegsToWin'] as int? ?? 3,
        defaultCheckoutMode: CheckoutMode.values.firstWhere(
          (m) => m.name == (json['defaultCheckoutMode'] as String?),
          orElse: () => CheckoutMode.doubleOut,
        ),
        defaultTournamentGroups:
            json['defaultTournamentGroups'] as int? ?? 2,
        themeMode: json['themeMode'] as String? ?? 'system',
      );
}

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final GameService gameService = GameService();
  final StatsService statsService = StatsService();
  final TournamentService tournamentService = TournamentService();
  final _uuid = const Uuid();

  List<Game> _games = [];
  List<Tournament> _tournaments = [];
  Tournament? _activeTournament;
  String? _pendingTournamentMatchId; // track if current game is a tournament match
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  List<Game> get games => List.unmodifiable(_games);
  List<Tournament> get tournaments => List.unmodifiable(_tournaments);
  Tournament? get activeTournament => _activeTournament;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storage.init();
      _games = await _storage.getGames();
      _tournaments = await _storage.getTournaments();
      await _loadSettings();
    } catch (e) {
      debugPrint('AppState init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('defaultStartingScore');
    final legs = prefs.getInt('defaultLegsToWin');
    final checkoutName = prefs.getString('defaultCheckoutMode');
    final groups = prefs.getInt('defaultTournamentGroups');
    final theme = prefs.getString('themeMode');

    _settings = AppSettings(
      defaultStartingScore: score ?? 501,
      defaultLegsToWin: legs ?? 3,
      defaultCheckoutMode: checkoutName != null
          ? CheckoutMode.values.firstWhere(
              (m) => m.name == checkoutName,
              orElse: () => CheckoutMode.doubleOut,
            )
          : CheckoutMode.doubleOut,
      defaultTournamentGroups: groups ?? 2,
      themeMode: theme ?? 'system',
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultStartingScore', settings.defaultStartingScore);
    await prefs.setInt('defaultLegsToWin', settings.defaultLegsToWin);
    await prefs.setString(
        'defaultCheckoutMode', settings.defaultCheckoutMode.name);
    await prefs.setInt(
        'defaultTournamentGroups', settings.defaultTournamentGroups);
    await prefs.setString('themeMode', settings.themeMode);
    notifyListeners();
  }

  Game createGame({
    required List<Player> players,
    required int startingScore,
    Map<String, int>? handicaps,
    required int legsToWin,
    required CheckoutMode checkoutMode,
  }) {
    return Game(
      id: _uuid.v4(),
      startedAt: DateTime.now(),
      players: players,
      startingScore: startingScore,
      handicaps: handicaps,
      legsToWin: legsToWin,
      checkoutMode: checkoutMode,
    );
  }

  void startGame(Game game) {
    gameService.startGame(game);
    notifyListeners();
  }

  Future<void> completeGame(Game game) async {
    // Update or add game to list
    final idx = _games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) {
      _games[idx] = game;
    } else {
      _games.add(game);
    }
    await _storage.saveGame(game);

    // Update tournament match if this was a tournament game
    if (_pendingTournamentMatchId != null &&
        _pendingTournamentMatchId == game.id &&
        _activeTournament != null) {
      _updateTournamentMatch(game);
      _pendingTournamentMatchId = null;
      await _storage.saveTournament(_activeTournament!);
    }

    gameService.reset();
    notifyListeners();
  }

  void _updateTournamentMatch(Game completedGame) {
    if (_activeTournament == null) return;

    // Search in group matches
    for (final group in _activeTournament!.groups) {
      final idx = group.matches.indexWhere((m) => m.id == completedGame.id);
      if (idx >= 0) {
        group.matches[idx] = completedGame;
        // Re-rank the group
        group.standings = tournamentService.rankGroup(group);
        return;
      }
    }

    // Search in knockout matches
    for (final round in _activeTournament!.knockoutRounds) {
      final idx = round.matches.indexWhere((m) => m.id == completedGame.id);
      if (idx >= 0) {
        round.matches[idx] = completedGame;
        // Generate next round if all matches in this round are done
        final allDone = round.matches.every((m) => m.isCompleted);
        if (allDone) {
          tournamentService.updateKnockoutBracket(
            _activeTournament!,
            completedGame,
            startingScore: _activeTournament!.startingScore,
            legsToWin: _activeTournament!.legsToWin,
            checkoutMode: _activeTournament!.checkoutMode,
          );
        }
        return;
      }
    }
  }

  /// Start a tournament match (tracks that the current game is a tournament match)
  void startTournamentMatch(Game game) {
    _pendingTournamentMatchId = game.id;
    gameService.startGame(game);
    notifyListeners();
  }

  Future<void> saveGameProgress(Game game) async {
    final idx = _games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) {
      _games[idx] = game;
    } else {
      _games.add(game);
    }
    await _storage.saveGame(game);
    notifyListeners();
  }

  Tournament createTournament({
    required List<Player> players,
    required int numberOfGroups,
    required int startingScore,
    required int legsToWin,
    required CheckoutMode checkoutMode,
  }) {
    final groups = tournamentService.generateGroups(players, numberOfGroups);
    final populatedGroups = groups.map((g) {
      final matches = tournamentService.generateRoundRobin(
        g,
        startingScore: startingScore,
        legsToWin: legsToWin,
        checkoutMode: checkoutMode,
      );
      return TournamentGroup(
        index: g.index,
        players: g.players,
        matches: matches,
      );
    }).toList();

    return Tournament(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      players: players,
      numberOfGroups: numberOfGroups,
      groups: populatedGroups,
      startingScore: startingScore,
      legsToWin: legsToWin,
      checkoutMode: checkoutMode,
    );
  }

  void setActiveTournament(Tournament tournament) {
    _activeTournament = tournament;
    notifyListeners();
  }

  Future<void> saveTournament(Tournament tournament) async {
    final idx = _tournaments.indexWhere((t) => t.id == tournament.id);
    if (idx >= 0) {
      _tournaments[idx] = tournament;
    } else {
      _tournaments.add(tournament);
    }
    if (_activeTournament?.id == tournament.id) {
      _activeTournament = tournament;
    }
    await _storage.saveTournament(tournament);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storage.clearAll();
    _games = [];
    _tournaments = [];
    _activeTournament = null;
    gameService.reset();
    notifyListeners();
  }

  Future<void> importData(
      List<Game> games, List<Tournament> tournaments) async {
    for (final game in games) {
      await _storage.saveGame(game);
      final idx = _games.indexWhere((g) => g.id == game.id);
      if (idx >= 0) {
        _games[idx] = game;
      } else {
        _games.add(game);
      }
    }
    for (final tournament in tournaments) {
      await _storage.saveTournament(tournament);
      final idx = _tournaments.indexWhere((t) => t.id == tournament.id);
      if (idx >= 0) {
        _tournaments[idx] = tournament;
      } else {
        _tournaments.add(tournament);
      }
    }
    notifyListeners();
  }
}
