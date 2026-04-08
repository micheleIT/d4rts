import 'package:d4rts/models/dart_throw.dart';

class Turn {
  final List<DartThrow> darts;
  final bool isBust;

  const Turn({required this.darts, this.isBust = false});

  int get totalScore => darts.fold(0, (s, d) => s + d.score);

  Map<String, dynamic> toJson() => {
        'darts': darts.map((d) => d.toJson()).toList(),
        'isBust': isBust,
      };

  factory Turn.fromJson(Map<String, dynamic> json) => Turn(
        darts: (json['darts'] as List)
            .map((d) => DartThrow.fromJson(d as Map<String, dynamic>))
            .toList(),
        isBust: json['isBust'] as bool? ?? false,
      );
}
