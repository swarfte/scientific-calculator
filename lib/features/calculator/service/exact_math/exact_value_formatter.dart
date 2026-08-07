import 'exact_number.dart';
import 'rational.dart';

/// 將 [ExactNumber] 轉成 `flutter_math_fork` 可渲染的 TeX 字串。
///
/// 規則（符合中學化作業要求）：
/// - 純整數結果 -> 回傳 `null`（讓 UI 顯示純文字，避免不必要的 TeX）。
/// - 純分數（分子絕對值 < 分母）-> `\frac{n}{d}`。
/// - 帶分數 -> `w\frac{n}{d}`（整數部份 + 真分數，正負號跟隨整數部份）。
/// - 根號項 -> `c\sqrt{r}`，`c` 為 1 時省略係數、為 -1 時只留負號；
///   `c` 為分數時寫成 `\frac{n}{d}\sqrt{r}`。
/// - 多項組合：有理部份在前，根號項以 `+` / `-` 串接。
///
/// 任何情況下若結果會退化為純整數（如 `2 + 0√3`），回傳 `null`。
class ExactValueFormatter {
  const ExactValueFormatter();

  /// 將 [value] 格式化為 TeX；若適合以純文字顯示則回傳 `null`。
  String? format(ExactNumber value) {
    if (value.isZero) {
      return null; // 0 以純文字顯示。
    }

    final surds = value.surdTerms;
    final rational = value.rationalPart;

    // 純有理數：整數 -> null（純文字）；分數/帶分數 -> TeX。
    if (surds.isEmpty) {
      return _pureRationalToTex(rational);
    }

    // 有理部份 + 根號項：整數部份此時必須顯示（例如 1 + √2）。
    final parts = <String>[];
    if (!rational.isZero) {
      parts.add(_rationalPartToTex(rational));
    }

    for (final surd in surds) {
      final term = _surdToTex(surd.key, surd.value, isFirst: parts.isEmpty);
      if (term != null) {
        parts.add(term);
      }
    }

    if (parts.isEmpty) {
      return null;
    }
    return parts.join();
  }

  /// 純有理結果的 TeX。整數回傳 `null`（由純文字顯示）；否則分數／帶分數。
  String? _pureRationalToTex(Rational rational) {
    if (rational.isInteger) {
      return null;
    }
    return _fractionBody(rational);
  }

  /// 在「有理 + 根號」組合中的有理部份 TeX。整數部份以純數字呈現（不省略），
  /// 分數／帶分數則以 `\frac` / `w\frac` 呈現。
  String _rationalPartToTex(Rational rational) {
    if (rational.isInteger) {
      return '${rational.numerator}';
    }
    return _fractionBody(rational);
  }

  /// 共用的分數／帶分數 TeX 主體（不含正負號判斷，由 [_fractionBody] 處理）。
  String _fractionBody(Rational rational) {
    final isNegative = rational.isNegative;
    final absRational = rational.abs();
    final absTruncated = absRational.truncateToBigInt();
    final frac = absRational.fractionalPartAbs();

    if (absTruncated == BigInt.zero) {
      // 真分數（|n| < d），例如 1/3、-1/3。
      final numerator = isNegative ? -frac.numerator : frac.numerator;
      return '\\frac{$numerator}{${frac.denominator}}';
    }
    // 帶分數：w + n/d，整數部份帶正負號。
    final signedWhole = isNegative ? -absTruncated : absTruncated;
    return '$signedWhole\\frac{${frac.numerator}}{${frac.denominator}}';
  }

  /// 將單一根號項 `coeff · √radicand` 轉成 TeX，含與前一項的銜接符號。
  ///
  /// [isFirst] 為 `true` 時，第一個項若是負數須前置負號。
  String? _surdToTex(BigInt radicand, Rational coeff, {required bool isFirst}) {
    final isNegative = coeff.isNegative;
    final absCoeff = coeff.abs();
    final sign = isNegative ? '-' : '+';

    final coefficientTex = _coefficientTex(absCoeff);
    final body = '$coefficientTex\\sqrt{$radicand}';

    if (isFirst) {
      // 首項：正號省略，負號保留。
      return isNegative ? '-$body' : body;
    }
    return ' $sign $body';
  }

  /// 係數部份的 TeX：
  /// - 1 -> 空字串（`\sqrt{3}` 而非 `1\sqrt{3}`）
  /// - 整數 -> 純數字
  /// - 分數 -> `\frac{n}{d}`
  String _coefficientTex(Rational coeff) {
    if (coeff == Rational.one) {
      return '';
    }
    if (coeff.isInteger) {
      return '${coeff.numerator}';
    }
    return '\\frac{${coeff.numerator}}{${coeff.denominator}}';
  }
}
