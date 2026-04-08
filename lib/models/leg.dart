import 'package:d4rts/models/turn.dart';
import 'package:d4rts/utils/constants.dart';

class Leg {
  final int startingScore;
  final CheckoutMode checkoutMode;
  final Map<String, List<Turn>> turns; // key: player name lowercase
  String? winnerName;

  Leg({
    required this.startingScore,
    required this.checkoutMode,
    Map<String, List<Turn>>? turns,
    this.winnerName,
  }) : turns = turns ?? {};

  void addTurn(String playerName, Turn turn) {
    final key = playerName.toLowerCase();
    turns.putIfAbsent(key, () => []);
    turns[key]!.add(turn);
  }

  List<Turn> getPlayerTurns(String playerName) {
    return turns[playerName.toLowerCase()] ?? [];
  }

  Map<String, dynamic> toJson() => {
        'startingScore': startingScore,
        'checkoutMode': checkoutMode.name,
        'turns': turns.map(
          (k, v) => MapEntry(k, v.map((t) => t.toJson()).toList()),
        ),
        'winnerName': winnerName,
      };

  factory Leg.fromJson(Map<String, dynamic> json) => Leg(
        startingScore: json['startingScore'] as int,
        checkoutMode: CheckoutMode.values
            .firstWhere((m) => m.name == json['checkoutMode'] as String),
        turns: (json['turns'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            (v as List)
                .map((t) => Turn.fromJson(t as Map<String, dynamic>))
                .toList(),
          ),
        ),
        winnerName: json['winnerName'] as String?,
      );
}
