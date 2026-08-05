import '../model/expression/expression_document.dart';
import '../model/expression/fraction_draft.dart';

class ExpressionTexSerializer {
  const ExpressionTexSerializer();

  String serialize(
    ExpressionDocument document, {
    FractionDraft? fractionDraft,
    bool showCursor = false,
  }) {
    final mainTex = _createSafeTex(document.texExpression);

    if (fractionDraft == null) {
      return _serializeMainExpression(mainTex, showCursor: showCursor);
    }

    final numeratorIsActive =
        fractionDraft.activePart == FractionPart.numerator;

    final denominatorIsActive =
        fractionDraft.activePart == FractionPart.denominator;

    final numeratorTex = _serializeFractionPart(
      fractionDraft.numerator,
      isActive: numeratorIsActive,
      showCursor: showCursor,
    );

    final denominatorTex = _serializeFractionPart(
      fractionDraft.denominator,
      isActive: denominatorIsActive,
      showCursor: showCursor,
    );

    final fractionTex = '\\frac{$numeratorTex}{$denominatorTex}';

    if (mainTex.isEmpty) {
      return fractionTex;
    }

    return '$mainTex$fractionTex';
  }

  String _serializeMainExpression(String mainTex, {required bool showCursor}) {
    final cursorTex = showCursor ? _visibleCursor : _hiddenCursor;

    if (mainTex.isEmpty) {
      return '$cursorTex$_minimumWidth';
    }

    return '$mainTex$cursorTex';
  }

  String _serializeFractionPart(
    ExpressionDocument document, {
    required bool isActive,
    required bool showCursor,
  }) {
    final safeTex = _createSafeTex(document.texExpression);

    if (!isActive) {
      return safeTex.isEmpty ? _minimumWidth : safeTex;
    }

    final cursorTex = showCursor ? _visibleCursor : _hiddenCursor;

    if (safeTex.isEmpty) {
      return '$cursorTex$_minimumWidth';
    }

    return '$safeTex$cursorTex';
  }

  String _createSafeTex(String source) {
    if (source.trim().isEmpty) {
      return '';
    }

    var tex = source;

    final leftParenthesisCount = RegExp(r'\\left\(').allMatches(tex).length;

    final rightParenthesisCount = RegExp(r'\\right\)').allMatches(tex).length;

    final missingRightParentheses =
        leftParenthesisCount - rightParenthesisCount;

    if (missingRightParentheses > 0) {
      for (var index = 0; index < missingRightParentheses; index++) {
        tex += r'\right)';
      }
    }

    final openingBraceCount = _countCharacter(tex, '{');

    final closingBraceCount = _countCharacter(tex, '}');

    final missingClosingBraces = openingBraceCount - closingBraceCount;

    if (missingClosingBraces > 0) {
      tex += List<String>.filled(missingClosingBraces, '}').join();
    }

    return tex;
  }

  int _countCharacter(String value, String character) {
    var count = 0;

    for (var index = 0; index < value.length; index++) {
      if (value[index] == character) {
        count++;
      }
    }

    return count;
  }

  static const String _visibleCursor = r'\,\vert';

  static const String _hiddenCursor = r'\,\phantom{\vert}';

  static const String _minimumWidth = r'\phantom{0}';
}
