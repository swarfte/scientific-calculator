import 'dart:math' as math;

import 'rational.dart';

/// 根式和的表示：`c₀ + c₁·√r₁ + c₂·√r₂ + …`，其中 `rᵢ` 為大於 1 的
/// square-free 整數，`cᵢ` 為 [Rational] 係數。`r = 1` 代表純有理部份。
///
/// 此型別可精確表示中學常見的「化簡」結果，例如：
/// - `2 + 1/3` -> `{1: 7/3}`
/// - `√12` -> `{3: 2}`（即 `2√3`）
/// - `√2 + √3` -> `{2: 1, 3: 1}`
/// - `(1/2)√3` -> `{3: 1/2}`
///
/// 所有運算皆以 [BigInt] 精確進行。無法以根式精確表示時（例如有理化分母
/// 失敗、n 次根、巨大被開方數），呼叫端會回退到小數路徑。
class ExactNumber {
  ExactNumber._(this._terms);

  /// 內部儲存：radicand -> coefficient。不變量：
  /// - 所有 radicand 為 square-free（radicand 1 代表有理部份）。
  /// - 係數為 0 的項會被移除。
  /// - radicand 恆 > 0（負被開方數無實根號表示）。
  final Map<BigInt, Rational> _terms;

  /// 空的根式和（即 0）。
  static final ExactNumber zero = ExactNumber._(const {});

  /// 由 [terms] 建構；會去除 0 係數項。呼叫者需保證 radicand 為 square-free。
  factory ExactNumber.fromTerms(Map<BigInt, Rational> terms) {
    final cleaned = <BigInt, Rational>{};
    for (final entry in terms.entries) {
      if (!entry.value.isZero) {
        cleaned[entry.key] = entry.value;
      }
    }
    return ExactNumber._(cleaned);
  }

  /// 由 [Rational] 建立純有理數。
  factory ExactNumber.rational(Rational value) => ExactNumber.fromTerms({
    BigInt.one: value,
  });

  /// 由 [int] 建立純整數。
  factory ExactNumber.fromInt(int value) =>
      ExactNumber.rational(Rational.fromInt(value));

  /// 是否為 0。
  bool get isZero => _terms.isEmpty;

  /// 是否為純有理數（沒有根號項）。
  ///
  /// 空的 terms（即 0）或僅含 radicand 1 的項皆視為純有理。
  bool get isRational {
    if (_terms.isEmpty) return true;
    if (_terms.length == 1 && _terms.containsKey(BigInt.one)) return true;
    return false;
  }

  /// 取得有理部份（radicand 1 的係數），不存在則為 0。
  Rational get rationalPart => _terms[BigInt.one] ?? Rational.zero;

  /// 取得所有根號項（不含 radicand 1），依 radicand 遞增排序。
  ///
  /// 回傳不可變的 list of (radicand, coefficient)。
  List<MapEntry<BigInt, Rational>> get surdTerms {
    final result = _terms.entries
        .where((e) => e.key != BigInt.one)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return List.unmodifiable(result);
  }

  /// 是否為負（依近似值判斷）。
  bool get isNegative => toDouble().isNegative;

  /// 轉成 [double] 近似值。
  double toDouble() {
    var sum = 0.0;
    _terms.forEach((radicand, coeff) {
      if (radicand == BigInt.one) {
        sum += coeff.toDouble();
      } else {
        sum += coeff.toDouble() * _sqrtDouble(radicand);
      }
    });
    return sum;
  }

  // ---- 算術 --------------------------------------------------------------

  ExactNumber operator +(ExactNumber other) {
    final result = Map<BigInt, Rational>.from(_terms);
    for (final entry in other._terms.entries) {
      final existing = result[entry.key] ?? Rational.zero;
      final combined = existing + entry.value;
      if (combined.isZero) {
        result.remove(entry.key);
      } else {
        result[entry.key] = combined;
      }
    }
    return ExactNumber._(result);
  }

  ExactNumber operator -(ExactNumber other) => this + (-other);

  /// 取負號。
  ExactNumber operator -() {
    final result = _terms.map((key, value) => MapEntry(key, -value));
    return ExactNumber._(result);
  }

  /// 乘法。distribute 後將 `√(r1·r2)` 重新化簡為 square-free。
  ExactNumber operator *(ExactNumber other) {
    final result = <BigInt, Rational>{};
    void add(BigInt radicand, Rational coeff) {
      final existing = result[radicand] ?? Rational.zero;
      final combined = existing + coeff;
      if (combined.isZero) {
        result.remove(radicand);
      } else {
        result[radicand] = combined;
      }
    }

    for (final a in _terms.entries) {
      for (final b in other._terms.entries) {
        final productRadicand = a.key * b.key;
        final productCoeff = a.value * b.value;
        final simplified = _simplifyRadicalProduct(productRadicand);
        add(simplified.radicand, productCoeff * simplified.coefficient);
      }
    }
    return ExactNumber._(result);
  }

