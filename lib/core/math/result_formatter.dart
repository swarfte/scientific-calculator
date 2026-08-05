abstract final class ResultFormatter {
  static String format(num value) {
    final doubleValue = value.toDouble();

    if (doubleValue.isNaN) {
      return 'Undefined';
    }

    if (doubleValue.isInfinite) {
      return doubleValue.isNegative ? '-Infinity' : 'Infinity';
    }

    if (doubleValue == 0) {
      return '0';
    }

    final absoluteValue = doubleValue.abs();

    if (absoluteValue >= 1e12 || absoluteValue < 1e-9) {
      return _cleanScientificNotation(doubleValue.toStringAsExponential(10));
    }

    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.toInt().toString();
    }

    var result = doubleValue.toStringAsPrecision(12);

    if (!result.contains('e')) {
      result = result.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    return result;
  }

  static String _cleanScientificNotation(String value) {
    final parts = value.split('e');

    var coefficient = parts.first;
    final exponent = parts.last;

    coefficient = coefficient.replaceFirst(RegExp(r'\.?0+$'), '');

    return '${coefficient}e$exponent';
  }
}
