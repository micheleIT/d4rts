import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/utils/constants.dart';

class TournamentGroup {
  final int index;
  final List<Player> players;
  final List<Game> matches;
  List<Player> standings; // ordered by wins, then leg diff

  TournamentGroup({
    required this.index,
    required this.players,
    List<Game>? matches,
    List<Player>? standings,
  })  : matches = matches ?? [],
        standings = standings ?? [];

  Map<String, dynamic> toJson() => {
        'index': index,
        'players': players.map((p) => p.toJson()).toList(),
        'matches': matches.map((m) => m.toJson()).toList(),
        'standings': standings.map((p) => p.toJson()).toList(),
      };

  factory TournamentGroup.fromJson(Map<String, dynamic> json) =>
      TournamentGroup(
        index: json['index'] as int,
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        matches: (json['matches'] as List?)
                ?.map((m) => Game.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        standings: (json['standings'] as List?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class KnockoutRound {
  final String name;
  final List<Game> matches;

  KnockoutRound({
    required this.name,
    List<Game>? matches,
  }) : matches = matches ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'matches': matches.map((m) => m.toJson()).toList(),
      };

  factory KnockoutRound.fromJson(Map<String, dynamic> json) => KnockoutRound(
        name: json['name'] as String,
        matches: (json['matches'] as List?)
                ?.map((m) => Game.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class Tournament {
  final String id;
  final DateTime createdAt;
  final List<Player> players;
  final int numberOfGroups;
  final List<TournamentGroup> groups;
  final List<KnockoutRound> knockoutRounds;
  final List<Player> finalStandings;
  final int startingScore;
  final int legsToWin;
  final CheckoutMode checkoutMode;

  Tournament({
    required this.id,
    required this.createdAt,
    required this.players,
    required this.numberOfGroups,
    List<TournamentGroup>? groups,
    List<KnockoutRound>? knockoutRounds,
    List<Player>? finalStandings,
    required this.startingScore,
    required this.legsToWin,
    required this.checkoutMode,
  })  : groups = groups ?? [],
        knockoutRounds = knockoutRounds ?? [],
        finalStandings = finalStandings ?? [];

  bool get isCompleted =>
      finalStandings.isNotEmpty ||
      (knockoutRounds.isNotEmpty &&
          knockoutRounds.last.matches.every((m) => m.isCompleted));

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
        'numberOfGroups': numberOfGroups,
        'groups': groups.map((g) => g.toJson()).toList(),
        'knockoutRounds': knockoutRounds.map((r) => r.toJson()).toList(),
        'finalStandings': finalStandings.map((p) => p.toJson()).toList(),
        'startingScore': startingScore,
        'legsToWin': legsToWin,
        'checkoutMode': checkoutMode.name,
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        numberOfGroups: json['numberOfGroups'] as int,
        groups: (json['groups'] as List?)
                ?.map((g) => TournamentGroup.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
        knockoutRounds: (json['knockoutRounds'] as List?)
                ?.map((r) => KnockoutRound.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        finalStandings: (json['finalStandings'] as List?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        startingScore: json['startingScore'] as int,
        legsToWin: json['legsToWin'] as int,
        checkoutMode: CheckoutMode.values
            .firstWhere((m) => m.name == json['checkoutMode'] as String),
      );
}
