import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/exact_number.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/exact_value_formatter.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/rational.dart';

void main() {
  const formatter = ExactValueFormatter();

  ExactNumber rational(int n, int d) =>
      ExactNumber.rational(Rational.reduce(BigInt.from(n), BigInt.from(d)));
  ExactNumber surd(int radicand, Rational coeff) =>
      ExactNumber.fromTerms({BigInt.from(radicand): coeff});

  group('純有理數', () {
    test('整數 -> null（純文字顯示）', () {
      expect(formatter.format(ExactNumber.fromInt(5)), isNull);
      expect(formatter.format(ExactNumber.fromInt(0)), isNull);
      expect(formatter.format(ExactNumber.fromInt(-3)), isNull);
    });

    test('真分數 1/3 -> \\frac{1}{3}', () {
      expect(formatter.format(rational(1, 3)), r'\frac{1}{3}');
    });

    test('負真分數 -1/3 -> \\frac{-1}{3}', () {
      expect(formatter.format(rational(-1, 3)), r'\frac{-1}{3}');
    });

    test('帶分數 4/3 -> 1\\frac{1}{3}', () {
      expect(formatter.format(rational(4, 3)), r'1\frac{1}{3}');
    });

    test('負帶分數 -7/3 -> -2\\frac{1}{3}', () {
      expect(formatter.format(rational(-7, 3)), r'-2\frac{1}{3}');
    });
  });

  group('純根號項', () {
    test('√3 -> \\sqrt{3}', () {
      expect(formatter.format(surd(3, Rational.one)), r'\sqrt{3}');
    });

    test('2√3 -> 2\\sqrt{3}', () {
      expect(formatter.format(surd(3, Rational.fromInt(2))), r'2\sqrt{3}');
    });

    test('-√3 -> -\\sqrt{3}（係數 -1 省略數字）', () {
      expect(formatter.format(surd(3, Rational.fromInt(-1))), r'-\sqrt{3}');
    });

    test('(1/2)√3 -> \\frac{1}{2}\\sqrt{3}', () {
      expect(
        formatter.format(surd(3, Rational.reduce(BigInt.one, BigInt.two))),
        r'\frac{1}{2}\sqrt{3}',
      );
    });
  });

  group('有理 + 根號（帶符號組合）', () {
    test('1 + √2 -> 1 + \\sqrt{2}（整數有理部份與根號並列時須保留）', () {
      final value = ExactNumber.fromTerms({
        BigInt.one: Rational.one,
        BigInt.two: Rational.one,
      });
      expect(formatter.format(value), r'1 + \sqrt{2}');
    });

    test('-1 + √2 -> -1 + \\sqrt{2}', () {
      final value = ExactNumber.fromTerms({
        BigInt.one: Rational.fromInt(-1),
        BigInt.two: Rational.one,
      });
      expect(formatter.format(value), r'-1 + \sqrt{2}');
    });

    test('1/2 + √3 -> \\frac{1}{2} + \\sqrt{3}', () {
      final value = ExactNumber.fromTerms({
        BigInt.one: Rational.reduce(BigInt.one, BigInt.two),
        BigInt.from(3): Rational.one,
      });
      expect(formatter.format(value), r'\frac{1}{2} + \sqrt{3}');
    });

    test('√2 + √3 -> \\sqrt{2} + \\sqrt{3}', () {
      final value = ExactNumber.fromTerms({
        BigInt.two: Rational.one,
        BigInt.from(3): Rational.one,
      });
      expect(formatter.format(value), r'\sqrt{2} + \sqrt{3}');
    });

    test('√2 - √3 -> \\sqrt{2} - \\sqrt{3}', () {
      final value = ExactNumber.fromTerms({
        BigInt.two: Rational.one,
        BigInt.from(3): Rational.fromInt(-1),
      });
      expect(formatter.format(value), r'\sqrt{2} - \sqrt{3}');
    });

    test('5 + 2√3 -> 5 + 2\\sqrt{3}', () {
      final value = ExactNumber.fromTerms({
        BigInt.one: Rational.fromInt(5),
        BigInt.from(3): Rational.fromInt(2),
      });
      expect(formatter.format(value), r'5 + 2\sqrt{3}');
    });

    test('-5 + 2√3 -> -5 + 2\\sqrt{3}', () {
      final value = ExactNumber.fromTerms({
        BigInt.one: Rational.fromInt(-5),
        BigInt.from(3): Rational.fromInt(2),
      });
      expect(formatter.format(value), r'-5 + 2\sqrt{3}');
    });
  });

  group('退化情況', () {
    test('0 -> null', () {
      expect(formatter.format(ExactNumber.zero), isNull);
    });
  });
}
