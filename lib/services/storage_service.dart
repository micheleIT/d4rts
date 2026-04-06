import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/tournament.dart';

class StorageService {
  static const String _gamesBoxName = 'games';
  static const String _tournamentsBoxName = 'tournaments';

  late Box<String> _gamesBox;
  late Box<String> _tournamentsBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _gamesBox = await Hive.openBox<String>(_gamesBoxName);
    _tournamentsBox = await Hive.openBox<String>(_tournamentsBoxName);
    _initialized = true;
  }

  Future<void> saveGame(Game game) async {
    await _gamesBox.put(game.id, jsonEncode(game.toJson()));
  }

  Future<List<Game>> getGames() async {
    return _gamesBox.values
        .map((json) =>
            Game.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteGame(String id) async {
    await _gamesBox.delete(id);
  }

  Future<void> saveTournament(Tournament tournament) async {
    await _tournamentsBox.put(
        tournament.id, jsonEncode(tournament.toJson()));
  }

  Future<List<Tournament>> getTournaments() async {
    return _tournamentsBox.values
        .map((json) =>
            Tournament.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteTournament(String id) async {
    await _tournamentsBox.delete(id);
  }

  Future<void> clearAll() async {
    await _gamesBox.clear();
    await _tournamentsBox.clear();
  }
}
