import 'package:d4rts/models/leg.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/utils/constants.dart';

class Game {
  final String id;
  final DateTime startedAt;
  final List<Player> players;
  final int startingScore;
  final Map<String, int> handicaps; // player name lowercase -> handicap points
  final int legsToWin;
  final CheckoutMode checkoutMode;
  final List<Leg> legs;
  String? winnerName;
  DateTime? completedAt;

  Game({
    required this.id,
    required this.startedAt,
    required this.players,
    required this.startingScore,
    Map<String, int>? handicaps,
    required this.legsToWin,
    required this.checkoutMode,
    List<Leg>? legs,
    this.winnerName,
    this.completedAt,
  })  : handicaps = handicaps ?? {},
        legs = legs ?? [];

  bool get isCompleted => winnerName != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
        'startingScore': startingScore,
        'handicaps': handicaps,
        'legsToWin': legsToWin,
        'checkoutMode': checkoutMode.name,
        'legs': legs.map((l) => l.toJson()).toList(),
        'winnerName': winnerName,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        startingScore: json['startingScore'] as int,
        handicaps: (json['handicaps'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        legsToWin: json['legsToWin'] as int,
        checkoutMode: CheckoutMode.values
            .firstWhere((m) => m.name == json['checkoutMode'] as String),
        legs: (json['legs'] as List?)
                ?.map((l) => Leg.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        winnerName: json['winnerName'] as String?,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
