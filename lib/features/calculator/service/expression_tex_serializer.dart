import '../model/expression/expression_document.dart';
import '../model/expression/fraction_draft.dart';

class ExpressionTexSerializer {
  const ExpressionTexSerializer();

  String serialize(
    ExpressionDocument document, {
    FractionDraft? fractionDraft,
    bool showCursor = false,
  }) {
    if (fractionDraft == null) {
      return _serializeDocument(
        document,
        isActive: true,
        showCursor: showCursor,
      );
    }

    final numeratorTex = _serializeDocument(
      fractionDraft.numerator,
      isActive: fractionDraft.activePart == FractionPart.numerator,
      showCursor: showCursor,
    );

    final denominatorTex = _serializeDocument(
      fractionDraft.denominator,
      isActive: fractionDraft.activePart == FractionPart.denominator,
      showCursor: showCursor,
    );

    final fractionTex = '\\frac{$numeratorTex}{$denominatorTex}';

    final mainTex = _createSafeTex(document.texExpression);

    if (mainTex.isEmpty) {
      return fractionTex;
    }

    return '$mainTex$fractionTex';
  }

  String _serializeDocument(
    ExpressionDocument document, {
    required bool isActive,
    required bool showCursor,
  }) {
    var source = document.texExpression;

    if (isActive) {
      final cursor = showCursor ? _visibleCursor : _hiddenCursor;

      final offset = document.texCursorOffset.clamp(0, source.length);

      source = source.replaceRange(offset, offset, cursor);
    }

    final safeTex = _createSafeTex(source);

    if (safeTex.isNotEmpty) {
      return safeTex;
    }

    if (!isActive) {
      return _minimumWidth;
    }

    return showCursor
        ? '$_visibleCursor$_minimumWidth'
        : '$_hiddenCursor$_minimumWidth';
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
      tex += List<String>.filled(missingRightParentheses, r'\right)').join();
    }

    final openingBraceCount = _countCharacter(tex, '{');

    final closingBraceCount = _countCharacter(tex, '}');

    if (openingBraceCount > closingBraceCount) {
      tex += List<String>.filled(
        openingBraceCount - closingBraceCount,
        '}',
      ).join();
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
