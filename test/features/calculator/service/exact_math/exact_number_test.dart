import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/exact_number.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/rational.dart';

void main() {
  final one = Rational.one;
  final two = Rational.fromInt(2);
  final three = Rational.fromInt(3);

  ExactNumber surd(BigInt radicand, Rational coeff) =>
      ExactNumber.fromTerms({radicand: coeff});

  group('ExactNumber construction', () {
    test('fromTerms 去除 0 係數', () {
      final n = ExactNumber.fromTerms({BigInt.one: Rational.zero, BigInt.two: one});
      expect(n.surdTerms.length, 1);
      expect(n.surdTerms.single.key, BigInt.two);
    });

    test('isZero / isRational', () {
      expect(ExactNumber.zero.isZero, isTrue);
      expect(ExactNumber.fromInt(5).isRational, isTrue);
      expect(surd(BigInt.two, one).isRational, isFalse);
      // 有理 + 根號 -> 非 rational。
      final mixed = ExactNumber.fromTerms({BigInt.one: one, BigInt.two: one});
      expect(mixed.isRational, isFalse);
    });
  });

  group('ExactNumber add/sub', () {
    test('合併相同 radicand', () {
      // 2√3 + √3 = 3√3
      final sum = surd(BigInt.from(3), two) + surd(BigInt.from(3), one);
      expect(sum, surd(BigInt.from(3), three));
    });

    test('不同 radicand 並存', () {
      // √2 + √3
      final sum = surd(BigInt.two, one) + surd(BigInt.from(3), one);
      expect(sum.surdTerms.length, 2);
    });

    test('相加為 0 時項被移除', () {
      // √2 - √2 = 0
      final result = surd(BigInt.two, one) - surd(BigInt.two, one);
      expect(result.isZero, isTrue);
    });
  });

  group('ExactNumber mul (square-free simplification)', () {
    test('√2 * √8 = 4（完全平方）', () {
      final result = surd(BigInt.two, one) * surd(BigInt.from(8), one);
      expect(result, ExactNumber.fromInt(4));
    });

    test('√2 * √3 = √6', () {
      final result = surd(BigInt.two, one) * surd(BigInt.from(3), one);
      expect(result, surd(BigInt.from(6), one));
    });

    test('2√3 * √3 = 6', () {
      final result = surd(BigInt.from(3), two) * surd(BigInt.from(3), one);
      expect(result, ExactNumber.fromInt(6));
    });

    test('(1+√2) * (1-√2) = -1（共軛相乘）', () {
      final a = ExactNumber.fromTerms({BigInt.one: one, BigInt.two: one});
      final b = ExactNumber.fromTerms({BigInt.one: one, BigInt.two: Rational.fromInt(-1)});
      expect(a * b, ExactNumber.fromInt(-1));
    });
  });

  group('ExactNumber divide (rationalization)', () {
    test('純有理分母逐項除', () {
      // (1 + √2) / 2
      final num = ExactNumber.fromTerms({BigInt.one: one, BigInt.two: one});
      final result = num.divide(ExactNumber.fromInt(2));
      expect(result, ExactNumber.fromTerms({
        BigInt.one: Rational.reduce(BigInt.one, BigInt.two),
        BigInt.two: Rational.reduce(BigInt.one, BigInt.two),
      }));
    });

    test('單根號項分母 c√d：1/√2 = √2/2', () {
      final result = ExactNumber.fromInt(1).divide(surd(BigInt.two, one));
      expect(result, surd(BigInt.two, Rational.reduce(BigInt.one, BigInt.two)));
    });

    test('兩項分母 a+b√d：1/(1+√2) = √2-1', () {
      final denom = ExactNumber.fromTerms({BigInt.one: one, BigInt.two: one});
      final result = ExactNumber.fromInt(1).divide(denom);
      // 1/(1+√2) = (√2 - 1) / ((1+√2)(√2-1)) = (√2-1)/(2-1) = √2 - 1
      expect(result, ExactNumber.fromTerms({
        BigInt.one: Rational.fromInt(-1),
        BigInt.two: Rational.one,
      }));
    });

    test('三項以上根號項分母無法有理化 -> null', () {
      final denom = ExactNumber.fromTerms({
        BigInt.one: one,
        BigInt.two: one,
        BigInt.from(3): one,
      });
      expect(ExactNumber.fromInt(1).divide(denom), isNull);
    });

    test('除以 0 -> null', () {
      expect(ExactNumber.fromInt(5).divide(ExactNumber.zero), isNull);
    });
  });

  group('ExactNumber pow', () {
    test('(1+√2)^2 = 3+2√2', () {
      final base = ExactNumber.fromTerms({BigInt.one: one, BigInt.two: one});
      final result = base.pow(2);
      expect(result, ExactNumber.fromTerms({
        BigInt.one: Rational.fromInt(3),
        BigInt.two: Rational.fromInt(2),
      }));
    });

    test('√3^4 = 9', () {
      expect(surd(BigInt.from(3), one).pow(4), ExactNumber.fromInt(9));
    });
  });

  group('sqrtOf (square-free extraction)', () {
    test('√12 = 2√3', () {
      expect(sqrtOf(BigInt.from(12)), surd(BigInt.from(3), two));
    });

    test('√18 = 3√2', () {
      expect(sqrtOf(BigInt.from(18)), surd(BigInt.two, Rational.fromInt(3)));
    });

    test('√50 = 5√2', () {
      expect(sqrtOf(BigInt.from(50)), surd(BigInt.two, Rational.fromInt(5)));
    });

    test('√72 = 6√2', () {
      expect(sqrtOf(BigInt.from(72)), surd(BigInt.two, Rational.fromInt(6)));
    });

    test('√16 = 4（完全平方 -> 純整數）', () {
      expect(sqrtOf(BigInt.from(16)), ExactNumber.fromInt(4));
    });

    test('√0 = 0', () {
      expect(sqrtOf(BigInt.zero), ExactNumber.zero);
    });

    test('負數 -> null', () {
      expect(sqrtOf(BigInt.from(-1)), isNull);
    });

    test('√48 = 4√3（驗證使用者原始範例的正確化簡）', () {
      // 注意：使用者誤寫 √12=4√3，正確為 √12=2√3；√48=4√3。
      expect(sqrtOf(BigInt.from(48)), surd(BigInt.from(3), Rational.fromInt(4)));
    });
  });

  group('sqrtOfRational', () {
    test('√(1/4) = 1/2', () {
      expect(
        sqrtOfRational(Rational.reduce(BigInt.one, BigInt.from(4))),
        ExactNumber.rational(Rational.reduce(BigInt.one, BigInt.two)),
      );
    });

    test('√(12/1) = 2√3', () {
      expect(
        sqrtOfRational(Rational.fromInt(12)),
        surd(BigInt.from(3), two),
      );
    });

    test('√(2/3) = √6/3（有理化分母）', () {
      // √(2/3) = √2/√3 = (√2·√3)/3 = √6/3
      expect(
        sqrtOfRational(Rational.reduce(BigInt.two, BigInt.from(3))),
        surd(BigInt.from(6), Rational.reduce(BigInt.one, BigInt.from(3))),
      );
    });

    test('負數 -> null', () {
      expect(sqrtOfRational(Rational.fromInt(-4)), isNull);
    });
  });

  group('toDouble (approximation)', () {
    test('2√3 ≈ 3.4641', () {
      final approx = surd(BigInt.from(3), two).toDouble();
      expect((approx - 3.46410161514).abs(), lessThan(1e-9));
    });

    test('1 + 1/2 = 1.5', () {
      expect(
        ExactNumber.rational(Rational.reduce(BigInt.from(3), BigInt.two)).toDouble(),
        1.5,
      );
    });
  });
}
