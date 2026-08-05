import '../model/expression/expression_document.dart';

class ExpressionEditor {
  const ExpressionEditor();

  ExpressionDocument appendDigit(ExpressionDocument document, String digit) {
    if (!_isDigit(digit)) {
      return document;
    }

    final needsMultiplication =
        _endsWithNamedConstant(document.evaluationExpression) ||
        document.evaluationExpression.endsWith(')');

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return document.copyWith(
      evaluationExpression:
          '${document.evaluationExpression}'
          '$evaluationPrefix'
          '$digit',
      texExpression:
          '${document.texExpression}'
          '$texPrefix'
          '$digit',
    );
  }

  ExpressionDocument appendDecimalPoint(ExpressionDocument document) {
    if (_currentNumberContainsDecimal(document.evaluationExpression)) {
      return document;
    }

    final expression = document.evaluationExpression;

    final needsLeadingZero =
        expression.isEmpty ||
        _endsWithOperator(expression) ||
        expression.endsWith('(');

    final value = needsLeadingZero ? '0.' : '.';

    return document.copyWith(
      evaluationExpression: '${document.evaluationExpression}$value',
      texExpression: '${document.texExpression}$value',
    );
  }

  ExpressionDocument appendOperator(
    ExpressionDocument document, {
    required String evaluationOperator,
    required String texOperator,
  }) {
    if (document.isEmpty) {
      if (evaluationOperator == '-') {
        return document.copyWith(evaluationExpression: '-', texExpression: '-');
      }

      return document;
    }

    var evaluation = document.evaluationExpression;
    var tex = document.texExpression;

    if (evaluation.endsWith('(')) {
      if (evaluationOperator == '-') {
        return document.copyWith(
          evaluationExpression: '$evaluation-',
          texExpression: '$tex-',
        );
      }

      return document;
    }

    if (_endsWithOperator(evaluation)) {
      evaluation = evaluation.substring(0, evaluation.length - 1);

      tex = _removeLastTexOperator(tex);
    }

    return document.copyWith(
      evaluationExpression: '$evaluation$evaluationOperator',
      texExpression: '$tex$texOperator',
    );
  }

  ExpressionDocument appendOpenParenthesis(ExpressionDocument document) {
    final needsMultiplication = _endsWithValue(document.evaluationExpression);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return document.copyWith(
      evaluationExpression:
          '${document.evaluationExpression}'
          '$evaluationPrefix'
          '(',
      texExpression:
          '${document.texExpression}'
          '$texPrefix'
          r'\left(',
      openParentheses: document.openParentheses + 1,
    );
  }

  ExpressionDocument appendCloseParenthesis(ExpressionDocument document) {
    final expression = document.evaluationExpression;

    if (document.openParentheses <= 0 ||
        document.isEmpty ||
        expression.endsWith('(') ||
        _endsWithOperator(expression)) {
      return document;
    }

    return document.copyWith(
      evaluationExpression: '${document.evaluationExpression})',
      texExpression:
          '${document.texExpression}'
          r'\right)',
      openParentheses: document.openParentheses - 1,
    );
  }

  ExpressionDocument appendFunction(
    ExpressionDocument document, {
    required String evaluationName,
    required String texName,
  }) {
    final needsMultiplication = _endsWithValue(document.evaluationExpression);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return document.copyWith(
      evaluationExpression:
          '${document.evaluationExpression}'
          '$evaluationPrefix'
          '$evaluationName(',
      texExpression:
          '${document.texExpression}'
          '$texPrefix'
          '$texName'
          r'\left(',
      openParentheses: document.openParentheses + 1,
    );
  }

  ExpressionDocument appendSquare(ExpressionDocument document) {
    final expression = document.evaluationExpression;

    if (document.isEmpty ||
        expression.endsWith('(') ||
        _endsWithOperator(expression)) {
      return document;
    }

    return document.copyWith(
      evaluationExpression: '($expression)^2',
      texExpression:
          r'\left('
          '${document.texExpression}'
          r'\right)^{2}',
    );
  }

  ExpressionDocument appendPower(ExpressionDocument document) {
    final expression = document.evaluationExpression;

    if (document.isEmpty ||
        expression.endsWith('(') ||
        _endsWithOperator(expression)) {
      return document;
    }

    return document.copyWith(
      evaluationExpression: '($expression)^',
      texExpression:
          r'\left('
          '${document.texExpression}'
          r'\right)^{',
    );
  }

  ExpressionDocument appendSquareRoot(ExpressionDocument document) {
    final needsMultiplication = _endsWithValue(document.evaluationExpression);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return document.copyWith(
      evaluationExpression:
          '${document.evaluationExpression}'
          '$evaluationPrefix'
          'sqrt(',
      texExpression:
          '${document.texExpression}'
          '$texPrefix'
          r'\sqrt{\left(',
      openParentheses: document.openParentheses + 1,
    );
  }

  ExpressionDocument appendConstant(
    ExpressionDocument document, {
    required String evaluationValue,
    required String texValue,
  }) {
    final needsMultiplication = _endsWithValue(document.evaluationExpression);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return document.copyWith(
      evaluationExpression:
          '${document.evaluationExpression}'
          '$evaluationPrefix'
          '$evaluationValue',
      texExpression:
          '${document.texExpression}'
          '$texPrefix'
          '$texValue',
    );
  }