  /// 整數次方（反覆乘法）。`n >= 0`。
  ExactNumber pow(int n) {
    if (n < 0) {
      throw ArgumentError('ExactNumber.pow requires n >= 0');
    }
    var result = ExactNumber.fromInt(1);
    var base = this;
    var exp = n;
    while (exp > 0) {
      if (exp & 1 == 1) {
        result = result * base;
      }
      exp >>= 1;
      if (exp > 0) {
        base = base * base;
      }
    }
    return result;
  }

  /// 除法。有理化分母；可處理單項分母與兩項分母 `a + b√d`。
  /// 無法有理化時回傳 `null`（呼叫端 fallback 到小數）。
  ExactNumber? divide(ExactNumber other) {
    if (other.isZero) {
      return null; // 除以 0；交由 decimal 路徑拋 overflow/domain。
    }
    if (other.surdTerms.isEmpty) {
      // 純有理分母：直接逐項除。
      final divisor = other.rationalPart;
      final result = _terms.map(
        (key, value) => MapEntry(key, value / divisor),
      );
      return ExactNumber._(result);
    }
    if (other.surdTerms.length == 1 && other.rationalPart.isZero) {
      // 單一根號項 `c√d`：分子分母同乘 `√d`，得 `√d/d`。
      final surd = other.surdTerms.single;
      final d = surd.key;
      final coeff = surd.value;
      // new denominator = c√d · √d = c·d（有理）。
      final newRationalDenom = coeff * Rational.integer(d);
      // new numerator = this · √d。
      final sqrtD = ExactNumber._({d: Rational.integer(BigInt.one)});
      final newNumerator = this * sqrtD;
      final result = newNumerator._terms.map(
        (key, value) => MapEntry(key, value / newRationalDenom),
      );
      return ExactNumber._(result);
    }
    if (other.surdTerms.length == 1) {
      // 兩項分母 `a + b√d`：乘以共軛 `a - b√d`，分母 = `a² - b²d`。
      final d = other.surdTerms.single.key;
      final a = other.rationalPart;
      final b = other.surdTerms.single.value;
      final conjugateTerms = <BigInt, Rational>{
        BigInt.one: a,
        d: -b,
      };
      final conjugate = ExactNumber._(conjugateTerms);
      final denomRational = a * a - b * b * Rational.integer(d);
      if (denomRational.isZero) {
        return null;
      }
      final newNumerator = this * conjugate;
      final result = newNumerator._terms.map(
        (key, value) => MapEntry(key, value / denomRational),
      );
      return ExactNumber._(result);
    }
    // 三項以上根號項（如 a + b√2 + c√3）：無法簡單有理化，fallback。
    return null;
  }

  /// 取倒數（`1 / this`）。等價於 `ExactNumber.fromInt(1).divide(this)`。
  ExactNumber? reciprocal() => ExactNumber.fromInt(1).divide(this);

  @override
  bool operator ==(Object other) {
    return other is ExactNumber && _mapsEqual(_terms, other._terms);
  }

