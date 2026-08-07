import 'dart:math' as math;

/// 精確分數：以 [BigInt] 表示的分子／分母，永遠化為最簡且分母為正。
///
/// 這個型別是 exact（symbolic）計算路徑的基礎，用來產生「中學生作業」要求的
/// 最簡分數／帶分數／根式結果。所有算術都在整數範圍內進行，不會累積浮點誤差。
///
/// 不變量（由工廠與 operators 共同維護）：
/// - [denominator] > 0
/// - gcd(|[numerator]|, [denominator]) == 1，或 [numerator] == 0 時
///   [denominator] == 1。
class Rational implements Comparable<Rational> {
  Rational(this.numerator, this.denominator) {
    if (denominator == BigInt.zero) {
      throw const FormatException('Rational denominator cannot be zero.');
    }
  }

  /// 由已經最簡的成員直接構造（不再次化簡）。內部使用。
  const Rational._raw(this.numerator, this.denominator);

  /// 整數。
  Rational.integer(BigInt value) : this._raw(value, BigInt.one);

  static final Rational zero = Rational.integer(BigInt.zero);
  static final Rational one = Rational.integer(BigInt.one);

  final BigInt numerator;
  final BigInt denominator;

  /// 是否為 0。
  bool get isZero => numerator == BigInt.zero;

  /// 是否為整數（分母為 1）。
  bool get isInteger => denominator == BigInt.one;

  /// 正負號：-1 / 0 / 1。
  int get sign => numerator.sign;

  /// 轉成 [double] 近似值（僅用於 fallback 顯示或比較）。
  double toDouble() => numerator.toDouble() / denominator.toDouble();