  ExpressionDocument backspace(ExpressionDocument document) {
    if (document.isEmpty) {
      return document;
    }

    final evaluation = document.evaluationExpression;

    const functionTokens = <String>[
      'sqrt(',
      'sin(',
      'cos(',
      'tan(',
      'log(',
      'ln(',
    ];

    for (final token in functionTokens) {
      if (evaluation.endsWith(token)) {
        final newEvaluation = evaluation.substring(
          0,
          evaluation.length - token.length,
        );

        return ExpressionDocument(
          evaluationExpression: newEvaluation,
          texExpression: _removeLastFunctionTex(document.texExpression),
          openParentheses: document.openParentheses > 0
              ? document.openParentheses - 1
              : 0,
        );
      }
    }

    if (evaluation.endsWith('pi')) {
      return document.copyWith(
        evaluationExpression: evaluation.substring(0, evaluation.length - 2),
        texExpression: _removeTexSuffix(document.texExpression, r'\pi'),
      );
    }

    final deletedCharacter = evaluation[evaluation.length - 1];

    var openParentheses = document.openParentheses;

    if (deletedCharacter == '(' && openParentheses > 0) {
      openParentheses--;
    } else if (deletedCharacter == ')') {
      openParentheses++;
    }

    return document.copyWith(
      evaluationExpression: evaluation.substring(0, evaluation.length - 1),
      texExpression: _removeLastTexToken(document.texExpression),
      openParentheses: openParentheses,
    );
  }

  ExpressionDocument closePendingGroups(ExpressionDocument document) {
    if (document.openParentheses == 0) {
      return _closePendingTexBraces(document);
    }

    final evaluationClosing = List<String>.filled(
      document.openParentheses,
      ')',
    ).join();

    final texBuffer = StringBuffer(document.texExpression);

    for (var index = 0; index < document.openParentheses; index++) {
      if (_hasUnclosedSquareRoot(texBuffer.toString())) {
        texBuffer.write(r'\right)}');
      } else {
        texBuffer.write(r'\right)');
      }
    }

    final completed = document.copyWith(
      evaluationExpression:
          '${document.evaluationExpression}'
          '$evaluationClosing',
      texExpression: texBuffer.toString(),
      openParentheses: 0,
    );

    return _closePendingTexBraces(completed);
  }

  ExpressionDocument _closePendingTexBraces(ExpressionDocument document) {
    var tex = document.texExpression;

    final openingBraceCount = RegExp(r'\{').allMatches(tex).length;

    final closingBraceCount = RegExp(r'\}').allMatches(tex).length;

    final missingBraceCount = openingBraceCount - closingBraceCount;

    if (missingBraceCount > 0) {
      tex += List<String>.filled(missingBraceCount, '}').join();
    }

    return document.copyWith(texExpression: tex);
  }

  bool _currentNumberContainsDecimal(String expression) {
    if (expression.isEmpty) {
      return false;
    }

    final parts = expression.split(RegExp(r'[\+\-\*\/\^\(\)]'));

    return parts.last.contains('.');
  }

  bool _endsWithOperator(String expression) {
    if (expression.isEmpty) {
      return false;
    }

    final lastCharacter = expression[expression.length - 1];

    return '+-*/^'.contains(lastCharacter);
  }

  bool _endsWithValue(String expression) {
    if (expression.isEmpty) {
      return false;
    }

    final lastCharacter = expression[expression.length - 1];

    return RegExp(r'[0-9a-zA-Z\)]').hasMatch(lastCharacter);
  }

  bool _endsWithNamedConstant(String expression) {
    return expression.endsWith('pi') || expression.endsWith('e');
  }

  bool _isDigit(String value) {
    return RegExp(r'^[0-9]$').hasMatch(value);
  }

  bool _hasUnclosedSquareRoot(String tex) {
    final squareRootCount = RegExp(r'\\sqrt\{').allMatches(tex).length;

    final squareRootCloseCount = RegExp(r'\\right\)\}').allMatches(tex).length;

    return squareRootCount > squareRootCloseCount;
  }

  String _removeLastTexOperator(String tex) {
    const operators = <String>[
      r'\times',
      r'\times ',
      r'\div',
      r'\div ',
      '+',
      '-',
    ];

    for (final operator in operators) {
      if (tex.endsWith(operator)) {
        return tex.substring(0, tex.length - operator.length);
      }
    }

    return tex;
  }

  String _removeLastFunctionTex(String tex) {
    const functionTokens = <String>[
      r'\sqrt{\left(',
      r'\sin\left(',
      r'\cos\left(',
      r'\tan\left(',
      r'\log\left(',
      r'\ln\left(',
    ];

    for (final token in functionTokens) {
      if (tex.endsWith(token)) {
        return tex.substring(0, tex.length - token.length);
      }
    }

    return tex;
  }

  String _removeLastTexToken(String tex) {
    const texTokens = <String>[
      r'\right)}',
      r'\right)',
      r'\left(',
      r'\times ',
      r'\times',
      r'\div ',
      r'\div',
      r'\pi',
    ];

    for (final token in texTokens) {
      if (tex.endsWith(token)) {
        return tex.substring(0, tex.length - token.length);
      }
    }

    if (tex.isEmpty) {
      return tex;
    }

    return tex.substring(0, tex.length - 1);
  }

  String _removeTexSuffix(String tex, String suffix) {
    if (!tex.endsWith(suffix)) {
      return tex;
    }

    return tex.substring(0, tex.length - suffix.length);
  }
}
