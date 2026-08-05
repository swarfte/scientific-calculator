import '../model/expression/expression_document.dart';
import '../model/expression/fraction_draft.dart';

class ExpressionTexSerializer {
  const ExpressionTexSerializer();

  String serialize(
    ExpressionDocument document, {
    FractionDraft? fractionDraft,
  }) {
    final mainTex = _createSafeTex(document.texExpression);

    if (fractionDraft == null) {
      return mainTex.isEmpty ? r'\square' : mainTex;
    }

    final numeratorTex = _draftPartTex(
      fractionDraft.numerator,
      isActive: fractionDraft.activePart == FractionPart.numerator,
    );

    final denominatorTex = _draftPartTex(
      fractionDraft.denominator,
      isActive: fractionDraft.activePart == FractionPart.denominator,
    );

    final fractionTex =
        r'\frac{'
        '$numeratorTex'
        r'}{'
        '$denominatorTex'
        r'}';

    if (mainTex.isEmpty) {
      return fractionTex;
    }

    return '$mainTex$fractionTex';
  }

  String serializeDocument(ExpressionDocument document) {
    final result = _createSafeTex(document.texExpression);

    return result.isEmpty ? r'\square' : result;
  }

  String _draftPartTex(ExpressionDocument document, {required bool isActive}) {
    final safeTex = _createSafeTex(document.texExpression);

    if (safeTex.isEmpty) {
      return isActive ? r'\boxed{\phantom{0}}' : r'\square';
    }

    if (!isActive) {
      return safeTex;
    }

    return '\\boxed{$safeTex}';
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

    final openingBraceCount = _countUnescaped(tex, '{');

    final closingBraceCount = _countUnescaped(tex, '}');

    final missingClosingBraces = openingBraceCount - closingBraceCount;

    if (missingClosingBraces > 0) {
      tex += List<String>.filled(missingClosingBraces, '}').join();
    }

    return tex;
  }

  int _countUnescaped(String value, String character) {
    var count = 0;

    for (var index = 0; index < value.length; index++) {
      if (value[index] == character) {
        count++;
      }
    }

    return count;
  }
}