  static bool _mapsEqual(Map<BigInt, Rational> a, Map<BigInt, Rational> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _terms.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() {
    if (isZero) return '0';
    return _terms.entries.map((e) {
      if (e.key == BigInt.one) return '${e.value}';
      return '${e.value}√${e.key}';
    }).join(' + ');
  }
}

// ---- free helpers -------------------------------------------------------

/// `_RadicalProduct { radicand (square-free), coefficient }`：`√n` 化簡結果。
class _RadicalProduct {
  const _RadicalProduct(this.radicand, this.coefficient);
  final BigInt radicand;
  final Rational coefficient;
}

/// 將乘積 radicand `n = r1*r2` 化簡成 square-free radicand 與提出來的整數係數。
///
/// 例如 `n = 12 = 4·3` -> `radicand = 3, coefficient = 2`。
/// `n = 1` -> `(1, 1)`。`n` 為 0 視為 0。
_RadicalProduct _simplifyRadicalProduct(BigInt n) {
  if (n == BigInt.zero) {
    return _RadicalProduct(BigInt.one, Rational.zero);
  }
  if (n == BigInt.one) {
    return _RadicalProduct(BigInt.one, Rational.integer(BigInt.one));
  }
  final extracted = _extractSquareFactor(n);
  if (extracted.squareFree == BigInt.one) {
    // n 是完全平方 -> 純整數。
    return _RadicalProduct(
      BigInt.one,
      Rational.integer(extracted.coefficient),
    );
  }
  return _RadicalProduct(
    extracted.squareFree,
    Rational.integer(extracted.coefficient),
  );
}

class _SquareExtraction {
  const _SquareExtraction(this.coefficient, this.squareFree);
  final BigInt coefficient; // 提出 radicand 外的整數（>= 1）
  final BigInt squareFree; // 剩餘 square-free 部份（>= 1）
}

/// 對 `n` 提出最大的完全平方因數 `k²`，回傳 `(k, n / k²)`。
///
/// 對 [n] 做質因數試除：每個質數 p 計算其指數，偶數部份提出作為 p^(e/2)，
/// 奇數部份留在 squareFree 中。為避免對巨大 n 時的緩慢試除，對 `n > 1e15`
/// 直接回傳 `(1, n)`（呼叫端會 fallback 到小數）。
_SquareExtraction _extractSquareFactor(BigInt n) {
  if (n <= BigInt.one) {
    return _SquareExtraction(BigInt.one, n);
  }
  // 超過此上限不嘗試因式分解（避免卡頓）；呼叫端會 fallback 到小數。
  const maxTrial = 1000000000000000; // 1e15
  if (n > BigInt.from(maxTrial)) {
    return _SquareExtraction(BigInt.one, n);
  }

  var remaining = n;
  var coefficient = BigInt.one;
  var squareFree = BigInt.one;

  // 處理 2。
  if (remaining % BigInt.two == BigInt.zero) {
    var exp = 0;
    while (remaining % BigInt.two == BigInt.zero) {
      remaining ~/= BigInt.two;
      exp++;
    }
    coefficient *= bigIntPow(BigInt.two, exp ~/ 2);
    if (exp & 1 == 1) {
      squareFree *= BigInt.two;
    }
  }

  // 奇質數試除。
  var p = BigInt.from(3);
  while (p * p <= remaining) {
    if (remaining % p == BigInt.zero) {
      var exp = 0;
      while (remaining % p == BigInt.zero) {
        remaining ~/= p;
        exp++;
      }
      coefficient *= bigIntPow(p, exp ~/ 2);
      if (exp & 1 == 1) {
        squareFree *= p;
      }
    }
    p += BigInt.two;
  }
  // 剩下的 remaining 是大於 1 的質數（指數 1）。
  if (remaining > BigInt.one) {
    squareFree *= remaining;
  }
  return _SquareExtraction(coefficient, squareFree);
}

/// 對 [radicand] 取平方根，回傳 [ExactNumber]（可能為純有理或根式）。
///
/// - radicand < 0：回傳 `null`（實數範圍無定義）。
/// - radicand == 0：回傳 0。
/// - radicand == 1：回傳 1。
/// - 否則提出完全平方因數：`√12 = 2√3`。
///
/// 超過 `_extractSquareFactor` 上限的 radicand 會回傳未化簡的根號項
/// （仍可顯示，只是未化到最簡）；呼叫端可選擇 fallback。
ExactNumber? sqrtOf(BigInt radicand) {
  if (radicand.isNegative) {
    return null;
  }
  if (radicand == BigInt.zero) {
    return ExactNumber.zero;
  }
  final extracted = _extractSquareFactor(radicand);
  if (extracted.squareFree == BigInt.one) {
    return ExactNumber.rational(Rational.integer(extracted.coefficient));
  }
  return ExactNumber._({
    extracted.squareFree: Rational.integer(extracted.coefficient),
  });
}

/// 對一個 [Rational] 取平方根。僅當分子分母皆為完全平方或可提出 square
/// factor 時回傳精確 [ExactNumber]，否則回傳 `null`。
///
/// 例如 `sqrt(1/4) = 1/2`、`sqrt(12/1) = 2√3`、`sqrt(2/3) = √6/3`。
ExactNumber? sqrtOfRational(Rational value) {
  if (value.isNegative) {
    return null;
  }
  if (value.isZero) {
    return ExactNumber.zero;
  }
  final numSqrt = sqrtOf(value.numerator.abs());
  final denSqrt = sqrtOf(value.denominator);
  if (numSqrt == null || denSqrt == null) {
    return null;
  }
  // sqrt(num)/sqrt(den)，若有理化分母。
  final divided = numSqrt.divide(denSqrt);
  return divided;
}

/// 以 [double] 計算 [n] 的平方根（內部近似用，不外露）。
double _sqrtDouble(BigInt n) {
  // 對大整數先取近似 double 再開根，避免溢位。
  return _bigSqrtToDouble(n);
}

double _bigSqrtToDouble(BigInt n) {
  if (n < BigInt.from(1 << 52)) {
    return math.sqrt(n.toDouble());
  }
  // 對極大數，以位數縮減：先算整數平方根估計，再修正為 double。
  final approx = bigIntSqrt(n);
  final hi = (approx + BigInt.one).toDouble();
  final lo = approx.toDouble();
  return (math.sqrt(hi) + math.sqrt(lo)) / 2;
}
