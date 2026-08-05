import '../model/expression/expression_document.dart';

class ExpressionEditor {
  const ExpressionEditor();

  ExpressionDocument appendDigit(ExpressionDocument document, String digit) {
    if (!RegExp(r'^[0-9]$').hasMatch(digit)) {
      return document;
    }

    final previousCharacter = _evaluationCharacterBeforeCursor(document);

    final needsMultiplication =
        previousCharacter == ')' || _namedConstantEndsAtCursor(document);

    final evaluationText = '${needsMultiplication ? '*' : ''}$digit';

    final texText = '${needsMultiplication ? r'\times ' : ''}$digit';

    return _insertAtCursor(
      document,
      evaluationText: evaluationText,
      texText: texText,
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

  ExpressionDocument _insertAtCursor(
    ExpressionDocument document, {
    required String evaluationText,
    required String texText,
    int? evaluationCursorAdvance,
    int? texCursorAdvance,
    int openParenthesesDelta = 0,
  }) {
    final evaluationOffset = document.evaluationCursorOffset;

    final texOffset = document.texCursorOffset;

    final nextEvaluation = document.evaluationExpression.replaceRange(
      evaluationOffset,
      evaluationOffset,
      evaluationText,
    );

    final nextTex = document.texExpression.replaceRange(
      texOffset,
      texOffset,
      texText,
    );

    return document.copyWith(
      evaluationExpression: nextEvaluation,
      texExpression: nextTex,
      evaluationCursorOffset:
          evaluationOffset + (evaluationCursorAdvance ?? evaluationText.length),
      texCursorOffset: texOffset + (texCursorAdvance ?? texText.length),
      openParentheses: document.openParentheses + openParenthesesDelta,
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
    final needsMultiplication = _cursorFollowsValue(document);

    return _insertAtCursor(
      document,
      evaluationText: '${needsMultiplication ? '*' : ''}(',
      texText:
          '${needsMultiplication ? r'\times ' : ''}'
          r'\left(',
      openParenthesesDelta: 1,
    );
  }

  ExpressionDocument appendCloseParenthesis(ExpressionDocument document) {
    if (document.openParentheses <= 0) {
      return document;
    }

    final previousCharacter = _evaluationCharacterBeforeCursor(document);

    if (previousCharacter == null ||
        previousCharacter == '(' ||
        '+-*/^'.contains(previousCharacter)) {
      return document;
    }

    return _insertAtCursor(
      document,
      evaluationText: ')',
      texText: r'\right)',
      openParenthesesDelta: -1,
    );
  }

  ExpressionDocument moveCursorLeft(ExpressionDocument document) {
    if (document.evaluationCursorOffset <= 0 || document.texCursorOffset <= 0) {
      return document;
    }

    final evaluationStep = _previousEvaluationTokenLength(document);

    final texStep = _previousTexTokenLength(document);

    return document.copyWith(
      evaluationCursorOffset: document.evaluationCursorOffset - evaluationStep,
      texCursorOffset: document.texCursorOffset - texStep,
    );
  }

  ExpressionDocument moveCursorRight(ExpressionDocument document) {
    if (document.evaluationCursorOffset >=
            document.evaluationExpression.length ||
        document.texCursorOffset >= document.texExpression.length) {
      return document;
    }

    final evaluationStep = _nextEvaluationTokenLength(document);

    final texStep = _nextTexTokenLength(document);

    return document.copyWith(
      evaluationCursorOffset: document.evaluationCursorOffset + evaluationStep,
      texCursorOffset: document.texCursorOffset + texStep,
    );
  }

  int _previousEvaluationTokenLength(ExpressionDocument document) {
    final before = document.evaluationExpression.substring(
      0,
      document.evaluationCursorOffset,
    );

    const tokens = <String>[
      'sqrt(',
      'sin(',
      'cos(',
      'tan(',
      'log(',
      'ln(',
      'pi',
    ];

    for (final token in tokens) {
      if (before.endsWith(token)) {
        return token.length;
      }
    }

    return 1;
  }

  int _nextEvaluationTokenLength(ExpressionDocument document) {
    final after = document.evaluationExpression.substring(
      document.evaluationCursorOffset,
    );

    const tokens = <String>[
      'sqrt(',
      'sin(',
      'cos(',
      'tan(',
      'log(',
      'ln(',
      'pi',
    ];

    for (final token in tokens) {
      if (after.startsWith(token)) {
        return token.length;
      }
    }

    return 1;
  }

  int _previousTexTokenLength(ExpressionDocument document) {
    final before = document.texExpression.substring(
      0,
      document.texCursorOffset,
    );

    const tokens = <String>[
      r'\log_{10}\left(',
      r'\sin\left(',
      r'\cos\left(',
      r'\tan\left(',
      r'\ln\left(',
      r'\sqrt{',
      r'\times ',
      r'\div ',
      r'\left(',
      r'\right)',
      r'\pi',
    ];

    for (final token in tokens) {
      if (before.endsWith(token)) {
        return token.length;
      }
    }

    return 1;
  }

  int _nextTexTokenLength(ExpressionDocument document) {
    final after = document.texExpression.substring(document.texCursorOffset);

    const tokens = <String>[
      r'\log_{10}\left(',
      r'\sin\left(',
      r'\cos\left(',
      r'\tan\left(',
      r'\ln\left(',
      r'\sqrt{',
      r'\times ',
      r'\div ',
      r'\left(',
      r'\right)',
      r'\pi',
    ];

    for (final token in tokens) {
      if (after.startsWith(token)) {
        return token.length;
      }
    }

    return 1;
  }

  String? _evaluationCharacterBeforeCursor(ExpressionDocument document) {
    if (document.evaluationCursorOffset <= 0) {
      return null;
    }

    return document.evaluationExpression[document.evaluationCursorOffset - 1];
  }

  bool _cursorFollowsValue(ExpressionDocument document) {
    final previous = _evaluationCharacterBeforeCursor(document);

    if (previous == null) {
      return false;
    }

    return RegExp(r'[0-9a-zA-Z\)]').hasMatch(previous);
  }

  bool _namedConstantEndsAtCursor(ExpressionDocument document) {
    final before = document.evaluationExpression.substring(
      0,
      document.evaluationCursorOffset,
    );

    return before.endsWith('pi') || before.endsWith('e');
  }

  ExpressionDocument appendFunction(
    ExpressionDocument document, {
    required String evaluationName,
    required String texName,
  }) {
    final needsMultiplication = _cursorFollowsValue(document);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    final evaluationText = '$evaluationPrefix$evaluationName(';

    final texText =
        '$texPrefix$texName'
        r'\left(';

    return _insertAtCursor(
      document,
      evaluationText: evaluationText,
      texText: texText,
      openParenthesesDelta: 1,
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
    final needsMultiplication = _cursorFollowsValue(document);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return _insertAtCursor(
      document,
      evaluationText: '${evaluationPrefix}sqrt(',
      texText:
          '$texPrefix'
          r'\sqrt{',
      openParenthesesDelta: 1,
    );
  }

  ExpressionDocument appendConstant(
    ExpressionDocument document, {
    required String evaluationValue,
    required String texValue,
  }) {
    final needsMultiplication = _cursorFollowsValue(document);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return _insertAtCursor(
      document,
      evaluationText: '$evaluationPrefix$evaluationValue',
      texText: '$texPrefix$texValue',
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
    var evaluation = document.evaluationExpression;

    var tex = document.texExpression;

    if (document.openParentheses > 0) {
      evaluation += List<String>.filled(document.openParentheses, ')').join();

      for (var index = 0; index < document.openParentheses; index++) {
        if (_hasUnclosedSquareRoot(tex)) {
          tex += '}';
        } else {
          tex += r'\right)';
        }
      }
    }

    final openingBraceCount = RegExp(r'\{').allMatches(tex).length;

    final closingBraceCount = RegExp(r'\}').allMatches(tex).length;

    if (openingBraceCount > closingBraceCount) {
      tex += List<String>.filled(
        openingBraceCount - closingBraceCount,
        '}',
      ).join();
    }

    return document.copyWith(
      evaluationExpression: evaluation,
      texExpression: tex,
      openParentheses: 0,
    );
  }

  ExpressionDocument appendFraction(
    ExpressionDocument document, {
    required ExpressionDocument numerator,
    required ExpressionDocument denominator,
  }) {
    if (numerator.isEmpty || denominator.isEmpty) {
      return document;
    }

    final completedNumerator = closePendingGroups(numerator);

    final completedDenominator = closePendingGroups(denominator);

    final needsMultiplication = _endsWithValue(document.evaluationExpression);

    final evaluationPrefix = needsMultiplication ? '*' : '';

    final texPrefix = needsMultiplication ? r'\times ' : '';

    return document.copyWith(
      evaluationExpression:
          '${document.evaluationExpression}'
          '$evaluationPrefix'
          '(('
          '${completedNumerator.evaluationExpression}'
          ')/('
          '${completedDenominator.evaluationExpression}'
          '))',
      texExpression:
          '${document.texExpression}'
          '$texPrefix'
          r'\frac{'
          '${completedNumerator.texExpression}'
          r'}{'
          '${completedDenominator.texExpression}'
          r'}',
    );
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

  bool _hasUnclosedSquareRoot(String tex) {
    final squareRootCount = RegExp(r'\\sqrt\{').allMatches(tex).length;

    var closeCount = 0;
    var depth = 0;

    for (var index = 0; index < tex.length; index++) {
      if (tex[index] == '{') {
        depth++;
      } else if (tex[index] == '}') {
        if (depth > 0) {
          depth--;
          closeCount++;
        }
      }
    }

    return squareRootCount > closeCount;
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
