import 'package:d4rts/models/dart_throw.dart';

class DartInputParser {
  /// Parse a string like "T20", "D17", "25", "d25", "0", "" into a DartThrow.
  /// Throws [ArgumentError] on invalid input.
  static DartThrow parse(String input) {
    final trimmed = input.trim();

    // Empty or "0" → miss
    if (trimmed.isEmpty || trimmed == '0') {
      return const DartThrow(
          baseValue: 0, multiplier: ThrowMultiplier.single);
    }

    final upper = trimmed.toUpperCase();

    // Check for multiplier prefix D or T
    if (upper.length >= 2) {
      final prefix = upper[0];
      final valueStr = upper.substring(1);
      final value = int.tryParse(valueStr);

      if (prefix == 'D') {
        if (value == null) {
          throw ArgumentError('Invalid dart input: $input');
        }
        if (value < 1 || (value > 20 && value != 25)) {
          throw ArgumentError(
              'Invalid double value: $value. Must be 1-20 or 25');
        }
        return DartThrow(
            baseValue: value, multiplier: ThrowMultiplier.double_);
      }

      if (prefix == 'T') {
        if (value == null) {
          throw ArgumentError('Invalid dart input: $input');
        }
        if (value == 25) {
          throw ArgumentError('Triple bull (T25) is invalid');
        }
        if (value < 1 || value > 20) {
          throw ArgumentError(
              'Invalid triple value: $value. Must be 1-20');
        }
        return DartThrow(
            baseValue: value, multiplier: ThrowMultiplier.triple);
      }
    }

    // Plain number
    final value = int.tryParse(trimmed);
    if (value == null) {
      throw ArgumentError('Invalid dart input: $input');
    }
    if (value == 0) {
      return const DartThrow(
          baseValue: 0, multiplier: ThrowMultiplier.single);
    }
    if (value < 0 || (value > 20 && value != 25)) {
      throw ArgumentError(
          'Invalid dart value: $value. Must be 0-20 or 25');
    }
    return DartThrow(baseValue: value, multiplier: ThrowMultiplier.single);
  }

  static bool isValid(String input) {
    try {
      parse(input);
      return true;
    } catch (_) {
      return false;
    }
  }
}
