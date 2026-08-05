enum CalculatorErrorType {
  emptyExpression,
  invalidExpression,
  divisionByZero,
  domainError,
  nonFiniteResult,
  unknown,
}

class CalculatorException implements Exception {
  const CalculatorException(
    this.message, {
    this.type = CalculatorErrorType.unknown,
  });

  final String message;
  final CalculatorErrorType type;

  @override
  String toString() => message;
}
