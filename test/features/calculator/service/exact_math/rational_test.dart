import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/rational.dart';

void main() {
  group('Rational construction', () {
    test('reduce 化為最簡並保證分母為正', () {
      final r = Rational.reduce(BigInt.from(6), BigInt.from(8));
      expect(r.numerator, BigInt.from(3));
      expect(r.denominator, BigInt.from(4));

      // 負分母移到分子。
      final neg = Rational.reduce(BigInt.from(6), BigInt.from(-8));
      expect(neg.numerator, BigInt.from(-3));
      expect(neg.denominator, BigInt.from(4));

      // 分子為 0 規範化為 0/1。
      final zero = Rational.reduce(BigInt.zero, BigInt.from(5));
      expect(zero.numerator, BigInt.zero);
      expect(zero.denominator, BigInt.one);
    });

    test('零分母拋 FormatException', () {
      expect(
        () => Rational(BigInt.one, BigInt.zero),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Rational.reduce(BigInt.one, BigInt.zero),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Rational.fromDecimalString', () {
    test('整數', () {
      expect(Rational.fromDecimalString('2'), Rational.fromInt(2));
      expect(Rational.fromDecimalString('0'), Rational.zero);
      expect(Rational.fromDecimalString('-7'), Rational.fromInt(-7));
      expect(Rational.fromDecimalString('+5'), Rational.fromInt(5));
    });

    test('小數精確化簡', () {
      expect(Rational.fromDecimalString('2.5'), Rational.reduce(BigInt.from(5), BigInt.two));
      expect(Rational.fromDecimalString('0.5'), Rational.reduce(BigInt.one, BigInt.two));
      expect(Rational.fromDecimalString('3.14'), Rational.reduce(BigInt.from(157), BigInt.from(50)));
      expect(Rational.fromDecimalString('1.25'), Rational.reduce(BigInt.from(5), BigInt.from(4)));
      expect(Rational.fromDecimalString('-1.5'), Rational.reduce(BigInt.from(-3), BigInt.two));
    });

    test('尾端零縮小分母', () {
      // 2.50 -> 5/2（而非 250/100）。
      expect(Rational.fromDecimalString('2.50'), Rational.reduce(BigInt.from(5), BigInt.two));
      expect(Rational.fromDecimalString('1.500'), Rational.reduce(BigInt.from(3), BigInt.two));
    });

    test('前導零與無整數部份', () {
      expect(Rational.fromDecimalString('.5'), Rational.reduce(BigInt.one, BigInt.two));
      expect(Rational.fromDecimalString('0.25'), Rational.reduce(BigInt.one, BigInt.from(4)));
    });

    test('非法輸入拋 FormatException', () {
      expect(() => Rational.fromDecimalString(''), throwsA(isA<FormatException>()));
      expect(() => Rational.fromDecimalString('.'), throwsA(isA<FormatException>()));
      expect(() => Rational.fromDecimalString('abc'), throwsA(isA<FormatException>()));
    });
  });

  group('Rational arithmetic', () {
    final oneThird = Rational.reduce(BigInt.one, BigInt.from(3));
    final twoThirds = Rational.reduce(BigInt.two, BigInt.from(3));

    test('加法', () {
      expect(oneThird + twoThirds, Rational.one);
      expect(Rational.fromInt(2) + Rational.fromInt(3), Rational.fromInt(5));
    });

    test('減法', () {
      expect(Rational.one - oneThird, twoThirds);
      expect(twoThirds - oneThird, oneThird);
    });

    test('乘法', () {
      expect(oneThird * Rational.fromInt(3), Rational.one);
      expect(twoThirds * twoThirds, Rational.reduce(BigInt.from(4), BigInt.from(9)));
    });

    test('除法', () {
      expect(Rational.fromInt(6) / Rational.fromInt(4), Rational.reduce(BigInt.from(3), BigInt.two));
      expect(Rational.one / oneThird, Rational.fromInt(3));
    });

    test('倒數與負號', () {
      expect(Rational.fromInt(4).reciprocal(), Rational.reduce(BigInt.one, BigInt.from(4)));
      expect(-oneThird, Rational.reduce(BigInt.from(-1), BigInt.from(3)));
    });

    test('零的倒數拋例外', () {
      expect(() => Rational.zero.reciprocal(), throwsA(isA<FormatException>()));
    });
  });

  group('Rational helpers', () {
    test('truncateToBigInt 與 fractionalPartAbs（帶分數用）', () {
      final sevenThirds = Rational.reduce(BigInt.from(7), BigInt.from(3));
      expect(sevenThirds.truncateToBigInt(), BigInt.two);
      expect(sevenThirds.fractionalPartAbs(), oneThird);

      final negSevenThirds = Rational.reduce(BigInt.from(-7), BigInt.from(3));
      expect(negSevenThirds.truncateToBigInt(), BigInt.from(-2));
      expect(negSevenThirds.fractionalPartAbs(), oneThird);
    });

    test('comparisons', () {
      expect(Rational.fromInt(2) > Rational.fromInt(1), isTrue);
      expect(oneThird < Rational.fromInt(1), isTrue);
      expect(Rational.fromInt(3) <= Rational.fromInt(3), isTrue);
      expect(Rational.fromInt(3) >= Rational.fromInt(3), isTrue);
    });

    test('isInteger / isZero / isNegative', () {
      expect(Rational.fromInt(5).isInteger, isTrue);
      expect(oneThird.isInteger, isFalse);
      expect(Rational.zero.isZero, isTrue);
      expect(Rational.fromInt(-5).isNegative, isTrue);
      expect(oneThird.isNegative, isFalse);
    });
  });

  group('BigInt helpers', () {
    test('bigIntSqrt', () {
      expect(bigIntSqrt(BigInt.from(0)), BigInt.zero);
      expect(bigIntSqrt(BigInt.from(1)), BigInt.one);
      expect(bigIntSqrt(BigInt.from(12)), BigInt.from(3));
      expect(bigIntSqrt(BigInt.from(16)), BigInt.from(4));
      expect(bigIntSqrt(BigInt.from(15)), BigInt.from(3));
      expect(bigIntSqrt(BigInt.from(1000000)), BigInt.from(1000));
    });

    test('isPerfectSquare', () {
      expect(isPerfectSquare(BigInt.from(16)), isTrue);
      expect(isPerfectSquare(BigInt.from(15)), isFalse);
      expect(isPerfectSquare(BigInt.from(0)), isTrue);
      expect(isPerfectSquare(BigInt.from(-4)), isFalse);
    });

    test('bigIntPow', () {
      expect(bigIntPow(BigInt.from(2), 10), BigInt.from(1024));
      expect(bigIntPow(BigInt.from(3), 4), BigInt.from(81));
      expect(bigIntPow(BigInt.from(5), 0), BigInt.one);
    });
  });
}

final Rational oneThird = Rational.reduce(BigInt.one, BigInt.from(3));