  /// 化為最簡並保證分母為正。
  factory Rational.reduce(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw const FormatException('Rational denominator cannot be zero.');
    }
    if (numerator == BigInt.zero) {
      return Rational._raw(BigInt.zero, BigInt.one);
    }
    var n = numerator;
    var d = denominator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final divisor = n.abs().gcd(d);
    if (divisor != BigInt.one) {
      n = n ~/ divisor;
      d = d ~/ divisor;
    }
    return Rational._raw(n, d);
  }

  /// 由 [int] 建立。
  factory Rational.fromInt(int value) =>
      Rational._raw(BigInt.from(value), BigInt.one);

  /// 解析十進位字串（如 `"2"`、`"3.14"`、`"0.5"`、`"-1.25"`）為精確分數。
  ///
  /// 不處理科學記號（`1e3`）——`NumberNode` 來自使用者逐位輸入，不會出現。
  /// 無法解析時拋 [FormatException]。
  factory Rational.fromDecimalString(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      throw const FormatException('Empty rational input.');
    }
    var negative = false;
    var body = text;
    if (body.startsWith('-')) {
      negative = true;
      body = body.substring(1);
    } else if (body.startsWith('+')) {
      body = body.substring(1);
    }
    if (body.isEmpty || body == '.') {
      throw FormatException('Invalid rational input: "$input".');
    }
    final dotIndex = body.indexOf('.');
    if (dotIndex < 0) {
      // 純整數。
      final value = BigInt.parse(body);
      return Rational.reduce(negative ? -value : value, BigInt.one);
    }
    final intPart = dotIndex == 0 ? '0' : body.substring(0, dotIndex);
    final fracPart = body.substring(dotIndex + 1);
    if (intPart.isEmpty && fracPart.isEmpty) {
      throw FormatException('Invalid rational input: "$input".');
    }
    // 去掉尾端零以縮小分母，但空白小數部分視為 0。
    final fracDigits = fracPart.isEmpty ? '' : fracPart.replaceFirst(
      RegExp(r'0+$'),
      '',
    );
    final intMagnitude = BigInt.parse(intPart.isEmpty ? '0' : intPart);
    if (fracDigits.isEmpty) {
      final value = intMagnitude;
      return Rational.reduce(negative ? -value : value, BigInt.one);
    }
    final fracValue = BigInt.parse(fracDigits);
    final denominator = BigInt.from(10).pow(fracDigits.length);
    final combined = intMagnitude * denominator + fracValue;
    return Rational.reduce(
      negative ? -combined : combined,
      denominator,
    );
  }

  // ---- 算術 --------------------------------------------------------------

  Rational operator +(Rational other) => Rational.reduce(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator -(Rational other) => Rational.reduce(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator *(Rational other) =>
      Rational.reduce(numerator * other.numerator, denominator * other.denominator);

  Rational operator /(Rational other) => Rational.reduce(
    numerator * other.denominator,
    denominator * other.numerator,
  );

  /// 取負號。
  Rational operator -() => Rational._raw(-numerator, denominator);

  /// 倒數（1 / this）。this 為 0 時拋 [FormatException]。
  Rational reciprocal() {
    if (isZero) {
      throw const FormatException('Cannot take reciprocal of zero.');
    }
    // reduce 會處理分母為負的情況。
    return Rational.reduce(denominator, numerator);
  }

  Rational abs() => isNegative ? -this : this;

  bool get isNegative => numerator.isNegative;

  @override
  int compareTo(Rational other) {
    // 分母為正，比較交叉相乘的結果。
    final left = numerator * other.denominator;
    final right = other.numerator * denominator;
    return left.compareTo(right);
  }

  bool operator <(Rational other) => compareTo(other) < 0;
  bool operator <=(Rational other) => compareTo(other) <= 0;
  bool operator >(Rational other) => compareTo(other) > 0;
  bool operator >=(Rational other) => compareTo(other) >= 0;

  /// 取整數部份（向零截斷），例如 `7/3 -> 2`、`-7/3 -> -2`。
  BigInt truncateToBigInt() => numerator ~/ denominator;

  /// 取分數部份的絕對值（永遠 >= 0 且 < 1），例如 `7/3 -> 1/3`、
  /// `-7/3 -> 1/3`。
  Rational fractionalPartAbs() {
    final truncated = truncateToBigInt();
    return Rational.reduce(
      (numerator - truncated * denominator).abs(),
      denominator,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Rational &&
        numerator == other.numerator &&
        denominator == other.denominator;
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}

/// 對 [BigInt] 取整數平方根（無條件進位捨棄小數部份）。
///
/// 例如 `bigIntSqrt(BigInt.from(12)) == BigInt.from(3)`、
/// `bigIntSqrt(BigInt.from(16)) == BigInt.from(4)`。
BigInt bigIntSqrt(BigInt n) {
  if (n < BigInt.zero) {
    throw ArgumentError('square root of negative number');
  }
  if (n < BigInt.two) {
    return n;
  }
  // 牛頓法（整數版），收斂快速且穩定。
  var x = n;
  var y = (x + BigInt.one) ~/ BigInt.two;
  while (y < x) {
    x = y;
    y = (x + n ~/ x) ~/ BigInt.two;
  }
  return x;
}

/// 判斷 [n] 是否為完全平方數。
bool isPerfectSquare(BigInt n) {
  if (n < BigInt.zero) return false;
  final root = bigIntSqrt(n);
  return root * root == n;
}

/// 計算 [a] 的非負整數次方 [n]；`n < 0` 時拋 [ArgumentError]。
BigInt bigIntPow(BigInt a, int n) {
  if (n < 0) {
    throw ArgumentError('bigIntPow does not support negative exponents');
  }
  var result = BigInt.one;
  var base = a;
  var exp = n;
  while (exp > 0) {
    if (exp & 1 == 1) {
      result *= base;
    }
    exp >>= 1;
    if (exp > 0) {
      base *= base;
    }
  }
  return result;
}

/// 整數 [n] 的整數立方根（向零截斷）。僅供 `ExactValueEvaluator` 判斷
/// `³√x` 是否為整數時偶爾需要的近似檢查使用。
BigInt bigIntCbrt(BigInt n) {
  if (n == BigInt.zero) return BigInt.zero;
  final negative = n.isNegative;
  final abs = n.abs();
  // 以 double 估計後再用牛頓法修正。
  var x = BigInt.from(math.pow(abs.toDouble(), 1.0 / 3.0).ceil());
  if (x == BigInt.zero) x = BigInt.one;
  // 單調收敛：找到最大的 x 使 x^3 <= abs。
  while (bigIntPow(x, 3) > abs) {
    x -= BigInt.one;
  }
  while (bigIntPow(x + BigInt.one, 3) <= abs) {
    x += BigInt.one;
  }
  return negative ? -x : x;
}
