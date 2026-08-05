class ExpressionDocument {
  const ExpressionDocument({
    this.evaluationExpression = '',
    this.texExpression = '',
    this.openParentheses = 0,
  });

  final String evaluationExpression;
  final String texExpression;
  final int openParentheses;

  bool get isEmpty => evaluationExpression.trim().isEmpty;

  ExpressionDocument copyWith({
    String? evaluationExpression,
    String? texExpression,
    int? openParentheses,
  }) {
    return ExpressionDocument(
      evaluationExpression: evaluationExpression ?? this.evaluationExpression,
      texExpression: texExpression ?? this.texExpression,
      openParentheses: openParentheses ?? this.openParentheses,
    );
  }

  factory ExpressionDocument.empty() {
    return const ExpressionDocument();
  }
}
