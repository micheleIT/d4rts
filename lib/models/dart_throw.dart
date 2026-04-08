enum ThrowMultiplier { single, double_, triple }

class DartThrow {
  final int baseValue; // 0-20 or 25
  final ThrowMultiplier multiplier;

  const DartThrow({required this.baseValue, required this.multiplier});

  int get score {
    switch (multiplier) {
      case ThrowMultiplier.single:
        return baseValue;
      case ThrowMultiplier.double_:
        return baseValue * 2;
      case ThrowMultiplier.triple:
        return baseValue * 3;
    }
  }

  bool get isBull => baseValue == 25;
  bool get isDouble => multiplier == ThrowMultiplier.double_;
  bool get isTriple => multiplier == ThrowMultiplier.triple;
  bool get isMiss => baseValue == 0;

  // Triple 25 is invalid
  bool get isValid =>
      !(baseValue == 25 && multiplier == ThrowMultiplier.triple);

  String get displayString {
    if (isMiss) return '0';
    if (multiplier == ThrowMultiplier.single) return '$baseValue';
    if (multiplier == ThrowMultiplier.double_) return 'D$baseValue';
    return 'T$baseValue';
  }

  Map<String, dynamic> toJson() => {
        'baseValue': baseValue,
        'multiplier': multiplier.name,
      };

  factory DartThrow.fromJson(Map<String, dynamic> json) => DartThrow(
        baseValue: json['baseValue'] as int,
        multiplier: ThrowMultiplier.values
            .firstWhere((m) => m.name == json['multiplier'] as String),
      );
}
