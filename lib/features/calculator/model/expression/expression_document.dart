class ExpressionDocument {
  const ExpressionDocument({
    this.evaluationExpression = '',
    this.texExpression = '',
    this.openParentheses = 0,
    int? evaluationCursorOffset,
    int? texCursorOffset,
  }) : evaluationCursorOffset =
           evaluationCursorOffset ?? evaluationExpression.length,
       texCursorOffset = texCursorOffset ?? texExpression.length;

  final String evaluationExpression;
  final String texExpression;
  final int openParentheses;

  final int evaluationCursorOffset;
  final int texCursorOffset;

  bool get isEmpty {
    return evaluationExpression.trim().isEmpty;
  }

  bool get isEvaluationCursorAtStart {
    return evaluationCursorOffset <= 0;
  }

  bool get isEvaluationCursorAtEnd {
    return evaluationCursorOffset >= evaluationExpression.length;
  }

  ExpressionDocument copyWith({
    String? evaluationExpression,
    String? texExpression,
    int? openParentheses,
    int? evaluationCursorOffset,
    int? texCursorOffset,
  }) {
    final nextEvaluationExpression =
        evaluationExpression ?? this.evaluationExpression;

    final nextTexExpression = texExpression ?? this.texExpression;

    return ExpressionDocument(
      evaluationExpression: nextEvaluationExpression,
      texExpression: nextTexExpression,
      openParentheses: openParentheses ?? this.openParentheses,
      evaluationCursorOffset:
          (evaluationCursorOffset ?? this.evaluationCursorOffset).clamp(
            0,
            nextEvaluationExpression.length,
          ),
      texCursorOffset: (texCursorOffset ?? this.texCursorOffset).clamp(
        0,
        nextTexExpression.length,
      ),
    );
  }

  factory ExpressionDocument.empty() {
    return const ExpressionDocument();
  }
}
