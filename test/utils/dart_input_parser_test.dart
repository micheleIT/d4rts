import 'package:flutter_test/flutter_test.dart';
import 'package:d4rts/models/dart_throw.dart';
import 'package:d4rts/utils/dart_input_parser.dart';

void main() {
  group('DartInputParser', () {
    test('parses plain number 20 as single 20', () {
      final dart = DartInputParser.parse('20');
      expect(dart.baseValue, 20);
      expect(dart.multiplier, ThrowMultiplier.single);
      expect(dart.score, 20);
    });

    test('parses D17 as double 17 (score 34)', () {
      final dart = DartInputParser.parse('D17');
      expect(dart.baseValue, 17);
      expect(dart.multiplier, ThrowMultiplier.double_);
      expect(dart.score, 34);
    });

    test('parses T20 as triple 20 (score 60)', () {
      final dart = DartInputParser.parse('T20');
      expect(dart.baseValue, 20);
      expect(dart.multiplier, ThrowMultiplier.triple);
      expect(dart.score, 60);
    });

    test('parses 25 as single bull (score 25)', () {
      final dart = DartInputParser.parse('25');
      expect(dart.baseValue, 25);
      expect(dart.multiplier, ThrowMultiplier.single);
      expect(dart.score, 25);
    });

    test('parses D25 as double bull (score 50)', () {
      final dart = DartInputParser.parse('D25');
      expect(dart.baseValue, 25);
      expect(dart.multiplier, ThrowMultiplier.double_);
      expect(dart.score, 50);
    });

    test('T25 throws ArgumentError (triple bull invalid)', () {
      expect(() => DartInputParser.parse('T25'), throwsArgumentError);
    });

    test('21 throws ArgumentError (invalid value)', () {
      expect(() => DartInputParser.parse('21'), throwsArgumentError);
    });

    test('parses 0 as miss (score 0)', () {
      final dart = DartInputParser.parse('0');
      expect(dart.baseValue, 0);
      expect(dart.score, 0);
      expect(dart.isMiss, isTrue);
    });

    test('parses empty string as miss (score 0)', () {
      final dart = DartInputParser.parse('');
      expect(dart.baseValue, 0);
      expect(dart.score, 0);
      expect(dart.isMiss, isTrue);
    });

    test('parses lowercase d20 as double 20 (score 40)', () {
      final dart = DartInputParser.parse('d20');
      expect(dart.baseValue, 20);
      expect(dart.multiplier, ThrowMultiplier.double_);
      expect(dart.score, 40);
    });

    test('parses lowercase t20 as triple 20 (score 60)', () {
      final dart = DartInputParser.parse('t20');
      expect(dart.baseValue, 20);
      expect(dart.multiplier, ThrowMultiplier.triple);
      expect(dart.score, 60);
    });

    test('negative number throws ArgumentError', () {
      expect(() => DartInputParser.parse('-5'), throwsArgumentError);
    });

    test('invalid string throws ArgumentError', () {
      expect(() => DartInputParser.parse('abc'), throwsArgumentError);
    });

    test('parses 1 as single 1', () {
      final dart = DartInputParser.parse('1');
      expect(dart.baseValue, 1);
      expect(dart.multiplier, ThrowMultiplier.single);
      expect(dart.score, 1);
    });

    test('parses D1 as double 1 (score 2)', () {
      final dart = DartInputParser.parse('D1');
      expect(dart.score, 2);
    });

    test('isValid returns true for valid inputs', () {
      expect(DartInputParser.isValid('T20'), isTrue);
      expect(DartInputParser.isValid('D25'), isTrue);
      expect(DartInputParser.isValid('0'), isTrue);
      expect(DartInputParser.isValid(''), isTrue);
    });

    test('isValid returns false for invalid inputs', () {
      expect(DartInputParser.isValid('T25'), isFalse);
      expect(DartInputParser.isValid('21'), isFalse);
      expect(DartInputParser.isValid('abc'), isFalse);
    });
  });
}
